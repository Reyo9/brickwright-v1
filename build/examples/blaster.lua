--[[
	Sci-Fi Blaster: a chunky white-and-orange laser blaster resting on a display stand.
	Size: about 4 x 8 x 12 studs. Faces -Z (muzzle forward).
	SUBJECT TYPE: weapon prop on a stand. CORE-OUT build: the main receiver block is placed first,
	every other piece (barrel, grip, stock, scope, magazine) is placed against one of its faces.
	SIGNATURE FEATURES: a boxy white receiver with orange side panels, a ribbed barrel with a glowing cyan muzzle ring,
	an angled grip and trigger guard, an energy cell magazine with a glowing window, a top scope and a sloped stock.
	LOOSE-PART RULES SHOWN: positions are offsets from the receiver faces (RX, RY, RZ = half sizes), so every part touches;
	the blaster rests on two stand prongs whose tops touch the receiver bottom.
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
model.Name = "SciFiBlaster"

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
	white = "Institutional white", grey = "Medium stone grey", dark = "Dark stone grey", black = "Black",
	accent = "Neon orange", glow = "Cyan", stand = "Dark stone grey", stand2 = "Black",
}

-- STAND: base, column, two prongs; receiver bottom = prong top
onTop("StandBase", V(6, 0.6, 9), 0, 0, 0, C.stand2, "2022 Big Stud")
onTop("StandColumn", V(1.2, 3, 1.2), 0, 0.6, 0, C.stand, "2022 Small Stud")
local PRONG_TOP = 0.6 + 3 + 0.8
for _, z in ipairs({ -2.2, 2.2 }) do
	bone("Prong", V(0, 3.4, 0), V(0, PRONG_TOP, z), 0.6, 0.6, C.stand, "2022 Small Stud")
	joint("ProngCap", V(0, PRONG_TOP - 0.3, z), 0.7, C.accent)
end

-- RECEIVER (core)
local REC = V(2.4, 2.6, 6)
local RX, RY, RZ = REC.X / 2, REC.Y / 2, REC.Z / 2
local recCF = CFrame.new(0, PRONG_TOP + RY, 0)
make("Part", "Receiver", REC, recCF, C.white, "2022 Big Stud")
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "SidePanel", V(0.2, 1.4, 3.6), recCF * CFrame.new(sx * (RX + 0.05), 0.2, -0.4), C.accent, "2022 Small Stud")
	make("Part", "Vent", V(0.2, 0.25, 1.6), recCF * CFrame.new(sx * (RX + 0.1), -0.8, 1.6), C.dark)
	make("Part", "Vent2", V(0.2, 0.25, 1.6), recCF * CFrame.new(sx * (RX + 0.1), -0.4, 1.6), C.dark)
end

-- BARREL out of the front face: shroud, ribs, muzzle with glowing ring
local front = -RZ
make("Part", "Shroud", V(1.8, 1.6, 2.4), recCF * CFrame.new(0, 0.3, front - 1.2), C.grey, "2022 Big Stud")
make("Cylinder", "Barrel", V(4, 0.9, 0.9), recCF * CFrame.new(0, 0.3, front - 3.4) * CFrame.Angles(0, math.pi / 2, 0), C.dark, "2022 Small Stud")
for k = 0, 2 do
	make("Cylinder", "Rib" .. k, V(0.4, 1.1, 1.1), recCF * CFrame.new(0, 0.3, front - 2.7 - k * 0.7) * CFrame.Angles(0, math.pi / 2, 0), C.black, "2022 Small Stud")
end
make("Cylinder", "Muzzle", V(0.7, 1.3, 1.3), recCF * CFrame.new(0, 0.3, front - 5.5) * CFrame.Angles(0, math.pi / 2, 0), C.white, "2022 Small Stud")
glow(make("Cylinder", "MuzzleRing", V(0.25, 1.1, 1.1), recCF * CFrame.new(0, 0.3, front - 5.95) * CFrame.Angles(0, math.pi / 2, 0), C.glow))

-- GRIP under the back half, angled; trigger guard in front of it
local gripCF = recCF * CFrame.new(0, -RY - 1.1, 1.4) * CFrame.Angles(math.rad(-15), 0, 0)
make("Part", "Grip", V(1.2, 2.6, 1.4), gripCF, C.black, "2022 Small Stud")
make("Part", "GripCap", V(1.3, 0.3, 1.5), gripCF * CFrame.new(0, -1.35, 0), C.accent, "2022 Small Stud")
make("Part", "TriggerGuard", V(0.4, 0.3, 1.8), recCF * CFrame.new(0, -RY - 1.2, 0), C.dark, "2022 Small Stud")
make("Part", "GuardFront", V(0.4, 1.2, 0.3), recCF * CFrame.new(0, -RY - 0.6, -0.8), C.dark, "2022 Small Stud")
make("Part", "Trigger", V(0.25, 0.7, 0.25), recCF * CFrame.new(0, -RY - 0.35, 0.1), C.accent)

-- ENERGY CELL magazine under the front half
make("Part", "Magazine", V(1.4, 1.8, 1.4), recCF * CFrame.new(0, -RY - 0.9, -1.8), C.grey, "2022 Big Stud")
glow(make("Part", "CellWindow", V(1.5, 0.9, 0.5), recCF * CFrame.new(0, -RY - 0.9, -1.8), C.glow))

-- SCOPE on top: two mounts touching the receiver top, tube on the mounts, glowing lens
for _, z in ipairs({ -1.2, 0.8 }) do
	make("Part", "ScopeMount", V(0.6, 0.6, 0.6), recCF * CFrame.new(0, RY + 0.3, z), C.dark, "2022 Small Stud")
end
make("Cylinder", "Scope", V(3.4, 0.9, 0.9), recCF * CFrame.new(0, RY + 1, -0.2) * CFrame.Angles(0, math.pi / 2, 0), C.black, "2022 Small Stud")
glow(make("Cylinder", "Lens", V(0.15, 0.7, 0.7), recCF * CFrame.new(0, RY + 1, -1.95) * CFrame.Angles(0, math.pi / 2, 0), C.glow))

-- STOCK off the back face, sloping down
local back = RZ
make("Part", "StockArm", V(1.6, 1.4, 2.4), recCF * CFrame.new(0, 0.2, back + 1.2), C.white, "2022 Big Stud")
-- wedge turned 180 so its tall face presses against the stock arm and the slope faces backwards
make("Wedge", "StockButt", V(1.8, 2.4, 1.6), recCF * CFrame.new(0, -0.3, back + 3.2) * CFrame.Angles(0, math.pi, 0), C.accent, "2022 Big Stud")
make("Part", "ButtPad", V(1.8, 0.3, 1.6), recCF * CFrame.new(0, -1.65, back + 3.2), C.black, "2022 Small Stud")

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
print(string.format("SciFiBlaster built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
