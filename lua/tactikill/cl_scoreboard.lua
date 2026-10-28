local TK = TACTIKILL
local C  = TK.Config

local cvScoreboard = CreateClientConVar("tactikill_scoreboard", "1", true, false, "Use the TactiKill scoreboard")

local Data = {}
local ShowBoard = false
local lastSentReq = 0

local COL_BG     = Color(12, 12, 16, 240)
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

local function BuildFonts()
	local s = math.Clamp(ScrH() / 1080, 0.7, 1.5)
	local face = "Lucida Console"
	local function mk(name, size, weight)
		surface.CreateFont(name, { font = face, size = math.floor(size * s), weight = weight, antialias = true })
	end
	mk("TACTIKILL_SB_Title", 26, 800)
	mk("TACTIKILL_SB_Head",  14, 700)
	mk("TACTIKILL_SB_Row",   15, 600)
	mk("TACTIKILL_SB_Small", 12, 500)
end
BuildFonts()
hook.Add("OnScreenSizeChanged", "TACTIKILL_SB_Fonts", BuildFonts)

net.Receive("TACTIKILL_Scoreboard", function()
	local n = net.ReadUInt(6)
	local incoming = {}
	for _ = 1, n do
		local p = net.ReadEntity()
		local k = net.ReadUInt(32)
		local d = net.ReadUInt(32)
		local s = net.ReadInt(32)
		local pr = net.ReadUInt(8)
		local npr = net.ReadUInt(8)
		local hs = net.ReadUInt(32)
		local mk = net.ReadUInt(32)
		local stk = net.ReadUInt(16)
		local bs = net.ReadUInt(16)
		local sh = net.ReadUInt(32)
		local ht = net.ReadUInt(32)
		local spm = net.ReadUInt(16)
		local ds = net.ReadFloat()
		local dc = net.ReadUInt(32)
		local dmax = net.ReadFloat()
		local dmin = net.ReadFloat()
		local fw = net.ReadString()
		local fwk = net.ReadUInt(16)
		local hb = net.ReadString()
		if IsValid(p) then
			incoming[#incoming + 1] = {
				ply = p, kills = k, deaths = d, score = s, prank = pr, nprank = npr,
				headshots = hs, multikills = mk, streak = stk, bestStreak = bs,
				shots = sh, hits = ht, spm = spm,
				distSum = ds, distCount = dc, distMax = dmax, distMin = dmin,
				favWeapon = fw, favWeaponKills = fwk, hitbox = hb,
			}
		end
	end
	table.sort(incoming, function(a, b)
		if a.kills ~= b.kills then return a.kills > b.kills end
		return a.score > b.score
	end)
	Data = incoming
end)

hook.Add("ScoreboardShow", "TACTIKILL_ScoreboardShow", function()
	if not cvScoreboard:GetBool() then return end
	ShowBoard = true
	return true
end)

hook.Add("ScoreboardHide", "TACTIKILL_ScoreboardHide", function()
	ShowBoard = false
end)

local function RequestIfNeeded()
	if RealTime() - lastSentReq > 0.5 then
		lastSentReq = RealTime()
		net.Start("TACTIKILL_RequestScoreboard")
		net.SendToServer()
	end
end

local function Truncate(str, font, maxW)
	surface.SetFont(font)
	if surface.GetTextSize(str) <= maxW then return str end
	for i = #str, 1, -1 do
		local s = string.sub(str, 1, i) .. "..."
		if surface.GetTextSize(s) <= maxW then return s end
	end
	return str
end

local function FormatKDR(k, d)
	if d == 0 then return k > 0 and string.format("%.2f", k) or "0.00" end
	return string.format("%.2f", k / d)
end

local function FormatHS(hs, k)
	if k == 0 then return "0%" end
	return string.format("%d%%", math.floor(hs / k * 100 + 0.5))
end

local function FormatAcc(hits, shots)
	if shots <= 0 then return "—" end
	local a = math.min(hits / shots, 1) * 100
	return string.format("%d%%", math.floor(a + 0.5))
end

local function FormatDist(d)
	if not d or d <= 0 then return "—" end
	return tostring(math.floor(d + 0.5))
end

local function FormatAvg(sum, count)
	if count <= 0 then return "—" end
	return tostring(math.floor(sum / count + 0.5))
end

local function GetRankName(idx)
	local r = C.PlayerRanks[idx]
	return r and r.name or "?"
end

