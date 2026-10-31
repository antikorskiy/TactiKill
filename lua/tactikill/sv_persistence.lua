local TK = TACTIKILL
local C  = TK.Config

TK.Persistence = {}
local P = TK.Persistence

local available = false
local dirty     = setmetatable({}, { __mode = "k" })

local ANON_SID64    = "76561197960265728"
local ANON_SID      = "STEAM_0:0:0"
local PENDING_SID   = "STEAM_ID_PENDING"

local function SafeNum(v, def)
	v = tonumber(v)
	if not v or v ~= v then return def or 0 end
	if v == math.huge or v == -math.huge then return def or 0 end
	return v
end

local function SafeInt(v, def)
	return math.floor(SafeNum(v, def))
end

local function SafeJson(tbl)
	if not istable(tbl) then return "{}" end
	local ok, res = pcall(util.TableToJSON, tbl, false)
	if not ok or not isstring(res) or res == "" then return "{}" end
	return res
end

local function FromJson(str)
	if not isstring(str) or str == "" then return {} end
	local t = util.JSONToTable(str)
	return istable(t) and t or {}
end

local function HashKey(s)
	if util and util.md5 then return util.md5(s) end
	local h = 5381
	for i = 1, #s do h = ((h * 33) + s:byte(i)) % 4294967296 end
	return string.format("%08X", h)
end

local function GetSid(ply)
	local sid64 = ply:SteamID64()
	if sid64 and sid64 ~= "" and sid64 ~= "0" and sid64 ~= ANON_SID64 then
		return sid64
	end

	local sid = ply:SteamID()
	if sid and sid ~= ""
		and sid ~= ANON_SID
		and sid ~= PENDING_SID
		and sid ~= "UNKNOWN"
	then
		return sid
	end

	local ip = ply:IPAddress() or ""
	if ip ~= "" then ip = string.match(ip, "^([^:]+)") or ip end
	if ip == "" or ip == "loopback" or ip == "localhost" or ip == "127.0.0.1" then
		ip = "0"
	end
	return "H:" .. HashKey(ip .. "|" .. string.lower(ply:Nick() or ""))
end

local function InitDB()
	if not sql or not sql.Query then
		print("[TACTIKILL] SQL not available - progress will not be saved")
		return
	end

	sql.Query([[CREATE TABLE IF NOT EXISTS tactikill_players (
		steamid TEXT PRIMARY KEY,
		nick TEXT DEFAULT '',
		kills INTEGER DEFAULT 0,
		deaths INTEGER DEFAULT 0,
		score INTEGER DEFAULT 0,
		headshots INTEGER DEFAULT 0,
		multikills INTEGER DEFAULT 0,
		best_streak INTEGER DEFAULT 0,
		shots INTEGER DEFAULT 0,
		hits INTEGER DEFAULT 0,
		distance_sum REAL DEFAULT 0,
		distance_count INTEGER DEFAULT 0,
		distance_max REAL DEFAULT 0,
		distance_min REAL DEFAULT 0,
		weapon_kills TEXT DEFAULT '{}',
		fav_weapon TEXT DEFAULT '',
		fav_weapon_kills INTEGER DEFAULT 0,
		hg_counts TEXT DEFAULT '{}',
		last_seen INTEGER DEFAULT 0
	)]])

	local cols = sql.Query("PRAGMA table_info(tactikill_players)") or {}
	local hasAch, hasTrials, hasNick = false, false, false
	for _, col in ipairs(cols) do
		if col.name == "achievements" then hasAch = true end
		if col.name == "trials"       then hasTrials = true end
		if col.name == "nick"         then hasNick = true end
	end
	if not hasAch then
		sql.Query("ALTER TABLE tactikill_players ADD COLUMN achievements TEXT DEFAULT '{}'")
		print("[TACTIKILL] Added 'achievements' column")
	end
	if not hasTrials then
		sql.Query("ALTER TABLE tactikill_players ADD COLUMN trials TEXT DEFAULT '{}'")
		print("[TACTIKILL] Added 'trials' column")
	end
	if not hasNick then
		sql.Query("ALTER TABLE tactikill_players ADD COLUMN nick TEXT DEFAULT ''")
		print("[TACTIKILL] Added 'nick' column")
	end

	sql.Query([[
		DELETE FROM tactikill_players
		WHERE steamid IN ('0','','STEAM_0:0:0','STEAM_ID_PENDING','UNKNOWN','76561197960265728')
	]])

	if sql.LastError() then
		print("[TACTIKILL] SQL init failed: " .. sql.LastError())
		return
	end

	available = true
	print("[TACTIKILL] SQLite ready")
