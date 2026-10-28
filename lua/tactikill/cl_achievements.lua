local TK = TACTIKILL
local C  = TK.Config

TK.Achievements = TK.Achievements or {}
local A = TK.Achievements

local cvBanner = CreateClientConVar("tactikill_ach_banner", "1", true, false, "Show achievement banners")
local cvSound  = CreateClientConVar("tactikill_ach_sound",  "1", true, false, "Play achievement sound")

A.Unlocked    = A.Unlocked or {}
A.Queue       = A.Queue or {}
A.Banner      = A.Banner or nil
A.LastRequest = A.LastRequest or 0

local function PlayUnlockSound()
	if not cvSound:GetBool() then return end
	surface.PlaySound("ui/achievement_earned.wav")
end

net.Receive("TACTIKILL_Achievement", function()
	local id   = net.ReadString()
	local name = net.ReadString()
	local desc = net.ReadString()
	local icon = net.ReadString()

	A.Unlocked[id] = true

	table.insert(A.Queue, { id = id, name = name, desc = desc, icon = icon, t = CurTime() })
	PlayUnlockSound()
	notification.AddLegacy("[Achievement] " .. name .. " — " .. desc, NOTIFY_GENERIC, 5)
end)

net.Receive("TACTIKILL_AchievementsSync", function()
	local n = net.ReadUInt(10)
	A.Unlocked = {}
	for _ = 1, n do
		local id = net.ReadString()
		A.Unlocked[id] = true
	end
end)

local function RequestSync()
	if RealTime() - A.LastRequest > 2 then
		A.LastRequest = RealTime()
		net.Start("TACTIKILL_RequestAchievements")
		net.SendToServer()
	end
end

hook.Add("InitPostEntity", "TACTIKILL_Ach_Init", function()
	timer.Simple(2, RequestSync)
end)

