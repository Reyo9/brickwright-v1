--[[
	Corner Ice Cream Shop: a small two-colour shop with a striped awning, big front window, door, sign and a bench.
	Size: about 16 x 13 x 14 studs. Faces -Z (shop front).
	SUBJECT TYPE: building. FLOOR-UP build: sidewalk, floor slab, walls on the slab (front wall built around
	window and door holes), roof slab on the walls, sign and awning fixed to the front wall.
	SIGNATURE FEATURES: pastel walls with a white base trim, a pink-and-white striped sloped awning,
	a large glass window with a display counter, a blue door with a gold knob, a giant ice cream cone sign on the roof,
	potted plants and a bench on the sidewalk.
	LOOSE-PART RULES SHOWN: the front wall is assembled from pieces that fill the gaps around the window and door
	(no holes left, no overlaps); the awning's back edge touches the wall face; the roof sign stands on the roof top.
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
model.Name = "CornerShop"

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
	walk = "Medium stone grey", walk2 = "Light stone grey", floor = "Brick yellow", wall = "Pastel blue-green", trim = "White",
	roof = "Carnation pink", awn = "Hot pink", awn2 = "White", glass = "Light blue", door = "Bright blue", knob = "Bright yellow",
	cone = "Nougat", cream = "Pink", cream2 = "Pastel yellow", cherry = "Bright red", wood = "Reddish brown", plant = "Bright green", pot = "Dark orange",
}

-- SIDEWALK and FLOOR
onTop("Sidewalk", V(18, 0.4, 16), 0, 0, 0, C.walk, "2022 Big Stud")
for k = -3, 3 do onTop("Slab", V(0.15, 0.1, 4), k * 2.5, 0.35, -6, C.walk2) end
onTop("FloorSlab", V(14, 0.6, 10), 0, 0.4, 1.5, C.floor, "2022 Big Stud")
local F = 1.0 -- floor top
local WH = 8 -- wall height
local FRONT_Z = 1.5 - 5 + 0.25 -- front wall centre z (wall thickness 0.5)

-- BACK and SIDE walls
onTop("WallBack", V(14, WH, 0.5), 0, F, 1.5 + 5 - 0.25, C.wall, "2022 Big Stud")
for _, sx in ipairs({ -1, 1 }) do
	onTop("WallSide", V(0.5, WH, 9), sx * 6.75, F, 1.5, C.wall, "2022 Big Stud")
end
-- FRONT wall around a window (x -5.5..0.5, y F+1.5..F+6) and a door (x 2..5, y F..F+6)
local function fw(name, x0, x1, y0, y1, colour)
	onTop(name, V(x1 - x0, y1 - y0, 0.5), (x0 + x1) / 2, F + y0, FRONT_Z, colour or C.wall, "2022 Big Stud")
end
fw("FrontLeft", -7, -5.5, 0, WH)
fw("UnderWindow", -5.5, 0.5, 0, 1.5)
fw("FrontMid", 0.5, 2, 0, WH)
fw("FrontRight", 5, 7, 0, WH)
fw("OverWindowDoor", -5.5, 5, 6, WH)
-- glass in the window hole and the door in its hole (exact fit)
onTop("Window", V(6, 4.5, 0.2), -2.5, F + 1.5, FRONT_Z, C.glass)
onTop("WindowBarV", V(0.25, 4.5, 0.3), -2.5, F + 1.5, FRONT_Z, C.trim)
onTop("WindowSill", V(6.6, 0.3, 0.9), -2.5, F + 1.2, FRONT_Z - 0.3, C.trim, "2022 Small Stud")
onTop("Door", V(3, 6, 0.3), 3.5, F, FRONT_Z, C.door, "2022 Big Stud")
make("Ball", "Knob", V(0.4, 0.4, 0.4), CFrame.new(4.5, F + 3, FRONT_Z - 0.25), C.knob)
onTop("DoorWindow", V(1.6, 1.6, 0.35), 3.5, F + 3.8, FRONT_Z, C.glass)
-- base trim sunk into the front of the wall
onTop("BaseTrim", V(14.2, 0.6, 0.2), 0, F, FRONT_Z - 0.3, C.trim, "2022 Small Stud")
-- counter inside the window, standing on the floor, touching the window wall
onTop("Counter", V(5.6, 1.4, 1.2), -2.5, F, FRONT_Z + 0.85, C.trim, "2022 Big Stud")
for i, x in ipairs({ -4.2, -2.5, -0.8 }) do
	onTop("Tub" .. i, V(1, 0.5, 0.8), x, F + 1.4, FRONT_Z + 0.85, ({ C.cream, C.cream2, C.cherry })[i], "2022 Small Stud")
end

-- ROOF slab on the walls and a trim lip
local ROOF_Y = F + WH
onTop("Roof", V(15, 0.8, 11), 0, ROOF_Y, 1.5, C.roof, "2022 Big Stud")
onTop("RoofLip", V(15.4, 0.4, 0.4), 0, ROOF_Y, -4.1, C.trim, "2022 Small Stud")
local ROOF_TOP = ROOF_Y + 0.8

-- AWNING: sloped stripes whose back edge touches the front wall face
local awnY = F + 6.3
for k = 0, 6 do
	local x = -5.6 + k * 1.6
	make("Wedge", "Awning" .. k, V(1.6, 1.2, 2.4), CFrame.new(x, awnY + 0.6, FRONT_Z - 0.25 - 1.2) * CFrame.Angles(0, math.pi, 0), k % 2 == 0 and C.awn or C.awn2, "2022 Small Stud")
	onTop("AwnFlap" .. k, V(1.6, 0.5, 0.15), x, awnY - 0.5, FRONT_Z - 0.25 - 2.4 + 0.08, k % 2 == 0 and C.awn or C.awn2, "2022 Small Stud")
end

-- ROOF SIGN: a giant ice cream cone standing on the roof
local sx0, sz0 = -3, 2
-- cone: discs that shrink toward the bottom, stacked with a running y from the roof top
local cy = ROOF_TOP
for i, d in ipairs({ 0.5, 0.9, 1.3, 1.7, 2.1 }) do
	make("Cylinder", "Cone" .. i, V(0.6, d, d), CFrame.new(sx0, cy + 0.3, sz0) * CFrame.Angles(0, 0, math.pi / 2), i % 2 == 0 and C.wood or C.cone, "2022 Small Stud")
	cy = cy + 0.6
end
make("Ball", "Scoop1", V(2.4, 2.4, 2.4), CFrame.new(sx0, ROOF_TOP + 3.9, sz0), C.cream, "2022 Small Stud")
make("Ball", "Scoop2", V(2, 2, 2), CFrame.new(sx0, ROOF_TOP + 5.6, sz0), C.cream2, "2022 Small Stud")
make("Ball", "Cherry", V(0.8, 0.8, 0.8), CFrame.new(sx0, ROOF_TOP + 6.8, sz0), C.cherry)
-- name board on two posts standing on the roof
for _, x in ipairs({ 1.5, 5.5 }) do onTop("SignPost", V(0.4, 1.4, 0.4), x, ROOF_TOP, -2.5, C.wood, "2022 Small Stud") end
onTop("SignBoard", V(5, 1.8, 0.4), 3.5, ROOF_TOP + 1.4, -2.5, C.trim, "2022 Big Stud")
onTop("SignText", V(4, 0.9, 0.1), 3.5, ROOF_TOP + 1.85, -2.75, C.awn, "2022 Small Stud")

-- SIDEWALK PROPS: bench and two potted plants
for _, x in ipairs({ -6.5, -3 }) do onTop("BenchLeg", V(0.4, 1, 1.2), x, 0.4, -6.2, C.wood, "2022 Small Stud") end
onTop("BenchSeat", V(4.4, 0.4, 1.4), -4.75, 1.4, -6.2, C.wood, "2022 Small Stud")
for i, x in ipairs({ 1, 6 }) do
	onTop("Pot" .. i, V(1.2, 1.2, 1.2), x, 0.4, FRONT_Z - 1.2, C.pot, "2022 Small Stud")
	make("Ball", "Bush" .. i, V(1.6, 1.6, 1.6), CFrame.new(x, 0.4 + 1.2 + 0.6, FRONT_Z - 1.2), C.plant, "2022 Small Stud")
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
print(string.format("CornerShop built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
