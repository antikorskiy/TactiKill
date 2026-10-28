if SERVER then AddCSLuaFile() end

local TK = TACTIKILL

SWEP.PrintName = "Artillery Designator"
SWEP.Author = "TactiKill"
SWEP.Instructions = "E: enter/exit | LMB: mark | RMB: undo | R: fire | ESC: exit"
SWEP.Category = "TactiKill"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 5
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"

function SWEP:PreDrawViewModel() return true end

local SWEP_CLASS = "tactikill_artillery"

local MAX_MARKS   = 5
local MAX_HEIGHT  = 2500
local MIN_HEIGHT  = 200
local MAX_DIST    = 3500
local CAM_SPEED   = 15
local CAM_FAST    = 50
local SENS        = 0.22
local ARTY_CAM_FOV = 75
local SCROLL_STEP = 250

function SWEP:Holster()
	if CLIENT and TACTIKILL and TACTIKILL.Arty then
		TACTIKILL.Arty.active = false
		TACTIKILL.Arty.marks = {}
	end
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

if CLIENT then
	TACTIKILL = TACTIKILL or {}
	TACTIKILL.Arty = TACTIKILL.Arty or {
		active = false,
		camPos = Vector(),
		camAng = Angle(),
		marks = {},
		lastUse = 0,
		lastEsc = false,
	}

	local A = TACTIKILL.Arty

	local function IsActiveWep()
		local ply = LocalPlayer()
		if not IsValid(ply) then return false end
		local wep = ply:GetActiveWeapon()
		return IsValid(wep) and wep:GetClass() == SWEP_CLASS
	end

	local function Enter()
		local ply = LocalPlayer()
		if not IsValid(ply) or not ply:Alive() then return end
		if ply:GetNWBool("TK_ArtyUsed") then
			chat.AddText(Color(255, 80, 80), "[TACTIKILL] ",
				Color(255, 200, 200), "Artillery already used. Respawn to reset.")
			return
		end
		A.active = true
		A.marks = {}
		A.camPos = ply:GetPos() + Vector(0, 0, 600)
		A.camAng = Angle(-45, ply:EyeAngles().y, 0)
		surface.PlaySound("ui/buttonclick.wav")
		print("[TACTIKILL] Arty mode ON")
	end

	local function Exit()
		A.active = false
		A.marks = {}
		surface.PlaySound("ui/buttonclickrelease.wav")
		print("[TACTIKILL] Arty mode OFF")
	end

	local function AddMark()
		if not A.active then return end
		local ply = LocalPlayer()
		if #A.marks >= MAX_MARKS then return end

		local tr = util.TraceLine({
			start  = A.camPos,
			endpos = A.camPos + A.camAng:Forward() * 20000,
			mask   = MASK_SOLID_BRUSHONLY,
			filter = ply,
		})
		if tr.Hit then
			table.insert(A.marks, tr.HitPos)
			surface.PlaySound("buttons/button14.wav")
			print("[TACTIKILL] Mark added: " .. #A.marks .. " / " .. MAX_MARKS)
		else
			print("[TACTIKILL] Mark failed: no trace hit")
		end
	end

	local function UndoMark()
		if not A.active then return end
		if #A.marks == 0 then return end
		table.remove(A.marks)
		surface.PlaySound("buttons/button15.wav")
		print("[TACTIKILL] Mark removed: " .. #A.marks .. " / " .. MAX_MARKS)
	end

	local function Fire()
		if not A.active then return end
		if #A.marks == 0 then
			chat.AddText(Color(255, 200, 80), "[TACTIKILL] ", Color(255, 255, 200),
				"No marks. Use LMB to place at least one.")
			return
		end
		print("[TACTIKILL] Fire(): sending " .. #A.marks .. " marks")
		net.Start("TACTIKILL_ArtyFire")
			net.WriteUInt(#A.marks, 4)
			for _, m in ipairs(A.marks) do
				net.WriteVector(m)
			end
		net.SendToServer()
		A.active = false
		A.marks = {}
		surface.PlaySound("ui/buttonclick.wav")
	end

	concommand.Add("tactikill_arty_fire", function()
		if not IsActiveWep() then return end
		Fire()
	end, nil, "Fire the artillery")

	hook.Add("PlayerBindPress", "TACTIKILL_ArtyBind", function(ply, bind, pressed)
		if not IsActiveWep() then return end
		if not IsValid(ply) or not ply:Alive() then return end

		if bind == "+use" then
			if not pressed then return true end
			local now = CurTime()
			if (A.lastUse or 0) > now then return true end
			A.lastUse = now + 0.3

			if A.active then
				Exit()
			else
				Enter()
			end
			return true
		end

		if not A.active then return end

		if bind == "+attack" then
			if pressed then AddMark() end
			return true
		end

		if bind == "+attack2" then
			if pressed then UndoMark() end
			return true
		end

		if bind == "+reload" then
			if pressed then Fire() end
			return true
		end

		if bind == "invnext" then
			A.camPos.z = A.camPos.z + SCROLL_STEP
			return true
		end

		if bind == "invprev" then
			A.camPos.z = A.camPos.z - SCROLL_STEP
			return true
		end
	end)

	hook.Add("CreateMove", "TACTIKILL_ArtyMove", function(cmd)
		local ply = LocalPlayer()
		if not IsValid(ply) or not ply:Alive() then return end

		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= SWEP_CLASS then
			if A.active then A.active = false; A.marks = {} end
			return
		end

		if not A.active then return end

		A.camAng.y = A.camAng.y - cmd:GetMouseX() * SENS
		A.camAng.p = math.Clamp(A.camAng.p - cmd:GetMouseY() * SENS, -89, 89)
		A.camAng.r = 0

		cmd:ClearMovement()
	end)

	hook.Add("Think", "TACTIKILL_ArtyThink", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= SWEP_CLASS then
			if A.active then A.active = false; A.marks = {} end
			return
		end

		if not A.active then return end
		if not ply:Alive() then
			A.active = false
			A.marks = {}
			return
		end

		local fwd   = A.camAng:Forward()
		local right = A.camAng:Right()
		local up    = A.camAng:Up()
		local speed = input.IsKeyDown(KEY_LSHIFT) and CAM_FAST or CAM_SPEED

		local moveX, moveY = 0, 0
		if input.IsKeyDown(KEY_W) or input.IsKeyDown(KEY_UP) then moveX = moveX + 1 end
		if input.IsKeyDown(KEY_S) or input.IsKeyDown(KEY_DOWN) then moveX = moveX - 1 end
		if input.IsKeyDown(KEY_D) or input.IsKeyDown(KEY_RIGHT) then moveY = moveY + 1 end
		if input.IsKeyDown(KEY_A) or input.IsKeyDown(KEY_LEFT) then moveY = moveY - 1 end

		if moveX ~= 0 or moveY ~= 0 then
			local dir = (fwd * moveX + right * moveY):GetNormalized()
			A.camPos = A.camPos + dir * speed
		end

		if input.IsKeyDown(KEY_SPACE) then A.camPos = A.camPos + up * speed end
		if input.IsKeyDown(KEY_LCONTROL) then A.camPos = A.camPos - up * speed end

		local playerPos = ply:GetPos()
		A.camPos.z = math.Clamp(A.camPos.z, playerPos.z + MIN_HEIGHT, playerPos.z + MAX_HEIGHT)

		local delta = A.camPos - playerPos
		local flatLen = Vector(delta.x, delta.y, 0):Length()
		if flatLen > MAX_DIST then
			local s = MAX_DIST / flatLen
			A.camPos.x = playerPos.x + delta.x * s
			A.camPos.y = playerPos.y + delta.y * s
		end

		local esc = input.IsKeyDown(KEY_ESCAPE)
		if esc and not A.lastEsc then
			Exit()
		end
		A.lastEsc = esc

		local enterFallback = input.IsKeyDown(KEY_ENTER) or input.IsKeyDown(KEY_PAD_ENTER)
		if enterFallback and not A.lastEnter then
			Fire()
		end
		A.lastEnter = enterFallback
	end)

	hook.Add("CalcView", "TACTIKILL_ArtyCalcView", function(ply, pos, ang, fov)
		if ply ~= LocalPlayer() then return end
		if not A.active then return end
		return { origin = A.camPos, angles = A.camAng, fov = ARTY_CAM_FOV }
	end)

	hook.Add("HUDPaint", "TACTIKILL_ArtyHUD", function()
		if not A.active then return end

		local sw, sh = ScrW(), ScrH()
		local cx, cy = sw / 2, sh / 2

		surface.SetDrawColor(0, 0, 0, 255)
		local curtain = math.floor(sw * 0.28)
		surface.DrawRect(0, 0, curtain, sh)
		surface.DrawRect(sw - curtain, 0, curtain, sh)
		local vcurtain = math.floor(sh * 0.15)
		surface.DrawRect(curtain, 0, sw - curtain * 2, vcurtain)
		surface.DrawRect(curtain, sh - vcurtain, sw - curtain * 2, vcurtain)

		surface.SetDrawColor(0, 255, 0, 220)
		surface.DrawRect(cx - 1, cy - 80, 2, 60)
		surface.DrawRect(cx - 1, cy + 20, 2, 60)
		surface.DrawRect(cx - 80, cy - 1, 60, 2)
		surface.DrawRect(cx + 20, cy - 1, 60, 2)
		surface.DrawRect(cx - 2, cy - 2, 4, 4)

		surface.SetDrawColor(0, 200, 0, 150)
		local cl = 40
		surface.DrawRect(cx - 100, cy - 100, cl, 2)
		surface.DrawRect(cx - 100, cy - 100, 2, cl)
		surface.DrawRect(cx + 100 - cl, cy - 100, cl, 2)
		surface.DrawRect(cx + 100 - 2, cy - 100, 2, cl)
		surface.DrawRect(cx - 100, cy + 100 - 2, cl, 2)
		surface.DrawRect(cx - 100, cy + 100 - cl, 2, cl)
		surface.DrawRect(cx + 100 - cl, cy + 100 - 2, cl, 2)
		surface.DrawRect(cx + 100 - 2, cy + 100 - cl, 2, cl)

		draw.SimpleText("MARKS: " .. #A.marks .. " / " .. MAX_MARKS,
			"DermaLarge", cx, 30, Color(0, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

		draw.SimpleText("LMB MARK  •  RMB UNDO  •  R FIRE  •  E EXIT",
			"DermaDefaultBold", cx, sh - 30, Color(0, 255, 0, 220),
			TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		draw.SimpleText("WASD move  •  SPACE / CTRL up-down  •  SHIFT fast  •  WHEEL quick up-down",
			"DermaDefault", cx, sh - 50, Color(0, 200, 0, 180),
			TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

		if #A.marks > 0 then
			draw.SimpleText("PRESS R TO FIRE",
				"DermaDefaultBold", cx, sh - 72, Color(255, 255, 100, 255),
				TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
	end)

	hook.Add("PostDrawTranslucentRenderables", "TACTIKILL_ArtyMarks", function(bDrawingDepth, bDrawingSkybox)
		if bDrawingDepth or bDrawingSkybox then return end
		if not A.active then return end

		local mat = Material("sprites/light_glow02_add")

		local tr = util.TraceLine({
			start  = A.camPos,
			endpos = A.camPos + A.camAng:Forward() * 20000,
			mask   = MASK_SOLID_BRUSHONLY,
			filter = LocalPlayer(),
		})
		if tr.Hit then
			render.SetMaterial(mat)
			render.DrawSprite(tr.HitPos + Vector(0, 0, 10), 120, 120, Color(255, 255, 100, 200))
		end

		for _, m in ipairs(A.marks) do
			render.SetMaterial(mat)
			render.DrawSprite(m + Vector(0, 0, 10), 150, 150, Color(255, 80, 80, 220))
		end
	end)

	hook.Add("RenderScene", "TACTIKILL_ArtyTint", function(origin, angles)
		if not A.active then return end
		DrawColorModify({
			["$pp_colour_brightness"] = -0.02,
			["$pp_colour_contrast"]   = 1.05,
			["$pp_colour_colour"]     = 0.5,
			["$pp_colour_mulr"]       = 0.3,
			["$pp_colour_mulg"]       = 1.0,
			["$pp_colour_mulb"]       = 0.3,
		})
	end)
end

if SERVER then
	util.AddNetworkString("TACTIKILL_ArtyFire")

	net.Receive("TACTIKILL_ArtyFire", function(_, ply)
		if not IsValid(ply) or not ply:Alive() then return end
		if ply:GetNWBool("TK_ArtyUsed") then return end

		local count = net.ReadUInt(4)
		if count < 1 or count > MAX_MARKS then
			print("[TACTIKILL] Arty rejected: bad count " .. tostring(count))
			return
		end

		local marks = {}
		for i = 1, count do
			marks[i] = net.ReadVector()
		end

		for _, m in ipairs(marks) do
			if m:Distance(ply:GetPos()) > 15000 then
				ply:ChatPrint("[TactiKill] Artillery: mark too far")
				return
			end
		end

		ply:SetNWBool("TK_ArtyUsed", true)
		print("[TACTIKILL] Artillery fire by " .. ply:Nick() .. " (" .. count .. " marks)")

		if TK and TK.FireBarrage then
			TK.FireBarrage(marks, {
				chargeTime   = 2.5,
				fireInterval = 1.2,
				leadTime     = 0.4,
				radius       = 400,
				damage       = 200,
			})
		else
			print("[TACTIKILL] ERROR: TK.FireBarrage is nil!")
			ply:ChatPrint("[TactiKill] ERROR: FireBarrage not loaded")
		end

		-- Remove the weapon from the player
		local wep = ply:GetWeapon("tactikill_artillery")
		if IsValid(wep) then
			ply:StripWeapon("tactikill_artillery")
			ply:ChatPrint("[TactiKill] Artillery designator expended.")
			print("[TACTIKILL] Weapon stripped from " .. ply:Nick())
		end
	end)
end