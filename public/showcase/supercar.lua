--[[
	Agera-style supercar (retro Roblox brick build)
	SUBJECT TYPE: vehicle (sports car); built from solid masses, no wall() helper.
	Size: about 8 wide x 7 tall x 21 long studs. Faces -Z, so the nose points toward -Z.
	SIGNATURE FEATURES: a long, low silver wedge body with a sloping hood;
	  a short dark bubble cabin with a raked windshield and a fastback deck;
	  two thin blue stripes running over the hood, roof, fastback and spoiler;
	  big black wheels with yellow rim rings; and a small rear spoiler on uprights.
	Treatment: retro 2008 Roblox, BrickColor names only, studded Glacier variants.
	Run this from the Studio command bar: game:GetObjects only works in Studio.
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
	stripe = "Medium blue",
	glass = "Black",
	trim = "Really black",
	tyre = "Really black",
	hub = "Black",
	rim = "Bright yellow",
	metal = "Dark stone grey",
	lamp = "Institutional white",
	tail = "Really red",
	signal = "Bright orange",
}

-- LAYOUT
local W, L = 8, 20
local WHEEL_D, WHEEL_W = 3.6, 1.4
local AXLE_F_Z = -L / 2 + 4
local AXLE_R_Z = L / 2 - 4
local SILL = WHEEL_D / 2
local LOWER_H = 2
local LOWER_TOP = SILL + LOWER_H
local HOOD_L, HOOD_RISE = 7, 1
local HOOD_TOP = LOWER_TOP + HOOD_RISE
local WS_L = 2
local CAB_W = 6
local CAB_H = 2
local CAB_START = -L / 2 + HOOD_L + WS_L
local CAB_L = 5
local CAB_END = CAB_START + CAB_L
local CAB_TOP = LOWER_TOP + CAB_H
local ROOF_T = 1
local ROOF_TOP = CAB_TOP + ROOF_T
local DECK_TOP = LOWER_TOP + 1
local FB_L = 4
local FB_RISE = ROOF_TOP - DECK_TOP
local STRIPE_X = 1
local SPOILER_Z = L / 2 - 1
local SPOILER_UP = 1.2
local FRONT_Z = -L / 2
local REAR_Z = L / 2

local model = Instance.new("Model")
model.Name = "Supercar"

local function paint(p, colour, variant)
	p.BrickColor = BrickColor.new(colour)
	if studsLoaded then
		p.Material = Enum.Material.Glacier
		p.MaterialVariant = variant or "2022 Universal"
	else
		p.Material = Enum.Material.SmoothPlastic
	end
end

local function make(kind, name, size, cf, colour, variant)
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
	p.CFrame = cf
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	paint(p, colour, variant)
	p.Parent = model
	return p
end

-- A wheel standing upright, axle along X: a tyre plus a hubcap disc on its outer face.
-- x is the tyre centre (its sign picks the side), z the axle position, d the diameter,
-- w the tyre width. It rests on y = 0. NEVER rotate a wheel: a Cylinder's axis is
-- already X, and turning it 90 degrees lays it flat like a coin.
local function wheel(name, x, z, d, w, tyreColour, hubColour)
	local side = (x < 0) and -1 or 1
	make("Cylinder", name .. "Tyre", Vector3.new(w, d, d), CFrame.new(x, d / 2, z), tyreColour)
	local hub = math.max(2, math.floor(d * 0.55))
	make("Cylinder", name .. "Hub", Vector3.new(0.2, hub, hub),
		CFrame.new(x + side * (w / 2 + 0.1), d / 2, z), hubColour, "2022 Big Stud")
end

-- Thin glowing light part
local function glow(name, size, cf, colour, withLight)
	local p = make("Part", name, size, cf, colour, "2022 Small Stud")
	p.Material = Enum.Material.Neon
	if withLight then
		local l = Instance.new("PointLight")
		l.Color = p.Color
		l.Range = 8
		l.Brightness = 1.5
		l.Parent = p
	end
	return p
end

-- CHASSIS
make("Part", "Chassis", Vector3.new(W - 2, 1, L - 4), CFrame.new(0, SILL - 0.5, 0), C.trim, "2022 Glue")

-- MAIN MASSES
local lower = make("Part", "LowerBody", Vector3.new(W, LOWER_H, L), CFrame.new(0, SILL + LOWER_H / 2, 0), C.body, "2022 Small Stud")
local hoodCF = CFrame.new(0, LOWER_TOP + HOOD_RISE / 2, FRONT_Z + HOOD_L / 2)
make("Wedge", "Hood", Vector3.new(W, HOOD_RISE, HOOD_L), hoodCF, C.body, "2022 Small Stud")
make("Part", "Cowl", Vector3.new(W, HOOD_RISE, WS_L), CFrame.new(0, LOWER_TOP + HOOD_RISE / 2, FRONT_Z + HOOD_L + WS_L / 2), C.body, "2022 Small Stud")
make("Part", "RearDeck", Vector3.new(W, DECK_TOP - LOWER_TOP, REAR_Z - CAB_END),
	CFrame.new(0, (LOWER_TOP + DECK_TOP) / 2, (CAB_END + REAR_Z) / 2), C.body, "2022 Small Stud")
local fbCF = CFrame.new(0, DECK_TOP + FB_RISE / 2, CAB_END + FB_L / 2) * CFrame.Angles(0, math.pi, 0)
make("Wedge", "Fastback", Vector3.new(CAB_W, FB_RISE, FB_L), fbCF, C.body, "2022 Small Stud")

-- GREENHOUSE
make("Wedge", "Windshield", Vector3.new(CAB_W, CAB_TOP - HOOD_TOP, WS_L),
	CFrame.new(0, (HOOD_TOP + CAB_TOP) / 2, CAB_START - WS_L / 2), C.glass, "2022 Glue")
make("Part", "CabinGlass", Vector3.new(CAB_W - 0.4, CAB_H, CAB_L),
	CFrame.new(0, LOWER_TOP + CAB_H / 2, CAB_START + CAB_L / 2), C.glass, "2022 Glue")
make("Part", "Roof", Vector3.new(CAB_W, ROOF_T, CAB_L), CFrame.new(0, CAB_TOP + ROOF_T / 2, CAB_START + CAB_L / 2), C.body, "2022 Small Stud")
local pillarZ = { CAB_START + 0.6, CAB_START + CAB_L / 2, CAB_END - 0.6 }
for _, sx in ipairs({ -1, 1 }) do
	for i, z in ipairs(pillarZ) do
		make("Part", "Pillar" .. i, Vector3.new(1, CAB_H, 1), CFrame.new(sx * (CAB_W / 2 - 0.5), LOWER_TOP + CAB_H / 2, z), C.body)
	end
end

-- WHEELS with yellow rim rings
for _, z in ipairs({ AXLE_F_Z, AXLE_R_Z }) do
	for _, sx in ipairs({ -1, 1 }) do
		wheel("Wheel", sx * W / 2, z, WHEEL_D, WHEEL_W, C.tyre, C.hub)
		make("Cylinder", "RimRing", Vector3.new(0.2, WHEEL_D - 0.8, WHEEL_D - 0.8),
			CFrame.new(sx * (W / 2 + WHEEL_W / 2 + 0.05), WHEEL_D / 2, z), C.rim, "2022 Small Stud")
		make("Cylinder", "HubCap", Vector3.new(0.2, 0.6, 0.6),
			CFrame.new(sx * (W / 2 + WHEEL_W / 2 + 0.3), WHEEL_D / 2, z), C.metal, "2022 Small Stud")
	end
end

-- BLUE STRIPES over hood, roof, fastback and wing (laid along each slope with atan)
local hoodAng = math.atan(HOOD_RISE / HOOD_L)
local hoodSlope = math.sqrt(HOOD_RISE * HOOD_RISE + HOOD_L * HOOD_L)
local fbAng = math.atan(FB_RISE / FB_L)
local fbSlope = math.sqrt(FB_RISE * FB_RISE + FB_L * FB_L)
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "HoodStripe", Vector3.new(1, 0.2, hoodSlope),
		hoodCF * CFrame.new(sx * STRIPE_X, 0, 0) * CFrame.Angles(-hoodAng, 0, 0) * CFrame.new(0, 0.15, 0), C.stripe, "2022 Big Stud")
	make("Part", "RoofStripe", Vector3.new(1, 0.2, CAB_L),
		CFrame.new(sx * STRIPE_X, ROOF_TOP + 0.1, CAB_START + CAB_L / 2), C.stripe, "2022 Big Stud")
	make("Part", "FastbackStripe", Vector3.new(1, 0.2, fbSlope),
		fbCF * CFrame.new(sx * STRIPE_X, 0, 0) * CFrame.Angles(-fbAng, 0, 0) * CFrame.new(0, 0.15, 0), C.stripe, "2022 Big Stud")
