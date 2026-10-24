-- Stone Cottage With Garden Props
-- Method: STRUCTURE — floor slab first, everything else stacked on something real.
local model = Instance.new("Model")
model.Name = "StoneCottage"

local GROUND = 0 -- top of the world floor; every free-standing thing starts here

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
-- places a block so its BOTTOM sits exactly at y (no guessing centre heights)
local function onTop(name, size, x, y, z, color, mat)
	return part(name, size, CFrame.new(x, y + size.Y / 2, z), color, mat)
end

-- 1. foundation slab and floor
local slab = onTop("Foundation", Vector3.new(24, 1, 18), 0, GROUND, 0, "Dark stone grey", Enum.Material.Slate)
local FLOOR = GROUND + 1 -- top of the slab

-- 2. walls: 16 x 12 footprint, 8 tall, 1 thick, door gap 4 wide on the front (+Z)
local W, D, H, T = 16, 12, 8, 1
onTop("BackWall", Vector3.new(W, H, T), 0, FLOOR, -D / 2 + T / 2, "Medium stone grey", Enum.Material.Cobblestone)
onTop("LeftWall", Vector3.new(T, H, D - 2 * T), -W / 2 + T / 2, FLOOR, 0, "Medium stone grey", Enum.Material.Cobblestone)
onTop("RightWall", Vector3.new(T, H, D - 2 * T), W / 2 - T / 2, FLOOR, 0, "Medium stone grey", Enum.Material.Cobblestone)
local DOOR_W, DOOR_H = 4, 6
local sideW = (W - DOOR_W) / 2
onTop("FrontWallL", Vector3.new(sideW, H, T), -(DOOR_W / 2 + sideW / 2), FLOOR, D / 2 - T / 2, "Medium stone grey", Enum.Material.Cobblestone)
onTop("FrontWallR", Vector3.new(sideW, H, T), DOOR_W / 2 + sideW / 2, FLOOR, D / 2 - T / 2, "Medium stone grey", Enum.Material.Cobblestone)
onTop("DoorLintel", Vector3.new(DOOR_W, H - DOOR_H, T), 0, FLOOR + DOOR_H, D / 2 - T / 2, "Dark stone grey", Enum.Material.Slate)
onTop("Door", Vector3.new(DOOR_W - 0.4, DOOR_H, 0.4), 0, FLOOR, D / 2 - T - 0.2, "Reddish brown", Enum.Material.WoodPlanks)
onTop("WindowL", Vector3.new(3, 3, 0.3), -5, FLOOR + 3, D / 2 + 0.15, "Pastel light blue", Enum.Material.Glass).Transparency = 0.3
onTop("WindowSillL", Vector3.new(3.6, 0.4, 0.8), -5, FLOOR + 2.6, D / 2 + 0.4, "White", Enum.Material.WoodPlanks)

-- 3. gable roof — ridge along X. A WedgePart's slope falls toward its local -Z, so:
--    front half: rotate 180 degrees about Y (slope falls toward +Z); back half: no rotation (falls toward -Z).
local TOP = FLOOR + H -- top of the walls
local RISE, RUN, LEN = 5, D / 2 + 1, W + 2
part("RoofFront", Vector3.new(LEN, RISE, RUN), CFrame.new(0, TOP + RISE / 2, RUN / 2) * CFrame.Angles(0, math.pi, 0), "Dark orange", Enum.Material.WoodPlanks, "WedgePart")
part("RoofBack", Vector3.new(LEN, RISE, RUN), CFrame.new(0, TOP + RISE / 2, -RUN / 2), "Dark orange", Enum.Material.WoodPlanks, "WedgePart")
onTop("RoofRidge", Vector3.new(LEN, 0.6, 0.8), 0, TOP + RISE - 0.1, 0, "Reddish brown", Enum.Material.WoodPlanks)
-- gable triangles fill the open ends (same wedge trick, thinner)
for _, side in ipairs({ -1, 1 }) do
	local x = side * (W / 2 - T / 2)
	part("GableFront" .. side, Vector3.new(T, RISE, D / 2), CFrame.new(x, TOP + RISE / 2, D / 4) * CFrame.Angles(0, math.pi, 0), "Medium stone grey", Enum.Material.Cobblestone, "WedgePart")
	part("GableBack" .. side, Vector3.new(T, RISE, D / 2), CFrame.new(x, TOP + RISE / 2, -D / 4), "Medium stone grey", Enum.Material.Cobblestone, "WedgePart")
end

-- 4. chimney rises from the GROUND beside the right wall, through the roof line
local CH = H + RISE + 2
onTop("Chimney", Vector3.new(3, CH, 3), W / 2 + 1.5, FLOOR, -2, "Bright red", Enum.Material.Brick)
onTop("ChimneyCap", Vector3.new(3.6, 0.6, 3.6), W / 2 + 1.5, FLOOR + CH, -2, "Dark stone grey", Enum.Material.Slate)
local fire = onTop("HearthGlow", Vector3.new(1.6, 1.4, 0.2), W / 2 + 1.5, FLOOR + 0.2, -0.45, "Neon orange", Enum.Material.Neon)
local light = Instance.new("PointLight")
light.Color = Color3.fromRGB(255, 140, 50)
light.Range = 12
light.Parent = fire

-- 5. props — each one's bottom sits on FLOOR (the slab), stacked pieces sit on the piece below
local bx, bz = -9.5, 6.5
local barrel = part("Barrel", Vector3.new(3, 2.4, 2.4), CFrame.new(bx, FLOOR + 1.5, bz) * CFrame.Angles(0, 0, math.rad(90)), "Brown", Enum.Material.Wood)
barrel.Shape = Enum.PartType.Cylinder
onTop("BarrelWater", Vector3.new(2, 0.2, 2), bx, FLOOR + 3, bz, "Bright blue", Enum.Material.Glass)

local sx, sz = 6, 7.5
onTop("Stump", Vector3.new(2, 1.6, 2), sx, FLOOR, sz, "Brown", Enum.Material.Wood)
onTop("AxeHead", Vector3.new(0.3, 0.8, 1.2), sx, FLOOR + 1.6, sz + 0.3, "Medium stone grey", Enum.Material.Metal)
onTop("AxeHandle", Vector3.new(0.3, 2.2, 0.3), sx, FLOOR + 1.6, sz - 0.3, "Reddish brown", Enum.Material.Wood)

for i = 0, 2 do -- log pile: a cylinder's round ends are on X, so these logs lie along X; each row rests on the row below
	for j = 0, 2 - i do
		local log = part("Log" .. i .. j, Vector3.new(3, 0.8, 0.8), CFrame.new(-9.5, FLOOR + 0.4 + i * 0.7, -3 + j * 0.8 + i * 0.4), "Reddish brown", Enum.Material.Wood)
		log.Shape = Enum.PartType.Cylinder
	end
end

-- hanging sign: bracket sticks out of the wall, sign hangs UNDER the bracket (touching it)
onTop("SignBracket", Vector3.new(0.4, 0.4, 3), 3.5, FLOOR + 6.6, D / 2 + 1.5, "Black", Enum.Material.Metal)
onTop("SignBoard", Vector3.new(0.3, 1.8, 2.4), 3.5, FLOOR + 6.6 - 1.8, D / 2 + 1.8, "Light brick yellow", Enum.Material.WoodPlanks)

model.PrimaryPart = slab
model.Parent = workspace
local count = 0
for _, d in ipairs(model:GetDescendants()) do
	if d:IsA("BasePart") then count += 1 end
end
print("StoneCottage built: " .. count .. " parts, about 24 x 16 x 18 studs")
