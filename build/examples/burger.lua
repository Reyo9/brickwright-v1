--[[
	Mega Burger Meal: a stacked double cheeseburger on a tray with fries and a soda.
	Size: about 14 x 10 x 10 studs. Faces -Z.
	SUBJECT TYPE: food prop scene. STACKING build: every layer's yBottom = previous layer's top, so nothing floats.
	SIGNATURE FEATURES: a domed sesame bun, two patties, melted cheese corners drooping over the edge,
	lettuce frills, tomato slices, a red fry box with fries poking out and a striped soda cup with a straw.
	LOOSE-PART RULES SHOWN: one running variable y for the stack; sesame seeds, drips and fries sink 0.05-0.3 into what holds them.
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
model.Name = "MegaBurger"

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
	tray = "Bright red", trayPaper = "Pastel yellow", bun = "Bright orange", bunTop = "Dark orange", seed = "Pastel yellow",
	patty = "Reddish brown", patty2 = "Brown", cheese = "New Yeller", lettuce = "Lime green", tomato = "Bright red",
	box = "Bright red", fry = "Bright yellow", cup = "White", stripe = "Bright red", lid = "White", straw = "Bright blue",
}

-- TRAY on the ground, paper sheet on the tray
onTop("Tray", V(14, 0.5, 10), 0, 0, 0, C.tray, "2022 Big Stud")
onTop("Paper", V(8, 0.1, 7), -1.8, 0.5 - 0.05, 0, C.trayPaper, "2022 Small Stud")
local TRAY_TOP = 0.55

-- BURGER STACK (centre x = -2)
local bx, R = -2, 6
local y = TRAY_TOP
local function disc(name, h, d, colour, variant)
	make("Cylinder", name, V(h, d, d), CFrame.new(bx, y + h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), colour, variant)
	y = y + h
end
disc("BottomBun", 1, R, C.bun, "2022 Big Stud")
disc("Patty1", 0.9, R + 0.3, C.patty, "2022 Big Stud")
-- cheese square: corners droop over the patty edge (drips touch the cheese)
onTop("Cheese1", V(5.6, 0.2, 5.6), bx, y, 0, C.cheese, "2022 Small Stud")
for i, c in ipairs({ { 1, 1 }, { -1, -1 } }) do
	make("Wedge", "CheeseDrip" .. i, V(0.2, 1, 1.2), CFrame.new(bx + c[1] * 2.6, y - 0.4, c[2] * 2.6) * CFrame.Angles(0, math.rad(45 + i * 180), math.pi), C.cheese, "2022 Small Stud")
end
y = y + 0.2
disc("Patty2", 0.9, R + 0.3, C.patty2, "2022 Big Stud")
onTop("Cheese2", V(5.6, 0.2, 5.6), bx, y, 0, C.cheese, "2022 Small Stud")
y = y + 0.2
-- lettuce frill: a disc a bit wider, plus wavy tabs that touch its rim
disc("Lettuce", 0.3, R + 1, C.lettuce, "2022 Small Stud")
for k = 0, 7 do
	local a = k / 8 * math.pi * 2
	onTop("LettuceTab" .. k, V(1.2, 0.3, 0.6), bx + math.cos(a) * 3.3, y - 0.45, math.sin(a) * 3.3, C.lettuce, "2022 Small Stud")
end
-- two tomato slices side by side on the lettuce
for i, dz in ipairs({ -1.3, 1.3 }) do
	make("Cylinder", "Tomato" .. i, V(0.3, 2.8, 2.8), CFrame.new(bx, y + 0.15, dz) * CFrame.Angles(0, 0, math.pi / 2), C.tomato, "2022 Small Stud")
end
y = y + 0.3
-- top bun: flat lower half + dome, seeds sunk into the dome
disc("TopBunBase", 0.8, R, C.bun, "2022 Big Stud")
-- dome from three shrinking discs (a Ball part is always a perfect sphere in Roblox, so it can't be squashed)
disc("TopBunDome1", 0.7, R - 0.4, C.bunTop, "2022 Big Stud")
disc("TopBunDome2", 0.5, R - 1.6, C.bunTop, "2022 Big Stud")
disc("TopBunDome3", 0.35, R - 3, C.bunTop, "2022 Big Stud")
-- seeds sunk 0.05 into the top face of each dome step
local seeds = { { 0, 3, 0 }, { 0.8, 2, 1 }, { -1, 2, 0.6 }, { 0.6, 2, -1.1 }, { 2.2, 1, 0.8 }, { -2.2, 1, -0.6 }, { 0.4, 1, 2.3 }, { -0.6, 1, -2.3 } }
local stepTop = { y - 0.35 - 0.5, y - 0.35, y }
for i, sd in ipairs(seeds) do
	onTop("Seed" .. i, V(0.4, 0.2, 0.25), bx + sd[1], stepTop[sd[2]] - 0.05, sd[3], C.seed, "2022 Small Stud")
end

-- FRIES BOX (x = 4, z = -2): box on the tray, fries sunk 1 stud into the box
local fx, fz = 4, -2
onTop("FryBox", V(2.6, 3, 1.8), fx, TRAY_TOP, fz, C.box, "2022 Big Stud")
onTop("FryLogo", V(1, 1, 0.1), fx, TRAY_TOP + 1.2, fz - 0.92, C.cheese, "2022 Small Stud")
for k = 0, 8 do
	local ox = -0.9 + (k % 5) * 0.45
	local oz = k < 5 and -0.3 or 0.35
	local h = 2.2 + (k * 37 % 5) * 0.25
	local tilt = math.rad(((k * 53) % 21) - 10)
	make("Part", "Fry" .. k, V(0.35, h, 0.35), CFrame.new(fx + ox, TRAY_TOP + 3 - 1 + h / 2, fz + oz) * CFrame.Angles(tilt * 0.5, 0, tilt), C.fry, "2022 Small Stud")
end

-- SODA CUP (x = 4.2, z = 2.4): cup, stripe ring, lid, straw through the lid
local cx, cz = 4.2, 2.4
make("Cylinder", "Cup", V(4, 2.4, 2.4), CFrame.new(cx, TRAY_TOP + 2, cz) * CFrame.Angles(0, 0, math.pi / 2), C.cup, "2022 Big Stud")
make("Cylinder", "CupStripe", V(0.8, 2.5, 2.5), CFrame.new(cx, TRAY_TOP + 2.2, cz) * CFrame.Angles(0, 0, math.pi / 2), C.stripe, "2022 Small Stud")
make("Cylinder", "Lid", V(0.4, 2.6, 2.6), CFrame.new(cx, TRAY_TOP + 4.2, cz) * CFrame.Angles(0, 0, math.pi / 2), C.lid, "2022 Small Stud")
bone("Straw", V(cx, TRAY_TOP + 3.5, cz), V(cx + 0.6, TRAY_TOP + 6.5, cz + 0.4), 0.3, 0.3, C.straw, "2022 Small Stud")

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
print(string.format("MegaBurger built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