local cols = {
	{ key = "insignia", label = "",        w = 0.04 },
	{ key = "player",   label = "PLAYER",  w = 0.155 },
	{ key = "kills",    label = "K",       w = 0.035 },
	{ key = "deaths",   label = "D",       w = 0.035 },
	{ key = "kd",       label = "K/D",     w = 0.045 },
	{ key = "score",    label = "SCORE",   w = 0.055 },
	{ key = "spm",      label = "SPM",     w = 0.035 },
	{ key = "streak",   label = "STREAK",  w = 0.055 },
	{ key = "hs",       label = "HS",      w = 0.07 },
	{ key = "multi",    label = "MULTI",   w = 0.045 },
	{ key = "dist",     label = "DIST",    w = 0.09 },
	{ key = "acc",      label = "ACC",     w = 0.045 },
	{ key = "hitbox",   label = "HITBOX",  w = 0.10 },
	{ key = "favwep",   label = "FAV WEAPON", w = 0.155 },
}

hook.Add("HUDPaint", "TACTIKILL_Scoreboard", function()
	if not ShowBoard then return end
	if not cvScoreboard:GetBool() then return end
	if not IsValid(LocalPlayer()) then return end
	RequestIfNeeded()

	local sw, sh = ScrW(), ScrH()
	local scale = math.Clamp(sh / 1080, 0.7, 1.5)
	local bw = math.min(sw * 0.96, 1600 * scale)
	local x = (sw - bw) / 2
	local y = sh * 0.06

	local titleH  = math.floor(52 * scale)
	local headerH = math.floor(28 * scale)
	local rowH    = math.floor(44 * scale)
	local maxRows = 15
	local shown   = math.max(#Data, 1)
	local bh      = titleH + headerH + math.min(shown, maxRows) * rowH + math.floor(22 * scale)

	surface.SetDrawColor(COL_BG)
	surface.DrawRect(x, y, bw, bh)
	surface.SetDrawColor(COL_BORDER)
	surface.DrawOutlinedRect(x, y, bw, bh, 1)
	surface.SetDrawColor(COL_AMBER)
	surface.DrawRect(x, y, math.max(math.floor(4 * scale), 2), bh)

	draw.SimpleText("TACTIKILL", "TACTIKILL_SB_Title", x + math.floor(20 * scale), y + math.floor(10 * scale), COL_AMBER)
	draw.SimpleText("COMBAT SCOREBOARD", "TACTIKILL_SB_Head",
		x + math.floor(20 * scale) + math.floor(190 * scale), y + math.floor(22 * scale), COL_DIM)
	draw.SimpleText(string.format("%d players  •  sorted by kills", #Data), "TACTIKILL_SB_Small",
		x + bw - math.floor(20 * scale), y + math.floor(22 * scale), COL_DIM, TEXT_ALIGN_RIGHT)

	local innerX = x + math.floor(14 * scale)
	local innerW = bw - math.floor(28 * scale)

	local colX = {}
	local cx = innerX
	for i, c in ipairs(cols) do
		colX[i] = cx
		cx = cx + math.floor(innerW * c.w)
	end

	local hy = y + titleH
	surface.SetDrawColor(COL_HEADER)
	surface.DrawRect(x + 1, hy, bw - 2, headerH)

	for i, c in ipairs(cols) do
		if c.label ~= "" then
			draw.SimpleText(c.label, "TACTIKILL_SB_Head", colX[i], hy + headerH / 2, COL_DIM)
		end
	end

	if #Data == 0 then
		draw.SimpleText("waiting for data...", "TACTIKILL_SB_Row",
			x + bw / 2, hy + headerH + rowH, COL_DIM, TEXT_ALIGN_CENTER)
		return
	end

	local me = LocalPlayer()
	local y1Off = math.floor(rowH * 0.30)
	local y2Off = math.floor(rowH * 0.72)

	for idx, row in ipairs(Data) do
		if idx > maxRows then break end
		local ry = hy + headerH + (idx - 1) * rowH
		local y1 = ry + y1Off
		local y2 = ry + y2Off

		local bgCol = (idx % 2 == 1) and COL_ROW_A or COL_ROW_B
		surface.SetDrawColor(bgCol)
		surface.DrawRect(x + 1, ry, bw - 2, rowH)

		if row.ply == me then
			surface.SetDrawColor(COL_AMBER.r, COL_AMBER.g, COL_AMBER.b, 40)
			surface.DrawRect(x + 1, ry, bw - 2, rowH)
			surface.SetDrawColor(COL_AMBER)
			surface.DrawRect(x + 1, ry, math.max(math.floor(3 * scale), 2), rowH)
		end

		local ins = TK.GetRankInsignia(row.prank)
		draw.SimpleText(ins, "TACTIKILL_SB_Head", colX[1], ry + rowH / 2, COL_AMBER)

		local nameW = innerW * cols[2].w - math.floor(6 * scale)
		local nameCol = row.ply:IsAdmin() and COL_RED or (row.ply == me and COL_AMBER or COL_TEXT)
		draw.SimpleText(Truncate(row.ply:Nick(), "TACTIKILL_SB_Row", nameW),
			"TACTIKILL_SB_Row", colX[2], y1, nameCol)

		local nextName = row.nprank > 0 and ("NEXT: " .. GetRankName(row.nprank)) or "MAX RANK"
		local nextCol = row.nprank > 0 and COL_DIM or COL_GREEN
		draw.SimpleText(Truncate(nextName, "TACTIKILL_SB_Small", nameW),
			"TACTIKILL_SB_Small", colX[2], y2, nextCol)

		draw.SimpleText(tostring(row.kills), "TACTIKILL_SB_Row", colX[3], ry + rowH / 2, COL_TEXT)
		draw.SimpleText(tostring(row.deaths), "TACTIKILL_SB_Row", colX[4], ry + rowH / 2, COL_DIM)

		local kd = row.deaths > 0 and (row.kills / row.deaths) or row.kills
		draw.SimpleText(FormatKDR(row.kills, row.deaths), "TACTIKILL_SB_Row", colX[5], ry + rowH / 2,
			kd >= 1 and COL_GREEN or COL_RED)

		draw.SimpleText(string.Comma(row.score), "TACTIKILL_SB_Row", colX[6], ry + rowH / 2, COL_AMBER)

		draw.SimpleText(tostring(row.spm), "TACTIKILL_SB_Row", colX[7], ry + rowH / 2, COL_TEXT)

		draw.SimpleText(tostring(row.streak), "TACTIKILL_SB_Row", colX[8], y1, COL_BLUE)
		draw.SimpleText("best " .. row.bestStreak, "TACTIKILL_SB_Small", colX[8], y2, COL_DIM)

		draw.SimpleText(tostring(row.headshots), "TACTIKILL_SB_Row", colX[9], y1, COL_TEXT)
		draw.SimpleText(FormatHS(row.headshots, row.kills), "TACTIKILL_SB_Small", colX[9], y2, COL_DIM)

		draw.SimpleText(tostring(row.multikills), "TACTIKILL_SB_Row", colX[10], ry + rowH / 2,
			row.multikills > 0 and COL_AMBER or COL_DIM)

		draw.SimpleText(FormatDist(row.distMin) .. " / " .. FormatDist(row.distMax),
			"TACTIKILL_SB_Row", colX[11], y1, COL_TEXT)
		draw.SimpleText("avg " .. FormatAvg(row.distSum, row.distCount),
			"TACTIKILL_SB_Small", colX[11], y2, COL_DIM)

		local acc = FormatAcc(row.hits, row.shots)
		local accCol = COL_TEXT
		if row.shots > 0 then
			local pct = math.min(row.hits / row.shots, 1) * 100
			accCol = pct >= 30 and COL_GREEN or (pct >= 15 and COL_AMBER or COL_RED)
		end
		draw.SimpleText(acc, "TACTIKILL_SB_Row", colX[12], ry + rowH / 2, accCol)

		local hb = row.hitbox ~= "" and row.hitbox or "—"
		draw.SimpleText(Truncate(hb, "TACTIKILL_SB_Row", innerW * cols[13].w - math.floor(6 * scale)),
			"TACTIKILL_SB_Row", colX[13], ry + rowH / 2, COL_TEXT)

		local wep = row.favWeapon
		if row.favWeaponKills > 0 then
			local wepW = innerW * cols[14].w - math.floor(40 * scale)
			draw.SimpleText(Truncate(wep, "TACTIKILL_SB_Row", wepW),
				"TACTIKILL_SB_Row", colX[14], y1, COL_TEXT)
			draw.SimpleText(row.favWeaponKills .. " kills", "TACTIKILL_SB_Small",
				colX[14], y2, COL_DIM)
		else
			draw.SimpleText("—", "TACTIKILL_SB_Row", colX[14], ry + rowH / 2, COL_DIM)
		end
	end

	local lastY = hy + headerH + math.min(#Data, maxRows) * rowH

	local gMin, gMax, gShots, gHits = 0, 0, 0, 0
	for _, row in ipairs(Data) do
		if row.distMin > 0 and (gMin == 0 or row.distMin < gMin) then gMin = row.distMin end
		if row.distMax > gMax then gMax = row.distMax end
		gShots = gShots + row.shots
		gHits = gHits + row.hits
	end

	local accStr = "—"
	if gShots > 0 then
		accStr = string.format("%d%%", math.floor(math.min(gHits / gShots, 1) * 100 + 0.5))
	end

	local summary = string.format(
		"SESSION: closest %s u  •  farthest %s u  •  overall acc %s  •  %d players  •  TAB to close",
		gMin > 0 and math.floor(gMin + 0.5) or "—",
		gMax > 0 and math.floor(gMax + 0.5) or "—",
		accStr, #Data)

	draw.SimpleText(summary, "TACTIKILL_SB_Small",
		x + bw / 2, lastY + math.floor(11 * scale), COL_DIM, TEXT_ALIGN_CENTER)
end)