TACTIKILL = TACTIKILL or {}
local TK = TACTIKILL
TK.Version = "1.5.0"

local C = {}
TK.Config = C

C.HUDEnabledByDefault   = true
C.CountPlayerKills      = false
C.CountFriendlyNPCs     = false
C.Debug                 = false

C.IgnoredClasses = {
	npc_furniture   = true,
	npc_bullseye    = true,
	npc_enemyfinder = true,
}

C.KillScore              = 10
C.HeadshotMultiplier     = 2
C.RankUpBonus            = 25
C.PlayerRankBonus        = 50
C.PlayerRankAnnounce     = true
C.PlayerRankShowInLogs   = true
C.PlayerRankScorePerKill = 10

C.Bonus = {
	Airborne   = 15,
	Slide      = 15,
	SlowMo     = 10,
	PointBlank = 10,
	LongRange  = 10,
	Prop       = 10,
}

C.PointBlankDistance  = 150
C.LongRangeDistance   = 1500
C.SlideMinSpeed       = 200
C.SlowMoThreshold     = 0.99
C.PropAttackerTimeout = 5
C.CustomSlideCheck    = nil

C.MultikillWindow     = 3
C.MultikillBonus      = { [2] = 30, [3] = 50 }
C.MultikillBonus4Plus = 100
C.MultikillLabels = {
	[2] = "DOUBLE KILL",
	[3] = "TRIPLE KILL",
	[4] = "SQUAD WIPE",
	[5] = "MASS KILL",
	[6] = "BLOODBATH",
}

C.Ranks = {
	-- TIER 1: early game
	{ min = 3,  name = "KILLING SPREE",  timeout = 15, shake = 0.2 },
	{ min = 4,  name = "DOMINATING",     timeout = 13, shake = 0.35 },
	{ min = 5,  name = "UNSTOPPABLE",    timeout = 12, shake = 0.5 },
	{ min = 6,  name = "RAMPAGE",        timeout = 11, shake = 0.7 },
	{ min = 7,  name = "GODLIKE",        timeout = 10, shake = 0.9 },

	-- TIER 2: mid game
	{ min = 8,  name = "LEGENDARY",      timeout = 9,  shake = 1.1 },
	{ min = 10, name = "LEGENDARY+",     timeout = 8,  shake = 1.3 },
	{ min = 12, name = "LEGENDARY++",    timeout = 7,  shake = 1.5 },
	{ min = 14, name = "LEGENDARY+++",   timeout = 6,  shake = 1.7 },
	{ min = 16, name = "MASTER",         timeout = 5,  shake = 1.9 },
	{ min = 18, name = "GRANDMASTER",    timeout = 5,  shake = 2.1 },

	-- TIER 3: high game
	{ min = 20, name = "SAVAGE",         timeout = 4,  shake = 2.3 },
	{ min = 22, name = "APEX PREDATOR",  timeout = 4,  shake = 2.5 },
	{ min = 24, name = "WICKED SICK",    timeout = 4,  shake = 2.7 },
	{ min = 26, name = "HOLY SHIT",      timeout = 3,  shake = 2.9 },
	{ min = 28, name = "MONSTER KILL",   timeout = 3,  shake = 3.1 },
	{ min = 30, name = "IMMORTAL",       timeout = 3,  shake = 3.3 },

	-- TIER 4: epic
	{ min = 33, name = "LUDICROUS KILL", timeout = 3,  shake = 3.5 },
	{ min = 36, name = "ULTRA KILL",     timeout = 3,  shake = 3.7 },
	{ min = 40, name = "DEVASTATING",    timeout = 2,  shake = 3.9 },

	-- TIER 5: god tier
	{ min = 44, name = "CATACLYSM",      timeout = 2,  shake = 4.1 },
	{ min = 48, name = "ANNIHILATION",   timeout = 2,  shake = 4.3 },
	{ min = 52, name = "OBLITERATION",   timeout = 2,  shake = 4.5 },
	{ min = 56, name = "APOCALYPSE",     timeout = 2,  shake = 4.8 },

	-- TIER 6: beyond human
	{ min = 60, name = "TRANSCENDENT",   timeout = 2,  shake = 5.0 },
	{ min = 65, name = "BEYOND GODLIKE", timeout = 2,  shake = 5.5 },
	{ min = 70, name = "LEGEND",         timeout = 2,  shake = 6.0 },
}

