--[[
	Pirate Treasure Chest: an open wooden chest overflowing with gold coins, gems and a crown, on sand.
	Size: about 12 x 9 x 10 studs. Faces -Z.
	SUBJECT TYPE: container prop scene. BOX-THEN-LID build: floor, four walls on the floor, lid hinged at the back top edge.
	SIGNATURE FEATURES: dark planked wood with gold metal bands, a hinged lid tilted open, a gold lock plate,
	a heap of coins above the rim, a few coins spilled on the sand, gems and a small crown on top.
	LOOSE-PART RULES SHOWN: the open lid is placed by rotating around the hinge line (back top edge), so it stays attached;
	the treasure heap is layered discs whose bottoms sit inside the chest; spilled coins sit on the sand.
	Must be run from the Studio command bar: game:GetObjects is Studio-only.
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

local V = Vector3.new
local model = Instance.new("Model")
model.Name = "TreasureChest"

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
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	paint(p, colour, variant)
	p.Parent = model
	return p
end

-- onTop: a box whose BOTTOM sits at yBottom (so stacking is exact: next yBottom = this yBottom + size.Y)
local function onTop(name, size, x, yBottom, z, colour, variant, kind)
	return make(kind or "Part", name, size, CFrame.new(x, yBottom + size.Y / 2, z), colour, variant)
end

-- bone: a part stretched between two joint points (length on local Z)
local function bone(name, a, b, w, h, colour, variant)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	make("Part", name, V(w, h, len), cf, colour, variant)
	return cf, len
end
local function joint(name, at, d, colour, variant)
	make("Ball", name, V(d, d, d), CFrame.new(at), colour, variant)
end
-- Neon for light only, and only on thin parts
local function glow(p)
	p.Material = Enum.Material.Neon
	p.MaterialVariant = ""
	return p
end

local C = {
	sand = "Brick yellow", sand2 = "Cool yellow", wood = "Reddish brown", wood2 = "Brown", band = "Bright yellow",
	band2 = "Neon orange", coin = "Bright yellow", coin2 = "New Yeller", ruby = "Bright red", emerald = "Lime green",
	sapphire = "Bright blue", dark = "Black",
}

onTop("Sand", V(14, 0.6, 12), 0, 0, 0, C.sand, "2022 Big Stud")
onTop("SandBump", V(5, 0.4, 4), -3.5, 0.55, 3.5, C.sand2, "2022 Small Stud")
local G = 0.6

-- CHEST BOX: floor + four walls (each wall's bottom = floor top)
local W, D, H, T = 8, 5, 3.6, 0.5
onTop("Floor", V(W, T, D), 0, G, 0, C.wood2, "2022 Big Stud")
local FLOOR_TOP = G + T
onTop("WallFront", V(W, H, T), 0, FLOOR_TOP, -D / 2 + T / 2, C.wood, "2022 Big Stud")
onTop("WallBack", V(W, H, T), 0, FLOOR_TOP, D / 2 - T / 2, C.wood, "2022 Big Stud")
for _, sx in ipairs({ -1, 1 }) do
	onTop("WallSide", V(T, H, D - 2 * T), sx * (W / 2 - T / 2), FLOOR_TOP, 0, C.wood, "2022 Big Stud")
end
local RIM = FLOOR_TOP + H
-- plank lines and metal bands sunk 0.05 into the front wall
for i, y in ipairs({ FLOOR_TOP + 1.2, FLOOR_TOP + 2.4 }) do
	onTop("Plank" .. i, V(W - 0.4, 0.12, 0.1), 0, y, -D / 2 - 0.02, C.wood2, "2022 Small Stud")
end
for _, x in ipairs({ -W / 2 + 0.8, W / 2 - 0.8 }) do
	onTop("BandFront", V(0.6, H, 0.15), x, FLOOR_TOP, -D / 2 - 0.05, C.band, "2022 Small Stud")
	onTop("BandBack", V(0.6, H, 0.15), x, FLOOR_TOP, D / 2 + 0.05, C.band, "2022 Small Stud")
end
onTop("LockPlate", V(1.2, 1.4, 0.2), 0, RIM - 1.6, -D / 2 - 0.08, C.band2, "2022 Big Stud")
onTop("Keyhole", V(0.25, 0.5, 0.1), 0, RIM - 1.2, -D / 2 - 0.2, C.dark)
for _, sx in ipairs({ -1, 1 }) do
	onTop("Handle", V(0.3, 0.9, 1.6), sx * (W / 2 + 0.12), RIM - 1.8, 0, C.band, "2022 Small Stud")
end

-- LID: hinge line = back top edge. Build it closed relative to the hinge, then rotate open by 110 degrees.
local hinge = CFrame.new(0, RIM, D / 2) * CFrame.Angles(math.rad(110), 0, 0)
local LID_T = 0.5
make("Part", "Lid", V(W, LID_T, D), hinge * CFrame.new(0, LID_T / 2, -D / 2), C.wood, "2022 Big Stud")
make("Part", "LidCurve", V(W, 1, D - 1), hinge * CFrame.new(0, LID_T + 0.5, -D / 2), C.wood2, "2022 Big Stud")
for _, x in ipairs({ -W / 2 + 0.8, W / 2 - 0.8 }) do
	make("Part", "LidBand", V(0.6, 1.6, D + 0.1), hinge * CFrame.new(x, 0.8, -D / 2), C.band, "2022 Small Stud")
end
for _, x in ipairs({ -2, 2 }) do
	make("Cylinder", "Hinge", V(1, 0.5, 0.5), CFrame.new(x, RIM, D / 2 + 0.1), C.band2, "2022 Small Stud")
end

-- TREASURE: a heap of discs whose bottoms are inside the chest, rising above the rim
local y = RIM - 1
for i, d in ipairs({ { W - 1.2, D - 1.2 }, { W - 2.2, D - 1.8 }, { W - 3.8, D - 2.6 }, { 2.2, 1.4 } }) do
	onTop("CoinHeap" .. i, V(d[1], 0.6, d[2]), 0, y, 0, i % 2 == 0 and C.coin2 or C.coin, "2022 Big Stud")
	y = y + 0.6
end
local HEAP_TOP = y
-- loose coins sunk into heap layers
for i, c in ipairs({ { -2.8, 1, 0.2 }, { 2.6, 1, -0.6 }, { -1.4, 2, 0.6 }, { 1.2, 2, -0.4 }, { 0.2, 3, 0.4 } }) do
	make("Cylinder", "Coin" .. i, V(0.2, 1, 1), CFrame.new(c[1], RIM - 1 + c[2] * 0.6 + 0.05, c[3]) * CFrame.Angles(0.3 * i, 0, math.pi / 2 + 0.2), C.coin2, "2022 Small Stud")
end
-- gems sitting on the heap
make("Ball", "Ruby", V(1, 1, 1), CFrame.new(-2.4, RIM - 1 + 1.2 + 0.4, -0.8), C.ruby)
make("Ball", "Emerald", V(0.9, 0.9, 0.9), CFrame.new(2.2, RIM - 1 + 1.2 + 0.35, 0.6), C.emerald)
make("Ball", "Sapphire", V(0.8, 0.8, 0.8), CFrame.new(1.4, RIM - 1 + 1.8 + 0.3, -0.7), C.sapphire)
-- crown on top of the heap: band + points + gems
onTop("CrownBand", V(1.8, 0.6, 1.8), -0.4, HEAP_TOP - 0.05, 0, C.band, "2022 Big Stud")
for i, p in ipairs({ { -1.1, -0.6 }, { 0.3, -0.6 }, { -1.1, 0.6 }, { 0.3, 0.6 } }) do
	onTop("CrownPoint" .. i, V(0.4, 0.7, 0.4), p[1], HEAP_TOP + 0.5, p[2], C.band, "2022 Small Stud")
end
make("Ball", "CrownGem", V(0.4, 0.4, 0.4), CFrame.new(-0.4, HEAP_TOP + 0.25, -0.9), C.ruby)

-- SPILLED COINS on the sand (bottom on the sand top)
for i, c in ipairs({ { -5, -3.2 }, { -4.2, -4 }, { 4.8, -3.6 }, { 5.4, -2.8 }, { -5.6, 1 } }) do
	make("Cylinder", "SpillCoin" .. i, V(0.2, 1, 1), CFrame.new(c[1], G + 0.1, c[2]) * CFrame.Angles(0, i, math.pi / 2), C.coin, "2022 Small Stud")
end
make("Cylinder", "CoinStack", V(0.8, 1, 1), CFrame.new(5, G + 0.4, -1.6) * CFrame.Angles(0, 0, math.pi / 2), C.coin2, "2022 Small Stud")

-- Stud guarantee: every part studded; keeps a chosen variant if the pack has it, else Universal.
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

model.Parent = workspace
local count = 0
for _, d in ipairs(model:GetDescendants()) do
	if d:IsA("BasePart") then count = count + 1 end
end
local ext = model:GetExtentsSize()
print(string.format("TreasureChest built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
