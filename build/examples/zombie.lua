
--[[
	ZOMBIE: a shambling undead figure, about 6 studs wide, 19 tall and 9 deep (arms reaching).
	Faces -Z. Its arms reach forward toward the viewer.
	SUBJECT TYPE: creature, UPRIGHT CHARACTER build (a vertical stack, limbs made with bone()/joint()).
	SIGNATURE FEATURES: green skin with a pale under-tone, both arms reaching forward
	(posed differently), glowing red eyes in black sockets, a gaping toothy mouth,
	a torn blue shirt with exposed ribs, ragged brown trousers and one bare foot.
	Run from the Studio command bar: game:GetObjects is Studio-only.
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
	skin = "Bright green",
	pale = "Sand green",
	shirt = "Bright blue",
	pants = "Reddish brown",
	dark = "Really black",
	glow = "Really red",
	bone = "Light stone grey",
	gore = "Sand red",
}

-- LAYOUT
local HIP_Y = 7
local KNEE_Y = 4
local ANKLE_Y = 1.2
local HIP_X = 1.5
local HIPS_W, HIPS_H, HIPS_D = 5, 2, 3
local HIPS_BOT = HIP_Y - 0.5
local BELT_H = 1
local BELT_BOT = HIPS_BOT + HIPS_H
local CHEST_W, CHEST_H, CHEST_D = 6, 4, 3
local CHEST_BOT = BELT_BOT + BELT_H
local CHEST_TOP = CHEST_BOT + CHEST_H
local NECK_H = 1
local HEAD_W, HEAD_H, HEAD_D = 5, 5, 4
local HEAD_BOT = CHEST_TOP + 0.5
local HEAD_TILT = 8
local SHOULDER_X = CHEST_W / 2 + 0.6
local SHOULDER_Y = CHEST_TOP - 0.6
local LIMB = 1.6
local JOINT_D = 1.9
local FOOT_W, FOOT_H, FOOT_L = 2, 1, 3
local FRONT = -CHEST_D / 2

-- per-side poses: sx = -1 (left) droops and steps forward, sx = 1 (right) reaches high
local ARMS = {
	{ sx = -1, elbow = Vector3.new(-4.4, SHOULDER_Y - 2, -2.2), wrist = Vector3.new(-4.1, SHOULDER_Y - 1.4, -5) },
	{ sx = 1, elbow = Vector3.new(4.2, SHOULDER_Y - 0.4, -3), wrist = Vector3.new(3.7, SHOULDER_Y, -6.2) },
}
local LEGS = {
	{ sx = -1, knee = Vector3.new(-1.7, KNEE_Y, -1.2), ankle = Vector3.new(-1.7, ANKLE_Y, -0.6), bare = false },
	{ sx = 1, knee = Vector3.new(1.7, KNEE_Y, 0.6), ankle = Vector3.new(1.7, ANKLE_Y, 1.1), bare = true },
}
local RAGS = { { x = -1.8, h = 1.2 }, { x = 0.4, h = 1.6 }, { x = 2, h = 1 } }
local RIB_YS = { CHEST_BOT + 0.7, CHEST_BOT + 1.3, CHEST_BOT + 1.9 }
local TEETH_X = { -0.75, -0.25, 0.25, 0.75 }

local model = Instance.new("Model")
model.Name = "Zombie"

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
	return p
end

local function bone(name, a, b, w, h, colour, variant)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	make("Part", name, Vector3.new(w, h, len), cf, colour, variant)
	return cf, len
end

local function joint(name, at, d, colour, variant)
	make("Ball", name, Vector3.new(d, d, d), CFrame.new(at), colour, variant)
end

-- LEGS
for _, lg in ipairs(LEGS) do
	local hip = Vector3.new(lg.sx * HIP_X, HIP_Y, 0)
	joint("Hip", hip, JOINT_D, C.pants)
	bone("Thigh", hip, lg.knee, LIMB, LIMB, C.pants, "2022 Small Stud")
	joint("Knee", lg.knee, JOINT_D, C.pants)
	local shinCol = lg.bare and C.pale or C.pants
	bone("Shin", lg.knee, lg.ankle, LIMB - 0.2, LIMB - 0.2, shinCol)
	local footZ = lg.ankle.Z - FOOT_L / 2 + 0.7
	local footCol = lg.bare and C.pale or C.dark
	make("Part", "Foot", Vector3.new(FOOT_W, FOOT_H, FOOT_L), CFrame.new(lg.ankle.X, FOOT_H / 2, footZ), footCol)
	if lg.bare then
		for t = -1, 1 do
			make("Part", "Toe", Vector3.new(0.4, 0.4, 0.6),
				CFrame.new(lg.ankle.X + t * 0.6, 0.3, footZ - FOOT_L / 2 - 0.3), C.pale, "2022 Small Stud")
		end
	end
end

-- HIPS AND BELT
make("Part", "Hips", Vector3.new(HIPS_W, HIPS_H, HIPS_D), CFrame.new(0, HIPS_BOT + HIPS_H / 2, 0), C.pants, "2022 Small Stud")
make("Part", "Belt", Vector3.new(HIPS_W + 0.4, BELT_H, HIPS_D + 0.2), CFrame.new(0, BELT_BOT + BELT_H / 2, 0), C.dark)
make("Part", "Buckle", Vector3.new(1.2, 0.8, 0.2), CFrame.new(0, BELT_BOT + BELT_H / 2, -(HIPS_D + 0.2) / 2 - 0.1), C.bone, "2022 Small Stud")

-- TORN SHIRT CHEST
local chest = make("Part", "Chest", Vector3.new(CHEST_W, CHEST_H, CHEST_D), CFrame.new(0, CHEST_BOT + CHEST_H / 2, 0), C.shirt, "2022 Small Stud")
make("Part", "BellyPatch", Vector3.new(2.4, 2.2, 0.2), CFrame.new(-1.2, CHEST_BOT + 1.3, FRONT - 0.1), C.pale)
for _, y in ipairs(RIB_YS) do
	make("Part", "Rib", Vector3.new(1.8, 0.3, 0.2), CFrame.new(-1.2, y, FRONT - 0.3), C.bone, "2022 Small Stud")
end
make("Part", "Wound", Vector3.new(1, 1, 0.2), CFrame.new(1.6, CHEST_TOP - 1.2, FRONT - 0.1), C.gore, "2022 Small Stud")
for _, r in ipairs(RAGS) do
	make("Part", "Rag", Vector3.new(1.2, r.h, 0.2), CFrame.new(r.x, CHEST_BOT - r.h / 2 + 0.3, FRONT - 0.1), C.shirt, "2022 Small Stud")
end

-- ARMS, both reaching forward
for _, a in ipairs(ARMS) do
	local sh = Vector3.new(a.sx * SHOULDER_X, SHOULDER_Y, 0)
	joint("Shoulder", sh, JOINT_D, C.shirt)
	bone("UpperArm", sh, a.elbow, LIMB - 0.2, LIMB - 0.2, C.shirt)
	joint("Elbow", a.elbow, JOINT_D - 0.2, C.skin)
	bone("Forearm", a.elbow, a.wrist, LIMB - 0.4, LIMB - 0.4, C.skin)
	local dir = (a.wrist - a.elbow).Unit
	local handCF = CFrame.lookAt(a.wrist, a.wrist + dir) * CFrame.new(0, 0, -0.6)
	make("Part", "Hand", Vector3.new(1.6, 1.2, 1.4), handCF, C.pale)
	for f = -1, 1 do
		make("Part", "Finger", Vector3.new(0.3, 0.3, 0.9), handCF * CFrame.new(f * 0.5, -0.2, -1.1), C.pale, "2022 Small Stud")
	end
end

-- NECK AND HEAD
make("Part", "Neck", Vector3.new(2, NECK_H, 2), CFrame.new(0, CHEST_TOP + NECK_H / 2, 0), C.pale)
local headCF = CFrame.new(0, HEAD_BOT + HEAD_H / 2, 0) * CFrame.Angles(0, 0, math.rad(HEAD_TILT))
make("Part", "Head", Vector3.new(HEAD_W, HEAD_H, HEAD_D), headCF, C.skin)
local face = -HEAD_D / 2
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "Socket", Vector3.new(1.4, 1.2, 0.2), headCF * CFrame.new(sx * 1.1, 0.5, face - 0.1), C.dark, "2022 Small Stud")
	local eye = make("Part", "Eye", Vector3.new(0.6, 0.6, 0.2), headCF * CFrame.new(sx * 1.1, 0.5, face - 0.3), C.glow)
	eye.Material = Enum.Material.Neon
	if sx == 1 then
		local light = Instance.new("PointLight")
		light.Color = eye.Color
		light.Range = 8
		light.Brightness = 2
		light.Parent = eye
	end
	make("Part", "Ear", Vector3.new(0.6, 1.4, 1.2), headCF * CFrame.new(sx * (HEAD_W / 2 + 0.3), 0.2, 0), C.pale, "2022 Small Stud")
