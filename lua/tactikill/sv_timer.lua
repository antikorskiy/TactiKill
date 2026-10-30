local TK = TACTIKILL

util.AddNetworkString("TACTIKILL_Timer")

TK.Timer = {}
local T = TK.Timer

local Timers = setmetatable({}, { __mode = "k" })

function T.Get(ply)
	local s = Timers[ply]
	if not s then
		s = { running = false, elapsed = 0, started = 0 }
		Timers[ply] = s
	end
	return s
end

function T.Elapsed(ply, now)
	local s = T.Get(ply)
	if s.running then return s.elapsed + ((now or CurTime()) - s.started) end
	return s.elapsed
end

function T.Send(ply)
	if not IsValid(ply) or ply:IsBot() then return end
	local s = T.Get(ply)
	net.Start("TACTIKILL_Timer")
		net.WriteBool(s.running)
		net.WriteFloat(T.Elapsed(ply))
	net.Send(ply)
end

function T.Start(ply)
	local s = T.Get(ply)
	if not s.running then
		s.running = true
		s.started = CurTime()
	end
	return true
end

function T.Pause(ply)
	local s = T.Get(ply)
	if s.running then
		s.elapsed = s.elapsed + (CurTime() - s.started)
		s.running = false
	end
	return false
end

function T.Toggle(ply)
	local s = T.Get(ply)
	if s.running then return T.Pause(ply) end
	return T.Start(ply)
end

function T.Reset(ply)
	local s = T.Get(ply)
	s.elapsed = 0
	s.started = CurTime()
end

function T.Clear(ply)
	Timers[ply] = nil
end
