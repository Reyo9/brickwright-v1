--[[
	Boxy Robot — a simple retro toy robot with two glowing eyes.
	Size: about 13 studs wide (arms out) x 19 tall x 5 deep. Faces -Z.
	SUBJECT TYPE: creature / UPRIGHT CHARACTER (stands on two legs like a person).
	SIGNATURE FEATURES: big square head with a black visor and two glowing
	yellow eyes, a boxy torso with a blue chest panel, an antenna with a glowing
	tip, chunky jointed arms (one raised in a wave), and blocky feet.
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
	body = "Medium stone grey",
	dark = "Dark stone grey",
	panel = "Bright blue",
	glow = "Bright yellow",
	visor = "Really black",
}

-- LAYOUT
local FOOT_W, FOOT_H, FOOT_L = 2, 1, 3.5
local HIP_X = 1.25
local HIP_Y = 6
local KNEE_Y, KNEE_Z = 3.5, -0.6
local LEG_T = 1.4
local JOINT_D = 1.8
local PELVIS_W, PELVIS_H, PELVIS_D = 4, 1, 3
local TORSO_W, TORSO_H, TORSO_D = 6, 5, 4
local TORSO_Y0 = HIP_Y + PELVIS_H
local NECK_W, NECK_H = 2, 1
local NECK_Y0 = TORSO_Y0 + TORSO_H
local HEAD_W, HEAD_H, HEAD_D = 5, 4, 4
local HEAD_Y0 = NECK_Y0 + NECK_H
local EYE_Y = HEAD_Y0 + HEAD_H * 0.6
local EYE_X = 1
local ANT_H = 1.5
local SHOULDER_X = TORSO_W / 2 + 0.5
local SHOULDER_Y = TORSO_Y0 + TORSO_H - 0.5
local ARM_T = 1.4
local HAND = 1.6

local model = Instance.new("Model")
model.Name = "BoxyRobot"

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

-- A bone stretched between two joints, length along local Z.
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

-- LEGS
for _, sx in ipairs({ -1, 1 }) do
	local hip = Vector3.new(sx * HIP_X, HIP_Y, 0)
	local knee = Vector3.new(sx * HIP_X, KNEE_Y, KNEE_Z)
	local ankle = Vector3.new(sx * HIP_X, FOOT_H, 0)
	joint("Hip", hip, JOINT_D, C.dark)
	bone("Thigh", hip, knee, LEG_T, LEG_T, C.body)
	joint("Knee", knee, JOINT_D, C.dark)
	bone("Shin", knee, ankle, LEG_T, LEG_T, C.body)
	make("Part", "Foot", Vector3.new(FOOT_W, FOOT_H, FOOT_L),
		CFrame.new(sx * HIP_X, FOOT_H / 2, -0.5), C.dark)
end

-- PELVIS, TORSO, NECK
make("Part", "Pelvis", Vector3.new(PELVIS_W, PELVIS_H, PELVIS_D),
	CFrame.new(0, HIP_Y + PELVIS_H / 2, 0), C.dark)
local torso = make("Part", "Torso", Vector3.new(TORSO_W, TORSO_H, TORSO_D),
	CFrame.new(0, TORSO_Y0 + TORSO_H / 2, 0), C.body, "2022 Small Stud")
local panel = make("Part", "ChestPanel", Vector3.new(3, 2, 0.2),
	torso.CFrame * CFrame.new(0, 0.5, -TORSO_D / 2 - 0.1), C.panel, "2022 Big Stud")
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "Button", Vector3.new(0.6, 0.6, 0.2),
		panel.CFrame * CFrame.new(sx * 0.7, 0, -0.2), C.glow, "2022 Small Stud")
end
make("Part", "Neck", Vector3.new(NECK_W, NECK_H, NECK_W),
	CFrame.new(0, NECK_Y0 + NECK_H / 2, 0), C.dark)

-- HEAD AND FACE
local head = make("Part", "Head", Vector3.new(HEAD_W, HEAD_H, HEAD_D),
	CFrame.new(0, HEAD_Y0 + HEAD_H / 2, 0), C.body, "2022 Small Stud")
local visor = make("Part", "Visor", Vector3.new(HEAD_W - 1, 1.4, 0.2),
	CFrame.new(0, EYE_Y, -HEAD_D / 2 - 0.1), C.visor)
for _, sx in ipairs({ -1, 1 }) do
	local eye = make("Part", "Eye", Vector3.new(1, 0.8, 0.2),
		visor.CFrame * CFrame.new(sx * EYE_X, 0, -0.2), C.glow)
	eye.Material = Enum.Material.Neon
	if sx == 1 then
		local light = Instance.new("PointLight")
		light.Color = eye.Color
		light.Range = 10
		light.Brightness = 2
		light.Parent = eye
	end
end
make("Part", "Mouth", Vector3.new(2.4, 0.4, 0.2),
	head.CFrame * CFrame.new(0, -1.2, -HEAD_D / 2 - 0.1), C.visor, "2022 Small Stud")
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "Ear", Vector3.new(0.4, 1.4, 1.4),
		head.CFrame * CFrame.new(sx * (HEAD_W / 2 + 0.2), 0.3, 0), C.dark, "2022 Small Stud")
end
make("Part", "Antenna", Vector3.new(0.4, ANT_H, 0.4),
	CFrame.new(0, HEAD_Y0 + HEAD_H + ANT_H / 2, 0), C.dark, "2022 Small Stud")
local tip = make("Ball", "AntennaTip", Vector3.new(0.8, 0.8, 0.8),
	CFrame.new(0, HEAD_Y0 + HEAD_H + ANT_H + 0.3, 0), C.glow)
tip.Material = Enum.Material.Neon

-- ARMS: left raised in a wave, right held out to the side
local arms = {
	{ sx = -1, elbow = Vector3.new(-SHOULDER_X - 1.5, SHOULDER_Y + 1.5, -1), wrist = Vector3.new(-SHOULDER_X - 2, SHOULDER_Y + 4, -2) },
	{ sx = 1, elbow = Vector3.new(SHOULDER_X + 2, SHOULDER_Y - 2, -0.5), wrist = Vector3.new(SHOULDER_X + 2.5, SHOULDER_Y - 4, -2) },
}
for _, a in ipairs(arms) do
	local sh = Vector3.new(a.sx * SHOULDER_X, SHOULDER_Y, 0)
	joint("Shoulder", sh, JOINT_D, C.dark)
	bone("UpperArm", sh, a.elbow, ARM_T, ARM_T, C.body)
	joint("Elbow", a.elbow, JOINT_D, C.dark)
	bone("Forearm", a.elbow, a.wrist, ARM_T, ARM_T, C.body)
	make("Part", "Hand", Vector3.new(HAND, HAND, HAND), CFrame.new(a.wrist), C.dark)
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

model.PrimaryPart = torso
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
print(string.format("BoxyRobot built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
