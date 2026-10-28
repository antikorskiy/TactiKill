local TK = TACTIKILL
local C  = TK.Config

local function cv(name, def, lo, hi, help)
	return CreateClientConVar(name, tostring(def), true, false, help, lo, hi)
end

TK.CV = {
	shake    = cv("tactikill_shake_enabled",    1, 0, 1, "Enable TactiKill screen shake"),
	mult     = cv("tactikill_shake_multiplier", 1, 0, 1, "Personal screen shake strength (0..1)"),
	max      = cv("tactikill_shake_max", C.ScreenShakeMaxIntensity, 0, 10, "Personal shake intensity cap"),
	rankup   = cv("tactikill_rankup_shake",     1, 0, 1, "Shake impulse on rank up"),
	hudscale = cv("tactikill_hud_scale",        1, 0.6, 1.6, "HUD scale"),
	timer    = cv("tactikill_hud_timer",        1, 0, 1, "Show the session timer on the HUD"),
	logs     = cv("tactikill_hud_logs",         1, 0, 1, "Show style logs on the HUD"),
}

local DEFAULTS = {
	tactikill_shake_enabled         = "1",
	tactikill_shake_multiplier      = "1",
	tactikill_shake_max             = tostring(C.ScreenShakeMaxIntensity),
	tactikill_rankup_shake          = "1",
	tactikill_hud                   = C.HUDEnabledByDefault and "1" or "0",
	tactikill_hud_scale             = "1",
	tactikill_hud_timer             = "1",
	tactikill_hud_logs              = "1",
	tactikill_hud_rank              = "1",
	tactikill_hud_insignia          = "1",
	tactikill_hud_brand             = "1",
	tactikill_hud_rank_progress     = "1",
	tactikill_hud_banner_duration   = "1.8",
	tactikill_sound_rankup          = "1",
	tactikill_hud_kd                = "1",
	tactikill_hud_hp                = "1",
	tactikill_hud_lowhp_threshold   = "30",
	tactikill_scoreboard            = "1",
    tactikill_hud_lowhp_threshold   = "30",
    tactikill_scoreboard            = "1",
    tactikill_ach_banner            = "1",   
    tactikill_ach_sound             = "1",
}
}

function TK.BuildSettings(panel)
	panel:Help("HUD")
	panel:CheckBox("Show TactiKill HUD", "tactikill_hud")
	panel:CheckBox("Show player rank panel", "tactikill_hud_rank")
	panel:CheckBox("Show rank insignia", "tactikill_hud_insignia")
	panel:CheckBox("Show TactiKill branding header", "tactikill_hud_brand")
	panel:CheckBox("Show rank progress bar", "tactikill_hud_rank_progress")
	panel:CheckBox("Show K/D row", "tactikill_hud_kd")
	panel:CheckBox("Show HEALTH row", "tactikill_hud_hp")
	panel:NumSlider("Health warning threshold (%)", "tactikill_hud_lowhp_threshold", 5, 100, 0)
	panel:NumSlider("Rank banner duration (s)", "tactikill_hud_banner_duration", 0.5, 10, 1)
	panel:NumSlider("HUD scale", "tactikill_hud_scale", 0.6, 1.6, 2)
	panel:CheckBox("Show session timer", "tactikill_hud_timer")
	panel:CheckBox("Show style logs", "tactikill_hud_logs")

	panel:Help("Scoreboard (TAB)")
	panel:CheckBox("Use TactiKill scoreboard", "tactikill_scoreboard")

	panel:Help("Sound")
	panel:CheckBox("Play sound on combo rank up", "tactikill_sound_rankup")

	panel:Help("Screen shake (subtle camera offset, no view-angle changes)")
	if not C.ScreenShakeEnabled then
		panel:ControlHelp("Screen shake is disabled in the server/addon configuration.")
	end
	panel:CheckBox("Enable screen shake", "tactikill_shake_enabled")
	panel:NumSlider("Strength", "tactikill_shake_multiplier", 0, 1, 2)
	panel:NumSlider("Max intensity", "tactikill_shake_max", 0, 10, 2)
	if C.RankUpShakeEnabled then
		panel:CheckBox("Impulse when a new rank is reached", "tactikill_rankup_shake")
	end

	local test = panel:Button("Test shake")
	test.DoClick = function()
		if TK.Shake and TK.Shake.Test then TK.Shake.Test() end
	end

	local testSnd = panel:Button("Test rank-up sound")
	testSnd.DoClick = function()
		if TK.PlayRankUpSound then TK.PlayRankUpSound() end
	end

	local reset = panel:Button("Reset these settings to defaults")
	reset.DoClick = function()
		for name, val in pairs(DEFAULTS) do RunConsoleCommand(name, val) end
	end

	TK.BuildAdminSettings(panel)
