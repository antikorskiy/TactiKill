local TK = TACTIKILL
local C  = TK.Config
local E  = C.Events

local BombardBeams = {}
local Airdrops     = {}

local BEAM_HEIGHT   = 2500
local BEAM_WIDTH    = 300
local BEAM_SEGMENTS = 8

local matBeam
local matGlow

local function IsClientAdmin()
	local lp = LocalPlayer()
	if not IsValid(lp) then return false end
	return lp:IsAdmin() or lp:IsSuperAdmin()
end

local function GetBeamMat()
	if matBeam and not matBeam:IsError() then return matBeam end
	matBeam = Material("trails/laser")
	if not matBeam or matBeam:IsError() then matBeam = Material("effects/laser1") end
	if not matBeam or matBeam:IsError() then matBeam = Material("cable/redlaser") end
	return matBeam
end

local function GetGlowMat()
	if not matGlow or matGlow:IsError() then matGlow = Material("sprites/light_glow02_add") end
	return matGlow
end

net.Receive("TACTIKILL_Event_Bombard_Start", function()
	BombardBeams = {}
	local n = net.ReadUInt(8)
	local now = CurTime()
	for i = 1, n do
		local x = net.ReadFloat()
		local y = net.ReadFloat()
		local z = net.ReadFloat()
		BombardBeams[i] = {
			x = x, y = y, z = z,
			appearAt = now + (i - 1) * E.Bombardment.BeamDelay,
			hit = false,
			hitAt = 0,
			done = false,
		}
	end

	if IsClientAdmin() then
		print("[TACTIKILL CLIENT] Bombardment received: " .. n .. " beams")
		chat.AddText(Color(255, 80, 80), "[TACTIKILL ADMIN] ",
			Color(255, 200, 200), "Bombardment: " .. n .. " strikes")
		for i, b in ipairs(BombardBeams) do
			chat.AddText(Color(200, 200, 200),
				string.format("  #%d: %.0f, %.0f, %.0f", i, b.x, b.y, b.z))
		end
	else
		chat.AddText(Color(255, 80, 80), "[TACTIKILL] ", Color(255, 200, 200),
			"BOMBARDMENT INCOMING")
	end
end)

net.Receive("TACTIKILL_Event_Bombard_Strike", function()
	local idx = net.ReadUInt(8)
	local x = net.ReadFloat()
	local y = net.ReadFloat()
	local z = net.ReadFloat()

	local b = BombardBeams[idx]
	if b then
		b.hit = true
		b.hitAt = CurTime()
	elseif IsClientAdmin() then
		BombardBeams[idx] = {
			x = x, y = y, z = z,
			appearAt = CurTime(),
			hit = true, hitAt = CurTime(),
			done = false,
		}
	end
end)

net.Receive("TACTIKILL_Event_Bombard_End", function()
	BombardBeams = {}
end)

net.Receive("TACTIKILL_Event_Airdrop_Start", function()
	local x = net.ReadFloat()
	local y = net.ReadFloat()
	local z = net.ReadFloat()
	local fallTime = net.ReadFloat()

	table.insert(Airdrops, {
		x = x, y = y, z = z,
		timerEnd = CurTime() + fallTime,
		active = true,
	})

	if IsClientAdmin() then
		print("[TACTIKILL CLIENT] Airdrop incoming: " ..
			math.floor(x) .. "," .. math.floor(y) .. "," .. math.floor(z) ..
			" in " .. fallTime .. "s")
		chat.AddText(Color(80, 160, 255), "[TACTIKILL ADMIN] ",
			Color(200, 220, 255),
			string.format("Airdrop: %.0f, %.0f, %.0f in %ds",
				x, y, z, math.floor(fallTime)))
	else
		chat.AddText(Color(80, 160, 255), "[TACTIKILL] ", Color(200, 220, 255),
			"AIRDROP INCOMING")
	end
end)

net.Receive("TACTIKILL_Event_Airdrop_Landing", function()
	local x = net.ReadFloat()
	local y = net.ReadFloat()
	local z = net.ReadFloat()

	for _, ad in ipairs(Airdrops) do
		if ad.active then
			ad.active = false
			ad.landed = CurTime()
		end
	end

	if IsClientAdmin() then
		chat.AddText(Color(80, 160, 255), "[TACTIKILL ADMIN] ",
			Color(200, 220, 255),
			string.format("Airdrop landed at %.0f, %.0f, %.0f", x, y, z))
	end
end)