C.ComboDecayEnabled = true
C.ComboDecayFactor  = 0.6
C.ComboDecayMinTime = 0.5
C.ComboDecayLog     = true

C.ComboRankUpSoundEnabled = true
C.ComboRankUpSound        = "sound/tactikill/low-honor-rdr-2.mp3"

C.DeathResetsCombo  = true
C.DeathComboLostLog = true

C.DeathScreen = {
	Enabled = true,
	Duration = 5,
	FadeIn = 0.4,
	FadeOut = 0.5,
	Quotes = {
		{ "War is hell.", "William Tecumseh Sherman" },
		{ "There are no winners in war, only survivors.", "Unknown" },
		{ "Death smiles at us all; all a man can do is smile back.", "Marcus Aurelius" },
		{ "War does not determine who is right — only who is left.", "Bertrand Russell" },
		{ "The loudest sound in war is silence.", "Unknown" },
		{ "We cannot change the past, but we can change the future.", "Unknown" },
		{ "After the war, everyone thinks they were a hero.", "Unknown" },
		{ "The dead do not count. The living do.", "Unknown" },
		{ "War is not glory. It is the smell of death.", "Unknown" },
		{ "While you live — you still have a chance.", "Unknown" },
		{ "What we do in life echoes in eternity.", "Marcus Aurelius" },
		{ "Death is not the end. It is the beginning of a path in another direction.", "Unknown" },
		{ "True heroes do not come back from war.", "Unknown" },
		{ "You are back in the fight. Do not fail those who did not return.", "TactiKill" },
		{ "Every battle could have been your last. This one wasn't.", "TactiKill" },
		{ "In war, truth is the first casualty.", "Aeschylus" },
		{ "The only winner in war is the one who never fights.", "Unknown" },
		{ "You do not win a war by dying for your country; you win by making the other bastard die for his.", "George S. Patton" },
		{ "It is well that war is so terrible, otherwise we should grow too fond of it.", "Robert E. Lee" },
		{ "Older men declare war. But it is youth that must fight and die.", "Herbert Hoover" },
		{ "Never think that war, no matter how necessary, nor how justified, is not a crime.", "Ernest Hemingway" },
		{ "The soldier above all others prays for peace, for it is the soldier who must suffer and bear the deepest wounds of war.", "Douglas MacArthur" },
		{ "If we don't end war, war will end us.", "H. G. Wells" },
		{ "I hate war as only a soldier who has lived it can, only as one who has seen its brutality, its futility, its stupidity.", "Dwight D. Eisenhower" },
		{ "War is a racket.", "Smedley Butler" },
		{ "The death of one man is a tragedy. The death of millions is a statistic.", "Joseph Stalin" },
		{ "A man who has never been to war does not know what peace is worth.", "Unknown" },
		{ "Courage is not the absence of fear — it is the triumph over it.", "Nelson Mandela" },
		{ "You died as you lived — fighting.", "TactiKill" },
		{ "One more fallen soldier. One more story that ends too soon.", "TactiKill" },
		{ "Not all heroes wear capes. Some carry rifles.", "Unknown" },
		{ "Every grave is someone's whole world.", "Unknown" },
		{ "The bravest are surely those who have the clearest vision of what is before them, glory and danger alike, and yet notwithstanding go out to meet it.", "Thucydides" },
		{ "It is foolish and wrong to mourn the men who died. Rather we should thank God that such men lived.", "George S. Patton" },
		{ "The best weapon against an enemy is another enemy.", "Friedrich Nietzsche" },
		{ "He who sweats more in training bleeds less in war.", "Spartan Warrior Creed" },
		{ "Don't forget — no one ever wins a war. Some just lose less.", "TactiKill" },
		{ "You lived through hell. Now live through the next round.", "TactiKill" },
		{ "The mission continues.", "TactiKill" },
		{ "Get back up. They need you.", "TactiKill" },
		{ "Death is lighter than a feather. Duty is heavier than a mountain.", "Imperial Rescript to Soldiers" },
		{ "Cowards die many times before their deaths; the valiant never taste of death but once.", "William Shakespeare" },
	},
}

