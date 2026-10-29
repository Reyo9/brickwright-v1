--[[
	Retro CRT Info Terminal: a chunky 2008-style computer monitor with a keyboard.
	Size: about 12 wide, 11 tall and 19 deep (studs). Faces -Z.
	SUBJECT TYPE: hard-surface item, with no stand. It rests on y = 0.
	SIGNATURE FEATURES: a deep boxy CRT case with a rear hump, a glowing green
	screen in a thick bezel, top cooling ribs, and a keyboard with chunky keys.
	Run this from the Studio command bar, because game:GetObjects is Studio-only.
]]

local MS = game:GetService("MaterialService")

local studsLoaded = false
do
	local ok, roots = pcall(game.GetObjects, game, "rbxassetid://13386676607")
	if ok then
		local tmp = Instance.new("Folder")
		for _, r in ipairs(roots) do r.Parent = tmp end
		for _, d in ipairs(tmp:GetDescendants()) do
			if d:IsA("MaterialVariant") and not MS:FindFirstChild(d.Name) then
				d.Parent = MS
			end
		end
		tmp:Destroy()
		studsLoaded = true
	else
		warn("Stud material pack failed to load, building smooth: " .. tostring(roots))
	end
end

local C = {
	case = "Light stone grey",
	trim = "Dark stone grey",
	dark = "Really black",
	glow = "Bright green",
	key = "Medium stone grey",
}

-- LAYOUT
local MON_W, MON_H, MON_D = 12, 10, 10
local FOOT_W, FOOT_H = 8, 1
local HUMP_W, HUMP_H, HUMP_D = 8, 6, 4
local BEZEL = 1.5
local BEZEL_T = 0.6
local SCREEN_W = MON_W - 2 * BEZEL
local SCREEN_H = MON_H - 2 * BEZEL
local SCREEN_T = 0.2
local CASE_Y = FOOT_H + MON_H / 2
local FRONT_Z = -MON_D / 2
local TOP_Y = FOOT_H + MON_H
local KB_W, KB_H, KB_D = 12, 1, 4
local KB_GAP = 1
local KB_Z = FRONT_Z - KB_GAP - KB_D / 2
local KEY_W, KEY_H, KEY_D = 1.2, 0.4, 1
local KEY_COLS, KEY_PITCH = 6, 1.6
local RIB_COUNT, RIB_PITCH = 6, 1.2
local VENT_ROWS, VENT_PITCH = 4, 1.2
local LINE_COUNT = 6
local LINE_LENS = { 7, 5, 6, 3, 6.5, 4 }

local model = Instance.new("Model")
model.Name = "InfoTerminal"

local function paint(p, colour, variant)
	p.BrickColor = BrickColor.new(colour)
	if studsLoaded then
		p.Material = Enum.Material.Glacier
		p.MaterialVariant = variant or "2022 Universal"
	else
		p.Material = Enum.Material.SmoothPlastic
	end
end

local function make(kind, name, size, cframe, colour, variant)
	local p
	if kind == "Wedge" then
		p = Instance.new("WedgePart")
	elseif kind == "Corner" then
		p = Instance.new("CornerWedgePart")
	else
		p = Instance.new("Part")
		if kind == "Cylinder" then
			p.Shape = Enum.PartType.Cylinder
		elseif kind == "Ball" then
			p.Shape = Enum.PartType.Ball
		end
	end
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	paint(p, colour, variant)
	p.Parent = model
	return p
end

local function glow(p)
	p.Material = Enum.Material.Neon
	return p
end

-- Foot and main CRT case
local foot = make("Part", "Foot", Vector3.new(FOOT_W, FOOT_H, FOOT_W), CFrame.new(0, FOOT_H / 2, 0), C.trim)
local case = make("Part", "Case", Vector3.new(MON_W, MON_H, MON_D), CFrame.new(0, CASE_Y, 0), C.case, "2022 Small Stud")
make("Part", "RearHump", Vector3.new(HUMP_W, HUMP_H, HUMP_D),
	CFrame.new(0, CASE_Y, MON_D / 2 + HUMP_D / 2), C.case, "2022 Small Stud")

-- Bezel frame standing proud of the case front
local bz = FRONT_Z - BEZEL_T / 2
make("Part", "BezelTop", Vector3.new(MON_W, BEZEL, BEZEL_T), CFrame.new(0, TOP_Y - BEZEL / 2, bz), C.trim, "2022 Big Stud")
make("Part", "BezelBottom", Vector3.new(MON_W, BEZEL, BEZEL_T), CFrame.new(0, FOOT_H + BEZEL / 2, bz), C.trim, "2022 Big Stud")
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "BezelSide", Vector3.new(BEZEL, SCREEN_H, BEZEL_T),
		CFrame.new(sx * (MON_W / 2 - BEZEL / 2), CASE_Y, bz), C.trim, "2022 Big Stud")
end

-- Glowing screen recessed in the bezel
local screen = glow(make("Part", "Screen", Vector3.new(SCREEN_W, SCREEN_H, SCREEN_T),
	CFrame.new(0, CASE_Y, FRONT_Z - SCREEN_T / 2), C.glow))
