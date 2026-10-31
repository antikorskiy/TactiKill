local TK = TACTIKILL
local C  = TK.Config

TK.Leaderboard = TK.Leaderboard or {
	category    = "kills",
	data        = {},
	isLoading   = false,
	requestedAt = 0,
}

local COL_BG     = Color(22, 22, 28, 240)
local COL_BORDER = Color(70, 70, 80, 255)
local COL_HEADER = Color(28, 28, 36, 255)
local COL_TEXT   = Color(235, 235, 235, 255)
local COL_DIM    = Color(150, 150, 160, 255)
local COL_AMBER  = Color(255, 190, 40, 255)
local COL_RED    = Color(255, 64, 56, 255)
local COL_GREEN  = Color(120, 220, 120, 255)
local COL_BLUE   = Color(80, 160, 255, 255)
local COL_ROW_A  = Color(20, 20, 26, 240)
local COL_ROW_B  = Color(15, 15, 20, 240)
local COL_GOLD   = Color(255, 215, 0, 255)
local COL_SILVER = Color(210, 210, 210, 255)
local COL_BRONZE = Color(205, 127, 50, 255)

local DEFAULT_CATS = {
	{ id = "kills",       label = "KILLS"     },
	{ id = "score",       label = "SCORE"     },
	{ id = "best_streak", label = "STREAK"    },
	{ id = "headshots",   label = "HEADSHOTS" },
	{ id = "multikills",  label = "MULTI"     },
}

local function GetCategories()
	if istable(C.Leaderboard) and istable(C.Leaderboard.Categories) and #C.Leaderboard.Categories > 0 then
		return C.Leaderboard.Categories
	end
	return DEFAULT_CATS
end

local function DefaultCategory()
	local cats = GetCategories()
	return cats[1] and cats[1].id or "kills"
end

function TK.RequestLeaderboard(cat)
	local now = CurTime()
	if TK.Leaderboard.isLoading and (now - (TK.Leaderboard.requestedAt or 0)) < 3 then
		return
	end
	if istable(C.Leaderboard) and C.Leaderboard.Enabled == false then return end

	TK.Leaderboard.isLoading = true
	TK.Leaderboard.requestedAt = now

	net.Start("TACTIKILL_RequestLeaderboard")
		net.WriteString(cat or TK.Leaderboard.category or DefaultCategory())
	net.SendToServer()
end

local function FormatTimeAgo(sec)
	sec = tonumber(sec) or 0
	if sec <= 0 then return "now" end
	if sec < 60 then return sec .. "s" end
	if sec < 3600 then return math.floor(sec / 60) .. "m" end
	if sec < 86400 then return math.floor(sec / 3600) .. "h" end
	return math.floor(sec / 86400) .. "d"
end

local function FormatKD(k, d)
	k, d = k or 0, d or 0
	if d == 0 then return k > 0 and string.format("%.2f", k) or "0.00" end
	return string.format("%.2f", k / d)
end

local function Trunc(str, font, maxW)
	str = tostring(str or "")
	surface.SetFont(font)
	if surface.GetTextSize(str) <= maxW then return str end
	for i = #str, 1, -1 do
		local s = string.sub(str, 1, i) .. "..."
		if surface.GetTextSize(s) <= maxW then return s end
	end
	return str
end

net.Receive("TACTIKILL_Leaderboard", function()
	local cat = net.ReadString()
	local n = net.ReadUInt(8)
	local rows = {}
	for i = 1, n do
		local row = {}
		row.nick        = net.ReadString()
		row.kills       = net.ReadUInt(32)
		row.deaths      = net.ReadUInt(32)
		row.score       = net.ReadInt(32)
		row.best_streak = net.ReadUInt(16)
		row.headshots   = net.ReadUInt(32)
		row.multikills  = net.ReadUInt(32)
		row.last_seen   = net.ReadUInt(32)
		rows[i] = row
	end
	TK.Leaderboard.data = rows
	TK.Leaderboard.category = cat
	TK.Leaderboard.isLoading = false
	TK.Leaderboard.lastReceived = CurTime()
end)

