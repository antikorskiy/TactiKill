local TK = TACTIKILL
local C  = TK.Config
local CT = TK.Contracts

TK.Dossier = TK.Dossier or { stats = nil, CurrentTab = "player" }

local COL_BG     = Color(12, 12, 16, 240)
local COL_BORDER = Color(70, 70, 80, 255)
local COL_HEADER = Color(28, 28, 36, 255)
local COL_TEXT   = Color(235, 235, 235, 255)
local COL_DIM    = Color(150, 150, 160, 255)
local COL_AMBER  = Color(255, 190, 40, 255)
local COL_RED    = Color(255, 64, 56, 255)
local COL_GREEN  = Color(120, 220, 120, 255)
local COL_BLUE   = Color(80, 160, 255, 255)

net.Receive("TACTIKILL_Dossier", function()
	local s = {}
	s.kills         = net.ReadUInt(32)
	s.deaths        = net.ReadUInt(32)
	s.score         = net.ReadInt(32)
	s.headshots     = net.ReadUInt(32)
	s.multikills    = net.ReadUInt(32)
	s.bestStreak    = net.ReadUInt(16)
	s.shots         = net.ReadUInt(32)
	s.hits          = net.ReadUInt(32)
	s.distanceSum   = net.ReadFloat()
	s.distanceCount = net.ReadUInt(32)
	s.distanceMax   = net.ReadFloat()
	s.distanceMin   = net.ReadFloat()
	s.favWeapon     = net.ReadString()
	s.favWeaponKills= net.ReadUInt(16)
	s.contractScore = net.ReadInt(32)
	s.rank          = net.ReadUInt(8)
	TK.Dossier.stats = s

	if openPending then
		openPending = false
		TK.BuildDossier(TK.Dossier.CurrentTab or "player")
	elseif IsValid(TK.Dossier.Panel) then
		TK.BuildDossier(TK.Dossier.CurrentTab)
	end
end)

local openPending = false

function TK.RequestDossier()
	net.Start("TACTIKILL_RequestDossier")
	net.SendToServer()
end

function TK.OpenDossier(tab)
	if tab then TK.Dossier.CurrentTab = tab end
	openPending = true
	TK.RequestDossier()
	if TK.Dossier.stats then
		openPending = false
		TK.BuildDossier(TK.Dossier.CurrentTab or "player")
	end
end

