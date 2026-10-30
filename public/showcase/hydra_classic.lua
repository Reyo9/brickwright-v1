-- Three-Headed Hydra Coiled Around Treasure
-- A small retro-brick hydra: a spiral body wrapping a mound of coins and gems, three necks branching widely, each head a different color.
-- Rough size: 24 x 17 x 24 studs. Methods: SKELETON (spiral coil joints, neck chains, head function) + ASSEMBLY (scattered treasure pile).

local model = Instance.new("Model")
model.Name = "HydraOnTreasure"
local count = 0

local function make(name, shape, size, cf, color)
	local p
	if shape == "Wedge" then
		p = Instance.new("WedgePart")
	else
		p = Instance.new("Part")
		if shape == "Ball" then p.Shape = Enum.PartType.Ball
		elseif shape == "Cylinder" then p.Shape = Enum.PartType.Cylinder end
	end
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.BrickColor = BrickColor.new(color)
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Studs
	p.LeftSurface = Enum.SurfaceType.Studs
	p.RightSurface = Enum.SurfaceType.Studs
	p.FrontSurface = Enum.SurfaceType.Studs
	p.BackSurface = Enum.SurfaceType.Studs
	p.Parent = model
	count += 1
	return p
end

local function bone(name, a, b, th, color)
	local len = (b - a).Magnitude
	return make(name, "Part", Vector3.new(th, th, len), CFrame.new((a + b) / 2, b), color)
end

-- LAYOUT
local GROUND = 24
local COIL_TURNS = 2.3
local COIL_SEGS = 30
local R_START, R_END = 8.5, 5.8
local PILE_RADIUS = 4.5
local rng = Random.new(77)

-- ground plate
local ground = make("StonePlate", "Part", Vector3.new(GROUND, 1, GROUND), CFrame.new(0, 0.5, 0), "Dark stone grey")
for i = 1, 4 do
	local a = math.rad(45 + i * 90)
	make("PlateCornerStud", "Part", Vector3.new(2, 1, 2), CFrame.new(math.cos(a) * 11, 1.5, math.sin(a) * 11), "Medium stone grey")
end

