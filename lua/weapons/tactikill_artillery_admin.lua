if SERVER then AddCSLuaFile() end

local TK = TACTIKILL

SWEP.PrintName = "Artillery Designator (Admin)"
SWEP.Author = "TactiKill"
SWEP.Instructions = "E: enter/exit | LMB: mark | RMB: undo | R: fire | ESC: exit"
SWEP.Category = "TactiKill (Admin)"

SWEP.Spawnable = true
SWEP.AdminOnly = true

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
SWEP.SlotPos = 5
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"

function SWEP:PreDrawViewModel() return true end

local SWEP_CLASS = "tactikill_artillery_admin"

local MAX_MARKS   = 64
local MAX_HEIGHT  = 50000
local MIN_HEIGHT  = 20
local MAX_DIST    = 50000
local CAM_SPEED   = 30
local CAM_FAST    = 120
local SENS        = 0.22
local ARTY_CAM_FOV = 75
local SCROLL_STEP = 600

function SWEP:Deploy()
	if SERVER then
		local owner = self:GetOwner()
		if IsValid(owner) and not owner:IsAdmin() then
			owner:ChatPrint("[TactiKill] Admin only")
			return false
		end
	end
	return true
end

function SWEP:Holster()
	if CLIENT and TACTIKILL and TACTIKILL.ArtyAdmin then
		TACTIKILL.ArtyAdmin.active = false
		TACTIKILL.ArtyAdmin.marks = {}
	end
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

