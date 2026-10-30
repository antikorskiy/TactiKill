local TK = TACTIKILL
local C  = TK.Config
local Combo = TK.Combo

local LastHit   = setmetatable({}, { __mode = "k" })
local Counted   = setmetatable({}, { __mode = "k" })
local PendingHG = setmetatable({}, { __mode = "k" })

local RECORD_MAX_AGE = 0.5
local HG_MAX_AGE     = 0.2

local HG_CATEGORY = {
	[HITGROUP_HEAD]      = "head",
	[HITGROUP_CHEST]     = "torso",
	[HITGROUP_STOMACH]   = "torso",
	[HITGROUP_LEFTARM]   = "larm",
	[HITGROUP_RIGHTARM]  = "rarm",
	[HITGROUP_LEFTLEG]   = "lleg",
	[HITGROUP_RIGHTLEG]  = "rleg",
	[HITGROUP_GEAR]      = "gear",
}

local function IsTrackedVictim(ent)
	if not IsValid(ent) then return false end
	if ent:IsNPC() or ent:IsNextBot() then return not C.IgnoredClasses[ent:GetClass()] end
	return C.CountPlayerKills and ent:IsPlayer()
end

local function IsPropClass(e)
	return IsValid(e) and string.sub(e:GetClass(), 1, 12) == "prop_physics"
end

local function PlayerFrom(e)
	if not IsValid(e) then return nil end
	if e:IsPlayer() then return e, false end
	if e:IsVehicle() then
		local d = e:GetDriver()
		if IsValid(d) and d:IsPlayer() then return d, false end
	end
	if e:IsWeapon() then
		local o = e:GetOwner()
		if IsValid(o) and o:IsPlayer() then return o, false end
	end
	if IsPropClass(e) then
		local pa = e:GetPhysicsAttacker(C.PropAttackerTimeout)
		if IsValid(pa) and pa:IsPlayer() then return pa, true end
	end
	local o = e:GetOwner()
	if IsValid(o) and o:IsPlayer() then return o, false end
	return nil
end

local function ResolveKiller(attacker, inflictor)
	local ply, viaProp = PlayerFrom(attacker)
	if not ply then ply, viaProp = PlayerFrom(inflictor) end
	if not ply then return nil end
	return ply, viaProp or IsPropClass(attacker) or IsPropClass(inflictor)
end

local function StoreHitgroup(victim, hitgroup, dmg)
	if not IsTrackedVictim(victim) then return end

	PendingHG[victim] = { hg = hitgroup, t = CurTime() }

	local rec = LastHit[victim]
	if rec then rec.hg = hitgroup end

	local attacker = dmg:GetAttacker()
	if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
		local st = TK.Combo.Get(attacker)
		if st then
			st.hits = (st.hits or 0) + 1
			if not st.hgCounts then st.hgCounts = {} end
			local cat = HG_CATEGORY[hitgroup] or "other"
			st.hgCounts[cat] = (st.hgCounts[cat] or 0) + 1
		end
	end
end

hook.Add("ScaleNPCDamage",    "TACTIKILL_HG_NPC",    StoreHitgroup)
hook.Add("ScalePlayerDamage", "TACTIKILL_HG_PLAYER", StoreHitgroup)

hook.Add("EntityTakeDamage", "TACTIKILL_TrackDamage", function(ent, dmg)
	if not IsTrackedVictim(ent) then return end

	local now = CurTime()
	local hg  = nil
	local pending = PendingHG[ent]
	if pending and (now - pending.t) <= HG_MAX_AGE then
		hg = pending.hg
	end
	PendingHG[ent] = nil

	local rec = {
		time      = now,
		attacker  = dmg:GetAttacker(),
		inflictor = dmg:GetInflictor(),
		hp        = ent:Health(),
		prev      = LastHit[ent],
		hg        = hg,
	}
	LastHit[ent] = rec

	if ent:IsPlayer() and IsValid(rec.attacker) then
		local d = dmg:GetDamage()
		if d and d > 0 and not dmg:IsDamageType(DMG_FALL) then
			local st = TK.Combo.Get(ent)
			st.perfectKills = 0
		end
	end
end)

hook.Add("PostEntityTakeDamage", "TACTIKILL_PostDamage", function(ent, dmg, took)
	local rec = LastHit[ent]
	if not rec or rec.time ~= CurTime() then return end

	if not took then
		LastHit[ent] = rec.prev
		rec.prev = nil
		return
	end
	rec.prev = nil

	if ent:IsNextBot() and ent:Health() <= 0 and rec.hp > 0 then
		TK.ProcessKill(ent, rec.attacker, rec.inflictor)
	end
end)

