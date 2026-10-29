if SERVER then AddCSLuaFile() end

SWEP.PrintName      = "Hands Up"
SWEP.Author         = "TactiKill"
SWEP.Instructions   = "Holding this weapon = surrendered. You cannot move or attack. Switch weapons to stop."
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

local HOLD_SOUND = "vo/npc/male01/getdown01.wav"

function SWEP:Initialize()
	self:SetHoldType("slam")
end

function SWEP:Deploy()
	self:SetHoldType("slam")

	local ply = self:GetOwner()
	if not IsValid(ply) then return true end

	if SERVER then
		ply:SetNWBool("TACTIKILL_Surrendered", true)
		ply:SetNWFloat("TACTIKILL_SurrenderAt", CurTime())
		ply:SetMaxSpeed(0)
		ply:SetWalkSpeed(0)
		ply:SetRunSpeed(0)
		ply:SetJumpPower(0)
		ply:SetDuckSpeed(0)
		ply:SetUnDuckSpeed(0)
		ply:ChatPrint("[TactiKill] You have SURRENDERED. Switch weapons to stop.")
		ply:EmitSound(HOLD_SOUND, 70, 100)
	end
	return true
end

function SWEP:Holster()
	local ply = self:GetOwner()
	if IsValid(ply) and SERVER then
		ply:SetNWBool("TACTIKILL_Surrendered", false)
		ply:SetMaxSpeed(400)
		ply:SetWalkSpeed(200)
		ply:SetRunSpeed(400)
		ply:SetJumpPower(200)
		ply:SetDuckSpeed(0.4)
		ply:SetUnDuckSpeed(0.2)
	end
	return true
end

function SWEP:OnRemove() self:Holster() end

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end
function SWEP:Reload() end

function SWEP:PreDrawViewModel() return true end

function SWEP:SetupMove(ply, mv, cmd)
	if SERVER and IsValid(ply) then
		mv:SetMaxSpeed(0)
		mv:SetMaxClientSpeed(0)
	end
end

if CLIENT then
	hook.Add("HUDPaint", "TACTIKILL_SurrenderIndicator", function()
		local lp = LocalPlayer()
		if not IsValid(lp) then return end

		if lp:GetNWBool("TACTIKILL_Surrendered") then
			local sw, sh = ScrW(), ScrH()
			draw.SimpleText("YOU ARE SURRENDERING",
				"DermaLarge", sw / 2, sh * 0.15,
				Color(255, 80, 80, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Switch weapons to stop",
				"DermaDefaultBold", sw / 2, sh * 0.15 + 30,
				Color(200, 200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) and ply ~= lp and ply:GetNWBool("TACTIKILL_Surrendered") then
				local head = ply:GetPos() + Vector(0, 0, 90)
				local scr  = head:ToScreen()
				if scr.visible then
					local dist = lp:GetPos():Distance(ply:GetPos())
					local a = math.Clamp(1 - dist / 3000, 0.15, 1) * 255
					draw.SimpleText("SURRENDERING",
						"DermaDefaultBold", scr.x, scr.y,
						Color(255, 80, 80, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					draw.SimpleText(ply:Nick(),
						"DermaDefault", scr.x, scr.y + 16,
						Color(230, 230, 230, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			end
		end
	end)
end