end
make("Part", "HoodVent", Vector3.new(1, 0.2, 2),
	hoodCF * CFrame.Angles(-hoodAng, 0, 0) * CFrame.new(0, 0.15, hoodSlope / 2 - 1.5), C.trim, "2022 Small Stud")

-- FRONT END
make("Part", "Splitter", Vector3.new(W, 0.4, 1.5), CFrame.new(0, SILL - 0.2, FRONT_Z + 0.25), C.trim)
make("Part", "Grille", Vector3.new(4, 1, 0.2), CFrame.new(0, SILL + 0.6, FRONT_Z - 0.1), C.trim, "2022 Small Stud")
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "SideIntake", Vector3.new(1.2, 1, 0.2), CFrame.new(sx * 3, SILL + 0.6, FRONT_Z - 0.1), C.trim, "2022 Small Stud")
	make("Part", "LampHousing", Vector3.new(1.8, 0.6, 0.2), CFrame.new(sx * 2.6, LOWER_TOP - 0.4, FRONT_Z - 0.1), C.trim, "2022 Small Stud")
	glow("HeadLens", Vector3.new(1.4, 0.4, 0.2), CFrame.new(sx * 2.6, LOWER_TOP - 0.4, FRONT_Z - 0.3), C.lamp, sx > 0)
	make("Part", "Signal", Vector3.new(0.6, 0.4, 0.2), CFrame.new(sx * 1.2, LOWER_TOP - 0.4, FRONT_Z - 0.1), C.signal, "2022 Small Stud")
	make("Part", "Wiper", Vector3.new(1.4, 0.2, 0.2), CFrame.new(sx * 1.2, HOOD_TOP + 0.1, CAB_START - WS_L + 0.3), C.trim, "2022 Small Stud")
