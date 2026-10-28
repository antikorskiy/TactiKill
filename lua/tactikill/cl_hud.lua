local TK = TACTIKILL
local C  = TK.Config

local cvHUD        = CreateClientConVar("tactikill_hud", C.HUDEnabledByDefault and "1" or "0", true, false, "")
local cvRank       = CreateClientConVar("tactikill_hud_rank", "1", true, false, "")
local cvInsignia   = CreateClientConVar("tactikill_hud_insignia", "1", true, false, "")
local cvBrand      = CreateClientConVar("tactikill_hud_brand", "1", true, false, "")
local cvProgress   = CreateClientConVar("tactikill_hud_rank_progress", "1", true, false, "")
local cvBannerDur  = CreateClientConVar("tactikill_hud_banner_duration", "1.8", true, false, "", 0.5, 10)
local cvSnd        = CreateClientConVar("tactikill_sound_rankup", "1", true, false, "")
local cvKD         = CreateClientConVar("tactikill_hud_kd", "1", true, false, "")
local cvHp         = CreateClientConVar("tactikill_hud_hp", "1", true, false, "")
local cvLowHpThr   = CreateClientConVar("tactikill_hud_lowhp_threshold", "30", true, false, "", 5, 100)

local H = {
	kills = 0, deaths = 0, score = 0, streak = 0, rank = 0, playerRank = 1, multikill = 0,
	expireAt = 0, duration = 0,
	timerRunning = false, timerElapsed = 0, timerRecv = 0,
	logs = {}, banner = nil, playerBanner = nil, firstUpdate = true,
}
TK.HUD = H

local COL_BG     = Color(12, 12, 16, 190)
local COL_BORDER = Color(70, 70, 80, 255)
local COL_TEXT   = Color(235, 235, 235, 255)
local COL_DIM    = Color(150, 150, 160, 255)
local COL_AMBER  = Color(255, 190, 40, 255)
local COL_RED    = Color(255, 64, 56, 255)
local COL_BLUE   = Color(80, 160, 255, 255)
local COL_GREEN  = Color(120, 220, 120, 255)
local COL_BAR_BG = Color(40, 40, 48, 255)
local scratch    = Color(255, 255, 255, 255)

local KIND_COLOR = { [0] = COL_TEXT, [1] = COL_AMBER, [2] = COL_RED, [3] = COL_DIM, [4] = COL_BLUE }

local fontGen = 0
local currentSound

local function NormalizeSoundPath(p)
	if not p or p == "" then return nil end
	if not string.StartsWith(p, "sound/") then p = "sound/" .. p end
	return p
end

function TK.PlayRankUpSound(path)
	path = NormalizeSoundPath(path or C.ComboRankUpSound)
	if not path then return end

	if currentSound and currentSound.IsValid and currentSound:IsValid() then
		currentSound:Stop()
		currentSound = nil
	end

	currentSound = sound.PlayFile(path, "noblock", function(snd, errCode, errStr)
		if not IsValid(snd) then
			TK.Debug("rank-up sound failed: %s (%s)", tostring(errStr), tostring(errCode))
		end
	end)
end

local function GetScale()
	return math.Clamp(ScrH() / 1080, 0.6, 2) * math.Clamp(TK.CV.hudscale:GetFloat(), 0.5, 2)
end

local function BuildFonts()
	local s = GetScale()
	local face = "Lucida Console"
	local function mk(name, size, weight)
		surface.CreateFont(name, { font = face, size = math.floor(size * s), weight = weight, antialias = true })
	end
	mk("TACTIKILL_Big", 30, 800)
	mk("TACTIKILL_Med", 22, 700)
	mk("TACTIKILL_Small", 15, 600)
	mk("TACTIKILL_Log", 20, 700)
	fontGen = fontGen + 1
end
BuildFonts()
hook.Add("OnScreenSizeChanged", "TACTIKILL_Fonts", BuildFonts)
cvars.AddChangeCallback("tactikill_hud_scale", function() BuildFonts() end, "TACTIKILL_HUDScale")

local function AddLog(text, bonus, kind)
	local logs = H.logs
	table.insert(logs, 1, { text = text, bonus = bonus, kind = kind, t = CurTime() })
	while #logs > C.MaxLogs do table.remove(logs) end
