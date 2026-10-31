TACTIKILL = TACTIKILL or {}

local function AddSoundFolder(folder)
	for _, ext in ipairs({ "mp3", "wav", "ogg" }) do
		local files = file.Find(folder .. "/*." .. ext, "GAME")
		for _, f in ipairs(files) do
			resource.AddFile(folder .. "/" .. f)
		end
	end
end

if SERVER then
	resource.AddFile("sound/tactikill/low-honor-rdr-2.mp3")
	resource.AddFile("sound/tactikill/projectile-launch.wav")
	resource.AddFile("sound/tactikill/parachute-airdrop.mp3")

	AddSoundFolder("sound/tactikill/headshot")
	AddSoundFolder("sound/tactikill/death")

	AddCSLuaFile("tactikill/sh_config.lua")
	AddCSLuaFile("tactikill/sh_settings.lua")
	AddCSLuaFile("tactikill/sh_achievements.lua")
	AddCSLuaFile("tactikill/sh_contracts.lua")
	AddCSLuaFile("tactikill/cl_settings.lua")
	AddCSLuaFile("tactikill/cl_hud.lua")
	AddCSLuaFile("tactikill/cl_scoreboard.lua")
	AddCSLuaFile("tactikill/cl_shake.lua")
	AddCSLuaFile("tactikill/cl_events.lua")
	AddCSLuaFile("tactikill/cl_deathscreen.lua")
	AddCSLuaFile("tactikill/cl_sounds.lua")
	AddCSLuaFile("tactikill/cl_achievements.lua")
	AddCSLuaFile("tactikill/cl_contracts.lua")
	AddCSLuaFile("tactikill/cl_leaderboard.lua")
	AddCSLuaFile("tactikill/cl_dossier.lua")

	AddCSLuaFile("weapons/tactikill_artillery.lua")
	AddCSLuaFile("weapons/tactikill_artillery_admin.lua")
	AddCSLuaFile("weapons/tactikill_noweapon.lua")
	AddCSLuaFile("weapons/tactikill_surrender.lua")
	AddCSLuaFile("weapons/tactikill_terminal.lua")

	include("tactikill/sh_config.lua")
	include("tactikill/sh_settings.lua")
	include("tactikill/sh_achievements.lua")
	include("tactikill/sh_contracts.lua")
	include("tactikill/sv_achievements.lua")
	include("tactikill/sv_timer.lua")
	include("tactikill/sv_combo.lua")
	include("tactikill/sv_contracts.lua")
	include("tactikill/sv_tools.lua")
	include("tactikill/sv_settings.lua")
	include("tactikill/sv_combat.lua")
	include("tactikill/sv_events.lua")
	include("tactikill/sv_autospawn.lua")
	include("tactikill/sv_deathscreen.lua")
	include("tactikill/sv_sounds.lua")
	include("tactikill/sv_persistence.lua")
	include("tactikill/sv_leaderboard.lua")
else
	include("tactikill/sh_config.lua")
	include("tactikill/sh_settings.lua")
	include("tactikill/sh_achievements.lua")
	include("tactikill/sh_contracts.lua")
	include("tactikill/cl_achievements.lua")
	include("tactikill/cl_settings.lua")
	include("tactikill/cl_hud.lua")
	include("tactikill/cl_scoreboard.lua")
	include("tactikill/cl_shake.lua")
	include("tactikill/cl_events.lua")
	include("tactikill/cl_deathscreen.lua")
	include("tactikill/cl_sounds.lua")
	include("tactikill/cl_contracts.lua")
	include("tactikill/cl_leaderboard.lua")
	include("tactikill/cl_dossier.lua")
end