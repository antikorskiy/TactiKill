local TK = TACTIKILL
local C  = TK.Config

TK.AutoSpawn = TK.AutoSpawn or {}
local AS = TK.AutoSpawn

local CombineWeapons = {
	"weapon_smg1",
	"weapon_ar2",
	"weapon_shotgun",
}

local RebelWeapons = {
	"weapon_smg1",
	"weapon_shotgun",
	"weapon_pistol",
}

local function PickRandom(list)
	if not list or #list == 0 then return nil end
	return list[math.random(#list)]
end

local function GetCenters()
	local centers = {}
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:Alive() then
			centers[#centers + 1] = ply:GetPos()
		end
	end

	if #centers == 0 then
		for _, sp in ipairs(ents.FindByClass("info_player_start")) do
			if IsValid(sp) then centers[#centers + 1] = sp:GetPos() end
		end
	end

	if #centers == 0 then
		local spawn = game.GetWorld() and game.GetWorld():GetPos() or Vector(0, 0, 0)
		centers[#centers + 1] = spawn
	end

	return centers
end

local function CountAutoSpawned()
	local total = 0
	for _, npc in ipairs(ents.FindByClass("npc_combine_s")) do
		if IsValid(npc) and npc.TACTIKILL_Autospawned then total = total + 1 end
	end
	for _, npc in ipairs(ents.FindByClass("npc_citizen")) do
		if IsValid(npc) and npc.TACTIKILL_Autospawned then total = total + 1 end
	end
	return total
end

local function IsPositionOccupied(pos, minDist)
	for _, ent in ipairs(ents.FindInSphere(pos, minDist)) do
		if IsValid(ent) and (ent:IsNPC() or ent:IsPlayer() or ent:IsNextBot()) then
			return true
		end
	end
	return false
end

local function FindSpawnPos(centers)
	local cfg = C.AutoSpawn

	for _ = 1, cfg.MaxAttempts do
		local center = centers[math.random(#centers)]

		local angle = math.random() * math.pi * 2
		local minDist = cfg.MinPlayerDistance
		local radius = cfg.Radius
		local dist = minDist + math.sqrt(math.random()) * math.max(radius - minDist, 100)

		local x = center.x + math.cos(angle) * dist
		local y = center.y + math.sin(angle) * dist

		local tr = util.TraceLine({
			start  = Vector(x, y, center.z + 3000),
			endpos = Vector(x, y, center.z - 3000),
			mask   = MASK_SOLID_BRUSHONLY,
		})

		if tr.Hit and not tr.HitSky and tr.HitNormal.z > 0.5 then
			local pos = tr.HitPos
			if pos.z > -5000 and pos.z < 20000 then
				if not IsPositionOccupied(pos, cfg.MinNpcDistance) then
					return pos + Vector(0, 0, 20)
				end
			end
		end
	end

	return nil
end

local function ApplyRelations(npc)
	local cfg = C.AutoSpawn

	if not cfg.RebelsHostileToPlayer and npc:GetClass() == "npc_citizen" then
		npc:AddRelationship("player", D_LI, 99)
	else
		npc:AddRelationship("player", D_HT, 99)
	end

	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) then
			if not cfg.RebelsHostileToPlayer and npc:GetClass() == "npc_citizen" then
				npc:AddEntityRelationship(ply, D_LI, 99)
			else
				npc:AddEntityRelationship(ply, D_HT, 99)
			end
		end
	end
end

function AS.CreateCombine(pos)
	local npc = ents.Create("npc_combine_s")
	if not IsValid(npc) then return nil end

	npc:SetPos(pos)
	npc:SetAngles(Angle(0, math.random(0, 360), 0))

	local skill = tostring(C.AutoSpawn.CombineSkill)
	npc:SetKeyValue("additionalequipment", PickRandom(CombineWeapons) or "weapon_smg1")
	npc:SetKeyValue("squadname", "Overwatch")
	npc:SetKeyValue("NumGrenades", "3")
	npc:SetKeyValue("WeaponType", "0")

	npc:Spawn()
	npc:Activate()

	local skillTable = skill and skillconv and skillconv[skill] or nil

	if IsValid(npc) then
		npc.TACTIKILL_Autospawned = true
		ApplyRelations(npc)
	end

	return npc
end

function AS.CreateRebel(pos)
	local npc = ents.Create("npc_citizen")
	if not IsValid(npc) then return nil end

	npc:SetPos(pos)
	npc:SetAngles(Angle(0, math.random(0, 360), 0))

	npc:SetKeyValue("citizentype", "4")
	npc:SetKeyValue("additionalequipment", PickRandom(RebelWeapons) or "weapon_smg1")
	npc:SetKeyValue("SquadName", "Rebels")
	npc:SetKeyValue("ExpressionType", "2")

	npc:Spawn()
	npc:Activate()

	if IsValid(npc) then
		npc.TACTIKILL_Autospawned = true
		ApplyRelations(npc)
	end

	return npc
end

function AS.SpawnCombine(count)
	count = math.Clamp(tonumber(count) or C.AutoSpawn.CombineCount, 0, 100)
	local cfg = C.AutoSpawn
	local centers = GetCenters()
	local spawned = 0

	for _ = 1, count do
		if CountAutoSpawned() >= cfg.MaxTotal then
			break
		end
		local pos = FindSpawnPos(centers)
		if pos then
			local npc = AS.CreateCombine(pos)
			if IsValid(npc) then spawned = spawned + 1 end
		end
	end

	return spawned
end

function AS.SpawnRebels(count)
	count = math.Clamp(tonumber(count) or C.AutoSpawn.RebelCount, 0, 100)
	local cfg = C.AutoSpawn
	local centers = GetCenters()
	local spawned = 0

	for _ = 1, count do
		if CountAutoSpawned() >= cfg.MaxTotal then
			break
		end
		local pos = FindSpawnPos(centers)
		if pos then
			local npc = AS.CreateRebel(pos)
			if IsValid(npc) then spawned = spawned + 1 end
		end
	end

	return spawned
end

function AS.Clear()
	local removed = 0

	for _, npc in ipairs(ents.FindByClass("npc_combine_s")) do
		if IsValid(npc) and npc.TACTIKILL_Autospawned then
			npc:Remove()
			removed = removed + 1
		end
	end

	for _, npc in ipairs(ents.FindByClass("npc_citizen")) do
		if IsValid(npc) and npc.TACTIKILL_Autospawned then
			npc:Remove()
			removed = removed + 1
		end
	end

	return removed
end

concommand.Add("tactikill_autospawn", function(caller, _, args)
	if IsValid(caller) and not caller:IsAdmin() then
		caller:PrintMessage(HUD_PRINTCONSOLE, "Admin only")
		return
	end

	local function say(msg)
		if IsValid(caller) then
			caller:PrintMessage(HUD_PRINTCONSOLE, msg)
		end
		print("[TACTIKILL] " .. msg)
	end

	local kind = (args[1] or "all"):lower()

	if kind == "clear" then
		local n = AS.Clear()
		say("Cleared " .. n .. " auto-spawned NPCs")
		return
	end

	local cfg = C.AutoSpawn
	local combine, rebels = 0, 0

	if kind == "combine" then
		combine = AS.SpawnCombine(cfg.CombineCount)
	elseif kind == "rebels" then
		if not cfg.RebelsEnabled then
			say("Rebels are disabled in config (AutoSpawn.RebelsEnabled = false)")
			return
		end
		rebels = AS.SpawnRebels(cfg.RebelCount)
	elseif kind == "all" or kind == "random" then
		combine = AS.SpawnCombine(cfg.CombineCount)
		if cfg.RebelsEnabled then
			rebels = AS.SpawnRebels(cfg.RebelCount)
		end
	else
		say("Usage: tactikill_autospawn [all|combine|rebels|clear]")
		return
	end

	say("Auto-spawn: " .. combine .. " combine, " .. rebels .. " rebels")
end, nil, "Auto-spawn NPCs on the map (admin)")