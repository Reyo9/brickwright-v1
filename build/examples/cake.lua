--[[
	Birthday Cake: a three-tier strawberry cake on a stand with frosting drips, candles with flames and strawberries.
	Size: about 10 x 11 x 10 studs. Faces -Z.
	SUBJECT TYPE: food prop. STACKING build: stand, plate, then each tier's yBottom = the tier below's top;
	frosting rims, drips and decorations attach to the tier faces they sit on.
	SIGNATURE FEATURES: pink, white and chocolate tiers, white frosting drips over each edge, a piped frosting rim,
	strawberries around the top, five striped candles with glowing flames and a gold "happy birthday" topper.
	LOOSE-PART RULES SHOWN: a running y for the tiers; drips hang from the tier top edge (top of the drip = tier top);
	candle flames are named "Glow..." because they float a tiny bit above the wick on purpose.
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
model.Name = "BirthdayCake"

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
	stand = "White", stand2 = "Light stone grey", tier1 = "Reddish brown", tier2 = "Carnation pink", tier3 = "White",
	frost = "White", frost2 = "Pink", berry = "Bright red", leaf = "Lime green", candle = "Bright blue", candle2 = "White",
	flame = "New Yeller", gold = "Bright yellow",
}

local function disc(name, h, d, y, colour, variant)
	make("Cylinder", name, V(h, d, d), CFrame.new(0, y + h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), colour, variant)
	return y + h
end

-- STAND and PLATE
local y = disc("StandFoot", 0.5, 4, 0, C.stand2, "2022 Big Stud")
y = disc("StandStem", 1.5, 1.4, y, C.stand, "2022 Small Stud")
y = disc("Plate", 0.4, 10, y, C.stand, "2022 Big Stud")

-- TIERS with frosting drips hanging from each top edge, and a piped rim on top
local tiers = { { 8, 2.2, C.tier1, C.frost }, { 6, 2, C.tier2, C.frost }, { 4, 1.8, C.tier3, C.frost2 } }
for t, T in ipairs(tiers) do
	local d, h = T[1], T[2]
	local bottom = y
	y = disc("Tier" .. t, h, d, y, T[3], "2022 Big Stud")
	disc("TierFrostTop" .. t, 0.2, d + 0.1, y - 0.1, T[4], "2022 Small Stud")
	local n = math.floor(d * 2)
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		local dl = 0.5 + ((k * 7) % 4) * 0.25
		local r = d / 2 + 0.05
		onTop("Drip" .. t .. "_" .. k, V(0.4, dl, 0.4), math.cos(a) * r, y - dl, math.sin(a) * r, T[4], "2022 Small Stud")
	end
	-- piped rim: small balls along the top edge (they sink into the top)
	for k = 0, n - 1 do
		local a = (k + 0.5) / n * math.pi * 2
		make("Ball", "Pipe" .. t .. "_" .. k, V(0.5, 0.5, 0.5), CFrame.new(math.cos(a) * (d / 2 - 0.3), y + 0.1, math.sin(a) * (d / 2 - 0.3)), T[4])
	end
	-- a band of dots around the middle of the tier face
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		make("Ball", "Dot" .. t .. "_" .. k, V(0.4, 0.4, 0.4), CFrame.new(math.cos(a) * d / 2, bottom + h * 0.45, math.sin(a) * d / 2), T[4])
	end
end
local TOP = y

-- STRAWBERRIES around the top tier (sitting on the top)
for k = 0, 5 do
	local a = k / 6 * math.pi * 2
	local p = V(math.cos(a) * 1.3, TOP + 0.35, math.sin(a) * 1.3)
	make("Ball", "Berry" .. k, V(0.8, 0.8, 0.8), CFrame.new(p), C.berry, "2022 Small Stud")
	make("Part", "BerryLeaf" .. k, V(0.5, 0.15, 0.5), CFrame.new(p + V(0, 0.4, 0)), C.leaf)
end

-- CANDLES standing on the top, flames just above the wick (named Glow so the checker allows it)
for k = 0, 4 do
	local a = k / 5 * math.pi * 2 + 0.3
	local cx, cz = math.cos(a) * 0.9, math.sin(a) * 0.9
	if k == 4 then cx, cz = 0, 0 end
	onTop("Candle" .. k, V(0.3, 1.4, 0.3), cx, TOP - 0.05, cz, C.candle, "2022 Small Stud")
	onTop("CandleStripe" .. k, V(0.32, 0.2, 0.32), cx, TOP + 0.6, cz, C.candle2)
	onTop("Wick" .. k, V(0.08, 0.2, 0.08), cx, TOP + 1.35, cz, C.stand2)
	glow(make("Ball", "GlowFlame" .. k, V(0.35, 0.35, 0.35), CFrame.new(cx, TOP + 1.75, cz), C.flame))
end

-- TOPPER on two sticks at the back edge
for _, x in ipairs({ -1, 1 }) do onTop("TopperStick", V(0.12, 2.2, 0.12), x, TOP - 0.05, 1.4, C.gold) end
onTop("Topper", V(2.6, 0.9, 0.15), 0, TOP + 2.1, 1.4, C.gold, "2022 Small Stud")

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
print(string.format("BirthdayCake built: %d parts, %.1f x %.1f x %.1f studs", count, ext.X, ext.Y, ext.Z))
