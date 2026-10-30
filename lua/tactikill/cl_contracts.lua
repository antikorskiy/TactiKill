local TK = TACTIKILL
local CT = TK.Contracts

CT.ClientState = CT.ClientState or { slots = {}, refreshAt = 0 }

net.Receive("TACTIKILL_Contracts", function()
	local n = net.ReadUInt(8)
	local slots = {}
	for i = 1, n do
		local tpl    = net.ReadString()
		local cust   = net.ReadString()
		local title  = net.ReadString()
		local desc   = net.ReadString()
		local prog   = net.ReadUInt(16)
		local target = net.ReadUInt(16)
		local diff   = net.ReadUInt(4)
		local reward = net.ReadInt(16)
		local pen    = net.ReadInt(16)
		local state  = net.ReadUInt(4)
		local expIn  = net.ReadFloat()
		local dur    = net.ReadFloat()
		slots[i] = {
			templateId = tpl, customerId = cust, title = title, desc = desc,
			progress = prog, target = target, difficulty = diff,
			reward = reward, penalty = pen, state = state,
			expiresAt = expIn > 0 and (CurTime() + expIn) or 0,
			duration = dur,
		}
	end
	local refreshIn = net.ReadFloat()
	CT.ClientState.slots = slots
	CT.ClientState.refreshAt = CurTime() + refreshIn
end)