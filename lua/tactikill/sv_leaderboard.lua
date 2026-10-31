local TK = TACTIKILL
local C  = TK.Config

util.AddNetworkString("TACTIKILL_RequestLeaderboard")
util.AddNetworkString("TACTIKILL_Leaderboard")

TK.Leaderboard = TK.Leaderboard or {}
local LB = TK.Leaderboard

local VALID_SORT = {
	kills       = "kills",
	score       = "score",
	best_streak = "best_streak",
	headshots   = "headshots",
	multikills  = "multikills",
}

local BAD_SIDS = {
	[""]                     = true,
	["0"]                    = true,
	["STEAM_0:0:0"]          = true,
	["STEAM_ID_PENDING"]     = true,
	["UNKNOWN"]              = true,
	["76561197960265728"]    = true,
}

local Cache   = {}
local CacheAt = {}
local Cooldown = setmetatable({}, { __mode = "k" })

local function NormalizeCategory(cat)
	if type(cat) == "string" and VALID_SORT[cat] then return cat end
	return "kills"
end

local function FallbackOnline(category, limit)
	local out = {}
	if not TK.Combo then return out end
	for _, p in ipairs(player.GetAll()) do
		local st = TK.Combo.Get(p)
		out[#out + 1] = {
			nick        = p:Nick(),
			kills       = st.kills or 0,
			deaths      = st.deaths or 0,
			score       = st.score or 0,
			best_streak = st.bestStreak or 0,
			headshots   = st.headshots or 0,
			multikills  = st.multikills or 0,
			last_seen   = 0,
		}
	end
	table.sort(out, function(a, b)
		local ak, bk = a[category] or 0, b[category] or 0
		if ak ~= bk then return ak > bk end
		return (a.score or 0) > (b.score or 0)
	end)
	while #out > limit do table.remove(out) end
	return out
end

local function OnlineNickBySid(sid)
	if not sid or sid == "" then return nil end
	for _, p in ipairs(player.GetAll()) do
		local p64 = p:SteamID64()
		local psteam = p:SteamID()
		if (p64 and p64 == sid) or (psteam and psteam == sid) then
			local n = p:Nick()
			if isstring(n) and n ~= "" then return n end
		end
	end
	return nil
end

local function NickFallback(sid)
	local online = OnlineNickBySid(sid)
	if online then return online end
	if isstring(sid) and sid ~= "" then
		-- show a readable tail of steamid instead of bare UNKNOWN
		local tail = string.sub(sid, -8)
		if tail ~= "" then return "AGENT-" .. tail end
	end
	return "UNKNOWN"
end

local function QueryDB(category, limit)
	local sortField = VALID_SORT[category] or "kills"
	local minKills = math.max(0, math.floor(tonumber(C.Leaderboard.MinKills) or 0))
	local q = string.format([[
		SELECT steamid, nick, kills, deaths, score, best_streak, headshots, multikills, last_seen
		FROM tactikill_players
		WHERE kills >= %d
		ORDER BY %s DESC, score DESC, kills DESC
		LIMIT %d
	]], minKills, sortField, limit)

	local rows = sql.Query(q)
	if not rows then return nil end

	local out = {}
	for _, r in ipairs(rows) do
		local sid = r.steamid
		if not (sid and BAD_SIDS[sid]) then
			local nick = (isstring(r.nick) and r.nick ~= "") and r.nick or NickFallback(sid)
			out[#out + 1] = {
				nick        = nick,
				kills       = tonumber(r.kills) or 0,
				deaths      = tonumber(r.deaths) or 0,
				score       = tonumber(r.score) or 0,
				best_streak = tonumber(r.best_streak) or 0,
				headshots   = tonumber(r.headshots) or 0,
				multikills  = tonumber(r.multikills) or 0,
				last_seen   = tonumber(r.last_seen) or 0,
			}
		end
	end
	return out
end

function LB.Get(category, limit)
	category = NormalizeCategory(category)
	limit = math.Clamp(math.floor(tonumber(limit) or (C.Leaderboard.Limit or 25)), 1, 100)

	local now = CurTime()
	local ttl = tonumber(C.Leaderboard.CacheSeconds) or 30
	local cached = Cache[category]
	if cached and (now - (CacheAt[category] or 0)) < ttl then
		if #cached <= limit then return cached end
		local out = {}
		for i = 1, limit do out[i] = cached[i] end
		return out
	end

	local result
	if TK.Persistence and TK.Persistence.Available and TK.Persistence.Available() then
		result = QueryDB(category, limit)
	end
	if not result then
		result = FallbackOnline(category, limit)
	end

	Cache[category] = result
	CacheAt[category] = now
	return result
end

function LB.Invalidate()
	Cache = {}
	CacheAt = {}
end

local function SendToClient(ply, category, rows)
	rows = rows or {}
	local count = math.Clamp(#rows, 0, 255)
	local now = os.time()

	net.Start("TACTIKILL_Leaderboard")
		net.WriteString(category)
		net.WriteUInt(count, 8)
		for i = 1, count do
			local r = rows[i]
			net.WriteString(string.sub(tostring(r.nick or "UNKNOWN"), 1, 32))
			net.WriteUInt(math.Clamp(math.floor(r.kills or 0), 0, 4294967295), 32)
			net.WriteUInt(math.Clamp(math.floor(r.deaths or 0), 0, 4294967295), 32)
			net.WriteInt(math.Clamp(math.floor(r.score or 0), -2147483648, 2147483647), 32)
			net.WriteUInt(math.Clamp(math.floor(r.best_streak or 0), 0, 65535), 16)
			net.WriteUInt(math.Clamp(math.floor(r.headshots or 0), 0, 4294967295), 32)
			net.WriteUInt(math.Clamp(math.floor(r.multikills or 0), 0, 4294967295), 32)
			local ago = 0
			if r.last_seen and r.last_seen > 0 then
				ago = math.Clamp(now - r.last_seen, 0, 4294967295)
			end
			net.WriteUInt(ago, 32)
		end
	net.Send(ply)
end

net.Receive("TACTIKILL_RequestLeaderboard", function(_, ply)
	if not IsValid(ply) or ply:IsBot() then return end
	if not C.Leaderboard.Enabled then return end

	local now = CurTime()
	if (Cooldown[ply] or 0) > now then return end
	Cooldown[ply] = now + 1

	local category = NormalizeCategory(net.ReadString())
	local rows = LB.Get(category, C.Leaderboard.Limit)
	SendToClient(ply, category, rows)
end)
