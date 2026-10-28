local TK = TACTIKILL
local C  = TK.Config

TK.Persistence = {}
local P = TK.Persistence

local available = false
local dirty = {}

local function InitDB()
	if not sql or not sql.Query then
		print("[TACTIKILL] SQL not available - progress will not be saved")
		return
	end

	sql.Query([[CREATE TABLE IF NOT EXISTS tactikill_players (
		steamid TEXT PRIMARY KEY,
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

	if sql.LastError() then
		print("[TACTIKILL] SQL init failed: " .. sql.LastError())
		return
	end

	available = true
	print("[TACTIKILL] SQLite ready")
end

local function ToJson(tbl)
	return util.TableToJSON(tbl or {}, false) or "{}"
end

local function FromJson(str)
	if not str or str == "" then return {} end
	local t = util.JSONToTable(str)
	return istable(t) and t or {}
end

local function GetSid(ply)
	local sid = ply:SteamID64()
	if not sid or sid == "" then sid = ply:SteamID() end
	return sid
end

function P.Load(ply)
	if not available or not C.PersistenceEnabled then return end
	if not IsValid(ply) or ply:IsBot() then return end

	local sid = GetSid(ply)
	if not sid or sid == "" then return end

	local row = sql.QueryRow("SELECT * FROM tactikill_players WHERE steamid = " .. sql.SQLStr(sid))
	if not row then
		TK.Debug("no saved progress for %s (%s)", ply:Nick(), sid)
		return
	end

	local st = TK.Combo.Get(ply)

	st.kills           = math.max(tonumber(row.kills) or 0, 0)
	st.deaths          = math.max(tonumber(row.deaths) or 0, 0)
	st.score           = math.max(tonumber(row.score) or 0, 0)
	st.headshots       = math.max(tonumber(row.headshots) or 0, 0)
	st.multikills      = math.max(tonumber(row.multikills) or 0, 0)
	st.bestStreak      = math.max(tonumber(row.best_streak) or 0, 0)
	st.shots           = math.max(tonumber(row.shots) or 0, 0)
	st.hits            = math.max(tonumber(row.hits) or 0, 0)
	st.distanceSum     = tonumber(row.distance_sum) or 0
	st.distanceCount   = math.max(tonumber(row.distance_count) or 0, 0)
	st.distanceMax     = tonumber(row.distance_max) or 0
	st.distanceMin     = tonumber(row.distance_min) or 0
	st.favWeapon       = (row.fav_weapon ~= "" and row.fav_weapon) or nil
	st.favWeaponKills  = math.max(tonumber(row.fav_weapon_kills) or 0, 0)
	st.weaponKills     = FromJson(row.weapon_kills)
	st.hgCounts        = FromJson(row.hg_counts)

	st.streak = 0
	st.rank = 0
	st.expire = 0
	st.mkCount = 0
	st.mkLast = 0

	TK.Debug("loaded progress for %s: %d kills, %d score, %d deaths",
		ply:Nick(), st.kills, st.score, st.deaths)

	if TK.Combo and TK.Combo.Send then
		TK.Combo.Send(ply)
	end
end

function P.Save(ply)
	if not available or not C.PersistenceEnabled then return end
	if not IsValid(ply) or ply:IsBot() then return end

	local sid = GetSid(ply)
	if not sid or sid == "" then return end

	local st = TK.Combo.Get(ply)

	local q = string.format([[
		REPLACE INTO tactikill_players (
			steamid, kills, deaths, score, headshots, multikills, best_streak,
			shots, hits, distance_sum, distance_count, distance_max, distance_min,
			weapon_kills, fav_weapon, fav_weapon_kills, hg_counts, last_seen
		) VALUES (%s, %d, %d, %d, %d, %d, %d, %d, %d, %f, %d, %f, %f, %s, %s, %d, %s, %d)
	]],
		sql.SQLStr(sid),
		math.floor(st.kills or 0),
		math.floor(st.deaths or 0),
		math.floor(st.score or 0),
		math.floor(st.headshots or 0),
		math.floor(st.multikills or 0),
		math.floor(st.bestStreak or 0),
		math.floor(st.shots or 0),
		math.floor(st.hits or 0),
		st.distanceSum or 0,
		math.floor(st.distanceCount or 0),
		st.distanceMax or 0,
		st.distanceMin or 0,
		sql.SQLStr(ToJson(st.weaponKills)),
		sql.SQLStr(st.favWeapon or ""),
		math.floor(st.favWeaponKills or 0),
		sql.SQLStr(ToJson(st.hgCounts)),
		os.time()
	)

	sql.Query(q)
	if sql.LastError() then
		print("[TACTIKILL] Save failed for " .. ply:Nick() .. ": " .. sql.LastError())
	else
		TK.Debug("saved progress for %s", ply:Nick())
	end

	dirty[ply] = nil
end

function P.Delete(ply)
	if not available then return end
	if not IsValid(ply) or ply:IsBot() then return end
	local sid = GetSid(ply)
	if not sid or sid == "" then return end
	sql.Query("DELETE FROM tactikill_players WHERE steamid = " .. sql.SQLStr(sid))
	TK.Debug("deleted saved progress for %s", ply:Nick())
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
	for ply, _ in pairs(dirty) do
		if IsValid(ply) then P.Save(ply) end
	end
end)

hook.Add("ShutDown", "TACTIKILL_Persistence_Shutdown", function()
	if not available or not C.PersistenceEnabled then return end
	for _, ply in ipairs(player.GetAll()) do
		P.Save(ply)
	end
end)

InitDB()