local TK = TACTIKILL

util.AddNetworkString("TACTIKILL_PlaySound")

local headshotFiles = {}
local deathFiles = {}

local function ScanFolder(folder, tbl)
	for _, ext in ipairs({ "mp3", "wav", "ogg" }) do
		local files = file.Find(folder .. "/*." .. ext, "GAME")
		for _, f in ipairs(files) do
			local rel = string.sub(folder, 7) .. "/" .. f
			tbl[#tbl + 1] = rel
		end
	end
end

ScanFolder("sound/tactikill/headshot", headshotFiles)
ScanFolder("sound/tactikill/death", deathFiles)

print("[TACTIKILL] headshot sounds: " .. #headshotFiles)
print("[TACTIKILL] death sounds: " .. #deathFiles)

local function SendRandomSound(ply, list, kind)
	if #list == 0 then return end
	if not IsValid(ply) or ply:IsBot() then return end
	local path = list[math.random(#list)]
	net.Start("TACTIKILL_PlaySound")
		net.WriteString(path)
		net.WriteUInt(kind, 2)
	net.Send(ply)
end

function TK.PlayHeadshotSound(ply)
	SendRandomSound(ply, headshotFiles, 0)
end

function TK.PlayDeathSound(ply)
	SendRandomSound(ply, deathFiles, 1)
end