end

net.Receive("TACTIKILL_Settings", function()
	local n = net.ReadUInt(10)
	for _ = 1, n do
		local id  = net.ReadString()
		local raw = net.ReadString()
		local def = TK.SettingsById[id]
		if def then TK.ApplySetting(def, TK.ParseValue(def, raw), true) end
	end
end)

local function SendSetting(id, raw)
	net.Start("TACTIKILL_SetSetting")
		net.WriteString(id)
		net.WriteString(raw)
	net.SendToServer()
end

local function AddControl(cat, def)
	local cur = TK.GetSettingValue(def)

	if def.type == "bool" then
		local cb = cat:CheckBox(def.label)
		cb:SetValue(cur and 1 or 0)
		cb.OnChange = function(_, val) SendSetting(def.id, val and "1" or "0") end
	elseif def.type == "enum" then
		local combo = cat:ComboBox(def.label)
		for _, opt in ipairs(def.enum) do combo:AddChoice(opt, opt, opt == cur) end
		combo.OnSelect = function(_, _, val) SendSetting(def.id, val) end
	elseif def.type == "string" then
		local entry = cat:TextEntry(def.label)
		entry:SetValue(tostring(cur or ""))
		entry.OnEnter = function(_, val) SendSetting(def.id, val) end
		entry.OnLoseFocus = function(_, val) SendSetting(def.id, val) end
	else
		local sl = cat:NumSlider(def.label, nil, def.lo, def.hi, def.dec)
		sl:SetValue(cur)
		sl.OnValueChanged = function(_, val)
			timer.Create("TACTIKILL_set_" .. def.id, 0.35, 1, function()
				if def.type == "int" then val = math.Round(val) end
				SendSetting(def.id, tostring(val))
			end)
		end
	end
end

function TK.BuildAdminSettings(panel)
	local lp = LocalPlayer()
	if not IsValid(lp) then return end

	if not TK.CanEditSettings(lp) then
		panel:Help("Server settings can only be changed by admins.")
		return
	end

	panel:Help("SERVER SETTINGS (admin) - changes apply to everyone immediately and are saved.")

	local groups = {}
	for _, def in ipairs(TK.SettingsList) do
		local cat = groups[def.group]
		if not cat then
			cat = vgui.Create("DForm", panel)
			cat:SetLabel(def.group)
			cat:SetExpanded(false)
			panel:AddItem(cat)
			groups[def.group] = cat
		end
		AddControl(cat, def)
	end

	local reset = panel:Button("Reset ALL server settings to defaults...")
	reset.DoClick = function()
		Derma_Query("Reset every server setting to the values from sh_config.lua?",
			"TactiKill - confirm", "RESET", function() SendSetting("__reset_all", "") end, "CANCEL", function() end)
	end
end

hook.Add("AddToolMenuCategories", "TACTIKILL_MenuCategory", function()
	spawnmenu.AddToolCategory("Utilities", "TactiKill", "TactiKill")
end)

hook.Add("PopulateToolMenu", "TACTIKILL_MenuEntry", function()
	spawnmenu.AddToolMenuOption("Utilities", "TactiKill", "tactikill_settings", "Settings", "", "", function(panel)
		panel:ClearControls()
		TK.BuildSettings(panel)
	end)
end)