TACTIKILL = TACTIKILL or {}
local TK = TACTIKILL
TK.Contracts = TK.Contracts or {}
local CT = TK.Contracts

CT.Customers = {
	-- ── STATE / INTELLIGENCE ─────────────────────────────────────────────
	{ id = "IATU",  name = "IATU",              fullName = "International Anti-Terrorist Union",           color = {  80, 140, 255 } },
	{ id = "CIWU",  name = "CIWU",              fullName = "Central Intelligence of West Union",           color = {  60, 180, 120 } },
	{ id = "MI6",   name = "MI6",               fullName = "Secret Intelligence Service",                  color = { 100, 100, 220 } },
	{ id = "MOSS",  name = "Mossad",            fullName = "Mossad",                                       color = {  40, 120, 200 } },
	{ id = "CIA",   name = "CIA",               fullName = "Central Intelligence Agency",                  color = {  60, 140, 220 } },
	{ id = "FSB",   name = "FSB",               fullName = "Federal Security Service",                     color = {  60,  60, 180 } },
	{ id = "DGSE",  name = "DGSE",              fullName = "Direction Générale de la Sécurité Extérieure", color = {  90, 150, 200 } },
	{ id = "BND",   name = "BND",               fullName = "Bundesnachrichtendienst",                      color = {  80, 180, 180 } },
	{ id = "MSS",   name = "MSS",               fullName = "Ministry of State Security",                   color = { 200,  60,  60 } },
	{ id = "ISI",   name = "ISI",               fullName = "Inter-Services Intelligence",                  color = { 120, 180,  60 } },
	{ id = "RAW",   name = "RAW",               fullName = "Research & Analysis Wing",                     color = { 220, 160,  40 } },
	{ id = "SHAB",  name = "Shin Bet",          fullName = "Shabak",                                       color = { 100, 150, 180 } },

	-- ── MILITARY / SPECIAL FORCES ────────────────────────────────────────
	{ id = "TF",    name = "Task Force",        fullName = "Task Force",                                   color = { 200, 200,  80 } },
	{ id = "SAS",   name = "SAS",               fullName = "Special Air Service",                          color = { 180, 140, 100 } },
	{ id = "SEAL",  name = "SEAL Team",         fullName = "US Navy SEALs",                                color = {  80, 180, 200 } },
	{ id = "GIGN",  name = "GIGN",              fullName = "GIGN",                                         color = { 100, 160, 200 } },
	{ id = "GSG9",  name = "GSG 9",             fullName = "Grenzschutzgruppe 9",                          color = { 120, 180,  40 } },
	{ id = "SPETZ", name = "Spetsnaz",          fullName = "Russian Spetsnaz",                             color = { 200, 100,  60 } },
	{ id = "JTF2",  name = "JTF2",              fullName = "Joint Task Force 2",                           color = { 160, 180, 120 } },
	{ id = "KSK",   name = "KSK",               fullName = "Kommando Spezialkräfte",                       color = { 180, 160,  80 } },

	-- ── DEFENSE CORPORATIONS ─────────────────────────────────────────────
	{ id = "BLCKW", name = "Blackwatch Ind.",   fullName = "Blackwatch Industries",                        color = {  60,  60,  60 } },
	{ id = "VANGR", name = "Vanguard Systems",  fullName = "Vanguard Systems",                             color = { 140,  60, 140 } },
	{ id = "HYPRN", name = "Hyperion Dynamics", fullName = "Hyperion Dynamics",                            color = { 200, 140,  40 } },
	{ id = "APEXA", name = "Apex Armory",       fullName = "Apex Armory",                                  color = { 180,  40,  40 } },
	{ id = "KRIEG", name = "Krieg Tech.",       fullName = "Krieg Technologies",                           color = {  80,  80,  80 } },
	{ id = "MURA",  name = "Murasame HI",       fullName = "Murasame Heavy Industries",                    color = { 200,  80, 120 } },
	{ id = "NORDD", name = "Nord Dynamics",     fullName = "Nord Dynamics",                                color = {  40, 140, 180 } },
	{ id = "VCTRD", name = "Vector Defense",    fullName = "Vector Defense Systems",                       color = { 160, 200,  80 } },
	{ id = "OMNIT", name = "Omnitech",          fullName = "Omnitech Consortium",                          color = { 100, 200, 160 } },
	{ id = "ZENITH",name = "Zenith Holdings",   fullName = "Zenith Holdings",                              color = { 120,  60, 180 } },

	-- ── PRIVATE MILITARY COMPANIES ───────────────────────────────────────
	{ id = "PMC",   name = "PMC Gruppa Krovi",  fullName = "PMC Gruppa Krovi",                             color = { 160,  40,  40 } },
	{ id = "MERC",  name = "MercNet",           fullName = "MercNet Private Contractors",                  color = { 160, 160,  40 } },
	{ id = "Malis", name = "Malis Group",       fullName = "Malis Group",                                  color = { 180, 120,  60 } },
	{ id = "ATLAS", name = "Atlas Security",    fullName = "Atlas Security Solutions",                     color = { 100, 140, 100 } },
	{ id = "GREYW", name = "Grey Wolf PMC",     fullName = "Grey Wolf Private Military",                   color = { 120, 120, 140 } },
	{ id = "ECLPS", name = "Eclipse Cont.",     fullName = "Eclipse Contractors",                          color = {  60,  40, 140 } },
	{ id = "VALKR", name = "Valkyrie Group",    fullName = "Valkyrie Group",                               color = { 180, 140,  80 } },
	{ id = "IRNCL", name = "Ironclad Services", fullName = "Ironclad Services",                            color = { 100,  80,  60 } },
	{ id = "LEGIO", name = "Legio Ferrum",      fullName = "Legio Ferrum",                                 color = { 160,  80,  60 } },
	{ id = "GHOST", name = "Ghost Brigade",     fullName = "Ghost Brigade",                                color = { 180, 180, 200 } },
	{ id = "SCORP", name = "Scorpion Cell",     fullName = "Scorpion Cell",                                color = { 200, 120,  40 } },

	-- ── ORGANIZED CRIME / UNDERGROUND ────────────────────────────────────
	{ id = "YAKU",  name = "Yakuza",            fullName = "Yamaguchi-gumi",                               color = { 200,  80, 120 } },
	{ id = "TRIAD", name = "Triad",             fullName = "14K Triad",                                    color = { 180,  60,  60 } },
	{ id = "CARTL", name = "Cartel",            fullName = "Cartel del Golfo",                             color = { 140, 100,  40 } },
	{ id = "BRATV", name = "Bratva",            fullName = "Solntsevskaya Bratva",                         color = {  80,  40,  40 } },
	{ id = "CAMOR", name = "Camorra",           fullName = "Camorra",                                      color = { 160, 140,  80 } },
	{ id = "NDRNG", name = "Ndrangheta",        fullName = "Ndrangheta",                                   color = { 100,  60,  60 } },
	{ id = "MS13",  name = "MS-13",             fullName = "Mara Salvatrucha",                             color = {  40,  60, 140 } },
	{ id = "SICAR", name = "Sicarios",          fullName = "Los Sicarios",                                 color = { 140,  80, 100 } },
	{ id = "IRISH", name = "Irish Mob",         fullName = "Irish Mob",                                    color = {  40, 140,  80 } },
	{ id = "VORY",  name = "Vory v Zakone",     fullName = "Vory v Zakone",                                color = { 100, 100, 100 } },
	{ id = "OPG18",  name = "Group 18",         fullName = "Brigada 18",                                   color = { 140,  80,  40 } },
	{ id = "OPG120", name = "Group 120",        fullName = "Brigada 120",                                  color = { 120, 100,  40 } },
	{ id = "OPG500", name = "Group 500",        fullName = "Brigada 500",                                  color = { 120,  60,  60 } },
	{ id = "OPG520", name = "Group 520",        fullName = "Brigada 520",                                  color = { 100,  60, 100 } },
	{ id = "OPG650", name = "Group 650",        fullName = "Brigada 650",                                  color = {  80,  80, 120 } },
	{ id = "OPG777", name = "Group 777",        fullName = "Brigada 777",                                  color = { 160, 120,  80 } },
	{ id = "OPG999", name = "Group 999",        fullName = "Brigada 999",                                  color = { 100,  40,  40 } },
	{ id = "OPG1000",name = "Group 1000",       fullName = "Brigada 1000",                                 color = {  60,  60,  60 } },
	{ id = "BLKJK", name = "Blackjack",         fullName = "Blackjack Syndicate",                          color = {  80,  40,  80 } },
	{ id = "SANDV", name = "Sand Viper",        fullName = "Sand Viper Network",                           color = { 200, 180, 100 } },

	-- ── INSURGENTS / MILITANTS ───────────────────────────────────────────
	{ id = "SFF",   name = "SFF",               fullName = "Slavian Freedom Front",                        color = { 200,  60,  60 } },
	{ id = "ALHQ",  name = "Al-Haqq",           fullName = "Al-Haqq Brigade",                              color = { 100,  60,  40 } },
	{ id = "CRIM",  name = "Crimson Path",      fullName = "Crimson Path",                                 color = { 180,  40,  80 } },
	{ id = "BLKB",  name = "Black Banner",      fullName = "Black Banner",                                 color = {  30,  30,  30 } },
	{ id = "JACKL", name = "The Jackals",       fullName = "The Jackals",                                  color = { 140, 100,  60 } },
	{ id = "ASHEN", name = "Ashen Hand",        fullName = "Ashen Hand",                                   color = {  80,  80,  80 } },
	{ id = "LIBF",  name = "Liberation Front",  fullName = "Popular Liberation Front",                     color = { 160, 180,  60 } },
	{ id = "HAMMR", name = "Hammerfall",        fullName = "Hammerfall Militia",                           color = { 200, 120,  40 } },
	{ id = "NR",    name = "Nassar-Rahka",      fullName = "Nassar-Rahka",                                 color = {  80, 200, 160 } },
	{ id = "SKVAD", name = "SKVAD",             fullName = "SKVAD",                                        color = { 140,  80, 180 } },
	{ id = "IRONL", name = "Iron Legion",       fullName = "Iron Legion",                                  color = { 140, 140, 140 } },
	{ id = "NORDW", name = "Nordwulf Front",    fullName = "Nordwulf Front",                               color = {  80, 120, 160 } },
	{ id = "BAST",  name = "Bastion",           fullName = "Bastion Movement",                             color = { 120,  80,  60 } },
	{ id = "DAWNV", name = "Vanguard of Dawn",  fullName = "Vanguard of the Dawn",                         color = { 200, 160,  80 } },
	{ id = "WOLFP", name = "Wolfpack",          fullName = "Wolfpack Militia",                             color = {  80, 100,  60 } },
	{ id = "KHAL",  name = "Khalid Front",      fullName = "Khalid Front",                                 color = { 180, 100,  60 } },
	{ id = "REDDL", name = "Red Delta",         fullName = "Red Delta Insurgents",                         color = { 200,  60,  60 } },
	{ id = "VORTX", name = "Vortex",            fullName = "Vortex Movement",                              color = { 100, 120, 180 } },
	{ id = "SHAN",  name = "Shanyrak Front",    fullName = "Shanyrak National Front",                      color = {  40, 180, 180 } },
	{ id = "STEPE", name = "Steppe Wolves",     fullName = "Steppe Wolves",                                color = { 200, 180,  60 } },
	{ id = "KAVK",  name = "Kavkaz Front",      fullName = "Kavkaz Volunteer Front",                       color = { 160, 100,  80 } },
	{ id = "URAL",  name = "Ural Bastion",      fullName = "Ural Bastion",                                 color = {  60, 100, 140 } },
	{ id = "NORDL", name = "Nordland League",   fullName = "Nordland League",                              color = { 100, 160, 200 } },
	{ id = "VOLGA", name = "Volga Pact",        fullName = "Volga Pact",                                   color = { 120, 140,  80 } },

	-- ── CULTS / MYSTERY ──────────────────────────────────────────────────
	{ id = "ORDER", name = "The Order",         fullName = "Order of the Silent Hand",                     color = { 100,  60, 140 } },
	{ id = "ASCND", name = "The Ascendants",    fullName = "Ascendants of the Ninth Gate",                 color = { 140, 100, 200 } },
	{ id = "KIRIN", name = "Kirin Society",     fullName = "Kirin Society",                                color = { 200, 180, 100 } },
	{ id = "NINE",  name = "Nine Fangs",        fullName = "Order of the Nine Fangs",                      color = {  60, 100,  80 } },
	{ id = "BLKTH", name = "Black Thorn",       fullName = "Black Thorn Society",                          color = {  60,  40,  40 } },
	{ id = "SILVB", name = "Silent Blood",      fullName = "Silent Blood Pact",                            color = { 100,  40,  60 } },

	-- ── UNKNOWN / OTHER ──────────────────────────────────────────────────
	{ id = "NULL",  name = "[NULL]",            fullName = "Unidentified Contractor",                      color = { 200,  40,  40 } },
}
CT.CustomerById = {}
for _, c in ipairs(CT.Customers) do CT.CustomerById[c.id] = c end

