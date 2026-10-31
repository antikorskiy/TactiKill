local TK = TACTIKILL
local C  = TK.Config
local CT = TK.Contracts

util.AddNetworkString("TACTIKILL_Contracts")
util.AddNetworkString("TACTIKILL_AcceptContract")

-- Weapon category helper (server-side, used by weapon-specific templates)
function CT.WeaponCategory(cls)
	if not isstring(cls) or cls == "" then return nil end
	local w = string.lower(cls)
	if w == "weapon_pistol" or w == "weapon_357" or w == "weapon_alyxgun"
		or string.find(w, "pistol", 1, true)
		or string.find(w, "magnum", 1, true)
		or string.find(w, "revolver", 1, true) then
		return "pistol"
	end
	if w == "weapon_smg1" or w == "weapon_ar2" or w == "weapon_smg2"
		or string.find(w, "smg", 1, true)
		or string.find(w, "rifle", 1, true)
		or string.find(w, "ak47", 1, true) then
		return "rifle"
	end
	if w == "weapon_shotgun" or string.find(w, "shotgun", 1, true) then
		return "shotgun"
	end
	if w == "weapon_crossbow" or string.find(w, "sniper", 1, true) or string.find(w, "awp", 1, true) then
		return "sniper"
	end
	if w == "weapon_crowbar" or w == "weapon_stunstick"
		or string.find(w, "crowbar", 1, true)
		or string.find(w, "knife", 1, true)
		or string.find(w, "bat", 1, true) then
		return "melee"
	end
	return nil
end