local function DrawBeamPillar(x, y, zBase, height, color)
	local m = GetBeamMat()
	local gm = GetGlowMat()

	if m and not m:IsError() then
		render.SetMaterial(m)
		local segH = height / BEAM_SEGMENTS
		for i = 0, BEAM_SEGMENTS - 1 do
			local s = Vector(x, y, zBase + segH * i)
			local e = Vector(x, y, zBase + segH * (i + 1))
			local w = BEAM_WIDTH * (1 - (i / BEAM_SEGMENTS) * 0.55)
			local a = color.a * (1 - (i / BEAM_SEGMENTS) * 0.35)
			render.DrawBeam(s, e, w, 0, 1, Color(color.r, color.g, color.b, a))
		end
	end

	if gm and not gm:IsError() then
		render.SetMaterial(gm)
		render.DrawSprite(Vector(x, y, zBase + 60), BEAM_WIDTH * 4, BEAM_WIDTH * 4,
			Color(color.r, color.g, color.b, color.a))
		render.DrawSprite(Vector(x, y, zBase + 20), BEAM_WIDTH * 6, BEAM_WIDTH * 6,
			Color(color.r, color.g, color.b, color.a * 0.45))
		render.DrawSprite(Vector(x, y, zBase + BEAM_HEIGHT * 0.5), BEAM_WIDTH * 2, BEAM_WIDTH * 2,
			Color(color.r, color.g, color.b, color.a * 0.3))
	end
end

hook.Add("PostDrawTranslucentRenderables", "TACTIKILL_EventBeams", function(bDrawingDepth, bDrawingSkybox)
	if bDrawingDepth then return end
	if bDrawingSkybox then return end

	local now = CurTime()
	local lp = LocalPlayer()
	if not IsValid(lp) then return end
	local playerPos = lp:GetPos()

	for _, b in ipairs(BombardBeams) do
		if now >= b.appearAt and not b.done then
			if playerPos:Distance(Vector(b.x, b.y, b.z)) < 12000 then
				local color = Color(255, 50, 50, 230)
				if b.hit then
					local fade = math.Clamp(1 - (now - b.hitAt) / 0.5, 0, 1)
					if fade <= 0 then
						b.done = true
					else
						color = Color(255, 255, 200, 255 * fade)
					end
				end
				if not b.done then
					DrawBeamPillar(b.x, b.y, b.z, BEAM_HEIGHT, color)
				end
			end
		end
	end

	for _, ad in ipairs(Airdrops) do
		if ad.active then
			if playerPos:Distance(Vector(ad.x, ad.y, ad.z)) < 12000 then
				local pulse = 0.65 + math.sin(now * 4) * 0.15
				DrawBeamPillar(ad.x, ad.y, ad.z, BEAM_HEIGHT,
					Color(80, 160, 255, 255 * pulse))
			end
		end
	end
end)

hook.Add("PreDrawHalos", "TACTIKILL_AirdropHalo", function()
	local boxes = {}
	for _, ent in ipairs(ents.FindByClass("prop_physics")) do
		if IsValid(ent) and ent:GetNWBool("TACTIKILL_Airdrop") then
			boxes[#boxes + 1] = ent
		end
	end
	if #boxes > 0 then
		halo.Add(boxes, Color(80, 160, 255), 2, 2, 2, true, true)
	end
end)

hook.Add("HUDPaint", "TACTIKILL_EventTimers", function()
	if not IsValid(LocalPlayer()) then return end
	if #Airdrops == 0 then return end

	local admin = IsClientAdmin()
	local now = CurTime()

	for i = #Airdrops, 1, -1 do
		local ad = Airdrops[i]
		if ad.active then
			local remaining = ad.timerEnd - now
			if remaining > 0 then
				local screen = Vector(ad.x, ad.y, ad.z + 500):ToScreen()
				if screen.visible then
					if admin then
						draw.SimpleText(string.format("%ds", math.ceil(remaining)),
							"DermaLarge", screen.x, screen.y,
							Color(80, 160, 255, 255),
							TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					else
						draw.SimpleText("?", "DermaLarge",
							screen.x, screen.y,
							Color(80, 160, 255, 200),
							TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
					draw.SimpleText("AIRDROP", "DermaDefaultBold",
						screen.x, screen.y - 24, Color(200, 220, 255, 200),
						TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			end
		elseif ad.landed and (now - ad.landed) > 5 then
			table.remove(Airdrops, i)
		end
	end
end)

hook.Add("HUDPaint", "TACTIKILL_BombardInfo", function()
	if not IsClientAdmin() then return end
	if #BombardBeams == 0 then return end

	local active = 0
	for _, b in ipairs(BombardBeams) do
		if not b.done then active = active + 1 end
	end
	if active == 0 then return end

	draw.SimpleText(string.format("BOMBARDMENT: %d STRIKES LEFT", active),
		"DermaDefaultBold", ScrW() / 2, 40,
		Color(255, 80, 80, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)