function CT.AllCustomerIds()
	local out = {}
	for i, c in ipairs(CT.Customers) do out[i] = c.id end
	return out
end

CT.SlotCount       = 10
CT.RefreshInterval = 300
CT.DifficultyMin   = 1
CT.DifficultyMax   = 10
CT.TimeLimitMin    = 300
CT.TimeLimitMax    = 600
CT.RewardBase      = 15
CT.RewardPerDiff   = 2
CT.PenaltyRatio    = 1.0

CT.NPCClassPool = {
	{ class = "npc_zombie",         label = "Zombie",          w = 10, dMin = 1, dMax = 5 },
	{ class = "npc_zombine",        label = "Zombine",         w =  4, dMin = 3, dMax = 7 },
	{ class = "npc_fastzombie",     label = "Fast Zombie",     w =  7, dMin = 2, dMax = 6 },
	{ class = "npc_poisonzombie",   label = "Poison Zombie",   w =  4, dMin = 4, dMax = 8 },
	{ class = "npc_headcrab",       label = "Headcrab",        w =  8, dMin = 1, dMax = 3 },
	{ class = "npc_headcrab_fast",  label = "Fast Headcrab",   w =  6, dMin = 2, dMax = 4 },
	{ class = "npc_headcrab_poison",label = "Poison Headcrab", w =  5, dMin = 3, dMax = 5 },
	{ class = "npc_combine_s",      label = "Combine Soldier", w =  8, dMin = 2, dMax = 7 },
	{ class = "npc_metropolice",    label = "Metrocop",        w =  8, dMin = 1, dMax = 5 },
	{ class = "npc_manhack",        label = "Manhack",         w =  5, dMin = 1, dMax = 4 },
	{ class = "npc_antlion",        label = "Antlion",         w =  7, dMin = 2, dMax = 6 },
	{ class = "npc_antlionguard",   label = "Antlion Guard",   w =  3, dMin = 5, dMax = 9 },
	{ class = "npc_strider",        label = "Strider",         w =  1, dMin = 8, dMax = 10 },
	{ class = "npc_hunter",         label = "Hunter",          w =  3, dMin = 5, dMax = 9 },
	{ class = "npc_vortigaunt",     label = "Vortigaunt",      w =  6, dMin = 2, dMax = 6 },
	{ class = "npc_citizen",        label = "Citizen",         w =  4, dMin = 1, dMax = 3 },
}

