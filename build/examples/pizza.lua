--[[
	Pizza in an open takeaway box: a cardboard box with its lid standing open at the back, a whole pizza inside and one loose slice in the front-right corner.
	Size: about 22 x 26 x 22 studs (W x H x D). Faces -Z, so the open box front points at the viewer and the lid stands at the back (+Z).
	SUBJECT TYPE: prop scene (food arrangement on a base). The box is the base, the pizza is the hero and the slice is the supporting cast.
	SIGNATURE FEATURES: a reddish brown box with an upright open lid, a pale nougat lining and a printed lid logo,
	a round pizza with a brown crust, an orange cheese disc and a ring of red pepperoni, green pepper and olive flecks,
	and a loose triangular slice.
	A second printed pizza logo sits on the outside of the lid, so the back of the box reads too.
	Must be run from the Studio command bar, because game:GetObjects is Studio-only.
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
	box = "Reddish brown",
	liner = "Nougat",
	crust = "Brown",
	cheese = "Bright orange",
	sauce = "Dark orange",
	pepperoni = "Bright red",
	pepper = "Bright green",
	olive = "Really black",
}

-- LAYOUT
local W, D = 22, 22                -- box footprint
local FLOOR_T = 1                  -- box floor thickness
local WALL_T = 1                   -- box wall thickness
local BOX_H = 4                    -- top of the box walls
local LINER_T = 0.2                -- inner cardboard liner
local LINER_TOP = FLOOR_T + LINER_T
local LID_L = D                    -- lid length, now standing upright
local FLAP = 2                     -- depth of the lid rim flaps
local PIZZA_X, PIZZA_Z = -1.5, 1.5 -- pizza centre, nudged back-left
local CRUST_D, CRUST_T = 16, 1.2
local SAUCE_D, SAUCE_T = 15, 0.3
local CHEESE_D, CHEESE_T = 14, 0.4
local CRUST_TOP = LINER_TOP + CRUST_T
local CHEESE_Y = CRUST_TOP + CHEESE_T / 2 - 0.1
local CHEESE_TOP = CHEESE_Y + CHEESE_T / 2
local PEP_D, PEP_T, PEP_COUNT, PEP_R = 2, 0.2, 7, 4.6
local OLIVE_D, OLIVE_COUNT, OLIVE_R = 0.8, 6, 2.6
local PEPPER_COUNT, PEPPER_R = 6, 6
local SLICE_X, SLICE_Z = 6, -6     -- loose slice in the front-right corner
local SLICE_L, SLICE_W, SLICE_T = 4.5, 3.6, 0.6
local SLICE_YAW = 135              -- tip points back toward the pizza
local BACK_LOGO_Y = 3              -- back logo height above the lid centre
local BACK_PANEL = 10              -- nougat print panel behind the back logo
local BACK_CRUST_D, BACK_CHEESE_D = 8, 6.6
local BACK_PEP_D, BACK_PEP_R, BACK_PEP_COUNT = 1.2, 2, 4

local model = Instance.new("Model")
model.Name = "PizzaBox"

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

-- A flat disc lying on the ground plane: a cylinder turned so its axis is Y.
local function disc(name, cf, t, d, colour, variant)
	return make("Cylinder", name, Vector3.new(t, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), colour, variant)
end

-- A flat disc printed on an upright face: a cylinder turned so its axis is Z.
local function faceDisc(name, cf, t, d, colour, variant)
	return make("Cylinder", name, Vector3.new(t, d, d), cf * CFrame.Angles(0, math.rad(90), 0), colour, variant)
end

-- BOX BASE
local floor = make("Part", "BoxFloor", Vector3.new(W, FLOOR_T, D), CFrame.new(0, FLOOR_T / 2, 0), C.box, "2022 Small Stud")
local wallH = BOX_H - FLOOR_T
for _, sz in ipairs({ -1, 1 }) do
	make("Part", "BoxWallFB", Vector3.new(W, wallH, WALL_T),
		CFrame.new(0, FLOOR_T + wallH / 2, sz * (D / 2 - WALL_T / 2)), C.box, "2022 Small Stud")
end
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "BoxWallSide", Vector3.new(WALL_T, wallH, D - 2 * WALL_T),
		CFrame.new(sx * (W / 2 - WALL_T / 2), FLOOR_T + wallH / 2, 0), C.box, "2022 Small Stud")
