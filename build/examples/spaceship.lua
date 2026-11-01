--[[
	Starfighter: a sleek white-and-blue space fighter parked on a landing pad with glowing engines.
	Size: about 18 wingspan x 7 tall x 20 long studs. Faces -Z (nose forward).
	SUBJECT TYPE: vehicle (spaceship). CORE-OUT build: the main hull block first, nose wedges on its front face,
	cockpit on its top, wings on its sides, engines on its back face, landing legs from the hull bottom to the pad.
	SIGNATURE FEATURES: a long hull with a pointed wedge nose, a tinted cockpit canopy, swept wings with blue
	stripes and wingtip cannons, twin engines with glowing blue exhausts, tail fins, and a hex landing pad with lights.
	LOOSE-PART RULES SHOWN: all hull parts are offsets from HULL's half sizes; swept wing panels are bone() pieces
	whose root point sits inside the hull side; landing legs run from inside the hull bottom down to the pad top.
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
model.Name = "Starfighter"

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
	pad = "Dark stone grey", pad2 = "Medium stone grey", hull = "Institutional white", hull2 = "Light stone grey",
	stripe = "Bright blue", dark = "Dark stone grey", glass = "Cyan", glow = "Cyan", gun = "Black", padLight = "New Yeller",
}

-- PAD: hex-ish slab from two rotated squares, lights sunk into the top
for i, a in ipairs({ 0, 45 }) do
	onTop("Pad" .. i, V(18, 0.6, 18), 0, 0, 0, i == 1 and C.pad or C.pad2, "2022 Big Stud")
	model:FindFirstChild("Pad" .. i).CFrame = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, math.rad(a), 0)
end
for k = 0, 7 do
	local a = k / 8 * math.pi * 2
	glow(onTop("PadLight" .. k, V(0.6, 0.15, 0.6), math.cos(a) * 8, 0.55, math.sin(a) * 8, C.padLight))
end
local G = 0.6

-- HULL
local HULL = V(3.4, 2.4, 12)
local HX, HY, HZ = HULL.X / 2, HULL.Y / 2, HULL.Z / 2
local LEG_H = 2.2
local hullCF = CFrame.new(0, G + LEG_H + HY, 0)
make("Part", "Hull", HULL, hullCF, C.hull, "2022 Big Stud")
make("Part", "HullSpine", V(1.2, 0.4, 10), hullCF * CFrame.new(0, HY + 0.15, 0.5), C.stripe, "2022 Small Stud")
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "SideStripe", V(0.1, 0.5, 11), hullCF * CFrame.new(sx * (HX + 0.02), 0, 0), C.stripe)
	make("Part", "SidePanel", V(0.15, 1, 3), hullCF * CFrame.new(sx * (HX + 0.05), -0.5, 2.5), C.hull2, "2022 Small Stud")
end

-- NOSE: upper and lower wedges on the front face
make("Wedge", "NoseTop", V(HULL.X, HY, 4), hullCF * CFrame.new(0, HY / 2, -HZ - 2), C.hull, "2022 Big Stud")
make("Wedge", "NoseBottom", V(HULL.X, HY, 4), hullCF * CFrame.new(0, -HY / 2, -HZ - 2) * CFrame.Angles(0, 0, math.pi), C.hull2, "2022 Big Stud")

-- COCKPIT on the hull top
make("Part", "CockpitBase", V(2.4, 0.4, 3.4), hullCF * CFrame.new(0, HY + 0.2, -3), C.dark, "2022 Small Stud")
make("Wedge", "CanopyFront", V(2.2, 1.2, 1.8), hullCF * CFrame.new(0, HY + 1, -4), C.glass)
make("Part", "CanopyTop", V(2.2, 1.2, 1.6), hullCF * CFrame.new(0, HY + 1, -2.3), C.glass)

-- WINGS: two swept panels per side, root inside the hull side, plus tip cannons and stripes
for _, sx in ipairs({ -1, 1 }) do
	local root = hullCF:PointToWorldSpace(V(sx * (HX - 0.3), -0.3, 1))
	local tip = hullCF:PointToWorldSpace(V(sx * (HX + 6.5), -0.6, 4))
	local wcf, wlen = bone("Wing", root, tip, 4, 0.5, C.hull, "2022 Big Stud")
	make("Part", "WingStripe", V(1, 0.55, wlen * 0.8), wcf * CFrame.new(0, 0.02, 0.4), C.stripe, "2022 Small Stud")
	local cannonBase = tip + V(0, 0.1, -1.5)
	bone("TipCannon", cannonBase + V(0, 0, 2.2), cannonBase + V(0, 0, -2.6), 0.5, 0.5, C.gun, "2022 Small Stud")
	glow(make("Part", "CannonTip", V(0.3, 0.3, 0.3), CFrame.new(cannonBase + V(0, 0, -2.75)), C.glow))
	-- tail fin standing on the hull top at the back
	make("Wedge", "TailFin", V(0.3, 2, 2.4), hullCF * CFrame.new(sx * 1, HY + 1, HZ - 1.4), C.hull2, "2022 Big Stud")
end

-- ENGINES on the back face, glowing exhaust rings at their ends
for _, sx in ipairs({ -1, 1 }) do
	local eCF = hullCF * CFrame.new(sx * 1, -0.2, HZ + 1.1) * CFrame.Angles(0, math.pi / 2, 0)
	make("Cylinder", "Engine", V(2.4, 1.8, 1.8), eCF, C.dark, "2022 Big Stud")
	make("Cylinder", "EngineRing", V(0.3, 2, 2), hullCF * CFrame.new(sx * 1, -0.2, HZ + 0.4) * CFrame.Angles(0, math.pi / 2, 0), C.stripe, "2022 Small Stud")
	glow(make("Cylinder", "Exhaust", V(0.2, 1.3, 1.3), hullCF * CFrame.new(sx * 1, -0.2, HZ + 2.35) * CFrame.Angles(0, math.pi / 2, 0), C.glow))
end

-- LANDING LEGS from inside the hull bottom to feet on the pad
for _, lp in ipairs({ { -1.2, -3.5 }, { 1.2, -3.5 }, { -1.4, 3.5 }, { 1.4, 3.5 } }) do
	local top = hullCF:PointToWorldSpace(V(lp[1], -HY + 0.3, lp[2]))
	local foot = V(top.X * 1.3, G + 0.2, top.Z)
	bone("LandingLeg", top, foot + V(0, 0.2, 0), 0.4, 0.4, C.dark, "2022 Small Stud")
	onTop("Foot", V(1, 0.4, 1.2), foot.X, G, foot.Z, C.hull2, "2022 Small Stud")
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
print(string.format("Starfighter built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
