--[[
	Pirate Sloop: a small wooden pirate ship on a patch of sea, one mast with a striped sail and a skull flag.
	Size: about 10 x 20 x 22 studs. Faces -Z (bow forward).
	SUBJECT TYPE: vehicle (ship) on a water base. HULL-UP build: water slab, hull layers sunk into the water,
	deck on the hull, mast through the deck, sail and yard hanging from the mast.
	SIGNATURE FEATURES: dark wood hull with a gold trim line, a pointed bow, raised stern deck with railings,
	two cannons poking from ports, a tall mast with a crow's nest, a red-and-white sail, a black skull flag and a ship's wheel.
	LOOSE-PART RULES SHOWN: the hull bottom sits 0.6 below the water top; railings sit on the deck edge;
	the sail hangs from a yard that crosses the mast; the flag pole starts inside the crow's nest.
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
model.Name = "PirateSloop"

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
	sea = "Bright blue", sea2 = "Medium blue", foam = "White", hull = "Reddish brown", hull2 = "Brown", deck = "Brick yellow",
	trim = "Bright yellow", mast = "Brown", sail = "White", stripe = "Bright red", iron = "Black", flag = "Really black", skull = "White",
}

-- SEA
onTop("Sea", V(16, 1, 28), 0, 0, 0, C.sea, "2022 Big Stud")
local SEA_TOP = 1
for i, w in ipairs({ { -5.5, -8 }, { 5.8, 4 }, { -6, 9 }, { 4.5, -11 } }) do
	onTop("Wave" .. i, V(3, 0.3, 1), w[1], SEA_TOP - 0.05, w[2], i % 2 == 0 and C.foam or C.sea2, "2022 Small Stud")
end

-- HULL: two layers, bottom sunk 0.6 into the water; bow = wedges on the front of each layer
local HULL_BOTTOM = SEA_TOP - 0.6
local layers = { { V(5, 1.4, 14), C.hull2 }, { V(7, 1.6, 16), C.hull } }
local y = HULL_BOTTOM
for i, L in ipairs(layers) do
	onTop("Hull" .. i, L[1], 0, y, 0, L[2], "2022 Big Stud")
	make("Wedge", "Bow" .. i, V(L[1].X, L[1].Y, 3), CFrame.new(0, y + L[1].Y / 2, -L[1].Z / 2 - 1.5) * CFrame.Angles(0, math.pi, 0), L[2], "2022 Big Stud")
	y = y + L[1].Y
end
local DECK_Y = y
onTop("TrimLine", V(7.1, 0.3, 16.1), 0, DECK_Y - 0.6, 0, C.trim, "2022 Small Stud")
onTop("Deck", V(6.4, 0.3, 15.4), 0, DECK_Y - 0.05, 0, C.deck, "2022 Small Stud")
local DECK_TOP = DECK_Y + 0.25

-- STERN CASTLE at the back, with a railing on its edge
local STERN = V(7, 2, 4)
onTop("Stern", STERN, 0, DECK_TOP, 6, C.hull, "2022 Big Stud")
local STERN_TOP = DECK_TOP + STERN.Y
for _, sx in ipairs({ -1, 1 }) do
	for k = 0, 3 do onTop("SternPost", V(0.3, 1, 0.3), sx * 3.3, STERN_TOP, 4.4 + k * 1.05, C.hull2, "2022 Small Stud") end
	onTop("SternRail", V(0.3, 0.3, 4), sx * 3.3, STERN_TOP + 1, 6, C.trim, "2022 Small Stud")
	-- deck railing along the main deck edges
	for k = 0, 5 do onTop("RailPost", V(0.3, 0.9, 0.3), sx * 3.3, DECK_TOP, -6 + k * 2, C.hull2, "2022 Small Stud") end
	onTop("Rail", V(0.3, 0.3, 10.4), sx * 3.3, DECK_TOP + 0.9, -1, C.hull2, "2022 Small Stud")
	-- cannons poking out of ports in the hull side
	for _, z in ipairs({ -3, 1 }) do
		make("Part", "Port", V(0.2, 0.9, 1.1), CFrame.new(sx * 3.52, DECK_Y - 1.1, z), C.iron)
		make("Cylinder", "Cannon", V(1.6, 0.7, 0.7), CFrame.new(sx * 3.9, DECK_Y - 1.1, z), C.iron, "2022 Small Stud")
	end
end
-- ship's wheel on a post on the stern deck
onTop("WheelPost", V(0.5, 1.4, 0.5), 0, STERN_TOP, 4.6, C.hull2, "2022 Small Stud")
make("Cylinder", "ShipWheel", V(0.3, 1.6, 1.6), CFrame.new(0, STERN_TOP + 1.6, 4.4) * CFrame.Angles(0, math.pi / 2, 0), C.hull2, "2022 Small Stud")
for k = 0, 3 do
	make("Part", "Spoke" .. k, V(0.15, 2.2, 0.15), CFrame.new(0, STERN_TOP + 1.6, 4.3) * CFrame.Angles(0, 0, k * math.pi / 4), C.trim)
end

-- MAST through the deck (bottom inside the hull), crow's nest, flag pole from inside the nest
local MAST_H = 15
local mastBottom = DECK_TOP - 1
onTop("Mast", V(0.7, MAST_H, 0.7), 0, mastBottom, -1, C.mast, "2022 Small Stud")
local nestY = mastBottom + MAST_H - 2.5
make("Cylinder", "CrowsNest", V(1.2, 2.4, 2.4), CFrame.new(0, nestY, -1) * CFrame.Angles(0, 0, math.pi / 2), C.hull, "2022 Big Stud")
onTop("FlagPole", V(0.25, 3.5, 0.25), 0, nestY, -1, C.mast, "2022 Small Stud")
local flagTop = nestY + 3.5
onTop("Flag", V(0.15, 1.6, 2.6), 0, flagTop - 1.7, 0.45, C.flag, "2022 Small Stud")
make("Ball", "Skull", V(0.7, 0.7, 0.7), CFrame.new(0, flagTop - 0.9, 0.5), C.skull)
make("Part", "Bones", V(0.12, 0.2, 1.6), CFrame.new(-0.05, flagTop - 1.4, 0.5) * CFrame.Angles(math.rad(30), 0, 0), C.skull)

-- YARD crossing the mast, SAIL hanging from the yard, stripes sunk into the sail, boom at the bottom
local yardY = mastBottom + MAST_H - 4.4
onTop("Yard", V(8, 0.5, 0.5), 0, yardY, -1.5, C.mast, "2022 Small Stud")
local SAIL = V(7.4, 7, 0.25)
onTop("Sail", SAIL, 0, yardY - SAIL.Y, -1.5, C.sail, "2022 Small Stud")
for k = 0, 2 do
	onTop("SailStripe" .. k, V(SAIL.X, 1, 0.3), 0, yardY - SAIL.Y + 0.8 + k * 2.2, -1.5, C.stripe, "2022 Small Stud")
end
onTop("Boom", V(8, 0.5, 0.5), 0, yardY - SAIL.Y - 0.5, -1.5, C.mast, "2022 Small Stud")
-- bowsprit from the bow tip forward and up
bone("Bowsprit", V(0, DECK_TOP, -9.5), V(0, DECK_TOP + 2, -13), 0.4, 0.4, C.mast, "2022 Small Stud")
bone("Rope", V(0, DECK_TOP + 2, -13), V(0, yardY + 0.2, -1.3), 0.12, 0.12, C.hull2)

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
print(string.format("PirateSloop built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
