local TK = TACTIKILL
local C  = TK.Config
local CT = TK.Contracts

util.AddNetworkString("TACTIKILL_Contracts")

CT.RefreshAt = CurTime() + CT.RefreshInterval

local function GetContracts(ply)
	local st = TK.Combo.Get(ply)
	if not st.contracts then st.contracts = { slots = {}, refreshAt = CT.RefreshAt } end
	return st.contracts
end

local function Reward(diff) return CT.RewardBase + diff * diff * CT.RewardPerDiff end

local function BuildOne(now)
	local tpl  = CT.Templates[math.random(#CT.Templates)]
	local diff = math.random(CT.DifficultyMin, CT.DifficultyMax)
	local data = tpl.build(diff)
	local cust = tpl.customers[math.random(#tpl.customers)]
	local reward = Reward(diff)
	return {
		id         = tostring(now * 1000 + math.random(1, 99999)),
		templateId = tpl.id,
		customerId = cust,
		title      = tpl.title,
		desc       = string.format(tpl.desc, data.target),
		target     = data.target,
		progress   = 0,
		difficulty = diff,
		reward     = reward,
		penalty    = math.floor(reward * CT.PenaltyRatio),
		state      = 0,
		created    = now,
		expiresAt  = tpl.timeLimit and (now + math.random(CT.TimeLimitMin, CT.TimeLimitMax)) or 0,
	}
end

local function FillSlots(contracts, now, onlyInactive)
	for i = 1, CT.SlotCount do
		local c = contracts.slots[i]
		if not c then
			contracts.slots[i] = BuildOne(now)
		elseif onlyInactive and c.state ~= 0 then
			contracts.slots[i] = BuildOne(now)
		end
	end
end

local function Sync(ply)
	if not IsValid(ply) or ply:IsBot() then return end
	local contracts = GetContracts(ply)
	net.Start("TACTIKILL_Contracts")
	net.WriteUInt(#contracts.slots, 8)
	for _, c in ipairs(contracts.slots) do
		net.WriteString(c.templateId or "")
		net.WriteString(c.customerId or "")
		net.WriteString(c.title or "")
		net.WriteString(c.desc or "")
		net.WriteUInt(math.Clamp(c.progress or 0, 0, 65535), 16)
		net.WriteUInt(math.Clamp(c.target or 0, 0, 65535), 16)
		net.WriteUInt(c.difficulty or 1, 4)
		net.WriteInt(c.reward or 0, 16)
		net.WriteInt(c.penalty or 0, 16)
		net.WriteUInt(c.state or 0, 4)
		net.WriteFloat(c.expiresAt and c.expiresAt > 0 and math.max(c.expiresAt - CurTime(), 0) or 0)
	end
	net.WriteFloat(math.max((contracts.refreshAt or CT.RefreshAt) - CurTime(), 0))
	net.Send(ply)
end

local function Complete(c, st, ply)
	c.state = 1
	st.contractScore = (st.contractScore or 0) + c.reward
	st.score = math.min(st.score + c.reward, 2147483647)
	if TK.Persistence then TK.Persistence.MarkDirty(ply) end
	TK.Combo.Send(ply)
	ply:ChatPrint(string.format("[Contract] %s — COMPLETE (+%d pts)", c.title, c.reward))
end

local function Fail(c, st, ply)
	c.state = 2
	st.contractScore = (st.contractScore or 0) - c.penalty
	st.score = math.max(st.score - c.penalty, 0)
	if TK.Persistence then TK.Persistence.MarkDirty(ply) end
	TK.Combo.Send(ply)
	ply:ChatPrint(string.format("[Contract] %s — FAILED (-%d pts)", c.title, c.penalty))
end

local function Expire(c, st, ply)
	if c.state ~= 0 then return end
	c.state = 3
	ply:ChatPrint(string.format("[Contract] %s — EXPIRED", c.title))
end

local function Iterate(ply, fn)
	local st = TK.Combo.Get(ply)
	local contracts = GetContracts(ply)
	for _, c in ipairs(contracts.slots) do
		if c.state == 0 then
			fn(c, st, ply)
			if c.state == 0 and c.progress >= c.target then
				Complete(c, st, ply)
			end
		end
	end
end

function CT.OnKill(ply, ev)
	Iterate(ply, function(c, st)
		for _, tpl in ipairs(CT.Templates) do
			if tpl.id == c.templateId then
				if tpl.onKill then tpl.onKill(c, st, ev) end
				break
			end
		end
	end)
	Sync(ply)
end

function CT.OnDeath(ply)
	Iterate(ply, function(c, st)
		for _, tpl in ipairs(CT.Templates) do
			if tpl.id == c.templateId then
				if tpl.onDeath then tpl.onDeath(c) end
				break
			end
		end
		if c.failed then
			c.failed = nil
			Fail(c, st, ply)
		end
	end)
	Sync(ply)
end

local function RefreshAll()
	local now = CurTime()
	CT.RefreshAt = now + CT.RefreshInterval
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) then
			local contracts = GetContracts(ply)
			local st = TK.Combo.Get(ply)
			for _, c in ipairs(contracts.slots) do
				if c.state == 0 and c.expiresAt > 0 and now >= c.expiresAt then
					Expire(c, st, ply)
				end
			end
			contracts.refreshAt = CT.RefreshAt
			FillSlots(contracts, now, true)
			Sync(ply)
		end
	end
end

timer.Create("TACTIKILL_ContractsRefresh", CT.RefreshInterval, 0, RefreshAll)

timer.Create("TACTIKILL_ContractsCheck", 5, 0, function()
	local now = CurTime()
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) then
			local contracts = GetContracts(ply)
			local st = TK.Combo.Get(ply)
			local changed = false
			for _, c in ipairs(contracts.slots) do
				if c.state == 0 and c.expiresAt > 0 and now >= c.expiresAt then
					Expire(c, st, ply); changed = true
				end
			end
			if changed then Sync(ply) end
		end
	end
end)

hook.Add("PlayerInitialSpawn", "TACTIKILL_Contracts_Init", function(ply)
	timer.Simple(1, function()
		if not IsValid(ply) then return end
		FillSlots(GetContracts(ply), CurTime(), true)
		Sync(ply)
	end)
end)