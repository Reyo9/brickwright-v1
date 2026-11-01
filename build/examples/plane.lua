--[[
	Propeller Plane: a red and white single-engine aircraft parked on a runway pad, landing gear down.
	Size: about 22 wingspan x 7 tall x 18 long studs. Faces -Z (nose forward).
	SUBJECT TYPE: vehicle (aircraft). GEAR-UP build: wheels on the ground, struts on the wheels, fuselage on the struts,
	wings and tail attached to the fuselage sides.
	SIGNATURE FEATURES: rounded fuselage with a white stripe, low wings with red tips and yellow lights, a glass cockpit canopy,
	a chrome spinner with a 3-blade propeller, a tall tail fin with a number, tail wings and a black-and-white runway pad.
	LOOSE-PART RULES SHOWN: struts run from the wheel axle INTO the fuselage bottom; wings overlap the fuselage sides by 0.5;
	propeller blades start inside the spinner.
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
model.Name = "PropPlane"

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
	body = "Bright red", body2 = "Dark red", white = "White", glass = "Light blue", chrome = "Light stone grey",
	tyre = "Black", strut = "Dark stone grey", light = "New Yeller", pad = "Dark stone grey", line = "White", prop = "Black",
}

onTop("RunwayPad", V(26, 0.4, 22), 0, 0, 0, C.pad, "2022 Big Stud")
for k = -2, 2 do onTop("RunwayLine", V(0.8, 0.1, 3), 0, 0.35, k * 4.4, C.line, "2022 Small Stud") end
local G = 0.4

-- LANDING GEAR: tyres on the pad; FUSE_BOTTOM is defined so the struts reach it
local WD, FUSE_BOTTOM = 1.8, 3.2
local gear = { { -2.6, -2.5 }, { 2.6, -2.5 } }
for _, g in ipairs(gear) do
	local axle = V(g[1], G + WD / 2, g[2])
	make("Cylinder", "Tyre", V(0.7, WD, WD), CFrame.new(axle), C.tyre, "2022 Small Stud")
	make("Cylinder", "Hub", V(0.8, 0.8, 0.8), CFrame.new(axle), C.chrome)
	bone("Strut", axle, V(g[1] * 0.5, FUSE_BOTTOM + 0.6, g[2]), 0.4, 0.4, C.strut, "2022 Small Stud")
end
local tailWheel = V(0, G + 0.45, 7.5)
make("Cylinder", "TailWheel", V(0.4, 0.9, 0.9), CFrame.new(tailWheel), C.tyre)
bone("TailStrut", tailWheel, V(0, FUSE_BOTTOM + 0.8, 7), 0.3, 0.3, C.strut, "2022 Small Stud")

-- FUSELAGE: a long box with rounded top, tapering tail cone, white stripe on both sides
local FUSE = V(3, 2.8, 12)
local FUSE_Y = FUSE_BOTTOM + FUSE.Y / 2
make("Part", "Fuselage", FUSE, CFrame.new(0, FUSE_Y, -1), C.body, "2022 Big Stud")
make("Cylinder", "FuseRoof", V(12, 3, 3), CFrame.new(0, FUSE_Y + 0.4, -1) * CFrame.Angles(0, math.pi / 2, 0), C.body, "2022 Big Stud")
bone("TailCone", V(0, FUSE_Y + 0.2, 4.8), V(0, FUSE_Y + 0.6, 9), 2, 1.6, C.body, "2022 Big Stud")
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "Stripe", V(0.1, 0.5, 11.6), CFrame.new(sx * 1.53, FUSE_Y - 0.2, -1), C.white, "2022 Small Stud")
end

-- NOSE: engine cowl at the front face, spinner on the cowl, blades out of the spinner
local noseZ = -1 - FUSE.Z / 2
make("Cylinder", "Cowl", V(1.6, 3, 3), CFrame.new(0, FUSE_Y, noseZ - 0.7) * CFrame.Angles(0, math.pi / 2, 0), C.white, "2022 Big Stud")
make("Ball", "Spinner", V(1.4, 1.4, 1.4), CFrame.new(0, FUSE_Y, noseZ - 1.6), C.chrome)
for k = 0, 2 do
	local a = k / 3 * math.pi * 2
	make("Part", "Blade" .. k, V(0.5, 3.2, 0.15), CFrame.new(0, FUSE_Y, noseZ - 1.9) * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.6, 0), C.prop, "2022 Small Stud")
end

-- COCKPIT canopy on the roof
make("Part", "CanopyBase", V(2.2, 0.3, 3.4), CFrame.new(0, FUSE_Y + 1.85, -2.5), C.body2, "2022 Small Stud")
make("Ball", "Canopy", V(2.2, 2.2, 2.2), CFrame.new(0, FUSE_Y + 2, -2.5), C.glass)
make("Wedge", "Windshield", V(2, 1, 1.4), CFrame.new(0, FUSE_Y + 2.3, -4.2), C.glass)

-- WINGS: overlap the fuselage sides by 0.5, red tips touch the wing ends, lights sunk into the tips
local WING = V(9, 0.5, 3.6)
for _, sx in ipairs({ -1, 1 }) do
	local wx = sx * (FUSE.X / 2 + WING.X / 2 - 0.5)
	make("Part", "Wing", WING, CFrame.new(wx, FUSE_BOTTOM + 0.5, -2) * CFrame.Angles(0, 0, sx * math.rad(4)), C.white, "2022 Big Stud")
	local tipX = sx * (FUSE.X / 2 + WING.X - 0.5)
	make("Part", "WingTip", V(1.4, 0.55, 3.6), CFrame.new(tipX - sx * 0.6, FUSE_BOTTOM + 0.5 + 0.32, -2), C.body, "2022 Big Stud")
	glow(make("Part", "NavLight", V(0.3, 0.3, 0.5), CFrame.new(tipX + sx * 0.05, FUSE_BOTTOM + 0.82, -3.2), C.light))
	make("Part", "Aileron", V(4, 0.3, 0.6), CFrame.new(wx + sx * 1.5, FUSE_BOTTOM + 0.5 + sx * 0.15, -0.1), C.body2, "2022 Small Stud")
end

-- TAIL: fin and stabilisers overlapping the tail cone
make("Wedge", "TailFin", V(0.4, 3.4, 3), CFrame.new(0, FUSE_Y + 2.6, 8) * CFrame.Angles(0, math.pi, 0), C.body, "2022 Big Stud")
make("Part", "FinNumber", V(0.5, 0.8, 1), CFrame.new(0, FUSE_Y + 2.2, 8.5), C.white)
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "Stabilizer", V(3.4, 0.35, 1.8), CFrame.new(sx * 2, FUSE_Y + 0.6, 8.4), C.white, "2022 Big Stud")
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
print(string.format("PropPlane built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