hook.Add("EntityFireBullets", "TACTIKILL_Shots", function(ent, data)
	if not IsValid(ent) or not ent:IsPlayer() then return end
	local st = Combo.Get(ent)
	if st then
		st.shots = (st.shots or 0) + (data and data.Num or 1)
	end
end)

local function IsSliding(ply)
	if C.CustomSlideCheck then
		local ok, res = pcall(C.CustomSlideCheck, ply)
		return ok and res == true
	end
	return ply:IsOnGround() and ply:Crouching()
		and ply:GetVelocity():Length2D() >= C.SlideMinSpeed
end

local function IsAirborne(ply)
	return not ply:IsOnGround()
		and ply:GetMoveType() == MOVETYPE_WALK
		and ply:WaterLevel() < 2
		and not ply:InVehicle()
end

local STYLE_ORDER = { "Airborne", "Slide", "SlowMo", "PointBlank", "LongRange", "Prop" }

local function EvaluateStyle(killer, victim, isProp)
	local f = {}
	f.Airborne = IsAirborne(killer)
	f.Slide    = IsSliding(killer)
	f.SlowMo   = game.GetTimeScale() < C.SlowMoThreshold
	f.Prop     = isProp

	if not isProp then
		local dist = killer:GetShootPos():Distance(victim:WorldSpaceCenter())
		f.PointBlank = dist <= C.PointBlankDistance
		f.LongRange  = dist >= C.LongRangeDistance
	end
	return f
end

local function KillWeaponClass(killer, inflictor)
	if IsValid(killer) then
		local wep = killer:GetActiveWeapon()
		if IsValid(wep) then return wep:GetClass() end
	end
	if IsValid(inflictor) then return inflictor:GetClass() end
	return "unknown"
end

local function TrackWeapon(st, class)
	st.weaponKills[class] = (st.weaponKills[class] or 0) + 1
	if st.weaponKills[class] > (st.favWeaponKills or 0) then
		st.favWeaponKills = st.weaponKills[class]
		st.favWeapon = class
	end
end

local function TrackDistance(st, killer, victim, isProp)
	if isProp then return end
	if not IsValid(killer) or not IsValid(victim) then return end
	local dist = killer:GetShootPos():Distance(victim:WorldSpaceCenter())
	st.distanceSum   = st.distanceSum + dist
	st.distanceCount = st.distanceCount + 1
	if dist > st.distanceMax then st.distanceMax = dist end
	if st.distanceMin == 0 or dist < st.distanceMin then st.distanceMin = dist end
end

