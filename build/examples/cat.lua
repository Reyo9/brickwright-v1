--[[
	Sitting Tabby Cat: a grey tabby cat sitting upright on a round cushion, tail curled around its paws.
	Size: about 7 x 9 x 7 studs. Faces -Z.
	SUBJECT TYPE: seated pet. STACKING build: cushion, then haunches and paws on the cushion, chest on the haunches, head on the chest.
	SIGNATURE FEATURES: tabby stripes, a white chest and paws, pointed ears with pink insides, green eyes with slit pupils,
	whiskers, a pink nose and a long striped tail curving around the front paws.
	LOOSE-PART RULES SHOWN: the curled tail is a chain of bones whose points all sit on the cushion top;
	stripes and face details sink 0.05 into the surface they decorate.
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
model.Name = "SittingCat"

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
	fur = "Medium stone grey", fur2 = "Dark stone grey", white = "White", pink = "Pink", eye = "Lime green",
	pupil = "Really black", cushion = "Bright violet", cushion2 = "Lavender", tassel = "Bright yellow",
}

-- CUSHION: two discs and corner tassels touching the side
make("Cylinder", "Cushion", V(1.4, 8, 8), CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.pi / 2), C.cushion, "2022 Big Stud")
make("Cylinder", "CushionTop", V(0.3, 7, 7), CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.pi / 2), C.cushion2, "2022 Small Stud")
for k = 0, 3 do
	local a = k / 4 * math.pi * 2 + math.pi / 4
	make("Ball", "Tassel" .. k, V(0.7, 0.7, 0.7), CFrame.new(math.cos(a) * 4, 0.7, math.sin(a) * 4), C.tassel)
end
local SEAT = 1.65

-- HAUNCHES (seated back legs) and FRONT PAWS on the cushion
local HAUNCH = V(4.4, 2.2, 3.6)
onTop("Haunches", HAUNCH, 0, SEAT, 0.6, C.fur, "2022 Big Stud")
for _, sx in ipairs({ -1, 1 }) do
	onTop("Thigh", V(1, 1.8, 2.6), sx * 2.2, SEAT, 0.8, C.fur, "2022 Small Stud")
	onTop("FrontLeg", V(0.9, 2.6, 0.9), sx * 0.8, SEAT + 0.5, -1.4, C.white, "2022 Small Stud")
	onTop("FrontPaw", V(1.1, 0.6, 1.3), sx * 0.8, SEAT, -1.6, C.white, "2022 Small Stud")
	onTop("BackPaw", V(1.1, 0.5, 1.3), sx * 2.1, SEAT, -0.8, C.white, "2022 Small Stud")
end
local HAUNCH_TOP = SEAT + HAUNCH.Y

-- CHEST rising from the haunches, white bib in front, stripes on the back
local CHEST = V(3.4, 3, 2.8)
onTop("Chest", CHEST, 0, HAUNCH_TOP - 0.2, 0, C.fur, "2022 Big Stud")
local CHEST_TOP = HAUNCH_TOP - 0.2 + CHEST.Y
onTop("Bib", V(2, 3.4, 0.3), 0, HAUNCH_TOP - 0.6, -CHEST.Z / 2 - 0.1, C.white, "2022 Small Stud")
for i = 0, 2 do
	onTop("BackStripe" .. i, V(CHEST.X + 0.1, 0.35, 0.6), 0, HAUNCH_TOP + 0.4 + i * 0.9, CHEST.Z / 2 - 0.25, C.fur2, "2022 Small Stud")
	onTop("HaunchStripe" .. i, V(0.3, 0.4, 2), (i - 1) * 1.6, HAUNCH_TOP - 0.05, 1, C.fur2, "2022 Small Stud")
end

-- HEAD on the chest
local HEAD = V(3.4, 2.8, 2.8)
local headCF = CFrame.new(0, CHEST_TOP + HEAD.Y / 2 - 0.1, -0.3)
make("Part", "Head", HEAD, headCF, C.fur, "2022 Big Stud")
local front = -HEAD.Z / 2
make("Part", "Muzzle", V(1.6, 1, 0.5), headCF * CFrame.new(0, -0.7, front - 0.2), C.white, "2022 Small Stud")
make("Wedge", "Nose", V(0.5, 0.3, 0.3), headCF * CFrame.new(0, -0.3, front - 0.45) * CFrame.Angles(math.pi, 0, 0), C.pink)
make("Part", "ForeheadStripe", V(0.3, 0.9, 0.1), headCF * CFrame.new(0, 0.9, front - 0.03), C.fur2)
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "Eye", V(0.7, 0.6, 0.15), headCF * CFrame.new(sx * 0.8, 0.25, front - 0.05), C.eye)
	make("Part", "Pupil", V(0.15, 0.5, 0.1), headCF * CFrame.new(sx * 0.8, 0.25, front - 0.15), C.pupil)
	make("Part", "CheekStripe", V(0.6, 0.15, 0.1), headCF * CFrame.new(sx * 1.4, -0.1, front - 0.03), C.fur2)
	for k, dy in ipairs({ -0.55, -0.8 }) do
		make("Part", "Whisker", V(1.4, 0.08, 0.08), headCF * CFrame.new(sx * 1.3, dy, front - 0.4) * CFrame.Angles(0, 0, sx * (k - 1.5) * 0.25), C.white)
	end
	local earCF = headCF * CFrame.new(sx * 1, HEAD.Y / 2 + 0.6, 0.2)
	make("Wedge", "Ear", V(1.2, 1.4, 0.5), earCF, C.fur, "2022 Small Stud")
	make("Wedge", "EarInner", V(0.7, 0.9, 0.2), earCF * CFrame.new(0, -0.15, -0.2), C.pink)
end

-- TAIL: from the back of the haunches, curling around the right side to the front paws,
-- every point at SEAT + radius so the whole tail lies ON the cushion top
local tr = 0.45
local pts = { V(0, SEAT + tr, 2.6), V(1.6, SEAT + tr, 2.9), V(3, SEAT + tr, 2), V(3.4, SEAT + tr, 0.4), V(3, SEAT + tr, -1.4), V(1.9, SEAT + tr, -2.6) }
for i = 1, #pts - 1 do
	bone("Tail" .. i, pts[i], pts[i + 1], 0.9, 0.9, i % 2 == 0 and C.fur2 or C.fur, "2022 Small Stud")
	joint("TailJoint" .. i, pts[i + 1], 0.9, i % 2 == 0 and C.fur or C.fur2)
end
joint("TailTip", pts[#pts], 1, C.fur2)

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
print(string.format("SittingCat built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
