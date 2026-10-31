--[[
	Brickwright for Roblox Studio — https://brickwright.netlify.app/plugin
	Insert your Brickwright builds and GUIs straight into your game.
	1. Get your plugin code at brickwright.netlify.app/plugin (sign in first).
	2. Click the Brickwright button in the Plugins tab, paste the code, press Connect.
	3. Press Insert on any build or GUI.
]]

local HttpService = game:GetService("HttpService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local API = "https://brickwright.netlify.app/api/plugin"
local VERSION = "1.0"

local toolbar = plugin:CreateToolbar("Brickwright")
local button = toolbar:CreateButton("Brickwright", "Insert your Brickwright builds and GUIs", "rbxassetid://6927295847")
button.ClickableWhenViewportHidden = true

-- opens floating in the middle of the screen at 680x500
local widget = plugin:CreateDockWidgetPluginGui("BrickwrightWindow", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 680, 500, 360, 320))
widget.Title = "Brickwright"
widget.Name = "Brickwright"

-- ---------------------------------------------------------------- UI helpers
local COL = {
	bg = Color3.fromRGB(22, 24, 30), panel = Color3.fromRGB(32, 35, 44), line = Color3.fromRGB(52, 56, 68),
	text = Color3.fromRGB(235, 237, 242), muted = Color3.fromRGB(150, 155, 168), accent = Color3.fromRGB(255, 107, 53),
	ok = Color3.fromRGB(75, 151, 75), err = Color3.fromRGB(230, 80, 70),
}
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function corner(o, r) new("UICorner", {CornerRadius = UDim.new(0, r or 6)}, o) return o end
local function label(text, props, parent)
	local t = new("TextLabel", {BackgroundTransparency = 1, Text = text, TextColor3 = COL.text, Font = Enum.Font.GothamMedium, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true}, parent)
	for k, v in pairs(props or {}) do t[k] = v end
	return t
end
local function btn(text, color, parent)
	local b = new("TextButton", {Text = text, BackgroundColor3 = color or COL.accent, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
		TextSize = 13, AutoButtonColor = true, Size = UDim2.new(0, 80, 0, 28)}, parent)
	return corner(b)
end

local root = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = COL.bg, BorderSizePixel = 0}, widget)
new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, root)

local header = label("Brickwright", {Size = UDim2.new(1, 0, 0, 22), Font = Enum.Font.GothamBlack, TextSize = 18}, root)
local status = label("", {Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 30), TextColor3 = COL.muted, TextSize = 12}, root)

-- connect screen
local connect = new("Frame", {Position = UDim2.new(0, 0, 0, 60), Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1}, root)
label("Paste your plugin code from brickwright.netlify.app/plugin", {Size = UDim2.new(1, 0, 0, 34), TextColor3 = COL.muted}, connect)
local codeBox = corner(new("TextBox", {Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = COL.panel, TextColor3 = COL.text,
	PlaceholderText = "bw_…", PlaceholderColor3 = COL.muted, Text = "", Font = Enum.Font.Code, TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left}, connect))
new("UIPadding", {PaddingLeft = UDim.new(0, 8)}, codeBox)
local connectBtn = btn("Connect", COL.accent, connect)
connectBtn.Position = UDim2.new(0, 0, 0, 82)
connectBtn.Size = UDim2.new(1, 0, 0, 32)

-- library screen
local lib = new("Frame", {Position = UDim2.new(0, 0, 0, 60), Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1, Visible = false}, root)
local tabBar = new("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1}, lib)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, tabBar)
local tabBuilds = btn("Builds", COL.panel, tabBar)
local tabGuis = btn("GUIs", COL.panel, tabBar)
local refreshBtn = btn("Refresh", COL.panel, tabBar)
local logoutBtn = btn("Log out", COL.panel, tabBar)
logoutBtn.Size = UDim2.new(0, 64, 0, 28)
local list = new("ScrollingFrame", {Position = UDim2.new(0, 0, 0, 38), Size = UDim2.new(1, 0, 1, -38), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 5, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, lib)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, list)

local function setStatus(text, kind)
	status.Text = text
	status.TextColor3 = kind == "ok" and COL.ok or kind == "err" and COL.err or COL.muted
end

-- ---------------------------------------------------------------- API
local code = plugin:GetSetting("BrickwrightCode")
local data = {builds = {}, guis = {}}
local current = "builds"

local function request(query)
	local ok, res = pcall(HttpService.RequestAsync, HttpService, {
		Url = API .. "?" .. query, Method = "GET",
		Headers = {Authorization = "Bearer " .. tostring(code), ["X-Plugin-Version"] = VERSION},
	})
	if not ok then return nil, "Couldn't reach Brickwright: " .. tostring(res) end
	local okJson, body = pcall(HttpService.JSONDecode, HttpService, res.Body)
	if not okJson then return nil, "Bad reply from Brickwright (" .. res.StatusCode .. ")" end
	if not res.Success then return nil, body.error or ("Error " .. res.StatusCode), res.StatusCode end
	return body
end

-- runs a Brickwright script (same as pasting it into the command bar)
local function runScript(source, name)
	local mod = Instance.new("ModuleScript")
	mod.Name = "BrickwrightInsert"
	mod.Source = "return function()\n" .. source .. "\nend"
	mod.Parent = game:GetService("ServerStorage")
	local recording
	pcall(function() recording = ChangeHistoryService:TryBeginRecording("Insert " .. name) end)
	local ok, err = pcall(function() require(mod)() end)
	mod:Destroy()
	if recording then pcall(function() ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit) end)
	else pcall(function() ChangeHistoryService:SetWaypoint("Insert " .. name) end) end
	return ok, err