end

net.Receive("TACTIKILL_Update", function()
	local now = CurTime()
	local oldRank = H.rank
	local oldPlayerRank = H.playerRank

	H.kills       = net.ReadUInt(32)
	H.deaths      = net.ReadUInt(32)
	H.score       = net.ReadInt(32)
	H.streak      = net.ReadUInt(16)
	H.rank        = net.ReadUInt(8)
	H.playerRank  = net.ReadUInt(8)
	H.multikill   = net.ReadUInt(8)
	local remaining = net.ReadFloat()
	H.duration    = net.ReadFloat()
	H.expireAt    = now + remaining

	local n = net.ReadUInt(5)
	for _ = 1, n do
		local text  = net.ReadString()
		local bonus = net.ReadInt(16)
		local kind  = net.ReadUInt(3)
		AddLog(text, bonus, kind)
	end

	if H.rank > oldRank and C.Ranks[H.rank] then
		H.banner = { name = C.Ranks[H.rank].name, t = now }
		if C.ComboRankUpSoundEnabled and cvSnd:GetBool() then
			TK.PlayRankUpSound()
		end
	end

	if not H.firstUpdate and H.playerRank > oldPlayerRank and C.PlayerRanks[H.playerRank] then
		H.playerBanner = { name = C.PlayerRanks[H.playerRank].name, t = now }
	end
	H.firstUpdate = false

	if TK.Shake then TK.Shake.OnRank(H.rank, now) end
end)

net.Receive("TACTIKILL_Timer", function()
	H.timerRunning = net.ReadBool()
	H.timerElapsed = net.ReadFloat()
	H.timerRecv    = CurTime()
end)

net.Receive("TACTIKILL_Notify", function()
	local msg  = net.ReadString()
	local kind = net.ReadUInt(2)
	notification.AddLegacy(msg, kind == 1 and NOTIFY_ERROR or NOTIFY_GENERIC, 3)
end)

net.Receive("TACTIKILL_ToggleHUD", function()
	local newState = not cvHUD:GetBool()
	RunConsoleCommand("tactikill_hud", newState and "1" or "0")
	notification.AddLegacy("TACTIKILL HUD " .. (newState and "ENABLED" or "HIDDEN") .. " (statistics unchanged)",
		NOTIFY_GENERIC, 3)
end)

hook.Add("InitPostEntity", "TACTIKILL_RequestSync", function()
	net.Start("TACTIKILL_RequestSync")
	net.SendToServer()
end)

local function DrawPanel(x, y, w, h, accent, s)
	surface.SetDrawColor(COL_BG)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(COL_BORDER)
	surface.DrawOutlinedRect(x, y, w, h, 1)
	surface.SetDrawColor(accent)
	surface.DrawRect(x, y, math.max(math.floor(3 * s), 2), h)
end

local function Text(str, font, x, y, col, ax, ay)
	draw.SimpleText(str, font, x, y, col, ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_CENTER)
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

