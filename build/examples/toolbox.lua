--[[
	WOODEN TOOLBOX - retro Roblox build.
	SUBJECT TYPE: hard-surface item (a single object), so no display stand.
	Size: about 15 studs wide (X), 9 deep (Z) and 14 tall to the top of the rope handle.
	Faces -Z: the clasp is on the front (-Z) face and the hinges are on the back (+Z).
	SIGNATURE FEATURES: a plank-banded wooden body, a lid that overhangs the body with
	barrel hinges at the back, a big metal clasp on the front, a thick arched rope
	handle on two metal brackets, and metal corner brackets with rivets.
	The rope arc is a soft material, so its segments follow computed curve points.
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
	wood = "Brown",
	woodDark = "Reddish brown",
	metal = "Dark stone grey",
	steel = "Light stone grey",
	rope = "Cork",
}

-- LAYOUT
local W, D = 14, 8
local SKID_H = 1
local PLANK_H, PLANKS = 2, 3
local BODY_H = PLANK_H * PLANKS
local BODY_TOP = SKID_H + BODY_H
local LID_H = 2
local LID_W, LID_D = W + 1, D + 1
local LID_TOP = BODY_TOP + LID_H
local STRAP_X = 4.5
local HINGE_X = STRAP_X
local ROPE_R = 3
local ROPE_Y = LID_TOP + 1.2
local ROPE_RISE = 3
local ROPE_SEGS = 6
local ROPE_T = 1.2
local FRONT_Z = -D / 2
local BACK_Z = D / 2

local model = Instance.new("Model")
model.Name = "WoodenToolbox"

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
		if kind == "Cylinder" then
			p.Shape = Enum.PartType.Cylinder
		elseif kind == "Ball" then
			p.Shape = Enum.PartType.Ball
		end
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

local ALONG_Z = CFrame.Angles(0, math.rad(90), 0)

-- SKIDS under the body
for _, sz in ipairs({ -1, 1 }) do
	make("Part", "Skid", Vector3.new(W - 1, SKID_H, 1.5),
		CFrame.new(0, SKID_H / 2, sz * (D / 2 - 1.5)), C.woodDark)
end

-- BODY: stacked planks in alternating tones
local firstPlank
for i = 1, PLANKS do
	local col = (i % 2 == 1) and C.wood or C.woodDark
	local p = make("Part", "Plank" .. i, Vector3.new(W, PLANK_H, D),
		CFrame.new(0, SKID_H + (i - 0.5) * PLANK_H, 0), col, "2022 Small Stud")
	if i == 1 then firstPlank = p end
end

-- LID overhanging the body
make("Part", "Lid", Vector3.new(LID_W, LID_H, LID_D),
	CFrame.new(0, BODY_TOP + LID_H / 2, 0), C.woodDark, "2022 Big Stud")

-- CORNER BRACKETS with rivets on the front pair
for _, sx in ipairs({ -1, 1 }) do
	for _, sz in ipairs({ -1, 1 }) do
		make("Part", "BracketFace", Vector3.new(1, BODY_H, 0.2),
			CFrame.new(sx * (W / 2 - 0.5), SKID_H + BODY_H / 2, sz * (D / 2 + 0.1)), C.metal)
		make("Part", "BracketSide", Vector3.new(0.2, BODY_H, 1),
			CFrame.new(sx * (W / 2 + 0.1), SKID_H + BODY_H / 2, sz * (D / 2 - 0.5)), C.metal)
	end
	for _, ry in ipairs({ SKID_H + 1, BODY_TOP - 1 }) do
		make("Ball", "Rivet", Vector3.new(0.4, 0.4, 0.4),
			CFrame.new(sx * (W / 2 - 0.5), ry, FRONT_Z - 0.25), C.steel, "2022 Small Stud")
	end
	-- end cleat grip
	make("Part", "EndCleat", Vector3.new(1, 1, 4),
		CFrame.new(sx * (W / 2 + 0.5), BODY_TOP - 1.5, 0), C.woodDark)
end

-- LID STRAPS running into the back hinges
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "StrapTop", Vector3.new(1, 0.2, LID_D + 0.4),
		CFrame.new(sx * STRAP_X, LID_TOP + 0.1, 0), C.metal)
	make("Part", "StrapFront", Vector3.new(1, LID_H, 0.2),
		CFrame.new(sx * STRAP_X, BODY_TOP + LID_H / 2, -LID_D / 2 - 0.1), C.metal)
	-- hinge: barrel plus two leaves
	make("Cylinder", "HingeBarrel", Vector3.new(2, 0.8, 0.8),
		CFrame.new(sx * HINGE_X, BODY_TOP, LID_D / 2), C.steel, "2022 Small Stud")
	make("Part", "HingeLeafBody", Vector3.new(1.6, 1.2, 0.2),
		CFrame.new(sx * HINGE_X, BODY_TOP - 0.8, BACK_Z + 0.1), C.metal, "2022 Small Stud")
	make("Part", "HingeLeafLid", Vector3.new(1.6, 1, 0.2),
		CFrame.new(sx * HINGE_X, LID_TOP - 0.7, LID_D / 2 + 0.1), C.metal, "2022 Small Stud")
