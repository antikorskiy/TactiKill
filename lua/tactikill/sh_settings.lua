local TK = TACTIKILL
local C  = TK.Config

TK.SettingsList     = {}
TK.SettingsById     = {}
TK.SettingsDefaults = {}

local function add(path, typ, lo, hi, group, label, dec, enum)
	local parts = {}
	for i, p in ipairs(path) do parts[i] = tostring(p) end
	local def = {
		id = table.concat(parts, "."), path = path, type = typ,
		lo = lo, hi = hi, group = group, label = label,
		dec = dec or (typ == "int" and 0 or 2), enum = enum,
	}
	TK.SettingsList[#TK.SettingsList + 1] = def
	TK.SettingsById[def.id] = def
	return def
end

local G_SCORE, G_BONUS, G_DETECT = "Score", "Style bonuses", "Style detection"
local G_MULTI, G_TIMEOUT, G_THRESH = "Multikill", "Combo rank timeouts (s)", "Combo rank thresholds (killstreak)"
local G_DECAY = "Combo decay, death & sound"
local G_RSHAKE, G_SHAKE = "Screen shake: strength per rank", "Screen shake: global"
local G_PRANKS = "Player ranks"
local G_LOGS, G_GEN = "Style logs", "Rules, session and admin"
local G_EVENTS = "Random events"
local G_DEATH = "Death screen"

add({ "KillScore" },              "int", 0, 100000, G_SCORE, "Normal kill score")
add({ "HeadshotMultiplier" },     "num", 1, 20,     G_SCORE, "Headshot multiplier")
add({ "RankUpBonus" },            "int", 0, 100000, G_SCORE, "Bonus for reaching a new combo rank")
add({ "PlayerRankBonus" },        "int", 0, 100000, G_SCORE, "Bonus for reaching a new player rank")
add({ "PlayerRankScorePerKill" }, "num", 0, 1000,   G_SCORE, "Player rank score threshold per kill (auto)")

add({ "Bonus", "Airborne" },   "int", 0, 100000, G_BONUS, "Airborne kill")
add({ "Bonus", "Slide" },      "int", 0, 100000, G_BONUS, "Slide kill")
add({ "Bonus", "SlowMo" },     "int", 0, 100000, G_BONUS, "Slow-mo kill")
add({ "Bonus", "PointBlank" }, "int", 0, 100000, G_BONUS, "Point blank")
add({ "Bonus", "LongRange" },  "int", 0, 100000, G_BONUS, "Long range")
add({ "Bonus", "Prop" },       "int", 0, 100000, G_BONUS, "Prop kill")

add({ "PointBlankDistance" },  "num", 1, 2000,   G_DETECT, "Point blank distance (units)", 0)
add({ "LongRangeDistance" },   "num", 100, 10000, G_DETECT, "Long range distance (units)", 0)
add({ "SlideMinSpeed" },       "num", 1, 1000,   G_DETECT, "Slide minimum speed", 0)
add({ "SlowMoThreshold" },     "num", 0.05, 1,   G_DETECT, "Slow-mo timescale threshold")
add({ "PropAttackerTimeout" }, "num", 0.5, 30,   G_DETECT, "Prop owner timeout (s)", 1)

add({ "MultikillWindow" },     "num", 0.5, 10,   G_MULTI, "Multikill chain window (s)", 1)
add({ "MultikillBonus", 2 },   "int", 0, 100000, G_MULTI, "Double kill bonus")
add({ "MultikillBonus", 3 },   "int", 0, 100000, G_MULTI, "Triple kill bonus")
add({ "MultikillBonus4Plus" }, "int", 0, 100000, G_MULTI, "Squad wipe (4+) bonus per kill")

for i, r in ipairs(C.Ranks) do
	add({ "Ranks", i, "timeout" }, "num", 0.5, 60, G_TIMEOUT, r.name .. " timeout", 1)
end
for i, r in ipairs(C.Ranks) do
	local d = add({ "Ranks", i, "min" }, "int", 1, 99, G_THRESH, r.name .. " from killstreak")
	d.rankMin = i
end
for i, r in ipairs(C.Ranks) do
	add({ "Ranks", i, "shake" }, "num", 0, 5, G_RSHAKE, r.name .. " shake")
end

add({ "ComboDecayEnabled" },      "bool", nil, nil, G_DECAY, "Rolling combo decay (rank by rank)")
add({ "ComboDecayFactor" },       "num", 0.1, 1.0,  G_DECAY, "Decay speed factor (lower = faster)", 2)
add({ "ComboDecayMinTime" },      "num", 0.1, 5,    G_DECAY, "Minimum decay step time (s)", 1)
add({ "ComboDecayLog" },          "bool", nil, nil, G_DECAY, "Show COMBO DECAY in logs")
add({ "DeathResetsCombo" },       "bool", nil, nil, G_DECAY, "Death resets combo")
add({ "DeathComboLostLog" },      "bool", nil, nil, G_DECAY, "Show COMBO LOST on death")
add({ "ComboRankUpSoundEnabled" }, "bool", nil, nil, G_DECAY, "Play sound on combo rank up")
local sndDef = add({ "ComboRankUpSound" }, "string", nil, nil, G_DECAY, "Combo rank up sound path")
sndDef.maxlen  = 256
sndDef.pattern = "^sound/[%w_/%-%.]+%.(mp3|wav|ogg)$"

add({ "PlayerRankAnnounce" },   "bool", nil, nil, G_PRANKS, "Chat announcement on player rank up")
add({ "PlayerRankShowInLogs" }, "bool", nil, nil, G_PRANKS, "Show player rank up in style logs")
add({ "RedAccentFromRank" },    "int", 1, #C.Ranks, G_PRANKS, "Red HUD accent starting at combo rank index")

add({ "ScreenShakeEnabled" },      "bool", nil, nil, G_SHAKE, "Screen shake enabled")
add({ "ScreenShakeMultiplier" },   "num", 0, 3,      G_SHAKE, "Global multiplier")
add({ "ScreenShakeMaxIntensity" }, "num", 0, 10,     G_SHAKE, "Max intensity")
add({ "RankUpShakeEnabled" },      "bool", nil, nil, G_SHAKE, "Rank-up impulse enabled")
add({ "ShakeSustainedFactor" },    "num", 0, 1,      G_SHAKE, "Sustained share of rank strength")
add({ "RankUpImpulseScale" },      "num", 0, 5,      G_SHAKE, "Rank-up impulse scale")
add({ "ShakeImpulseDecay" },       "num", 0.5, 30,   G_SHAKE, "Impulse decay speed", 1)
add({ "ShakeSmoothing" },          "num", 0.5, 30,   G_SHAKE, "Rank follow speed", 1)
add({ "ShakeUnitsPerIntensity" },  "num", 0, 2,      G_SHAKE, "Camera units per 1.0 intensity")
add({ "ShakeMaxOffsetUnits" },     "num", 0, 5,      G_SHAKE, "Max camera offset (units)")
add({ "ShakeFrequency" },          "num", 0.1, 5,    G_SHAKE, "Vibration speed")
add({ "ShakeRollDegrees" },        "num", 0, 2,      G_SHAKE, "Roll degrees per intensity")

add({ "MaxLogs" },      "int", 1, 20,    G_LOGS, "Max visible logs")
add({ "LogLifetime" },  "num", 0.5, 30,  G_LOGS, "Log lifetime (s)", 1)
add({ "ShowLogBonus" }, "bool", nil, nil, G_LOGS, "Show +SCORE in logs")
add({ "LogComboLost" }, "bool", nil, nil, G_LOGS, "Log combo lost")

add({ "Events", "Enabled" },        "bool", nil, nil, G_EVENTS, "Random events enabled")
add({ "Events", "MinPlayers" },     "int", 0, 32,    G_EVENTS, "Minimum players for events")
add({ "Events", "CheckInterval" },  "num", 15, 600,  G_EVENTS, "Event check interval (s)", 0)
add({ "Events", "Chance" },         "num", 0, 1,     G_EVENTS, "Event chance per check", 2)

add({ "Events", "Bombardment", "BeamRadius" },      "num", 500, 8000, G_EVENTS, "Bombardment radius (u)", 0)
add({ "Events", "Bombardment", "ChargeTime" },      "num", 1, 30,     G_EVENTS, "Bombardment charge time (s)", 1)
add({ "Events", "Bombardment", "FireInterval" },    "num", 0.2, 20,   G_EVENTS, "Bombardment fire interval (s)", 1)
add({ "Events", "Bombardment", "ExplosionRadius" }, "num", 50, 2000,  G_EVENTS, "Bombardment explosion radius", 0)
add({ "Events", "Bombardment", "ExplosionDamage" }, "num", 10, 2000,  G_EVENTS, "Bombardment explosion damage", 0)

add({ "Events", "Airdrop", "DropRadius" },   "num", 500, 8000, G_EVENTS, "Airdrop radius (u)", 0)
add({ "Events", "Airdrop", "FallTime" },     "num", 3, 120,   G_EVENTS, "Airdrop timer (s)", 1)
add({ "Events", "Airdrop", "AmmoChance" },   "num", 0, 1,     G_EVENTS, "Chance for ammo (rest = health)", 2)
add({ "Events", "Airdrop", "AmmoAmount" },   "int", 1, 10000, G_EVENTS, "Ammo amount in airdrop")
add({ "Events", "Airdrop", "HealthAmount" }, "int", 1, 1000,  G_EVENTS, "Health amount in airdrop")
add({ "Events", "Airdrop", "ArtyEnabled" }, "bool", nil, nil, G_EVENTS, "Allow artillery designator in airdrop")
add({ "Events", "Airdrop", "ArtyChance" },  "num", 0, 1,     G_EVENTS, "Artillery chance per airdrop", 2)

add({ "DeathScreen", "Enabled" },  "bool", nil, nil, G_DEATH, "Enable death screen")
add({ "DeathScreen", "Duration" }, "num", 1, 30, G_DEATH, "Death screen duration (s)", 1)
add({ "DeathScreen", "FadeIn" },   "num", 0.1, 3, G_DEATH, "Fade-in duration (s)", 2)
add({ "DeathScreen", "FadeOut" },  "num", 0.1, 3, G_DEATH, "Fade-out duration (s)", 2)

add({ "CountPlayerKills" },        "bool", nil, nil, G_GEN, "Count player kills (PvP)")
add({ "CountFriendlyNPCs" },       "bool", nil, nil, G_GEN, "Count friendly NPCs")
add({ "ResetKillstreakOnExpire" }, "bool", nil, nil, G_GEN, "Reset killstreak after full decay")
add({ "SessionShowOnHUD" },        "bool", nil, nil, G_GEN, "Session timer on HUD")
add({ "SessionAutoStart" },        "bool", nil, nil, G_GEN, "Auto-start session timer")
add({ "ResetAllowSelf" },          "bool", nil, nil, G_GEN, "Players may reset own stats")
add({ "ResetOthersLevel" },        "enum", nil, nil, G_GEN, "Level to reset others' stats", nil, { "admin", "superadmin" })
add({ "PersistenceEnabled" }, "bool", nil, nil, G_GEN, "Save player progress to SQLite")
add({ "Debug" },                   "bool", nil, nil, G_GEN, "Debug logging")

local function walk(path)
	local t = C
	for i = 1, #path - 1 do
		t = t[path[i]]
		if not istable(t) then return nil end
	end
	return t, path[#path]
end

function TK.GetSettingValue(def)
	local t, k = walk(def.path)
	if t then return t[k] end
end

for _, def in ipairs(TK.SettingsList) do
	TK.SettingsDefaults[def.id] = TK.GetSettingValue(def)
end

function TK.ParseValue(def, raw)
	if def.type == "bool" then return raw == "1" or raw == "true" end
	if def.type == "enum" or def.type == "string" then return raw end
	return tonumber(raw)
end

function TK.SerializeValue(def, v)
	if def.type == "bool" then return v and "1" or "0" end
	return tostring(v)
end

function TK.ApplySetting(def, value, force)
	local t, k = walk(def.path)
	if not t then return false end
	local v

	if def.type == "bool" then
		if value == true or value == 1 or value == "1" or value == "true" then v = true
		elseif value == false or value == 0 or value == "0" or value == "false" then v = false
		else return false end
	elseif def.type == "enum" then
		if not table.HasValue(def.enum, value) then return false end
		v = value
	elseif def.type == "string" then
		if type(value) ~= "string" or value == "" then return false end
		if def.maxlen and #value > def.maxlen then return false end
		if def.pattern and not string.match(value, def.pattern) then return false end
		v = value
	else
		value = tonumber(value)
		if not value or value ~= value then return false end
		local lo, hi = def.lo, def.hi
		if def.rankMin and not force then
			local i = def.rankMin
			local prev = i > 1 and C.Ranks[i - 1].min or 0
			local nxt = C.Ranks[i + 1] and C.Ranks[i + 1].min or math.huge
			lo = math.max(lo, prev + 1)
			hi = math.min(hi, nxt - 1)
			if lo > hi then return false end
		end
		value = math.Clamp(value, lo, hi)
		if def.type == "int" then value = math.floor(value + 0.5) end
		v = value
	end

	t[k] = v

	if def.id == "PlayerRankScorePerKill" then
		for _, r in ipairs(C.PlayerRanks) do
			if r.autoScore then r.score = math.floor(r.min * C.PlayerRankScorePerKill) end
		end
	end

	return true, v
end

function TK.RankMinsValid()
	local prev = 0
	for _, r in ipairs(C.Ranks) do
		if r.min <= prev then return false end
		prev = r.min
	end
	return true
end

function TK.RestoreRankMins()
	for _, def in ipairs(TK.SettingsList) do
		if def.rankMin then TK.ApplySetting(def, TK.SettingsDefaults[def.id], true) end
	end
end

function TK.CanEditSettings(ply)
	if not IsValid(ply) then return SERVER end
	if C.SettingsEditLevel == "superadmin" then return ply:IsSuperAdmin() end
	return ply:IsAdmin()
end