C.Events = {
	Enabled           = true,
	MinPlayers        = 1,
	CheckInterval     = 75,
	Chance            = 0.45,

	Bombardment = {
		MinBeams       = 3,
		MaxBeams       = 10,
		BeamRadius     = 2000,
		BeamHeight     = 2500,
		BeamDelay      = 0.5,
		ChargeTime     = 5,
		FireInterval   = 2,
		ExplosionRadius = 400,
		ExplosionDamage = 200,
		SoundPath       = "sound/tactikill/projectile-launch.wav",
		SoundLeadTime   = 0.4,
	},

	Airdrop = {
		DropRadius    = 2000,
		FallTime      = 20,
		FallSpeed     = 750,
		BoxModel      = "models/props_junk/wood_crate002a.mdl",
		AmmoChance    = 0.5,
		AmmoAmount    = 200,
		HealthAmount  = 100,
		SoundPath     = "sound/tactikill/parachute-airdrop.mp3",
		ArtyEnabled   = true,
		ArtyChance    = 0.15,
	},
}

C.AutoSpawn = {
	CombineCount      = 20,
	RebelCount        = 15,
	RebelsEnabled     = false,
	Radius            = 3500,
	MinPlayerDistance = 400,
	MinNpcDistance    = 120,
	MaxAttempts       = 40,
	MaxTotal          = 60,
	CombineSkill      = "3",
	RebelSkill        = "2",
	RebelsHostileToPlayer = true,
}

C.Achievements = {
	Enabled      = true,
	Bonus        = 0,
	SoundEnabled = true,
}

C.Leaderboard = {
	Enabled        = true,
	Limit          = 25,
	MinKills       = 1,
	CacheSeconds   = 30,
	Categories = {
		{ id = "kills",       label = "KILLS"     },
		{ id = "score",       label = "SCORE"     },
		{ id = "best_streak", label = "STREAK"    },
		{ id = "headshots",   label = "HEADSHOTS" },
		{ id = "multikills",  label = "MULTI"     },
	},
}