end

-- SIDES: mirrors, skirts, intakes, handles
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "MirrorStem", Vector3.new(0.6, 0.3, 0.3), CFrame.new(sx * (CAB_W / 2 + 0.3), LOWER_TOP + 0.8, pillarZ[1]), C.trim, "2022 Small Stud")
	make("Part", "MirrorHead", Vector3.new(0.4, 0.6, 0.8), CFrame.new(sx * (CAB_W / 2 + 0.8), LOWER_TOP + 0.8, pillarZ[1]), C.body, "2022 Small Stud")
	make("Part", "SideSkirt", Vector3.new(0.2, 1, 8), CFrame.new(sx * (W / 2 + 0.1), SILL + 0.5, 0), C.trim)
	make("Part", "SideScoop", Vector3.new(0.2, 1, 3), CFrame.new(sx * (W / 2 + 0.1), SILL + 1.5, 2), C.trim)
	make("Part", "DoorHandle", Vector3.new(0.2, 0.3, 0.6), CFrame.new(sx * (W / 2 + 0.1), LOWER_TOP - 0.4, -0.5), C.metal, "2022 Small Stud")
end

-- REAR END
make("Part", "Diffuser", Vector3.new(W - 2, 1, 0.2), CFrame.new(0, SILL + 0.5, REAR_Z + 0.1), C.trim)
for i = 1, 4 do
	make("Part", "DiffuserFin", Vector3.new(0.2, 0.8, 0.6), CFrame.new(-2.25 + (i - 1) * 1.5, SILL + 0.4, REAR_Z + 0.4), C.metal, "2022 Small Stud")
end
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "TailHousing", Vector3.new(2, 0.6, 0.2), CFrame.new(sx * 2.6, LOWER_TOP - 0.4, REAR_Z + 0.1), C.trim, "2022 Small Stud")
	glow("TailLamp", Vector3.new(1.6, 0.4, 0.2), CFrame.new(sx * 2.6, LOWER_TOP - 0.4, REAR_Z + 0.3), C.tail, sx > 0)
	make("Part", "RearSignal", Vector3.new(0.4, 0.4, 0.2), CFrame.new(sx * 1.3, LOWER_TOP - 0.4, REAR_Z + 0.1), C.signal, "2022 Small Stud")
	make("Cylinder", "Exhaust", Vector3.new(0.6, 0.6, 0.6),
		CFrame.new(sx * 0.6, SILL + 0.4, REAR_Z + 0.3) * CFrame.Angles(0, math.pi / 2, 0), C.metal, "2022 Small Stud")
end
make("Part", "Plate", Vector3.new(2, 0.6, 0.2), CFrame.new(0, LOWER_TOP - 0.4, REAR_Z + 0.1), C.lamp, "2022 Small Stud")

-- REAR SPOILER on two uprights, stripes carried over the wing
for _, sx in ipairs({ -1, 1 }) do
	make("Part", "SpoilerUpright", Vector3.new(1, SPOILER_UP, 1),
		CFrame.new(sx * 2.5, DECK_TOP + SPOILER_UP / 2, SPOILER_Z), C.trim, "2022 Glue")
	make("Part", "WingEndplate", Vector3.new(0.2, 1, 2),
		CFrame.new(sx * (W / 2 + 0.1), DECK_TOP + SPOILER_UP + 0.2, SPOILER_Z), C.trim, "2022 Small Stud")
	make("Part", "WingStripe", Vector3.new(1, 0.2, 2),
		CFrame.new(sx * STRIPE_X, DECK_TOP + SPOILER_UP + 0.5, SPOILER_Z), C.stripe, "2022 Big Stud")
end
make("Part", "Wing", Vector3.new(W, 0.4, 2), CFrame.new(0, DECK_TOP + SPOILER_UP + 0.2, SPOILER_Z), C.body, "2022 Small Stud")

-- FINISH
local partCount = 0
for _, d in ipairs(model:GetDescendants()) do
	if d:IsA("BasePart") then partCount = partCount + 1 end
end
model.PrimaryPart = lower
-- Stud guarantee: keeps a chosen variant if the pack has it, else Universal; thin Neon keeps glowing.
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

-- Wheel check: a wheel's axle runs along its local X; if one lies flat like a coin, stand it back up.
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
print(("Built %s: %d parts (studs %s)"):format(model.Name, partCount, studsLoaded and "on" or "off"))
