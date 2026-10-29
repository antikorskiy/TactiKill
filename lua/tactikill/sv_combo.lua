local TK = TACTIKILL
local C  = TK.Config

util.AddNetworkString("TACTIKILL_Update")
util.AddNetworkString("TACTIKILL_RequestSync")
util.AddNetworkString("TACTIKILL_RequestScoreboard")
util.AddNetworkString("TACTIKILL_Scoreboard")
util.AddNetworkString("TACTIKILL_RequestDossier")
util.AddNetworkString("TACTIKILL_Dossier")

TK.Combo = {}
local Combo = TK.Combo

local States = setmetatable({}, { __mode = "k" })
local Active, activeCount = {}, 0
local TIMER_ID = "TACTIKILL_ComboExpiry"
local SyncCooldown = setmetatable({}, { __mode = "k" })
local ScoreboardCooldown = setmetatable({}, { __mode = "k" })

local AGENT_LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

local function RandLetter()
	local n = math.random(#AGENT_LETTERS)
	return string.sub(AGENT_LETTERS, n, n)
end

local function GenerateAgentId()
	return string.format("%s%s%s-%03d-%s",
		RandLetter(), RandLetter(), RandLetter(),
		math.random(100, 999),
		RandLetter())
end

function Combo.Get(ply)
	local st = States[ply]
	if not st then
		st = {
			kills = 0, score = 0, streak = 0, rank = 0, expire = 0, mkCount = 0, mkLast = 0,
			deaths = 0, headshots = 0, multikills = 0, bestStreak = 0,
			distanceSum = 0, distanceCount = 0, distanceMax = 0, distanceMin = 0,
			weaponKills = {}, favWeapon = nil, favWeaponKills = 0,
			shots = 0, hits = 0, hgCounts = {},
			achievements = {},

			headshotChain = 0, bestHeadshotChain = 0,
			perfectKills = 0,  bestPerfectStreak = 0,
			lowHpKills = 0,    lowHpChain = 0,
			fullHpKills = 0,
			deathsInRow = 0,
			lastWeapon = "",
			weaponChainSet = {}, weaponChainUnique = 0,

			bestRank = 0,
			bestMultikill = 0,

			agentId = nil,
			contractScore = 0,
			contracts = nil,
		}

		States[ply] = st
	end
	return st
end

function Combo.GetAgentId(ply)
	local st = Combo.Get(ply)
	if not st.agentId then
		st.agentId = GenerateAgentId()
		if TK.Persistence then TK.Persistence.MarkDirty(ply) end
	end
	return st.agentId
end

function Combo.Send(ply, logs)
	if not IsValid(ply) or ply:IsBot() then return end
	local st = States[ply]
	if not st then return end

	local remaining = 0
	if st.expire > 0 then remaining = math.max(st.expire - CurTime(), 0) end
	local rankData = st.rank > 0 and C.Ranks[st.rank] or nil
	local duration = rankData and rankData.timeout or 0
	local n = logs and math.min(#logs, 31) or 0

	net.Start("TACTIKILL_Update")
		net.WriteUInt(st.kills, 32)
		net.WriteUInt(st.deaths, 32)
		net.WriteInt(st.score, 32)
		net.WriteUInt(math.Clamp(st.streak, 0, 65535), 16)
		net.WriteUInt(st.rank, 8)
		net.WriteUInt(TK.GetPlayerRankIndex(st.kills, st.score), 8)
		net.WriteUInt(math.Clamp(st.mkCount, 0, 255), 8)
		net.WriteFloat(remaining)
		net.WriteFloat(duration)
		net.WriteString(Combo.GetAgentId(ply))
		net.WriteUInt(n, 5)
		for i = 1, n do
			local lg = logs[i]
			net.WriteString(lg.text)
			net.WriteInt(math.Clamp(lg.bonus or 0, -32768, 32767), 16)
			net.WriteUInt(lg.kind or 0, 3)
		end
	net.Send(ply)
end

local HG_LABEL = {
	head = "HEAD", torso = "TORSO",
	larm = "L-ARM", rarm = "R-ARM",
	lleg = "L-LEG", rleg = "R-LEG",
	gear = "GEAR",
}

local function GetTopHitbox(st)
	if not st.hgCounts then return "" end
	local bestCat, bestCount = nil, 0
	for cat, cnt in pairs(st.hgCounts) do
		if cnt > bestCount then bestCat, bestCount = cat, cnt end
	end
	if not bestCat or bestCount == 0 then return "" end
	local total = st.hits or 0
	if total == 0 then return "" end
	local pct = math.floor(bestCount / total * 100 + 0.5)
	return string.format("%s %d%%", HG_LABEL[bestCat] or bestCat:upper(), pct)
end

function Combo.SendScoreboard(target)
	if not IsValid(target) or target:IsBot() then return end
	local players = player.GetAll()
	net.Start("TACTIKILL_Scoreboard")
		net.WriteUInt(#players, 6)
		for _, p in ipairs(players) do
			local st = Combo.Get(p)
			local wep = st.favWeapon or ""
			if wep ~= "" then
				local wepStored = weapons.GetStored(wep)
				if wepStored and wepStored.PrintName and wepStored.PrintName ~= "" then
					wep = wepStored.PrintName
				end
			end

			local curRank = TK.GetPlayerRankIndex(st.kills, st.score)
			local nextRank = curRank < #C.PlayerRanks and (curRank + 1) or 0

			local spm = 0
			local t = p:TimeConnected()
			if t > 30 then spm = math.floor(st.score / (t / 60) + 0.5) end

			net.WriteEntity(p)
			net.WriteUInt(st.kills, 32)
			net.WriteUInt(st.deaths, 32)
			net.WriteInt(st.score, 32)
			net.WriteUInt(curRank, 8)
			net.WriteUInt(nextRank, 8)
			net.WriteUInt(st.headshots, 32)
			net.WriteUInt(st.multikills, 32)
			net.WriteUInt(math.Clamp(st.streak, 0, 65535), 16)
			net.WriteUInt(math.Clamp(st.bestStreak, 0, 65535), 16)
			net.WriteUInt(math.Clamp(st.shots, 0, 4294967295), 32)
			net.WriteUInt(math.Clamp(st.hits, 0, 4294967295), 32)
			net.WriteUInt(math.Clamp(spm, 0, 65535), 16)
			net.WriteFloat(st.distanceSum)
			net.WriteUInt(st.distanceCount, 32)
			net.WriteFloat(st.distanceMax)
			net.WriteFloat(st.distanceMin)
			net.WriteString(wep)
			net.WriteUInt(math.Clamp(st.favWeaponKills, 0, 65535), 16)
			net.WriteString(GetTopHitbox(st))
		end
	net.Send(target)
end

net.Receive("TACTIKILL_RequestScoreboard", function(_, ply)
	if not IsValid(ply) then return end
	local now = CurTime()
	if (ScoreboardCooldown[ply] or 0) > now then return end
	ScoreboardCooldown[ply] = now + 0.5
	Combo.SendScoreboard(ply)
end)

net.Receive("TACTIKILL_RequestSync", function(_, ply)
	if not IsValid(ply) then return end
	local now = CurTime()
	if (SyncCooldown[ply] or 0) > now then return end
	SyncCooldown[ply] = now + 2

	Combo.Get(ply)
	if TK.Settings then TK.Settings.SendAll(ply) end
	Combo.ExpireIfDue(ply, now)
	Combo.Send(ply)
	TK.Timer.Send(ply)
end)

local tick

local function SetActive(ply, on)
	if on then
		if not Active[ply] then
			Active[ply] = true
			activeCount = activeCount + 1
			if activeCount == 1 then
				timer.Create(TIMER_ID, C.ExpiryCheckInterval, 0, function() tick() end)
			end
		end
	elseif Active[ply] then
		Active[ply] = nil
		activeCount = activeCount - 1
		if activeCount <= 0 then
			activeCount = 0
			timer.Remove(TIMER_ID)
		end
	end
end

local function FullExpire(ply, st, now, reason)
	local prevRank = st.rank
	st.rank = 0
	st.expire = 0
	if C.ResetKillstreakOnExpire then st.streak = 0 end
	SetActive(ply, false)

	local logs
	if prevRank > 0 and C.LogComboLost then
		local label = reason == "death" and C.Labels.ComboLostDeath or C.Labels.ComboLost
		logs = { { text = label, bonus = 0, kind = 3 } }
	end
	TK.Debug("combo expired: %s (from rank %d, %s)", tostring(ply), prevRank, tostring(reason))
	Combo.Send(ply, logs)
end

function Combo.ExpireIfDue(ply, now)
	local st = States[ply]
	if not st or st.expire <= 0 or now < st.expire then return false end

	if C.ComboDecayEnabled and st.rank > 1 then
		local newRank = st.rank - 1
		local rankData = C.Ranks[newRank]
		if rankData then
			local timeout = math.max(rankData.timeout * C.ComboDecayFactor, C.ComboDecayMinTime)
			st.rank = newRank
			st.streak = rankData.min
			st.expire = now + timeout

			local logs
			if C.ComboDecayLog then
				logs = { { text = C.Labels.ComboDecay .. ": " .. rankData.name, bonus = 0, kind = 3 } }
			end
			TK.Debug("combo decay: %s -> %s", tostring(ply), rankData.name)
			Combo.Send(ply, logs)
			return true
		end
	end

	FullExpire(ply, st, now, "expire")
	return true
end

tick = function()
	local now = CurTime()
	for ply in pairs(Active) do
		if IsValid(ply) then
			Combo.ExpireIfDue(ply, now)
		else
			Active[ply] = nil
			activeCount = math.max(activeCount - 1, 0)
		end
	end
	if activeCount <= 0 then timer.Remove(TIMER_ID) end
end

function Combo.RegisterKill(ply, now)
	local st = Combo.Get(ply)
	st.kills = st.kills + 1
	st.streak = st.streak + 1
	if st.streak > (st.bestStreak or 0) then st.bestStreak = st.streak end

	local oldRank = st.rank
	local newRank = TK.GetRankIndex(st.streak)
	st.rank = newRank
	if newRank > (st.bestRank or 0) then st.bestRank = newRank end

	if newRank > 0 and C.Ranks[newRank] then
		st.expire = now + C.Ranks[newRank].timeout
		SetActive(ply, true)
	end

	if TK.Persistence then TK.Persistence.MarkDirty(ply) end
	return st, newRank > oldRank
end

function Combo.RegisterMultikill(ply, now)
	local st = Combo.Get(ply)
	if st.mkLast > 0 and (now - st.mkLast) <= C.MultikillWindow then
		st.mkCount = st.mkCount + 1
	else
		st.mkCount = 1
	end
	st.mkLast = now
	if st.mkCount == 2 then st.multikills = (st.multikills or 0) + 1 end
	if st.mkCount > (st.bestMultikill or 0) then st.bestMultikill = st.mkCount end
	return st.mkCount
end

function Combo.OnDeath(ply)
	local st = Combo.Get(ply)
	st.deaths = (st.deaths or 0) + 1
	st.deathsInRow   = (st.deathsInRow or 0) + 1
	st.perfectKills  = 0
	st.headshotChain = 0
	st.lowHpChain    = 0
	st.lastWeapon    = ""
	st.weaponChainSet    = {}
	st.weaponChainUnique = 0

	st.agentId = nil

	if not C.DeathResetsCombo then
		if TK.Persistence then TK.Persistence.MarkDirty(ply) end
		Combo.Send(ply)
		return
	end

	local hadCombo = st.rank > 0 or st.streak > 0
	st.streak = 0
	st.rank = 0
	st.expire = 0
	st.mkCount = 0
	st.mkLast = 0
	SetActive(ply, false)

	local logs
	if hadCombo and C.DeathComboLostLog then
		logs = { { text = C.Labels.ComboLostDeath, bonus = 0, kind = 3 } }
	end
	TK.Debug("combo reset on death: %s", tostring(ply))
	if TK.Achievements then TK.Achievements.Check(ply, { kind = "death" }) end
	if TK.Contracts and TK.Contracts.OnDeath then TK.Contracts.OnDeath(ply) end
	Combo.Send(ply, logs)

	if TK.Persistence then TK.Persistence.MarkDirty(ply) end
end

function Combo.ResetStats(ply)
	local st = Combo.Get(ply)
	st.kills, st.score, st.streak, st.rank = 0, 0, 0, 0
	st.expire, st.mkCount, st.mkLast = 0, 0, 0
	st.deaths, st.headshots, st.multikills, st.bestStreak = 0, 0, 0, 0
	st.distanceSum, st.distanceCount, st.distanceMax, st.distanceMin = 0, 0, 0, 0
	st.weaponKills, st.favWeapon, st.favWeaponKills = {}, nil, 0
	st.shots, st.hits, st.hgCounts = 0, 0, {}
	st.headshotChain, st.bestHeadshotChain = 0, 0
	st.perfectKills, st.bestPerfectStreak = 0, 0
	st.lowHpKills, st.lowHpChain = 0, 0
	st.fullHpKills = 0
	st.deathsInRow = 0
	st.lastWeapon = ""
	st.weaponChainSet = {}
	st.weaponChainUnique = 0
	st.bestRank, st.bestMultikill = 0, 0
	st.contractScore = 0
	st.contracts = nil 
	SetActive(ply, false)
	Combo.Send(ply)
end

hook.Add("PlayerInitialSpawn", "TACTIKILL_Join", function(ply)
	Combo.Get(ply)
	if C.SessionAutoStart then TK.Timer.Start(ply) end
end)

hook.Add("PlayerSpawn", "TACTIKILL_ResetOnSpawn", function(ply)
	local st = States[ply]
	if not st then return end
	if st.rank > 0 or st.streak > 0 then
		st.streak, st.rank, st.expire, st.mkCount, st.mkLast = 0, 0, 0, 0, 0
		SetActive(ply, false)
		Combo.Send(ply)
	end
end)

hook.Add("PlayerDisconnected", "TACTIKILL_Leave", function(ply)
	if TK.Persistence then TK.Persistence.Save(ply) end
	SetActive(ply, false)
	States[ply] = nil
	SyncCooldown[ply] = nil
	ScoreboardCooldown[ply] = nil
	TK.Timer.Clear(ply)
end)

net.Receive("TACTIKILL_RequestDossier", function(_, ply)
	if not IsValid(ply) then return end
	local st = Combo.Get(ply)
	net.Start("TACTIKILL_Dossier")
		net.WriteUInt(st.kills, 32)
		net.WriteUInt(st.deaths, 32)
		net.WriteInt(st.score, 32)
		net.WriteUInt(st.headshots, 32)
		net.WriteUInt(st.multikills, 32)
		net.WriteUInt(math.Clamp(st.bestStreak, 0, 65535), 16)
		net.WriteUInt(math.Clamp(st.shots, 0, 4294967295), 32)
		net.WriteUInt(math.Clamp(st.hits, 0, 4294967295), 32)
		net.WriteFloat(st.distanceSum)
		net.WriteUInt(st.distanceCount, 32)
		net.WriteFloat(st.distanceMax)
		net.WriteFloat(st.distanceMin)
		net.WriteString(st.favWeapon or "")
		net.WriteUInt(math.Clamp(st.favWeaponKills, 0, 65535), 16)
		net.WriteInt(st.contractScore or 0, 32)
		net.WriteUInt(TK.GetPlayerRankIndex(st.kills, st.score), 8)
	net.Send(ply)
end)