C.PlayerRanks = {
	{ min = 0,     name = "Silver I",                          symbol = ">", count = 1 },
	{ min = 1,     name = "Silver II",                         symbol = ">", count = 2 },
	{ min = 2,     name = "Silver III",                        symbol = ">", count = 3 },
	{ min = 4,     name = "Silver IV",                         symbol = ">", count = 4 },
	{ min = 6,     name = "Silver V",                          symbol = ">", count = 4, brackets = 1 },
	{ min = 8,     name = "Silver VI",                         symbol = ">", count = 4, brackets = 2 },
	{ min = 11,    name = "Silver VII",                        symbol = ">", count = 4, brackets = 3 },
	{ min = 15,    name = "Silver VIII",                       symbol = ">", count = 4, brackets = 4 },
	{ min = 20,    name = "Silver Elite",                      symbol = ">", count = 4, brackets = 1, stars = 1 },
	{ min = 26,    name = "Silver Elite Master",               symbol = ">", count = 4, brackets = 1, stars = 3 },
	{ min = 33,    name = "Gold Nova I",                       symbol = "*", count = 1 },
	{ min = 41,    name = "Gold Nova II",                      symbol = "*", count = 2 },
	{ min = 50,    name = "Gold Nova III",                     symbol = "*", count = 3 },
	{ min = 60,    name = "Gold Nova IV",                      symbol = "*", count = 4 },
	{ min = 72,    name = "Gold Nova V",                       symbol = "*", count = 4, brackets = 1 },
	{ min = 86,    name = "Gold Nova VI",                      symbol = "*", count = 4, brackets = 2 },
	{ min = 102,   name = "Gold Nova VII",                     symbol = "*", count = 4, brackets = 3 },
	{ min = 120,   name = "Gold Nova Master",                  symbol = "*", count = 4, brackets = 1, stars = 2 },
	{ min = 140,   name = "Master Guardian I",                 symbol = "+", count = 1 },
	{ min = 163,   name = "Master Guardian II",                symbol = "+", count = 2 },
	{ min = 189,   name = "Master Guardian III",               symbol = "+", count = 3 },
	{ min = 218,   name = "Master Guardian IV",                symbol = "+", count = 4 },
	{ min = 250,   name = "Master Guardian V",                 symbol = "+", count = 4, brackets = 1 },
	{ min = 286,   name = "Master Guardian Elite",             symbol = "+", count = 4, brackets = 2 },
	{ min = 326,   name = "Distinguished Master Guardian",     symbol = "+", count = 4, brackets = 3 },
	{ min = 370,   name = "Exceptional Master Guardian",       symbol = "+", count = 4, brackets = 4 },
	{ min = 420,   name = "Legendary Eagle",                   symbol = "^", count = 1 },
	{ min = 476,   name = "Legendary Eagle II",                symbol = "^", count = 2 },
	{ min = 538,   name = "Legendary Eagle III",               symbol = "^", count = 3 },
	{ min = 606,   name = "Legendary Eagle IV",                symbol = "^", count = 4 },
	{ min = 680,   name = "Legendary Eagle Master",            symbol = "^", count = 4, brackets = 1 },
	{ min = 760,   name = "Supreme Legendary Eagle",           symbol = "^", count = 4, brackets = 2, stars = 1 },
	{ min = 850,   name = "Supreme Master First Class I",      symbol = "=", count = 1 },
	{ min = 950,   name = "Supreme Master First Class II",     symbol = "=", count = 2 },
	{ min = 1060,  name = "Supreme Master First Class III",    symbol = "=", count = 3 },
	{ min = 1180,  name = "Supreme Master First Class Elite",  symbol = "=", count = 4 },
	{ min = 1310,  name = "Supreme Master First Class Master", symbol = "=", count = 4, brackets = 1, stars = 1 },
	{ min = 1450,  name = "Global Elite I",                    symbol = "#", count = 1 },
	{ min = 1600,  name = "Global Elite II",                   symbol = "#", count = 2 },
	{ min = 1770,  name = "Global Elite III",                  symbol = "#", count = 3 },
	{ min = 1960,  name = "Global Elite Master",               symbol = "#", count = 4, stars = 1 },
	{ min = 2160,  name = "Continental Legend",                symbol = "~", count = 1 },
	{ min = 2400,  name = "World Legend",                      symbol = "~", count = 2 },
	{ min = 2660,  name = "Celestial Legend",                  symbol = "~", count = 3 },
	{ min = 2960,  name = "Imperial Legend",                   symbol = "~", count = 4 },
	{ min = 3300,  name = "Immortal",                          symbol = "~", count = 4, brackets = 1 },
	{ min = 3700,  name = "Immortal Master",                   symbol = "~", count = 4, brackets = 1, stars = 1 },
	{ min = 4160,  name = "Mythic",                            symbol = "~", count = 4, brackets = 2, stars = 1 },
	{ min = 4680,  name = "Mythic Master",                     symbol = "~", count = 4, brackets = 2, stars = 2 },
	{ min = 5280,  name = "Titan",                             symbol = "~", count = 4, brackets = 3, stars = 2 },
	{ min = 5960,  name = "Titan Master",                      symbol = "~", count = 4, brackets = 3, stars = 3 },
	{ min = 6740,  name = "Absolute",                          symbol = "~", count = 4, brackets = 4, stars = 3 },
	{ min = 7640,  name = "Absolute Master",                   symbol = "~", count = 4, brackets = 4, stars = 4 },
	{ min = 8660,  name = "Apex",                              symbol = "@", count = 1, stars = 4 },
	{ min = 9840,  name = "Overlord",                          symbol = "@", count = 2, stars = 4 },
	{ min = 11180, name = "Overlord Master",                   symbol = "@", count = 3, stars = 4 },
	{ min = 12720, name = "Ascendant",                         symbol = "@", count = 4, stars = 4 },
	{ min = 14480, name = "TactiKill Elite",                   symbol = "@", count = 4, brackets = 1, stars = 4 },
	{ min = 16520, name = "TactiKill Master",                  symbol = "@", count = 4, brackets = 2, stars = 4 },
	{ min = 19000, name = "TactiKill Legend",                  symbol = "@", count = 4, brackets = 3, stars = 4 },
}

C.ResetKillstreakOnExpire = true
C.ExpiryCheckInterval     = 0.2
C.RedAccentFromRank       = 6

C.ScreenShakeEnabled      = true
C.ScreenShakeMultiplier   = 1.0
C.ScreenShakeMaxIntensity = 4.5
C.RankUpShakeEnabled      = true
C.ShakeSustainedFactor    = 0.5
C.RankUpImpulseScale      = 1.0
C.ShakeImpulseDecay       = 5
C.ShakeSmoothing          = 6
C.ShakeUnitsPerIntensity  = 0.4
C.ShakeMaxOffsetUnits     = 1.5
C.ShakeFrequency          = 1.0
C.ShakeRollDegrees        = 0

C.MaxLogs      = 10
C.LogLifetime  = 3.5
C.ShowLogBonus = true
C.LogComboLost = true