end
make("Part", "Liner", Vector3.new(W - 2 * WALL_T, LINER_T, D - 2 * WALL_T),
	CFrame.new(0, FLOOR_T + LINER_T / 2, 0), C.liner, "2022 Universal")

-- FRONT LABEL
make("Part", "FrontLabel", Vector3.new(6, 1.6, 0.2), CFrame.new(0, FLOOR_T + wallH / 2, -D / 2 - 0.1), C.liner, "2022 Big Stud")
make("Part", "FrontStripe", Vector3.new(4, 1, 0.2), CFrame.new(0, FLOOR_T + wallH / 2, -D / 2 - 0.3), C.pepperoni, "2022 Small Stud")

-- LID, standing open on the back wall
local lidCF = CFrame.new(0, BOX_H + LID_L / 2, D / 2 - WALL_T / 2)
make("Part", "Lid", Vector3.new(W, LID_L, WALL_T), lidCF, C.box, "2022 Small Stud")
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "LidFlapSide", Vector3.new(WALL_T, LID_L, FLAP),
		lidCF * CFrame.new(sx * (W / 2 - WALL_T / 2), 0, -(WALL_T / 2 + FLAP / 2)), C.box, "2022 Universal")
end
make("Part", "LidFlapTop", Vector3.new(W - 2 * WALL_T, WALL_T, FLAP),
	lidCF * CFrame.new(0, LID_L / 2 - WALL_T / 2, -(WALL_T / 2 + FLAP / 2)), C.box, "2022 Universal")
local lidInner = make("Part", "LidLiner", Vector3.new(W - 2 * WALL_T, LID_L - 2, 0.2),
	lidCF * CFrame.new(0, 0, -(WALL_T / 2 + 0.1)), C.liner, "2022 Universal")

-- LID LOGO: a red pizza disc with a nougat wedge cut-out, plus lettering bars
local logoCF = lidInner.CFrame * CFrame.new(0, 3, -0.2)
make("Cylinder", "LogoDisc", Vector3.new(0.2, 8, 8), logoCF * CFrame.Angles(0, math.rad(90), 0), C.pepperoni, "2022 Big Stud")
make("Wedge", "LogoSlice", Vector3.new(0.2, 3, 3), logoCF * CFrame.new(1.2, 1.2, -0.2) * CFrame.Angles(0, math.rad(90), 0), C.liner, "2022 Small Stud")
for i = 1, 2 do
	make("Part", "LogoText", Vector3.new(10 - i * 2, 1, 0.2),
		lidInner.CFrame * CFrame.new(0, -3 - i * 2, -0.2), C.pepperoni, "2022 Small Stud")
end

-- BACK LOGO: printed on the outside of the lid, facing +Z.
-- A nougat print panel, a brown crust disc, an orange cheese disc, red pepperoni dots,
-- a nougat wedge where a slice has been taken, and two lettering bars underneath.
local backCF = lidCF * CFrame.new(0, 0, WALL_T / 2)
local backLogoCF = backCF * CFrame.new(0, BACK_LOGO_Y, 0)
make("Part", "BackPanel", Vector3.new(BACK_PANEL, BACK_PANEL + 6, 0.2),
	backCF * CFrame.new(0, BACK_LOGO_Y - 3, 0.1), C.liner, "2022 Big Stud")
faceDisc("BackLogoCrust", backLogoCF * CFrame.new(0, 0, 0.3), 0.2, BACK_CRUST_D, C.crust, "2022 Weld")
faceDisc("BackLogoCheese", backLogoCF * CFrame.new(0, 0, 0.5), 0.2, BACK_CHEESE_D, C.cheese, "2022 Big Stud")
faceDisc("BackLogoPepperoni", backLogoCF * CFrame.new(0, 0, 0.7), 0.2, BACK_PEP_D, C.pepperoni, "2022 Weld")
for i = 1, BACK_PEP_COUNT do
	local a = (i - 0.5) / BACK_PEP_COUNT * math.pi * 2 + math.rad(90)
	faceDisc("BackLogoPepperoni", backLogoCF * CFrame.new(math.cos(a) * BACK_PEP_R, math.sin(a) * BACK_PEP_R, 0.7),
		0.2, BACK_PEP_D, C.pepperoni, "2022 Weld")
end
make("Wedge", "BackLogoSlice", Vector3.new(0.2, 3, 3),
	backLogoCF * CFrame.new(-1.6, 1.6, 0.9) * CFrame.Angles(0, math.rad(-90), 0), C.liner, "2022 Small Stud")
