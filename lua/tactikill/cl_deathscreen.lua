local TK = TACTIKILL
local C  = TK.Config

local deathStartedAt = 0
local deathDuration  = 5
local currentQuote   = nil

local fallbackQuote = { "You died. Rise again.", "TactiKill" }

local function BuildFonts()
	local s = math.Clamp(ScrH() / 1080, 0.7, 1.5)
	surface.CreateFont("TACTIKILL_DeathQuote", {
		font = "Georgia", size = math.floor(32 * s),
		weight = 400, italic = true, antialias = true,
	})
	surface.CreateFont("TACTIKILL_DeathAuthor", {
		font = "Georgia", size = math.floor(20 * s),
		weight = 400, italic = true, antialias = true,
	})
	surface.CreateFont("TACTIKILL_DeathCountdown", {
		font = "Lucida Console", size = math.floor(36 * s),
		weight = 800, antialias = true,
	})
end
BuildFonts()
hook.Add("OnScreenSizeChanged", "TACTIKILL_DeathFonts", BuildFonts)

local function PickQuote()
	if not C.DeathScreen or not C.DeathScreen.Quotes or #C.DeathScreen.Quotes == 0 then
		return fallbackQuote
	end
	return C.DeathScreen.Quotes[math.random(#C.DeathScreen.Quotes)]
end

net.Receive("TACTIKILL_DeathScreen", function()
	deathDuration = net.ReadFloat()
	deathStartedAt = CurTime()
	currentQuote = PickQuote()
	print("[TACTIKILL] death screen received: " .. tostring(deathDuration) .. "s")
end)

hook.Add("Think", "TACTIKILL_DeathTrack", function()
	if deathStartedAt == 0 then return end
	local lp = LocalPlayer()
	if not IsValid(lp) then return end
	local elapsed = CurTime() - deathStartedAt

	if elapsed > deathDuration + 5 then
		deathStartedAt = 0
		currentQuote = nil
		return
	end

	if elapsed > 1.5 and lp:Alive() then
		deathStartedAt = 0
		currentQuote = nil
	end
end)

local function DrawDeathScreen()
	if deathStartedAt == 0 then return end
	if not C.DeathScreen or not C.DeathScreen.Enabled then return end

	local lp = LocalPlayer()
	if not IsValid(lp) then return end

	local now = CurTime()
	local elapsed = now - deathStartedAt
	if elapsed > 1.5 and lp:Alive() then return end

	local duration = deathDuration
	local fadeIn = math.max(C.DeathScreen.FadeIn, 0.01)
	local fadeOut = math.max(C.DeathScreen.FadeOut, 0.01)

	local textAlpha = math.min(255, elapsed / fadeIn * 255)
	if elapsed > duration - fadeOut then
		textAlpha = math.min(textAlpha, 255 * math.max(0, (duration - elapsed) / fadeOut))
	end

	local sw, sh = ScrW(), ScrH()
	local shadowOffset = math.max(math.floor(2 * (sh / 1080)), 1)

	if currentQuote and currentQuote[1] and currentQuote[1] ~= "" then
		draw.SimpleText(currentQuote[1], "TACTIKILL_DeathQuote",
			sw / 2 + shadowOffset, sh * 0.36 + shadowOffset,
			Color(0, 0, 0, textAlpha * 0.85),
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		draw.SimpleText(currentQuote[1], "TACTIKILL_DeathQuote",
			sw / 2, sh * 0.36,
			Color(230, 230, 230, textAlpha),
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if currentQuote[2] and currentQuote[2] ~= "" then
			local ay = sh * 0.36 + math.floor(60 * (sh / 1080))
			local at = "— " .. currentQuote[2]

			draw.SimpleText(at, "TACTIKILL_DeathAuthor",
				sw / 2 + shadowOffset, ay + shadowOffset,
				Color(0, 0, 0, textAlpha * 0.85),
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			draw.SimpleText(at, "TACTIKILL_DeathAuthor",
				sw / 2, ay,
				Color(200, 200, 200, textAlpha),
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	local remaining = math.max(0, duration - elapsed)
	local pulse = 0.85 + math.sin(now * 4) * 0.15
	local ct = string.format("RESPAWN IN %.1f", remaining)

	draw.SimpleText(ct, "TACTIKILL_DeathCountdown",
		sw / 2 + shadowOffset, sh * 0.70 + shadowOffset,
		Color(0, 0, 0, textAlpha * 0.9),
		TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	draw.SimpleText(ct, "TACTIKILL_DeathCountdown",
		sw / 2, sh * 0.70,
		Color(255, 90, 90, textAlpha * pulse),
		TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "TACTIKILL_DeathScreen_HUD", DrawDeathScreen)
hook.Add("PostRender", "TACTIKILL_DeathScreen_Post", DrawDeathScreen)