local function BuildPlayerPage(parent)
	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:Dock(FILL)
	scroll:DockMargin(10, 10, 10, 10)

	local header = vgui.Create("DPanel", scroll)
	header:Dock(TOP)
	header:SetTall(110)
	header:DockMargin(0, 0, 0, 12)
	header.Paint = function(s, w, h)
		surface.SetDrawColor(30, 26, 15, 240)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(COL_AMBER)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		surface.DrawRect(0, 0, 4, h)

		draw.SimpleText("AGENT ID", "DermaDefaultBold", 20, 12, COL_DIM)
		draw.SimpleText(TK.HUD.agentId ~= "" and TK.HUD.agentId or "—",
			"DermaLarge", 20, 30, COL_AMBER)

		draw.SimpleText("CALLSIGN", "DermaDefaultBold", 20, 68, COL_DIM)
		draw.SimpleText(IsValid(LocalPlayer()) and LocalPlayer():Nick() or "—",
			"DermaLarge", 20, 84, COL_TEXT)

		local rank = C.PlayerRanks[TK.HUD.playerRank or 1] or C.PlayerRanks[1]
		draw.SimpleText("CURRENT RANK", "DermaDefaultBold", w - 20, 12, COL_DIM, 2)
		draw.SimpleText(rank.name, "DermaLarge", w - 20, 30, COL_AMBER, 2)

		local ins = TK.GetRankInsignia(TK.HUD.playerRank or 1)
		if ins ~= "" then
			draw.SimpleText(ins, "DermaDefaultBold", w - 20, 62, COL_AMBER, 2)
		end
	end

	local stats = vgui.Create("DPanel", scroll)
	stats:Dock(TOP)
	stats:SetTall(260)
	stats:DockMargin(0, 0, 0, 12)
	stats.Paint = function(s, w, h)
		surface.SetDrawColor(22, 22, 28, 240)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(COL_BORDER)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		local st = TK.Dossier.stats or {}
		local kd  = (st.deaths and st.deaths > 0) and (st.kills / st.deaths) or (st.kills or 0)
		local acc = (st.shots and st.shots > 0) and math.min((st.hits or 0) / st.shots, 1) * 100 or 0
		local avg = (st.distanceCount and st.distanceCount > 0) and (st.distanceSum / st.distanceCount) or 0

		local rows = {
			{ "KILLS",          string.Comma(st.kills or 0),              COL_TEXT  },
			{ "DEATHS",         string.Comma(st.deaths or 0),             COL_DIM   },
			{ "K / D",          string.format("%.2f", kd),                kd >= 1 and COL_GREEN or COL_RED },
			{ "HEADSHOTS",      string.Comma(st.headshots or 0),          COL_TEXT  },
			{ "MULTIKILLS",     string.Comma(st.multikills or 0),         COL_TEXT  },
			{ "BEST STREAK",    tostring(st.bestStreak or 0),             COL_BLUE  },
			{ "ACCURACY",       string.format("%.1f%%", acc),             acc >= 30 and COL_GREEN or COL_AMBER },
			{ "SCORE",          string.Comma(st.score or 0),              COL_AMBER },
			{ "CONTRACT SCORE", string.Comma(st.contractScore or 0),      COL_BLUE  },
			{ "MAX DISTANCE",   string.format("%d u", math.floor(st.distanceMax or 0)), COL_TEXT },
			{ "AVG DISTANCE",   string.format("%d u", math.floor(avg)),   COL_TEXT  },
			{ "FAV WEAPON",     (st.favWeapon ~= "" and st.favWeapon) or "—", COL_TEXT },
		}

		local cols = 3
		local rowH = math.floor((h - 20) / math.ceil(#rows / cols))
		local colW = math.floor((w - 20) / cols)

		for i, row in ipairs(rows) do
			local ci = (i - 1) % cols
			local ri = math.floor((i - 1) / cols)
			local x = 10 + ci * colW
			local y = 10 + ri * rowH
			draw.SimpleText(row[1], "DermaDefaultBold", x, y, COL_DIM)
			draw.SimpleText(row[2], "DermaLarge", x, y + 20, row[3])
		end
	end
end

local function BuildRanksPage(parent)
	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:Dock(FILL)
	scroll:DockMargin(10, 10, 10, 10)

	local H = TK.HUD
	local curIdx = TK.GetPlayerRankIndex(H.kills, H.score)

	for i, rank in ipairs(C.PlayerRanks) do
		local unlocked = i <= curIdx
		local isCurrent = i == curIdx
		local row = vgui.Create("DPanel", scroll)
		row:Dock(TOP)
		row:DockMargin(0, 0, 0, 2)
		row:SetTall(52)
		row.Paint = function(s, w, h)
			if isCurrent then surface.SetDrawColor(60, 50, 20, 240)
			elseif unlocked then surface.SetDrawColor(30, 30, 25, 220)
			else surface.SetDrawColor(20, 20, 25, 220) end
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(isCurrent and COL_AMBER or (unlocked and Color(120, 120, 100) or COL_BORDER))
			surface.DrawOutlinedRect(0, 0, w, h, 1)

			local ins = TK.GetRankInsignia(i)
			draw.SimpleText(ins, "DermaDefaultBold", 12, h / 2,
				isCurrent and COL_AMBER or COL_DIM, 0, 4)

			draw.SimpleText(rank.name, "DermaDefaultBold", 190, h / 2 - 8,
				isCurrent and COL_AMBER or (unlocked and COL_TEXT or COL_DIM), 0, 4)

			draw.SimpleText(string.format("%d kills  •  %d score", rank.min, rank.score or 0),
				"DermaDefault", 190, h / 2 + 8, COL_DIM, 0, 4)

			local status = isCurrent and "CURRENT" or (unlocked and "UNLOCKED" or "LOCKED")
			local col    = isCurrent and COL_AMBER or (unlocked and COL_GREEN or COL_DIM)
			draw.SimpleText(status, "DermaDefaultBold", w - 12, h / 2, col, 2, 4)
		end
	end
end

local function BuildAchPage(parent)
	local A = TK.Achievements
	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:Dock(FILL)
	scroll:DockMargin(10, 10, 10, 10)

	local total, unlocked = #A.List, 0
	for _ in pairs(A.Unlocked or {}) do unlocked = unlocked + 1 end

	local header = vgui.Create("DLabel", scroll)
	header:SetText(string.format("ACHIEVEMENTS  •  %d / %d", unlocked, total))
	header:SetFont("DermaLarge")
	header:SetTextColor(COL_AMBER)
	header:Dock(TOP)
	header:DockMargin(0, 0, 0, 8)

	local groups, order = {}, {}
	for _, def in ipairs(A.List) do
		local cat = def.category or "General"
		if not groups[cat] then groups[cat] = {}; order[#order+1] = cat end
		table.insert(groups[cat], def)
	end

	for _, catName in ipairs(order) do
		local catLbl = vgui.Create("DLabel", scroll)
		catLbl:SetText("— " .. catName .. " —")
		catLbl:SetFont("DermaDefaultBold")
		catLbl:SetTextColor(Color(255, 180, 40))
		catLbl:Dock(TOP)
		catLbl:DockMargin(0, 10, 0, 4)

		for _, def in ipairs(groups[catName]) do
			local on = A.Unlocked and A.Unlocked[def.id]
			local row = vgui.Create("DPanel", scroll)
			row:Dock(TOP)
			row:DockMargin(0, 2, 0, 2)
			row:SetTall(46)
			row.Paint = function(s, w, h)
				surface.SetDrawColor(on and Color(60, 50, 20, 220) or Color(30, 30, 35, 220))
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(on and COL_AMBER or COL_BORDER)
				surface.DrawOutlinedRect(0, 0, w, h, 1)

				surface.SetDrawColor(on and COL_AMBER or Color(80, 80, 90))
				surface.DrawRect(6, 6, 34, 34)
				draw.SimpleText(def.icon, "DermaDefaultBold", 23, 23,
					on and Color(20, 18, 10) or Color(180, 180, 190), 1, 1)

				draw.SimpleText(def.name, "DermaDefaultBold", 48, 10,
					on and Color(255, 240, 200) or Color(180, 180, 190))
				draw.SimpleText(def.desc, "DermaDefault", 48, 26,
					on and Color(200, 200, 200) or Color(130, 130, 140))
				draw.SimpleText(on and "UNLOCKED" or "LOCKED", "DermaDefaultBold",
					w - 10, h / 2, on and COL_GREEN or COL_DIM, 2, 4)
			end
		end
	end
end

local function BuildContractsPage(parent)
	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:Dock(FILL)
	scroll:DockMargin(10, 10, 10, 10)

	local header = vgui.Create("DPanel", scroll)
	header:Dock(TOP)
	header:SetTall(40)
	header:DockMargin(0, 0, 0, 10)
	header.Paint = function(s, w, h)
		surface.SetDrawColor(28, 28, 36, 240)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(COL_AMBER)
		surface.DrawRect(0, 0, 3, h)
		draw.SimpleText("CONTRACT BOARD", "DermaDefaultBold", 14, h / 2, COL_AMBER, 0, 4)
		local rem = math.max(0, (CT.ClientState.refreshAt or 0) - CurTime())
		draw.SimpleText(string.format("REFRESH IN %s", TK.FormatTime(rem)),
			"DermaDefaultBold", w - 14, h / 2, COL_DIM, 2, 4)
	end

	local legend = vgui.Create("DPanel", scroll)
	legend:Dock(TOP)
	legend:SetTall(60)
	legend:DockMargin(0, 0, 0, 10)
	legend.Paint = function(s, w, h)
		surface.SetDrawColor(20, 20, 26, 220)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(COL_BORDER)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText("ACTIVE CLIENTS", "DermaDefaultBold", 10, 8, COL_DIM)

		local x = 10
		for _, cust in ipairs(CT.Customers) do
			local col = Color(cust.color[1], cust.color[2], cust.color[3])
			draw.SimpleText(cust.name, "DermaDefaultBold", x, 32, col)
			surface.SetFont("DermaDefaultBold")
			local tw = surface.GetTextSize(cust.name)
			x = x + tw + 20
			if x > w - 80 then break end
		end
	end

	local slotCount = CT.SlotCount or 3
	for idx = 1, slotCount do
		local card = vgui.Create("DPanel", scroll)
		card:Dock(TOP)
		card:DockMargin(0, 0, 0, 8)
		card:SetTall(120)

		card.Paint = function(s, w, h)
			local c = CT.ClientState.slots[idx]
			if not c then return end
			local cust = CT.CustomerById[c.customerId]
			local cc   = cust and Color(cust.color[1], cust.color[2], cust.color[3]) or COL_AMBER

			surface.SetDrawColor(22, 22, 28, 240)
			surface.DrawRect(0, 0, w, h)

			local borderCol
			if c.state == 1 then borderCol = COL_GREEN
			elseif c.state == 2 then borderCol = COL_RED
			elseif c.state == 3 then borderCol = COL_DIM
			elseif c.state == 4 then
				local pulse = 0.7 + math.sin(CurTime() * 4) * 0.3
				borderCol = Color(255, 190, 40, 255 * pulse)
			else borderCol = cc end

			surface.SetDrawColor(borderCol)
			surface.DrawOutlinedRect(0, 0, w, h, c.state == 4 and 2 or 1)
			surface.DrawRect(0, 0, 4, h)

			local custText = cust and (cust.name .. " // " .. cust.fullName) or "UNKNOWN"
			draw.SimpleText(custText, "DermaDefaultBold", 14, 12, cc)

			local stars = string.rep("*", c.difficulty) .. string.rep(".", 10 - c.difficulty)
			draw.SimpleText(stars, "DermaDefaultBold", w - 14, 12, COL_AMBER, 2, 0)

			draw.SimpleText(c.title, "DermaLarge", 14, 34, COL_TEXT)
			draw.SimpleText(c.desc, "DermaDefault", 14, 60, COL_DIM)

			local barY = 84
			if c.state == 4 then
				local durStr = (c.duration and c.duration > 0) and TK.FormatTime(c.duration) or "NO LIMIT"
				draw.SimpleText("OFFERED", "DermaDefaultBold", 14, barY - 4, cc)
				draw.SimpleText("Time limit: " .. durStr .. "  ·  +" .. c.reward .. " / -" .. c.penalty,
					"DermaDefault", 14, barY + 14, COL_DIM)
			elseif c.state == 0 then
				local pct = c.target > 0 and math.Clamp(c.progress / c.target, 0, 1) or 0
				local barW = w - 260
				surface.SetDrawColor(40, 40, 48, 255)
				surface.DrawRect(14, barY, barW, 8)
				surface.SetDrawColor(cc)
				surface.DrawRect(14, barY, math.floor(barW * pct), 8)
				draw.SimpleText(string.format("%d / %d", c.progress, c.target),
					"DermaDefaultBold", 14, barY + 14, COL_TEXT)

				draw.SimpleText(string.format("+%d pts", c.reward), "DermaDefaultBold",
					w - 240, barY - 4, COL_GREEN)
				draw.SimpleText(string.format("-%d on fail", c.penalty), "DermaDefault",
					w - 240, barY + 14, COL_RED)

				if c.expiresAt > 0 then
					local rem = math.max(0, c.expiresAt - CurTime())
					draw.SimpleText(string.format("TIME: %s", TK.FormatTime(rem)),
						"DermaDefaultBold", w - 14, h - 14,
						rem < 60 and COL_RED or COL_AMBER, 2, 2)
				else
					draw.SimpleText("NO TIMER", "DermaDefault", w - 14, h - 14, COL_DIM, 2, 2)
				end
			else
				local stText = c.state == 1 and "COMPLETE" or c.state == 2 and "FAILED" or "EXPIRED"
				local stCol  = c.state == 1 and COL_GREEN or c.state == 2 and COL_RED or COL_DIM
				draw.SimpleText(stText, "DermaLarge", w / 2, 40, stCol, 1, 1)
				draw.SimpleText(string.format("+%d / -%d", c.reward, c.penalty),
					"DermaDefault", w - 14, h - 14, COL_DIM, 2, 2)
			end
		end

		local btn = vgui.Create("DButton", card)
		btn:SetText("ACCEPT")
		btn:SetFont("DermaDefaultBold")
		btn:SetTextColor(Color(20, 18, 10))

		btn.Paint = function(s, w, h)
			local c = CT.ClientState.slots[idx]
			if not c or c.state ~= 4 then return end
			local hover = s:IsHovered()
			surface.SetDrawColor(hover and Color(255, 220, 80) or Color(255, 190, 40))
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 240, 120)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end

		btn.Think = function(s)
			local c = CT.ClientState.slots[idx]
			s:SetVisible(c ~= nil and c.state == 4)
			if c and c.state == 4 then
				local w = s:GetParent():GetWide()
				s:SetPos(w - 130, 78)
				s:SetSize(120, 34)
			end
		end

		btn.DoClick = function()
			local c = CT.ClientState.slots[idx]
			if not c or c.state ~= 4 then return end
			net.Start("TACTIKILL_AcceptContract")
				net.WriteUInt(idx, 4)
			net.SendToServer()
		end
	end
end

function TK.BuildDossier(forceTab)
	if IsValid(TK.Dossier.Panel) then TK.Dossier.Panel:Remove() end
	local tab = forceTab or TK.Dossier.CurrentTab or "player"
	TK.Dossier.CurrentTab = tab

	local frame = vgui.Create("DFrame")
	TK.Dossier.Panel = frame
	frame:SetSize(math.min(ScrW() * 0.92, 1000), math.min(ScrH() * 0.9, 680))
	frame:Center()
	frame:SetTitle("TACTIKILL // AGENT DOSSIER")
	frame:MakePopup()

	local strip = vgui.Create("DPanel", frame)
	strip:Dock(TOP)
	strip:SetTall(36)
	strip:DockMargin(0, 0, 0, 6)
	strip.Paint = function(s, w, h)
		surface.SetDrawColor(12, 12, 16, 240)
		surface.DrawRect(0, 0, w, h)
	end

	local content = vgui.Create("DPanel", frame)
	content:Dock(FILL)
	content.Paint = function(s, w, h)
		surface.SetDrawColor(18, 18, 24, 240)
		surface.DrawRect(0, 0, w, h)
	end

	local pages, tabBtns = {}, {}
	local current

	local function Show(id)
		current = id
		TK.Dossier.CurrentTab = id
		for tid, b in pairs(tabBtns) do
			b:SetTextColor(tid == id and COL_AMBER or COL_DIM)
		end
		for pid, page in pairs(pages) do
			if pid == id then page:Show() else page:Hide() end
		end
	end

	local function MakeTab(id, label, builder)
		local btn = vgui.Create("DButton", strip)
		btn:Dock(LEFT)
		btn:SetWide(180)
		btn:SetText(label)
		btn:SetFont("DermaDefaultBold")
		btn:SetTextColor(COL_DIM)
		btn.Paint = function(s, w, h)
			if current == id then
				surface.SetDrawColor(255, 200, 50, 40)
				surface.DrawRect(0, 0, w, h)
			end
			surface.SetDrawColor(60, 60, 70)
			surface.DrawRect(w - 1, 4, 1, h - 8)
		end
		btn.DoClick = function() Show(id) end
		tabBtns[id] = btn

		local page = vgui.Create("DPanel", content)
		page:Dock(FILL)
		page.Paint = function() end
		page:Hide()
		pages[id] = page
		builder(page)
		return page
	end

	MakeTab("player",    "AGENT / STATS", BuildPlayerPage)
	MakeTab("ranks",     "RANKS",         BuildRanksPage)
	MakeTab("ach",       "ACHIEVEMENTS",  BuildAchPage)
	MakeTab("contracts", "CONTRACTS",     BuildContractsPage)

	Show(tab)
end

concommand.Add("tactikill_dossier", function() TK.OpenDossier("player") end, nil, "Open agent dossier (Agent / Stats)")
concommand.Add("tactikill_ranks", function() TK.OpenDossier("ranks") end, nil, "Open the rank tree")
concommand.Add("tactikill_contracts", function() TK.OpenDossier("contracts") end, nil, "Open the contract board")
concommand.Add("tactikill_dossier_ach", function() TK.OpenDossier("ach") end, nil, "Open achievements")

hook.Add("Think", "TACTIKILL_DossierLive", function()
	if not IsValid(TK.Dossier.Panel) then return end
	if TK.Dossier.CurrentTab ~= "contracts" then return end
end)