for i = 1, 2 do
	make("Part", "BackLogoText", Vector3.new(10 - i * 2, 1, 0.2),
		backCF * CFrame.new(0, BACK_LOGO_Y - 4 - i * 2, 0.3), C.pepperoni, "2022 Small Stud")
end

-- PIZZA (hero)
local pizzaBase = CFrame.new(PIZZA_X, 0, PIZZA_Z)
disc("Crust", pizzaBase * CFrame.new(0, LINER_TOP + CRUST_T / 2, 0), CRUST_T, CRUST_D, C.crust, "2022 Weld")
disc("Sauce", pizzaBase * CFrame.new(0, CRUST_TOP - SAUCE_T / 2 + 0.15, 0), SAUCE_T, SAUCE_D, C.sauce, "2022 Universal")
disc("Cheese", pizzaBase * CFrame.new(0, CHEESE_Y, 0), CHEESE_T, CHEESE_D, C.cheese, "2022 Big Stud")

local topY = CHEESE_TOP + PEP_T / 2 - 0.02
-- pepperoni ring plus one in the middle
disc("Pepperoni", pizzaBase * CFrame.new(0, topY, 0), PEP_T, PEP_D, C.pepperoni, "2022 Weld")
for i = 1, PEP_COUNT do
	local a = (i - 1) / PEP_COUNT * math.pi * 2
	disc("Pepperoni", pizzaBase * CFrame.new(math.cos(a) * PEP_R, topY, math.sin(a) * PEP_R), PEP_T, PEP_D, C.pepperoni, "2022 Weld")
end
-- olives between the rings
for i = 1, OLIVE_COUNT do
	local a = (i - 0.5) / OLIVE_COUNT * math.pi * 2
	disc("Olive", pizzaBase * CFrame.new(math.cos(a) * OLIVE_R, CHEESE_TOP + 0.13, math.sin(a) * OLIVE_R), 0.3, OLIVE_D, C.olive, "2022 Small Stud")
end
-- green pepper strips near the edge
for i = 1, PEPPER_COUNT do
	local a = (i - 0.25) / PEPPER_COUNT * math.pi * 2
	make("Part", "Pepper", Vector3.new(1.2, 0.2, 0.4),
		pizzaBase * CFrame.new(math.cos(a) * PEPPER_R, CHEESE_TOP + 0.08, math.sin(a) * PEPPER_R) * CFrame.Angles(0, -a + math.rad(45), 0),
		C.pepper, "2022 Small Stud")
end

-- LOOSE SLICE: two mirrored wedges laid flat form the triangle, crust bar at the wide end
local sliceCF = CFrame.new(SLICE_X, LINER_TOP + SLICE_T / 2, SLICE_Z) * CFrame.Angles(0, math.rad(SLICE_YAW), 0)
for _, sx in ipairs({ -1, 1 }) do
	make("Wedge", "SliceCheese", Vector3.new(SLICE_T, SLICE_W / 2, SLICE_L),
		sliceCF * CFrame.new(sx * SLICE_W / 4, 0, 0) * CFrame.Angles(0, 0, math.rad(-90 * sx)), C.cheese, "2022 Big Stud")
end
make("Part", "SliceCrust", Vector3.new(SLICE_W, 1, 1),
	sliceCF * CFrame.new(0, 0.5 - SLICE_T / 2, SLICE_L / 2 + 0.5), C.crust, "2022 Weld")
local sTop = SLICE_T / 2 + PEP_T / 2 - 0.02
disc("SlicePepperoni", sliceCF * CFrame.new(0, sTop, 0.8), PEP_T, 1.4, C.pepperoni, "2022 Weld")
disc("SliceOlive", sliceCF * CFrame.new(0, SLICE_T / 2 + 0.13, -0.8), 0.3, OLIVE_D, C.olive, "2022 Small Stud")
make("Part", "SlicePepper", Vector3.new(1.2, 0.2, 0.4),
	sliceCF * CFrame.new(0.6, SLICE_T / 2 + 0.08, 1.6) * CFrame.Angles(0, math.rad(45), 0), C.pepper, "2022 Small Stud")

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

model.PrimaryPart = floor
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
local _, size = model:GetBoundingBox()
print(("PizzaBox built: %d parts, %.1f x %.1f x %.1f studs"):format(#model:GetChildren(), size.X, size.Y, size.Z))