end

-- FRONT CLASP: base plate, hasp from the lid, tongue, staple and knob
make("Part", "ClaspPlate", Vector3.new(2.4, 2, 0.2),
	CFrame.new(0, BODY_TOP - 1.4, FRONT_Z - 0.1), C.metal)
make("Part", "Hasp", Vector3.new(1.6, LID_H, 0.2),
	CFrame.new(0, BODY_TOP + LID_H / 2, -LID_D / 2 - 0.1), C.steel)
make("Part", "HaspTongue", Vector3.new(1.6, 1.6, 0.6),
	CFrame.new(0, BODY_TOP - 0.8, FRONT_Z - 0.3), C.steel)
make("Cylinder", "Staple", Vector3.new(0.6, 0.8, 0.8),
	CFrame.new(0, BODY_TOP - 0.8, FRONT_Z - 0.9) * ALONG_Z, C.metal, "2022 Small Stud")
make("Ball", "ClaspKnob", Vector3.new(0.6, 0.6, 0.6),
	CFrame.new(0, BODY_TOP - 0.8, FRONT_Z - 1.3), C.steel, "2022 Small Stud")
for _, sx in ipairs({ -1, 1 }) do
	make("Ball", "ClaspScrew", Vector3.new(0.4, 0.4, 0.4),
		CFrame.new(sx * 0.9, BODY_TOP - 2, FRONT_Z - 0.25), C.steel, "2022 Small Stud")
end

-- NAMEPLATE on the lower plank
make("Part", "Nameplate", Vector3.new(3, 1, 0.2),
	CFrame.new(0, SKID_H + PLANK_H / 2, FRONT_Z - 0.1), C.steel, "2022 Small Stud")

-- ROPE HANDLE: brackets, arched rope, knots
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "RopeBracket", Vector3.new(1, 2, 2),
		CFrame.new(sx * ROPE_R, LID_TOP + 1, 0), C.metal)
	make("Cylinder", "BracketBolt", Vector3.new(0.2, 0.8, 0.8),
		CFrame.new(sx * ROPE_R, LID_TOP + 1.2, -1.1) * ALONG_Z, C.steel, "2022 Small Stud")
	make("Ball", "RopeKnot", Vector3.new(1.6, 1.6, 1.6),
		CFrame.new(sx * (ROPE_R + 1.3), ROPE_Y, 0), C.rope, "2022 Weld")
end

local pts = {}
for i = 0, ROPE_SEGS do
	local a = math.pi * i / ROPE_SEGS
	table.insert(pts, Vector3.new(-ROPE_R * math.cos(a), ROPE_Y + ROPE_RISE * math.sin(a), 0))
end
for i = 1, #pts - 1 do
	local a, b = pts[i], pts[i + 1]
	local len = (b - a).Magnitude
	make("Part", "Rope" .. i, Vector3.new(ROPE_T, ROPE_T, len + 0.2),
		CFrame.lookAt((a + b) / 2, b), C.rope, "2022 Weld")
	if i > 1 then
		make("Ball", "RopeBend" .. i, Vector3.new(ROPE_T + 0.2, ROPE_T + 0.2, ROPE_T + 0.2),
			CFrame.new(a), C.rope, "2022 Weld")
	end
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

model.PrimaryPart = firstPlank
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
print(string.format("WoodenToolbox built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
