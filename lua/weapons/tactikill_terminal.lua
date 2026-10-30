if SERVER then AddCSLuaFile() end

SWEP.PrintName      = "Field Terminal"
SWEP.Author         = "TactiKill"
SWEP.Instructions   = "E: open agent dossier."
SWEP.Category       = "TactiKill"

SWEP.Spawnable      = true
SWEP.AdminOnly      = false

SWEP.Primary.ClipSize      = -1
SWEP.Primary.DefaultClip   = -1
SWEP.Primary.Automatic     = false
SWEP.Primary.Ammo          = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

SWEP.Weight         = 1
SWEP.AutoSwitchTo   = false
SWEP.AutoSwitchFrom = false
SWEP.Slot           = 5
SWEP.SlotPos        = 10
SWEP.DrawAmmo       = false
SWEP.DrawCrosshair  = false

SWEP.ViewModel      = ""
SWEP.WorldModel     = ""

local SWEP_CLASS = "tactikill_terminal"

function SWEP:Initialize()
	self:SetHoldType("slam")
end

function SWEP:Deploy()
	self:SetHoldType("slam")
	return true
end

function SWEP:PreDrawViewModel() return true end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.6)
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.6)
end

function SWEP:Reload() end

if CLIENT then
	hook.Add("PlayerBindPress", "TACTIKILL_TerminalBind", function(ply, bind, pressed)
		if not pressed then return end
		if not IsValid(ply) then return end
		if bind ~= "+use" then return end

		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= SWEP_CLASS then return end

		if IsValid(TACTIKILL and TACTIKILL.Dossier and TACTIKILL.Dossier.Panel) then
			return true
		end

		if TACTIKILL and TACTIKILL.OpenDossier then
			TACTIKILL.OpenDossier("player")
		end
		return true
	end)
end