end

function P.Load(ply)
	if not available or not C.PersistenceEnabled then return end
	if not IsValid(ply) or ply:IsBot() then return end

	local sid = GetSid(ply)
	if not sid or sid == "" then return end

	local row = sql.QueryRow("SELECT * FROM tactikill_players WHERE steamid = " .. sql.SQLStr(sid))
	if not row then
		TK.Debug("no saved progress for %s (%s)", ply:Nick(), sid)
		if TK.Leaderboard and TK.Leaderboard.Invalidate then TK.Leaderboard.Invalidate() end
		return
	end

	local currentNick = string.sub(ply:Nick() or "", 1, 64)
	if currentNick ~= "" and (row.nick == nil or row.nick == "" or row.nick ~= currentNick) then
		sql.Query("UPDATE tactikill_players SET nick = " .. sql.SQLStr(currentNick)
			.. " WHERE steamid = " .. sql.SQLStr(sid))
		row.nick = currentNick
	end

	local st = TK.Combo.Get(ply)

	st.kills          = math.max(SafeInt(row.kills), 0)
	st.deaths         = math.max(SafeInt(row.deaths), 0)
	st.score          = math.max(SafeInt(row.score), 0)
	st.headshots      = math.max(SafeInt(row.headshots), 0)
	st.multikills     = math.max(SafeInt(row.multikills), 0)
	st.bestStreak     = math.max(SafeInt(row.best_streak), 0)
	st.shots          = math.max(SafeInt(row.shots), 0)
	st.hits           = math.max(SafeInt(row.hits), 0)
	st.distanceSum    = math.max(SafeNum(row.distance_sum), 0)
	st.distanceCount  = math.max(SafeInt(row.distance_count), 0)
	st.distanceMax    = math.max(SafeNum(row.distance_max), 0)
	st.distanceMin    = math.max(SafeNum(row.distance_min), 0)
	st.favWeapon      = (isstring(row.fav_weapon) and row.fav_weapon ~= "") and row.fav_weapon or nil
	st.favWeaponKills = math.max(SafeInt(row.fav_weapon_kills), 0)
	st.weaponKills    = FromJson(row.weapon_kills)
	st.hgCounts       = FromJson(row.hg_counts)
	st.achievements   = FromJson(row.achievements)

	st.streak, st.rank, st.expire, st.mkCount, st.mkLast = 0, 0, 0, 0, 0

	local trials = FromJson(row.trials)
	st.bestHeadshotChain = math.max(SafeInt(trials.bestHeadshotChain), 0)
	st.bestPerfectStreak = math.max(SafeInt(trials.bestPerfectStreak), 0)
	st.lowHpKills        = math.max(SafeInt(trials.lowHpKills), 0)
	st.fullHpKills       = math.max(SafeInt(trials.fullHpKills), 0)
	st.bestRank          = math.max(SafeInt(trials.bestRank), 0)
	st.bestMultikill     = math.max(SafeInt(trials.bestMultikill), 0)

	if isstring(trials.agentId)
		and string.match(trials.agentId, "^%u%u%u%-%d%d%d%-%u$")
	then
		st.agentId = trials.agentId
	else
		st.agentId = nil
	end

	st.contractScore = SafeInt(trials.contractScore)

	if istable(trials.contracts) and istable(trials.contracts.slots) then
		local slots = {}
		for _, c in ipairs(trials.contracts.slots) do
			if istable(c) and isstring(c.templateId) and isstring(c.customerId)
				and isnumber(c.target) and isnumber(c.progress) and isnumber(c.difficulty)
			then
				slots[#slots + 1] = c
			end
		end
		st.contracts = { slots = slots, refreshAt = 0 }
	else
		st.contracts = nil
	end

	TK.Debug("loaded progress for %s (%s): %d kills, %d score",
		ply:Nick(), sid, st.kills, st.score)

	if TK.Achievements and TK.Achievements.Check then
		TK.Achievements.Check(ply, { kind = "load" }, true)
	end

	if TK.Combo and TK.Combo.Send then TK.Combo.Send(ply) end
end

function P.Save(ply)
	if not available or not C.PersistenceEnabled then return end
	if not IsValid(ply) or ply:IsBot() then return end

	local sid = GetSid(ply)
	if not sid or sid == "" then return end

	local st = TK.Combo.Get(ply)
	local fav = isstring(st.favWeapon) and st.favWeapon or ""

	local q = string.format([[
		REPLACE INTO tactikill_players (
			steamid, nick, kills, deaths, score, headshots, multikills, best_streak,
			shots, hits, distance_sum, distance_count, distance_max, distance_min,
			weapon_kills, fav_weapon, fav_weapon_kills, hg_counts,
			achievements, trials, last_seen
		) VALUES (%s, %s, %d, %d, %d, %d, %d, %d, %d, %d, %f, %d, %f, %f,
		          %s, %s, %d, %s, %s, %s, %d)
	]],
		sql.SQLStr(sid),
		sql.SQLStr(string.sub(ply:Nick() or "", 1, 64)),
		SafeInt(st.kills), SafeInt(st.deaths), SafeInt(st.score),
		SafeInt(st.headshots), SafeInt(st.multikills), SafeInt(st.bestStreak),
		SafeInt(st.shots), SafeInt(st.hits),
		SafeNum(st.distanceSum), SafeInt(st.distanceCount),
		SafeNum(st.distanceMax), SafeNum(st.distanceMin),
		sql.SQLStr(SafeJson(st.weaponKills)),
		sql.SQLStr(fav),
		SafeInt(st.favWeaponKills),
		sql.SQLStr(SafeJson(st.hgCounts)),
		sql.SQLStr(SafeJson(st.achievements)),
		sql.SQLStr(SafeJson({
			bestHeadshotChain = SafeInt(st.bestHeadshotChain),
			bestPerfectStreak = SafeInt(st.bestPerfectStreak),
			lowHpKills        = SafeInt(st.lowHpKills),
			fullHpKills       = SafeInt(st.fullHpKills),
			bestRank          = SafeInt(st.bestRank),
			bestMultikill     = SafeInt(st.bestMultikill),
			agentId           = isstring(st.agentId) and st.agentId or "",
			contractScore     = SafeInt(st.contractScore),
			contracts         = st.contracts or {},
		})),
		SafeInt(os.time())
	)

	sql.Query(q)
	if sql.LastError() then
		print("[TACTIKILL] Save failed for " .. ply:Nick() .. " (" .. sid .. "): " .. sql.LastError())
		if C.Debug then print(q) end
	else
		TK.Debug("saved progress for %s", ply:Nick())
		if TK.Leaderboard and TK.Leaderboard.Invalidate then
			TK.Leaderboard.Invalidate()
		end
	end
	dirty[ply] = nil
end

function P.Available()
	return available and C.PersistenceEnabled
end

function P.Delete(ply)
	if not available or not IsValid(ply) or ply:IsBot() then return end
	local sid = GetSid(ply)
	if not sid or sid == "" then return end
	sql.Query("DELETE FROM tactikill_players WHERE steamid = " .. sql.SQLStr(sid))
end

function P.MarkDirty(ply)
	if not available or not C.PersistenceEnabled then return end
	if IsValid(ply) then dirty[ply] = true end
end

hook.Add("PlayerInitialSpawn", "TACTIKILL_Persistence_Load", function(ply)
	P.Load(ply)
end)

timer.Create("TACTIKILL_AutoSave", 45, 0, function()
	if not available or not C.PersistenceEnabled then return end
	for ply in pairs(dirty) do
		if IsValid(ply) then P.Save(ply) end
	end
end)

hook.Add("ShutDown", "TACTIKILL_Persistence_Shutdown", function()
	if not available or not C.PersistenceEnabled then return end
	for _, ply in ipairs(player.GetAll()) do P.Save(ply) end
end)

InitDB()