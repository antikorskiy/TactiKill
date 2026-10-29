TACTIKILL = TACTIKILL or {}
local TK = TACTIKILL
TK.Contracts = TK.Contracts or {}
local CT = TK.Contracts

CT.Customers = {
	{ id = "IATU",  name = "IATU",             fullName = "International Anti-Terrorist Union", color = {  80, 140, 255 } },
	{ id = "SFF",   name = "SFF",              fullName = "Slavian Freedom Front",              color = { 200,  60,  60 } },
	{ id = "CIWU",  name = "CIWU",             fullName = "Central Intelligence of West Union", color = {  60, 180, 120 } },
	{ id = "Malis", name = "Malis Group",      fullName = "Malis Group",                        color = { 180, 120,  60 } },
	{ id = "TF",    name = "Task Force",       fullName = "Task Force",                         color = { 200, 200,  80 } },
	{ id = "SKVAD", name = "SKVAD",            fullName = "SKVAD",                              color = { 140,  80, 180 } },
	{ id = "PMC",   name = "PMC Gruppa Krovi", fullName = "PMC Gruppa Krovi",                   color = { 160,  40,  40 } },
	{ id = "NR",    name = "Nassar-Rahka",     fullName = "Nassar-Rahka",                       color = {  80, 200, 160 } },
}
CT.CustomerById = {}
for _, c in ipairs(CT.Customers) do CT.CustomerById[c.id] = c end

CT.SlotCount       = 3
CT.RefreshInterval = 300
CT.DifficultyMin   = 1
CT.DifficultyMax   = 10
CT.TimeLimitMin    = 300
CT.TimeLimitMax    = 600
CT.RewardBase      = 15
CT.RewardPerDiff   = 2      -- reward = base + diff^2 * perDiff
CT.PenaltyRatio    = 1.0    -- penalty = reward * ratio (full loss)

CT.Templates = {
	{
		id = "kill_headshot", title = "Headhunter Protocol",
		desc = "Eliminate %d hostiles with headshots",
		customers = { "IATU", "CIWU" }, timeLimit = true,
		build = function(d) return { target = d + 1 } end,
		onKill = function(c, st, ev) if ev.isHeadshot then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_total", title = "Clean Sweep",
		desc = "Eliminate %d hostiles",
		customers = { "SFF", "TF", "Malis" }, timeLimit = true,
		build = function(d) return { target = d * 3 } end,
		onKill = function(c, st, ev) c.progress = c.progress + 1 end,
	},
	{
		id = "kill_streak", title = "Killing Spree",
		desc = "Achieve a %d-kill streak",
		customers = { "SFF", "TF", "PMC", "SKVAD" }, timeLimit = true,
		build = function(d) return { target = 3 + d } end,
		onKill = function(c, st) c.progress = math.max(c.progress, st.streak or 0) end,
		onDeath = function(c) c.failed = true end,
	},
	{
		id = "kill_airborne", title = "Birds of Prey",
		desc = "Kill %d hostiles while airborne",
		customers = { "SFF", "CIWU" }, timeLimit = true,
		build = function(d) return { target = d } end,
		onKill = function(c, st, ev) if ev.style and ev.style.Airborne then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_pointblank", title = "Close Quarters",
		desc = "Kill %d hostiles at point-blank range",
		customers = { "NR", "PMC" }, timeLimit = true,
		build = function(d) return { target = d } end,
		onKill = function(c, st, ev) if ev.style and ev.style.PointBlank then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_longrange", title = "Overwatch",
		desc = "Kill %d hostiles at long range",
		customers = { "IATU", "CIWU" }, timeLimit = true,
		build = function(d) return { target = d } end,
		onKill = function(c, st, ev) if ev.style and ev.style.LongRange then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_slide", title = "Momentum",
		desc = "Kill %d hostiles while sliding",
		customers = { "SFF", "NR" }, timeLimit = true,
		build = function(d) return { target = d } end,
		onKill = function(c, st, ev) if ev.style and ev.style.Slide then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_no_death", title = "Untouchable",
		desc = "Kill %d hostiles without dying",
		customers = { "TF", "PMC" }, timeLimit = false,
		build = function(d) return { target = d + 2 } end,
		onKill = function(c, st, ev) c.progress = c.progress + 1 end,
		onDeath = function(c) c.failed = true end,
	},
	{
		id = "kill_multikill", title = "Rampage",
		desc = "Reach a %d-kill multikill",
		customers = { "NR", "SKVAD", "Malis" }, timeLimit = true,
		build = function(d) return { target = math.max(2, d - 3) } end,
		onKill = function(c, st, ev) if ev.step and ev.step >= c.target then c.progress = ev.step end end,
	},
}