C.Labels = {
	Airborne       = "AIRBORNE KILL",
	Slide          = "SLIDE KILL",
	SlowMo         = "SLOW-MO KILL",
	PointBlank     = "POINT BLANK",
	LongRange      = "LONG RANGE",
	Prop           = "PROP KILL",
	RankUp         = "COMBO RANK UP",
	PlayerRankUp   = "PLAYER RANK UP",
	ComboDecay     = "COMBO DECAY",
	ComboLost      = "COMBO LOST",
	ComboLostDeath = "COMBO LOST — YOU DIED",
	Headshot       = "HEADSHOT",
}

C.SessionAutoStart  = false
C.SessionShowOnHUD  = true

C.ResetAllowSelf    = true
C.ResetOthersLevel  = "admin"
C.SettingsEditLevel = "admin"
C.PersistenceEnabled = true

local function num(v, def, lo, hi)
	v = tonumber(v)
	if not v or v ~= v then return def end
	if lo and v < lo then return lo end
	if hi and v > hi then return hi end
	return v
end
local function int(v, def, lo, hi) return math.floor(num(v, def, lo, hi)) end
local function bool(v, def) if type(v) == "boolean" then return v end return def end
local function str(v, def) if isstring(v) and v ~= "" then return v end return def end
local function fill(tbl, defaults, conv)
	if not istable(tbl) then tbl = {} end
	for k, def in pairs(defaults) do tbl[k] = conv(tbl[k], def) end
	return tbl
end

local function DefaultRanks()
	return {
		{ min = 3,  name = "KILLING SPREE", timeout = 15, shake = 0.2 },
		{ min = 4,  name = "DOMINATING",    timeout = 13, shake = 0.35 },
		{ min = 5,  name = "UNSTOPPABLE",   timeout = 12, shake = 0.5 },
		{ min = 6,  name = "RAMPAGE",       timeout = 11, shake = 0.7 },
		{ min = 7,  name = "GODLIKE",       timeout = 10, shake = 0.9 },
		{ min = 8,  name = "LEGENDARY",     timeout = 7,  shake = 1.2 },
		{ min = 10, name = "LEGENDARY+",    timeout = 5,  shake = 1.5 },
		{ min = 12, name = "LEGENDARY++",   timeout = 3,  shake = 1.8 },
		{ min = 14, name = "LEGENDARY+++",  timeout = 2,  shake = 2.2 },
	}
end

local function DefaultPlayerRanks()
	return { { min = 0, name = "Silver I", symbol = ">", count = 1, score = 0 } }
end

