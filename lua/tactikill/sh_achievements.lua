local TK = TACTIKILL
local C  = TK.Config

TK.Achievements = TK.Achievements or {}
local A = TK.Achievements

A.List = {}
A.ById = {}

local function add(id, name, desc, icon, check, category)
	local def = {
		id       = id,
		name     = name,
		desc     = desc,
		icon     = icon,
		check    = check,
		category = category or "General",
	}
	A.List[#A.List + 1] = def
	A.ById[id] = def
	return def
end

local function GetPlayerRankIdx(st)
	return TK.GetPlayerRankIndex(st.kills or 0, st.score or 0)
end

local function wk(st, class)
	return (st.weaponKills and st.weaponKills[class]) or 0
end

local function hg(st, cat)
	return (st.hgCounts and st.hgCounts[cat]) or 0
end

local function acc(st)
	if not st.shots or st.shots <= 0 then return 0 end
	return math.min(st.hits / st.shots, 1)
end

local function avgDist(st)
	if not st.distanceCount or st.distanceCount <= 0 then return 0 end
	return st.distanceSum / st.distanceCount
end

-- =========================================================================
-- KILLS (12 milestones, up to 100,000)
-- =========================================================================
add("kills_1",      "First Blood",         "1 kill",         "1",      function(s) return (s.kills or 0) >= 1 end,      "Kills")
add("kills_10",     "Getting Started",     "10 kills",       "10",     function(s) return (s.kills or 0) >= 10 end,     "Kills")
add("kills_100",    "Killing Machine",     "100 kills",      "100",    function(s) return (s.kills or 0) >= 100 end,    "Kills")
add("kills_1k",     "Exterminator",        "1,000 kills",    "1K",     function(s) return (s.kills or 0) >= 1000 end,   "Kills")
add("kills_5k",     "Genocider",           "5,000 kills",    "5K",     function(s) return (s.kills or 0) >= 5000 end,   "Kills")
add("kills_10k",    "Legend",              "10,000 kills",   "10K",    function(s) return (s.kills or 0) >= 10000 end,  "Kills")
add("kills_15k",    "War Machine",         "15,000 kills",   "15K",    function(s) return (s.kills or 0) >= 15000 end,  "Kills")
add("kills_20k",    "Death Incarnate",     "20,000 kills",   "20K",    function(s) return (s.kills or 0) >= 20000 end,  "Kills")
add("kills_25k",    "Ruin",                "25,000 kills",   "25K",    function(s) return (s.kills or 0) >= 25000 end,  "Kills")
add("kills_50k",    "Apocalypse",          "50,000 kills",   "50K",    function(s) return (s.kills or 0) >= 50000 end,  "Kills")
add("kills_90k",    "Cataclysm",           "90,000 kills",   "90K",    function(s) return (s.kills or 0) >= 90000 end,  "Kills")
add("kills_100k",   "God of War",          "100,000 kills",  "100K",   function(s) return (s.kills or 0) >= 100000 end, "Kills")

-- =========================================================================
-- HEADSHOTS
-- =========================================================================
add("hs_1",     "Headshot",        "1 headshot",        "H1",     function(s) return (s.headshots or 0) >= 1 end,      "Headshots")
add("hs_10",    "Headhunter",      "10 headshots",      "H10",    function(s) return (s.headshots or 0) >= 10 end,     "Headshots")
add("hs_50",    "Sharpshooter",    "50 headshots",      "H50",    function(s) return (s.headshots or 0) >= 50 end,     "Headshots")
add("hs_100",   "Sniper",          "100 headshots",     "H100",   function(s) return (s.headshots or 0) >= 100 end,    "Headshots")
add("hs_500",   "Brain Surgeon",   "500 headshots",     "H500",   function(s) return (s.headshots or 0) >= 500 end,    "Headshots")
add("hs_1k",    "Skull Collector", "1,000 headshots",   "H1K",    function(s) return (s.headshots or 0) >= 1000 end,   "Headshots")
add("hs_5k",    "Headmaster",      "5,000 headshots",   "H5K",    function(s) return (s.headshots or 0) >= 5000 end,   "Headshots")
add("hs_10k",   "Cranial Nightmare","10,000 headshots", "H10K",   function(s) return (s.headshots or 0) >= 10000 end,  "Headshots")

-- =========================================================================
-- MULTIKILL
-- =========================================================================
add("multi_2",   "Double Kill",   "Get a DOUBLE KILL",   "2x",  function(s) return (s.bestMultikill or 0) >= 2 end,  "Multikill")
add("multi_3",   "Triple Kill",   "Get a TRIPLE KILL",   "3x",  function(s) return (s.bestMultikill or 0) >= 3 end,  "Multikill")
add("multi_4",   "Squad Wipe",    "Get a SQUAD WIPE",    "4x",  function(s) return (s.bestMultikill or 0) >= 4 end,  "Multikill")
add("multi_5",   "Mass Kill",     "Get a MASS KILL",     "5x",  function(s) return (s.bestMultikill or 0) >= 5 end,  "Multikill")
add("multi_6",   "Bloodbath",     "Get a BLOODBATH",     "6x",  function(s) return (s.bestMultikill or 0) >= 6 end,  "Multikill")
add("multi_50",  "Multi Master",  "50 multikills total", "M50", function(s) return (s.multikills or 0) >= 50 end,    "Multikill")
add("multi_500", "Carnage",       "500 multikills",      "M500",function(s) return (s.multikills or 0) >= 500 end,   "Multikill")

-- =========================================================================
-- STREAKS
-- =========================================================================
add("streak_5",   "Warming Up",     "5 killstreak",     "S5",   function(s) return (s.bestStreak or 0) >= 5 end,    "Streaks")
add("streak_10",  "On Fire",        "10 killstreak",    "S10",  function(s) return (s.bestStreak or 0) >= 10 end,   "Streaks")
add("streak_20",  "Unstoppable",    "20 killstreak",    "S20",  function(s) return (s.bestStreak or 0) >= 20 end,   "Streaks")
add("streak_30",  "Godlike",        "30 killstreak",    "S30",  function(s) return (s.bestStreak or 0) >= 30 end,   "Streaks")
add("streak_40",  "Dominator",      "40 killstreak",    "S40",  function(s) return (s.bestStreak or 0) >= 40 end,   "Streaks")
add("streak_50",  "Immortal",       "50 killstreak",    "S50",  function(s) return (s.bestStreak or 0) >= 50 end,   "Streaks")
add("streak_70",  "Unkillable",     "70 killstreak",    "S70",  function(s) return (s.bestStreak or 0) >= 70 end,   "Streaks")
add("streak_100", "The Reaper",     "100 killstreak",   "S100", function(s) return (s.bestStreak or 0) >= 100 end,  "Streaks")

-- =========================================================================
-- STYLE
-- =========================================================================
add("style_air",   "Airborne",     "Airborne kill",         "AIR", function(s, e) return e and e.style and e.style.Airborne end,   "Style")
add("style_slide", "Slider",       "Slide kill",            "SLD", function(s, e) return e and e.style and e.style.Slide end,      "Style")
add("style_slow",  "Bullet Time",  "Slow-mo kill",          "SLW", function(s, e) return e and e.style and e.style.SlowMo end,     "Style")
add("style_pb",    "Point Blank",  "Point blank kill",      "PB",  function(s, e) return e and e.style and e.style.PointBlank end, "Style")
add("style_lr",    "Long Shot",    "Long range kill",       "LR",  function(s, e) return e and e.style and e.style.LongRange end,  "Style")
add("style_prop",  "Prop Killer",  "Prop kill",             "PRP", function(s, e) return e and e.style and e.style.Prop end,       "Style")

-- =========================================================================
-- WEAPONS (Only HL2)
-- =========================================================================
add("wep_pistol",   "Pistol Master",    "50 pistol kills",     "PST", function(s) return wk(s, "weapon_pistol") >= 50 end,       						"Weapons")
add("wep_smg1",     "SMG Master",       "100 SMG kills",       "SMG", function(s) return wk(s, "weapon_smg1") >= 100 end,        						"Weapons")
add("wep_ar2",      "AR2 Master",       "100 AR2 kills",       "AR2", function(s) return wk(s, "weapon_ar2") >= 100 end,         						"Weapons")
add("wep_shotgun",  "Shotgun Master",   "100 shotgun kills",   "SHG", function(s) return wk(s, "weapon_shotgun") >= 100 end,     						"Weapons")
add("wep_crowbar",  "Crowbar Hero",     "10 crowbar kills",    "CRB", function(s) return wk(s, "weapon_crowbar") >= 10 end,      						"Weapons")
add("wep_357",      "Revolver Fan",     "30 .357 kills",       "357", function(s) return wk(s, "weapon_357") >= 30 end,          						"Weapons")
add("wep_crossbow", "Silent Killer",    "25 crossbow kills",   "CRS", function(s) return wk(s, "weapon_crossbow") >= 25 end,     						"Weapons")
add("wep_rpg",      "Rocket Man",       "25 RPG kills",        "RPG", function(s) return wk(s, "weapon_rpg") >= 25 end,         					 	"Weapons")
add("wep_gravgun",  "Zero Point Energy", "5 gravity gun kills","GRA", function(s) return wk(s, "weapon_physcannon") >= 5 end,    						"Weapons")
add("wep_grenade",  "Frag Out",         "10 grenade kills",    "GRN", function(s) return wk(s, "weapon_frag") >= 10 end,         						"Weapons")
add("wep_melee",    "Hands On",         "25 melee kills",      "MEL", function(s) return wk(s, "weapon_stunstick") + wk(s, "weapon_crowbar") >= 25 end, "Weapons")

-- =========================================================================
-- RANKS (player rank progression)
-- =========================================================================
add("rank_silver",   "Silver",              "Reach Silver IV",         "S4",  function(s) return GetPlayerRankIdx(s) >= 4 end,   			"Ranks")
add("rank_nova",     "Gold Nova",           "Reach Gold Nova I",       "GN1", function(s) return GetPlayerRankIdx(s) >= 11 end,  			"Ranks")
add("rank_mg",       "Master Guardian",     "Reach Master Guardian I","MG1", function(s) return GetPlayerRankIdx(s) >= 19 end,   			"Ranks")
add("rank_eagle",    "Legendary Eagle",     "Reach Legendary Eagle",   "LE",  function(s) return GetPlayerRankIdx(s) >= 27 end,  			"Ranks")
add("rank_supreme",  "Supreme Master",      "Reach SMFC I",            "SM",  function(s) return GetPlayerRankIdx(s) >= 33 end,  			"Ranks")
add("rank_global",   "Global Elite",        "Reach Global Elite",      "GE",  function(s) return GetPlayerRankIdx(s) >= 38 end,  			"Ranks")
add("rank_legend",   "World Legend",        "Reach World Legend",      "WL",  function(s) return GetPlayerRankIdx(s) >= 41 end,  			"Ranks")
add("rank_immortal", "Immortal",            "Reach Immortal",          "IM",  function(s) return GetPlayerRankIdx(s) >= 46 end,  			"Ranks")
add("rank_mythic",   "Mythic",              "Reach Mythic",            "MY",  function(s) return GetPlayerRankIdx(s) >= 50 end,  			"Ranks")
add("rank_apex",     "Apex",                "Reach Apex",              "AX",  function(s) return GetPlayerRankIdx(s) >= 55 end,  			"Ranks")
add("rank_tklegend", "TactiKill Legend",    "Max player rank",         "TK",  function(s) return GetPlayerRankIdx(s) >= #C.PlayerRanks end, "Ranks")

-- =========================================================================
-- COMBO RANKS
-- =========================================================================
add("combo_spree",     "Spree",           "Reach KILLING SPREE",  "KS",  function(s) return (s.bestRank or 0) >= 1 end,        "Combo")
add("combo_dominating","Dominating",      "Reach DOMINATING",     "DOM", function(s) return (s.bestRank or 0) >= 2 end,        "Combo")
add("combo_legendary", "Legendary Streak","Reach LEGENDARY",      "LEG", function(s) return (s.bestRank or 0) >= 6 end,        "Combo")
add("combo_savage",    "Savage",          "Reach SAVAGE",         "SVG", function(s) return (s.bestRank or 0) >= 12 end,       "Combo")
add("combo_immortal",  "Immortal Streak", "Reach IMMORTAL",       "IMS", function(s) return (s.bestRank or 0) >= 17 end,       "Combo")
add("combo_devas",     "Devastating",     "Reach DEVASTATING",    "DEV", function(s) return (s.bestRank or 0) >= 20 end,       "Combo")
add("combo_apoc",      "Apocalypse",      "Reach APOCALYPSE",     "APC", function(s) return (s.bestRank or 0) >= 24 end,       "Combo")
add("combo_legend",    "Living Legend",   "Reach LEGEND",         "LGD", function(s) return (s.bestRank or 0) >= #C.Ranks end, "Combo")

-- =========================================================================
-- DEATHS
-- =========================================================================
add("death_1",    "First Death",     "Die once",         "D1",     function(s) return (s.deaths or 0) >= 1 end,      "Deaths")
add("death_10",   "Cannon Fodder",   "Die 10 times",     "D10",    function(s) return (s.deaths or 0) >= 10 end,     "Deaths")
add("death_100",  "Kamikaze",        "Die 100 times",    "D100",   function(s) return (s.deaths or 0) >= 100 end,    "Deaths")
add("death_1k",   "Frequent Flyer",  "Die 1,000 times",  "D1K",    function(s) return (s.deaths or 0) >= 1000 end,   "Deaths")

-- =========================================================================
-- ACCURACY / SHOTS
-- =========================================================================
add("shots_1",       "First Shot",      "Fire your first shot",     "SH1",    function(s) return (s.shots or 0) >= 1 end,             			"Accuracy")
add("shots_100",     "Trigger Happy",   "Fire 100 shots",           "SH100",  function(s) return (s.shots or 0) >= 100 end,          		    "Accuracy")
add("shots_10k",     "Lead Sprayer",    "Fire 10,000 shots",        "SH10K",  function(s) return (s.shots or 0) >= 10000 end,         			"Accuracy")
add("hits_1k",       "Marksman",        "Land 1,000 hits",          "HT1K",   function(s) return (s.hits or 0) >= 1000 end,           			"Accuracy")
add("acc_30",        "Deadly Aim",      "30% accuracy (500+ shots)","A30",    function(s) return (s.shots or 0) >= 500 and acc(s) >= 0.30 end,  "Accuracy")
add("acc_50",        "Eagle Eye",       "50% accuracy (1000+ shots)","A50",   function(s) return (s.shots or 0) >= 1000 and acc(s) >= 0.50 end, "Accuracy")
add("acc_70",        "Surgical",        "70% accuracy (1000+ shots)","A70",   function(s) return (s.shots or 0) >= 1000 and acc(s) >= 0.70 end, "Accuracy")

-- =========================================================================
-- DISTANCE
-- =========================================================================
add("dist_500",   "Medium Range",  "Kill at 500+ units",  "D500",  function(s) return (s.distanceMax or 0) >= 500 end,                                            "Distance")
add("dist_1k",    "Long Range",    "Kill at 1000+ units", "D1K",   function(s) return (s.distanceMax or 0) >= 1000 end,                                           "Distance")
add("dist_2k",    "Sniper Shot",   "Kill at 2000+ units", "D2K",   function(s) return (s.distanceMax or 0) >= 2000 end,                                           "Distance")
add("dist_5k",    "Cross-Map",     "Kill at 5000+ units", "D5K",   function(s) return (s.distanceMax or 0) >= 5000 end,                                           "Distance")
add("dist_avg",   "Steady Hand",   "Average kill distance 1500+ (50+ kills)", "DAVG", function(s) return (s.distanceCount or 0) >= 50 and avgDist(s) >= 1500 end, "Distance")

-- =========================================================================
-- HITBOX
-- =========================================================================
add("hg_head_100",  "Head Hunter",   "100 hits on head",    "HH",    function(s) return hg(s, "head") >= 100 end,                                                 "Hitbox")
add("hg_torso_500", "Center Mass",   "500 hits on torso",   "TM",    function(s) return hg(s, "torso") >= 500 end,                                                "Hitbox")
add("hg_limbs",     "Limb Shooter",  "100 limb hits",       "LM",    function(s) return hg(s, "larm") + hg(s, "rarm") + hg(s, "lleg") + hg(s, "rleg") >= 100 end, "Hitbox")

-- =========================================================================
-- SINGLE LIFE / SPECIAL
-- =========================================================================
add("lucky",       "Lucky",         "Survive a 5 killstreak",  "LCK", function(s) return (s.streak or 0) >= 5 end,                                   "Special")
add("pentakill",   "Penta Kill",    "Reach LEGENDARY+++",      "PK",  function(s) return (s.bestRank or 0) >= 9 end,                                 "Special")
add("veteran",     "Veteran",       "10k kills + 5k headshots","VET", function(s) return (s.kills or 0) >= 10000 and (s.headshots or 0) >= 5000 end, "Special")

-- =========================================================================
-- TRIALS — special stateful challenges
-- =========================================================================
add("trial_phoenix",        "Phoenix",              "Kill 10 enemies while at 1 HP",              "PHX", function(s) return (s.lowHpKills or 0) >= 10 end, "Trials")
add("trial_phoenix_rising", "Phoenix Rising",       "3 kills in a row at 1 HP",                   "PHX+", function(s) return (s.lowHpChain or 0) >= 3 end, "Trials")
add("trial_last_stand",     "Last Stand",           "Kill an enemy while at 5 HP or less",        "LS",  function(s, e) return e and e.kind == "kill" and e.hp and e.hp > 0 and e.hp <= 5 end, "Trials")
add("trial_survivor",       "Survivor",             "10 kills in a row without taking damage",    "SRV", function(s) return (s.bestPerfectStreak or 0) >= 10 end, "Trials")
add("trial_untouchable",    "Untouchable",          "25 kills in a row without taking damage",    "UNT", function(s) return (s.bestPerfectStreak or 0) >= 25 end, "Trials")
add("trial_air_hs",         "Sky Marksman",         "Airborne headshot kill",                     "AHS", function(s, e) return e and e.isHeadshot and e.style and e.style.Airborne end, "Trials")
add("trial_pb_hs",          "Point Blank Headshot", "Point blank headshot kill",                  "PBH", function(s, e) return e and e.isHeadshot and e.style and e.style.PointBlank end, "Trials")
add("trial_lr_hs",          "Sniper Legend",        "Long range headshot kill (1500+ units)",     "LRH", function(s, e) return e and e.isHeadshot and e.style and e.style.LongRange end, "Trials")
add("trial_executioner",    "Executioner",          "5 headshot kills in a row",                  "EXE", function(s) return (s.bestHeadshotChain or 0) >= 5 end, "Trials")
add("trial_hs_master",      "Headshot Master",      "10 headshot kills in a row",                 "HSM", function(s) return (s.bestHeadshotChain or 0) >= 10 end, "Trials")
add("trial_speed",          "Speed Demon",          "5 kills within 10 seconds",                  "SPD", function(s) return (s.bestMultikill or 0) >= 5 end,   "Trials")
add("trial_triple_threat",  "Triple Threat",        "3 different weapons in a row",               "TT",  function(s) return (s.weaponChainUnique or 0) >= 3 end, "Trials")
add("trial_quad_threat",    "Quad Threat",          "4 different weapons in a row",               "QT",  function(s) return (s.weaponChainUnique or 0) >= 4 end, "Trials")
add("trial_comeback",       "Comeback Kid",         "Kill after 10 deaths in a row",              "CB",  function(s, e) return e and e.kind == "kill" and e.deathsInRowAtKill and e.deathsInRowAtKill >= 10 end, "Trials")
add("trial_war_machine",    "War Machine",          "100 kills without dying",                    "WM",  function(s) return (s.bestStreak or 0) >= 100 end, "Trials")
add("trial_iron_wall",      "Iron Wall",            "50 kills at full HP",                        "IRW", function(s) return (s.fullHpKills or 0) >= 50 end, "Trials")

-- =========================================================================
-- HELPERS
-- =========================================================================
function A.Get(id) return A.ById[id] end
function A.GetList() return A.List end