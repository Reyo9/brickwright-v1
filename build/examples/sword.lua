--[[
	Legendary Sword in the Stone: a glowing knight's sword driven into a mossy rock.
	Size: about 9 x 14 x 8 studs. Faces -Z.
	SUBJECT TYPE: weapon prop on a base. STACKING build: rock tiers first, blade sunk INTO the top tier, guard on the blade, grip on the guard.
	SIGNATURE FEATURES: a long steel blade with a darker centre fuller and a glowing blue rune line,
	a wide gold crossguard with curled tips, a wrapped leather grip, a gem pommel and a mossy stepped rock.
	LOOSE-PART RULES SHOWN: every tier's yBottom is the previous tier's top; the blade bottom sits 1.5 studs
	inside the rock; wraps and rivets sink 0.05 into the part they decorate.
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
model.Name = "LegendSword"

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
	rock = "Dark stone grey", rock2 = "Medium stone grey", moss = "Earth green", moss2 = "Bright green",
	steel = "Light stone grey", steel2 = "Medium stone grey", gold = "Bright yellow", gold2 = "Neon orange",
	leather = "Reddish brown", wrap = "Brown", gem = "Bright blue", rune = "Cyan",
}

-- ROCK: three stepped tiers, each resting exactly on the one below
local y = 0
local tiers = { { V(9, 1.6, 8), C.rock }, { V(7, 1.4, 6), C.rock2 }, { V(4.6, 1.2, 4), C.rock } }
for i, t in ipairs(tiers) do
	onTop("RockTier" .. i, t[1], 0, y, 0, t[2], "2022 Big Stud")
	y = y + t[1].Y
end
local ROCK_TOP = y
-- boulders hugging the lower tier (bottom on the ground, side touching tier 1)
for i, b in ipairs({ { -4.2, -2.6, 2.2 }, { 4, 2.2, 1.8 }, { 3.6, -3, 1.4 } }) do
	make("Ball", "Boulder" .. i, V(b[3], b[3], b[3]), CFrame.new(b[1], b[3] / 2, b[2]), C.rock2, "2022 Big Stud")
end
-- moss patches sunk 0.05 into the tier tops
onTop("Moss1", V(3, 0.3, 2), -2.4, 1.6 - 0.05, 1.8, C.moss, "2022 Small Stud")
onTop("Moss2", V(2, 0.3, 2.4), 2.6, 3.0 - 0.05, -1.2, C.moss2, "2022 Small Stud")
onTop("Moss3", V(1.6, 0.3, 1.2), -1.4, ROCK_TOP - 0.05, -1.2, C.moss, "2022 Small Stud")
for i, g in ipairs({ { -3.6, 2.6 }, { 3.2, -2.2 }, { 0.8, 2.6 } }) do
	onTop("Grass" .. i, V(0.3, 0.9, 0.3), g[1], 1.6 - 0.05, g[2], C.moss2, "2022 Small Stud")
end

-- BLADE: bottom 1.5 studs INSIDE the rock so it is clearly stuck in it
local BLADE_LEN, BLADE_W = 8, 1.2
local bladeBottom = ROCK_TOP - 1.5
onTop("Blade", V(BLADE_W, BLADE_LEN, 0.3), 0, bladeBottom, 0, C.steel, "2022 Small Stud")
onTop("Fuller", V(0.4, BLADE_LEN - 1.6, 0.36), 0, bladeBottom + 1, 0, C.steel2, "2022 Small Stud")
glow(onTop("RuneLine", V(0.12, BLADE_LEN - 3, 0.4), 0, bladeBottom + 2, 0, C.rune))
local bladeTop = bladeBottom + BLADE_LEN
-- crack ring where the blade enters the stone
for i, dx in ipairs({ -0.9, 0.9 }) do
	onTop("Crack" .. i, V(0.4, 0.2, 1.4), dx, ROCK_TOP - 0.05, 0, C.rock2, "2022 Small Stud")
end

-- GUARD: rests on the blade top, curled tips touch the guard ends
local GUARD = V(4.4, 0.6, 0.8)
onTop("Guard", GUARD, 0, bladeTop, 0, C.gold, "2022 Big Stud")
onTop("GuardCore", V(1.4, 1, 1), 0, bladeTop - 0.2, 0, C.gold2, "2022 Big Stud")
make("Ball", "GuardGem", V(0.6, 0.6, 0.6), CFrame.new(0, bladeTop + 0.3, -0.5), C.gem)
for _, sx in ipairs({ -1, 1 }) do
	local tipBase = V(sx * GUARD.X / 2, bladeTop + GUARD.Y / 2, 0)
	local tipTop = tipBase + V(sx * 0.4, 0.9, 0)
	bone("GuardCurl", tipBase, tipTop, 0.5, 0.5, C.gold, "2022 Small Stud")
	joint("GuardTip", tipTop, 0.6, C.gold2)
end

-- GRIP: sits on the guard, wraps sink into the grip
local gripBottom = bladeTop + GUARD.Y
local GRIP_H = 2.6
make("Cylinder", "Grip", V(GRIP_H, 0.6, 0.6), CFrame.new(0, gripBottom + GRIP_H / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), C.leather, "2022 Small Stud")
for k = 0, 3 do
	make("Cylinder", "Wrap" .. k, V(0.25, 0.68, 0.68), CFrame.new(0, gripBottom + 0.35 + k * 0.62, 0) * CFrame.Angles(0, 0, math.pi / 2), C.wrap, "2022 Small Stud")
end
-- POMMEL: ball on the grip top, gem sunk into its front
local pommelY = gripBottom + GRIP_H + 0.35
make("Ball", "Pommel", V(1, 1, 1), CFrame.new(0, pommelY, 0), C.gold, "2022 Big Stud")
make("Ball", "PommelGem", V(0.5, 0.5, 0.5), CFrame.new(0, pommelY, -0.35), C.gem)
glow(make("Part", "GemShine", V(0.15, 0.15, 0.1), CFrame.new(0.1, pommelY + 0.1, -0.6), C.rune))

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
print(string.format("LegendSword built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