local light = Instance.new("PointLight")
light.Color = BrickColor.new(C.glow).Color
light.Range = 14
light.Brightness = 2
light.Parent = screen

-- Text lines on the screen
for i = 1, LINE_COUNT do
	local len = LINE_LENS[i]
	local y = CASE_Y + SCREEN_H / 2 - 1 - (i - 1) * 1
	make("Part", "TextLine", Vector3.new(len, 0.4, 0.2),
		CFrame.new(-SCREEN_W / 2 + 0.5 + len / 2, y, FRONT_Z - SCREEN_T - 0.1), C.dark, "2022 Small Stud")
end

-- Power button and LED on the lower bezel
make("Cylinder", "PowerButton", Vector3.new(0.4, 0.8, 0.8),
	CFrame.new(MON_W / 2 - 2, FOOT_H + BEZEL / 2, FRONT_Z - BEZEL_T - 0.2) * CFrame.Angles(0, math.rad(90), 0),
	C.dark, "2022 Small Stud")
glow(make("Part", "PowerLED", Vector3.new(0.4, 0.4, 0.2),
	CFrame.new(MON_W / 2 - 3.2, FOOT_H + BEZEL / 2, FRONT_Z - BEZEL_T - 0.1), C.glow))

-- Cooling ribs on top
for i = 1, RIB_COUNT do
	local x = (i - (RIB_COUNT + 1) / 2) * RIB_PITCH
	make("Part", "TopRib", Vector3.new(0.4, 0.4, MON_D - 4), case.CFrame * CFrame.new(x, MON_H / 2 + 0.2, 0),
		C.trim, "2022 Small Stud")
end

-- Side vent slots
for _, sx in ipairs({ -1, 1 }) do
	for i = 1, VENT_ROWS do
		local y = (i - (VENT_ROWS + 1) / 2) * VENT_PITCH
		make("Part", "SideVent", Vector3.new(0.2, 0.4, MON_D - 6),
			case.CFrame * CFrame.new(sx * (MON_W / 2 + 0.1), y, 0), C.dark, "2022 Small Stud")
	end
end

-- Keyboard
local kb = make("Part", "Keyboard", Vector3.new(KB_W, KB_H, KB_D), CFrame.new(0, KB_H / 2, KB_Z), C.case, "2022 Small Stud")
for _, row in ipairs({ 0, 1.2 }) do
	for i = 1, KEY_COLS do
		local x = (i - (KEY_COLS + 1) / 2) * KEY_PITCH
		make("Part", "Key", Vector3.new(KEY_W, KEY_H, KEY_D),
			kb.CFrame * CFrame.new(x, KB_H / 2 + KEY_H / 2, row), C.key, "2022 Small Stud")
	end
end
make("Part", "SpaceBar", Vector3.new(6, KEY_H, 0.8), kb.CFrame * CFrame.new(0, KB_H / 2 + KEY_H / 2, -1.2), C.key, "2022 Small Stud")

-- Cable from keyboard to monitor foot
local cableLen = (KB_Z + KB_D / 2) - (-FOOT_W / 2)
make("Part", "Cable", Vector3.new(0.4, 0.4, math.abs(cableLen)),
	CFrame.new(0, 0.2, (KB_Z + KB_D / 2 - FOOT_W / 2) / 2), C.dark, "2022 Small Stud")


-- Stud guarantee: every surface of every part is studded, no exceptions.
-- Keeps a chosen classic variant if the pack really has it; anything else
-- (no variant, a smooth one, a name the pack lacks) becomes Universal.
-- Neon is left glowing wherever it is THIN — a lens, a strip, a core bar. It may run
-- the whole length of the model; it just may not be a fat glowing block.
if studsLoaded then
	local STUDDED = { ["2022 Universal"] = true, ["2022 Small Stud"] = true, ["2022 Big Stud"] = true,
		["2022 Weld"] = true, ["2022 Glue"] = true }
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			local s = p.Size
			local thin = math.min(s.X, math.min(s.Y, s.Z))
			local light = p.Material == Enum.Material.Neon and thin <= 2.2
			if not light then
				p.Material = Enum.Material.Glacier
				if not STUDDED[p.MaterialVariant] or not MS:FindFirstChild(p.MaterialVariant) then
					p.MaterialVariant = "2022 Universal"
				end
			end
		end
	end
end

model.PrimaryPart = foot
-- Wheel check: a wheel's axle runs along its local X. A wheel, tyre or
-- hub turned so its axle points up would lie flat like a coin; stand it back up.
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("Part") and p.Shape == Enum.PartType.Cylinder then
		local n = p.Name:lower()
		local isWheel = n:find("wheel") or n:find("tyre") or n:find("tire") or n:find("hub")
		if isWheel and not n:find("steer") and math.abs(p.CFrame.RightVector.Y) > 0.7 then
			p.CFrame = CFrame.new(p.Position)
		end
	end
end

model.Parent = workspace
local count = 0
for _, d in ipairs(model:GetDescendants()) do
	if d:IsA("BasePart") then count = count + 1 end
end
local ext = model:GetExtentsSize()
print(string.format("InfoTerminal built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
