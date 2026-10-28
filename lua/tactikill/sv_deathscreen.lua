local TK = TACTIKILL
local C  = TK.Config

util.AddNetworkString("TACTIKILL_DeathScreen")

hook.Add("PlayerDeath", "TACTIKILL_DeathDelay_Set", function(ply, inflictor, attacker)
	if not C.DeathScreen or not C.DeathScreen.Enabled then return end
	if not IsValid(ply) then return end

	local dur = C.DeathScreen.Duration

	ply.TK_DeathAt = CurTime()
	ply.NextSpawnTime = CurTime() + dur

	print("[TACTIKILL] PlayerDeath: " .. ply:Nick() .. ", delaying respawn " .. dur .. "s")

	if not ply:IsBot() then
		net.Start("TACTIKILL_DeathScreen")
			net.WriteFloat(dur)
		net.Send(ply)
	end

	timer.Simple(dur + 0.1, function()
		if IsValid(ply) and not ply:Alive() then
			ply:Spawn()
		end
	end)
end)

hook.Add("PlayerDeathThink", "TACTIKILL_DeathDelay_Block", function(ply)
	if not IsValid(ply) then return end
	if not ply.TK_DeathAt then return end

	if not C.DeathScreen or not C.DeathScreen.Enabled then
		ply.TK_DeathAt = nil
		ply.NextSpawnTime = 0
		return false
	end

	local elapsed = CurTime() - ply.TK_DeathAt

	if elapsed < C.DeathScreen.Duration then
		return true
	end

	ply.TK_DeathAt = nil
	ply.NextSpawnTime = 0
	return false
end)

hook.Add("PlayerSpawn", "TACTIKILL_DeathDelay_Reset", function(ply)
	ply.TK_DeathAt = nil
	ply.NextSpawnTime = 0
end)

hook.Add("PlayerDisconnected", "TACTIKILL_DeathDelay_Cleanup", function(ply)
	ply.TK_DeathAt = nil
	ply.NextSpawnTime = 0
end)