hook.Add("HUDPaint", "TACTIKILL_Ach_Banner", function()
	if not cvBanner:GetBool() then return end

	if not A.Banner and #A.Queue > 0 then
		A.Banner = table.remove(A.Queue, 1)
		A.Banner.startT = CurTime()
	end
	if not A.Banner then return end

	local b = A.Banner
	local now = CurTime()
	local life = 4
	local age = now - b.startT
	if age >= life then
		A.Banner = nil
		return
	end

	local sw, sh = ScrW(), ScrH()
	local scale = math.Clamp(sh / 1080, 0.7, 1.5)
	local w = math.floor(420 * scale)
	local h = math.floor(88 * scale)
	local x = sw / 2 - w / 2
	local y = sh * 0.24

	local a = 1
	if age < 0.2 then a = age / 0.2
	elseif age > life - 0.6 then a = (life - age) / 0.6 end
	a = math.Clamp(a, 0, 1)

	local slide = 0
	if age < 0.25 then slide = (1 - age / 0.25) * 50 * scale end
	y = y - slide

	surface.SetDrawColor(20, 18, 10, 230 * a)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(255, 200, 50, 255 * a)
	surface.DrawOutlinedRect(x, y, w, h, math.max(2, math.floor(2 * scale)))

	local iconSize = math.floor(60 * scale)
	local iconX = x + math.floor(15 * scale)
	local iconY = y + (h - iconSize) / 2

	surface.SetDrawColor(255, 200, 50, 255 * a)
	surface.DrawRect(iconX, iconY, iconSize, iconSize)

	draw.SimpleText(b.icon, "DermaLarge", iconX + iconSize / 2, iconY + iconSize / 2,
		Color(20, 18, 10, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local tx = iconX + iconSize + math.floor(15 * scale)
	draw.SimpleText("ACHIEVEMENT UNLOCKED", "DermaDefaultBold", tx, y + math.floor(16 * scale),
		Color(255, 200, 50, 255 * a))
	draw.SimpleText(b.name, "DermaLarge", tx, y + math.floor(42 * scale),
		Color(255, 240, 200, 255 * a))
	draw.SimpleText(b.desc, "DermaDefault", tx, y + math.floor(66 * scale),
		Color(200, 200, 200, 255 * a))
end)

local function BuildPanel()
	if IsValid(A.Panel) then A.Panel:Remove() end

	local frame = vgui.Create("DFrame")
	A.Panel = frame
	frame:SetSize(math.min(ScrW() * 0.9, 900), math.min(ScrH() * 0.85, 700))
	frame:Center()
	frame:SetTitle("TactiKill — Achievements")
	frame:MakePopup()

	local scroll = vgui.Create("DScrollPanel", frame)
	scroll:Dock(FILL)
	scroll:DockMargin(8, 8, 8, 8)

	local unlocked = 0
	for _ in pairs(A.Unlocked) do unlocked = unlocked + 1 end

	local header = vgui.Create("DLabel", scroll)
	header:SetText(string.format("Unlocked: %d / %d", unlocked, #A.List))
	header:SetFont("DermaLarge")
	header:SetTextColor(Color(255, 200, 50))
	header:Dock(TOP)
	header:DockMargin(0, 0, 0, 8)

	local groups, order = {}, {}
	for _, def in ipairs(A.List) do
		local cat = def.category or "General"
		if not groups[cat] then
			groups[cat] = {}
			order[#order + 1] = cat
		end
		table.insert(groups[cat], def)
	end

	for _, catName in ipairs(order) do
		local catLbl = vgui.Create("DLabel", scroll)
		catLbl:SetText("— " .. catName .. " —")
		catLbl:SetFont("DermaDefaultBold")
		catLbl:SetTextColor(Color(255, 180, 40))
		catLbl:Dock(TOP)
		catLbl:DockMargin(0, 10, 0, 4)

		for _, def in ipairs(groups[catName]) do
			local isUnlocked = A.Unlocked[def.id] or false

			local row = vgui.Create("DPanel", scroll)
			row:Dock(TOP)
			row:DockMargin(0, 2, 0, 2)
			row:SetTall(58)

			row.Paint = function(s, w, h)
				surface.SetDrawColor(isUnlocked and Color(60, 50, 20, 220) or Color(30, 30, 35, 220))
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(isUnlocked and Color(255, 200, 50, 180) or Color(80, 80, 90, 180))
				surface.DrawOutlinedRect(0, 0, w, h, 1)
			end

			local iconBox = vgui.Create("DPanel", row)
			iconBox:SetPos(6, 6)
			iconBox:SetSize(46, 46)
			iconBox.Paint = function(s, w, h)
				surface.SetDrawColor(isUnlocked and Color(255, 200, 50) or Color(80, 80, 90))
				surface.DrawRect(0, 0, w, h)
				draw.SimpleText(def.icon, "DermaLarge", w / 2, h / 2,
					isUnlocked and Color(20, 18, 10) or Color(180, 180, 190),
					TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

			local nameLbl = vgui.Create("DLabel", row)
			nameLbl:SetPos(62, 2)
			nameLbl:SetSize(row:GetWide() - 68, 22)
			nameLbl:SetText(def.name)
			nameLbl:SetFont("DermaDefaultBold")
			nameLbl:SetTextColor(isUnlocked and Color(255, 240, 200) or Color(180, 180, 190))

			local descLbl = vgui.Create("DLabel", row)
			descLbl:SetPos(62, 24)
			descLbl:SetSize(row:GetWide() - 68, 22)
			descLbl:SetText(def.desc)
			descLbl:SetFont("DermaDefault")
			descLbl:SetTextColor(isUnlocked and Color(200, 200, 200) or Color(130, 130, 140))

			local stateLbl = vgui.Create("DLabel", row)
			stateLbl:SetPos(62, 44)
			stateLbl:SetSize(row:GetWide() - 68, 14)
			stateLbl:SetText(isUnlocked and "UNLOCKED" or "LOCKED")
			stateLbl:SetFont("DermaDefault")
			stateLbl:SetTextColor(isUnlocked and Color(120, 220, 120) or Color(120, 120, 130))
		end
	end
end

concommand.Add("tactikill_achievements", function()
	BuildPanel()
end, nil, "Open achievements panel")

concommand.Add("tactikill_achievements_refresh", function()
	RequestSync()
end, nil, "Refresh achievements from server")

hook.Add("PopulateToolMenu", "TACTIKILL_Ach_Settings", function()
	spawnmenu.AddToolMenuOption("Utilities", "TactiKill", "tactikill_ach", "Achievements", "", "", function(panel)
		panel:ClearControls()
		panel:Help("Achievement banners")
		panel:CheckBox("Show achievement banner", "tactikill_ach_banner")
		panel:CheckBox("Play achievement sound", "tactikill_ach_sound")

		local btn = panel:Button("Open achievements panel")
		btn.DoClick = function() BuildPanel() end

		local refresh = panel:Button("Refresh from server")
		refresh.DoClick = function() RequestSync() end
	end)
end)