function TK.ProcessKill(victim, attacker, inflictor)
	if not IsTrackedVictim(victim) then return end

	if Counted[victim] then
		TK.Debug("duplicate death ignored: %s", tostring(victim))
		return
	end
	Counted[victim] = true

	local now = CurTime()
	local rec = LastHit[victim]
	if rec and (now - rec.time) > RECORD_MAX_AGE then rec = nil end
	if rec and rec.hp <= 0 then return end

	local killer, isProp = ResolveKiller(attacker, inflictor)
	if not IsValid(killer) or killer == victim then return end

	if victim:IsNPC() and not C.CountFriendlyNPCs and victim:Disposition(killer) == D_LI then return end

	Combo.ExpireIfDue(killer, now)

	local headshot = rec ~= nil and rec.hg == HITGROUP_HEAD
		and (rec.attacker == attacker or rec.inflictor == inflictor)

	local st, rankedUp = Combo.RegisterKill(killer, now)
	local prevPlayerRank = TK.GetPlayerRankIndex(st.kills - 1, st.score)
	local logs, total = {}, 0

	if headshot then
		st.headshots = (st.headshots or 0) + 1
		if TK.PlayHeadshotSound then TK.PlayHeadshotSound(killer) end
	end

	local wepClass = KillWeaponClass(killer, inflictor)
	TrackWeapon(st, wepClass)
	TrackDistance(st, killer, victim, isProp)

	local base = C.KillScore
	if headshot then
		base = math.floor(base * C.HeadshotMultiplier)
		logs[#logs + 1] = { text = C.Labels.Headshot .. " x" .. tostring(C.HeadshotMultiplier),
			bonus = base, kind = 0 }
	end
	total = total + base

	local style = EvaluateStyle(killer, victim, isProp)
	for _, key in ipairs(STYLE_ORDER) do
		if style[key] then
			local b = C.Bonus[key]
			total = total + b
			logs[#logs + 1] = { text = C.Labels[key], bonus = b, kind = 0 }
		end
	end

	local step = Combo.RegisterMultikill(killer, now)
	if step >= 2 then
		local b = C.MultikillBonus[step] or (step >= 4 and C.MultikillBonus4Plus) or 0
		local label = C.MultikillLabels[math.min(step, 6)]
		total = total + b
		logs[#logs + 1] = { text = label, bonus = b, kind = 1 }
	end

	st.score = math.min(st.score + total, 2147483647)

	local newPlayerRank = TK.GetPlayerRankIndex(st.kills, st.score)
	local playerRankedUp = newPlayerRank > prevPlayerRank

	if playerRankedUp then
		local newData = C.PlayerRanks[newPlayerRank]
		if newData then
			st.score = math.min(st.score + C.PlayerRankBonus, 2147483647)
			if C.PlayerRankShowInLogs then
				logs[#logs + 1] = { text = C.Labels.PlayerRankUp .. ": " .. newData.name,
					bonus = C.PlayerRankBonus, kind = 4 }
			end
			if C.PlayerRankAnnounce then
				killer:ChatPrint("[TactiKill] Rank up: " .. newData.name .. "!")
			end
		end
	end

	if rankedUp then
		st.score = math.min(st.score + C.RankUpBonus, 2147483647)
		logs[#logs + 1] = { text = C.Labels.RankUp, bonus = C.RankUpBonus, kind = 2 }
	end

	TK.Debug("%s killed %s | +%d | streak %d rank %d prank %d wep %s | hs=%s",
		killer:Nick(), tostring(victim), total, st.streak, st.rank,
		newPlayerRank, wepClass, tostring(headshot))

	local hp    = killer:Health()
	local maxHp = math.max(killer:GetMaxHealth(), 1)
	local deathsAtKill = st.deathsInRow or 0
	local victimClass = victim:GetClass()

	if headshot then
		st.headshotChain = (st.headshotChain or 0) + 1
		if st.headshotChain > (st.bestHeadshotChain or 0) then
			st.bestHeadshotChain = st.headshotChain
		end
	else
		st.headshotChain = 0
	end

	if hp <= 1 then
		st.lowHpKills = (st.lowHpKills or 0) + 1
		st.lowHpChain = (st.lowHpChain or 0) + 1
	else
		st.lowHpChain = 0
	end

	if hp >= maxHp then
		st.fullHpKills = (st.fullHpKills or 0) + 1
	end

	st.perfectKills = (st.perfectKills or 0) + 1
	if st.perfectKills > (st.bestPerfectStreak or 0) then
		st.bestPerfectStreak = st.perfectKills
	end

	if wepClass ~= st.lastWeapon then
		if not st.weaponChainSet then st.weaponChainSet = {} end
		st.weaponChainSet[wepClass] = true
		local uniq = 0
		for _ in pairs(st.weaponChainSet) do uniq = uniq + 1 end
		st.weaponChainUnique = uniq
	end
	st.lastWeapon = wepClass

	st.deathsInRow = 0

	local killEvent = {
		kind              = "kill",
		style             = style,
		step              = step,
		hp                = hp,
		maxHp             = maxHp,
		isHeadshot        = headshot,
		weaponClass       = wepClass,
		deathsInRowAtKill = deathsAtKill,
		victimClass       = victimClass,
		victim            = victim,
	}

	if TK.Achievements then
		TK.Achievements.Check(killer, killEvent)
	end
	if TK.Contracts and TK.Contracts.OnKill then
		TK.Contracts.OnKill(killer, killEvent)
	end

	Combo.Send(killer, logs)
	LastHit[victim] = nil
end

hook.Add("OnNPCKilled", "TACTIKILL_NPCKilled", function(npc, attacker, inflictor)
	TK.ProcessKill(npc, attacker, inflictor)
end)

hook.Add("PlayerDeath", "TACTIKILL_PlayerDeath", function(victim, inflictor, attacker)
	Combo.OnDeath(victim)
	if TK.PlayDeathSound then TK.PlayDeathSound(victim) end
	if C.CountPlayerKills then
		TK.ProcessKill(victim, attacker, inflictor)
	end
end)

hook.Add("PlayerSpawn", "TACTIKILL_Respawn", function(ply)
	Counted[ply] = nil
	LastHit[ply] = nil
	PendingHG[ply] = nil
end)

hook.Add("EntityRemoved", "TACTIKILL_Cleanup", function(ent)
	if Counted[ent]   then Counted[ent] = nil end
	if LastHit[ent]   then LastHit[ent] = nil end
	if PendingHG[ent] then PendingHG[ent] = nil end
end)