-- Extra contract templates (appended to the shared CT.Templates table)
local ExtraTemplates = {
	{
		id = "kill_prop", title = "Gravity Assassin",
		desc = "Kill %d hostiles with physics props",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = math.max(1, math.floor(d * 0.8)) } end,
		onKill = function(c, st, ev) if ev.style and ev.style.Prop then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_slowmo", title = "Bullet Time",
		desc = "Kill %d hostiles in slow motion",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = math.max(1, math.floor(d * 0.7)) } end,
		onKill = function(c, st, ev) if ev.style and ev.style.SlowMo then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_style_any", title = "Signature Kill",
		desc = "Kill %d hostiles with any style bonus",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = math.max(2, d + 1) } end,
		onKill = function(c, st, ev)
			local s = ev.style
			if s and (s.Airborne or s.Slide or s.SlowMo or s.PointBlank or s.LongRange or s.Prop) then
				c.progress = c.progress + 1
			end
		end,
	},
	{
		id = "kill_lowhp", title = "Do or Die",
		desc = "Kill %d hostiles while below 25 HP",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = math.max(1, math.floor(d * 0.7)) } end,
		onKill = function(c, st, ev) if ev.hp and ev.hp <= 25 then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_fullhp", title = "Untouched Predator",
		desc = "Kill %d hostiles at full health",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = math.max(2, d + 1) } end,
		onKill = function(c, st, ev) if ev.hp and ev.maxHp and ev.hp >= ev.maxHp then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_double", title = "Double Down",
		desc = "Land %d double kills",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = math.max(1, math.floor(d * 0.7)) } end,
		onKill = function(c, st, ev) if ev.step == 2 then c.progress = c.progress + 1 end end,
	},
	{
		id = "kill_headshot_chain", title = "Chain Reaction",
		desc = "Get %d headshots in a row",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = math.max(2, d + 1) } end,
		onKill = function(c, st)
			if st.headshotChain and st.headshotChain > (c.progress or 0) then
				c.progress = st.headshotChain
			end
		end,
	},
	{
		id = "kill_perfect", title = "Flawless",
		desc = "Get %d kills in a row without taking damage",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = math.max(2, d + 1) } end,
		onKill = function(c, st)
			if st.perfectKills and st.perfectKills > (c.progress or 0) then
				c.progress = st.perfectKills
			end
		end,
	},
	{
		id = "kill_variety", title = "Arms Dealer",
		desc = "Kill with %d different weapons this life",
		customerPool = "all", timeLimit = false,
		build = function(d) return { target = math.max(2, math.min(6, d + 2)) } end,
		onKill = function(c, st)
			if st.weaponChainUnique and st.weaponChainUnique > (c.progress or 0) then
				c.progress = st.weaponChainUnique
			end
		end,
	},
	{
		id = "kill_pistol", title = "Sidearm Specialist",
		desc = "Kill %d hostiles with a pistol",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = math.max(2, d + 1) } end,
		onKill = function(c, st, ev)
			if CT.WeaponCategory(ev.weaponClass) == "pistol" then c.progress = c.progress + 1 end
		end,
	},
	{
		id = "kill_shotgun", title = "Close Support",
		desc = "Kill %d hostiles with a shotgun",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = math.max(2, d + 1) } end,
		onKill = function(c, st, ev)
			if CT.WeaponCategory(ev.weaponClass) == "shotgun" then c.progress = c.progress + 1 end
		end,
	},
	{
		id = "kill_melee", title = "CQC Master",
		desc = "Kill %d hostiles in melee",
		customerPool = "all", timeLimit = true,
		build = function(d) return { target = math.max(1, math.floor(d * 0.7)) } end,
		onKill = function(c, st, ev)
			if CT.WeaponCategory(ev.weaponClass) == "melee" then c.progress = c.progress + 1 end
		end,
	},
}
for _, tpl in ipairs(ExtraTemplates) do CT.Templates[#CT.Templates + 1] = tpl end

CT.RefreshAt = CurTime() + CT.RefreshInterval

local function GetContracts(ply)
	local st = TK.Combo.Get(ply)
	if not st.contracts then st.contracts = { slots = {}, refreshAt = CT.RefreshAt } end
	return st.contracts
end

local function Reward(diff) return CT.RewardBase + diff * diff * CT.RewardPerDiff end

local function BuildOne(now)
	local picked = nil
	for _ = 1, 6 do
		local tpl = CT.Templates[math.random(#CT.Templates)]
		if tpl.id == "kill_class" then
			local cls = CT.PickAvailableClass()
			if cls then
				picked = { tpl = tpl, classEntry = cls }
				break
			end
		else
			picked = { tpl = tpl }
			break
		end
	end
	if not picked then
		picked = { tpl = CT.Templates[2] } 
	end

	local tpl        = picked.tpl
	local classEntry = picked.classEntry

	local diff
	if classEntry then
		local lo = math.max(classEntry.dMin or CT.DifficultyMin, CT.DifficultyMin)
		local hi = math.min(classEntry.dMax or CT.DifficultyMax, CT.DifficultyMax)
		if hi < lo then hi = lo end
		diff = math.random(lo, hi)
		if math.random() < 0.5 then
			diff = math.max(lo, math.min(hi, diff))
		end
	end
	if not diff then
		diff = math.random(CT.DifficultyMin, CT.DifficultyMax)
	end

	local data     = tpl.build(diff, classEntry)
	local cust
	if tpl.customerPool == "all" then
		local all = CT.AllCustomerIds()
		cust = all[math.random(#all)]
	else
		cust = tpl.customers[math.random(#tpl.customers)]
	end
	local reward   = Reward(diff)
	local duration = tpl.timeLimit and math.random(CT.TimeLimitMin, CT.TimeLimitMax) or 0

	local c = {
		id         = tostring(now * 1000 + math.random(1, 99999)),
		templateId = tpl.id,
		customerId = cust,
		title      = tpl.title,
		target     = data.target,
		progress   = 0,
		difficulty = diff,
		reward     = reward,
		penalty    = math.floor(reward * CT.PenaltyRatio),
		state      = 4,       -- 4 = pending accept; 0 = active
		created    = now,
		duration   = duration,
		expiresAt  = 0,
	}

	if classEntry then
		local label = classEntry.label
		if data.target ~= 1 then label = label .. "s" end
		c.targetClass      = classEntry.class
		c.targetClassLabel = classEntry.label
		c.desc  = string.format(tpl.desc, data.target, label)
		c.title = "Hunt Order: " .. classEntry.label
	else
		c.desc = string.format(tpl.desc, data.target)
	end
	return c
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
		net.WriteFloat(c.duration or 0)
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

net.Receive("TACTIKILL_AcceptContract", function(_, ply)
	if not IsValid(ply) or ply:IsBot() then return end
	if not ply:Alive() then
		TK.Notify(ply, "Cannot accept a contract while dead", 1)
		return
	end
	local idx = net.ReadUInt(4)
	if idx < 1 or idx > CT.SlotCount then return end

	local st = TK.Combo.Get(ply)
	local contracts = GetContracts(ply)
	local c = contracts.slots[idx]
	if not c then return end
	if c.state ~= 4 then
		TK.Notify(ply, "This offer is no longer available", 1)
		Sync(ply)
		return
	end

	if c.templateId == "kill_class" and c.targetClass then
		if #ents.FindByClass(c.targetClass) == 0 then
			TK.Notify(ply, "Target class not available on this map anymore", 1)
			contracts.slots[idx] = BuildOne(CurTime())
			Sync(ply)
			return
		end
	end

	c.state = 0
	if c.duration and c.duration > 0 then
		c.expiresAt = CurTime() + c.duration
	else
		c.expiresAt = 0
	end

	if TK.Persistence then TK.Persistence.MarkDirty(ply) end
	ply:ChatPrint(string.format("[Contract] ACCEPTED: %s", c.title))
	Sync(ply)
end)

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
				elseif c.state == 4 then
					c.state = 3
					ply:ChatPrint(string.format("[Contract] OFFER EXPIRED: %s", c.title))
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