if CLIENT then
	TACTIKILL = TACTIKILL or {}
	TACTIKILL.ArtyAdmin = TACTIKILL.ArtyAdmin or {
		active = false,
		camPos = Vector(),
		camAng = Angle(),
		marks = {},
		lastUse = 0,
		lastEsc = false,
	}

	local A = TACTIKILL.ArtyAdmin

	local function IsActiveWep()
		local ply = LocalPlayer()
		if not IsValid(ply) then return false end
		local wep = ply:GetActiveWeapon()
		return IsValid(wep) and wep:GetClass() == SWEP_CLASS
	end

	local function CanUse()
		local ply = LocalPlayer()
		if not IsValid(ply) or not ply:Alive() then return false end
		if not ply:IsAdmin() then return false end
		return true
	end

	local function Enter()
		if not CanUse() then return end
		A.active = true
		A.marks = {}
		A.camPos = LocalPlayer():GetPos() + Vector(0, 0, 600)
		A.camAng = Angle(-45, LocalPlayer():EyeAngles().y, 0)
		surface.PlaySound("ui/buttonclick.wav")
		print("[TACTIKILL] ADMIN Arty mode ON")
	end

	local function Exit()
		A.active = false
		A.marks = {}
		surface.PlaySound("ui/buttonclickrelease.wav")
		print("[TACTIKILL] ADMIN Arty mode OFF")
	end

	local function AddMark()
		if not A.active then return end
		if #A.marks >= MAX_MARKS then return end

		local tr = util.TraceLine({
			start  = A.camPos,
			endpos = A.camPos + A.camAng:Forward() * 60000,
			mask   = MASK_SOLID_BRUSHONLY,
			filter = LocalPlayer(),
		})
		if tr.Hit then
			table.insert(A.marks, tr.HitPos)
			surface.PlaySound("buttons/button14.wav")
			print("[TACTIKILL] ADMIN Mark added: " .. #A.marks .. " / " .. MAX_MARKS)
		end
	end

	local function UndoMark()
		if not A.active then return end
		if #A.marks == 0 then return end
		table.remove(A.marks)
		surface.PlaySound("buttons/button15.wav")
	end

	local function Fire()
		if not A.active then return end
		if #A.marks == 0 then
			chat.AddText(Color(255, 200, 80), "[TACTIKILL] ",
				Color(255, 255, 200), "No marks.")
			return
		end
		print("[TACTIKILL] ADMIN Fire(): sending " .. #A.marks .. " marks")
		net.Start("TACTIKILL_ArtyFireAdmin")
			net.WriteUInt(#A.marks, 8)
			for _, m in ipairs(A.marks) do
				net.WriteVector(m)
			end
		net.SendToServer()
		surface.PlaySound("ui/buttonclick.wav")
		A.marks = {}
	end

	concommand.Add("tactikill_arty_fire_admin", function()
		if not CanUse() then return end
		if not IsActiveWep() then return end
		Fire()
	end, nil, "Fire admin artillery")

	hook.Add("PlayerBindPress", "TACTIKILL_ArtyAdminBind", function(ply, bind, pressed)
		if not IsActiveWep() then return end
		if not CanUse() then return end

		if bind == "+use" then
			if not pressed then return true end
			local now = CurTime()
			if (A.lastUse or 0) > now then return true end
			A.lastUse = now + 0.3

			if A.active then Exit() else Enter() end
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

	hook.Add("CreateMove", "TACTIKILL_ArtyAdminMove", function(cmd)
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

	hook.Add("Think", "TACTIKILL_ArtyAdminThink", function()
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
		if esc and not A.lastEsc then Exit() end
		A.lastEsc = esc
	end)

	hook.Add("CalcView", "TACTIKILL_ArtyAdminCalcView", function(ply, pos, ang, fov)
		if ply ~= LocalPlayer() then return end
		if not A.active then return end
		return { origin = A.camPos, angles = A.camAng, fov = ARTY_CAM_FOV }
	end)

	hook.Add("HUDPaint", "TACTIKILL_ArtyAdminHUD", function()
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

		surface.SetDrawColor(255, 180, 0, 230)
		surface.DrawRect(cx - 1, cy - 80, 2, 60)
		surface.DrawRect(cx - 1, cy + 20, 2, 60)
		surface.DrawRect(cx - 80, cy - 1, 60, 2)
		surface.DrawRect(cx + 20, cy - 1, 60, 2)
		surface.DrawRect(cx - 2, cy - 2, 4, 4)

		surface.SetDrawColor(255, 150, 0, 180)
		local cl = 40
		surface.DrawRect(cx - 100, cy - 100, cl, 2)
		surface.DrawRect(cx - 100, cy - 100, 2, cl)
		surface.DrawRect(cx + 100 - cl, cy - 100, cl, 2)
		surface.DrawRect(cx + 100 - 2, cy - 100, 2, cl)
		surface.DrawRect(cx - 100, cy + 100 - 2, cl, 2)
		surface.DrawRect(cx - 100, cy + 100 - cl, 2, cl)
		surface.DrawRect(cx + 100 - cl, cy + 100 - 2, cl, 2)
		surface.DrawRect(cx + 100 - 2, cy + 100 - cl, 2, cl)

		draw.SimpleText("[ADMIN] MARKS: " .. #A.marks .. " / " .. MAX_MARKS,
			"DermaLarge", cx, 30, Color(255, 180, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

		draw.SimpleText("LMB MARK  •  RMB UNDO  •  R FIRE  •  E EXIT",
			"DermaDefaultBold", cx, sh - 30, Color(255, 150, 0, 220),
			TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		draw.SimpleText("WASD move  •  SPACE / CTRL up-down  •  SHIFT fast  •  WHEEL quick up-down",
			"DermaDefault", cx, sh - 50, Color(255, 150, 0, 180),
			TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

		if #A.marks > 0 then
			draw.SimpleText("PRESS R TO FIRE",
				"DermaDefaultBold", cx, sh - 72, Color(255, 255, 100, 255),
				TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
	end)

	hook.Add("PostDrawTranslucentRenderables", "TACTIKILL_ArtyAdminMarks", function(bDrawingDepth, bDrawingSkybox)
		if bDrawingDepth or bDrawingSkybox then return end
		if not A.active then return end

		local mat = Material("sprites/light_glow02_add")

		local tr = util.TraceLine({
			start  = A.camPos,
			endpos = A.camPos + A.camAng:Forward() * 60000,
			mask   = MASK_SOLID_BRUSHONLY,
			filter = LocalPlayer(),
		})
		if tr.Hit then
			render.SetMaterial(mat)
			render.DrawSprite(tr.HitPos + Vector(0, 0, 10), 120, 120, Color(255, 255, 100, 200))
		end

		for _, m in ipairs(A.marks) do
			render.SetMaterial(mat)
			render.DrawSprite(m + Vector(0, 0, 10), 150, 150, Color(255, 140, 0, 220))
		end
	end)

	hook.Add("RenderScene", "TACTIKILL_ArtyAdminTint", function(origin, angles)
		if not A.active then return end
		DrawColorModify({
			["$pp_colour_brightness"] = -0.02,
			["$pp_colour_contrast"]   = 1.05,
			["$pp_colour_colour"]     = 0.5,
			["$pp_colour_mulr"]       = 1.0,
			["$pp_colour_mulg"]       = 0.6,
			["$pp_colour_mulb"]       = 0.2,
		})
	end)
end

if SERVER then
	util.AddNetworkString("TACTIKILL_ArtyFireAdmin")

	net.Receive("TACTIKILL_ArtyFireAdmin", function(_, ply)
		if not IsValid(ply) or not ply:Alive() then return end
		if not ply:IsAdmin() then
			ply:ChatPrint("[TactiKill] Admin only")
			return
		end

		local count = net.ReadUInt(8)
		if count < 1 or count > MAX_MARKS then return end

		local marks = {}
		for i = 1, count do
			marks[i] = net.ReadVector()
		end

		print("[TACTIKILL] ADMIN artillery by " .. ply:Nick() .. " (" .. count .. " marks)")

		if TK and TK.FireBarrage then
			TK.FireBarrage(marks, {
				chargeTime   = 1.5,
				fireInterval = 0.6,
				leadTime     = 0.3,
				radius       = 550,
				damage       = 350,
			})
		else
			print("[TACTIKILL] ERROR: TK.FireBarrage is nil!")
			ply:ChatPrint("[TactiKill] ERROR: FireBarrage not loaded")
		end
	end)
end