local function PaintPlayerRank(x, y, w, s, now)
	if not cvRank:GetBool() then return 0 end
	local ranks = C.PlayerRanks
	if not ranks or #ranks == 0 then return 0 end

	local idx  = math.Clamp(H.playerRank or 1, 1, #ranks)
	local rank = ranks[idx]
	local nxt  = ranks[idx + 1]

	local pad = math.floor(10 * s)
	local px  = x + pad + math.floor(4 * s)
	local rx  = x + w - pad
	local h   = math.floor(82 * s)

	DrawPanel(x, y, w, h, COL_AMBER, s)

	local row1Y = y + pad + math.floor(12 * s)
	if cvInsignia:GetBool() then
		local ins = TK.GetRankInsignia(idx)
		if ins ~= "" then Text(ins, "TACTIKILL_Med", px, row1Y, COL_AMBER) end
	end
	Text("RANK", "TACTIKILL_Small", rx, row1Y, COL_DIM, TEXT_ALIGN_RIGHT)

	local row2Y = row1Y + math.floor(20 * s)
	Text(Truncate(rank.name, "TACTIKILL_Small", rx - px), "TACTIKILL_Small", px, row2Y, COL_TEXT)

	if nxt and cvProgress:GetBool() then
		local killsFrac = math.Clamp((H.kills - rank.min) / math.max(nxt.min - rank.min, 1), 0, 1)
		local scoreFrac = math.Clamp((H.score - (rank.score or 0)) / math.max((nxt.score or 0) - (rank.score or 0), 1), 0, 1)
		local frac = math.min(killsFrac, scoreFrac)

		local bh = math.floor(10 * s)
		local bx = px
		local by = y + h - pad - bh
		local bw = rx - px
		surface.SetDrawColor(COL_BAR_BG)
		surface.DrawRect(bx, by, bw, bh)
		surface.SetDrawColor(frac >= 1 and COL_GREEN or COL_AMBER)
		surface.DrawRect(bx, by, math.floor(bw * frac), bh)

		Text(string.format("%d/%d  %d/%d", H.kills, nxt.min, H.score, nxt.score or 0),
			"TACTIKILL_Small", bx + bw / 2, by + bh / 2, COL_TEXT, TEXT_ALIGN_CENTER)
	elseif not nxt then
		Text("MAX RANK", "TACTIKILL_Small", px, y + h - pad - math.floor(11 * s), COL_GREEN)
	end
	return h
end

local function PaintStats(x, y, w, s, now)
	local pad = math.floor(10 * s)
	local rowH = math.floor(28 * s)
	local showTimer = C.SessionShowOnHUD and TK.CV.timer:GetBool()
	local showBrand = cvBrand:GetBool()
	local showKD    = cvKD:GetBool()
	local showHp    = cvHp:GetBool()
	local rows = 1 + (showKD and 1 or 0) + (showHp and 1 or 0) + 1 + (showTimer and 1 or 0)
	local brandH = showBrand and math.floor(26 * s) or 0
	local h = rows * rowH + pad * 2 + brandH
	local px = x + pad + math.floor(4 * s)
	local rx = x + w - pad
	local cy = y + pad + brandH + rowH / 2

	DrawPanel(x, y, w, h, COL_AMBER, s)

	if showBrand then
		local by = y + pad + math.floor(12 * s)
		Text("TACTIKILL", "TACTIKILL_Small", px, by, COL_AMBER)
		Text("v" .. TK.Version, "TACTIKILL_Small", rx, by, COL_DIM, TEXT_ALIGN_RIGHT)
		local lineY = y + pad + math.floor(20 * s)
		surface.SetDrawColor(COL_BORDER.r, COL_BORDER.g, COL_BORDER.b, 128)
		surface.DrawRect(px, lineY, rx - px, math.max(1, math.floor(s)))
	end

	Text("KILLS", "TACTIKILL_Small", px, cy, COL_DIM)
	Text(string.Comma(H.kills), "TACTIKILL_Med", rx, cy, COL_TEXT, TEXT_ALIGN_RIGHT)

	if showKD then
		cy = cy + rowH
		local kd = H.deaths > 0 and (H.kills / H.deaths) or H.kills
		local kdCol = kd >= 1 and COL_GREEN or COL_RED
		Text("K / D  (" .. H.deaths .. ")", "TACTIKILL_Small", px, cy, COL_DIM)
		Text(string.format("%.2f", kd), "TACTIKILL_Med", rx, cy, kdCol, TEXT_ALIGN_RIGHT)
	end

	if showHp then
		cy = cy + rowH
		local lp = LocalPlayer()
		local hp = IsValid(lp) and lp:Health() or 0
		local maxHp = IsValid(lp) and lp:GetMaxHealth() or 100
		local frac = maxHp > 0 and math.Clamp(hp / maxHp, 0, 1) or 0
		local thr = cvLowHpThr:GetFloat()
		local hpCol
		if frac * 100 <= thr then
			local pulse = 0.6 + math.sin(RealTime() * 8) * 0.4
			hpCol = Color(255, 64, 56, 200 + 55 * pulse)
		elseif frac * 100 <= thr * 1.5 then
			hpCol = COL_AMBER
		else
			hpCol = COL_GREEN
		end
		Text("HEALTH", "TACTIKILL_Small", px, cy, COL_DIM)
		Text(tostring(hp), "TACTIKILL_Med", rx, cy, hpCol, TEXT_ALIGN_RIGHT)

		local bh = math.floor(4 * s)
		local bx, by = px, cy + rowH / 2 - math.floor(2 * s)
		local bw = rx - px
		surface.SetDrawColor(COL_BAR_BG)
		surface.DrawRect(bx, by, bw, bh)
		surface.SetDrawColor(hpCol)
		surface.DrawRect(bx, by, math.floor(bw * frac), bh)
	end

	cy = cy + rowH
	Text("SCORE", "TACTIKILL_Small", px, cy, COL_DIM)
	Text(string.Comma(H.score), "TACTIKILL_Med", rx, cy, COL_AMBER, TEXT_ALIGN_RIGHT)

	if showTimer then
		cy = cy + rowH
		local elapsed = H.timerElapsed
		if H.timerRunning then elapsed = elapsed + (now - H.timerRecv) end
		Text("TIME", "TACTIKILL_Small", px, cy, COL_DIM)
		Text(TK.FormatTime(elapsed), "TACTIKILL_Med", rx, cy, H.timerRunning and COL_TEXT or COL_DIM, TEXT_ALIGN_RIGHT)
	end
	return h
end

local function PaintCombo(x, y, w, s, now)
	local pad = math.floor(10 * s)
	local px = x + pad + math.floor(4 * s)
	local rx = x + w - pad
	local remaining = math.max(H.expireAt - now, 0)
	local rankData = C.Ranks[H.rank]

	if rankData and remaining > 0 then
		local accent = (H.rank >= C.RedAccentFromRank) and COL_RED or COL_AMBER
		local h = math.floor(92 * s)
		DrawPanel(x, y, w, h, accent, s)

		Text(rankData.name, "TACTIKILL_Med", px, y + pad + math.floor(11 * s), accent)
		local row2 = y + pad + math.floor(44 * s)
		Text("STREAK " .. H.streak, "TACTIKILL_Small", px, row2, COL_TEXT)
		Text(string.format("%.1fs", remaining), "TACTIKILL_Med", rx, row2, COL_TEXT, TEXT_ALIGN_RIGHT)

		local bh = math.floor(8 * s)
		local bx, by = px, y + h - pad - bh
		local bw = rx - px
		local frac = H.duration > 0 and math.Clamp(remaining / H.duration, 0, 1) or 0
		surface.SetDrawColor(COL_BAR_BG)
		surface.DrawRect(bx, by, bw, bh)
		surface.SetDrawColor(accent)
		surface.DrawRect(bx, by, math.floor(bw * frac), bh)
		return h
	end

	if H.streak > 0 then
		local h = math.floor(60 * s)
		DrawPanel(x, y, w, h, COL_BORDER, s)
		Text("COMBO INACTIVE", "TACTIKILL_Small", px, y + pad + math.floor(8 * s), COL_DIM)
		local nxt = TK.GetNextRank(H.streak)
		local line = "STREAK " .. H.streak
		if nxt and H.rank == 0 then line = line .. "  NEXT RANK AT " .. nxt.min end
		Text(line, "TACTIKILL_Small", px, y + pad + math.floor(30 * s), COL_DIM)
		return h
	end
	return 0
end

local function PaintBanner(sw, s, now, banner, y, label, color, life)
	if not banner then return 0 end
	local age = now - banner.t
	if age >= life then return 0 end

	local a = math.min(math.Clamp(age / 0.12, 0, 1), math.Clamp((life - age) / 0.5, 0, 1)) * 255
	surface.SetFont("TACTIKILL_Big")
	local tw, th = surface.GetTextSize(banner.name)
	local padx, pady = math.floor(24 * s), math.floor(10 * s)
	local w, h = tw + padx * 2, th + pady * 2 + math.floor(18 * s)
	local x = sw / 2 - w / 2

	surface.SetDrawColor(12, 12, 16, a * 0.75)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(color.r, color.g, color.b, a)
	surface.DrawOutlinedRect(x, y, w, h, 1)

	scratch.r, scratch.g, scratch.b, scratch.a = COL_DIM.r, COL_DIM.g, COL_DIM.b, a
	Text(label, "TACTIKILL_Small", sw / 2, y + pady + math.floor(6 * s), scratch, TEXT_ALIGN_CENTER)
	scratch.r, scratch.g, scratch.b = color.r, color.g, color.b
	Text(banner.name, "TACTIKILL_Big", sw / 2, y + h - pady - th / 2, scratch, TEXT_ALIGN_CENTER)
	return h
end

local function PaintLogs(sw, sh, s, now)
	local logs = H.logs
	local life = C.LogLifetime

	for i = #logs, 1, -1 do
		if now - logs[i].t >= life then table.remove(logs, i) end
	end
	if #logs == 0 then return end

	local lineH = math.floor(30 * s)
	local gap = math.floor(4 * s)
	local pad = math.floor(10 * s)
	local y0 = sh * 0.66
	local lerpT = math.min(FrameTime() * 14, 1)

	for i, lg in ipairs(logs) do
		if lg.gen ~= fontGen then
			surface.SetFont("TACTIKILL_Log")
			lg.w1 = surface.GetTextSize(lg.text)
			lg.bonusText = (C.ShowLogBonus and lg.bonus ~= 0 and lg.bonus ~= nil) and ("+" .. lg.bonus .. " SCORE") or nil
			lg.w2 = lg.bonusText and surface.GetTextSize(lg.bonusText) or 0
			lg.gen = fontGen
		end

		local ty = y0 + (i - 1) * (lineH + gap)
		lg.y = lg.y and Lerp(lerpT, lg.y, ty) or (ty - 12 * s)

		local age = now - lg.t
		local a = math.min(math.Clamp(age / 0.1, 0, 1), math.Clamp((life - age) / 0.5, 0, 1)) * 255
		a = a * (1 - (i - 1) * 0.07)

		local inner = lg.w1 + (lg.bonusText and (lg.w2 + pad * 2) or 0)
		local w = inner + pad * 2 + math.floor(4 * s)
		local x = sw / 2 - w / 2
		local col = KIND_COLOR[lg.kind] or COL_TEXT

		surface.SetDrawColor(12, 12, 16, a * 0.75)
		surface.DrawRect(x, lg.y, w, lineH)
		surface.SetDrawColor(col.r, col.g, col.b, a)
		surface.DrawRect(x, lg.y, math.max(math.floor(3 * s), 2), lineH)

		scratch.r, scratch.g, scratch.b, scratch.a = col.r, col.g, col.b, a
		local tx = x + pad + math.floor(4 * s)
		Text(lg.text, "TACTIKILL_Log", tx, lg.y + lineH / 2, scratch)

		if lg.bonusText then
			scratch.r, scratch.g, scratch.b = COL_AMBER.r, COL_AMBER.g, COL_AMBER.b
			Text(lg.bonusText, "TACTIKILL_Log", tx + lg.w1 + pad * 2, lg.y + lineH / 2, scratch)
		end
	end
end

hook.Add("HUDPaint", "TACTIKILL_HUD", function()
	if not cvHUD:GetBool() then return end
	if not IsValid(LocalPlayer()) then return end

	local now = CurTime()
	local sw, sh = ScrW(), ScrH()
	local s = GetScale()
	local margin = math.floor(24 * s)
	local w = math.floor(280 * s)
	local x = sw - w - margin
	local y = margin
	local gap = math.floor(10 * s)

	local hRank = PaintPlayerRank(x, y, w, s, now)
	local y2 = y + hRank + (hRank > 0 and gap or 0)
	local h1 = PaintStats(x, y2, w, s, now)
	PaintCombo(x, y2 + h1 + gap, w, s, now)

	local life = cvBannerDur:GetFloat()
	local by = sh * 0.13
	if H.banner then
		if now - H.banner.t >= life then
			H.banner = nil
		else
			local h = PaintBanner(sw, s, now, H.banner, by, "COMBO RANK UP", COL_RED, life)
			by = by + h + (h > 0 and math.floor(8 * s) or 0)
		end
	end
	if H.playerBanner then
		if now - H.playerBanner.t >= life then
			H.playerBanner = nil
		else
			PaintBanner(sw, s, now, H.playerBanner, by, "PLAYER RANK UP", COL_BLUE, life)
		end
	end

	if TK.CV.logs:GetBool() then PaintLogs(sw, sh, s, now) end
end)