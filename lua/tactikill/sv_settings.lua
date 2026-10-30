local TK = TACTIKILL
local C  = TK.Config

util.AddNetworkString("TACTIKILL_Settings")
util.AddNetworkString("TACTIKILL_SetSetting")

TK.Settings = {}
local Settings = TK.Settings

local FILE_DIR  = "tactikill"
local FILE_PATH = "tactikill/settings.json"
local NextAllowed = setmetatable({}, { __mode = "k" })

local function Save()
	local out = {}
	for _, def in ipairs(TK.SettingsList) do
		local cur = TK.GetSettingValue(def)
		if cur ~= TK.SettingsDefaults[def.id] then out[def.id] = cur end
	end

	if next(out) == nil then
		if file.Exists(FILE_PATH, "DATA") then file.Delete(FILE_PATH) end
		return
	end
	file.CreateDir(FILE_DIR)
	file.Write(FILE_PATH, util.TableToJSON(out, true))
end

local function ScheduleSave()
	timer.Create("TACTIKILL_SaveSettings", 1, 1, Save)
end

local function Load()
	if not file.Exists(FILE_PATH, "DATA") then return end
	local data = util.JSONToTable(file.Read(FILE_PATH, "DATA") or "")
	if not istable(data) then
		ErrorNoHalt("[TactiKill] settings.json is corrupt - ignoring it.\n")
		return
	end

	for id, val in pairs(data) do
		local def = TK.SettingsById[id]
		if def then TK.ApplySetting(def, val, true) end
	end

	if not TK.RankMinsValid() then
		ErrorNoHalt("[TactiKill] Saved rank thresholds are inconsistent - restoring defaults for them.\n")
		TK.RestoreRankMins()
	end
	TK.Debug("settings loaded from %s", FILE_PATH)
end

local function Write(defs, ply)
	net.Start("TACTIKILL_Settings")
		net.WriteUInt(#defs, 10)
		for _, def in ipairs(defs) do
			net.WriteString(def.id)
			net.WriteString(TK.SerializeValue(def, TK.GetSettingValue(def)))
		end
	if ply then net.Send(ply) else net.Broadcast() end
end

function Settings.SendAll(ply)
	if not IsValid(ply) or ply:IsBot() then return end
	Write(TK.SettingsList, ply)
end

net.Receive("TACTIKILL_SetSetting", function(_, ply)
	if not IsValid(ply) then return end

	local now = CurTime()
	if (NextAllowed[ply] or 0) > now then return end
	NextAllowed[ply] = now + 0.03

	if not TK.CanEditSettings(ply) then
		TK.Notify(ply, "You are not allowed to change TactiKill settings", 1)
		return
	end

	local id, raw = net.ReadString(), net.ReadString()

	if id == "__reset_all" then
		for _, def in ipairs(TK.SettingsList) do
			TK.ApplySetting(def, TK.SettingsDefaults[def.id], true)
		end
		Save()
		Write(TK.SettingsList)
		TK.Notify(ply, "TactiKill settings reset to defaults", 0)
		return
	end

	local def = TK.SettingsById[id]
	if not def then return end

	local ok = TK.ApplySetting(def, TK.ParseValue(def, raw), false)
	if ok then
		ScheduleSave()
		Write({ def })
		TK.Debug("%s set %s = %s", ply:Nick(), id, tostring(TK.GetSettingValue(def)))
	else
		Write({ def }, ply)
		TK.Notify(ply, "Invalid value for " .. def.label, 1)
	end
end)

Load()
