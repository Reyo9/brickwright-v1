--[[
	Giant Beanstalk - a blocky, tapering stalk climbing about 32 studs high,
	with leaves angled upward on both sides and pea pods hanging below two of them.
	Size: about 16 wide x 32 tall x 8 deep (studs). Front faces -Z.
	SUBJECT TYPE: nature (a single plant, naturalistic treatment).
	SIGNATURE FEATURES: a thick stepped stalk that tapers and bows as it rises;
	long leaf blades angled upward and alternating left and right; dangling
	bead-chain pea pods; a big flared leaf and roots at the base; a darker crown.
	Run this from the Studio command bar: game:GetObjects only works in Studio.
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
	stalk = Color3.fromRGB(39, 70, 45),
	stalkAlt = Color3.fromRGB(46, 82, 50),
	ridge = Color3.fromRGB(58, 98, 58),
	crown = Color3.fromRGB(40, 127, 71),
	crownAlt = Color3.fromRGB(34, 110, 62),
	leaf = Color3.fromRGB(75, 151, 75),
	leafDark = Color3.fromRGB(62, 130, 64),
	rib = Color3.fromRGB(104, 172, 92),
	pod = Color3.fromRGB(86, 150, 74),
	podCap = Color3.fromRGB(44, 92, 52),
	root = Color3.fromRGB(52, 66, 42),
}

-- LAYOUT
local HEIGHT = 32
local SEGS = 10
local SEG_H = HEIGHT / SEGS
local BASE_W, TOP_W = 5, 2.4
local DEPTH_RATIO = 0.9
local LEAN, BOW = 3, -1.5
local CROWN_T = 0.7
local LEAF_T, LEAF_W = 1, 1.6
local TIP_L = 2
local POD_BALLS, POD_D = 4, 0.9
local ROOT_L, ROOT_H = 3, 1
-- t = height fraction, side = -1 left / 1 right, len, tilt (deg), yaw (deg), pod
local LEAVES = {
	{ t = 0.10, side = 1, len = 6, tilt = 20, yaw = 15, pod = false },
	{ t = 0.24, side = -1, len = 7, tilt = 35, yaw = -10, pod = false },
	{ t = 0.36, side = -1, len = 6, tilt = 30, yaw = 20, pod = true },
	{ t = 0.48, side = -1, len = 6, tilt = 40, yaw = -15, pod = false },
	{ t = 0.58, side = -1, len = 5.5, tilt = 30, yaw = 10, pod = false },
	{ t = 0.66, side = -1, len = 5, tilt = 40, yaw = -20, pod = false },
	{ t = 0.72, side = 1, len = 4.5, tilt = 35, yaw = 15, pod = true },
	{ t = 0.84, side = 1, len = 4, tilt = 40, yaw = -10, pod = false },
	{ t = 0.92, side = -1, len = 4, tilt = 45, yaw = 10, pod = false },
	{ t = 0.97, side = 1, len = 3.5, tilt = 50, yaw = -15, pod = false },
}

local model = Instance.new("Model")
model.Name = "Beanstalk"

local function paint(p, colour, variant)
	p.Color = colour
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

local function stalkX(t)
	return LEAN * t + BOW * math.sin(t * math.pi)
end

local function stalkW(t)
	return BASE_W + (TOP_W - BASE_W) * t
end

-- STALK: stepped tapering segments with a lighter front ridge
local first
for i = 0, SEGS - 1 do
	local t = i / SEGS
	local w = stalkW(t)
	local d = w * DEPTH_RATIO
	local col = C.stalk
	if i % 2 == 1 then col = C.stalkAlt end
	if t >= CROWN_T then
		col = C.crown
		if i % 2 == 1 then col = C.crownAlt end
	end
	local cf = CFrame.new(stalkX(t), i * SEG_H + SEG_H / 2, 0)
	local seg = make("Part", "Stalk" .. i, Vector3.new(w, SEG_H, d), cf, col, "2022 Small Stud")
	if not first then first = seg end
	make("Part", "Ridge" .. i, Vector3.new(w * 0.4, SEG_H - 0.4, 0.2),
		cf * CFrame.new(w * 0.15, 0, -d / 2 - 0.1), C.ridge, "2022 Small Stud")
end

-- CROWN: a tapering bud on the top
local topX = stalkX(1)
make("Part", "CrownBud", Vector3.new(TOP_W - 0.6, 1.4, TOP_W * DEPTH_RATIO - 0.6),
	CFrame.new(topX, HEIGHT + 0.7, 0), C.crown, "2022 Small Stud")
make("Part", "CrownTip", Vector3.new(1, 1, 1),
	CFrame.new(topX, HEIGHT + 1.9, 0) * CFrame.Angles(0, math.rad(45), 0), C.crownAlt, "2022 Small Stud")

-- ROOTS: flared blocks around the base
for k, a in ipairs({ 30, 150, 260 }) do
	local r = math.rad(a)
	local rx = math.cos(r) * (BASE_W / 2 + ROOT_L / 2 - 1)
	local rz = math.sin(r) * (BASE_W * DEPTH_RATIO / 2 + ROOT_L / 2 - 1)
	make("Part", "Root" .. k, Vector3.new(ROOT_L, ROOT_H, 1.6),
		CFrame.new(rx, ROOT_H / 2, rz) * CFrame.Angles(0, -r, 0), C.root, "2022 Universal")
end

-- BASE LEAF: big flared blade low on the right
local baseLeafCf = CFrame.new(BASE_W / 2 + 1, 2, -1) * CFrame.Angles(0, math.rad(30), 0)
make("Wedge", "BaseLeaf", Vector3.new(1, 3, 4),
	baseLeafCf * CFrame.new(1, 0.5, -1) * CFrame.Angles(0, math.rad(-90), 0), C.leafDark, "2022 Universal")

-- LEAVES: blades angled up, with a tip and a mid rib
for k, L in ipairs(LEAVES) do
	local w = stalkW(L.t)
	local base = Vector3.new(stalkX(L.t) + L.side * (w / 2 - 0.3), L.t * HEIGHT, 0)
	local lcf = CFrame.new(base) * CFrame.Angles(0, math.rad(L.yaw), 0)
		* CFrame.Angles(0, 0, L.side * math.rad(L.tilt)) * CFrame.new(L.side * L.len / 2, 0, 0)
	local col = C.leaf
	if L.t >= CROWN_T then col = C.crown end
	make("Part", "Leaf" .. k, Vector3.new(L.len, LEAF_T, LEAF_W), lcf, col, "2022 Universal")
	make("Part", "LeafTip" .. k, Vector3.new(TIP_L, LEAF_T - 0.2, LEAF_W - 0.4),
		lcf * CFrame.new(L.side * (L.len / 2 + TIP_L / 2 - 0.2), 0, 0) * CFrame.Angles(0, 0, L.side * math.rad(10)),
		C.leafDark, "2022 Small Stud")
	make("Part", "LeafRib" .. k, Vector3.new(L.len * 0.8, 0.2, 0.4),
		lcf * CFrame.new(0, LEAF_T / 2 + 0.1, 0), C.rib, "2022 Small Stud")
	-- PEA POD: a bead chain hanging under the leaf
	if L.pod then
		local hang = (lcf * CFrame.new(L.side * L.len * 0.25, -LEAF_T / 2, 0)).Position
		make("Part", "PodCap" .. k, Vector3.new(0.8, 0.6, 0.8),
			CFrame.new(hang - Vector3.new(0, 0.3, 0)), C.podCap, "2022 Small Stud")
		for b = 1, POD_BALLS do
			make("Ball", "Pea" .. k .. "_" .. b, Vector3.new(POD_D, POD_D, POD_D),
				CFrame.new(hang - Vector3.new(0, 0.6 + (b - 0.5) * POD_D * 0.95, 0)), C.pod, "2022 Small Stud")
		end
	end
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

model.PrimaryPart = first
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
local count = 0
for _, d in ipairs(model:GetDescendants()) do
	if d:IsA("BasePart") then count = count + 1 end
end
local ext = model:GetExtentsSize()
print(string.format("Beanstalk built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