-- TREASURE PILE: stepped core hidden under scattered coins and gems
make("PileCoreLow", "Cylinder", Vector3.new(1.5, 9, 9), CFrame.new(0, 1.75, 0) * CFrame.Angles(0, 0, math.rad(90)), "Br. yellowish orange")
make("PileCoreMid", "Cylinder", Vector3.new(1.5, 7, 7), CFrame.new(0, 3.25, 0) * CFrame.Angles(0, 0, math.rad(90)), "Bright yellow")
make("PileCoreTop", "Cylinder", Vector3.new(1.5, 4, 4), CFrame.new(0, 4.75, 0) * CFrame.Angles(0, 0, math.rad(90)), "Br. yellowish orange")
local golds = {"Bright yellow", "Br. yellowish orange", "New Yeller"}
local gems = {"Bright red", "Bright blue", "Lime green", "Bright violet"}
for i = 1, 30 do
	local ang = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(0, 4.2)
	local y = 2 + (1 - r / PILE_RADIUS) * 4.2 + rng:NextNumber(0, 0.6)
	local pos = Vector3.new(math.cos(ang) * r, y, math.sin(ang) * r)
	local tilt = CFrame.Angles(rng:NextNumber(-0.7, 0.7), rng:NextNumber(0, 6.28), rng:NextNumber(-0.7, 0.7))
	if i % 4 == 0 then
		make("Gem", "Part", Vector3.new(1, 1, 1), CFrame.new(pos) * tilt, gems[rng:NextInteger(1, #gems)])
	else
		make("GoldCoin", "Cylinder", Vector3.new(0.5, 2, 2), CFrame.new(pos) * tilt * CFrame.Angles(0, 0, math.rad(90)), golds[rng:NextInteger(1, #golds)])
	end
end
-- goblet crown on top of the pile
make("CrownBand", "Cylinder", Vector3.new(1, 2, 2), CFrame.new(0, 6.7, 0) * CFrame.Angles(0, 0, math.rad(90)), "Bright yellow")
for i = 0, 3 do
	local a = i * math.pi / 2
	make("CrownPoint", "Part", Vector3.new(0.5, 1, 0.5), CFrame.new(math.cos(a) * 0.8, 7.7, math.sin(a) * 0.8), "Bright yellow")
end

-- COILED BODY: spiral joints, tightening and climbing in back half
local J, TH = {}, {}
for i = 0, COIL_SEGS do
	local t = i / COIL_SEGS
	local ang = t * COIL_TURNS * math.pi * 2
	local r = R_START + (R_END - R_START) * t
	local y = 2.5 + math.max(0, t - 0.5) * 2 * 3.5
	J[i] = Vector3.new(math.cos(ang) * r, y, math.sin(ang) * r)
	TH[i] = 1.5 + 1.5 * t
end
for i = 1, COIL_SEGS do
	local col = (i % 2 == 0) and "Earth green" or "Dark green"
	bone("BodySegment", J[i - 1], J[i], TH[i], col)
end
for i = 0, COIL_SEGS do
	make("BodyJointBall", "Ball", Vector3.new(TH[i], TH[i], TH[i]), CFrame.new(J[i]), "Earth green")
	if i % 3 == 0 and i > 0 then
		make("DorsalSpike", "Part", Vector3.new(0.5, 1, 0.5), CFrame.new(J[i] + Vector3.new(0, TH[i] / 2 + 0.5, 0)), "Bright yellow")
	end
end
make("TailTip", "Ball", Vector3.new(1, 1, 1), CFrame.new(J[0] + Vector3.new(0.5, 0, 0)), "Bright yellow")

-- HEAD: built once in local space, facing -Z, placed per neck
local function buildHead(place, s, n)
	local function P(name, shape, size, lcf, color)
		local pos = lcf.Position * s
		return make(name, shape, size * s, place * (CFrame.new(pos) * (lcf - lcf.Position)), color)
	end
	P("Skull", "Part", Vector3.new(3, 2, 3), CFrame.new(0, 0, 0), n.col)
	P("Snout", "Part", Vector3.new(2, 1.5, 2), CFrame.new(0, -0.25, -2.5), n.col)
	P("Brow", "Part", Vector3.new(3, 0.5, 1), CFrame.new(0, 1.25, -1), "Dark green")
	-- open jaw: its own rigid frame hinged under the skull
	local jaw = place * CFrame.new(0, -1 * s, -0.5 * s) * CFrame.Angles(math.rad(-20), 0, 0)
	local function Jw(name, shape, size, lcf, color)
		local pos = lcf.Position * s
		return make(name, shape, size * s, jaw * (CFrame.new(pos) * (lcf - lcf.Position)), color)
	end
	Jw("LowerJaw", "Part", Vector3.new(2, 0.5, 3.5), CFrame.new(0, 0, -1.75), n.col)
	Jw("Tongue", "Part", Vector3.new(0.5, 0.3, 2.5), CFrame.new(0, 0.35, -1.9), "Bright red")
	for _, sx in ipairs({-0.8, 0.8}) do
		Jw("LowerTooth", "Part", Vector3.new(0.3, 0.5, 0.3), CFrame.new(sx, 0.5, -3.2), "Institutional white")
		Jw("LowerTooth", "Part", Vector3.new(0.3, 0.5, 0.3), CFrame.new(sx, 0.5, -2.2), "Institutional white")
		P("UpperFang", "Part", Vector3.new(0.3, 0.7, 0.3), CFrame.new(sx, -1.25, -3.2), "Institutional white")
		P("UpperFang", "Part", Vector3.new(0.3, 0.5, 0.3), CFrame.new(sx, -1.15, -2.2), "Institutional white")
		-- eyes
		local eye = P("Eye", "Part", Vector3.new(0.4, 0.6, 0.6), CFrame.new(sx * 2, 0.4, -0.9), "New Yeller")
		eye.Material = Enum.Material.Neon
		P("Pupil", "Part", Vector3.new(0.2, 0.4, 0.2), CFrame.new(sx * 2.3, 0.4, -1.0), "Really black")
		P("Nostril", "Part", Vector3.new(0.3, 0.3, 0.3), CFrame.new(sx * 0.5, 0.1, -3.5), "Really black")
		P("Horn", "Part", Vector3.new(0.5, 1.5, 0.5), CFrame.new(sx * 1, 1.75, 0.8), n.horn)
		P("HornTip", "Part", Vector3.new(0.5, 0.5, 0.5), CFrame.new(sx * 1, 2.75, 0.5), n.horn)
	end
	local glow = P("EyeGlow", "Part", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, 0.4, 0), "New Yeller")
	glow.Transparency = 1
	glow.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 90)
	light.Range = 8
	light.Parent = glow
	-- back crest sweeping down the neck
	P("Crest", "Wedge", Vector3.new(0.5, 1.5, 2.5), CFrame.new(0, 1.75, 0.8), "Bright yellow")
	-- per-head individuality
	if n.extra == "scar" then
		P("CheekScar", "Part", Vector3.new(0.2, 0.2, 1.5), CFrame.new(1.55, -0.3, 0) * CFrame.Angles(0, 0, math.rad(35)), "Really black")
		P("CheekScar", "Part", Vector3.new(0.2, 0.5, 0.2), CFrame.new(1.55, -0.3, -0.4), "Bright red")
	elseif n.extra == "spikes" then
		for _, sx in ipairs({-1, 1}) do
			P("CheekSpike", "Wedge", Vector3.new(0.5, 1, 1.5), CFrame.new(sx * 2, -0.5, 0.5) * CFrame.Angles(0, 0, math.rad(sx * 90)), "Bright yellow")
		end
	else
		P("NoseHorn", "Part", Vector3.new(0.5, 1, 0.5), CFrame.new(0, 0.75, -3.0), n.horn)
		P("BrowStud", "Part", Vector3.new(1, 0.5, 0.5), CFrame.new(0, 1.75, -1.3), "Bright red")
	end
end

-- THREE NECKS from the body's last joint, widely spread from the start
local B = J[COIL_SEGS]
local inward = Vector3.new(-B.X, 0, -B.Z).Unit
local necks = {
	{yaw = -60, rise = 7, th = 3, col = "Bright green", horn = "Institutional white", extra = "scar", s = 1},
	{yaw = 15, rise = 9, th = 3, col = "Bright blue", horn = "Bright yellow", extra = "spikes", s = 1.2},
	{yaw = 90, rise = 6.5, th = 3, col = "Bright violet", horn = "Light stone grey", extra = "horn", s = 1},
}
for _, n in ipairs(necks) do
	local h = CFrame.Angles(0, math.rad(n.yaw), 0) * inward
	local side = Vector3.new(0, 1, 0):Cross(h).Unit
	local j1 = B + h * 1 + side * 0.5 + Vector3.new(0, n.rise * 0.45, 0)
	local j2 = j1 + h * 2.5 + Vector3.new(0, n.rise * 0.4, 0)
	local j3 = j2 + h * 2.5 + Vector3.new(0, n.rise * 0.15, 0)
	local pts = {B, j1, j2, j3}
	local widths = {3, 2.5, 2, 2}
	for i = 2, 4 do
		bone("Neck", pts[i - 1], pts[i], widths[i], n.col)
	end
	for i = 2, 4 do
		make("NeckJointBall", "Ball", Vector3.new(widths[i], widths[i], widths[i]), CFrame.new(pts[i]), n.col)
	end
	-- belly scales along the neck front
	for i = 2, 4 do
		make("NeckScaleBand", "Part", Vector3.new(1, 0.5, 1), CFrame.new(pts[i] + Vector3.new(0, widths[i] / 2 + 0.25, 0)), "Bright yellow")
	end
	local facing = (h + inward) * 0.5 - Vector3.new(0, 0.35, 0)
	local place = CFrame.lookAt(j3 + h * 0.5, j3 + h * 0.5 + facing)
	buildHead(place, n.s, n)
end

model.PrimaryPart = ground
model.Parent = workspace
print("Hydra on treasure built: " .. count .. " parts, roughly 24 x 17 x 24 studs")