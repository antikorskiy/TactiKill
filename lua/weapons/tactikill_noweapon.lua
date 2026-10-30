if SERVER then AddCSLuaFile() end

SWEP.PrintName      = "Free Hands"
SWEP.Author         = "TactiKill"
SWEP.Instructions   = "Empty, lowered hands. No weapon drawn — no attack."
SWEP.Category       = "TactiKill"

SWEP.Spawnable      = true
SWEP.AdminOnly      = false

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "none"
SWEP.Secondary.ClipSize  = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

SWEP.Weight         = 1
SWEP.AutoSwitchTo   = false
SWEP.AutoSwitchFrom = false
SWEP.Slot           = 0
SWEP.SlotPos        = 0
SWEP.DrawAmmo       = false
SWEP.DrawCrosshair  = false

SWEP.ViewModel      = ""
SWEP.WorldModel     = ""

local HOLDTYPE = "normal"

function SWEP:Initialize()
	self:SetHoldType(HOLDTYPE)
end

function SWEP:Deploy()
	self:SetHoldType(HOLDTYPE)
	return true
end

function SWEP:PreDrawViewModel()
	return true 
end
