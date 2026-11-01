--[[
	Candy Dragon (Detailed+): a pastel-pink candy dragon made of sweets.
	Size: about 36 studs wingspan (X), 22 studs tall (Y), 34 studs long (Z). Faces -Z.
	SUBJECT TYPE: creature, SKELETON FIRST build (long and posed, wings spread).
	SIGNATURE FEATURES: candy-cane striped horns, a row of rainbow gumdrop spikes,
	mint-and-lavender wafer wings on striped candy-stick fingers, a giant swirl lollipop
	on the tail tip, white frosting drips along the back, rainbow sprinkles all over,
	a cream belly with chocolate bar plates and glowing cherry-red eyes.
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
	body = "Carnation pink",
	body2 = "Light reddish violet",
	belly = "Pastel yellow",
	choc = "Reddish brown",
	choc2 = "Dark orange",
	frost = "White",
	membrane = "Lavender",
	membrane2 = "Pastel blue-green",
	cane = "Bright red",
	dark = "Really black",
	tongue = "Hot pink",
	glow = "Really red",
}
local GUM = { "Bright red", "Bright orange", "New Yeller", "Lime green", "Bright bluish green", "Bright violet", "Hot pink" }
local SPRINKLE = { "Bright red", "New Yeller", "Lime green", "Bright blue", "Bright violet", "Bright orange", "White" }

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
model.Name = "CandyDragon"

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
local seed = 7
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648 return seed / 2147483648 end

-- The body as ONE flowing curve. Candy dressing per segment: chocolate belly bars,
-- a rainbow gumdrop on top, frosting drips down both sides and scattered sprinkles.
local function spine(name, pts, widths, heights, colour)
	for i = 1, #pts - 1 do
		local w, h = widths[i], heights[i]
		local cf, len = bone(name .. i, pts[i], pts[i + 1], w, h, i % 2 == 0 and C.body2 or colour, "2022 Small Stud")
		if i > 1 then
			joint(name .. "Bend" .. i, pts[i], math.min(w, h), colour, "2022 Small Stud")
		end
		-- chocolate bar belly: two tiles per segment with a darker groove
		local tiles = math.max(1, math.floor(len / 1.6))
		for t = 1, tiles do
			local z = -len / 2 + (t - 0.5) * len / tiles
			make("Part", name .. "Choc" .. i .. "_" .. t, Vector3.new(math.max(1, w - 0.8), 0.5, len / tiles - 0.25),
				cf * CFrame.new(0, -h / 2 - 0.25, z), C.choc, "2022 Big Stud")
		end
		make("Part", name .. "Cream" .. i, Vector3.new(math.max(1, w - 0.2), 0.3, len), cf * CFrame.new(0, -h / 2 + 0.05, 0), C.belly)
		-- frosting cap and drips
		make("Part", name .. "Frost" .. i, Vector3.new(math.min(1.2, w * 0.35), 0.3, len * 0.9), cf * CFrame.new(0, h / 2 + 0.1, 0), C.frost, "2022 Small Stud")
		for _, sx in ipairs({ -1, 1 }) do
			for d = 1, 2 do
				local dl = 0.6 + rnd() * (h * 0.35)
				make("Part", name .. "Drip", Vector3.new(0.35, dl, 0.5),
					cf * CFrame.new(sx * (w / 2 + 0.1), h / 2 - dl / 2, -len / 2 + d * len / 3), C.frost, "2022 Small Stud")
				make("Ball", name .. "DripEnd", Vector3.new(0.5, 0.5, 0.5),
					cf * CFrame.new(sx * (w / 2 + 0.1), h / 2 - dl, -len / 2 + d * len / 3), C.frost)
			end
		end
		-- gumdrop spike: domed body + sugar top
		local g = math.max(0.9, h * 0.38)
		local gc = GUM[(i - 1) % #GUM + 1]
		make("Cylinder", name .. "Gumdrop" .. i, Vector3.new(g * 0.8, g * 1.3, g * 1.3), cf * CFrame.new(0, h / 2 + 0.3 + g * 0.4, 0) * CFrame.Angles(0, 0, math.pi / 2), gc, "2022 Big Stud")
		make("Ball", name .. "GumTop" .. i, Vector3.new(g * 1.1, g * 1.1, g * 1.1), cf * CFrame.new(0, h / 2 + 0.3 + g * 0.85, 0), gc, "2022 Big Stud")
		-- sprinkles
		for k = 1, math.floor(len * 1.2) do
			local sx = (rnd() - 0.5) * w * 0.9
			local sz = (rnd() - 0.5) * len * 0.85
			make("Part", "Sprinkle", Vector3.new(0.2, 0.2, 0.6), cf * CFrame.new(sx * 0.6, h / 2 + 0.05, sz) * CFrame.Angles(0, rnd() * math.pi, 0),
				SPRINKLE[math.floor(rnd() * #SPRINKLE) + 1], "2022 Small Stud")
		end
	end
end

-- candy-cane bone: a bone split into alternating red/white bands
local function caneBone(name, a, b, w, bands)
	local dir = b - a
	for k = 0, bands - 1 do
		local pa, pb = a + dir * (k / bands), a + dir * ((k + 1) / bands)
		bone(name .. k, pa, pb, w * (1 - 0.35 * k / bands), w * (1 - 0.35 * k / bands), k % 2 == 0 and C.cane or C.frost, "2022 Small Stud")
	end
end

-- Neon for light only
local function glow(p)
	p.Material = Enum.Material.Neon
	p.MaterialVariant = ""
	return p
end

-- A flat membrane plate fanning from a pivot to the edge between a and b
local function membrane(name, pivot, a, b, colour)
	local m = (a + b) / 2
	local zA = (m - pivot).Unit
	local across = b - a
	local xA = (across - zA * across:Dot(zA)).Unit
	local yA = zA:Cross(xA)
	local len = (m - pivot).Magnitude
	make("Part", name, Vector3.new(math.max(1, across.Magnitude * 0.7), 0.4, len),
		CFrame.fromMatrix((pivot + m) / 2, xA, yA), colour or C.membrane, "2022 Small Stud")
end

local function mir(v, sx)
	return Vector3.new(v.X * sx, v.Y, v.Z)
end

-- BODY: neck, torso and tail as one curve
spine("Body", SPINE, SPINE_W, SPINE_H, C.body)
joint("NeckBase", SPINE[1], 2.8, C.body, "2022 Small Stud")

-- TAIL TIP: a giant swirl lollipop on a white stick
local tip = SPINE[#SPINE]
local stickTop = tip + Vector3.new(1.5, 4.5, 1.5)
bone("LollyStick", tip, stickTop, 0.5, 0.5, C.frost, "2022 Small Stud")
local lollyCF = CFrame.lookAt(stickTop + Vector3.new(0, 2.6, 0), stickTop + Vector3.new(0, 2.6, 0) + Vector3.new(1, 0, -0.6))
make("Cylinder", "LollyDisc", Vector3.new(0.8, 5.6, 5.6), lollyCF * CFrame.Angles(0, math.pi / 2, 0), C.frost, "2022 Small Stud")
local swirlCols = { "Hot pink", "Bright bluish green", "New Yeller", "Bright violet" }
for ring = 1, 4 do
	local d = 5.6 - ring * 1.15
	make("Cylinder", "LollySwirl" .. ring, Vector3.new(0.8 + ring * 0.06, d, d), lollyCF * CFrame.Angles(0, math.pi / 2, 0), swirlCols[ring], "2022 Small Stud")
end
make("Ball", "LollyCenter", Vector3.new(0.9, 0.9, 0.9), lollyCF * CFrame.new(0, 0, -0.5), C.frost)
make("Part", "LollyBow", Vector3.new(1.6, 0.6, 0.6), CFrame.new(stickTop + Vector3.new(0, -0.6, 0)), C.cane, "2022 Big Stud")
make("Ball", "LollyKnot", Vector3.new(0.7, 0.7, 0.7), CFrame.new(stickTop + Vector3.new(0, -0.6, 0)), C.cane)

-- LEGS with feet and claws
for _, sx in ipairs({ -1, 1 }) do
	for li, L in ipairs(LEGS) do
		local top, mid, low, foot = mir(L.top, sx), mir(L.mid, sx), mir(L.low, sx), mir(L.foot, sx)
		bone("UpperLeg" .. li, top, mid, 1.6, 1.6, C.body, "2022 Small Stud")
		bone("LowerLeg" .. li, mid, low, 1.2, 1.2, C.body, "2022 Small Stud")
		joint("Knee" .. li, mid, 1.8, GUM[li + 2], "2022 Big Stud")
		joint("Ankle" .. li, low, 1.6, C.body2)
		make("Part", "Foot" .. li, FOOT, CFrame.new(foot), C.choc, "2022 Big Stud")
		make("Part", "FootIcing" .. li, Vector3.new(FOOT.X + 0.2, 0.3, FOOT.Z + 0.2), CFrame.new(foot + Vector3.new(0, FOOT.Y / 2, 0)), C.frost)
		for _, dx in ipairs({ -0.5, 0, 0.5 }) do
			make("Wedge", "Claw", Vector3.new(0.4, 0.6, 1),
				CFrame.new(foot + Vector3.new(dx, -FOOT.Y / 2 + 0.3, -FOOT.Z / 2 - 0.5)), C.frost, "2022 Small Stud")
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
	joint("WingElbow", elbow, 1.6, "New Yeller", "2022 Big Stud")
	joint("WingWrist", wrist, 1.4, "Bright bluish green", "2022 Big Stud")
	for i, t in ipairs(tips) do
		caneBone("WingFinger" .. i, wrist, t, 0.7, 6)
		make("Ball", "FingerGum" .. i, Vector3.new(1, 1, 1), CFrame.new(t), GUM[i + 3], "2022 Big Stud")
	end
	membrane("Membrane1", wrist, tips[1], tips[2], C.membrane)
	membrane("Membrane2", wrist, tips[2], tips[3], C.membrane2)
	membrane("Membrane3", wrist, tips[3], bodyPt, C.membrane)
	membrane("Membrane4", elbow, root, bodyPt, C.membrane2)
	-- wafer grid lines on the big membranes
	for k = 1, 3 do
		local a = wrist:Lerp(tips[1], k / 4)
		local b = wrist:Lerp(tips[2], k / 4)
		bone("WaferLine", a, b, 0.2, 0.5, C.frost, "2022 Small Stud")
		local c2 = wrist:Lerp(tips[3], k / 4)
		bone("WaferLine2", b, c2, 0.2, 0.5, C.frost, "2022 Small Stud")
	end
	make("Wedge", "ThumbClaw", Vector3.new(0.4, 1, 0.6), CFrame.new(wrist + Vector3.new(0, 1, 0)), C.frost, "2022 Small Stud")
end

-- HEAD
local headCF = CFrame.new(HEAD_POS)
local head = make("Part", "Cranium", CRANIUM, headCF, C.body, "2022 Small Stud")
local snoutCF = headCF * CFrame.new(0, -0.6, -(CRANIUM.Z + SNOUT.Z) / 2)
make("Part", "Snout", SNOUT, snoutCF, C.body, "2022 Small Stud")
local jawCF = headCF * CFrame.new(0, -2.2, -2.5) * CFrame.Angles(math.rad(JAW_DROP), 0, 0)
make("Part", "Jaw", Vector3.new(2.6, 1, 4), jawCF, C.belly)
-- cheek blush
for _, sx in ipairs({ -1, 1 }) do make("Part", "Blush", Vector3.new(0.2, 0.6, 1), headCF * CFrame.new(sx * (CRANIUM.X / 2 + 0.1), -0.4, -1), "Hot pink") end
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
	make("Part", "Brow", Vector3.new(1.6, 0.4, 0.8), headCF * CFrame.new(sx * 1.2, 1.2, -CRANIUM.Z / 2 - 0.1), C.choc, "2022 Small Stud")
	make("Part", "Nostril", Vector3.new(0.4, 0.4, 0.2), headCF * CFrame.new(sx * 0.7, -0.2, snoutFront - 0.1), C.dark, "2022 Small Stud")
	-- horns from two tapering bones
	local hb = headCF:PointToWorldSpace(Vector3.new(sx * 1.2, 1.4, 0.8))
	local hm = headCF:PointToWorldSpace(Vector3.new(sx * 1.8, 2.8, 2.6))
	local ht = headCF:PointToWorldSpace(Vector3.new(sx * 2.1, 3.6, 4.4))
	caneBone("HornBase", hb, hm, 1, 3)
	caneBone("HornTip", hm, ht, 0.7, 3)
	-- candy-cane hook
	local hk = ht + (ht - hm).Unit * 0.6 + Vector3.new(sx * 0.6, -0.8, 0)
	bone("HornHook", ht, hk, 0.5, 0.5, C.cane, "2022 Small Stud")
	-- flowing whiskers
	local wa = headCF:PointToWorldSpace(Vector3.new(sx * 1.5, -0.8, -4.5))
	local wb = headCF:PointToWorldSpace(Vector3.new(sx * 3.5, -2, -2))
	caneBone("Whisker", wa, wb, 0.3, 4)
end
-- crest on the crown
for i, z in ipairs({ -0.5, 1 }) do
	make("Ball", "CrestGum" .. i, Vector3.new(1.2, 1.2, 1.2), headCF * CFrame.new(0, CRANIUM.Y / 2 + 0.4, z), GUM[i * 3], "2022 Big Stud")
end

-- CHERRY on top of the head
make("Ball", "Cherry", Vector3.new(1.4, 1.4, 1.4), headCF * CFrame.new(0, CRANIUM.Y / 2 + 1.3, -1.5), "Really red", "2022 Small Stud")
bone("CherryStem", headCF:PointToWorldSpace(Vector3.new(0, CRANIUM.Y / 2 + 1.9, -1.5)), headCF:PointToWorldSpace(Vector3.new(0.4, CRANIUM.Y / 2 + 3, -1.1)), 0.2, 0.2, "Earth green", "2022 Small Stud")

-- BASE: a round cookie plate with icing rim
make("Cylinder", "Cookie", Vector3.new(1, 22, 22), CFrame.new(0, -0.5, 2) * CFrame.Angles(0, 0, math.pi / 2), C.choc2, "2022 Big Stud")
for i = 1, 14 do
	local a = i / 14 * 2 * math.pi
	make("Ball", "CookieChip", Vector3.new(1, 0.6, 1), CFrame.new(math.cos(a) * 8.5, 0.05, 2 + math.sin(a) * 8.5), C.choc, "2022 Small Stud")
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
print(string.format("CandyDragon built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
