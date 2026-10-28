--[[---------------------------------------------------------------------------
  Project: TactiKill - Combat System
  tactikill/sv_tools.lua  (SERVER)

  Server side of the "TactiKill Timer" tool, feedback messages and the
  explicit statistics reset command.

  Permissions:
    * The tool only ever affects the player HOLDING it (their own timer/HUD).
    * Resetting statistics:  tactikill_reset_stats confirm [target|*]
        - own stats: allowed if C.ResetAllowSelf
        - other players / "*": needs C.ResetOthersLevel (admin/superadmin)
        - server console: always allowed
-----------------------------------------------------------------------------]]

local TK = TACTIKILL
local C  = TK.Config

util.AddNetworkString("TACTIKILL_Notify")
util.AddNetworkString("TACTIKILL_ToggleHUD")

TK.Tools = {}
local Tools = TK.Tools

local Cooldowns = setmetatable({}, { __mode = "k" })

-- kind: 0 info, 1 error/denied
function TK.Notify(ply, msg, kind)
	if not IsValid(ply) or ply:IsBot() then return end
	net.Start("TACTIKILL_Notify")
		net.WriteString(msg)
		net.WriteUInt(kind or 0, 2)
	net.Send(ply)
end

local function OnCooldown(ply, key, delay)
	local now = CurTime()
	local t = Cooldowns[ply]
	if not t then t = {}; Cooldowns[ply] = t end
	if (t[key] or 0) > now then return true end
	t[key] = now + delay
	return false
end

----------------------------------------------------------------------------
-- Tool actions (called from stools/tactikill_timer.lua, server side only)
----------------------------------------------------------------------------
function Tools.TimerToggle(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if OnCooldown(ply, "toggle", 0.3) then return false end

	local running = TK.Timer.Toggle(ply)
	TK.Timer.Send(ply)
	if running then
		TK.Notify(ply, "SESSION TIMER STARTED", 0)
	else
		TK.Notify(ply, "SESSION TIMER PAUSED  " .. TK.FormatTime(TK.Timer.Elapsed(ply)), 0)
	end
	return true
end

function Tools.TimerReset(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if OnCooldown(ply, "reset", 0.5) then return false end

	TK.Timer.Reset(ply)
	TK.Timer.Send(ply)
	TK.Notify(ply, "SESSION TIMER RESET (kills and score unchanged)", 0)
	return true
end

-- HUD visibility is a client setting; the server only relays the request.
-- The tool gun may call Reload repeatedly while the key is held, so debounce.
function Tools.HUDToggle(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if OnCooldown(ply, "hud", 0.5) then return false end

	net.Start("TACTIKILL_ToggleHUD")
	net.Send(ply)
	return true
end

----------------------------------------------------------------------------
-- Statistics reset
----------------------------------------------------------------------------
function Tools.CanReset(caller, target)
	if not IsValid(caller) then return true end -- server console
	if caller == target then return C.ResetAllowSelf end
	if C.ResetOthersLevel == "superadmin" then return caller:IsSuperAdmin() end
	return caller:IsAdmin()
end

local function Reply(caller, msg, kind)
	if IsValid(caller) then
		TK.Notify(caller, msg, kind)
	else
		print("[TactiKill] " .. msg)
	end
end

local function FindTargets(arg)
	if arg == "*" then return player.GetAll() end

	local id = tonumber(arg)
	if id then
		for _, p in ipairs(player.GetAll()) do
			if p:UserID() == id then return { p } end
		end
		return {}
	end

	local out, needle = {}, string.lower(arg)
	for _, p in ipairs(player.GetAll()) do
		if string.find(string.lower(p:Nick()), needle, 1, true) then out[#out + 1] = p end
	end
	return out
end

concommand.Add("tactikill_reset_stats", function(caller, _, args)
	-- The literal word "confirm" is required so the destructive action can
	-- never be triggered by an accidental/ambiguous input.
	if args[1] ~= "confirm" then
		Reply(caller, "Usage: tactikill_reset_stats confirm [userid|name|*]", 1)
		return
	end

	local targets
	if args[2] then
		targets = FindTargets(args[2])
	elseif IsValid(caller) then
		targets = { caller }
	else
		Reply(caller, "From the server console specify a target: userid, name or *", 1)
		return
	end

	if #targets == 0 then
		Reply(caller, "No matching player", 1)
		return
	end

	local done = 0
	for _, target in ipairs(targets) do
		if IsValid(target) and Tools.CanReset(caller, target) then
			TK.Combo.ResetStats(target)
			done = done + 1
			TK.Notify(target, "STATISTICS RESET: kills, score, combo (session timer unchanged)", 0)
			TK.Debug("stats reset for %s by %s", target:Nick(), IsValid(caller) and caller:Nick() or "console")
		end
	end

	if done == 0 then
		Reply(caller, "You are not allowed to reset these statistics", 1)
	elseif done < #targets then
		Reply(caller, "Reset " .. done .. " of " .. #targets .. " players (others not permitted)", 0)
	end
end, nil, "Reset kills/score/combo. Usage: tactikill_reset_stats confirm [userid|name|*]")
