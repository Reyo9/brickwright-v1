--[[
	Divine Dragon: a white-and-gold celestial dragon with spread wings and a glowing halo.
	Size: about 35 studs wingspan (X), 19 studs tall (Y), 33 studs long (Z). Faces -Z.
	SUBJECT TYPE: creature, SKELETON FIRST build (long and posed, wings spread).
	SIGNATURE FEATURES: wide pale-blue membrane wings on gold finger bones, a raised
	horned head with glowing gold eyes, a floating gold halo, a gold dorsal spike line
	and a white body with a cream belly.
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

local C = {
	body = "White",
	belly = "Cool yellow",
	accent = "Bright yellow",
	horn = "Brick yellow",
	membrane = "Pastel Blue",
	dark = "Really black",
	tongue = "Bright red",
	glow = "Bright yellow",
}

-- LAYOUT
local V = Vector3.new
local SPINE = {
	V(0, 13, -9), V(0, 10.5, -6.5), V(0, 9, -3.5), V(0, 8.8, 0), V(0, 8.5, 3.5),
	V(0, 7, 7), V(0, 5, 10.5), V(1, 3, 14), V(2.5, 1.5, 17.5),
}
local SPINE_W = { 2.5, 3, 4, 4.5, 3.5, 2.5, 2, 1.2 }
local SPINE_H = { 2.5, 3, 4, 4, 3.5, 2.5, 1.8, 1.2 }
local HEAD_POS = V(0, 13.5, -10.5)
local CRANIUM = V(4, 3, 4)
local SNOUT = V(3, 1.8, 3)
local JAW_DROP = -12
-- legs: one side, mirrored by sx
local LEGS = {
	{ top = V(2, 8, -3), mid = V(3.5, 5, -1.5), low = V(3.5, 1.5, -4), foot = V(3.5, 0.5, -4.5) },
	{ top = V(2, 8, 3.5), mid = V(3.5, 5, 1.5), low = V(3.5, 1.5, 4.5), foot = V(3.5, 0.5, 3.5) },
}
local FOOT = V(1.6, 1, 2.2)
-- wings: one side, mirrored by sx
local W_ROOT = V(2.2, 10, -2.5)
local W_ELBOW = V(7, 15, -0.5)
local W_WRIST = V(11.5, 17, -1.5)
local W_TIPS = { V(17.5, 13, 1), V(15, 9, 4.5), V(10, 8, 6) }
local W_BODY = V(3, 9, 4)
local HALO_R, HALO_N, HALO_UP = 2.5, 8, 4.2
local HALO_SEG = 2 * HALO_R * math.sin(math.pi / HALO_N) + 0.3

local model = Instance.new("Model")
model.Name = "DivineDragon"

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

-- A bone: a part stretched between two joints a and b, its length along local Z,
-- so a pose is just a list of joint positions. Returns the CFrame and length.
local function bone(name, a, b, w, h, colour, variant)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	make("Part", name, Vector3.new(w, h, len), cf, colour, variant)
	return cf, len
end

-- A ball at a joint hides the seam where two angled bones meet.
local function joint(name, at, d, colour, variant)
	make("Ball", name, Vector3.new(d, d, d), CFrame.new(at), colour, variant)
end

-- The body as ONE flowing curve: a bone per pair of points, tapering by the widths and
-- heights tables, a ball at every bend, a lighter belly plate underneath and a dorsal spike on top.
local function spine(name, pts, widths, heights, colour, bellyColour, spikeColour)
	for i = 1, #pts - 1 do
		local w, h = widths[i], heights[i]
		local cf, len = bone(name .. i, pts[i], pts[i + 1], w, h, colour, "2022 Small Stud")
		if i > 1 then
			joint(name .. "Bend" .. i, pts[i], math.min(w, h), colour, "2022 Small Stud")
		end
		if bellyColour then
			make("Part", name .. "Belly" .. i, Vector3.new(math.max(1, w - 1), 0.4, len),
				cf * CFrame.new(0, -h / 2 - 0.2, 0), bellyColour)
		end
		if spikeColour then
			local sp = math.max(1, math.floor(h / 2))
			make("Wedge", name .. "Spike" .. i, Vector3.new(1, sp, sp),
				cf * CFrame.new(0, h / 2 + sp / 2, 0), spikeColour, "2022 Big Stud")
		end
	end
end

-- Neon for light only
local function glow(p)
	p.Material = Enum.Material.Neon
	p.MaterialVariant = ""
	return p
end

-- A flat membrane plate fanning from a pivot to the edge between a and b
local function membrane(name, pivot, a, b)
	local m = (a + b) / 2
	local zA = (m - pivot).Unit
	local across = b - a
	local xA = (across - zA * across:Dot(zA)).Unit
	local yA = zA:Cross(xA)
	local len = (m - pivot).Magnitude
	make("Part", name, Vector3.new(math.max(1, across.Magnitude * 0.7), 0.4, len),
		CFrame.fromMatrix((pivot + m) / 2, xA, yA), C.membrane, "2022 Small Stud")
end

local function mir(v, sx)
	return Vector3.new(v.X * sx, v.Y, v.Z)
end

-- BODY: neck, torso and tail as one curve
spine("Body", SPINE, SPINE_W, SPINE_H, C.body, C.belly, C.accent)
joint("NeckBase", SPINE[1], 2.8, C.body, "2022 Small Stud")

-- TAIL TIP: gold spade
local tip = SPINE[#SPINE]
make("Ball", "TailOrb", Vector3.new(1.5, 1.5, 1.5), CFrame.new(tip), C.accent, "2022 Big Stud")
make("Part", "TailSpade", Vector3.new(1.6, 0.4, 1.6), CFrame.new(tip + Vector3.new(0.4, 0, 0.8)) * CFrame.Angles(0, math.pi / 4, 0), C.accent, "2022 Big Stud")

-- LEGS with feet and claws
for _, sx in ipairs({ -1, 1 }) do
	for li, L in ipairs(LEGS) do
		local top, mid, low, foot = mir(L.top, sx), mir(L.mid, sx), mir(L.low, sx), mir(L.foot, sx)
		bone("UpperLeg" .. li, top, mid, 1.6, 1.6, C.body, "2022 Small Stud")
		bone("LowerLeg" .. li, mid, low, 1.2, 1.2, C.body, "2022 Small Stud")
		joint("Knee" .. li, mid, 1.8, C.body)
		joint("Ankle" .. li, low, 1.6, C.body)
		make("Part", "Foot" .. li, FOOT, CFrame.new(foot), C.belly)
		for _, dx in ipairs({ -0.5, 0, 0.5 }) do
			make("Wedge", "Claw", Vector3.new(0.4, 0.6, 1),
				CFrame.new(foot + Vector3.new(dx, -FOOT.Y / 2 + 0.3, -FOOT.Z / 2 - 0.5)), C.horn, "2022 Small Stud")
		end
	end
end

-- WINGS: arm bones, gold fingers, membranes, thumb claw
for _, sx in ipairs({ -1, 1 }) do
	local root, elbow, wrist = mir(W_ROOT, sx), mir(W_ELBOW, sx), mir(W_WRIST, sx)
	local tips = {}
	for i, t in ipairs(W_TIPS) do tips[i] = mir(t, sx) end
	local bodyPt = mir(W_BODY, sx)
	bone("WingArm", root, elbow, 1.2, 1.2, C.body, "2022 Small Stud")
	bone("WingFore", elbow, wrist, 1, 1, C.body, "2022 Small Stud")
	joint("WingElbow", elbow, 1.6, C.accent, "2022 Big Stud")
	joint("WingWrist", wrist, 1.4, C.accent, "2022 Big Stud")
	for i, t in ipairs(tips) do
		bone("WingFinger" .. i, wrist, t, 0.6, 0.6, C.accent, "2022 Small Stud")
	end
	membrane("Membrane1", wrist, tips[1], tips[2])
	membrane("Membrane2", wrist, tips[2], tips[3])
	membrane("Membrane3", wrist, tips[3], bodyPt)
	membrane("Membrane4", elbow, root, bodyPt)
	make("Wedge", "ThumbClaw", Vector3.new(0.4, 1, 0.6), CFrame.new(wrist + Vector3.new(0, 1, 0)), C.horn, "2022 Small Stud")
end

-- HEAD
local headCF = CFrame.new(HEAD_POS)
local head = make("Part", "Cranium", CRANIUM, headCF, C.body, "2022 Small Stud")
local snoutCF = headCF * CFrame.new(0, -0.6, -(CRANIUM.Z + SNOUT.Z) / 2)
make("Part", "Snout", SNOUT, snoutCF, C.body, "2022 Small Stud")
local jawCF = headCF * CFrame.new(0, -2.2, -2.5) * CFrame.Angles(math.rad(JAW_DROP), 0, 0)
make("Part", "Jaw", Vector3.new(2.6, 1, 4), jawCF, C.belly)
make("Part", "Tongue", Vector3.new(1.2, 0.2, 2.5), headCF * CFrame.new(0, -1.7, -3), C.tongue, "2022 Small Stud")
local snoutFront = -(CRANIUM.Z / 2 + SNOUT.Z)
for _, sx in ipairs({ -1, 1 }) do
	-- teeth
	for _, z in ipairs({ -3, -4.3 }) do
		make("Wedge", "ToothUpper", Vector3.new(0.3, 0.6, 0.4),
			headCF * CFrame.new(sx * 1.1, -0.6 - SNOUT.Y / 2 - 0.3, z) * CFrame.Angles(math.pi, 0, 0), "White", "2022 Small Stud")
	end
	make("Wedge", "ToothLower", Vector3.new(0.3, 0.6, 0.4), jawCF * CFrame.new(sx * 1, 0.8, -1.2), "White", "2022 Small Stud")
	-- eyes: dark socket, glowing pupil, gold brow
	make("Part", "EyeSocket", Vector3.new(1.2, 0.8, 0.2), headCF * CFrame.new(sx * 1.2, 0.5, -CRANIUM.Z / 2 - 0.1), C.dark, "2022 Small Stud")
	glow(make("Part", "Pupil", Vector3.new(0.6, 0.5, 0.2), headCF * CFrame.new(sx * 1.2, 0.5, -CRANIUM.Z / 2 - 0.3), C.glow))
	make("Part", "Brow", Vector3.new(1.6, 0.4, 0.8), headCF * CFrame.new(sx * 1.2, 1.2, -CRANIUM.Z / 2 - 0.1), C.accent, "2022 Small Stud")
	make("Part", "Nostril", Vector3.new(0.4, 0.4, 0.2), headCF * CFrame.new(sx * 0.7, -0.2, snoutFront - 0.1), C.dark, "2022 Small Stud")
	-- horns from two tapering bones
	local hb = headCF:PointToWorldSpace(Vector3.new(sx * 1.2, 1.4, 0.8))
	local hm = headCF:PointToWorldSpace(Vector3.new(sx * 1.8, 2.8, 2.6))
	local ht = headCF:PointToWorldSpace(Vector3.new(sx * 2.1, 3.6, 4.4))
	bone("HornBase", hb, hm, 1, 1, C.horn)
	bone("HornTip", hm, ht, 0.6, 0.6, C.accent, "2022 Small Stud")
	-- flowing whiskers
	local wa = headCF:PointToWorldSpace(Vector3.new(sx * 1.5, -0.8, -4.5))
	local wb = headCF:PointToWorldSpace(Vector3.new(sx * 3.5, -2, -2))
	bone("Whisker", wa, wb, 0.2, 0.2, C.belly, "2022 Small Stud")
end
-- crest on the crown
for i, z in ipairs({ -0.5, 1 }) do
	make("Wedge", "Crest" .. i, Vector3.new(0.4, 1, 1.2), headCF * CFrame.new(0, CRANIUM.Y / 2 + 0.5, z), C.accent, "2022 Big Stud")
end

-- HALO: a floating ring of light above the head
local haloC = headCF.Position + Vector3.new(0, HALO_UP, 1)
for i = 0, HALO_N - 1 do
	local a = i / HALO_N * 2 * math.pi
	local pos = haloC + Vector3.new(math.cos(a) * HALO_R, 0, math.sin(a) * HALO_R)
	local tan = Vector3.new(-math.sin(a), 0, math.cos(a))
	local seg = glow(make("Part", "Halo", Vector3.new(0.4, 0.4, HALO_SEG), CFrame.lookAt(pos, pos + tan), C.glow))
	if i == 0 then
		local light = Instance.new("PointLight")
		light.Color = BrickColor.new(C.glow).Color
		light.Range = 14
		light.Brightness = 2
		light.Parent = seg
	end
end

-- Stud guarantee: every part studded; keeps a chosen variant if the pack has it, else Universal.
-- Neon stays glowing only where it is THIN (lens, strip, core bar).
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

model.PrimaryPart = head
model.Parent = workspace
local count = 0
for _, d in ipairs(model:GetDescendants()) do
	if d:IsA("BasePart") then count = count + 1 end
end
local ext = model:GetExtentsSize()
print(string.format("DivineDragon built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
