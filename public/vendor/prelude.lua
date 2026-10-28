-- Brickwright preview runtime: a small fake of the Roblox API, enough to run generated build
-- scripts in the browser and read back every BasePart they leave in workspace.
local sqrt, sin, cos, abs, atan2 = math.sqrt, math.sin, math.cos, math.abs, (math.atan2 or math.atan)
local unpack = table.unpack or unpack
local LOGS = {}
local MAXPARTS = 20000
local partCount = 0

----------------------------------------------------------------- Vector3
local V3 = {}
V3.__index = function(v, k)
	if k == "X" or k == "x" then return rawget(v, 1)
	elseif k == "Y" or k == "y" then return rawget(v, 2)
	elseif k == "Z" or k == "z" then return rawget(v, 3)
	elseif k == "Magnitude" or k == "magnitude" then return sqrt(v[1]*v[1]+v[2]*v[2]+v[3]*v[3])
	elseif k == "Unit" or k == "unit" then
		local m = sqrt(v[1]*v[1]+v[2]*v[2]+v[3]*v[3])
		if m == 0 then return setmetatable({0/0,0/0,0/0}, V3) end
		return setmetatable({v[1]/m, v[2]/m, v[3]/m}, V3)
	end
	return V3[k]
end
local function v3(x, y, z) return setmetatable({x or 0, y or 0, z or 0}, V3) end
local function isV3(v) return getmetatable(v) == V3 end
V3.__add = function(a, b) return v3(a[1]+b[1], a[2]+b[2], a[3]+b[3]) end
V3.__sub = function(a, b) return v3(a[1]-b[1], a[2]-b[2], a[3]-b[3]) end
V3.__mul = function(a, b)
	if type(a) == "number" then return v3(a*b[1], a*b[2], a*b[3]) end
	if type(b) == "number" then return v3(a[1]*b, a[2]*b, a[3]*b) end
	return v3(a[1]*b[1], a[2]*b[2], a[3]*b[3])
end
V3.__div = function(a, b)
	if type(a) == "number" then return v3(a/b[1], a/b[2], a/b[3]) end
	if type(b) == "number" then return v3(a[1]/b, a[2]/b, a[3]/b) end
	return v3(a[1]/b[1], a[2]/b[2], a[3]/b[3])
