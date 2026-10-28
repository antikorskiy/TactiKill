local TK = TACTIKILL
local C  = TK.Config
local E  = C.Events

util.AddNetworkString("TACTIKILL_Event_Bombard_Start")
util.AddNetworkString("TACTIKILL_Event_Bombard_Strike")
util.AddNetworkString("TACTIKILL_Event_Bombard_End")
util.AddNetworkString("TACTIKILL_Event_Airdrop_Start")
util.AddNetworkString("TACTIKILL_Event_Airdrop_Landing")

local lastCheck = 0
local eventBusy = false

local function StripSoundPrefix(path)
	if string.StartsWith(path, "sound/") then return string.sub(path, 7) end
	return path
end

local function GetRandomPlayer()
	local players = player.GetAll()
	if #players == 0 then return nil end
	return players[math.random(#players)]
end

local function GetGroundPos(center, radius)
	local downTr = util.TraceLine({
		start  = center + Vector(0, 0, 128),
		endpos = center - Vector(0, 0, 30000),
		mask   = MASK_SOLID_BRUSHONLY,
	})

	if not downTr.Hit then
		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) and ply:Alive() then
				local pTr = util.TraceLine({
					start  = ply:GetPos() + Vector(0, 0, 128),
					endpos = ply:GetPos() - Vector(0, 0, 30000),
					mask   = MASK_SOLID_BRUSHONLY,
				})
				if pTr.Hit and pTr.HitNormal.z > 0.3 then
					return pTr.HitPos
				end
			end
		end
		print("[TACTIKILL DEBUG] GetGroundPos: no ground under any player")
		return nil
	end

	local baseZ = downTr.HitPos.z

	for _ = 1, 80 do
		local angle = math.random() * math.pi * 2
		local dist  = math.sqrt(math.random()) * radius
		local tx = center.x + math.cos(angle) * dist
		local ty = center.y + math.sin(angle) * dist

		local tr = util.TraceLine({
			start  = Vector(tx, ty, baseZ + 500),
			endpos = Vector(tx, ty, baseZ - 500),
			mask   = MASK_SOLID_BRUSHONLY,
		})

		if tr.Hit and not tr.HitSky
			and tr.HitNormal.z > 0.4
			and math.abs(tr.HitPos.z - baseZ) < 300 then
			return tr.HitPos
		end
	end

	local angle = math.random() * math.pi * 2
	local tx = center.x + math.cos(angle) * 200
	local ty = center.y + math.sin(angle) * 200

	local fbTr = util.TraceLine({
		start  = Vector(tx, ty, baseZ + 500),
		endpos = Vector(tx, ty, baseZ - 500),
		mask   = MASK_SOLID_BRUSHONLY,
	})

	if fbTr.Hit and not fbTr.HitSky and fbTr.HitNormal.z > 0.4 then
		print("[TACTIKILL DEBUG] GetGroundPos: using fallback with offset")
		return fbTr.HitPos
	end

	print("[TACTIKILL DEBUG] GetGroundPos: using player ground position")
	return downTr.HitPos
end

local function PlayWorldSound(path, pos)
	if not path or path == "" then return end
	sound.Play(StripSoundPrefix(path), pos, 100, 100, 1)
end

local function SpawnExplosion(pos, radius, damage)
	local exp = ents.Create("env_explosion")
	exp:SetPos(pos + Vector(0, 0, 16))
	exp:SetKeyValue("iMagnitude", tostring(damage))
	exp:SetKeyValue("iRadiusOverride", tostring(radius))
	exp:Spawn()
	exp:Fire("Explode", 0, 0)
	timer.Simple(0.5, function()
		if IsValid(exp) then exp:Remove() end
	end)
end

local function FireBombardStrikeAt(pos, R, D)
	SpawnExplosion(pos, R, D)

	local dirs = { Vector(1,0,0), Vector(-1,0,0), Vector(0,1,0), Vector(0,-1,0) }
	local function FireWave(distance, radiusScale, damageScale)
		for _, dir in ipairs(dirs) do
			local p = pos + dir * distance
			local tr = util.TraceLine({
				start  = p + Vector(0, 0, 200),
				endpos = p - Vector(0, 0, 500),
				mask   = MASK_SOLID_BRUSHONLY,
			})
			if tr.Hit then
				SpawnExplosion(tr.HitPos, R * radiusScale, D * damageScale)
			end
		end
	end
	timer.Simple(0.15, function() FireWave(R * 0.9, 0.75, 0.7) end)
	timer.Simple(0.30, function() FireWave(R * 1.8, 0.55, 0.45) end)
end

local function FireBombardStrike(pos)
	FireBombardStrikeAt(pos, E.Bombardment.ExplosionRadius, E.Bombardment.ExplosionDamage)
end

local function DoBombardment()
	if eventBusy then return end
	local players = player.GetAll()
	if #players == 0 then return end
	eventBusy = true

	local numBeams = math.random(E.Bombardment.MinBeams, E.Bombardment.MaxBeams)
	local beams = {}
	local attempts = 0
	local maxAttempts = numBeams * 8

	while #beams < numBeams and attempts < maxAttempts do
		attempts = attempts + 1
		local center = GetRandomPlayer()
		if center then
			local pos = GetGroundPos(center:GetPos(), E.Bombardment.BeamRadius)
			if pos then
				beams[#beams + 1] = pos
			end
		end
	end

	if #beams == 0 then
		eventBusy = false
		print("[TACTIKILL] Bombardment skipped: no valid positions")
		return
	end

	net.Start("TACTIKILL_Event_Bombard_Start")
		net.WriteUInt(#beams, 8)
		for _, pos in ipairs(beams) do
			net.WriteFloat(pos.x)
			net.WriteFloat(pos.y)
			net.WriteFloat(pos.z)
		end
	net.Broadcast()

	print("[TACTIKILL SERVER] Bombardment start: " .. #beams .. " beams")

	local preDelay = (#beams - 1) * E.Bombardment.BeamDelay + E.Bombardment.ChargeTime

	timer.Simple(preDelay, function()
		for i, pos in ipairs(beams) do
			timer.Simple((i - 1) * E.Bombardment.FireInterval, function()
				PlayWorldSound(E.Bombardment.SoundPath, pos + Vector(0, 0, 50))
				timer.Simple(E.Bombardment.SoundLeadTime, function()
					net.Start("TACTIKILL_Event_Bombard_Strike")
						net.WriteUInt(i, 8)
						net.WriteFloat(pos.x)
						net.WriteFloat(pos.y)
						net.WriteFloat(pos.z)
					net.Broadcast()
					FireBombardStrike(pos)
				end)
			end)
		end
		timer.Simple(#beams * E.Bombardment.FireInterval + E.Bombardment.SoundLeadTime + 2, function()
			net.Start("TACTIKILL_Event_Bombard_End")
			net.Broadcast()
			eventBusy = false
		end)
	end)
end

local function OpenAirdrop(box, ply)
	if not IsValid(box) or not IsValid(ply) then return end
	if not box.TACTIKILL_Airdrop then return end
	if box.TACTIKILL_Opened or box.TACTIKILL_Pending then return end
	box.TACTIKILL_Opened = true

	local hp = ply:Health()
	local maxHp = math.max(ply:GetMaxHealth(), 1)
	local hpFrac = hp / maxHp

	local hasArtyWep = IsValid(ply:GetWeapon("tactikill_artillery"))
	local canGetArty = E.Airdrop.ArtyEnabled and not hasArtyWep

	local content
	if canGetArty and math.random() < E.Airdrop.ArtyChance then
		content = "artillery"
	elseif hpFrac >= 0.9 then
		content = "ammo"
	else
		content = (math.random() < E.Airdrop.AmmoChance) and "ammo" or "health"
	end

	if content == "artillery" then
		ply:Give("tactikill_artillery")
		ply:SetNWBool("TK_ArtyUsed", false)
		ply:ChatPrint("[TactiKill] Airdrop: ARTILLERY DESIGNATOR")
		print("[TACTIKILL] Airdrop gave artillery to " .. ply:Nick())

	elseif content == "ammo" then
		local wep = ply:GetActiveWeapon()
		local ammoGiven = false
		if IsValid(wep) then
			local primary = wep:GetPrimaryAmmoType()
			local secondary = wep:GetSecondaryAmmoType()
			if primary and primary >= 0 then
				ply:GiveAmmo(E.Airdrop.AmmoAmount, primary, true)
				ammoGiven = true
			elseif secondary and secondary >= 0 then
				ply:GiveAmmo(math.floor(E.Airdrop.AmmoAmount / 2), secondary, true)
				ammoGiven = true
			end
		end
		if not ammoGiven then
			ply:GiveAmmo(E.Airdrop.AmmoAmount, "smg1", true)
		end
		ply:ChatPrint("[TactiKill] Airdrop: +AMMO")

	else
		ply:SetHealth(math.min(hp + E.Airdrop.HealthAmount, maxHp))
		ply:ChatPrint("[TactiKill] Airdrop: +HEALTH")
	end

	local ed = EffectData()
	ed:SetOrigin(box:GetPos())
	ed:SetScale(2)
	util.Effect("cball_explode", ed)
	sound.Play("items/ammo_pickup.wav", box:GetPos(), 80, 120, 1)

	local idx = box:EntIndex()
	hook.Remove("Think", "TACTIKILL_AirdropThink_" .. idx)
	hook.Remove("EntityRemoved", "TACTIKILL_AirdropRemoved_" .. idx)
	box:Remove()
end

local function DoAirdrop()
	if eventBusy then return end
	local center = GetRandomPlayer()
	if not center then return end
	eventBusy = true

	local pos = GetGroundPos(center:GetPos(), E.Airdrop.DropRadius)
	if not pos then
		eventBusy = false
		print("[TACTIKILL SERVER] Airdrop skipped: no valid ground position")
		return
	end

	local fallTime = E.Airdrop.FallTime
	local startZ = pos.z + 800

	net.Start("TACTIKILL_Event_Airdrop_Start")
		net.WriteFloat(pos.x)
		net.WriteFloat(pos.y)
		net.WriteFloat(pos.z)
		net.WriteFloat(fallTime)
	net.Broadcast()

	print("[TACTIKILL SERVER] Airdrop start at " .. math.floor(pos.x) .. "," ..
		math.floor(pos.y) .. "," .. math.floor(pos.z) .. " in " .. fallTime .. "s")

	timer.Simple(fallTime, function()
		PlayWorldSound(E.Airdrop.SoundPath, pos + Vector(0, 0, 500))

		net.Start("TACTIKILL_Event_Airdrop_Landing")
			net.WriteFloat(pos.x)
			net.WriteFloat(pos.y)
			net.WriteFloat(pos.z)
		net.Broadcast()

		local box = ents.Create("prop_physics")
		box:SetModel(E.Airdrop.BoxModel)
		box:SetPos(Vector(pos.x, pos.y, startZ))
		box:SetAngles(Angle(0, math.random() * 360, 0))
		box:Spawn()

		box:PhysicsDestroy()
		box:SetMoveType(MOVETYPE_NONE)
		box:SetSolid(SOLID_BBOX)
		box:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
		box:SetPos(Vector(pos.x, pos.y, startZ))

		box.TACTIKILL_Airdrop  = true
		box.TACTIKILL_Pending  = true
		box.TACTIKILL_Opened   = false

		box:SetNWBool("TACTIKILL_Airdrop", true)
		box:SetHealth(999999)
		box:DrawShadow(false)

		local min = box:OBBMins()
		local targetZ = pos.z - min.z + 2

		local idx = box:EntIndex()
		local timerName = "TACTIKILL_Drop_" .. idx
		local currentZ = startZ
		local stepZ = E.Airdrop.FallSpeed * 0.05

		timer.Create(timerName, 0.05, 0, function()
			if not IsValid(box) then timer.Remove(timerName) return end
			currentZ = currentZ - stepZ
			if currentZ <= targetZ then
				currentZ = targetZ
				box:SetPos(Vector(pos.x, pos.y, currentZ))
				box.TACTIKILL_Pending = false
				box:SetNWBool("TACTIKILL_Landed", true)
				timer.Remove(timerName)
				sound.Play("physics/wood/wood_box_impact_hard3.wav", box:GetPos(), 80, 100, 1)
				print("[TACTIKILL SERVER] Airdrop landed at " .. math.floor(pos.x) .. "," ..
					math.floor(pos.y) .. "," .. math.floor(targetZ))
				return
			end
			box:SetPos(Vector(pos.x, pos.y, currentZ))
		end)

		hook.Add("Think", "TACTIKILL_AirdropThink_" .. idx, function()
			if not IsValid(box) then
				hook.Remove("Think", "TACTIKILL_AirdropThink_" .. idx)
				return
			end
			if box.TACTIKILL_Pending or box.TACTIKILL_Opened then return end
			local c = box:GetPos()
			local r = box:BoundingRadius() + 40
			for _, ply in ipairs(player.GetAll()) do
				if IsValid(ply) and ply:Alive() then
					if ply:GetPos():DistToSqr(c) <= r * r then
						OpenAirdrop(box, ply)
						return
					end
				end
			end
		end)

		hook.Add("EntityRemoved", "TACTIKILL_AirdropRemoved_" .. idx, function(ent)
			if ent ~= box then return end
			hook.Remove("Think", "TACTIKILL_AirdropThink_" .. idx)
			hook.Remove("EntityRemoved", "TACTIKILL_AirdropRemoved_" .. idx)
			timer.Remove(timerName)
		end)

		eventBusy = false
	end)
end

hook.Add("EntityTakeDamage", "TACTIKILL_AirdropImmune", function(ent, dmg)
	if IsValid(ent) and ent.TACTIKILL_Airdrop and not ent.TACTIKILL_Opened then
		dmg:SetDamage(0)
		return true
	end
end)

hook.Add("PhysgunPickup", "TACTIKILL_AirdropPhysgun", function(_, ent)
	if IsValid(ent) and ent.TACTIKILL_Airdrop then return false end
end)

hook.Add("GravGunPickupAllowed", "TACTIKILL_AirdropGrav", function(_, ent)
	if IsValid(ent) and ent.TACTIKILL_Airdrop then return false end
end)

hook.Add("AllowPlayerPickup", "TACTIKILL_AirdropPickup", function(_, ent)
	if IsValid(ent) and ent.TACTIKILL_Airdrop then return false end
end)

timer.Remove("TACTIKILL_EventTick")
timer.Create("TACTIKILL_EventTick", 5, 0, function()
	if not E.Enabled then return end
	if eventBusy then return end
	if #player.GetAll() < E.MinPlayers then return end
	if CurTime() - lastCheck < E.CheckInterval then return end
	lastCheck = CurTime()
	if math.random() > E.Chance then return end
	if math.random() < 0.5 then DoBombardment() else DoAirdrop() end
end)

concommand.Add("tactikill_event", function(caller, _, args)
	if IsValid(caller) and not caller:IsAdmin() then
		caller:PrintMessage(HUD_PRINTCONSOLE, "Admin only")
		return
	end
	local kind = args[1] or "random"
	if kind == "bombard" then
		DoBombardment()
	elseif kind == "airdrop" then
		DoAirdrop()
	elseif kind == "random" then
		if math.random() < 0.5 then DoBombardment() else DoAirdrop() end
	else
		if IsValid(caller) then
			caller:PrintMessage(HUD_PRINTCONSOLE, "Usage: tactikill_event bombard|airdrop|random")
		else
			print("[TactiKill] Usage: tactikill_event bombard|airdrop|random")
		end
	end
end, nil, "Trigger a TactiKill random event (admin)")

function TK.FireBarrage(marks, opts)
	if not marks or #marks == 0 then return end
	opts = opts or {}

	local chargeTime   = opts.chargeTime   or 2
	local fireInterval = opts.fireInterval or 1.2
	local leadTime     = opts.leadTime     or E.Bombardment.SoundLeadTime
	local radius       = opts.radius       or E.Bombardment.ExplosionRadius
	local damage       = opts.damage       or E.Bombardment.ExplosionDamage
	local soundPath    = opts.soundPath    or E.Bombardment.SoundPath

	print("[TACTIKILL] FireBarrage called: " .. #marks .. " marks, charge " .. chargeTime .. "s")

	net.Start("TACTIKILL_Event_Bombard_Start")
		net.WriteUInt(#marks, 8)
		for _, pos in ipairs(marks) do
			net.WriteFloat(pos.x)
			net.WriteFloat(pos.y)
			net.WriteFloat(pos.z)
		end
	net.Broadcast()

	timer.Simple(chargeTime, function()
		for i, pos in ipairs(marks) do
			timer.Simple((i - 1) * fireInterval, function()
				PlayWorldSound(soundPath, pos + Vector(0, 0, 50))
				timer.Simple(leadTime, function()
					net.Start("TACTIKILL_Event_Bombard_Strike")
						net.WriteUInt(i, 8)
						net.WriteFloat(pos.x)
						net.WriteFloat(pos.y)
						net.WriteFloat(pos.z)
					net.Broadcast()
					FireBombardStrikeAt(pos, radius, damage)
				end)
			end)
		end
		timer.Simple(#marks * fireInterval + leadTime + 2, function()
			net.Start("TACTIKILL_Event_Bombard_End")
			net.Broadcast()
		end)
	end)
end