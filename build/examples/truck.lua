-- Classic Pickup Truck
-- Method: CHASSIS — wheels on the ground, chassis on the wheels, body on the chassis, cab and bed on the body.
-- Front of the vehicle = -Z, back = +Z, width along X.
local model = Instance.new("Model")
model.Name = "PickupTruck"

local GROUND = 0
local RED, WHITE, CHROME = "Bright red", "Institutional white", "Light stone grey"

local function part(name, size, cf, color, mat, cls)
	local p = Instance.new(cls or "Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.BrickColor = BrickColor.new(color)
	p.Material = mat or Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Inlet
	p.Parent = model
	return p
end
local function onTop(name, size, x, yBottom, z, color, mat)
	return part(name, size, CFrame.new(x, yBottom + size.Y / 2, z), color, mat)
end
-- a Cylinder Part has its round faces on local X; rotate it when the round face must point elsewhere
local function cyl(name, size, cf, color, mat)
	local p = part(name, size, cf, color, mat)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- 1. wheels: round faces must point sideways (X) so they roll along Z — that is the default, no rotation.
--    Diameter 3 => centre at GROUND + 1.5 so the tyre bottom touches the ground exactly.
local WHEEL_D, WHEEL_W = 3, 1.2
local AXLE_Y = GROUND + WHEEL_D / 2
for _, z in ipairs({ -4.5, 4.5 }) do
	for _, side in ipairs({ -1, 1 }) do
		local x = side * 3.4
		cyl("Tyre", Vector3.new(WHEEL_W, WHEEL_D, WHEEL_D), CFrame.new(x, AXLE_Y, z), "Black", Enum.Material.Rubber)
		cyl("Hubcap", Vector3.new(0.2, 1.6, 1.6), CFrame.new(x + side * (WHEEL_W / 2 + 0.1), AXLE_Y, z), CHROME, Enum.Material.Metal)
	end
	part("Axle", Vector3.new(6.8, 0.5, 0.5), CFrame.new(0, AXLE_Y, z), "Dark stone grey", Enum.Material.Metal)
end

-- 2. chassis sits across the axles; lower body sits on the chassis
local CH_BOTTOM = AXLE_Y - 0.3
onTop("Chassis", Vector3.new(6, 1, 13), 0, CH_BOTTOM, 0, "Dark stone grey", Enum.Material.Metal)
local BODY_BOTTOM = CH_BOTTOM + 1
local BODY_H = 2
onTop("LowerBody", Vector3.new(7, BODY_H, 13), 0, BODY_BOTTOM, 0, RED)
local DECK = BODY_BOTTOM + BODY_H -- top of the hood / bed floor
-- wheel arches: dark strips just above each tyre, touching the body side
for _, z in ipairs({ -4.5, 4.5 }) do
	for _, side in ipairs({ -1, 1 }) do
		onTop("Fender", Vector3.new(0.3, 0.5, 3.6), side * 3.65, DECK - 0.5, z, RED)
	end
end

-- 3. cab (z from -2 to 3) with a white roof
local CAB_Z, CAB_L, CAB_H = 0.5, 5, 3
onTop("Cab", Vector3.new(7, CAB_H, CAB_L), 0, DECK, CAB_Z, RED)
onTop("Roof", Vector3.new(7.2, 0.5, CAB_L + 0.2), 0, DECK + CAB_H, CAB_Z, WHITE)
-- windshield: a WedgePart slope falls toward local -Z (the front), so no rotation — tall edge against the cab
local CAB_FRONT = CAB_Z - CAB_L / 2
part("Windshield", Vector3.new(6.6, CAB_H - 0.4, 1.6), CFrame.new(0, DECK + (CAB_H - 0.4) / 2, CAB_FRONT - 0.8), "Pastel light blue", Enum.Material.Glass, "WedgePart").Transparency = 0.25
for _, side in ipairs({ -1, 1 }) do
	onTop("SideWindow", Vector3.new(0.2, 1.6, 2.8), side * 3.55, DECK + 1, CAB_Z, "Pastel light blue", Enum.Material.Glass).Transparency = 0.25
	-- mirror: touches the cab side, sticks outward
	onTop("Mirror", Vector3.new(0.8, 0.7, 0.3), side * 3.9, DECK + 1.2, CAB_FRONT + 0.3, CHROME, Enum.Material.Metal)
	onTop("DoorHandle", Vector3.new(0.2, 0.2, 0.6), side * 3.6, DECK + 0.6, CAB_Z + 1.2, CHROME, Enum.Material.Metal)
end

-- 4. front: grille, bumper, round headlights (cylinders turned 90 degrees about Y so their round face points forward)
local FRONT = -6.5
onTop("Grille", Vector3.new(4.4, 1.4, 0.3), 0, BODY_BOTTOM + 0.3, FRONT - 0.15, CHROME, Enum.Material.DiamondPlate)
onTop("FrontBumper", Vector3.new(7.4, 0.8, 0.8), 0, CH_BOTTOM, FRONT - 0.3, CHROME, Enum.Material.Metal)
for _, side in ipairs({ -1, 1 }) do
	cyl("Headlight", Vector3.new(0.3, 1.2, 1.2), CFrame.new(side * 2.7, BODY_BOTTOM + 1, FRONT - 0.15) * CFrame.Angles(0, math.pi / 2, 0), "Institutional white", Enum.Material.Neon)
end

-- 5. bed: three low walls standing on the deck, a crate standing on the bed floor
local BED_FRONT, BED_BACK = CAB_Z + CAB_L / 2, 6.5
local BED_L = BED_BACK - BED_FRONT
local BED_MID = (BED_FRONT + BED_BACK) / 2
for _, side in ipairs({ -1, 1 }) do
	onTop("BedSide", Vector3.new(0.5, 1.6, BED_L), side * 3.25, DECK, BED_MID, RED)
	onTop("Taillight", Vector3.new(0.6, 0.8, 0.2), side * 2.9, BODY_BOTTOM + 0.8, BED_BACK + 0.1, "Really red", Enum.Material.Neon)
end
onTop("Tailgate", Vector3.new(6, 1.6, 0.5), 0, DECK, BED_BACK - 0.25, RED)
onTop("RearBumper", Vector3.new(7.4, 0.6, 0.6), 0, CH_BOTTOM, BED_BACK + 0.2, CHROME, Enum.Material.Metal)
onTop("Crate", Vector3.new(2.4, 2, 2.4), 0, DECK, BED_MID, "Brown", Enum.Material.WoodPlanks)
onTop("CrateLid", Vector3.new(2.6, 0.2, 2.6), 0, DECK + 2, BED_MID, "Reddish brown", Enum.Material.WoodPlanks)

model.PrimaryPart = model:FindFirstChild("Chassis")
model.Parent = workspace
local count = 0
for _, d in ipairs(model:GetDescendants()) do
	if d:IsA("BasePart") then count += 1 end
end
print("PickupTruck built: " .. count .. " parts, about 8 x 8 x 14 studs")
