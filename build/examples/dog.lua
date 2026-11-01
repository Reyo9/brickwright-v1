--[[
	Happy Corgi: a chunky orange-and-white corgi standing with its tongue out, wagging tail, on a grass mat.
	Size: about 6 x 7 x 11 studs. Faces -Z.
	SUBJECT TYPE: four-legged pet. LEGS-UP build: paws on the mat, legs on paws, body on legs, head on the neck.
	SIGNATURE FEATURES: very short legs, long loaf body with a white belly and chest bib, big upright
	triangle ears with pink insides, white muzzle with a black nose, pink tongue, fluffy tail and a red collar with a gold tag.
	LOOSE-PART RULES SHOWN: every height is computed from the part below (PAW_TOP, LEG_TOP, BODY_TOP);
	face details sink 0.05 into the head front; ears overlap the head top by 0.2.
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
model.Name = "Corgi"

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
	fur = "Bright orange", fur2 = "Dark orange", white = "White", nose = "Really black", eye = "Really black",
	pink = "Pink", tongue = "Hot pink", collar = "Bright red", tag = "Bright yellow", grass = "Bright green", grass2 = "Earth green",
}

onTop("Mat", V(8, 0.4, 13), 0, 0, 0, C.grass, "2022 Big Stud")
for i, g in ipairs({ { -3.2, 5 }, { 3.3, -5.4 }, { 3, 4.6 }, { -3.4, -5 } }) do
	onTop("Tuft" .. i, V(0.4, 0.8, 0.4), g[1], 0.35, g[2], C.grass2, "2022 Small Stud")
end
local G = 0.4

-- PAWS (white) and short LEGS
local PAW = V(1.4, 0.6, 1.6)
local LEG = V(1.2, 1.4, 1.2)
local PAW_TOP = G + PAW.Y
local LEG_TOP = PAW_TOP + LEG.Y
for _, z in ipairs({ -3, 3 }) do
	for _, sx in ipairs({ -1, 1 }) do
		onTop("Paw", PAW, sx * 1.4, G, z - 0.15, C.white, "2022 Small Stud")
		onTop("Leg", LEG, sx * 1.4, PAW_TOP, z, z < 0 and C.white or C.fur, "2022 Small Stud")
	end
end

-- BODY loaf on the legs: belly plate underneath, back plate on top, chest bib in front
local BODY = V(4, 2.8, 8)
onTop("Belly", V(3.4, 0.4, 7), 0, LEG_TOP - 0.1, 0, C.white, "2022 Small Stud")
onTop("Body", BODY, 0, LEG_TOP + 0.3, 0, C.fur, "2022 Big Stud")
local BODY_TOP = LEG_TOP + 0.3 + BODY.Y
onTop("Saddle", V(3.2, 0.3, 4.6), 0, BODY_TOP - 0.05, 0.6, C.fur2, "2022 Small Stud")
onTop("Bib", V(2.6, 2.4, 0.4), 0, LEG_TOP + 0.3, -BODY.Z / 2 - 0.15, C.white, "2022 Small Stud")
-- rump: rounded back end touching the body
make("Cylinder", "Rump", V(4, 2.8, 2.8), CFrame.new(0, LEG_TOP + 0.3 + 1.4, BODY.Z / 2 - 0.4), C.fur, "2022 Big Stud")

-- TAIL: a short fluffy bone from inside the rump, angled up, with a white tip ball
local tailBase = V(0, BODY_TOP - 0.8, BODY.Z / 2 + 0.6)
local tailTip = tailBase + V(0.6, 1.4, 1.2)
bone("Tail", tailBase, tailTip, 1, 1, C.fur, "2022 Small Stud")
joint("TailTip", tailTip, 1.2, C.white, "2022 Small Stud")

-- NECK and HEAD at the front top
local neckBase = V(0, BODY_TOP - 0.6, -BODY.Z / 2 + 0.6)
local neckTop = neckBase + V(0, 1.4, -0.8)
bone("Neck", neckBase, neckTop, 2.2, 2.2, C.fur, "2022 Small Stud")
local HEAD = V(3.2, 2.6, 2.8)
local headCF = CFrame.new(neckTop + V(0, 0.8, -0.6))
make("Part", "Head", HEAD, headCF, C.fur, "2022 Big Stud")
local front = -HEAD.Z / 2
-- white blaze down the face, muzzle box sticking out of the head front
make("Part", "Blaze", V(0.8, 1.6, 0.2), headCF * CFrame.new(0, 0.2, front - 0.05), C.white, "2022 Small Stud")
local MUZ = V(1.8, 1.2, 1.4)
local muzCF = headCF * CFrame.new(0, -0.6, front - MUZ.Z / 2 + 0.1)
make("Part", "Muzzle", MUZ, muzCF, C.white, "2022 Small Stud")
make("Part", "Nose", V(0.7, 0.5, 0.3), muzCF * CFrame.new(0, 0.35, -MUZ.Z / 2 - 0.1), C.nose, "2022 Small Stud")
make("Part", "Mouth", V(1, 0.15, 0.1), muzCF * CFrame.new(0, -0.25, -MUZ.Z / 2 - 0.02), C.nose)
make("Part", "Tongue", V(0.6, 0.15, 0.8), muzCF * CFrame.new(0, -0.55, -MUZ.Z / 2 + 0.1) * CFrame.Angles(math.rad(-25), 0, 0), C.tongue, "2022 Small Stud")
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "Eye", V(0.5, 0.6, 0.2), headCF * CFrame.new(sx * 0.85, 0.4, front - 0.05), C.eye)
	make("Part", "EyeShine", V(0.15, 0.15, 0.1), headCF * CFrame.new(sx * 0.85 + 0.12, 0.55, front - 0.15), C.white)
	make("Part", "Cheek", V(0.7, 0.3, 0.1), headCF * CFrame.new(sx * 1.2, -0.3, front - 0.03), C.pink)
	-- ears: wedges whose bottom overlaps the head top by 0.2, pink inner sunk into the front face
	local earCF = headCF * CFrame.new(sx * 0.95, HEAD.Y / 2 + 0.9, 0.3) * CFrame.Angles(0, 0, sx * math.rad(-12))
	make("Wedge", "Ear", V(1, 2.2, 0.6), earCF, C.fur, "2022 Small Stud")
	make("Wedge", "EarInner", V(0.6, 1.4, 0.2), earCF * CFrame.new(0, -0.2, -0.25), C.pink, "2022 Small Stud")
end

-- COLLAR around the neck base with a hanging tag touching the collar
local collarCF = CFrame.lookAt(neckBase:Lerp(neckTop, 0.35), neckTop)
make("Part", "Collar", V(2.5, 2.5, 0.5), collarCF, C.collar, "2022 Small Stud")
make("Cylinder", "Tag", V(0.2, 0.7, 0.7), collarCF * CFrame.new(0, -1.5, -0.1) * CFrame.Angles(0, math.pi / 2, 0), C.tag, "2022 Small Stud")

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
print(string.format("Corgi built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