end
V3.__idiv = function(a, b) local r = V3.__div(a, b) return v3(math.floor(r[1]), math.floor(r[2]), math.floor(r[3])) end
V3.__unm = function(a) return v3(-a[1], -a[2], -a[3]) end
V3.__eq = function(a, b) return a[1]==b[1] and a[2]==b[2] and a[3]==b[3] end
V3.__tostring = function(a) return string.format("%g, %g, %g", a[1], a[2], a[3]) end
function V3.Dot(a, b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
function V3.Cross(a, b) return v3(a[2]*b[3]-a[3]*b[2], a[3]*b[1]-a[1]*b[3], a[1]*b[2]-a[2]*b[1]) end
function V3.Lerp(a, b, t) return v3(a[1]+(b[1]-a[1])*t, a[2]+(b[2]-a[2])*t, a[3]+(b[3]-a[3])*t) end
function V3.Abs(a) return v3(abs(a[1]), abs(a[2]), abs(a[3])) end
function V3.Min(a, b) return v3(math.min(a[1],b[1]), math.min(a[2],b[2]), math.min(a[3],b[3])) end
function V3.Max(a, b) return v3(math.max(a[1],b[1]), math.max(a[2],b[2]), math.max(a[3],b[3])) end
function V3.Floor(a) return v3(math.floor(a[1]), math.floor(a[2]), math.floor(a[3])) end
function V3.Ceil(a) return v3(math.ceil(a[1]), math.ceil(a[2]), math.ceil(a[3])) end
function V3.Sign(a) local function s(n) return n > 0 and 1 or (n < 0 and -1 or 0) end return v3(s(a[1]), s(a[2]), s(a[3])) end
function V3.FuzzyEq(a, b, e) e = e or 1e-5 return abs(a[1]-b[1])<=e and abs(a[2]-b[2])<=e and abs(a[3]-b[3])<=e end
function V3.Angle(a, b) local d = V3.Dot(a.Unit, b.Unit) return math.acos(math.max(-1, math.min(1, d))) end
Vector3 = {
	new = v3,
	zero = v3(0,0,0), one = v3(1,1,1),
	xAxis = v3(1,0,0), yAxis = v3(0,1,0), zAxis = v3(0,0,1),
	FromNormalId = function() return v3(0,1,0) end,
}
Vector2 = { new = function(x, y) return {X = x or 0, Y = y or 0} end }
Vector2.zero = Vector2.new()

----------------------------------------------------------------- CFrame
-- stored as {px,py,pz, r00,r01,r02, r10,r11,r12, r20,r21,r22}; columns = Right, Up, Back
local CF = {}
local function cfraw(t) return setmetatable(t, CF) end
local function isCF(c) return getmetatable(c) == CF end
local function mk(px,py,pz, a,b,c, d,e,f, g,h,i) return cfraw({px,py,pz, a,b,c, d,e,f, g,h,i}) end
local function fromCols(p, rx, ry, rz)
	return mk(p[1],p[2],p[3], rx[1],ry[1],rz[1], rx[2],ry[2],rz[2], rx[3],ry[3],rz[3])
end
local function cmul(A, B)
	local a = A
	local b = B
	return mk(
		a[4]*b[1]+a[5]*b[2]+a[6]*b[3]+a[1],
		a[7]*b[1]+a[8]*b[2]+a[9]*b[3]+a[2],
		a[10]*b[1]+a[11]*b[2]+a[12]*b[3]+a[3],
		a[4]*b[4]+a[5]*b[7]+a[6]*b[10], a[4]*b[5]+a[5]*b[8]+a[6]*b[11], a[4]*b[6]+a[5]*b[9]+a[6]*b[12],
		a[7]*b[4]+a[8]*b[7]+a[9]*b[10], a[7]*b[5]+a[8]*b[8]+a[9]*b[11], a[7]*b[6]+a[8]*b[9]+a[9]*b[12],
		a[10]*b[4]+a[11]*b[7]+a[12]*b[10], a[10]*b[5]+a[11]*b[8]+a[12]*b[11], a[10]*b[6]+a[11]*b[9]+a[12]*b[12])
end
local function cpoint(a, v)
	return v3(a[4]*v[1]+a[5]*v[2]+a[6]*v[3]+a[1], a[7]*v[1]+a[8]*v[2]+a[9]*v[3]+a[2], a[10]*v[1]+a[11]*v[2]+a[12]*v[3]+a[3])
end
local function cvec(a, v)
	return v3(a[4]*v[1]+a[5]*v[2]+a[6]*v[3], a[7]*v[1]+a[8]*v[2]+a[9]*v[3], a[10]*v[1]+a[11]*v[2]+a[12]*v[3])
end
local function cinv(a)
	-- rotation is orthonormal: inverse = transpose
	local r00,r01,r02,r10,r11,r12,r20,r21,r22 = a[4],a[7],a[10],a[5],a[8],a[11],a[6],a[9],a[12]
	local px,py,pz = a[1],a[2],a[3]
	return mk(-(r00*px+r01*py+r02*pz), -(r10*px+r11*py+r12*pz), -(r20*px+r21*py+r22*pz), r00,r01,r02, r10,r11,r12, r20,r21,r22)
end
local function rotX(t) local c,s = cos(t), sin(t) return mk(0,0,0, 1,0,0, 0,c,-s, 0,s,c) end
local function rotY(t) local c,s = cos(t), sin(t) return mk(0,0,0, c,0,s, 0,1,0, -s,0,c) end
local function rotZ(t) local c,s = cos(t), sin(t) return mk(0,0,0, c,-s,0, s,c,0, 0,0,1) end
local IDENT = mk(0,0,0, 1,0,0, 0,1,0, 0,0,1)
local function lookAt(pos, target, up)
	up = up or v3(0,1,0)
	local look = (target - pos)
	if look.Magnitude < 1e-9 then return mk(pos[1],pos[2],pos[3], 1,0,0, 0,1,0, 0,0,1) end
	look = look.Unit
	local right = V3.Cross(look, up)
	if right.Magnitude < 1e-6 then right = V3.Cross(look, v3(0,0,1)) end
	if right.Magnitude < 1e-6 then right = V3.Cross(look, v3(1,0,0)) end
	right = right.Unit
	local upv = V3.Cross(right, look).Unit
	return fromCols(pos, right, upv, -look)
end
local function fromQuat(x, y, z, qx, qy, qz, qw)
	local n = sqrt(qx*qx+qy*qy+qz*qz+qw*qw)
	if n == 0 then n = 1 end
	qx, qy, qz, qw = qx/n, qy/n, qz/n, qw/n
	return mk(x, y, z,
		1-2*(qy*qy+qz*qz), 2*(qx*qy-qz*qw), 2*(qx*qz+qy*qw),
		2*(qx*qy+qz*qw), 1-2*(qx*qx+qz*qz), 2*(qy*qz-qx*qw),
		2*(qx*qz-qy*qw), 2*(qy*qz+qx*qw), 1-2*(qx*qx+qy*qy))
end
local function toQuat(a)
	local m00,m01,m02,m10,m11,m12,m20,m21,m22 = a[4],a[5],a[6],a[7],a[8],a[9],a[10],a[11],a[12]
	local tr = m00+m11+m22
	local qw,qx,qy,qz
	if tr > 0 then local s = sqrt(tr+1)*2 qw=0.25*s qx=(m21-m12)/s qy=(m02-m20)/s qz=(m10-m01)/s
	elseif m00 > m11 and m00 > m22 then local s = sqrt(1+m00-m11-m22)*2 qw=(m21-m12)/s qx=0.25*s qy=(m01+m10)/s qz=(m02+m20)/s
	elseif m11 > m22 then local s = sqrt(1+m11-m00-m22)*2 qw=(m02-m20)/s qx=(m01+m10)/s qy=0.25*s qz=(m12+m21)/s
	else local s = sqrt(1+m22-m00-m11)*2 qw=(m10-m01)/s qx=(m02+m20)/s qy=(m12+m21)/s qz=0.25*s end
	return qx,qy,qz,qw
end
CF.__index = function(c, k)
	if k == "Position" or k == "p" then return v3(c[1], c[2], c[3])
	elseif k == "X" or k == "x" then return c[1]
	elseif k == "Y" or k == "y" then return c[2]
	elseif k == "Z" or k == "z" then return c[3]
	elseif k == "RightVector" or k == "XVector" then return v3(c[4], c[7], c[10])
	elseif k == "UpVector" or k == "YVector" then return v3(c[5], c[8], c[11])
	elseif k == "ZVector" then return v3(c[6], c[9], c[12])
	elseif k == "LookVector" or k == "lookVector" then return v3(-c[6], -c[9], -c[12])
	elseif k == "Rotation" then return mk(0,0,0, c[4],c[5],c[6], c[7],c[8],c[9], c[10],c[11],c[12])
	end
	return CF[k]
end
CF.__mul = function(a, b)
	if isCF(b) then return cmul(a, b) end
	if isV3(b) then return cpoint(a, b) end
	error("bad CFrame multiply", 2)
end
CF.__add = function(a, b) return mk(a[1]+b[1], a[2]+b[2], a[3]+b[3], a[4],a[5],a[6],a[7],a[8],a[9],a[10],a[11],a[12]) end
CF.__sub = function(a, b) return mk(a[1]-b[1], a[2]-b[2], a[3]-b[3], a[4],a[5],a[6],a[7],a[8],a[9],a[10],a[11],a[12]) end
CF.__eq = function(a, b) for i = 1, 12 do if a[i] ~= b[i] then return false end end return true end
CF.__tostring = function(a) local t = {} for i = 1, 12 do t[i] = string.format("%g", a[i]) end return table.concat(t, ", ") end
function CF.Inverse(a) return cinv(a) end
function CF.ToWorldSpace(a, b) return cmul(a, b or IDENT) end
function CF.ToObjectSpace(a, b) return cmul(cinv(a), b or IDENT) end
function CF.PointToWorldSpace(a, v) return cpoint(a, v) end
function CF.PointToObjectSpace(a, v) return cpoint(cinv(a), v) end
function CF.VectorToWorldSpace(a, v) return cvec(a, v) end
function CF.VectorToObjectSpace(a, v) return cvec(cinv(a), v) end
function CF.GetComponents(a) return unpack(a, 1, 12) end
CF.components = CF.GetComponents
function CF.Orthonormalize(a) return a end
function CF.FuzzyEq(a, b) for i = 1, 12 do if abs(a[i]-b[i]) > 1e-5 then return false end end return true end
function CF.Lerp(a, b, t)
	local ax,ay,az,aw = toQuat(a)
	local bx,by,bz,bw = toQuat(b)
	local d = ax*bx+ay*by+az*bz+aw*bw
	if d < 0 then bx,by,bz,bw,d = -bx,-by,-bz,-bw,-d end
	local qx,qy,qz,qw
	if d > 0.9995 then
		qx,qy,qz,qw = ax+(bx-ax)*t, ay+(by-ay)*t, az+(bz-az)*t, aw+(bw-aw)*t
	else
		local th = math.acos(d)
		local s1, s2 = sin((1-t)*th)/sin(th), sin(t*th)/sin(th)
		qx,qy,qz,qw = ax*s1+bx*s2, ay*s1+by*s2, az*s1+bz*s2, aw*s1+bw*s2
	end
	return fromQuat(a[1]+(b[1]-a[1])*t, a[2]+(b[2]-a[2])*t, a[3]+(b[3]-a[3])*t, qx,qy,qz,qw)
end
function CF.ToEulerAnglesXYZ(a)
	local r02 = a[6]
	local y = math.asin(math.max(-1, math.min(1, r02)))
	local x = atan2(-a[9], a[12])
	local z = atan2(-a[5], a[4])
	return x, y, z
end
function CF.ToEulerAnglesYXZ(a)
	local x = math.asin(math.max(-1, math.min(1, -a[9])))
	local y = atan2(a[6], a[12])
	local z = atan2(a[7], a[8])
	return x, y, z
end
CF.ToOrientation = CF.ToEulerAnglesYXZ
function CF.ToAxisAngle(a)
	local qx,qy,qz,qw = toQuat(a)
	local ang = 2*math.acos(math.max(-1, math.min(1, qw)))
	local s = sqrt(1-qw*qw)
	if s < 1e-6 then return v3(1,0,0), 0 end
	return v3(qx/s, qy/s, qz/s), ang
end
local function angles(rx, ry, rz) return cmul(cmul(rotX(rx or 0), rotY(ry or 0)), rotZ(rz or 0)) end
local function yxz(rx, ry, rz) return cmul(cmul(rotY(ry or 0), rotX(rx or 0)), rotZ(rz or 0)) end
CFrame = {
	new = function(...)
		local n = select("#", ...)
		local a, b, c = ...
		if n == 0 then return IDENT end
		if isV3(a) then
			if isV3(b) then return lookAt(a, b) end
			return mk(a[1],a[2],a[3], 1,0,0, 0,1,0, 0,0,1)
		end
		if n == 12 then return mk(...) end
		if n == 7 then return fromQuat(...) end
		return mk(a or 0, b or 0, c or 0, 1,0,0, 0,1,0, 0,0,1)
	end,
	lookAt = lookAt,
	Angles = angles, fromEulerAnglesXYZ = angles,
	fromEulerAnglesYXZ = yxz, fromOrientation = yxz,
	fromEulerAngles = function(rx, ry, rz) return angles(rx, ry, rz) end,
	fromAxisAngle = function(axis, t)
		local u = axis.Unit
		local s = sin(t/2)
		return fromQuat(0,0,0, u[1]*s, u[2]*s, u[3]*s, cos(t/2))
	end,
	fromMatrix = function(pos, vx, vy, vz)
		vz = vz or V3.Cross(vx, vy).Unit
		return fromCols(pos, vx, vy, vz)
	end,
	lookAlong = function(pos, dir, up) return lookAt(pos, pos + dir, up) end,
	identity = IDENT,
}

----------------------------------------------------------------- Color3 / BrickColor
local C3 = {}
C3.__index = function(c, k)
	if k == "R" or k == "r" then return c[1] elseif k == "G" or k == "g" then return c[2]
	elseif k == "B" or k == "b" then return c[3] end
	return C3[k]
end
local function c3(r, g, b) return setmetatable({r or 0, g or 0, b or 0}, C3) end
C3.__eq = function(a, b) return a[1]==b[1] and a[2]==b[2] and a[3]==b[3] end
function C3.Lerp(a, b, t) return c3(a[1]+(b[1]-a[1])*t, a[2]+(b[2]-a[2])*t, a[3]+(b[3]-a[3])*t) end
function C3.ToHSV(c)
	local r,g,b = c[1],c[2],c[3]
	local mx, mn = math.max(r,g,b), math.min(r,g,b)
	local h, s, v = 0, 0, mx
	local d = mx - mn
	if mx > 0 then s = d / mx end
	if d > 0 then
		if mx == r then h = ((g - b) / d) % 6 elseif mx == g then h = (b - r) / d + 2 else h = (r - g) / d + 4 end
		h = h / 6
	end
	return h, s, v
end
function C3.ToHex(c) return string.format("%02X%02X%02X", math.floor(c[1]*255+0.5), math.floor(c[2]*255+0.5), math.floor(c[3]*255+0.5)) end
local function hsv(h, s, v)
	local i = math.floor(h*6) local f = h*6 - i
	local p, q, t = v*(1-s), v*(1-f*s), v*(1-(1-f)*s)
	i = i % 6
	if i == 0 then return c3(v,t,p) elseif i == 1 then return c3(q,v,p) elseif i == 2 then return c3(p,v,t)
	elseif i == 3 then return c3(p,q,v) elseif i == 4 then return c3(t,p,v) else return c3(v,p,q) end
end
Color3 = {
	new = c3,
	fromRGB = function(r, g, b) return c3((r or 0)/255, (g or 0)/255, (b or 0)/255) end,
	fromHSV = hsv,
	fromHex = function(h) h = h:gsub("#", "") return c3(tonumber(h:sub(1,2),16)/255, tonumber(h:sub(3,4),16)/255, tonumber(h:sub(5,6),16)/255) end,
	toHSV = function(c) return C3.ToHSV(c) end,
}
local BC_HEX = __BRICK_HEX or {}
local BC = {}
BC.__index = function(b, k)
	if k == "Color" then return rawget(b, "_c") elseif k == "Name" or k == "name" then return rawget(b, "_n")
	elseif k == "r" then return rawget(b, "_c")[1] elseif k == "g" then return rawget(b, "_c")[2] elseif k == "b" then return rawget(b, "_c")[3] end
	return nil
end
BC.__eq = function(a, b) return rawget(a, "_n") == rawget(b, "_n") end
BC.__tostring = function(b) return rawget(b, "_n") end
local BC_LOWER = {}
for name, hex in pairs(BC_HEX) do BC_LOWER[string.lower(name)] = {name, hex} end
local function bcFromName(name)
	local e = BC_LOWER[string.lower(tostring(name))]
	if not e then e = BC_LOWER["medium stone grey"] or {"Medium stone grey", "a3a2a5"} end
	return setmetatable({_n = e[1], _c = Color3.fromHex(e[2])}, BC)
end
local function bcNearest(c)
	local best, bd = nil, 1e9
	for name, hex in pairs(BC_HEX) do
		local o = Color3.fromHex(hex)
		local d = (o[1]-c[1])^2 + (o[2]-c[2])^2 + (o[3]-c[3])^2
		if d < bd then bd = d best = name end
	end
	return setmetatable({_n = best or "Medium stone grey", _c = c}, BC)
end
BrickColor = {
	new = function(a, g, b)
		if type(a) == "string" then return bcFromName(a) end
		if getmetatable(a) == C3 then return bcNearest(a) end
		if type(a) == "number" and g then return bcNearest(c3(a, g, b)) end
		return bcFromName("Medium stone grey")
	end,
	random = function() local names = {} for n in pairs(BC_HEX) do names[#names+1] = n end return bcFromName(names[math.random(#names)]) end,
	White = function() return bcFromName("White") end, Black = function() return bcFromName("Black") end,
	Red = function() return bcFromName("Bright red") end, Blue = function() return bcFromName("Bright blue") end,
	Green = function() return bcFromName("Dark green") end, Yellow = function() return bcFromName("Bright yellow") end,
	Gray = function() return bcFromName("Medium stone grey") end, palette = function() return bcFromName("Medium stone grey") end,
}
BrickColor.DarkGray = function() return bcFromName("Dark stone grey") end

----------------------------------------------------------------- Enum
local enumCache = {}
local EnumItemMT = { __tostring = function(e) return "Enum." .. e.EnumType .. "." .. e.Name end }
Enum = setmetatable({}, { __index = function(_, typ)
	local t = enumCache[typ]
	if not t then
		local items = {}
		t = setmetatable({}, { __index = function(_, name)
			local it = items[name]
			if not it then it = setmetatable({Name = name, EnumType = typ, Value = 0}, EnumItemMT) items[name] = it end
			return it
		end })
		function t:GetEnumItems() local r = {} for _, v in pairs(items) do r[#r+1] = v end return r end
		enumCache[typ] = t
	end
	return t
end })

----------------------------------------------------------------- Random / math / misc
local RND = {}
RND.__index = RND
local function nextRaw(r)
	-- xorshift-ish LCG; deterministic for a given seed (Roblox's own generator differs)
	r._s = (r._s * 1103515245 + 12345) % 2147483648
	return r._s / 2147483648
end
function RND:NextNumber(a, b) local u = nextRaw(self) if a == nil then return u end return a + (b - a) * u end
function RND:NextInteger(a, b) return math.floor(a + (b - a + 1) * nextRaw(self)) end
function RND:NextUnitVector() local z = self:NextNumber(-1, 1) local t = self:NextNumber(0, 2*math.pi) local s = sqrt(1-z*z) return v3(s*cos(t), s*sin(t), z) end
function RND:Shuffle(t) for i = #t, 2, -1 do local j = self:NextInteger(1, i) t[i], t[j] = t[j], t[i] end end
function RND:Clone() return setmetatable({_s = self._s}, RND) end
Random = { new = function(seed) return setmetatable({_s = math.floor(abs(seed or os.time()) * 7919) % 2147483648 + 1}, RND) end }
math.clamp = function(x, a, b) if x < a then return a elseif x > b then return b end return x end
math.sign = function(x) return x > 0 and 1 or (x < 0 and -1 or 0) end
math.round = function(x) return math.floor(x + 0.5) end
math.noise = function(x, y, z) x = x or 0 y = y or 0 z = z or 0 return sin(x*12.9898 + y*78.233 + z*37.719) * 0.5 end
math.lerp = function(a, b, t) return a + (b - a) * t end
math.atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
math.pow = math.pow or function(a, b) return a ^ b end
table.find = function(t, v) for i, x in ipairs(t) do if x == v then return i end end return nil end
table.clear = function(t) for k in pairs(t) do t[k] = nil end end
table.create = function(n, v) local t = {} for i = 1, n do t[i] = v end return t end
table.freeze = function(t) return t end
table.isfrozen = function() return false end
table.clone = function(t) local r = {} for k, v in pairs(t) do r[k] = v end return r end
table.unpack = table.unpack or unpack
table.getn = table.getn or function(t) return #t end
string.split = function(s, sep)
	sep = sep or ","
	local out, i = {}, 1
	while true do
		local a, b = string.find(s, sep, i, true)
		if not a then out[#out+1] = string.sub(s, i) break end
		out[#out+1] = string.sub(s, i, a - 1)
		i = b + 1
	end
	return out
end
unpack = unpack or table.unpack
NumberSequence = { new = function(...) return {...} end }
NumberSequenceKeypoint = { new = function(...) return {...} end }
ColorSequence = { new = function(...) return {...} end }
ColorSequenceKeypoint = { new = function(...) return {...} end }
NumberRange = { new = function(a, b) return {Min = a, Max = b or a} end }
UDim = { new = function(a, b) return {Scale = a, Offset = b} end }
UDim2 = { new = function(...) return {...} end, fromScale = function(...) return {...} end, fromOffset = function(...) return {...} end }
Rect = { new = function(...) return {...} end }
Ray = { new = function(o, d) return {Origin = o, Direction = d} end }
Region3 = { new = function(a, b) return {CFrame = CFrame.new((a + b) / 2), Size = b - a} end }
PhysicalProperties = { new = function(...) return {...} end }
TweenInfo = { new = function(...) return {...} end }
Faces = { new = function(...) return {...} end }
Axes = { new = function(...) return {...} end }
DateTime = { now = function() return {UnixTimestamp = os.time(), UnixTimestampMillis = os.time() * 1000} end }
local function stamp(...)
	local t = {}
	for i = 1, select("#", ...) do t[#t+1] = tostring((select(i, ...))) end
	return table.concat(t, " ")
end
print = function(...) if #LOGS < 200 then LOGS[#LOGS+1] = stamp(...) end end
warn = function(...) if #LOGS < 200 then LOGS[#LOGS+1] = "WARN: " .. stamp(...) end end
tick = function() return os.time() end
time = function() return 0 end
os.clock = os.clock or function() return 0 end
wait = function() return 0, 0 end
delay = function() end
spawn = function(f) pcall(f) end
task = {
	wait = function() return 0 end,
	spawn = function(f, ...) if type(f) == "function" then pcall(f, ...) end end,
	defer = function(f, ...) if type(f) == "function" then pcall(f, ...) end end,
	delay = function() end,
	cancel = function() end,
	synchronize = function() end, desynchronize = function() end,
}
typeof = function(v)
	local m = getmetatable(v)
	if m == V3 then return "Vector3" elseif m == CF then return "CFrame" elseif m == C3 then return "Color3"
	elseif m == BC then return "BrickColor" elseif m == EnumItemMT then return "EnumItem" end
	if type(v) == "table" and rawget(v, "__isInstance") then return "Instance" end
	return type(v)
end

----------------------------------------------------------------- Instances
local SIGNAL = { Connect = function() return { Disconnect = function() end } end, Once = function() return { Disconnect = function() end } end, Wait = function() end }
SIGNAL.__index = SIGNAL
local function signal() return setmetatable({}, SIGNAL) end

local PART_CLASSES = { Part = true, WedgePart = true, CornerWedgePart = true, TrussPart = true, Seat = true,
	SpawnLocation = true, MeshPart = true, UnionOperation = true, NegateOperation = true, VehicleSeat = true, BasePart = true }
local INHERIT = {
	BasePart = function(c) return PART_CLASSES[c] end,
	PVInstance = function(c) return PART_CLASSES[c] or c == "Model" or c == "Workspace" end,
	PartOperation = function(c) return c == "UnionOperation" or c == "NegateOperation" end,
	FormFactorPart = function(c) return c == "Part" or c == "WedgePart" or c == "CornerWedgePart" end,
	Model = function(c) return c == "Model" or c == "Workspace" end,
	Light = function(c) return c == "PointLight" or c == "SpotLight" or c == "SurfaceLight" end,
	DataModelMesh = function(c) return c == "SpecialMesh" or c == "BlockMesh" or c == "CylinderMesh" end,
	JointInstance = function(c) return c == "Weld" or c == "Motor6D" or c == "ManualWeld" end,
	Constraint = function(c) return c:find("Constraint") ~= nil end,
	GuiObject = function(c) return c:find("Frame") or c:find("Label") or c:find("Button") or c:find("Image") end,
	LuaSourceContainer = function(c) return c == "Script" or c == "LocalScript" or c == "ModuleScript" end,
	BaseScript = function(c) return c == "Script" or c == "LocalScript" end,
}

local Inst = {}
local getters, setters = {}, {}

local function isPart(o) return PART_CLASSES[rawget(o, "ClassName")] end

local function defaultsFor(cls, o)
	if PART_CLASSES[cls] then
		o._p.Size = v3(4, 1, 2)
		if cls == "WedgePart" or cls == "CornerWedgePart" then o._p.Size = v3(4, 1, 2) end
		if cls == "TrussPart" then o._p.Size = v3(2, 2, 2) end
		if cls == "SpawnLocation" then o._p.Size = v3(12, 1, 12) end
		o._p.CFrame = IDENT
		o._p.Color = Color3.fromRGB(163, 162, 165)
		o._p.Transparency = 0
		o._p.Reflectance = 0
		o._p.Material = Enum.Material.Plastic
		o._p.Shape = Enum.PartType.Block
		o._p.Anchored = false
		o._p.CanCollide = true
		o._p.CastShadow = true
		for _, f in ipairs({"TopSurface","BottomSurface","LeftSurface","RightSurface","FrontSurface","BackSurface"}) do
			o._p[f] = Enum.SurfaceType.Smooth
		end
		if cls == "SpawnLocation" then o._p.TopSurface = Enum.SurfaceType.Smooth end
	end
end

local InstMT = {}
InstMT.__index = function(o, k)
	local g = getters[k]
	if g then local ok, v = g(o) if ok then return v end end
	local p = rawget(o, "_p")
	local v = p[k]
	if v ~= nil then return v end
	local m = Inst[k]
	if m ~= nil then return m end
	-- child lookup by name, like Roblox's dot access
	for _, c in ipairs(rawget(o, "_ch")) do if rawget(c, "_p").Name == k then return c end end
	if k:match("Changed$") or k == "ChildAdded" or k == "ChildRemoved" or k == "Touched" or k == "TouchEnded"
		or k == "DescendantAdded" or k == "DescendantRemoving" or k == "AncestryChanged" or k == "Destroying" then
		local s = signal() p[k] = s return s
	end
	return nil
end
InstMT.__newindex = function(o, k, v)
	local s = setters[k]
	if s and s(o, v) then return end
	rawget(o, "_p")[k] = v
end
InstMT.__tostring = function(o) return rawget(o, "_p").Name or "Instance" end

local function setParent(o, parent)
	local old = rawget(o, "_parent")
	if old == parent then return end
	if old then
		local ch = rawget(old, "_ch")
		for i = #ch, 1, -1 do if ch[i] == o then table.remove(ch, i) break end end
	end
	rawset(o, "_parent", parent)
	if parent then
		if rawget(o, "_destroyed") then error("The Parent property of " .. tostring(o) .. " is locked", 3) end
		local ch = rawget(parent, "_ch")
		ch[#ch+1] = o
	end
end

getters.Parent = function(o) return true, rawget(o, "_parent") end
setters.Parent = function(o, v) setParent(o, v) return true end
getters.ClassName = function(o) return true, rawget(o, "ClassName") end
getters.Position = function(o) local cf = rawget(o, "_p").CFrame if cf then return true, cf.Position end return false end
setters.Position = function(o, v)
	local p = rawget(o, "_p")
	if not p.CFrame then return false end
	local c = p.CFrame
	p.CFrame = mk(v[1], v[2], v[3], c[4],c[5],c[6],c[7],c[8],c[9],c[10],c[11],c[12])
	return true
end
local function deg(x) return x * 180 / math.pi end
local function rad(x) return x * math.pi / 180 end
getters.Orientation = function(o)
	local cf = rawget(o, "_p").CFrame
	if not cf then return false end
	local x, y, z = CF.ToEulerAnglesYXZ(cf)
	return true, v3(deg(x), deg(y), deg(z))
end
setters.Orientation = function(o, v)
	local p = rawget(o, "_p")
	if not p.CFrame then return false end
	local c = p.CFrame
	local r = yxz(rad(v[1]), rad(v[2]), rad(v[3]))
	p.CFrame = r + v3(c[1], c[2], c[3])
	return true
end
getters.Rotation = function(o)
	local cf = rawget(o, "_p").CFrame
	if not cf or not isPart(o) then return false end
	local x, y, z = CF.ToEulerAnglesXYZ(cf)
	return true, v3(deg(x), deg(y), deg(z))
end
setters.Rotation = function(o, v)
	if not isPart(o) then return false end
	local p = rawget(o, "_p")
	local c = p.CFrame
	p.CFrame = angles(rad(v[1]), rad(v[2]), rad(v[3])) + v3(c[1], c[2], c[3])
	return true
end
getters.BrickColor = function(o)
	local c = rawget(o, "_p").Color
	if not c or getmetatable(c) ~= C3 then return false end
	return true, bcNearest(c)
end
setters.BrickColor = function(o, v)
	if getmetatable(v) == BC then rawget(o, "_p").Color = rawget(v, "_c") rawget(o, "_p")._bcName = rawget(v, "_n") return true end
	return false
end
setters.Color = function(o, v) rawget(o, "_p").Color = v rawget(o, "_p")._bcName = nil return true end
getters.Name = function(o) return true, rawget(o, "_p").Name end
getters.PrimaryPart = function(o) return true, rawget(o, "_p").PrimaryPart end
getters.Size = function(o) local s = rawget(o, "_p").Size if s ~= nil then return true, s end return false end
setters.Size = function(o, v)
	if isPart(o) then
		v = v3(math.max(v[1], 0.001), math.max(v[2], 0.001), math.max(v[3], 0.001))
	end
	rawget(o, "_p").Size = v
	return true
end
getters.WorldPivot = function(o)
	local p = rawget(o, "_p")
	if p.WorldPivot then return true, p.WorldPivot end
	return true, Inst.GetPivot(o)
end

local allParts = {}

local function newInstance(cls, parent)
	cls = tostring(cls)
	local o = { __isInstance = true, ClassName = cls, _p = { Name = cls }, _ch = {} }
	setmetatable(o, InstMT)
	defaultsFor(cls, o)
	if PART_CLASSES[cls] then
		partCount = partCount + 1
		if partCount > MAXPARTS then error("preview limit: more than " .. MAXPARTS .. " parts", 2) end
		allParts[#allParts+1] = o
	end
	if parent then setParent(o, parent) end
	return o
end

function Inst.IsA(o, cls)
	local c = rawget(o, "ClassName")
	if cls == c or cls == "Instance" then return true end
	local f = INHERIT[cls]
	return f and f(c) and true or false
end
function Inst.GetChildren(o) local r = {} for i, c in ipairs(rawget(o, "_ch")) do r[i] = c end return r end
function Inst.GetDescendants(o)
	local r = {}
	local function walk(x) for _, c in ipairs(rawget(x, "_ch")) do r[#r+1] = c walk(c) end end
	walk(o)
	return r
end
function Inst.FindFirstChild(o, name, recursive)
	for _, c in ipairs(rawget(o, "_ch")) do if rawget(c, "_p").Name == name then return c end end
	if recursive then
		for _, c in ipairs(rawget(o, "_ch")) do local f = Inst.FindFirstChild(c, name, true) if f then return f end end
	end
	return nil
end
Inst.WaitForChild = function(o, name) return Inst.FindFirstChild(o, name) end
function Inst.FindFirstChildOfClass(o, cls)
	for _, c in ipairs(rawget(o, "_ch")) do if rawget(c, "ClassName") == cls then return c end end
	return nil
end
function Inst.FindFirstChildWhichIsA(o, cls, recursive)
	for _, c in ipairs(rawget(o, "_ch")) do if Inst.IsA(c, cls) then return c end end
	if recursive then
		for _, c in ipairs(rawget(o, "_ch")) do local f = Inst.FindFirstChildWhichIsA(c, cls, true) if f then return f end end
	end
	return nil
end
function Inst.FindFirstAncestor(o, name)
	local p = rawget(o, "_parent")
	while p do if rawget(p, "_p").Name == name then return p end p = rawget(p, "_parent") end
	return nil
end
function Inst.FindFirstAncestorOfClass(o, cls)
	local p = rawget(o, "_parent")
	while p do if rawget(p, "ClassName") == cls then return p end p = rawget(p, "_parent") end
	return nil
end
Inst.FindFirstAncestorWhichIsA = function(o, cls)
	local p = rawget(o, "_parent")
	while p do if Inst.IsA(p, cls) then return p end p = rawget(p, "_parent") end
	return nil
end
function Inst.IsDescendantOf(o, a)
	local p = rawget(o, "_parent")
	while p do if p == a then return true end p = rawget(p, "_parent") end
	return false
end
function Inst.IsAncestorOf(o, d) return Inst.IsDescendantOf(d, o) end
function Inst.Destroy(o)
	for _, c in ipairs(Inst.GetChildren(o)) do Inst.Destroy(c) end
	setParent(o, nil)
	rawset(o, "_destroyed", true)
end
Inst.Remove = Inst.Destroy
function Inst.ClearAllChildren(o) for _, c in ipairs(Inst.GetChildren(o)) do Inst.Destroy(c) end end
function Inst.Clone(o)
	local c = newInstance(rawget(o, "ClassName"))
	for k, v in pairs(rawget(o, "_p")) do rawget(c, "_p")[k] = v end
	for _, ch in ipairs(rawget(o, "_ch")) do
		local cc = Inst.Clone(ch)
		setParent(cc, c)
		if rawget(o, "_p").PrimaryPart == ch then rawget(c, "_p").PrimaryPart = cc end
	end
	return c
end
function Inst.GetFullName(o)
	local names = {}
	local x = o
	while x do table.insert(names, 1, rawget(x, "_p").Name) x = rawget(x, "_parent") end
	return table.concat(names, ".")
end
function Inst.GetPropertyChangedSignal() return signal() end
function Inst.GetAttribute(o, k) local a = rawget(o, "_attr") return a and a[k] end
function Inst.SetAttribute(o, k, v) local a = rawget(o, "_attr") or {} rawset(o, "_attr", a) a[k] = v end
function Inst.GetAttributes(o) return rawget(o, "_attr") or {} end
function Inst.AddTag() end
function Inst.RemoveTag() end
function Inst.HasTag() return false end
function Inst.BreakJoints() end
function Inst.MakeJoints() end
function Inst.Resize() return true end
function Inst.SetNetworkOwner() end
function Inst.GetMass(o) local s = rawget(o, "_p").Size return s and s[1]*s[2]*s[3] * 0.7 or 0 end

local function partsUnder(o)
	local r = {}
	if isPart(o) then r[1] = o end
	for _, d in ipairs(Inst.GetDescendants(o)) do if isPart(d) then r[#r+1] = d end end
	return r
end
local function boundingBox(o)
	local mn, mx = v3(1e9,1e9,1e9), v3(-1e9,-1e9,-1e9)
	local any = false
	for _, pt in ipairs(partsUnder(o)) do
		local cf, s = rawget(pt, "_p").CFrame, rawget(pt, "_p").Size
		local h = s * 0.5
		for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
			local w = cpoint(cf, v3(h[1]*sx, h[2]*sy, h[3]*sz))
			mn = V3.Min(mn, w) mx = V3.Max(mx, w) any = true
		end end end
	end
	if not any then return IDENT, v3(0,0,0) end
	return CFrame.new((mn + mx) * 0.5), mx - mn
end
function Inst.GetBoundingBox(o) return boundingBox(o) end
function Inst.GetExtentsSize(o) local _, s = boundingBox(o) return s end
function Inst.GetPivot(o)
	local p = rawget(o, "_p")
	if isPart(o) then return p.CFrame end
	if p.WorldPivot then return p.WorldPivot end
	if p.PrimaryPart then return rawget(p.PrimaryPart, "_p").CFrame end
	local cf = boundingBox(o)
	return cf
end
function Inst.PivotTo(o, target)
	local pivot = Inst.GetPivot(o)
	local delta = cmul(target, cinv(pivot))
	for _, pt in ipairs(partsUnder(o)) do
		local pp = rawget(pt, "_p")
		pp.CFrame = cmul(delta, pp.CFrame)
	end
	local p = rawget(o, "_p")
	if p.WorldPivot then p.WorldPivot = cmul(delta, p.WorldPivot) end
end
function Inst.SetPrimaryPartCFrame(o, cf)
	local pp = rawget(o, "_p").PrimaryPart
	if not pp then error("Model:SetPrimaryPartCFrame() failed because no PrimaryPart has been set", 2) end
	local delta = cmul(cf, cinv(rawget(pp, "_p").CFrame))
	for _, pt in ipairs(partsUnder(o)) do local q = rawget(pt, "_p") q.CFrame = cmul(delta, q.CFrame) end
end
function Inst.GetPrimaryPartCFrame(o) local pp = rawget(o, "_p").PrimaryPart return pp and rawget(pp, "_p").CFrame or nil end
function Inst.TranslateBy(o, v) Inst.PivotTo(o, Inst.GetPivot(o) + v) end
function Inst.MoveTo(o, pos)
	local pv = Inst.GetPivot(o)
	Inst.PivotTo(o, pv - pv.Position + pos)
end
function Inst.GetScale(o) return rawget(o, "_scale") or 1 end
function Inst.ScaleTo(o, s)
	local cur = rawget(o, "_scale") or 1
	local f = s / cur
	local pivot = Inst.GetPivot(o)
	for _, pt in ipairs(partsUnder(o)) do
		local q = rawget(pt, "_p")
		local rel = cmul(cinv(pivot), q.CFrame)
		rel = mk(rel[1]*f, rel[2]*f, rel[3]*f, rel[4],rel[5],rel[6],rel[7],rel[8],rel[9],rel[10],rel[11],rel[12])
		q.CFrame = cmul(pivot, rel)
		q.Size = q.Size * f
	end
	rawset(o, "_scale", s)
end
-- CSG: approximate a union as the merged visible pieces (negates dropped)
function Inst.UnionAsync(o, others)
	local u = newInstance("UnionOperation")
	local pieces = {}
	local function add(x)
		if rawget(x, "ClassName") == "NegateOperation" then return end
		local pieceList = rawget(x, "_pieces")
		if pieceList then
			for _, pc in ipairs(pieceList) do pieces[#pieces+1] = pc end
		else
			local xp = rawget(x, "_p")
			pieces[#pieces+1] = {cls = rawget(x, "ClassName"), size = xp.Size, cf = xp.CFrame, color = xp.Color, shape = xp.Shape, mat = xp.Material}
		end
	end
	add(o)
	for _, x in ipairs(others or {}) do add(x) end
	rawset(u, "_pieces", pieces)
	local cf, size = boundingBox(o)
	rawget(u, "_p").CFrame = rawget(o, "_p").CFrame
	rawget(u, "_p").Size = size
	rawget(u, "_p").Color = rawget(o, "_p").Color
	rawget(u, "_p").Material = rawget(o, "_p").Material
	rawset(u, "_pieceOrigin", rawget(o, "_p").CFrame)
	return u
end
Inst.SubtractAsync = function(o) return Inst.UnionAsync(o, {}) end
Inst.IntersectAsync = function(o) return Inst.UnionAsync(o, {}) end

Instance = { new = function(cls, parent) return newInstance(cls, parent) end, fromExisting = function(o) return Inst.Clone(o) end }

----------------------------------------------------------------- game / workspace
local DataModel = newInstance("DataModel")
rawget(DataModel, "_p").Name = "Game"
local WS = newInstance("Workspace", DataModel)
rawget(WS, "_p").Name = "Workspace"
local cam = newInstance("Camera", WS)
rawget(cam, "_p").Name = "Camera"
rawget(cam, "_p").CFrame = CFrame.new(0, 20, 40)
rawget(WS, "_p").CurrentCamera = cam
rawget(WS, "_p").Gravity = 196.2
local terrain = newInstance("Terrain", WS)
rawget(terrain, "_p").Name = "Terrain"
for _, nm in ipairs({"FillBlock","FillBall","FillCylinder","FillWedge","Clear","FillRegion","WriteVoxels"}) do
	rawget(terrain, "_p")[nm] = function() end
end
function Inst.Raycast() return nil end
function Inst.GetPartBoundsInBox() return {} end
function Inst.GetPartBoundsInRadius() return {} end
function Inst.GetPartsInPart() return {} end
function Inst.GetServerTimeNow() return 0 end
local services = { Workspace = WS }
function Inst.GetService(o, name)
	if name == "Workspace" then return WS end
	local s = services[name]
	if not s then
		s = newInstance(name, DataModel)
		rawget(s, "_p").Name = name
		services[name] = s
		if name == "RunService" then
			local sp = rawget(s, "_p")
			sp.IsStudio = function() return true end
			sp.IsServer = function() return true end
			sp.IsClient = function() return false end
			sp.IsRunning = function() return false end
			sp.IsEdit = function() return true end
			sp.Heartbeat = signal() sp.Stepped = signal() sp.RenderStepped = signal()
		elseif name == "ChangeHistoryService" then
			local sp = rawget(s, "_p")
			sp.SetWaypoint = function() end
			sp.TryBeginRecording = function() return "rec" end
			sp.FinishRecording = function() end
		elseif name == "Selection" then
			local sp = rawget(s, "_p")
			sp.Get = function() return {} end
			sp.Set = function() end
		elseif name == "TweenService" then
			rawget(s, "_p").Create = function() return { Play = function() end, Completed = signal() } end
		elseif name == "HttpService" then
			local sp = rawget(s, "_p")
			sp.GenerateGUID = function() return "00000000-0000-0000-0000-000000000000" end
			sp.JSONEncode = function() return "{}" end
			sp.JSONDecode = function() return {} end
		elseif name == "CollectionService" then
			local sp = rawget(s, "_p")
			sp.AddTag = function() end sp.GetTagged = function() return {} end sp.HasTag = function() return false end
		elseif name == "Players" then
			rawget(s, "_p").GetPlayers = function() return {} end
			rawget(s, "_p").PlayerAdded = signal()
		end
	end
	return s
end
Inst.FindService = Inst.GetService
function Inst.GetObjects() return {} end
function Inst.InsertService() return nil end
game = DataModel
workspace = WS
Workspace = WS
script = newInstance("Script")
plugin = nil
shared = {}
_G.shared = shared

----------------------------------------------------------------- export
local function fmt(n) if n ~= n then return "0" end return string.format("%.4g", n) end
local SURF = {"RightSurface","LeftSurface","TopSurface","BottomSurface","BackSurface","FrontSurface"}
local function surfFlags(p)
	local mv = p.MaterialVariant
	if type(mv) == "string" and (mv:find("Stud") or mv:find("Universal")) then return "111111" end
	local s = {}
	for i, f in ipairs(SURF) do
		local v = p[f]
		s[i] = (v and v.Name == "Studs") and "1" or ((v and v.Name == "Inlet") and "2" or "0")
	end
	return table.concat(s)
end
local function shapeCode(cls, p)
	if cls == "WedgePart" then return "w" end
	if cls == "CornerWedgePart" then return "k" end
	if cls == "Part" or cls == "SpawnLocation" or cls == "Seat" or cls == "VehicleSeat" then
		local sh = p.Shape and p.Shape.Name or "Block"
		if sh == "Ball" then return "s" elseif sh == "Cylinder" then return "c" end
		if sh == "Wedge" then return "w" elseif sh == "CornerWedge" then return "k" end
	end
	return "b"
end
local function emitPiece(out, code, size, cf, color, transp, mat, flags, name)
	local c = color or c3(0.64, 0.64, 0.65)
	out[#out+1] = table.concat({code, fmt(size[1]), fmt(size[2]), fmt(size[3]),
		fmt(cf[1]), fmt(cf[2]), fmt(cf[3]), fmt(cf[4]), fmt(cf[5]), fmt(cf[6]), fmt(cf[7]), fmt(cf[8]), fmt(cf[9]), fmt(cf[10]), fmt(cf[11]), fmt(cf[12]),
		fmt(c[1]), fmt(c[2]), fmt(c[3]), fmt(transp or 0), (mat and mat.Name) or "Plastic", flags or "000000", (tostring(name or ""):gsub("[,\n\r\t]", " "))}, ",")
end
function __export(ok, err)
	local out = {}
	local shown = 0
	for _, o in ipairs(allParts) do
		if not rawget(o, "_destroyed") and Inst.IsDescendantOf(o, WS) then
			local p = rawget(o, "_p")
			local cls = rawget(o, "ClassName")
			local tr = p.Transparency or 0
			local pieces = rawget(o, "_pieces")
			if cls == "NegateOperation" then
				-- not visible
			elseif pieces then
				local origin = rawget(o, "_pieceOrigin") or p.CFrame
				local delta = cmul(p.CFrame, cinv(origin))
				for _, pc in ipairs(pieces) do
					local code = (pc.cls == "WedgePart" and "w") or (pc.cls == "CornerWedgePart" and "k") or
						((pc.shape and pc.shape.Name == "Ball") and "s") or ((pc.shape and pc.shape.Name == "Cylinder") and "c") or "b"
					if tr < 0.98 then emitPiece(out, code, pc.size, cmul(delta, pc.cf), p.Color or pc.color, tr, p.Material or pc.mat, "000000", p.Name or rawget(o, "Name")) shown = shown + 1 end
				end
			elseif tr < 0.98 and p.Size and p.CFrame then
				emitPiece(out, shapeCode(cls, p), p.Size, p.CFrame, p.Color, tr, p.Material, surfFlags(p), p.Name or rawget(o, "Name"))
				shown = shown + 1
			end
		end
	end
	local header = (ok and "OK" or ("ERR " .. tostring(err))) .. "\n" .. table.concat(LOGS, "\t")
	return header .. "\n" .. table.concat(out, "\n")
end