end

local function renderList()
	for _, c in ipairs(list:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end end
	tabBuilds.BackgroundColor3 = current == "builds" and COL.accent or COL.panel
	tabGuis.BackgroundColor3 = current == "guis" and COL.accent or COL.panel
	local items = data[current] or {}
	if #items == 0 then
		label(current == "builds" and "No builds yet — make one at brickwright.netlify.app/studio" or "No GUIs yet — make one at brickwright.netlify.app/gui",
			{Size = UDim2.new(1, 0, 0, 40), TextColor3 = COL.muted}, list)
		return
	end
	for i, it in ipairs(items) do
		local row = corner(new("Frame", {Size = UDim2.new(1, -6, 0, 52), BackgroundColor3 = COL.panel, LayoutOrder = i}, list))
		new("UIStroke", {Color = COL.line, Thickness = 1}, row)
		label(it.name, {Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -110, 0, 20), Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false}, row)
		local sub = it.parts and (it.parts .. " parts") or (it.kind == "gui" and "ScreenGui" or "Model")
		label(sub, {Position = UDim2.new(0, 10, 0, 26), Size = UDim2.new(1, -110, 0, 18), TextColor3 = COL.muted, TextSize = 11}, row)
		local ins = btn("Insert", COL.ok, row)
		ins.Position = UDim2.new(1, -90, 0.5, -14)
		ins.MouseButton1Click:Connect(function()
			ins.Text = "…"
			setStatus("Downloading " .. it.name .. "…")
			local body, err = request((it.kind == "gui" and "gui=" or "build=") .. HttpService:UrlEncode(it.id))
			if not body then setStatus(err, "err") ins.Text = "Insert" return end
			setStatus("Building " .. it.name .. "…")
			local ok, runErr = runScript(body.script, it.name)
			ins.Text = "Insert"
			if ok then setStatus("Inserted " .. it.name .. (it.kind == "gui" and " into StarterGui" or " into Workspace"), "ok")
			else setStatus("Script error: " .. tostring(runErr), "err") end
		end)
	end
end

local function showLibrary(on)
	connect.Visible = not on
	lib.Visible = on
end

local function refresh()
	setStatus("Loading your library…")
	local body, err, statusCode = request("list=1")
	if not body then
		setStatus(err, "err")
		if statusCode == 401 then code = nil plugin:SetSetting("BrickwrightCode", nil) showLibrary(false) end
		return false
	end
	data.builds, data.guis = body.builds or {}, body.guis or {}
	setStatus(#data.builds .. " builds · " .. #data.guis .. " GUIs", "ok")
	showLibrary(true)
	renderList()
	return true
end

connectBtn.MouseButton1Click:Connect(function()
	local c = codeBox.Text:gsub("%s", "")
	if c == "" then setStatus("Paste your plugin code first.", "err") return end
	code = c
	if refresh() then plugin:SetSetting("BrickwrightCode", c) codeBox.Text = "" end
end)
tabBuilds.MouseButton1Click:Connect(function() current = "builds" renderList() end)
tabGuis.MouseButton1Click:Connect(function() current = "guis" renderList() end)
refreshBtn.MouseButton1Click:Connect(refresh)
logoutBtn.MouseButton1Click:Connect(function()
	code = nil
	plugin:SetSetting("BrickwrightCode", nil)
	showLibrary(false)
	setStatus("Logged out.")
end)

button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	if widget.Enabled and code and not lib.Visible then refresh() end
end)
widget:GetPropertyChangedSignal("Enabled"):Connect(function() button:SetActive(widget.Enabled) end)

if code then setStatus("Open to load your library.") else setStatus("Not connected.") end
