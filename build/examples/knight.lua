--[[
	Armored Knight: a blocky knight standing guard with a sword and a kite shield, on a stone tile.
	Size: about 8 x 11 x 5 studs. Faces -Z.
	SUBJECT TYPE: upright character. BOTTOM-UP build: boots on the tile, legs on boots, hips on legs,
	torso on hips, head on the neck, arms hang from the shoulders, held items touch the hands.
	SIGNATURE FEATURES: silver plate armour with gold trim, a helmet with a visor slit and a red plume,
	shoulder pauldrons, a blue tabard with a gold emblem, a belt, a sword held point-down and a blue-and-gold kite shield.
	LOOSE-PART RULES SHOWN: every body part is placed from the part below (BOOT_TOP, LEG_TOP, HIP_TOP, CHEST_TOP);
	arms are attached at the torso side faces; the shield's back face touches the left forearm; the sword grip goes through the right hand.
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
model.Name = "Knight"

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
	tile = "Medium stone grey", tile2 = "Dark stone grey", steel = "Light stone grey", steel2 = "Medium stone grey",
	dark = "Dark stone grey", gold = "Bright yellow", tabard = "Bright blue", plume = "Bright red", leather = "Reddish brown",
	slit = "Really black", blade = "Institutional white",
}

onTop("Tile", V(8, 0.6, 6), 0, 0, 0, C.tile, "2022 Big Stud")
onTop("TileEdge", V(8.2, 0.2, 6.2), 0, 0, 0, C.tile2, "2022 Small Stud")
local G = 0.6

-- LEGS
local BOOT, LEG = V(1.4, 0.8, 1.8), V(1.2, 2.6, 1.2)
local BOOT_TOP, LEG_TOP = G + BOOT.Y, G + BOOT.Y + LEG.Y
for _, sx in ipairs({ -1, 1 }) do
	onTop("Boot", BOOT, sx * 0.8, G, -0.2, C.dark, "2022 Small Stud")
	onTop("Leg", LEG, sx * 0.8, BOOT_TOP, 0, C.steel, "2022 Small Stud")
	onTop("KneeGuard", V(1.3, 0.6, 0.3), sx * 0.8, BOOT_TOP + 1, -0.7, C.steel2, "2022 Small Stud")
end

-- HIPS and BELT, TORSO with tabard, CHEST plate
onTop("Hips", V(2.8, 0.8, 1.4), 0, LEG_TOP, 0, C.steel2, "2022 Small Stud")
local HIP_TOP = LEG_TOP + 0.8
onTop("Belt", V(2.9, 0.4, 1.5), 0, HIP_TOP - 0.4, 0, C.leather, "2022 Small Stud")
onTop("Buckle", V(0.6, 0.5, 0.1), 0, HIP_TOP - 0.45, -0.8, C.gold)
local TORSO = V(3, 2.8, 1.6)
onTop("Torso", TORSO, 0, HIP_TOP, 0, C.steel, "2022 Big Stud")
local CHEST_TOP = HIP_TOP + TORSO.Y
-- tabard hangs from the torso front down over the hips (front face sunk 0.05)
onTop("Tabard", V(2, 3.6, 0.2), 0, LEG_TOP - 0.6, -TORSO.Z / 2 - 0.05, C.tabard, "2022 Small Stud")
onTop("Emblem", V(0.9, 0.9, 0.1), 0, HIP_TOP + 1.2, -TORSO.Z / 2 - 0.2, C.gold)
onTop("Gorget", V(1.8, 0.4, 1.2), 0, CHEST_TOP, 0, C.steel2, "2022 Small Stud")

-- HEAD / HELMET on the gorget
local HELM = V(1.9, 1.9, 1.9)
local helmCF = CFrame.new(0, CHEST_TOP + 0.4 + HELM.Y / 2, 0)
make("Part", "Helmet", HELM, helmCF, C.steel, "2022 Big Stud")
make("Part", "VisorSlit", V(1.4, 0.2, 0.1), helmCF * CFrame.new(0, 0.2, -HELM.Z / 2 - 0.02), C.slit)
make("Part", "VisorRidge", V(0.2, 1.2, 0.2), helmCF * CFrame.new(0, -0.2, -HELM.Z / 2 - 0.05), C.gold)
make("Part", "HelmBand", V(2, 0.3, 2), helmCF * CFrame.new(0, 0.55, 0), C.gold, "2022 Small Stud")
-- plume: a chain of bones starting inside the helmet top, curving back
local p0 = helmCF:PointToWorldSpace(V(0, HELM.Y / 2 - 0.2, 0))
local p1 = p0 + V(0, 0.9, 0.3)
local p2 = p1 + V(0, 0.3, 1)
bone("Plume1", p0, p1, 0.5, 0.7, C.plume, "2022 Small Stud")
joint("PlumeBend", p1, 0.7, C.plume)
bone("Plume2", p1, p2, 0.5, 0.6, C.plume, "2022 Small Stud")

-- ARMS: pauldron on each shoulder, upper arm against the torso side face, forearm, gauntlet
local ARM = V(0.9, 1.4, 0.9)
local hands = {}
for _, sx in ipairs({ -1, 1 }) do
	local ax = sx * (TORSO.X / 2 + ARM.X / 2)
	onTop("Pauldron", V(1.4, 0.7, 1.6), sx * (TORSO.X / 2 + 0.3), CHEST_TOP - 0.5, 0, C.steel2, "2022 Big Stud")
	onTop("PauldronTrim", V(1.5, 0.2, 1.7), sx * (TORSO.X / 2 + 0.3), CHEST_TOP - 0.55, 0, C.gold, "2022 Small Stud")
	onTop("UpperArm", ARM, ax, CHEST_TOP - 0.5 - ARM.Y, 0, C.steel, "2022 Small Stud")
	onTop("Forearm", ARM, ax, CHEST_TOP - 0.5 - 2 * ARM.Y, -0.15, C.steel2, "2022 Small Stud")
	local handY = CHEST_TOP - 0.5 - 2 * ARM.Y - 0.8
	onTop("Gauntlet", V(1, 0.8, 1), ax, handY, -0.2, C.dark, "2022 Small Stud")
	hands[sx] = V(ax, handY + 0.4, -0.2)
end

-- SWORD through the right hand, pointing down to the tile
local h = hands[1]
onTop("SwordGrip", V(0.35, 1.2, 0.35), h.X, h.Y - 0.6, h.Z - 0.6, C.leather, "2022 Small Stud")
onTop("SwordGuard", V(0.3, 0.3, 1.6), h.X, h.Y - 0.9, h.Z - 0.6, C.gold, "2022 Small Stud")
onTop("SwordBlade", V(0.25, h.Y - 0.9 - G, 0.6), h.X, G, h.Z - 0.6, C.blade, "2022 Small Stud")
make("Ball", "SwordPommel", V(0.5, 0.5, 0.5), CFrame.new(h.X, h.Y + 0.75, h.Z - 0.6), C.gold)
-- grip connects to the gauntlet: a small bar between them
bone("GripBar", h, V(h.X, h.Y, h.Z - 0.6), 0.4, 0.4, C.dark)

-- KITE SHIELD on the left forearm: back face touching the forearm's outer face
local L = hands[-1]
local shX = L.X - 0.5 - 0.15
onTop("Shield", V(0.3, 2.6, 2), shX, L.Y - 0.6, -0.2, C.tabard, "2022 Big Stud")
make("Wedge", "ShieldPoint", V(0.3, 1, 2), CFrame.new(shX, L.Y - 0.6 - 0.5, -0.2) * CFrame.Angles(math.pi, 0, 0), C.tabard, "2022 Big Stud")
onTop("ShieldRim", V(0.35, 0.25, 2.1), shX, L.Y + 2 - 0.05, -0.2, C.gold, "2022 Small Stud")
onTop("ShieldCrossV", V(0.4, 2.4, 0.35), shX - 0.05, L.Y - 0.5, -0.2, C.gold, "2022 Small Stud")
onTop("ShieldCrossH", V(0.4, 0.35, 1.8), shX - 0.05, L.Y + 0.9, -0.2, C.gold, "2022 Small Stud")

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
print(string.format("Knight built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
