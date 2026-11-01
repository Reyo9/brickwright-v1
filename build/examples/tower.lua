--[[
	Wooden Watchtower: a tall medieval lookout tower on stilts with a ladder, a railed platform, a pointed roof and a torch.
	Size: about 10 x 22 x 10 studs. Faces -Z.
	SUBJECT TYPE: tall structure. FRAME build: four legs on stone footings, cross braces between the legs
	(each brace's two ends sit exactly on two legs), platform on the leg tops, railing on the platform edge,
	roof posts on the platform, roof on the posts.
	SIGNATURE FEATURES: four splayed log legs with X braces, a plank platform, a railing with posts, a red cone-like
	stepped roof with a flag, a ladder leaning from the ground to the platform, a lantern and a banner.
	LOOSE-PART RULES SHOWN: braces and the ladder use bone() between points computed ON the legs (lerp along each leg),
	so their ends always touch; roof steps stack with a running y.
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
model.Name = "Watchtower"

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
	ground = "Bright green", stone = "Medium stone grey", log = "Reddish brown", log2 = "Brown", plank = "Brick yellow",
	roof = "Bright red", roof2 = "Dark red", flag = "Bright blue", gold = "Bright yellow", lamp = "Neon orange", rope = "Nougat",
}

onTop("Ground", V(14, 0.5, 14), 0, 0, 0, C.ground, "2022 Big Stud")
local G = 0.5

-- LEGS: from footings (wide) up to the platform corners (narrower)
local PLAT_Y = G + 13
local foot, top = 4.2, 3
local legs = {}
for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
	local a = V(c[1] * foot, G + 0.8, c[2] * foot)
	local b = V(c[1] * top, PLAT_Y, c[2] * top)
	onTop("Footing", V(1.8, 0.8, 1.8), a.X, G, a.Z, C.stone, "2022 Big Stud")
	bone("Leg", a, b, 1, 1, C.log, "2022 Small Stud")
	table.insert(legs, { a = a, b = b })
end
local function on(leg, t) return leg.a:Lerp(leg.b, t) end
-- X BRACES between neighbouring legs, ends ON the legs at 15% and 55% height
for i = 1, 4 do
	local L1, L2 = legs[i], legs[i % 4 + 1]
	bone("Brace", on(L1, 0.15), on(L2, 0.55), 0.5, 0.5, C.log2, "2022 Small Stud")
	bone("Brace", on(L2, 0.15), on(L1, 0.55), 0.5, 0.5, C.log2, "2022 Small Stud")
	bone("Ring", on(L1, 0.7), on(L2, 0.7), 0.5, 0.5, C.log2, "2022 Small Stud")
end

-- PLATFORM on the leg tops, planks sunk into it
local PLAT = V(8, 0.6, 8)
onTop("Platform", PLAT, 0, PLAT_Y - 0.3, 0, C.log2, "2022 Big Stud")
local PT = PLAT_Y + 0.3
for k = -3, 3 do onTop("Plank", V(0.15, 0.1, 7.8), k * 1.1, PT - 0.05, 0, C.plank) end
-- RAILING: posts on the edge, rails on the posts (front gap for the ladder)
for _, sx in ipairs({ -1, 1 }) do
	for k = 0, 3 do
		onTop("RailPost", V(0.4, 1.6, 0.4), sx * 3.8, PT, -3.8 + k * 2.53, C.log, "2022 Small Stud")
		onTop("RailPost", V(0.4, 1.6, 0.4), -3.8 + k * 2.53, PT, sx * 3.8, C.log, "2022 Small Stud")
	end
	onTop("RailSide", V(0.3, 0.3, 8), sx * 3.8, PT + 1.6, 0, C.log2, "2022 Small Stud")
end
onTop("RailBack", V(8, 0.3, 0.3), 0, PT + 1.6, 3.8, C.log2, "2022 Small Stud")
onTop("RailFrontL", V(2.6, 0.3, 0.3), -2.5, PT + 1.6, -3.8, C.log2, "2022 Small Stud")
onTop("RailFrontR", V(2.6, 0.3, 0.3), 2.5, PT + 1.6, -3.8, C.log2, "2022 Small Stud")
-- banner hanging from the front rail, touching it
onTop("Banner", V(1.6, 2.4, 0.1), -2.5, PT + 1.6 - 2.4, -3.95, C.flag, "2022 Small Stud")
onTop("BannerMark", V(0.6, 0.6, 0.1), -2.5, PT + 0.2, -4.02, C.gold)

-- ROOF: four corner posts on the platform, then a stepped roof stacked with a running y
local POST_H = 4
for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
	onTop("RoofPost", V(0.5, POST_H, 0.5), c[1] * 3.6, PT, c[2] * 3.6, C.log, "2022 Small Stud")
end
local y = PT + POST_H
for i, w in ipairs({ 9.4, 7.6, 5.8, 4, 2.2 }) do
	onTop("RoofStep" .. i, V(w, 0.9, w), 0, y, 0, i % 2 == 0 and C.roof2 or C.roof, "2022 Big Stud")
	y = y + 0.9
end
onTop("FlagPole", V(0.25, 2.6, 0.25), 0, y, 0, C.log2, "2022 Small Stud")
onTop("Flag", V(0.1, 1, 1.6), 0, y + 1.5, 0.9, C.flag, "2022 Small Stud")
make("Ball", "PoleTop", V(0.5, 0.5, 0.5), CFrame.new(0, y + 2.7, 0), C.gold)
-- lantern hanging under the roof from a short rope
onTop("LanternRope", V(0.12, 0.8, 0.12), 2.6, PT + POST_H - 0.8, -2.6, C.rope)
onTop("Lantern", V(0.8, 1, 0.8), 2.6, PT + POST_H - 1.8, -2.6, C.log2, "2022 Small Stud")
glow(onTop("LanternLight", V(0.5, 0.6, 0.9), 2.6, PT + POST_H - 1.6, -2.6, C.lamp))

-- LADDER from the ground to the front gap: rails between ground points and platform edge points
local ladBottom, ladTop = V(0, G, -7), V(0, PT, -4)
for _, sx in ipairs({ -0.9, 0.9 }) do
	bone("LadderRail", ladBottom + V(sx, 0, 0), ladTop + V(sx, 0.6, 0), 0.3, 0.3, C.log, "2022 Small Stud")
end
for k = 1, 9 do
	local p = ladBottom:Lerp(ladTop + V(0, 0.6, 0), k / 10)
	make("Part", "Rung" .. k, V(1.8, 0.25, 0.25), CFrame.new(p), C.log2, "2022 Small Stud")
end

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
print(string.format("Watchtower built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
