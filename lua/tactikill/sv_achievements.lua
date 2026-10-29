local TK = TACTIKILL
local C  = TK.Config
local A  = TK.Achievements

util.AddNetworkString("TACTIKILL_Achievement")
util.AddNetworkString("TACTIKILL_AchievementsSync")
util.AddNetworkString("TACTIKILL_RequestAchievements")

local SyncCooldown = setmetatable({}, { __mode = "k" })

function A.Give(ply, id, silent)
	if not IsValid(ply) or ply:IsBot() then return false end
	if not C.Achievements.Enabled then return false end
	local def = A.ById[id]
	if not def then return false end

	local st = TK.Combo.Get(ply)
	if not st.achievements then st.achievements = {} end
	if st.achievements[id] then return false end

	st.achievements[id] = true

	if not silent then
		net.Start("TACTIKILL_Achievement")
			net.WriteString(def.id)
			net.WriteString(def.name)
			net.WriteString(def.desc)
			net.WriteString(def.icon)
		net.Send(ply)

		print("[TACTIKILL] Achievement unlocked: " .. ply:Nick() .. " -> " .. id)
	end

	if C.Achievements.Bonus > 0 then
		st.score = math.min(st.score + C.Achievements.Bonus, 2147483647)
		TK.Combo.Send(ply)
	end

	if TK.Persistence then TK.Persistence.MarkDirty(ply) end
	return true
end

function A.Check(ply, extra, silent)
	if not IsValid(ply) or ply:IsBot() then return end
	if not C.Achievements.Enabled then return end

	local st = TK.Combo.Get(ply)
	if not st.achievements then st.achievements = {} end

	for _, def in ipairs(A.List) do
		if not st.achievements[def.id] then
			local ok, res = pcall(def.check, st, extra)
			if ok and res then
				A.Give(ply, def.id, silent)
			end
		end
	end
end

function A.Sync(ply)
	if not IsValid(ply) or ply:IsBot() then return end
	local st = TK.Combo.Get(ply)
	if not st.achievements then st.achievements = {} end

	local ids = {}
	for id in pairs(st.achievements) do ids[#ids + 1] = id end

	net.Start("TACTIKILL_AchievementsSync")
		net.WriteUInt(#ids, 10)
		for _, id in ipairs(ids) do net.WriteString(id) end
	net.Send(ply)
end

net.Receive("TACTIKILL_RequestAchievements", function(_, ply)
	if not IsValid(ply) then return end
	local now = CurTime()
	if (SyncCooldown[ply] or 0) > now then return end
	SyncCooldown[ply] = now + 1
	A.Sync(ply)
end)

hook.Add("PlayerInitialSpawn", "TACTIKILL_Ach_Init", function(ply)
	timer.Simple(2, function()
		if IsValid(ply) then A.Sync(ply) end
	end)
end)

concommand.Add("tactikill_reset_achievements", function(caller, _, args)
	if IsValid(caller) and not caller:IsAdmin() then
		caller:PrintMessage(HUD_PRINTCONSOLE, "Admin only")
		return
	end

	local target = IsValid(caller) and caller or nil
	if args[1] then
		target = nil
		for _, p in ipairs(player.GetAll()) do
			if p:Nick():lower():find(args[1]:lower(), 1, true) then
				target = p
				break
			end
		end
	end

	if not IsValid(target) then
		if IsValid(caller) then
			caller:PrintMessage(HUD_PRINTCONSOLE, "Usage: tactikill_reset_achievements [nick]")
		end
		return
	end

	local st = TK.Combo.Get(target)
	st.achievements = {}

	-- Silent re-check so that earned achievements don't fire as a flood
	-- next time the player kills something.
	A.Check(target, { kind = "reset" }, true)

	if TK.Persistence then TK.Persistence.Save(target) end
	A.Sync(target)
	TK.Combo.Send(target)

	if IsValid(caller) then
		caller:PrintMessage(HUD_PRINTCONSOLE, "Reset achievements for " .. target:Nick())
	end
	print("[TACTIKILL] Achievements reset for " .. target:Nick())
end, nil, "Reset achievements for a player (admin)")