end
make("Part", "Brow", Vector3.new(4, 0.6, 0.6), headCF * CFrame.new(0, 1.4, face - 0.3), C.pale, "2022 Small Stud")
make("Part", "Nose", Vector3.new(0.6, 0.6, 0.2), headCF * CFrame.new(0, -0.4, face - 0.1), C.dark, "2022 Small Stud")
make("Part", "Mouth", Vector3.new(2.6, 1.2, 0.2), headCF * CFrame.new(0, -1.5, face - 0.1), C.dark, "2022 Small Stud")
for i, tx in ipairs(TEETH_X) do
	local drop = (i % 2 == 0) and 0.1 or 0
	make("Part", "Tooth", Vector3.new(0.4, 0.5, 0.2), headCF * CFrame.new(tx, -1.15 - drop, face - 0.3), C.bone, "2022 Small Stud")
end
make("Part", "Brain", Vector3.new(2, 0.4, 2), headCF * CFrame.new(1, HEAD_H / 2 + 0.2, 0.4), C.gore, "2022 Small Stud")
make("Part", "CheekWound", Vector3.new(1, 1, 0.2), headCF * CFrame.new(-1.6, -0.9, face - 0.1), C.gore, "2022 Small Stud")

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

model.PrimaryPart = chest
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
print(string.format("Zombie built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))