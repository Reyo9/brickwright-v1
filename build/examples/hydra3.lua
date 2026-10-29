--[[
Hydra Dragon: a four-legged reptilian beast with three serpentine necks and heads.
Size: about 10 studs wide, 25 tall (horns) and 32 long, including the tail. Faces -Z.
SUBJECT TYPE: creature. Build: SKELETON FIRST.
SIGNATURE FEATURES: three separated raised necks with distinct heads (calm, snarling, roaring);
horn shapes that differ per head (swept, tall, curled); folded bat wings along the back;
a bronze-spined tail; sturdy clawed feet. The palette is two-tone: dark teal over a turquoise belly.
Must be run from the Studio command bar, because game:GetObjects is Studio-only.
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
	body = "Bright bluish green",
	belly = "Pastel Blue",
	bronze = "Dark orange",
	horn = "Dark stone grey",
	wing = "Earth green",
	teeth = "White",
	eye = "Bright yellow",
	pupil = "Really black",
	mouth = "Crimson",
}

-- LAYOUT
local BODY_Y = 9
local TAIL_START_Z = 4
local TAIL_L = 15
local TAIL_DROP = 6
local TAIL_SWAY = 2
local TAIL_N = 3
local HEAD_MID = Vector3.new(0, 20, -9)
local NECK_TOP = Vector3.new(0, 16, -8)
local NECK_BASE = Vector3.new(0, 12, -6)
local CHEST = Vector3.new(0, BODY_Y, -2)
local HIPS = Vector3.new(0, BODY_Y, TAIL_START_Z)
local BODY_W = { 2.6, 3, 5, 6, 4, 2.6, 1.6 }
local SIDE_HEAD = Vector3.new(7, 18, -8)
local SIDE_MID = Vector3.new(5, 14.5, -6)
local SIDE_BASE = Vector3.new(2.2, 11, -4.5)
local SIDE_W = { 2, 2.6 }
local HEAD_YAW = 20
local HEADS = {
	{ key = "Mid", sx = 0, open = 25, tilt = 20, horn = "tall" },
	{ key = "Left", sx = -1, open = 8, tilt = -5, horn = "swept" },
	{ key = "Right", sx = 1, open = 40, tilt = 25, horn = "curl" },
}
local HORNS = {
	tall = { Vector3.new(1.3, 3.4, 0.8), Vector3.new(1.0, 5.0, 1.6) },
	swept = { Vector3.new(1.4, 2.6, 1.8), Vector3.new(1.6, 3.0, 3.4) },
	curl = { Vector3.new(2.4, 2.4, 1.0), Vector3.new(2.6, 3.4, -0.4) },
}
local LEGS = {
	{ name = "Fore", top = Vector3.new(3, 8, -2), mid = Vector3.new(3.8, 4.8, -0.8), low = Vector3.new(3.8, 1, -2.6) },
	{ name = "Hind", top = Vector3.new(3, 8, 4.5), mid = Vector3.new(3.8, 5, 2.5), low = Vector3.new(3.8, 1, 6) },
}
local FOOT = Vector3.new(2.4, 1, 3)
local CLAW = Vector3.new(0.5, 0.6, 0.8)
local W_SHOULDER = Vector3.new(2.8, 11.5, -0.5)
local W_ELBOW = Vector3.new(4, 15, 2)
local W_WRIST = Vector3.new(3.6, 13, 9)
local W_F1 = Vector3.new(3.8, 10, 12.5)
local W_F2 = Vector3.new(4, 9.5, 7)
local MEM_X = 3.8
local MEM_T = 0.4

local model = Instance.new("Model")
model.Name = "HydraDragon"
local count = 0

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
	paint(p, colour, variant)
	p.Parent = model
	count = count + 1
	return p
end

-- A bone: a part stretched between two joints a and b (Vector3s), its length
-- along local Z, so a pose is just a list of joint positions. Returns the
-- bone's CFrame and length so plates and spikes can hang off it.
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

-- The body as ONE flowing curve: a bone per pair of points, tapering by the
-- widths and heights tables, with a ball at every bend, a lighter belly plate
-- underneath and a dorsal spike on top (pass nil to skip either).
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

local function mx(v, sx)
	return Vector3.new(v.X * sx, v.Y, v.Z)
end

-- A head: cranium, snout, open jaw, tongue, fangs, glowing eyes, brows, horns
local function head(name, at, yaw, open, tilt, hornType)
	local cf = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
	make("Part", name .. "Cranium", Vector3.new(3, 2.4, 3), cf * CFrame.new(0, 0.6, -0.8), C.body, "2022 Small Stud")
	make("Part", name .. "Snout", Vector3.new(2.2, 1.4, 2.6), cf * CFrame.new(0, 0.3, -3.6), C.body, "2022 Small Stud")
	local jawCf = cf * CFrame.new(0, -0.6, -1.8) * CFrame.Angles(-math.rad(open), 0, 0) * CFrame.new(0, -0.4, -1.4)
	make("Part", name .. "Jaw", Vector3.new(2, 0.8, 2.8), jawCf, C.belly, "2022 Small Stud")
	make("Part", name .. "Tongue", Vector3.new(0.8, 0.2, 1.6), jawCf * CFrame.new(0, 0.5, -0.3), C.mouth, "2022 Small Stud")
	local eye
	for _, sx in ipairs({ -1, 1 }) do
		make("Wedge", name .. "Fang", Vector3.new(0.3, 0.5, 0.4),
			cf * CFrame.new(sx * 0.7, -0.65, -4.4) * CFrame.Angles(math.pi, 0, 0), C.teeth, "2022 Small Stud")
		make("Wedge", name .. "Tooth", Vector3.new(0.3, 0.4, 0.4), jawCf * CFrame.new(sx * 0.6, 0.6, -0.9), C.teeth, "2022 Small Stud")
		eye = make("Part", name .. "Eye", Vector3.new(0.2, 0.6, 0.8), cf * CFrame.new(sx * 1.6, 1.0, -1.6), C.eye, "2022 Small Stud")
		eye.Material = Enum.Material.Neon
		make("Part", name .. "Pupil", Vector3.new(0.2, 0.4, 0.3), cf * CFrame.new(sx * 1.75, 1.0, -1.7), C.pupil, "2022 Small Stud")
		make("Part", name .. "Brow", Vector3.new(1.4, 0.5, 1),
			cf * CFrame.new(sx * 1.0, 1.9, -1.9) * CFrame.Angles(0, 0, sx * math.rad(tilt)), C.horn, "2022 Small Stud")
		local h = HORNS[hornType]
		local a = cf:PointToWorldSpace(Vector3.new(sx * 0.9, 1.8, 0.2))
		local b = cf:PointToWorldSpace(mx(h[1], sx))
		local c = cf:PointToWorldSpace(mx(h[2], sx))
		bone(name .. "Horn", a, b, 0.8, 0.8, C.horn, "2022 Small Stud")
		bone(name .. "HornTip", b, c, 0.5, 0.5, C.bronze, "2022 Small Stud")
	end
	return eye
end

-- BODY: middle neck, torso and tail as one spine
local pts = { HEAD_MID, NECK_TOP, NECK_BASE, CHEST, HIPS }
for i = 1, TAIL_N do
	local t = i / TAIL_N
	table.insert(pts, Vector3.new(TAIL_SWAY * math.sin(t * math.pi), BODY_Y - TAIL_DROP * math.sin(t * math.pi * 0.75), TAIL_START_Z + TAIL_L * t))
end
spine("Body", pts, BODY_W, BODY_W, C.body, C.belly, C.bronze)
-- Tail tip blade
local tip, pre = pts[#pts], pts[#pts - 1]
make("Wedge", "TailBlade", Vector3.new(1, 2, 2), CFrame.lookAt(tip, tip + (tip - pre)) * CFrame.Angles(0, math.pi, 0), C.bronze, "2022 Big Stud")

-- SIDE NECKS
for _, sx in ipairs({ -1, 1 }) do
	spine(sx < 0 and "NeckL" or "NeckR", { mx(SIDE_HEAD, sx), mx(SIDE_MID, sx), mx(SIDE_BASE, sx) }, SIDE_W, SIDE_W, C.body, C.belly, C.bronze)
end

-- HEADS, each with its own expression and horns
for _, hd in ipairs(HEADS) do
	local at = HEAD_MID
	if hd.sx ~= 0 then at = mx(SIDE_HEAD, hd.sx) end
	local eye = head(hd.key, at, -hd.sx * math.rad(HEAD_YAW), hd.open, hd.tilt, hd.horn)
	if hd.sx == 0 then
		local l = Instance.new("PointLight")
		l.Color = BrickColor.new(C.eye).Color
		l.Range = 8
		l.Brightness = 2
		l.Parent = eye
	end
end

-- LEGS with feet and claws
for _, leg in ipairs(LEGS) do
	for _, sx in ipairs({ -1, 1 }) do
		local a, b, c = mx(leg.top, sx), mx(leg.mid, sx), mx(leg.low, sx)
		joint(leg.name .. "Shoulder", a, 3, C.body, "2022 Small Stud")
		bone(leg.name .. "Upper", a, b, 2.4, 2.4, C.body, "2022 Small Stud")
		joint(leg.name .. "Knee", b, 2.6, C.body, "2022 Small Stud")
		bone(leg.name .. "Lower", b, c, 2, 2, C.body, "2022 Small Stud")
		local footZ = c.Z - FOOT.Z / 3
		make("Part", leg.name .. "Foot", FOOT, CFrame.new(c.X, FOOT.Y / 2, footZ), C.belly)
		for k = -1, 1 do
			make("Wedge", leg.name .. "Claw", CLAW,
				CFrame.new(c.X + k * (FOOT.X / 3), CLAW.Y / 2, footZ - FOOT.Z / 2 - CLAW.Z / 2), C.horn, "2022 Small Stud")
		end
	end
end

-- WINGS folded along the back
for _, sx in ipairs({ -1, 1 }) do
	local s, e, w = mx(W_SHOULDER, sx), mx(W_ELBOW, sx), mx(W_WRIST, sx)
	bone("WingArm", s, e, 1, 1, C.body, "2022 Small Stud")
	joint("WingElbow", e, 1.4, C.bronze, "2022 Big Stud")
	bone("WingFore", e, w, 0.8, 0.8, C.body, "2022 Small Stud")
	bone("WingFinger", w, mx(W_F1, sx), 0.4, 0.4, C.horn, "2022 Small Stud")
	bone("WingFinger", w, mx(W_F2, sx), 0.4, 0.4, C.horn, "2022 Small Stud")
	make("Wedge", "WingThumb", Vector3.new(0.4, 0.6, 0.8), CFrame.lookAt(w, w + (w - e)) * CFrame.new(0, 0.5, -0.4), C.bronze, "2022 Small Stud")

	-- Membrane panels: thin vertical plates hung beneath each wing bone,
	-- all pulled onto one plane at MEM_X so the folded wing reads as a single sheet.
	local function membrane(name, a, b, drop)
		local pa = Vector3.new(sx * MEM_X, a.Y, a.Z)
		local pb = Vector3.new(sx * MEM_X, b.Y, b.Z)
		local len = (pb - pa).Magnitude
		local cf = CFrame.lookAt((pa + pb) / 2, pb)
		make("Part", name, Vector3.new(MEM_T, drop, len), cf * CFrame.new(0, -drop / 2, 0), C.wing, "2022 Small Stud")
	end
	membrane("WingMemArm", s, e, 2)
	membrane("WingMemFore", e, w, 3)
	membrane("WingMemOuter", w, mx(W_F1, sx), 2)
	membrane("WingMemInner", w, mx(W_F2, sx), 2)
end

-- BRONZE ACCENTS: a collar band at each neck base and a chest plate
for _, sx in ipairs({ -1, 0, 1 }) do
	local at = sx == 0 and NECK_BASE or mx(SIDE_BASE, sx)
	make("Cylinder", "NeckCollar", Vector3.new(0.6, 2.8, 2.8),
		CFrame.new(at) * CFrame.Angles(0, 0, math.pi / 2), C.bronze, "2022 Small Stud")
end
make("Part", "ChestPlate", Vector3.new(2, 2, 0.4), CFrame.lookAt(CHEST, CHEST + Vector3.new(0, -0.5, -1)) * CFrame.new(0, -1, -2.6), C.bronze, "2022 Small Stud")

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
model.PrimaryPart = model:FindFirstChild("Body4")
print("Built HydraDragon with " .. count .. " parts")
