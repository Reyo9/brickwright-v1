--[[
	Cozy Living Room corner: a sofa with cushions, a coffee table with a mug and book, a floor lamp, a rug and a plant.
	Size: about 16 x 9 x 12 studs. Faces -Z (sofa faces the viewer).
	SUBJECT TYPE: furniture interior scene. FLOOR-UP build: floor, rug on the floor, every furniture leg on the rug or floor,
	seats on legs, cushions on seats, small items on table tops.
	SIGNATURE FEATURES: a teal sofa with armrests, back and two pillows, a wooden coffee table with a mug and stacked books,
	a tall floor lamp with a warm glowing shade, a round patterned rug, a potted plant and a wall section with a picture frame.
	LOOSE-PART RULES SHOWN: each item's yBottom comes from the surface it stands on (FLOOR, RUG_TOP, SEAT_TOP, TABLE_TOP);
	the lamp shade hangs on the pole top; the picture frame is sunk 0.05 into the wall.
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
model.Name = "CozyLivingRoom"

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
	floor = "Brown", floor2 = "Reddish brown", wall = "Pastel yellow", rug = "Bright red", rug2 = "Bright yellow",
	sofa = "Bright bluish green", sofa2 = "Teal", pillow = "Pastel yellow", pillow2 = "Carnation pink", wood = "Reddish brown",
	mug = "White", book = "Bright blue", book2 = "Bright red", metal = "Dark stone grey", shade = "Cream", pot = "Dark orange", plant = "Bright green",
	frame = "Brick yellow", art = "Light blue",
}

-- FLOOR planks and a back WALL standing on the floor
onTop("Floor", V(16, 0.5, 12), 0, 0, 0, C.floor, "2022 Big Stud")
for k = -3, 3 do onTop("PlankLine", V(0.1, 0.1, 12), k * 2.2, 0.45, 0, C.floor2) end
local FLOOR = 0.5
onTop("Wall", V(16, 8, 0.6), 0, FLOOR, 5.7, C.wall, "2022 Big Stud")
onTop("Skirting", V(16, 0.5, 0.2), 0, FLOOR, 5.35, C.floor2, "2022 Small Stud")
-- picture frame sunk into the wall face
onTop("Frame", V(4, 2.6, 0.3), -3.5, FLOOR + 4.6, 5.35, C.frame, "2022 Small Stud")
onTop("Art", V(3.4, 2, 0.1), -3.5, FLOOR + 4.9, 5.18, C.art, "2022 Small Stud")
onTop("ArtSun", V(0.8, 0.8, 0.1), -2.6, FLOOR + 5.8, 5.1, C.rug2)

-- RUG: round, two rings
make("Cylinder", "Rug", V(0.2, 8, 8), CFrame.new(0, FLOOR + 0.1, -0.5) * CFrame.Angles(0, 0, math.pi / 2), C.rug, "2022 Small Stud")
make("Cylinder", "RugRing", V(0.22, 5.5, 5.5), CFrame.new(0, FLOOR + 0.11, -0.5) * CFrame.Angles(0, 0, math.pi / 2), C.rug2, "2022 Small Stud")
local RUG_TOP = FLOOR + 0.2

-- SOFA against the wall: feet on the floor, base on feet, seat cushions, back, armrests, pillows
local SX, SZ = 0, 3.6
for _, fx in ipairs({ -3.6, 3.6 }) do for _, fz in ipairs({ -1.2, 1.2 }) do onTop("SofaFoot", V(0.5, 0.5, 0.5), SX + fx, FLOOR, SZ + fz, C.wood) end end
onTop("SofaBase", V(8, 1.2, 3), SX, FLOOR + 0.5, SZ, C.sofa2, "2022 Big Stud")
local SEAT_TOP = FLOOR + 1.7 + 0.8
for i, x in ipairs({ -1.6, 1.6 }) do onTop("SeatCushion" .. i, V(3.1, 0.8, 2.6), SX + x, FLOOR + 1.7, SZ - 0.15, C.sofa, "2022 Big Stud") end
onTop("SofaBack", V(8, 2.4, 0.8), SX, FLOOR + 1.7, SZ + 1.1, C.sofa2, "2022 Big Stud")
for _, sx in ipairs({ -1, 1 }) do onTop("Armrest", V(0.8, 1.6, 3), SX + sx * 3.6, FLOOR + 1.7, SZ, C.sofa2, "2022 Big Stud") end
onTop("Pillow1", V(1.6, 1.4, 0.5), SX - 2, SEAT_TOP, SZ + 0.45, C.pillow, "2022 Small Stud")
onTop("Pillow2", V(1.6, 1.4, 0.5), SX + 2.2, SEAT_TOP, SZ + 0.45, C.pillow2, "2022 Small Stud")

-- COFFEE TABLE on the rug: four legs, top, mug and books on the top
local TX, TZ = 0, -1.6
for _, fx in ipairs({ -1.8, 1.8 }) do for _, fz in ipairs({ -0.9, 0.9 }) do onTop("TableLeg", V(0.4, 1.6, 0.4), TX + fx, RUG_TOP, TZ + fz, C.wood, "2022 Small Stud") end end
onTop("TableTop", V(4.4, 0.4, 2.6), TX, RUG_TOP + 1.6, TZ, C.wood, "2022 Big Stud")
local TABLE_TOP = RUG_TOP + 2
make("Cylinder", "Mug", V(0.9, 0.8, 0.8), CFrame.new(TX + 1.2, TABLE_TOP + 0.45, TZ) * CFrame.Angles(0, 0, math.pi / 2), C.mug, "2022 Small Stud")
make("Part", "MugHandle", V(0.2, 0.5, 0.15), CFrame.new(TX + 1.7, TABLE_TOP + 0.5, TZ), C.mug)
onTop("Book1", V(1.6, 0.3, 1.1), TX - 1, TABLE_TOP, TZ, C.book, "2022 Small Stud")
onTop("Book2", V(1.4, 0.3, 1), TX - 1, TABLE_TOP + 0.3, TZ + 0.05, C.book2, "2022 Small Stud")

-- FLOOR LAMP at the right: base on the floor, pole on the base, shade hanging from the pole top
local LX, LZ = 6, 3.6
make("Cylinder", "LampBase", V(0.3, 1.6, 1.6), CFrame.new(LX, FLOOR + 0.15, LZ) * CFrame.Angles(0, 0, math.pi / 2), C.metal, "2022 Small Stud")
onTop("LampPole", V(0.25, 6, 0.25), LX, FLOOR + 0.3, LZ, C.metal, "2022 Small Stud")
local poleTop = FLOOR + 6.3
for i, d in ipairs({ 2.2, 1.8, 1.4 }) do
	make("Cylinder", "Shade" .. i, V(0.5, d, d), CFrame.new(LX, poleTop - 1.2 + i * 0.5, LZ) * CFrame.Angles(0, 0, math.pi / 2), C.shade, "2022 Small Stud")
end
glow(make("Part", "Bulb", V(0.6, 0.4, 0.6), CFrame.new(LX, poleTop - 1.15, LZ), C.rug2))

-- PLANT at the left corner
onTop("PlantPot", V(1.4, 1.4, 1.4), -6.2, FLOOR, 4, C.pot, "2022 Small Stud")
for i, b in ipairs({ { 0, 2.4, 0, 1.6 }, { -0.4, 3.2, 0.2, 1.2 }, { 0.4, 3, -0.3, 1.1 } }) do
	make("Ball", "Leaves" .. i, V(b[4], b[4], b[4]), CFrame.new(-6.2 + b[1], FLOOR + b[2], 4 + b[3]), C.plant, "2022 Small Stud")
end

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
print(string.format("CozyLivingRoom built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
