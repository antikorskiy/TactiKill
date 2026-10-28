local TK = TACTIKILL

local channels = { [0] = nil, [1] = nil }

net.Receive("TACTIKILL_PlaySound", function()
	local path = net.ReadString()
	local kind = net.ReadUInt(2)

	if not path or path == "" then return end

	local prev = channels[kind]
	if prev and prev.IsValid and prev:IsValid() then
		prev:Stop()
	end

	local ch = sound.PlayFile("sound/" .. path, "noblock", function(snd, errCode, errStr)
		if not IsValid(snd) then
			print("[TACTIKILL] sound failed: " .. tostring(path) ..
				" (" .. tostring(errStr) .. ")")
		end
	end)

	channels[kind] = ch
	if IsValid(ch) then
		if kind == 1 then
			ch:SetVolume(0.9)
		else
			ch:SetVolume(0.7)
		end
	end
end)