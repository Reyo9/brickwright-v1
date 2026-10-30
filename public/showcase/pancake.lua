--[[
	Pancake Stack - a plate of five pancakes with butter melting and syrup dripping.
	Size: 18 x 7.4 x 18 studs (plate diameter 18, stack about 7.4 tall). Faces -Z (long drip and fork to the front/right).
	SUBJECT TYPE: prop scene (food). Plate base, the pancake stack as hero, a fork as supporting item.
	SIGNATURE FEATURES: a tall stack of thick golden discs, a square butter pat set on the diagonal,
	an amber syrup pool on top, fat syrup drips running down the sides into a puddle on the plate.
	Run from the Studio command bar: game:GetObjects is Studio-only.
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
	plate = "White",
	cakeA = "Nougat",
	cakeB = "Cork",
	syrup = "Dark orange",
	butter = "Cool yellow",
	melt = "Bright yellow",
	fork = "Medium stone grey",
}

-- LAYOUT
local PLATE_D, PLATE_T = 18, 1
local CAKE_T = 1
local CAKES = {
	{ d = 12, x = 0 },
	{ d = 12, x = 0.5 },
	{ d = 11, x = 0 },
	{ d = 12, x = -0.5 },
	{ d = 11, x = 0 },
}
local STACK_BASE = PLATE_T
local STACK_TOP = STACK_BASE + #CAKES * CAKE_T
local SYRUP_D, FILM_T = 9, 0.2
local MELT_W = 4
local BUTTER_W, BUTTER_H = 3, 1
local DRIP_W = 1
local DRIP_R = 6 - 0.3
local DRIPS = {
	{ a = -90, len = 4.6 },
	{ a = -135, len = 2.5 },
	{ a = -45, len = 3.5 },
	{ a = 90, len = 2 },
}
local TIP_D = 1.2
local PUDDLE_D, PUDDLE_R = 4, 6.5
local FORK_X, FORK_Z, FORK_L = 7.5, 1, 6
local TINE_N, TINE_L = 3, 1.5

local model = Instance.new("Model")
model.Name = "PancakeStack"

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
		if kind == "Cylinder" then p.Shape = Enum.PartType.Cylinder end
		if kind == "Ball" then p.Shape = Enum.PartType.Ball end
	end
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	paint(p, colour, variant)
	p.Parent = model
	return p
end

-- A flat disc lying on the ground plane (cylinder axis turned to Y)
local FLAT = CFrame.Angles(0, 0, math.rad(90))
local function disc(name, d, t, x, y, z, colour, variant)
	return make("Cylinder", name, Vector3.new(t, d, d), CFrame.new(x, y, z) * FLAT, colour, variant)
end

-- PLATE (ceramic)
local plate = disc("Plate", PLATE_D, PLATE_T, 0, PLATE_T / 2, 0, C.plate, "2022 Glue")

-- PANCAKE STACK (bread texture, alternating golden tones)
local topX = 0
for i, c in ipairs(CAKES) do
	local y = STACK_BASE + (i - 0.5) * CAKE_T
	local col = (i % 2 == 0) and C.cakeB or C.cakeA
	disc("Pancake" .. i, c.d, CAKE_T, c.x, y, 0, col, "2022 Weld")
	topX = c.x
end

-- SYRUP POOL ON TOP
disc("SyrupPool", SYRUP_D, FILM_T, topX, STACK_TOP + FILM_T / 2, 0, C.syrup, "2022 Big Stud")

-- MELTING BUTTER: melt puddle then pat, both on the diagonal
local meltY = STACK_TOP + FILM_T + FILM_T / 2
make("Part", "ButterMelt", Vector3.new(MELT_W, FILM_T, MELT_W),
	CFrame.new(topX, meltY, 0) * CFrame.Angles(0, math.rad(45), 0), C.melt, "2022 Big Stud")
make("Part", "Butter", Vector3.new(BUTTER_W, BUTTER_H, BUTTER_W),
	CFrame.new(topX, meltY + FILM_T / 2 + BUTTER_H / 2, 0) * CFrame.Angles(0, math.rad(45), 0),
	C.butter, "2022 Big Stud")

-- SYRUP DRIPS down the sides, each with a bead at the tip
local dripTop = STACK_TOP + FILM_T
for i, d in ipairs(DRIPS) do
	local a = math.rad(d.a)
	local x, z = math.cos(a) * DRIP_R, math.sin(a) * DRIP_R
	make("Part", "Drip" .. i, Vector3.new(DRIP_W, d.len, DRIP_W),
		CFrame.new(x, dripTop - d.len / 2, z) * CFrame.Angles(0, -a, 0), C.syrup, "2022 Big Stud")
	make("Ball", "DripTip" .. i, Vector3.new(TIP_D, TIP_D, TIP_D),
		CFrame.new(x, dripTop - d.len, z), C.syrup, "2022 Small Stud")
end

-- SYRUP PUDDLE on the plate under the long front drip
disc("SyrupPuddle", PUDDLE_D, FILM_T, 0, PLATE_T + FILM_T / 2, -PUDDLE_R, C.syrup, "2022 Big Stud")

-- FORK resting on the plate rim
local forkY = PLATE_T + 0.2
make("Part", "ForkHandle", Vector3.new(1, 0.4, FORK_L), CFrame.new(FORK_X, forkY, FORK_Z), C.fork, "2022 Small Stud")
for t = 1, TINE_N do
	local tx = FORK_X + (t - (TINE_N + 1) / 2) * 0.35
	make("Part", "ForkTine" .. t, Vector3.new(0.2, 0.4, TINE_L),
		CFrame.new(tx, forkY, FORK_Z - FORK_L / 2 - TINE_L / 2), C.fork, "2022 Small Stud")
end

-- Stud guarantee: every surface of every part is studded. Keeps a chosen variant if the pack has it;
-- anything else becomes Universal. Neon stays glowing only where it is THIN (lens, strip, core bar).
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

model.PrimaryPart = plate
-- Wheel check: a wheel's axle runs along its local X. A wheel turned so its axle points up lies flat like a coin; stand it back up.
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
local _, size = model:GetBoundingBox()
print(string.format("PancakeStack built: %d parts, %.1f x %.1f x %.1f studs", #model:GetChildren(), size.X, size.Y, size.Z))
