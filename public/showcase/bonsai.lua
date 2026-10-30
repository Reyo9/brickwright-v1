--[[
	Potted Bonsai Tree, retro Roblox treatment.
	Size: about 15 x 19 x 11 studs (W x H x D). Faces -Z.
	SUBJECT TYPE: nature. It is a single tree in a pot, not a prop scene.
	SIGNATURE FEATURES:
	  1. A round ceramic pot with a wide rim, sitting on three little feet.
	  2. A gnarled trunk that zig-zags upward in bars, with balls at the bends.
	  3. Three flat, layered leaf pads: an apex pad, a left branch and a right branch.
	  4. Flared surface roots, a soil top, and moss and stone accents.
	Run it from the Studio command bar: game:GetObjects only works in Studio.
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
	pot = "Sand blue",
	foot = "Dark stone grey",
	soil = "Brown",
	bark = "Reddish brown",
	leaf = "Dark green",
	leafTop = "Bright green",
	stone = "Medium stone grey",
}

-- LAYOUT
local FOOT_H = 1
local FOOT_S = 2
local FOOT_R = 3.5
local POT_D, POT_H = 10, 3
local RIM_D, RIM_H = 11, 1
local SOIL_D, SOIL_T = 9, 0.4
local POT_TOP = FOOT_H + POT_H + RIM_H
local SOIL_TOP = POT_TOP + SOIL_T
local ROOT_Y = SOIL_TOP + 0.5
local TRUNK_PTS = {
	Vector3.new(0, POT_TOP - 0.5, 0),
	Vector3.new(1.5, SOIL_TOP + 3, -0.5),
	Vector3.new(-1, SOIL_TOP + 6, 0.5),
	Vector3.new(-3, SOIL_TOP + 8, 0),
	Vector3.new(-1, SOIL_TOP + 10.5, -0.5),
	Vector3.new(2, SOIL_TOP + 12, 0),
}
local TRUNK_W = { 2.4, 2, 1.8, 1.5, 1.2 }
local PAD_H = 2
local CAP_H = 1
local PADS = {
	{ from = 6, at = Vector3.new(2, SOIL_TOP + 13, 0), w = 7, d = 6 },
	{ from = 4, at = Vector3.new(-6.5, SOIL_TOP + 9, -1), w = 6, d = 5 },
	{ from = 2, at = Vector3.new(5.5, SOIL_TOP + 6, 0.5), w = 6, d = 5 },
}
local ROOTS = { Vector3.new(-2.5, ROOT_Y, -1.5), Vector3.new(2.5, ROOT_Y, 1) }
local MOSS = { Vector3.new(-3, SOIL_TOP + 0.2, 1.5), Vector3.new(2.5, SOIL_TOP + 0.2, -2.5) }

local model = Instance.new("Model")
model.Name = "BonsaiTree"

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

-- A square bar between two points, its length along local Z.
local function bar(name, a, b, w, colour, variant)
	local len = (b - a).Magnitude
	return make("Part", name, Vector3.new(w, w, len), CFrame.lookAt((a + b) / 2, b), colour, variant)
end

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

-- POT
for i = 0, 2 do
	local a = math.rad(90 + i * 120)
	make("Part", "PotFoot", Vector3.new(FOOT_S, FOOT_H, FOOT_S),
		CFrame.new(FOOT_R * math.cos(a), FOOT_H / 2, FOOT_R * math.sin(a)), C.foot)
end
local pot = make("Cylinder", "PotBody", Vector3.new(POT_H, POT_D, POT_D),
	CFrame.new(0, FOOT_H + POT_H / 2, 0) * UPRIGHT, C.pot, "2022 Glue")
make("Cylinder", "PotRim", Vector3.new(RIM_H, RIM_D, RIM_D),
	CFrame.new(0, FOOT_H + POT_H + RIM_H / 2, 0) * UPRIGHT, C.pot, "2022 Glue")
make("Cylinder", "Soil", Vector3.new(SOIL_T, SOIL_D, SOIL_D),
	CFrame.new(0, POT_TOP + SOIL_T / 2, 0) * UPRIGHT, C.soil, "2022 Glue")

-- SOIL DETAIL: a stone and moss tufts
make("Part", "Stone", Vector3.new(2, 1, 1),
	CFrame.new(3, SOIL_TOP + 0.5, 2) * CFrame.Angles(0, math.rad(45), 0), C.stone)
for i, m in ipairs(MOSS) do
	make("Part", "Moss" .. i, Vector3.new(1.2, 0.4, 1), CFrame.new(m), C.leafTop, "2022 Small Stud")
end

-- GNARLED TRUNK
for i = 1, #TRUNK_PTS - 1 do
	bar("Trunk" .. i, TRUNK_PTS[i], TRUNK_PTS[i + 1], TRUNK_W[i], C.bark)
end
for _, i in ipairs({ 3, 4 }) do
	local d = TRUNK_W[i] + 0.4
	make("Ball", "TrunkKnot" .. i, Vector3.new(d, d, d), CFrame.new(TRUNK_PTS[i]), C.bark, "2022 Small Stud")
end

-- SURFACE ROOTS
for i, r in ipairs(ROOTS) do
	bar("Root" .. i, Vector3.new(0, ROOT_Y, 0), r, 1, C.bark, "2022 Small Stud")
end

-- BRANCHES AND LEAF PADS
for i, pd in ipairs(PADS) do
	if pd.from ~= #TRUNK_PTS then
		bar("Branch" .. i, TRUNK_PTS[pd.from], pd.at - Vector3.new(0, PAD_H / 2, 0), 1, C.bark)
	end
	make("Part", "LeafPad" .. i, Vector3.new(pd.w, PAD_H, pd.d), CFrame.new(pd.at), C.leaf, "2022 Small Stud")
	make("Part", "LeafCap" .. i, Vector3.new(pd.w - 2, CAP_H, pd.d - 2),
		CFrame.new(pd.at + Vector3.new(-0.5, PAD_H / 2 + CAP_H / 2, 0.5)), C.leafTop, "2022 Big Stud")
end

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

model.PrimaryPart = pot
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
local ext = model:GetExtentsSize()
print(string.format("Bonsai built: %d parts, %.1f x %.1f x %.1f studs", #model:GetChildren(), ext.X, ext.Y, ext.Z))