function TK.ValidateConfig()
	C.HUDEnabledByDefault = bool(C.HUDEnabledByDefault, true)
	C.CountPlayerKills    = bool(C.CountPlayerKills, false)
	C.CountFriendlyNPCs   = bool(C.CountFriendlyNPCs, false)
	C.Debug               = bool(C.Debug, false)
	if not istable(C.IgnoredClasses) then C.IgnoredClasses = {} end

	C.KillScore              = int(C.KillScore, 10, 0, 1000000)
	C.HeadshotMultiplier     = num(C.HeadshotMultiplier, 2, 1, 100)
	C.RankUpBonus            = int(C.RankUpBonus, 0, 0, 1000000)
	C.PlayerRankBonus        = int(C.PlayerRankBonus, 50, 0, 1000000)
	C.PlayerRankAnnounce     = bool(C.PlayerRankAnnounce, true)
	C.PlayerRankShowInLogs   = bool(C.PlayerRankShowInLogs, true)
	C.PlayerRankScorePerKill = num(C.PlayerRankScorePerKill, 10, 0, 1000)

	C.Bonus = fill(C.Bonus, { Airborne = 15, Slide = 15, SlowMo = 10, PointBlank = 10, LongRange = 10, Prop = 10 },
		function(v, d) return int(v, d, 0, 1000000) end)

	C.PointBlankDistance  = num(C.PointBlankDistance, 150, 1, 100000)
	C.LongRangeDistance   = num(C.LongRangeDistance, 1500, 1, 100000)
	C.SlideMinSpeed       = num(C.SlideMinSpeed, 200, 1, 100000)
	C.SlowMoThreshold     = num(C.SlowMoThreshold, 0.99, 0.01, 1)
	C.PropAttackerTimeout = num(C.PropAttackerTimeout, 5, 0.1, 60)
	if not isfunction(C.CustomSlideCheck) then C.CustomSlideCheck = nil end

	C.MultikillWindow = num(C.MultikillWindow, 3, 0.2, 60)
	C.MultikillBonus = fill(C.MultikillBonus, { [2] = 30, [3] = 50 },
		function(v, d) return int(v, d, 0, 1000000) end)
	C.MultikillBonus4Plus = int(C.MultikillBonus4Plus, 100, 0, 1000000)
	C.MultikillLabels = fill(C.MultikillLabels,
		{ [2] = "DOUBLE KILL", [3] = "TRIPLE KILL", [4] = "SQUAD WIPE", [5] = "MASS KILL", [6] = "BLOODBATH" }, str)

	if not istable(C.Events) then C.Events = {} end
	C.Events.Enabled       = bool(C.Events.Enabled, true)
	C.Events.MinPlayers    = int(C.Events.MinPlayers, 1, 0, 64)
	C.Events.CheckInterval = num(C.Events.CheckInterval, 75, 15, 3600)
	C.Events.Chance        = num(C.Events.Chance, 0.45, 0, 1)

	if not istable(C.Achievements) then C.Achievements = {} end
	C.Achievements.Enabled      = bool(C.Achievements.Enabled, true)
	C.Achievements.Bonus        = int(C.Achievements.Bonus, 0, 0, 100000)
	C.Achievements.SoundEnabled = bool(C.Achievements.SoundEnabled, true)

	if not istable(C.Leaderboard) then C.Leaderboard = {} end
	local LB = C.Leaderboard
	LB.Enabled      = bool(LB.Enabled, true)
	LB.Limit        = int(LB.Limit, 25, 1, 100)
	LB.MinKills     = int(LB.MinKills, 1, 0, 100000)
	LB.CacheSeconds = num(LB.CacheSeconds, 30, 0, 600)
	if not istable(LB.Categories) or #LB.Categories == 0 then
		LB.Categories = {
			{ id = "kills",       label = "KILLS"     },
			{ id = "score",       label = "SCORE"     },
			{ id = "best_streak", label = "STREAK"    },
			{ id = "headshots",   label = "HEADSHOTS" },
			{ id = "multikills",  label = "MULTI"     },
		}
	end

	if not istable(C.AutoSpawn) then C.AutoSpawn = {} end
	local AS = C.AutoSpawn
	AS.CombineCount        = int(AS.CombineCount, 20, 0, 100)
	AS.RebelCount          = int(AS.RebelCount, 15, 0, 100)
	AS.RebelsEnabled       = bool(AS.RebelsEnabled, false)
	AS.Radius              = num(AS.Radius, 3500, 500, 10000)
	AS.MinPlayerDistance   = num(AS.MinPlayerDistance, 400, 100, 3000)
	AS.MinNpcDistance      = num(AS.MinNpcDistance, 120, 30, 500)
	AS.MaxAttempts         = int(AS.MaxAttempts, 40, 10, 100)
	AS.MaxTotal            = int(AS.MaxTotal, 60, 10, 200)
	AS.CombineSkill        = str(AS.CombineSkill, "3")
	AS.RebelSkill          = str(AS.RebelSkill, "2")
	AS.RebelsHostileToPlayer = bool(AS.RebelsHostileToPlayer, true)

	if not istable(C.Events.Bombardment) then C.Events.Bombardment = {} end
	local B = C.Events.Bombardment
	B.MinBeams        = int(B.MinBeams, 3, 1, 30)
	B.MaxBeams        = int(B.MaxBeams, 10, B.MinBeams, 30)
	B.BeamRadius      = num(B.BeamRadius, 2000, 200, 10000)
	B.BeamHeight      = num(B.BeamHeight, 2500, 500, 8000)
	B.BeamDelay       = num(B.BeamDelay, 0.5, 0.05, 5)
	B.ChargeTime      = num(B.ChargeTime, 5, 1, 30)
	B.FireInterval    = num(B.FireInterval, 2, 0.2, 20)
	B.ExplosionRadius = num(B.ExplosionRadius, 400, 50, 2000)
	B.ExplosionDamage = num(B.ExplosionDamage, 200, 10, 2000)
	B.SoundPath       = str(B.SoundPath, "sound/tactikill/projectile-launch.wav")	
	B.SoundLeadTime   = num(B.SoundLeadTime, 0.4, 0, 3)
	
	if not istable(C.Events.Airdrop) then C.Events.Airdrop = {} end
	local A = C.Events.Airdrop
	A.DropRadius   = num(A.DropRadius, 2000, 200, 10000)
	A.FallTime     = num(A.FallTime, 20, 3, 120)
	A.FallSpeed    = num(A.FallSpeed, 750, 100, 3000)
	A.BoxModel     = str(A.BoxModel, "models/props_junk/wood_crate002a.mdl")
	A.AmmoChance   = num(A.AmmoChance, 0.5, 0, 1)
	A.AmmoAmount   = int(A.AmmoAmount, 200, 1, 10000)
	A.HealthAmount = int(A.HealthAmount, 100, 1, 1000)
	A.SoundPath    = str(A.SoundPath, "sound/tactikill/parachute-airdrop.mp3")
	A.ArtyEnabled  = bool(A.ArtyEnabled, true)
	A.ArtyChance   = num(A.ArtyChance, 0.15, 0, 1)

	local ok = istable(C.Ranks) and #C.Ranks > 0
	if ok then
		local prev = 0
		for _, r in ipairs(C.Ranks) do
			if not (istable(r)
				and isnumber(r.min) and r.min == math.floor(r.min) and r.min > prev
				and isstring(r.name) and r.name ~= ""
				and isnumber(r.timeout) and r.timeout >= 0.5) then
				ok = false
				break
			end
			prev = r.min
		end
	end
	if not ok then
		ErrorNoHalt("[TactiKill] Invalid Ranks table - using defaults.\n")
		C.Ranks = DefaultRanks()
	end
	for _, r in ipairs(C.Ranks) do r.shake = num(r.shake, 0, 0, 100) end

	C.ComboDecayEnabled = bool(C.ComboDecayEnabled, true)
	C.ComboDecayFactor  = num(C.ComboDecayFactor, 0.6, 0.1, 1.0)
	C.ComboDecayMinTime = num(C.ComboDecayMinTime, 0.5, 0.1, 5)
	C.ComboDecayLog     = bool(C.ComboDecayLog, true)

	C.ComboRankUpSoundEnabled = bool(C.ComboRankUpSoundEnabled, true)
	C.ComboRankUpSound        = str(C.ComboRankUpSound, "sound/tactikill/low-honor-rdr-2.mp3")

	C.DeathResetsCombo  = bool(C.DeathResetsCombo, true)
	C.DeathComboLostLog = bool(C.DeathComboLostLog, true)

	local prOk = istable(C.PlayerRanks) and #C.PlayerRanks > 0
	if prOk then
		local first = C.PlayerRanks[1]
		if not (istable(first) and isnumber(first.min) and first.min == 0 and isstring(first.name)) then
			prOk = false
		else
			local prev = -1
			for i, r in ipairs(C.PlayerRanks) do
				if not (istable(r) and isnumber(r.min) and r.min == math.floor(r.min)
					and r.min > prev and isstring(r.name) and r.name ~= "") then
					while #C.PlayerRanks >= i do table.remove(C.PlayerRanks) end
					break
				end
				prev = r.min
				r.symbol   = str(r.symbol, ">")
				r.count    = int(r.count, 1, 1, 20)
				r.brackets = int(r.brackets, 0, 0, 10)
				r.stars    = int(r.stars, 0, 0, 10)
				if r.score == nil or r.autoScore then
					r.score = math.floor(r.min * C.PlayerRankScorePerKill)
					r.autoScore = true
				else
					r.score = num(r.score, 0, 0, 2147483647)
					r.autoScore = nil
				end
			end
		end
	end
	if not prOk then
		ErrorNoHalt("[TactiKill] Invalid PlayerRanks - using defaults.\n")
		C.PlayerRanks = DefaultPlayerRanks()
	end

	C.ScreenShakeEnabled      = bool(C.ScreenShakeEnabled, true)
	C.ScreenShakeMultiplier   = num(C.ScreenShakeMultiplier, 1.0, 0, 3)
	C.ScreenShakeMaxIntensity = num(C.ScreenShakeMaxIntensity, 2.2, 0, 10)
	C.RankUpShakeEnabled      = bool(C.RankUpShakeEnabled, true)
	C.ShakeSustainedFactor    = num(C.ShakeSustainedFactor, 0.5, 0, 1)
	C.RankUpImpulseScale      = num(C.RankUpImpulseScale, 1.0, 0, 5)
	C.ShakeImpulseDecay       = num(C.ShakeImpulseDecay, 5, 0.5, 30)
	C.ShakeSmoothing          = num(C.ShakeSmoothing, 6, 0.5, 30)
	C.ShakeUnitsPerIntensity  = num(C.ShakeUnitsPerIntensity, 0.4, 0, 2)
	C.ShakeMaxOffsetUnits     = num(C.ShakeMaxOffsetUnits, 1.5, 0, 5)
	C.ShakeFrequency          = num(C.ShakeFrequency, 1.0, 0.1, 5)
	C.ShakeRollDegrees        = num(C.ShakeRollDegrees, 0, 0, 2)

	C.ResetKillstreakOnExpire = bool(C.ResetKillstreakOnExpire, true)
	C.ExpiryCheckInterval     = num(C.ExpiryCheckInterval, 0.2, 0.05, 1)
	C.RedAccentFromRank       = int(C.RedAccentFromRank, 6, 1, #C.Ranks)

	C.MaxLogs      = int(C.MaxLogs, 6, 1, 20)
	C.LogLifetime  = num(C.LogLifetime, 3.5, 0.5, 30)
	C.ShowLogBonus = bool(C.ShowLogBonus, true)
	C.LogComboLost = bool(C.LogComboLost, true)
	C.Labels = fill(C.Labels, {
		Airborne = "AIRBORNE KILL", Slide = "SLIDE KILL", SlowMo = "SLOW-MO KILL",
		PointBlank = "POINT BLANK", LongRange = "LONG RANGE", Prop = "PROP KILL",
		RankUp = "COMBO RANK UP", PlayerRankUp = "PLAYER RANK UP", ComboDecay = "COMBO DECAY",
		ComboLost = "COMBO LOST", ComboLostDeath = "COMBO LOST — YOU DIED", Headshot = "HEADSHOT",
	}, str)

	if not istable(C.DeathScreen) then C.DeathScreen = {} end
	C.DeathScreen.Enabled  = bool(C.DeathScreen.Enabled, true)
	C.DeathScreen.Duration = num(C.DeathScreen.Duration, 5, 1, 30)
	C.DeathScreen.FadeIn   = num(C.DeathScreen.FadeIn, 0.4, 0.1, 3)
	C.DeathScreen.FadeOut  = num(C.DeathScreen.FadeOut, 0.5, 0.1, 3)
	if not istable(C.DeathScreen.Quotes) then C.DeathScreen.Quotes = {} end

    C.PersistenceEnabled = bool(C.PersistenceEnabled, true)
	C.SessionAutoStart = bool(C.SessionAutoStart, false)
	C.SessionShowOnHUD = bool(C.SessionShowOnHUD, true)

	C.ResetAllowSelf = bool(C.ResetAllowSelf, true)
	if C.ResetOthersLevel ~= "admin" and C.ResetOthersLevel ~= "superadmin" then
		C.ResetOthersLevel = "admin"
	end
	if C.SettingsEditLevel ~= "admin" and C.SettingsEditLevel ~= "superadmin" then
		C.SettingsEditLevel = "admin"
	end
end

TK.ValidateConfig()

function TK.GetRankIndex(streak)
	for i = #C.Ranks, 1, -1 do
		if streak >= C.Ranks[i].min then return i end
	end
	return 0
end

function TK.GetNextRank(streak)
	for _, r in ipairs(C.Ranks) do
		if r.min > streak then return r end
	end
end

function TK.GetPlayerRankIndex(kills, score)
	kills = kills or 0
	score = score or 0
	for i = #C.PlayerRanks, 1, -1 do
		local r = C.PlayerRanks[i]
		if kills >= r.min and score >= (r.score or 0) then return i end
	end
	return 1
end

function TK.GetPlayerRank(kills, score)
	return C.PlayerRanks[TK.GetPlayerRankIndex(kills, score)]
end

function TK.GetRankInsignia(rankIdx)
	local ranks = C.PlayerRanks
	if not ranks or not ranks[rankIdx] then return "" end
	local r = ranks[rankIdx]
	local sym  = r.symbol or ">"
	local cnt  = math.max(1, math.floor(r.count or 1))
	local brk  = math.max(0, math.floor(r.brackets or 0))
	local strs = math.max(0, math.floor(r.stars or 0))
	return string.rep("*", strs) .. string.rep("(", brk) .. string.rep(sym, cnt)
end

function TK.FormatTime(sec)
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
	if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
	return string.format("%02d:%02d", m, s)
end

function TK.Debug(fmt, ...)
	if not C.Debug then return end
	MsgC(Color(255, 190, 40), "[TactiKill] ", string.format(fmt, ...), "\n")
end