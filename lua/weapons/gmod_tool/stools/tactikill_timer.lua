--[[---------------------------------------------------------------------------
  Project: TactiKill - Combat System
  stools/tactikill_timer.lua  (SHARED, loaded by gmod_tool)

  Left click  : start / pause the session timer
  Right click : reset the session timer (kills/score/combo are NOT touched)
  Reload      : toggle the TactiKill HUD (statistics are NOT touched)

  Resetting kills/score/combo is deliberately NOT bound to any click: use the
  button in the tool panel (asks for confirmation) or the console command
  "tactikill_reset_stats confirm".

  The tool only affects the player who is holding it (the owner).
-----------------------------------------------------------------------------]]

TOOL.Category = "TactiKill"
TOOL.Name = "#tool.tactikill_timer.name"

TOOL.Information = {
	{ name = "left" },
	{ name = "right" },
	{ name = "reload" },
}

if CLIENT then
	language.Add("tool.tactikill_timer.name", "TactiKill Timer")
	language.Add("tool.tactikill_timer.desc", "Control the TactiKill session timer and HUD")
	language.Add("tool.tactikill_timer.left", "Start / pause the session timer")
	language.Add("tool.tactikill_timer.right", "Reset the session timer (kills and score are kept)")
	language.Add("tool.tactikill_timer.reload", "Toggle the TactiKill HUD (statistics are kept)")
end

-- Actions run on the server only; the client returns true so the tool gun
-- plays its normal feedback animation.
local function Ready()
	return TACTIKILL and TACTIKILL.Tools and TACTIKILL.Timer
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if not Ready() then return false end
	return TACTIKILL.Tools.TimerToggle(self:GetOwner())
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not Ready() then return false end
	return TACTIKILL.Tools.TimerReset(self:GetOwner())
end

-- The tool gun can call Reload repeatedly while the key is held; the server
-- side debounces it (0.5 s) so one press = one toggle.
function TOOL:Reload(trace)
	if CLIENT then return true end
	if not Ready() then return false end
	return TACTIKILL.Tools.HUDToggle(self:GetOwner())
end

function TOOL.BuildCPanel(panel)
	panel:Help("Left click: start/pause timer. Right click: reset timer. Reload: toggle HUD.")

	local btn = panel:Button("Reset kills, score and combo...")
	btn.DoClick = function()
		Derma_Query(
			"Reset your kills, score, killstreak and combo?\nThe session timer will NOT be reset.",
			"TactiKill - confirm reset",
			"RESET STATISTICS", function() RunConsoleCommand("tactikill_reset_stats", "confirm") end,
			"CANCEL", function() end
		)
	end

	-- personal HUD / screen shake settings (same panel as in Utilities -> TactiKill)
	if TACTIKILL and TACTIKILL.BuildSettings then TACTIKILL.BuildSettings(panel) end
end
