local TK = TACTIKILL
local C  = TK.Config
local CV = TK.CV

TK.Shake = {}
local S = TK.Shake

local sustained, impulse = 0, 0
local lastRank, lastImpulseT = 0, -10
local lastFrameT = 0

local function Enabled()
	return C.ScreenShakeEnabled and CV.shake:GetBool()
end

function S.OnRank(rank, now)
	if rank <= 0 then
		lastRank = 0
		return
	end
	if rank < lastRank then
		lastRank = rank
		return
	end
	if rank > lastRank then
		lastRank = rank
		if C.RankUpShakeEnabled and CV.rankup:GetBool() and (now - lastImpulseT) > 0.25 then
			local r = C.Ranks[rank]
			if r then
				impulse = math.max(impulse, r.shake * C.RankUpImpulseScale)
				lastImpulseT = now
			end
		end
	end
end

function S.Test()
	local r = C.Ranks[#C.Ranks]
	impulse = math.max(impulse, (r and r.shake or 1) * math.max(C.RankUpImpulseScale, 1))
end

local function Advance(dt, target)
	sustained = sustained + (target - sustained) * (1 - math.exp(-dt * C.ShakeSmoothing))
	impulse = impulse * math.exp(-dt * C.ShakeImpulseDecay)
	if impulse < 0.001 then impulse = 0 end
	if sustained < 0.001 and target == 0 then sustained = 0 end
end

hook.Add("CalcView", "TACTIKILL_Shake", function(ply, origin, angles, fov)
	if TACTIKILL.Arty and TACTIKILL.Arty.active then return end
	if ply ~= LocalPlayer() then return end

	local H = TK.HUD
	local now = CurTime()
	local real = RealTime()

	local target = 0
	if H and ply:Alive() and H.rank > 0 and H.expireAt > now then
		local r = C.Ranks[H.rank]
		if r then target = r.shake * C.ShakeSustainedFactor end
	end

	if real ~= lastFrameT then
		local dt = math.Clamp(real - lastFrameT, 0, 0.1)
		lastFrameT = real
		if not ply:Alive() then impulse = 0 end
		Advance(dt, target)
	end

	if not Enabled() then return end
	if not ply:Alive() or ply:InVehicle() or ply:ShouldDrawLocalPlayer() then return end
	if ply:GetViewEntity() ~= ply then return end

	local cap = math.min(CV.max:GetFloat(), C.ScreenShakeMaxIntensity)
	local intensity = math.min(sustained + impulse, cap) * C.ScreenShakeMultiplier * CV.mult:GetFloat()
	local amp = math.min(intensity * C.ShakeUnitsPerIntensity, C.ShakeMaxOffsetUnits)
	if amp < 0.005 then return end

	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep.CalcView then
		local o, a, f = wep:CalcView(ply, Vector(origin), Angle(angles), fov)
		origin, angles, fov = o or origin, a or angles, f or fov
	end

	local t = real * C.ShakeFrequency
	local x = math.sin(t * 37.0) * 0.6 + math.sin(t * 23.3 + 1.7) * 0.4
	local y = math.sin(t * 31.0 + 0.5) * 0.6 + math.sin(t * 17.1 + 2.3) * 0.4

	local view = {
		origin = origin + angles:Right() * (x * amp) + angles:Up() * (y * amp),
		angles = angles,
		fov = fov,
	}

	if C.ShakeRollDegrees > 0 then
		view.angles = Angle(angles.p, angles.y, angles.r + x * intensity * C.ShakeRollDegrees)
	end

	return view
end)