function CT.PickAvailableClass()
	local candidates, totalW = {}, 0
	for _, entry in ipairs(CT.NPCClassPool) do
		if #ents.FindByClass(entry.class) > 0 then
			candidates[#candidates + 1] = entry
			totalW = totalW + (entry.w or 1)
		end
	end
	if #candidates == 0 then return nil end
	local r = math.random(totalW)
	for _, entry in ipairs(candidates) do
		r = r - (entry.w or 1)
		if r <= 0 then return entry end
	end
	return candidates[1]
end

CT.Templates = {
	{
		id = "kill_headshot", title = "Headhunter Protocol",
		desc = "Eliminate %d hostiles with headshots",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = d + 1 } end,
		onKill = function(c, st, ev) if ev.isHeadshot then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_total", title = "Clean Sweep",
		desc = "Eliminate %d hostiles",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = d * 3 } end,
		onKill = function(c, st, ev) c.progress = c.progress + 1 end,
	},
	{
		id = "kill_streak", title = "Killing Spree",
		desc = "Achieve a %d-kill streak",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = 3 + d } end,
		onKill = function(c, st) c.progress = math.max(c.progress, st.streak or 0) end,
		onDeath = function(c) c.failed = true end,
	},
	{
		id = "kill_airborne", title = "Birds of Prey",
		desc = "Kill %d hostiles while airborne",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = d } end,
		onKill = function(c, st, ev) if ev.style and ev.style.Airborne then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_pointblank", title = "Close Quarters",
		desc = "Kill %d hostiles at point-blank range",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = d } end,
		onKill = function(c, st, ev) if ev.style and ev.style.PointBlank then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_longrange", title = "Overwatch",
		desc = "Kill %d hostiles at long range",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = d } end,
		onKill = function(c, st, ev) if ev.style and ev.style.LongRange then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_slide", title = "Momentum",
		desc = "Kill %d hostiles while sliding",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = d } end,
		onKill = function(c, st, ev) if ev.style and ev.style.Slide then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_no_death", title = "Untouchable",
		desc = "Kill %d hostiles without dying",
		customerPool = "all", timeLimit = false,
		build = function(d) return { target = d + 2 } end,
		onKill = function(c, st, ev) c.progress = c.progress + 1 end,
		onDeath = function(c) c.failed = true end,
	},
	{
		id = "kill_multikill", title = "Rampage",
		desc = "Reach a %d-kill multikill",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = math.max(2, d - 3) } end,
		onKill = function(c, st, ev) if ev.step and ev.step >= c.target then c.progress = ev.step end end,
	},
	{
		id = "kill_class", title = "Hunt Order",
		desc = "Eliminate %d %s",
		customerPool = "all", timeLimit = true,
		build = function(d, entry)
			local cap = 5
			if entry then
				local hi = entry.dMax or 10
				if hi >= 8 then      cap = 2
				elseif hi >= 6 then  cap = 3 end
			end
			return { target = math.max(1, math.min(cap, d)) }
		end,
		onKill = function(c, st, ev)
			if c.targetClass and ev.victimClass == c.targetClass then
				c.progress = c.progress + 1
			end
		end,
	},
}