local function BuildLeaderboardPage(parent)
	local bar = vgui.Create("DPanel", parent)
	bar:Dock(TOP)
	bar:SetTall(36)
	bar:DockMargin(10, 10, 10, 4)
	bar.Paint = function(s, w, h)
		surface.SetDrawColor(12, 12, 16, 240)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(COL_BORDER)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local cats = GetCategories()
	for _, cat in ipairs(cats) do
		local btn = vgui.Create("DButton", bar)
		btn:Dock(LEFT)
		btn:SetWide(140)
		btn:SetText(cat.label)
		btn:SetFont("DermaDefaultBold")
		btn:SetTextColor(COL_DIM)
		btn.Paint = function(s, w, h)
			local active = (TK.Leaderboard.category == cat.id)
			if active then
				surface.SetDrawColor(255, 200, 50, 40)
				surface.DrawRect(0, 0, w, h)
			end
			surface.SetDrawColor(60, 60, 70)
			surface.DrawRect(w - 1, 4, 1, h - 8)
		end
		btn.DoClick = function()
			if TK.Leaderboard.category == cat.id and #TK.Leaderboard.data > 0 then return end
			TK.Leaderboard.category = cat.id
			TK.Leaderboard.data = {}
			TK.RequestLeaderboard(cat.id)
		end
	end

	local table_ = vgui.Create("DPanel", parent)
	table_:Dock(FILL)
	table_:DockMargin(10, 0, 10, 10)
	table_.Paint = function(s, w, h)
		surface.SetDrawColor(COL_BG)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(COL_BORDER)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		local headerH = 28
		surface.SetDrawColor(COL_HEADER)
		surface.DrawRect(1, 1, w - 2, headerH)

		local order = { "rank", "nick", "kills", "deaths", "kd", "score", "streak", "hs", "ago" }
		local widths = {
			rank = 0.06, nick = 0.28, kills = 0.08, deaths = 0.08, kd = 0.08,
			score = 0.14, streak = 0.08, hs = 0.10, ago = 0.10,
		}
		local xs = {}
		local cursor = 0
		for _, key in ipairs(order) do
			xs[key] = cursor * w
			cursor = cursor + widths[key]
		end

		draw.SimpleText("RANK",   "DermaDefaultBold", xs.rank   + 6, headerH / 2, COL_DIM, 0, 4)
		draw.SimpleText("PLAYER", "DermaDefaultBold", xs.nick   + 6, headerH / 2, COL_DIM, 0, 4)
		draw.SimpleText("K",      "DermaDefaultBold", xs.kills  + 6, headerH / 2, COL_DIM, 0, 4)
		draw.SimpleText("D",      "DermaDefaultBold", xs.deaths + 6, headerH / 2, COL_DIM, 0, 4)
		draw.SimpleText("K/D",    "DermaDefaultBold", xs.kd     + 6, headerH / 2, COL_DIM, 0, 4)
		draw.SimpleText("SCORE",  "DermaDefaultBold", xs.score  + 6, headerH / 2, COL_DIM, 0, 4)
		draw.SimpleText("STREAK", "DermaDefaultBold", xs.streak + 6, headerH / 2, COL_DIM, 0, 4)
		draw.SimpleText("HS",     "DermaDefaultBold", xs.hs     + 6, headerH / 2, COL_DIM, 0, 4)
		draw.SimpleText("LAST",   "DermaDefaultBold", xs.ago    + 6, headerH / 2, COL_DIM, 0, 4)

		local data = TK.Leaderboard.data or {}
		if #data == 0 then
			local msg = TK.Leaderboard.isLoading and "loading..." or "no data"
			draw.SimpleText(msg, "DermaDefault", w / 2, h / 2, COL_DIM, 1, 1)
			return
		end

		local rowH = 26
		local y = headerH + 2
		for i, r in ipairs(data) do
			if y + rowH > h then break end
			local bg = (i % 2 == 1) and COL_ROW_A or COL_ROW_B
			surface.SetDrawColor(bg)
			surface.DrawRect(1, y, w - 2, rowH)

			local rankCol = COL_DIM
			if i == 1 then rankCol = COL_GOLD
			elseif i == 2 then rankCol = COL_SILVER
			elseif i == 3 then rankCol = COL_BRONZE end

			local ry = y + rowH / 2
			draw.SimpleText("#" .. i, "DermaDefaultBold", xs.rank + 6, ry, rankCol, 0, 4)

			local nickW = widths.nick * w - 12
			draw.SimpleText(Trunc(r.nick, "DermaDefaultBold", nickW),
				"DermaDefaultBold", xs.nick + 6, ry, COL_TEXT, 0, 4)

			draw.SimpleText(tostring(r.kills),  "DermaDefault", xs.kills  + 6, ry, COL_TEXT, 0, 4)
			draw.SimpleText(tostring(r.deaths), "DermaDefault", xs.deaths + 6, ry, COL_DIM,  0, 4)

			local kd = (r.deaths > 0) and (r.kills / r.deaths) or r.kills
			draw.SimpleText(FormatKD(r.kills, r.deaths), "DermaDefault",
				xs.kd + 6, ry, kd >= 1 and COL_GREEN or COL_RED, 0, 4)

			draw.SimpleText(string.Comma(r.score or 0), "DermaDefault", xs.score + 6, ry, COL_AMBER, 0, 4)
			draw.SimpleText(tostring(r.best_streak),    "DermaDefault", xs.streak + 6, ry, COL_BLUE, 0, 4)
			draw.SimpleText(tostring(r.headshots),      "DermaDefault", xs.hs + 6, ry, COL_TEXT, 0, 4)
			draw.SimpleText(FormatTimeAgo(r.last_seen), "DermaDefault", xs.ago + 6, ry, COL_DIM, 0, 4)

			y = y + rowH
		end
	end

	if not TK.Leaderboard.data or #TK.Leaderboard.data == 0 then
		TK.RequestLeaderboard(TK.Leaderboard.category or DefaultCategory())
	end
end

TK.BuildLeaderboardPage = BuildLeaderboardPage
