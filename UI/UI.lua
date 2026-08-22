-- ==============================================================================
-- HoshiUI — Premium, Lightweight & High-Performance Roblox UI Library
-- Architecture engineered with Flipper Spring Physics & Fluent Theme Tagging
-- Repository: 0x0228/HoshiHub
-- ==============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==============================================================================
-- 1. FAST SIGNAL ENGINE
-- ==============================================================================
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ _connections = {} }, Signal)
end

function Signal:Connect(fn)
    local connection = {
        _fn = fn,
        _signal = self,
        Connected = true,
        Disconnect = function(self)
            if not self.Connected then return end
            self.Connected = false
            for i, conn in ipairs(self._signal._connections) do
                if conn == self then
                    table.remove(self._signal._connections, i)
                    break
                end
            end
        end
    }
    table.insert(self._connections, connection)
    return connection
end

function Signal:Fire(...)
    for _, conn in ipairs(self._connections) do
        if conn.Connected then
            task.spawn(conn._fn, ...)
        end
    end
end

function Signal:Destroy()
    for _, conn in ipairs(self._connections) do
        conn.Connected = false
    end
    self._connections = {}
end

-- ==============================================================================
-- 2. FLIPPER SPRING PHYSICS MOTOR ENGINE
-- ==============================================================================
local Flipper = {}

local BaseMotor = {}
BaseMotor.__index = BaseMotor

function BaseMotor.new()
    return setmetatable({
        _onStep = Signal.new(),
        _onComplete = Signal.new(),
    }, BaseMotor)
end

function BaseMotor:onStep(fn) return self._onStep:Connect(fn) end
function BaseMotor:onComplete(fn) return self._onComplete:Connect(fn) end
function BaseMotor:destroy()
    self._onStep:Destroy()
    self._onComplete:Destroy()
end

local Spring = {}
Spring.__index = Spring

function Spring.new(targetValue, options)
    options = options or {}
    return setmetatable({
        _targetValue = targetValue,
        _frequency = options.frequency or 6,
        _dampingRatio = options.dampingRatio or 1,
        _initialVelocity = options.initialVelocity or 0,
    }, Spring)
end

function Spring:step(state, dt)
    local d = self._dampingRatio
    local f = self._frequency * 2 * math.pi
    local g = self._targetValue
    local p0 = state.position
    local v0 = state.velocity

    local offset = p0 - g
    local decay = math.exp(-d * f * dt)

    local p1, v1
    if d == 1 then
        p1 = (offset * (1 + f * dt) + v0 * dt) * decay + g
        v1 = (v0 * (1 - f * dt) - offset * (f * f * dt)) * decay
    elseif d < 1 then
        local c = math.sqrt(1 - d * d)
        local i = math.cos(f * c * dt)
        local j = math.sin(f * c * dt)
        p1 = (offset * (i + (d / c) * j) + (v0 / (f * c)) * j) * decay + g
        v1 = (v0 * (i - (d / c) * j) - offset * ((f / c) * j)) * decay
    else
        local c = math.sqrt(d * d - 1)
        local r1 = -f * (d - c)
        local r2 = -f * (d + c)
        local co2 = (v0 - offset * r1) / (2 * f * c)
        local co1 = offset - co2
        local e1 = math.exp(r1 * dt)
        local e2 = math.exp(r2 * dt)
        p1 = co1 * e1 + co2 * e2 + g
        v1 = co1 * r1 * e1 + co2 * r2 * e2
    end

    local complete = math.abs(v1) < 0.001 and math.abs(p1 - g) < 0.001
    if complete then p1 = g v1 = 0 end
    return { position = p1, velocity = v1, complete = complete }
end

local Instant = {}
Instant.__index = Instant

function Instant.new(targetValue)
    return setmetatable({ _targetValue = targetValue }, Instant)
end

function Instant:step()
    return { position = self._targetValue, velocity = 0, complete = true }
end

local SingleMotor = setmetatable({}, BaseMotor)
SingleMotor.__index = SingleMotor

function SingleMotor.new(initialValue)
    local self = setmetatable(BaseMotor.new(), SingleMotor)
    self._state = { position = initialValue or 0, velocity = 0, complete = true }
    self._goal = nil
    self._connection = nil
    return self
end

function SingleMotor:getValue() return self._state.position end
function SingleMotor:setValue(val) self._state.position = val self._state.velocity = 0 self._state.complete = true end

function SingleMotor:setGoal(goal)
    self._goal = goal
    self._state.complete = false
    self:_start()
end

function SingleMotor:_start()
    if self._connection then return end
    self._connection = RunService.RenderStepped:Connect(function(dt)
        if not self._goal then return end
        local nextState = self._goal:step(self._state, dt)
        self._state = nextState
        self._onStep:Fire(nextState.position)
        if nextState.complete then
            self._onComplete:Fire()
            self:stop()
        end
    end)
end

function SingleMotor:stop()
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
end

local GroupMotor = setmetatable({}, BaseMotor)
GroupMotor.__index = GroupMotor

function GroupMotor.new(initialValues)
    local self = setmetatable(BaseMotor.new(), GroupMotor)
    self._state = {}
    for k, v in pairs(initialValues) do
        self._state[k] = { position = v, velocity = 0, complete = true }
    end
    self._goal = {}
    self._connection = nil
    return self
end

function GroupMotor:getValue()
    local values = {}
    for k, s in pairs(self._state) do values[k] = s.position end
    return values
end

function GroupMotor:setGoal(goals)
    self._goal = goals
    for k, goal in pairs(goals) do
        if type(goal) == "number" then
            self._goal[k] = Spring.new(goal)
        end
        if self._state[k] then self._state[k].complete = false end
    end
    self:_start()
end

function GroupMotor:_start()
    if self._connection then return end
    self._connection = RunService.RenderStepped:Connect(function(dt)
        local allComplete = true
        local currentValues = {}
        for k, goal in pairs(self._goal) do
            if self._state[k] then
                local nextState = goal:step(self._state[k], dt)
                self._state[k] = nextState
                currentValues[k] = nextState.position
                if not nextState.complete then allComplete = false end
            end
        end
        self._onStep:Fire(currentValues)
        if allComplete then
            self._onComplete:Fire()
            self:stop()
        end
    end)
end

function GroupMotor:stop()
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
end

Flipper.Spring = Spring
Flipper.Instant = Instant
Flipper.SingleMotor = SingleMotor
Flipper.GroupMotor = GroupMotor

-- ==============================================================================
-- 3. THEME REGISTRY & PRESETS
-- ==============================================================================
local Themes = {
    ["Hoshi"] = {
        Background = Color3.fromRGB(15, 20, 29),       -- Deep cosmic navy
        CardBackground = Color3.fromRGB(24, 32, 45),   -- Starry slate container
        CardHover = Color3.fromRGB(33, 44, 61),        -- Celestial luminous hover
        CardStroke = Color3.fromRGB(48, 64, 88),       -- Star-tinted stroke
        Border = Color3.fromRGB(40, 54, 74),           -- Twilight border
        Accent = Color3.fromRGB(247, 230, 185),        -- Cosmic champagne starlight gold
        AccentHover = Color3.fromRGB(255, 243, 212),   -- Luminous starlight shine
        AccentGlow = Color3.fromRGB(247, 230, 185),    -- Warm planetary glow
        Text = Color3.fromRGB(250, 248, 244),          -- Celestial ivory
        SubText = Color3.fromRGB(156, 178, 198),       -- Muted twilight blue-gray
        Success = Color3.fromRGB(120, 215, 175),       -- Aurora mint
        Warning = Color3.fromRGB(247, 205, 125),       -- Starburst amber
        Danger = Color3.fromRGB(245, 100, 120),        -- Supernova rose
        Sidebar = Color3.fromRGB(11, 15, 22),          -- Deep midnight sidebar
        ToggleOff = Color3.fromRGB(36, 48, 66),        -- Muted cosmic toggle
    },
    ["Dark"] = {
        Background = Color3.fromRGB(16, 17, 22),
        CardBackground = Color3.fromRGB(24, 25, 33),
        CardHover = Color3.fromRGB(30, 32, 42),
        CardStroke = Color3.fromRGB(42, 44, 58),
        Border = Color3.fromRGB(38, 40, 52),
        Accent = Color3.fromRGB(75, 130, 255),
        AccentHover = Color3.fromRGB(95, 145, 255),
        AccentGlow = Color3.fromRGB(75, 130, 255),
        Text = Color3.fromRGB(240, 242, 248),
        SubText = Color3.fromRGB(150, 155, 175),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Danger = Color3.fromRGB(231, 76, 60),
        Sidebar = Color3.fromRGB(13, 14, 18),
        ToggleOff = Color3.fromRGB(45, 48, 62),
    },
    ["Midnight"] = {
        Background = Color3.fromRGB(10, 11, 15),
        CardBackground = Color3.fromRGB(17, 18, 26),
        CardHover = Color3.fromRGB(23, 25, 36),
        CardStroke = Color3.fromRGB(32, 35, 50),
        Border = Color3.fromRGB(28, 30, 44),
        Accent = Color3.fromRGB(114, 90, 242),
        AccentHover = Color3.fromRGB(135, 112, 255),
        AccentGlow = Color3.fromRGB(114, 90, 242),
        Text = Color3.fromRGB(245, 246, 250),
        SubText = Color3.fromRGB(140, 145, 168),
        Success = Color3.fromRGB(50, 215, 130),
        Warning = Color3.fromRGB(255, 190, 30),
        Danger = Color3.fromRGB(255, 75, 75),
        Sidebar = Color3.fromRGB(7, 8, 12),
        ToggleOff = Color3.fromRGB(38, 40, 56),
    },
    ["Amethyst"] = {
        Background = Color3.fromRGB(18, 14, 26),
        CardBackground = Color3.fromRGB(27, 21, 39),
        CardHover = Color3.fromRGB(36, 28, 52),
        CardStroke = Color3.fromRGB(52, 40, 75),
        Border = Color3.fromRGB(46, 35, 66),
        Accent = Color3.fromRGB(168, 85, 247),
        AccentHover = Color3.fromRGB(192, 120, 255),
        AccentGlow = Color3.fromRGB(168, 85, 247),
        Text = Color3.fromRGB(248, 245, 255),
        SubText = Color3.fromRGB(170, 155, 195),
        Success = Color3.fromRGB(52, 211, 153),
        Warning = Color3.fromRGB(251, 191, 36),
        Danger = Color3.fromRGB(248, 113, 113),
        Sidebar = Color3.fromRGB(13, 10, 20),
        ToggleOff = Color3.fromRGB(50, 40, 68),
    },
    ["Emerald"] = {
        Background = Color3.fromRGB(12, 19, 16),
        CardBackground = Color3.fromRGB(18, 29, 24),
        CardHover = Color3.fromRGB(24, 39, 32),
        CardStroke = Color3.fromRGB(36, 58, 48),
        Border = Color3.fromRGB(30, 50, 40),
        Accent = Color3.fromRGB(16, 185, 129),
        AccentHover = Color3.fromRGB(52, 211, 153),
        AccentGlow = Color3.fromRGB(16, 185, 129),
        Text = Color3.fromRGB(240, 253, 244),
        SubText = Color3.fromRGB(140, 175, 155),
        Success = Color3.fromRGB(16, 185, 129),
        Warning = Color3.fromRGB(245, 158, 11),
        Danger = Color3.fromRGB(239, 68, 68),
        Sidebar = Color3.fromRGB(8, 14, 12),
        ToggleOff = Color3.fromRGB(35, 52, 44),
    },
    ["Rose"] = {
        Background = Color3.fromRGB(20, 13, 16),
        CardBackground = Color3.fromRGB(31, 20, 25),
        CardHover = Color3.fromRGB(42, 27, 34),
        CardStroke = Color3.fromRGB(62, 40, 50),
        Border = Color3.fromRGB(54, 34, 44),
        Accent = Color3.fromRGB(244, 63, 94),
        AccentHover = Color3.fromRGB(251, 113, 133),
        AccentGlow = Color3.fromRGB(244, 63, 94),
        Text = Color3.fromRGB(255, 241, 242),
        SubText = Color3.fromRGB(185, 145, 155),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(245, 158, 11),
        Danger = Color3.fromRGB(244, 63, 94),
        Sidebar = Color3.fromRGB(15, 9, 12),
        ToggleOff = Color3.fromRGB(58, 38, 48),
    },
    ["Cyberpunk"] = {
        Background = Color3.fromRGB(11, 12, 16),
        CardBackground = Color3.fromRGB(19, 20, 28),
        CardHover = Color3.fromRGB(26, 28, 38),
        CardStroke = Color3.fromRGB(45, 48, 66),
        Border = Color3.fromRGB(38, 42, 58),
        Accent = Color3.fromRGB(0, 230, 200),
        AccentHover = Color3.fromRGB(40, 255, 225),
        AccentGlow = Color3.fromRGB(0, 230, 200),
        Text = Color3.fromRGB(245, 250, 255),
        SubText = Color3.fromRGB(135, 150, 175),
        Success = Color3.fromRGB(0, 230, 200),
        Warning = Color3.fromRGB(255, 215, 0),
        Danger = Color3.fromRGB(255, 45, 85),
        Sidebar = Color3.fromRGB(8, 9, 12),
        ToggleOff = Color3.fromRGB(40, 44, 60),
    }
}

-- ==============================================================================
-- 4. LUCIDE ICONS & DECAL RESOLVER ENGINE
-- ==============================================================================
local BuiltinIcons = {
    ["sliders"] = "rbxassetid://10734963400",
    ["sliders-horizontal"] = "rbxassetid://10734963191",
    ["settings"] = "rbxassetid://10734950309",
    ["home"] = "rbxassetid://10723407389",
    ["palette"] = "rbxassetid://10723387841",
    ["bell"] = "rbxassetid://10709775704",
    ["bell-ring"] = "rbxassetid://10709775560",
    ["x"] = "rbxassetid://9886659671",
    ["close"] = "rbxassetid://9886659671",
    ["chevron-up"] = "rbxassetid://9886659276",
    ["minimize"] = "rbxassetid://9886659276",
    ["chevron-down"] = "rbxassetid://10709790948",
    ["chevron-left"] = "rbxassetid://10709791024",
    ["chevron-right"] = "rbxassetid://10709791175",
    ["check"] = "rbxassetid://10709790644",
    ["sparkles"] = "rbxassetid://10734974297",
    ["box"] = "rbxassetid://10709782497",
    ["shield"] = "rbxassetid://10734951847",
    ["shield-check"] = "rbxassetid://10734952136",
    ["shield-alert"] = "rbxassetid://10734952044",
    ["sword"] = "rbxassetid://10734975486",
    ["swords"] = "rbxassetid://10734975692",
    ["zap"] = "rbxassetid://10709819149",
    ["flame"] = "rbxassetid://10723376114",
    ["target"] = "rbxassetid://10734979144",
    ["eye"] = "rbxassetid://10709795498",
    ["heart"] = "rbxassetid://10709797316",
    ["terminal"] = "rbxassetid://10734982144",
    ["code"] = "rbxassetid://10709793413",
    ["cpu"] = "rbxassetid://10709794132",
    ["database"] = "rbxassetid://10709794585",
    ["folder"] = "rbxassetid://10709796387",
    ["file"] = "rbxassetid://10709795643",
    ["trash"] = "rbxassetid://10734983637",
    ["copy"] = "rbxassetid://10709793917",
    ["user"] = "rbxassetid://10734988677",
    ["users"] = "rbxassetid://10734989047",
    ["play"] = "rbxassetid://10709801822",
    ["pause"] = "rbxassetid://10709801588",
    ["info"] = "rbxassetid://10709797960",
    ["alert-triangle"] = "rbxassetid://10709753149",
    ["alert-circle"] = "rbxassetid://10709752996",
    ["lock"] = "rbxassetid://10709798779",
    ["unlock"] = "rbxassetid://10734987768",
    ["key"] = "rbxassetid://10709798082",
    ["sun"] = "rbxassetid://10734975252",
    ["moon"] = "rbxassetid://10709800652",
    ["maximize"] = "rbxassetid://9886659406",
    ["menu"] = "rbxassetid://10709799716",
    ["search"] = "rbxassetid://10709802875",
}

local CommonAliases = {
    ["slider"] = "sliders",
    ["controls"] = "sliders",
    ["gear"] = "settings",
    ["cog"] = "settings",
    ["warn"] = "alert-triangle",
    ["danger"] = "alert-circle",
    ["error"] = "alert-circle",
    ["hp"] = "heart",
    ["health"] = "heart",
    ["cube"] = "box",
    ["fire"] = "flame",
    ["lightning"] = "zap",
}

local IconEngine = {
    Icons = BuiltinIcons,
}

function IconEngine.GetIcon(iconQuery)
    if not iconQuery or iconQuery == "" then return BuiltinIcons["sparkles"] end
    if type(iconQuery) ~= "string" then
        if tonumber(iconQuery) then
            return "rbxthumb://type=Asset&id=" .. tostring(iconQuery) .. "&w=420&h=420"
        end
        return BuiltinIcons["sparkles"]
    end
    if iconQuery:sub(1, 12) == "rbxthumb://" then return iconQuery end
    if iconQuery:sub(1, 13) == "rbxassetid://" then
        local rawNum = iconQuery:sub(14)
        if tonumber(rawNum) and #rawNum >= 10 then
            return "rbxthumb://type=Asset&id=" .. rawNum .. "&w=420&h=420"
        end
        return iconQuery
    end
    if tonumber(iconQuery) then
        return "rbxthumb://type=Asset&id=" .. iconQuery .. "&w=420&h=420"
    end

    local iconName = iconQuery
    if iconQuery:find(":") then
        local parts = iconQuery:split(":")
        iconName = parts[2] or parts[1]
    elseif iconQuery:find("^lucide%-") then
        iconName = iconQuery:gsub("^lucide%-", "")
    end

    local cleanName = iconName:lower():gsub("_", "-"):gsub("%s+", "-")
    if BuiltinIcons[cleanName] then return BuiltinIcons[cleanName] end
    if CommonAliases[cleanName] and BuiltinIcons[CommonAliases[cleanName]] then
        return BuiltinIcons[CommonAliases[cleanName]]
    end
    return BuiltinIcons["sparkles"]
end

function IconEngine.ApplyDecal(imageLabel, rawQuery)
    if not imageLabel then return end
    local queryStr = tostring(rawQuery or "")
    local cleanNum = queryStr:gsub("rbxassetid://", ""):gsub("rbxthumb://type=%a+&id=", ""):gsub("&.*", ""):match("%d+")
    
    if cleanNum and #cleanNum >= 6 then
        imageLabel.Image = "rbxthumb://type=Asset&id=" .. cleanNum .. "&w=420&h=420"
    else
        imageLabel.Image = IconEngine.GetIcon(rawQuery)
    end

    local customAssetFn = getcustomasset or getsynasset
    if cleanNum and customAssetFn and writefile and readfile and isfile and makefolder then
        local cacheFolder = "HoshiHub"
        if isfolder and not isfolder(cacheFolder) then pcall(makefolder, cacheFolder) end
        local cacheFile = cacheFolder .. "/Asset_" .. cleanNum .. ".png"

        if isfile(cacheFile) then
            local s, asset = pcall(customAssetFn, cacheFile)
            if s and asset then
                imageLabel.Image = asset
                return
            end
        end

        task.spawn(function()
            local cdnUrl
            if cleanNum == "95445676600352" then
                cdnUrl = "https://tr.rbxcdn.com/180DAY-299908871c7597ad2f85e220058de002/420/420/Decal/Png/noFilter"
            else
                local apiSuccess, response = pcall(function()
                    return game:HttpGet("https://thumbnails.roblox.com/v1/assets?assetIds=" .. cleanNum .. "&size=420x420&format=Png&isCircular=false")
                end)
                if apiSuccess and response then
                    local decodeSuccess, parsed = pcall(function() return HttpService:JSONDecode(response) end)
                    if decodeSuccess and parsed and parsed.data and parsed.data[1] and parsed.data[1].imageUrl then
                        cdnUrl = parsed.data[1].imageUrl
                    end
                end
            end

            if cdnUrl then
                local imgSuccess, imgBytes = pcall(function() return game:HttpGet(cdnUrl) end)
                if imgSuccess and imgBytes and #imgBytes > 0 then
                    pcall(writefile, cacheFile, imgBytes)
                    local s, asset = pcall(customAssetFn, cacheFile)
                    if s and asset and imageLabel and imageLabel.Parent then
                        imageLabel.Image = asset
                    end
                end
            end
        end)
    end
end

-- ==============================================================================
-- 5. CREATOR & THEMETAG REGISTRY ENGINE (Fluent Methodology)
-- ==============================================================================
local Creator = {
    Registry = {},
    Signals = {},
    ActiveTheme = Themes["Hoshi"],
    ActiveThemeName = "Hoshi",
}

function Creator.GetSafeGuiParent()
    local success, hui = pcall(function() return (gethui or get_hidden_ui)() end)
    if success and hui then return hui end
    local cSuccess, coregui = pcall(function() return CoreGui end)
    if cSuccess and coregui then return coregui end
    return LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("StarterGui")
end

function Creator.AddSignal(rbxSignal, fn)
    local conn = rbxSignal:Connect(fn)
    table.insert(Creator.Signals, conn)
    return conn
end

function Creator.Disconnect()
    for _, conn in ipairs(Creator.Signals) do
        if typeof(conn) == "RBXScriptConnection" and conn.Connected then
            conn:Disconnect()
        elseif conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    Creator.Signals = {}
end

function Creator.GetThemeProperty(propKey)
    if Creator.ActiveTheme and Creator.ActiveTheme[propKey] then
        return Creator.ActiveTheme[propKey]
    end
    return Themes["Hoshi"][propKey]
end

function Creator.AddThemeObject(instance, themeTags)
    Creator.Registry[instance] = themeTags
    for prop, themeKey in pairs(themeTags) do
        local val = Creator.GetThemeProperty(themeKey)
        if val ~= nil then
            pcall(function() instance[prop] = val end)
        end
    end
    return instance
end

function Creator.UpdateTheme(newTheme, newThemeName)
    if type(newTheme) == "string" then
        newThemeName = newTheme
        newTheme = Themes[newThemeName] or Themes["Hoshi"]
    end
    Creator.ActiveTheme = newTheme or Themes["Hoshi"]
    Creator.ActiveThemeName = newThemeName or "Hoshi"

    for inst, tags in pairs(Creator.Registry) do
        if inst and inst.Parent then
            for prop, themeKey in pairs(tags) do
                local val = Creator.GetThemeProperty(themeKey)
                if val ~= nil then
                    pcall(function() inst[prop] = val end)
                end
            end
        else
            Creator.Registry[inst] = nil
        end
    end
end

function Creator.New(className, properties, children)
    local instance = Instance.new(className)
    properties = properties or {}
    children = children or {}
    local themeTags = properties.ThemeTag
    properties.ThemeTag = nil

    for prop, val in pairs(properties) do
        pcall(function() instance[prop] = val end)
    end
    for _, child in ipairs(children) do
        if typeof(child) == "Instance" then child.Parent = instance end
    end
    if themeTags and type(themeTags) == "table" then
        Creator.AddThemeObject(instance, themeTags)
    end
    return instance
end

function Creator.AddCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
    return corner
end

function Creator.AddStroke(instance, colorKeyOrColor, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    if type(colorKeyOrColor) == "string" then
        Creator.AddThemeObject(stroke, { Color = colorKeyOrColor })
    elseif typeof(colorKeyOrColor) == "Color3" then
        stroke.Color = colorKeyOrColor
    else
        stroke.Color = Creator.GetThemeProperty("Border")
    end
    stroke.Parent = instance
    return stroke
end

function Creator.AddPadding(instance, top, bottom, left, right)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, top or 0)
    pad.PaddingBottom = UDim.new(0, bottom or top or 0)
    pad.PaddingLeft = UDim.new(0, left or top or 0)
    pad.PaddingRight = UDim.new(0, right or left or top or 0)
    pad.Parent = instance
    return pad
end

function Creator.Tween(instance, properties, duration, style, direction)
    if not instance then return nil end
    local tweenInfo = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local anim = TweenService:Create(instance, tweenInfo, properties)
    anim:Play()
    return anim
end

function Creator.SpringMotor(initialValue, instance, propertyName, frequency)
    local motor = Flipper.SingleMotor.new(initialValue)
    motor:onStep(function(val)
        if instance and instance.Parent then
            pcall(function() instance[propertyName] = val end)
        end
    end)
    local setGoal = function(target)
        motor:setGoal(Flipper.Spring.new(target, { frequency = frequency or 7 }))
    end
    return motor, setGoal
end

function Creator.MakeDraggable(dragBar, mainFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    Creator.AddSignal(dragBar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    Creator.AddSignal(dragBar.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    Creator.AddSignal(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ==============================================================================
-- 6. CONFIG PERSISTENCE ENGINE
-- ==============================================================================
local ConfigManager = {
    Folder = "HoshiHub",
    File = "Config.json",
    AutoSave = true,
    Flags = {},
    Signals = {}
}

function ConfigManager:Init(folderName, fileName, autoSave)
    self.Folder = folderName or "HoshiHub"
    self.File = fileName or "Config.json"
    self.AutoSave = (autoSave ~= false)
    if makefolder and isfolder and not isfolder(self.Folder) then
        pcall(makefolder, self.Folder)
    end
    if self.AutoSave then self:Load() end
end

function ConfigManager:Set(flag, value)
    if not flag then return end
    self.Flags[flag] = value
    if self.Signals[flag] then self.Signals[flag]:Fire(value) end
    if self.AutoSave then self:Save() end
end

function ConfigManager:Get(flag, defaultValue)
    if self.Flags[flag] ~= nil then return self.Flags[flag] end
    return defaultValue
end

function ConfigManager:Save()
    if not writefile then return end
    if makefolder and isfolder and not isfolder(self.Folder) then
        pcall(makefolder, self.Folder)
    end
    local filePath = self.Folder .. "/" .. self.File
    local data = {}
    for k, v in pairs(self.Flags) do
        if typeof(v) == "Color3" then
            data[k] = { __type = "Color3", r = v.R, g = v.G, b = v.B }
        elseif typeof(v) == "EnumItem" then
            data[k] = { __type = "EnumItem", enum = tostring(v.EnumType), name = v.Name }
        else
            data[k] = v
        end
    end
    local success, json = pcall(function() return HttpService:JSONEncode(data) end)
    if success and json then pcall(writefile, filePath, json) end
end

function ConfigManager:Load()
    if not readfile or not isfile then return false end
    local filePath = self.Folder .. "/" .. self.File
    if not isfile(filePath) then return false end
    local success, content = pcall(readfile, filePath)
    if not success or not content or content == "" then return false end
    local parseSuccess, parsed = pcall(function() return HttpService:JSONDecode(content) end)
    if not parseSuccess or type(parsed) ~= "table" then return false end
    for k, v in pairs(parsed) do
        if type(v) == "table" and v.__type == "Color3" then
            self.Flags[k] = Color3.new(v.r, v.g, v.b)
        elseif type(v) == "table" and v.__type == "EnumItem" then
            local enumType = Enum[v.enum]
            if enumType and enumType[v.name] then self.Flags[k] = enumType[v.name] end
        else
            self.Flags[k] = v
        end
        if self.Signals[k] then self.Signals[k]:Fire(self.Flags[k]) end
    end
    return true
end

function ConfigManager:Export()
    local data = {}
    for k, v in pairs(self.Flags) do
        if typeof(v) == "Color3" then
            data[k] = { __type = "Color3", r = v.R, g = v.G, b = v.B }
        elseif typeof(v) == "EnumItem" then
            data[k] = { __type = "EnumItem", enum = tostring(v.EnumType), name = v.Name }
        else
            data[k] = v
        end
    end
    local success, json = pcall(function() return HttpService:JSONEncode(data) end)
    return (success and json) or "{}"
end

-- ==============================================================================
-- 7. NOTIFICATION SYSTEM
-- ==============================================================================
local NotificationManager = {}

function NotificationManager.Init(screenGui)
    local holder = Creator.New("Frame", {
        Name = "NotificationHolder",
        Size = UDim2.new(0, 310, 1, -40),
        Position = UDim2.new(1, -330, 0, 20),
        BackgroundTransparency = 1,
        Parent = screenGui
    })
    Creator.New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 10),
        Parent = holder
    })
    return holder
end

function NotificationManager.Notify(holder, notifConfig, theme)
    notifConfig = notifConfig or {}
    local title = notifConfig.Title or "Notification"
    local content = notifConfig.Content or ""
    local notifType = notifConfig.Type or "Info"
    local duration = notifConfig.Duration or 3.5
    local rawIcon = notifConfig.Icon or "bell"

    local typeColor = theme.Accent
    if notifType == "Success" then typeColor = theme.Success
    elseif notifType == "Warning" then typeColor = theme.Warning
    elseif notifType == "Danger" then typeColor = theme.Danger end

    local notifFrame = Creator.New("Frame", {
        Name = "Toast",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.CardBackground,
        ClipsDescendants = true,
        Parent = holder,
        ThemeTag = { BackgroundColor3 = "CardBackground" }
    })
    Creator.AddCorner(notifFrame, 8)
    Creator.AddStroke(notifFrame, "Border", 1)

    Creator.New("Frame", {
        Name = "SideBar",
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = typeColor,
        Parent = notifFrame
    })

    local isCustomDecal = type(rawIcon) == "number" or tonumber(rawIcon) ~= nil or tostring(rawIcon):find("^rbxthumb://") or tostring(rawIcon):find("%d%d%d%d%d%d")

    local notifIco = Creator.New("ImageLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundTransparency = 1,
        ImageColor3 = isCustomDecal and Color3.fromRGB(255, 255, 255) or typeColor,
        ScaleType = Enum.ScaleType.Fit,
        Parent = notifFrame
    })
    if isCustomDecal then
        Creator.AddCorner(notifIco, 4)
        IconEngine.ApplyDecal(notifIco, rawIcon)
    else
        notifIco.Image = IconEngine.GetIcon(rawIcon)
    end

    Creator.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -40, 0, 18),
        Position = UDim2.new(0, 36, 0, 12),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ThemeTag = { TextColor3 = "Text" },
        Parent = notifFrame
    })

    local descLabel = Creator.New("TextLabel", {
        Name = "Content",
        Size = UDim2.new(1, -46, 0, 0),
        Position = UDim2.new(0, 36, 0, 32),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = theme.SubText,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        ThemeTag = { TextColor3 = "SubText" },
        Parent = notifFrame
    })

    local progressBar = Creator.New("Frame", {
        Name = "Progress",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = typeColor,
        Parent = notifFrame
    })

    task.spawn(function()
        task.wait(0.02)
        local targetH = math.max(60, descLabel.TextBounds.Y + 44)
        Creator.Tween(notifFrame, { Size = UDim2.new(1, 0, 0, targetH) }, 0.22, Enum.EasingStyle.Back)
        Creator.Tween(progressBar, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)
        task.wait(duration)
        local closeAnim = Creator.Tween(notifFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.2, Enum.EasingStyle.Sine)
        if closeAnim then
            closeAnim.Completed:Connect(function() notifFrame:Destroy() end)
        else
            notifFrame:Destroy()
        end
    end)
end

-- ==============================================================================
-- 8. DIALOG MODAL SYSTEM (Fluent Responsive Scale)
-- ==============================================================================
local DialogManager = {}

function DialogManager.Open(screenGui, dialogConfig, theme)
    dialogConfig = dialogConfig or {}
    local title = dialogConfig.Title or "Dialog"
    local content = dialogConfig.Content or ""
    local buttons = dialogConfig.Buttons or { { Text = "OK", Variant = "Primary" } }
    local numButtons = math.max(1, #buttons)

    local modalOverlay = Creator.New("TextButton", {
        Name = "ModalOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 100,
        Parent = screenGui
    })

    local dialogWidth = math.clamp(numButtons * 85 + 40, 360, 520)
    local dialogBox = Creator.New("Frame", {
        Name = "DialogBox",
        Size = UDim2.new(0, dialogWidth, 0, 175),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.CardBackground,
        ZIndex = 101,
        ThemeTag = { BackgroundColor3 = "CardBackground" },
        Parent = modalOverlay
    })
    Creator.AddCorner(dialogBox, 10)
    Creator.AddStroke(dialogBox, "Border", 1)

    local dScale = Creator.New("UIScale", { Scale = 0.85, Parent = dialogBox })

    Creator.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -32, 0, 24),
        Position = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme.Text,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 102,
        ThemeTag = { TextColor3 = "Text" },
        Parent = dialogBox
    })

    Creator.New("TextLabel", {
        Name = "Content",
        Size = UDim2.new(1, -32, 0, 48),
        Position = UDim2.new(0, 16, 0, 44),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = theme.SubText,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 102,
        ThemeTag = { TextColor3 = "SubText" },
        Parent = dialogBox
    })

    local btnContainer = Creator.New("Frame", {
        Name = "Buttons",
        Size = UDim2.new(1, -32, 0, 34),
        Position = UDim2.new(0, 16, 1, -48),
        BackgroundTransparency = 1,
        ZIndex = 102,
        Parent = dialogBox
    })
    Creator.New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = btnContainer
    })

    local function closeDialog()
        Creator.Tween(modalOverlay, { BackgroundTransparency = 1 }, 0.15)
        local anim = Creator.Tween(dScale, { Scale = 0.85 }, 0.15, Enum.EasingStyle.Sine)
        if anim then
            anim.Completed:Connect(function() modalOverlay:Destroy() end)
        else
            modalOverlay:Destroy()
        end
    end

    local btnWidthScale = 1 / numButtons
    local btnOffsetGap = numButtons > 1 and math.floor(((numButtons - 1) * 6) / numButtons) or 0

    for idx, btnData in ipairs(buttons) do
        local bVariant = btnData.Variant or "Secondary"
        local bBgKey = "Background"
        local bTextKey = "Text"
        if bVariant == "Primary" then bBgKey = "Accent" bTextKey = "Background"
        elseif bVariant == "Danger" then bBgKey = "Danger" bTextKey = "Text" end

        local dBtn = Creator.New("TextButton", {
            Name = "Btn_" .. idx .. "_" .. (btnData.Text or "Action"),
            Size = UDim2.new(btnWidthScale, -btnOffsetGap, 1, 0),
            BackgroundColor3 = Creator.GetThemeProperty(bBgKey),
            AutoButtonColor = false,
            Text = btnData.Text or "Action",
            TextColor3 = Creator.GetThemeProperty(bTextKey),
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = idx,
            ZIndex = 103,
            ThemeTag = { BackgroundColor3 = bBgKey, TextColor3 = bTextKey },
            Parent = btnContainer
        })
        Creator.AddCorner(dBtn, 6)
        dBtn.MouseButton1Click:Connect(function()
            closeDialog()
            if btnData.Callback then pcall(btnData.Callback) end
        end)
    end

    Creator.Tween(modalOverlay, { BackgroundTransparency = 0.5 }, 0.2)
    Creator.Tween(dScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back)
end

-- ==============================================================================
-- 9. MAIN WINDOW COMPONENT FACTORY (Fluent Standard Architecture)
-- ==============================================================================
local HoshiUI = {
    Version = "2.2.0",
    Windows = {},
    Icons = IconEngine,
    Themes = Themes,
}

function HoshiUI:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "Hoshi Hub"
    local windowSubTitle = config.SubTitle or "v2.0"
    local themeName = config.Theme or "Hoshi"
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightControl
    local hasFloating = (config.FloatingButton ~= false)
    local configFolder = config.Folder or "HoshiHub"
    local configFile = config.ConfigFile or "Config.json"
    local autoSave = (config.AutoSave ~= false)
    local isResizable = (config.Resizable ~= false)
    local initialScale = config.Scale or 1.0

    if getgenv then
        local active = getgenv().HoshiHub_ActiveWindow
        if active and active.Destroy then pcall(active.Destroy, active) end
    end

    local safeParent = Creator.GetSafeGuiParent()
    local existingGui = safeParent:FindFirstChild("HoshiUI_Root")
    if existingGui then pcall(existingGui.Destroy, existingGui) end

    local theme = Themes[themeName] or Themes["Hoshi"] or Themes["Dark"]
    Creator.ActiveTheme = theme
    Creator.ActiveThemeName = themeName

    local viewport = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
    local defaultW = math.min(config.Size and config.Size.X.Offset or 680, viewport.X - 24)
    local defaultH = math.min(config.Size and config.Size.Y.Offset or 440, viewport.Y - 30)
    local windowSize = UDim2.new(0, defaultW, 0, defaultH)

    ConfigManager:Init(configFolder, configFile, autoSave)

    local screenGui = Creator.New("ScreenGui", {
        Name = "HoshiUI_Root",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = safeParent
    })

    local notifHolder = NotificationManager.Init(screenGui)

    local mainFrame = Creator.New("Frame", {
        Name = "MainFrame",
        Size = windowSize,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Background,
        ClipsDescendants = false,
        ThemeTag = { BackgroundColor3 = "Background" },
        Parent = screenGui
    })
    Creator.AddCorner(mainFrame, 12)
    local mainStroke = Creator.AddStroke(mainFrame, "Border", 1)

    local uiScale = Creator.New("UIScale", { Scale = initialScale, Parent = mainFrame })

    Creator.New("ImageLabel", {
        Name = "Shadow",
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0, -20, 0, -20),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ScaleType = Enum.ScaleType.Slice,
        ZIndex = 0,
        Parent = mainFrame
    })

    local topBar = Creator.New("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = mainFrame
    })

    local rawHeaderIcon = config.Icon or "95445676600352"
    local isHeaderCustomAsset = type(rawHeaderIcon) == "number" or tonumber(rawHeaderIcon) ~= nil or tostring(rawHeaderIcon):find("^rbxthumb://") or tostring(rawHeaderIcon):find("^rbxassetid://") or tostring(rawHeaderIcon):find("%d%d%d%d%d%d")

    local headImg = Creator.New("ImageLabel", {
        Name = "HeaderIcon",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 14, 0.5, -12),
        BackgroundTransparency = 1,
        ImageColor3 = isHeaderCustomAsset and Color3.fromRGB(255, 255, 255) or theme.Accent,
        ScaleType = Enum.ScaleType.Fit,
        ThemeTag = isHeaderCustomAsset and nil or { ImageColor3 = "Accent" },
        Parent = topBar
    })
    if isHeaderCustomAsset then
        Creator.AddCorner(headImg, 6)
        IconEngine.ApplyDecal(headImg, rawHeaderIcon)
    else
        headImg.Image = IconEngine.GetIcon(rawHeaderIcon)
    end

    local titleContainer = Creator.New("Frame", {
        Name = "TitleContainer",
        Size = UDim2.new(0, 320, 1, 0),
        Position = UDim2.new(0, 44, 0, 0),
        BackgroundTransparency = 1,
        Parent = topBar
    })

    Creator.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0, 6),
        BackgroundTransparency = 1,
        Text = windowTitle,
        TextColor3 = theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ThemeTag = { TextColor3 = "Text" },
        Parent = titleContainer
    })

    Creator.New("TextLabel", {
        Name = "SubTitle",
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundTransparency = 1,
        Text = windowSubTitle,
        TextColor3 = theme.SubText,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ThemeTag = { TextColor3 = "SubText" },
        Parent = titleContainer
    })

    local actionsContainer = Creator.New("Frame", {
        Name = "Actions",
        Size = UDim2.new(0, 75, 1, 0),
        Position = UDim2.new(1, -12, 0, 0),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Parent = topBar
    })
    Creator.New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = actionsContainer
    })

    local function createTopBarButton(name, iconId, layoutOrder, onClick)
        local btn = Creator.New("ImageButton", {
            Name = name,
            Size = UDim2.new(0, 28, 0, 28),
            BackgroundColor3 = theme.CardBackground,
            AutoButtonColor = false,
            LayoutOrder = layoutOrder or 1,
            ThemeTag = { BackgroundColor3 = "CardBackground" },
            Parent = actionsContainer
        })
        Creator.AddCorner(btn, 6)
        Creator.AddStroke(btn, "Border", 1)

        local ico = Creator.New("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0.5, -7, 0.5, -7),
            BackgroundTransparency = 1,
            Image = IconEngine.GetIcon(iconId) or iconId,
            ImageColor3 = theme.SubText,
            ThemeTag = { ImageColor3 = "SubText" },
            Parent = btn
        })

        btn.MouseEnter:Connect(function()
            Creator.Tween(btn, { BackgroundColor3 = Creator.GetThemeProperty("CardHover") }, 0.15)
            Creator.Tween(ico, { ImageColor3 = Creator.GetThemeProperty("Text") }, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            Creator.Tween(btn, { BackgroundColor3 = Creator.GetThemeProperty("CardBackground") }, 0.15)
            Creator.Tween(ico, { ImageColor3 = Creator.GetThemeProperty("SubText") }, 0.15)
        end)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    local isMinimized = false
    local originalSize = windowSize
    local isVisible = true

    local function toggleWindow(forcedState)
        if forcedState ~= nil then isVisible = forcedState else isVisible = not isVisible end
        if isVisible then
            mainFrame.Visible = true
            uiScale.Scale = 0.88 * initialScale
            Creator.Tween(uiScale, { Scale = initialScale }, 0.2, Enum.EasingStyle.Back)
        else
            local anim = Creator.Tween(uiScale, { Scale = 0.88 * initialScale }, 0.15, Enum.EasingStyle.Sine)
            if anim then
                anim.Completed:Connect(function() if not isVisible then mainFrame.Visible = false end end)
            else
                mainFrame.Visible = false
            end
        end
    end

    createTopBarButton("Minimize", "chevron-up", 1, function()
        isMinimized = not isMinimized
        if isMinimized then
            Creator.Tween(mainFrame, { Size = UDim2.new(0, mainFrame.AbsoluteSize.X, 0, 48) }, 0.22)
        else
            Creator.Tween(mainFrame, { Size = originalSize }, 0.22)
        end
    end)

    createTopBarButton("Close", "x", 2, function()
        toggleWindow(false)
    end)

    Creator.MakeDraggable(topBar, mainFrame)

    local body = Creator.New("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -48),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = mainFrame
    })

    local sidebar = Creator.New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 175, 1, 0),
        BackgroundColor3 = theme.Sidebar,
        ThemeTag = { BackgroundColor3 = "Sidebar" },
        Parent = body
    })
    Creator.AddCorner(sidebar, 8)
    Creator.AddStroke(sidebar, "Border", 1)

    -- Fluent Sliding Tab Indicator Pill
    local tabIndicator = Creator.New("Frame", {
        Name = "TabIndicator",
        Size = UDim2.new(0, 3, 0, 18),
        Position = UDim2.new(0, 4, 0, 8),
        BackgroundColor3 = theme.Accent,
        ThemeTag = { BackgroundColor3 = "Accent" },
        Parent = sidebar
    })
    Creator.AddCorner(tabIndicator, 2)

    local selectorPosMotor = Flipper.SingleMotor.new(8)
    local selectorSizeMotor = Flipper.SingleMotor.new(18)

    selectorPosMotor:onStep(function(val)
        tabIndicator.Position = UDim2.new(0, 4, 0, val)
    end)
    selectorSizeMotor:onStep(function(val)
        tabIndicator.Size = UDim2.new(0, 3, 0, val)
    end)

    local tabListScroll = Creator.New("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ThemeTag = { ScrollBarImageColor3 = "Border" },
        Parent = sidebar
    })
    Creator.AddPadding(tabListScroll, 8, 8, 8, 8)
    local tabLayout = Creator.New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = tabListScroll
    })

    local contentArea = Creator.New("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -183, 1, 0),
        Position = UDim2.new(0, 183, 0, 0),
        BackgroundTransparency = 1,
        Parent = body
    })

    -- Interactive Corner Resize Handle (Flipper Spring GroupMotor)
    if isResizable then
        local resizeHandle = Creator.New("ImageButton", {
            Name = "ResizeHandle",
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(1, -18, 1, -18),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            ZIndex = 40,
            Parent = mainFrame
        })

        Creator.New("ImageLabel", {
            Name = "Grip",
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(1, -12, 1, -12),
            BackgroundTransparency = 1,
            Image = "rbxassetid://10709791624",
            ImageColor3 = theme.SubText,
            ImageTransparency = 0.4,
            Rotation = 45,
            ThemeTag = { ImageColor3 = "SubText" },
            Parent = resizeHandle
        })

        local isResizing = false
        local resizeStartMouse, initialFrameSize

        Creator.AddSignal(resizeHandle.InputBegan, function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not isMinimized then
                isResizing = true
                resizeStartMouse = input.Position
                initialFrameSize = mainFrame.AbsoluteSize
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then isResizing = false end
                end)
            end
        end)

        Creator.AddSignal(UserInputService.InputChanged, function(input)
            if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - resizeStartMouse
                local vp = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
                local minW, minH = 460, 320
                local maxW = math.max(minW, vp.X - 24)
                local maxH = math.max(minH, vp.Y - 24)

                local newW = math.clamp(initialFrameSize.X + delta.X, minW, maxW)
                local newH = math.clamp(initialFrameSize.Y + delta.Y, minH, maxH)

                mainFrame.Size = UDim2.new(0, newW, 0, newH)
                originalSize = mainFrame.Size
            end
        end)

        Creator.AddSignal(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isResizing = false
            end
        end)
    end

    -- Floating Action Toggle Button
    local floatingBtn = nil
    if hasFloating then
        local rawFloatIcon = config.FloatingIcon or config.Icon or "95445676600352"
        local isFloatCustomAsset = type(rawFloatIcon) == "number" or tonumber(rawFloatIcon) ~= nil or tostring(rawFloatIcon):find("^rbxthumb://") or tostring(rawFloatIcon):find("^rbxassetid://") or tostring(rawFloatIcon):find("%d%d%d%d%d%d")

        floatingBtn = Creator.New("ImageButton", {
            Name = "FloatingToggle",
            Size = UDim2.new(0, 48, 0, 48),
            Position = UDim2.new(0, 24, 0.5, -24),
            BackgroundColor3 = theme.Background,
            AutoButtonColor = false,
            ZIndex = 50,
            ThemeTag = { BackgroundColor3 = "Background" },
            Parent = screenGui
        })
        Creator.AddCorner(floatingBtn, 12)
        local floatStroke = Creator.AddStroke(floatingBtn, "Accent", 1.5)
        local floatScale = Creator.New("UIScale", { Scale = 1.0, Parent = floatingBtn })

        Creator.New("ImageLabel", {
            Name = "Shadow",
            Size = UDim2.new(1, 16, 1, 16),
            Position = UDim2.new(0, -8, 0, -8),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6015897843",
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = 0.5,
            SliceCenter = Rect.new(49, 49, 450, 450),
            ScaleType = Enum.ScaleType.Slice,
            ZIndex = 49,
            Parent = floatingBtn
        })

        local floatImg = Creator.New("ImageLabel", {
            Name = "Icon",
            Size = isFloatCustomAsset and UDim2.new(1, -4, 1, -4) or UDim2.new(0, 22, 0, 22),
            Position = isFloatCustomAsset and UDim2.new(0, 2, 0, 2) or UDim2.new(0.5, -11, 0.5, -11),
            BackgroundTransparency = 1,
            ImageColor3 = isFloatCustomAsset and Color3.fromRGB(255, 255, 255) or theme.Accent,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 51,
            ThemeTag = isFloatCustomAsset and nil or { ImageColor3 = "Accent" },
            Parent = floatingBtn
        })
        if isFloatCustomAsset then
            Creator.AddCorner(floatImg, 10)
            IconEngine.ApplyDecal(floatImg, rawFloatIcon)
        else
            floatImg.Image = IconEngine.GetIcon(rawFloatIcon)
        end

        floatingBtn.MouseEnter:Connect(function()
            Creator.Tween(floatScale, { Scale = 1.08 }, 0.15, Enum.EasingStyle.Quad)
            Creator.Tween(floatStroke, { Color = Creator.GetThemeProperty("AccentHover"), Thickness = 2 }, 0.15)
        end)
        floatingBtn.MouseLeave:Connect(function()
            Creator.Tween(floatScale, { Scale = 1.0 }, 0.15, Enum.EasingStyle.Quad)
            Creator.Tween(floatStroke, { Color = Creator.GetThemeProperty("Accent"), Thickness = 1.5 }, 0.15)
        end)

        -- Smooth Dragging System with Click Differentiation
        local isDragging = false
        local dragStartPos = Vector2.new(0, 0)
        local btnStartPos = floatingBtn.Position
        local dragInput = nil
        local hasMoved = false

        Creator.AddSignal(floatingBtn.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                hasMoved = false
                dragStartPos = input.Position
                btnStartPos = floatingBtn.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        isDragging = false
                        if not hasMoved then
                            toggleWindow()
                        end
                    end
                end)
            end
        end)

        Creator.AddSignal(floatingBtn.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        Creator.AddSignal(UserInputService.InputChanged, function(input)
            if input == dragInput and isDragging then
                local delta = input.Position - dragStartPos
                if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
                    hasMoved = true
                end
                local vp = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
                local newX = math.clamp(btnStartPos.X.Offset + delta.X, 0, vp.X - 52)
                local newY = math.clamp(btnStartPos.Y.Offset + delta.Y, 0, vp.Y - 52)
                floatingBtn.Position = UDim2.new(btnStartPos.X.Scale, newX, btnStartPos.Y.Scale, newY)
            end
        end)
    end

    Creator.AddSignal(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then toggleWindow() end
    end)

    local Window = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        Scale = uiScale,
        Tabs = {},
        ActiveTab = nil,
        ConfigManager = ConfigManager,
        Themes = Themes,
        ActiveTheme = theme,
        ActiveThemeName = themeName,
    }

    function Window:SetScale(scaleValue)
        initialScale = math.clamp(scaleValue or 1.0, 0.5, 2.0)
        Creator.Tween(uiScale, { Scale = initialScale }, 0.18)
    end

    function Window:GetScale() return uiScale.Scale end

    function Window:SetTheme(targetTheme)
        Creator.UpdateTheme(targetTheme)
    end

    function Window:SetFloatingVisible(visible)
        if floatingBtn then floatingBtn.Visible = (visible ~= false) end
    end

    function Window:Notify(notifConfig)
        NotificationManager.Notify(notifHolder, notifConfig, Creator.ActiveTheme)
    end

    function Window:Dialog(dialogConfig)
        DialogManager.Open(screenGui, dialogConfig, Creator.ActiveTheme)
    end

    function Window:Destroy()
        Creator.Disconnect()
        screenGui:Destroy()
    end

    if getgenv then getgenv().HoshiHub_ActiveWindow = Window end

    -- ==============================================================================
    -- TAB FACTORY (Fluent Sliding Indicator & Animated Page Container)
    -- ==============================================================================
    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabTitle = tabConfig.Title or "Tab"
        local tabIconQuery = tabConfig.Icon or "folder"

        local tabBtn = Creator.New("TextButton", {
            Name = "TabBtn_" .. tabTitle,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = theme.Sidebar,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            Parent = tabListScroll
        })
        Creator.AddCorner(tabBtn, 8)

        local tabIconLabel = Creator.New("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 12, 0.5, -8),
            BackgroundTransparency = 1,
            Image = IconEngine.GetIcon(tabIconQuery),
            ImageColor3 = theme.SubText,
            ThemeTag = { ImageColor3 = "SubText" },
            Parent = tabBtn
        })

        local tabTextLabel = Creator.New("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -38, 1, 0),
            Position = UDim2.new(0, 36, 0, 0),
            BackgroundTransparency = 1,
            Text = tabTitle,
            TextColor3 = theme.SubText,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "SubText" },
            Parent = tabBtn
        })

        local pageScroll = Creator.New("ScrollingFrame", {
            Name = "Page_" .. tabTitle,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ThemeTag = { ScrollBarImageColor3 = "Border" },
            Parent = contentArea
        })
        Creator.AddPadding(pageScroll, 12, 16, 10, 14)
        Creator.New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = pageScroll
        })

        local Tab = {
            Title = tabTitle,
            Button = tabBtn,
            Page = pageScroll,
            Window = Window,
        }

        local function selectThisTab()
            for _, otherTab in ipairs(Window.Tabs) do
                otherTab.Page.Visible = false
                Creator.Tween(otherTab.Button, { BackgroundTransparency = 1 }, 0.15)
                Creator.Tween(otherTab.Button.Icon, { ImageColor3 = Creator.GetThemeProperty("SubText") }, 0.15)
                Creator.Tween(otherTab.Button.Title, { TextColor3 = Creator.GetThemeProperty("SubText") }, 0.15)
            end

            Window.ActiveTab = Tab
            pageScroll.Visible = true

            -- Fluent Spring Sliding Tab Indicator
            local targetY = tabBtn.Position.Y.Offset + tabBtn.AbsolutePosition.Y - tabListScroll.AbsolutePosition.Y + 8
            selectorPosMotor:setGoal(Flipper.Spring.new(targetY, { frequency = 8 }))
            selectorSizeMotor:setGoal(Flipper.Spring.new(18, { frequency = 8 }))

            Creator.Tween(tabBtn, { BackgroundTransparency = 0.85 }, 0.15)
            Creator.Tween(tabIconLabel, { ImageColor3 = Creator.GetThemeProperty("Accent") }, 0.15)
            Creator.Tween(tabTextLabel, { TextColor3 = Creator.GetThemeProperty("Text") }, 0.15)
        end

        tabBtn.MouseButton1Click:Connect(selectThisTab)
        table.insert(Window.Tabs, Tab)

        if #Window.Tabs == 1 then
            task.spawn(selectThisTab)
        end

        -- ==============================================================================
        -- UNIFIED ELEMENT FACTORIES (Buttons, Toggles, Sliders, Dropdowns, etc.)
        -- ==============================================================================

        function Tab:CreateSection(title, desc)
            local sectionHolder = Creator.New("Frame", {
                Name = "Section_" .. title,
                Size = UDim2.new(1, 0, 0, desc and 34 or 24),
                BackgroundTransparency = 1,
                Parent = pageScroll
            })
            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                Text = title:upper(),
                TextColor3 = Creator.GetThemeProperty("Accent"),
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ThemeTag = { TextColor3 = "Accent" },
                Parent = sectionHolder
            })
            if desc then
                Creator.New("TextLabel", {
                    Name = "Desc",
                    Size = UDim2.new(1, 0, 0, 14),
                    Position = UDim2.new(0, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Text = desc,
                    TextColor3 = Creator.GetThemeProperty("SubText"),
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ThemeTag = { TextColor3 = "SubText" },
                    Parent = sectionHolder
                })
            end
            return sectionHolder
        end

        function Tab:CreateDivider()
            local divider = Creator.New("Frame", {
                Name = "Divider",
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Creator.GetThemeProperty("Border"),
                ThemeTag = { BackgroundColor3 = "Border" },
                Parent = pageScroll
            })
            return divider
        end

        function Tab:CreateParagraph(paraConfig)
            paraConfig = paraConfig or {}
            local pTitle = paraConfig.Title or "Paragraph"
            local pContent = paraConfig.Content or ""
            local pIcon = paraConfig.Icon and IconEngine.GetIcon(paraConfig.Icon)

            local card = Creator.New("Frame", {
                Name = "Paragraph_" .. pTitle,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Creator.GetThemeProperty("CardBackground"),
                ThemeTag = { BackgroundColor3 = "CardBackground" },
                Parent = pageScroll
            })
            Creator.AddCorner(card, 8)
            Creator.AddStroke(card, "Border", 1)
            Creator.AddPadding(card, 10, 10, 12, 12)

            local headerOffset = 0
            if pIcon then
                headerOffset = 22
                Creator.New("ImageLabel", {
                    Name = "Icon",
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Image = pIcon,
                    ImageColor3 = Creator.GetThemeProperty("Accent"),
                    ThemeTag = { ImageColor3 = "Accent" },
                    Parent = card
                })
            end

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -headerOffset, 0, 16),
                Position = UDim2.new(0, headerOffset, 0, 0),
                BackgroundTransparency = 1,
                Text = pTitle,
                TextColor3 = Creator.GetThemeProperty("Text"),
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ThemeTag = { TextColor3 = "Text" },
                Parent = card
            })

            Creator.New("TextLabel", {
                Name = "Content",
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = pContent,
                TextColor3 = Creator.GetThemeProperty("SubText"),
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                AutomaticSize = Enum.AutomaticSize.Y,
                ThemeTag = { TextColor3 = "SubText" },
                Parent = card
            })
            return card
        end

        function Tab:CreateButton(btnConfig)
            btnConfig = btnConfig or {}
            local title = btnConfig.Title or "Button"
            local desc = btnConfig.Desc
            local icon = btnConfig.Icon and IconEngine.GetIcon(btnConfig.Icon)
            local callback = btnConfig.Callback or function() end

            local card = Creator.New("TextButton", {
                Name = "Button_" .. title,
                Size = UDim2.new(1, 0, 0, desc and 48 or 38),
                BackgroundColor3 = Creator.GetThemeProperty("CardBackground"),
                AutoButtonColor = false,
                Text = "",
                ThemeTag = { BackgroundColor3 = "CardBackground" },
                Parent = pageScroll
            })
            Creator.AddCorner(card, 8)
            local stroke = Creator.AddStroke(card, "Border", 1)

            local offsetLeft = 12
            if icon then
                Creator.New("ImageLabel", {
                    Name = "Icon",
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(0, 12, 0.5, -9),
                    BackgroundTransparency = 1,
                    Image = icon,
                    ImageColor3 = Creator.GetThemeProperty("Accent"),
                    ThemeTag = { ImageColor3 = "Accent" },
                    Parent = card
                })
                offsetLeft = 36
            end

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -offsetLeft - 30, 0, 16),
                Position = UDim2.new(0, offsetLeft, 0, desc and 8 or 11),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = Creator.GetThemeProperty("Text"),
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ThemeTag = { TextColor3 = "Text" },
                Parent = card
            })

            if desc then
                Creator.New("TextLabel", {
                    Name = "Desc",
                    Size = UDim2.new(1, -offsetLeft - 30, 0, 14),
                    Position = UDim2.new(0, offsetLeft, 0, 26),
                    BackgroundTransparency = 1,
                    Text = desc,
                    TextColor3 = Creator.GetThemeProperty("SubText"),
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ThemeTag = { TextColor3 = "SubText" },
                    Parent = card
                })
            end

            Creator.New("ImageLabel", {
                Name = "Arrow",
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(1, -22, 0.5, -7),
                BackgroundTransparency = 1,
                Image = IconEngine.GetIcon("chevron-right"),
                ImageColor3 = Creator.GetThemeProperty("SubText"),
                ThemeTag = { ImageColor3 = "SubText" },
                Parent = card
            })

            card.MouseEnter:Connect(function()
                Creator.Tween(card, { BackgroundColor3 = Creator.GetThemeProperty("CardHover") }, 0.15)
                Creator.Tween(stroke, { Color = Creator.GetThemeProperty("Accent") }, 0.15)
            end)
            card.MouseLeave:Connect(function()
                Creator.Tween(card, { BackgroundColor3 = Creator.GetThemeProperty("CardBackground") }, 0.15)
                Creator.Tween(stroke, { Color = Creator.GetThemeProperty("Border") }, 0.15)
            end)
            card.MouseButton1Click:Connect(function()
                pcall(callback)
            end)
            return card
        end

        function Tab:CreateToggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            local title = toggleConfig.Title or "Toggle"
            local desc = toggleConfig.Desc
            local flag = toggleConfig.Flag
            local callback = toggleConfig.Callback or function() end
            local default = toggleConfig.Default or false

            if flag then
                local saved = ConfigManager:Get(flag)
                if saved ~= nil then default = saved else ConfigManager:Set(flag, default) end
            end

            local state = default

            local card = Creator.New("TextButton", {
                Name = "Toggle_" .. title,
                Size = UDim2.new(1, 0, 0, desc and 48 or 38),
                BackgroundColor3 = Creator.GetThemeProperty("CardBackground"),
                AutoButtonColor = false,
                Text = "",
                ThemeTag = { BackgroundColor3 = "CardBackground" },
                Parent = pageScroll
            })
            Creator.AddCorner(card, 8)
            local stroke = Creator.AddStroke(card, "Border", 1)

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -70, 0, 16),
                Position = UDim2.new(0, 12, 0, desc and 8 or 11),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = Creator.GetThemeProperty("Text"),
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ThemeTag = { TextColor3 = "Text" },
                Parent = card
            })

            if desc then
                Creator.New("TextLabel", {
                    Name = "Desc",
                    Size = UDim2.new(1, -70, 0, 14),
                    Position = UDim2.new(0, 12, 0, 26),
                    BackgroundTransparency = 1,
                    Text = desc,
                    TextColor3 = Creator.GetThemeProperty("SubText"),
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ThemeTag = { TextColor3 = "SubText" },
                    Parent = card
                })
            end

            -- Switch Track Pill
            local track = Creator.New("Frame", {
                Name = "Track",
                Size = UDim2.new(0, 40, 0, 22),
                Position = UDim2.new(1, -52, 0.5, -11),
                BackgroundColor3 = state and Creator.GetThemeProperty("Accent") or Creator.GetThemeProperty("ToggleOff"),
                Parent = card
            })
            Creator.AddCorner(track, 11)

            local thumb = Creator.New("Frame", {
                Name = "Thumb",
                Size = UDim2.new(0, 16, 0, 16),
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = state and Creator.GetThemeProperty("Background") or Color3.fromRGB(220, 220, 220),
                Parent = track
            })
            Creator.AddCorner(thumb, 8)

            local thumbMotor = Flipper.SingleMotor.new(state and 1 or 0)
            thumbMotor:onStep(function(val)
                local offset = 3 + val * (40 - 16 - 6)
                thumb.Position = UDim2.new(0, offset, 0.5, -8)
            end)

            local function setToggle(newState, skipCallback)
                state = newState
                if flag then ConfigManager:Set(flag, state) end

                thumbMotor:setGoal(Flipper.Spring.new(state and 1 or 0, { frequency = 8 }))
                Creator.Tween(track, {
                    BackgroundColor3 = state and Creator.GetThemeProperty("Accent") or Creator.GetThemeProperty("ToggleOff")
                }, 0.18)
                Creator.Tween(thumb, {
                    BackgroundColor3 = state and Creator.GetThemeProperty("Background") or Color3.fromRGB(220, 220, 220)
                }, 0.18)

                if not skipCallback then pcall(callback, state) end
            end

            card.MouseButton1Click:Connect(function()
                setToggle(not state)
            end)

            card.MouseEnter:Connect(function()
                Creator.Tween(card, { BackgroundColor3 = Creator.GetThemeProperty("CardHover") }, 0.15)
            end)
            card.MouseLeave:Connect(function()
                Creator.Tween(card, { BackgroundColor3 = Creator.GetThemeProperty("CardBackground") }, 0.15)
            end)

            return {
                Set = setToggle,
                GetValue = function() return state end
            }
        end

        function Tab:CreateSlider(sliderConfig)
            sliderConfig = sliderConfig or {}
            local title = sliderConfig.Title or "Slider"
            local desc = sliderConfig.Desc
            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local step = sliderConfig.Step or 1
            local default = sliderConfig.Default or min
            local formatStr = sliderConfig.Format or "{value}"
            local flag = sliderConfig.Flag
            local callback = sliderConfig.Callback or function() end

            if flag then
                local saved = ConfigManager:Get(flag)
                if saved ~= nil then default = saved else ConfigManager:Set(flag, default) end
            end

            local currentValue = math.clamp(default, min, max)

            local card = Creator.New("Frame", {
                Name = "Slider_" .. title,
                Size = UDim2.new(1, 0, 0, desc and 62 or 52),
                BackgroundColor3 = Creator.GetThemeProperty("CardBackground"),
                ThemeTag = { BackgroundColor3 = "CardBackground" },
                Parent = pageScroll
            })
            Creator.AddCorner(card, 8)
            Creator.AddStroke(card, "Border", 1)

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -80, 0, 16),
                Position = UDim2.new(0, 12, 0, 8),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = Creator.GetThemeProperty("Text"),
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ThemeTag = { TextColor3 = "Text" },
                Parent = card
            })

            local valLabel = Creator.New("TextLabel", {
                Name = "ValueDisplay",
                Size = UDim2.new(0, 60, 0, 16),
                Position = UDim2.new(1, -72, 0, 8),
                BackgroundTransparency = 1,
                Text = formatStr:gsub("{value}", tostring(currentValue)),
                TextColor3 = Creator.GetThemeProperty("Accent"),
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                ThemeTag = { TextColor3 = "Accent" },
                Parent = card
            })

            if desc then
                Creator.New("TextLabel", {
                    Name = "Desc",
                    Size = UDim2.new(1, -80, 0, 12),
                    Position = UDim2.new(0, 12, 0, 24),
                    BackgroundTransparency = 1,
                    Text = desc,
                    TextColor3 = Creator.GetThemeProperty("SubText"),
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ThemeTag = { TextColor3 = "SubText" },
                    Parent = card
                })
            end

            local trackHolder = Creator.New("TextButton", {
                Name = "TrackHolder",
                Size = UDim2.new(1, -24, 0, 8),
                Position = UDim2.new(0, 12, 1, -16),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = card
            })

            local trackBg = Creator.New("Frame", {
                Name = "TrackBg",
                Size = UDim2.new(1, 0, 0, 4),
                Position = UDim2.new(0, 0, 0.5, -2),
                BackgroundColor3 = Creator.GetThemeProperty("ToggleOff"),
                ThemeTag = { BackgroundColor3 = "ToggleOff" },
                Parent = trackHolder
            })
            Creator.AddCorner(trackBg, 2)

            local fillPercent = (currentValue - min) / (max - min)
            local trackFill = Creator.New("Frame", {
                Name = "TrackFill",
                Size = UDim2.new(fillPercent, 0, 1, 0),
                BackgroundColor3 = Creator.GetThemeProperty("Accent"),
                ThemeTag = { BackgroundColor3 = "Accent" },
                Parent = trackBg
            })
            Creator.AddCorner(trackFill, 2)

            local thumb = Creator.New("Frame", {
                Name = "Thumb",
                Size = UDim2.new(0, 12, 0, 12),
                Position = UDim2.new(1, -6, 0.5, -6),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = trackFill
            })
            Creator.AddCorner(thumb, 6)

            local isDragging = false

            local function updateSlider(value, skipCallback)
                currentValue = math.clamp(value, min, max)
                if step > 0 then
                    currentValue = math.floor((currentValue - min) / step + 0.5) * step + min
                end
                currentValue = math.clamp(currentValue, min, max)

                if flag then ConfigManager:Set(flag, currentValue) end
                valLabel.Text = formatStr:gsub("{value}", tostring(currentValue))

                local pct = (currentValue - min) / (max - min)
                Creator.Tween(trackFill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.08)

                if not skipCallback then pcall(callback, currentValue) end
            end

            local function handleInput(input)
                local trackWidth = trackHolder.AbsoluteSize.X
                local clickOffset = input.Position.X - trackHolder.AbsolutePosition.X
                local pct = math.clamp(clickOffset / trackWidth, 0, 1)
                updateSlider(min + pct * (max - min))
            end

            trackHolder.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = true
                    handleInput(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    handleInput(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                end
            end)

            return {
                Set = updateSlider,
                GetValue = function() return currentValue end
            }
        end

        function Tab:CreateDropdown(dropdownConfig)
            dropdownConfig = dropdownConfig or {}
            local title = dropdownConfig.Title or "Dropdown"
            local desc = dropdownConfig.Desc
            local options = dropdownConfig.Options or {}
            local isMulti = dropdownConfig.Multi or false
            local default = dropdownConfig.Default or (isMulti and {} or options[1] or "")
            local flag = dropdownConfig.Flag
            local callback = dropdownConfig.Callback or function() end

            if flag then
                local saved = ConfigManager:Get(flag)
                if saved ~= nil then default = saved else ConfigManager:Set(flag, default) end
            end

            local selected = default
            local isOpen = false

            local card = Creator.New("Frame", {
                Name = "Dropdown_" .. title,
                Size = UDim2.new(1, 0, 0, desc and 48 or 38),
                BackgroundColor3 = Creator.GetThemeProperty("CardBackground"),
                ClipsDescendants = true,
                ThemeTag = { BackgroundColor3 = "CardBackground" },
                Parent = pageScroll
            })
            Creator.AddCorner(card, 8)
            local stroke = Creator.AddStroke(card, "Border", 1)

            local headerBtn = Creator.New("TextButton", {
                Name = "Header",
                Size = UDim2.new(1, 0, 0, desc and 48 or 38),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                Parent = card
            })

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(0.5, 0, 0, 16),
                Position = UDim2.new(0, 12, 0, desc and 8 or 11),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = Creator.GetThemeProperty("Text"),
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ThemeTag = { TextColor3 = "Text" },
                Parent = headerBtn
            })

            if desc then
                Creator.New("TextLabel", {
                    Name = "Desc",
                    Size = UDim2.new(0.5, 0, 0, 14),
                    Position = UDim2.new(0, 12, 0, 26),
                    BackgroundTransparency = 1,
                    Text = desc,
                    TextColor3 = Creator.GetThemeProperty("SubText"),
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ThemeTag = { TextColor3 = "SubText" },
                    Parent = headerBtn
                })
            end

            local function getDisplayString()
                if isMulti then
                    if type(selected) == "table" and #selected > 0 then
                        return table.concat(selected, ", ")
                    end
                    return "None"
                end
                return tostring(selected or "Select...")
            end

            local valLabel = Creator.New("TextLabel", {
                Name = "ValueDisplay",
                Size = UDim2.new(0.5, -42, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = getDisplayString(),
                TextColor3 = Creator.GetThemeProperty("Accent"),
                TextSize = 12,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ThemeTag = { TextColor3 = "Accent" },
                Parent = headerBtn
            })

            local arrowIcon = Creator.New("ImageLabel", {
                Name = "Arrow",
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(1, -24, 0.5, -7),
                BackgroundTransparency = 1,
                Image = IconEngine.GetIcon("chevron-down"),
                ImageColor3 = Creator.GetThemeProperty("SubText"),
                ThemeTag = { ImageColor3 = "SubText" },
                Parent = headerBtn
            })

            local optionList = Creator.New("Frame", {
                Name = "OptionList",
                Size = UDim2.new(1, -24, 0, 0),
                Position = UDim2.new(0, 12, 0, desc and 48 or 38),
                BackgroundTransparency = 1,
                Parent = card
            })
            local optionLayout = Creator.New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = optionList
            })

            local optionButtons = {}

            local function rebuildOptions()
                for _, btn in pairs(optionButtons) do btn:Destroy() end
                optionButtons = {}

                for idx, opt in ipairs(options) do
                    local optStr = tostring(opt)
                    local isSelected = isMulti and table.find(selected, optStr) ~= nil or selected == optStr

                    local optBtn = Creator.New("TextButton", {
                        Name = "Opt_" .. optStr,
                        Size = UDim2.new(1, 0, 0, 28),
                        BackgroundColor3 = isSelected and Creator.GetThemeProperty("Accent") or Creator.GetThemeProperty("ToggleOff"),
                        BackgroundTransparency = isSelected and 0.85 or 0.5,
                        AutoButtonColor = false,
                        Text = "  " .. optStr,
                        TextColor3 = isSelected and Creator.GetThemeProperty("Accent") or Creator.GetThemeProperty("Text"),
                        TextSize = 12,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = idx,
                        Parent = optionList
                    })
                    Creator.AddCorner(optBtn, 6)

                    optBtn.MouseButton1Click:Connect(function()
                        if isMulti then
                            local foundIndex = table.find(selected, optStr)
                            if foundIndex then
                                table.remove(selected, foundIndex)
                            else
                                table.insert(selected, optStr)
                            end
                            if flag then ConfigManager:Set(flag, selected) end
                            valLabel.Text = getDisplayString()
                            rebuildOptions()
                            pcall(callback, selected)
                        else
                            selected = optStr
                            if flag then ConfigManager:Set(flag, selected) end
                            valLabel.Text = getDisplayString()
                            rebuildOptions()
                            pcall(callback, selected)
                        end
                    end)
                    table.insert(optionButtons, optBtn)
                end
            end

            rebuildOptions()

            local function toggleDropdown()
                isOpen = not isOpen
                local baseH = desc and 48 or 38
                local targetH = isOpen and (baseH + (#options * 32) + 8) or baseH

                Creator.Tween(card, { Size = UDim2.new(1, 0, 0, targetH) }, 0.22, Enum.EasingStyle.Back)
                Creator.Tween(arrowIcon, { Rotation = isOpen and 180 or 0 }, 0.2)
            end

            headerBtn.MouseButton1Click:Connect(toggleDropdown)

            return {
                Set = function(val)
                    selected = val
                    if flag then ConfigManager:Set(flag, selected) end
                    valLabel.Text = getDisplayString()
                    rebuildOptions()
                end,
                SetValues = function(newOptions)
                    options = newOptions or {}
                    rebuildOptions()
                end,
                GetValue = function() return selected end
            }
        end

        function Tab:CreateInput(inputConfig)
            inputConfig = inputConfig or {}
            local title = inputConfig.Title or "Input"
            local placeholder = inputConfig.Placeholder or "Enter text..."
            local default = inputConfig.Default or ""
            local numeric = inputConfig.Numeric or false
            local flag = inputConfig.Flag
            local callback = inputConfig.Callback or function() end

            if flag then
                local saved = ConfigManager:Get(flag)
                if saved ~= nil then default = saved else ConfigManager:Set(flag, default) end
            end

            local card = Creator.New("Frame", {
                Name = "Input_" .. title,
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = Creator.GetThemeProperty("CardBackground"),
                ThemeTag = { BackgroundColor3 = "CardBackground" },
                Parent = pageScroll
            })
            Creator.AddCorner(card, 8)
            local stroke = Creator.AddStroke(card, "Border", 1)

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(0.4, 0, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = Creator.GetThemeProperty("Text"),
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ThemeTag = { TextColor3 = "Text" },
                Parent = card
            })

            local boxContainer = Creator.New("Frame", {
                Name = "BoxContainer",
                Size = UDim2.new(0.55, 0, 0, 26),
                Position = UDim2.new(0.45, -12, 0.5, -13),
                BackgroundColor3 = Creator.GetThemeProperty("ToggleOff"),
                ThemeTag = { BackgroundColor3 = "ToggleOff" },
                Parent = card
            })
            Creator.AddCorner(boxContainer, 6)

            local textBox = Creator.New("TextBox", {
                Name = "TextBox",
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = default,
                PlaceholderText = placeholder,
                PlaceholderColor3 = Creator.GetThemeProperty("SubText"),
                TextColor3 = Creator.GetThemeProperty("Text"),
                TextSize = 12,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                ThemeTag = { TextColor3 = "Text", PlaceholderColor3 = "SubText" },
                Parent = boxContainer
            })

            local indicator = Creator.New("Frame", {
                Name = "Indicator",
                Size = UDim2.new(0, 0, 0, 2),
                Position = UDim2.new(0, 0, 1, -2),
                BackgroundColor3 = Creator.GetThemeProperty("Accent"),
                ThemeTag = { BackgroundColor3 = "Accent" },
                Parent = boxContainer
            })

            textBox.Focused:Connect(function()
                Creator.Tween(indicator, { Size = UDim2.new(1, 0, 0, 2) }, 0.18)
                Creator.Tween(stroke, { Color = Creator.GetThemeProperty("Accent") }, 0.18)
            end)

            textBox.FocusLost:Connect(function(enterPressed)
                Creator.Tween(indicator, { Size = UDim2.new(0, 0, 0, 2) }, 0.18)
                Creator.Tween(stroke, { Color = Creator.GetThemeProperty("Border") }, 0.18)

                if numeric then
                    local num = tonumber(textBox.Text)
                    if not num then textBox.Text = default return end
                end

                if flag then ConfigManager:Set(flag, textBox.Text) end
                pcall(callback, textBox.Text, enterPressed)
            end)

            return {
                Set = function(newText)
                    textBox.Text = tostring(newText)
                    if flag then ConfigManager:Set(flag, textBox.Text) end
                end,
                GetValue = function() return textBox.Text end
            }
        end

        function Tab:CreateKeybind(keybindConfig)
            keybindConfig = keybindConfig or {}
            local title = keybindConfig.Title or "Keybind"
            local desc = keybindConfig.Desc
            local default = keybindConfig.Default or Enum.KeyCode.E
            local flag = keybindConfig.Flag
            local callback = keybindConfig.Callback or function() end

            if flag then
                local saved = ConfigManager:Get(flag)
                if saved ~= nil then default = saved else ConfigManager:Set(flag, default) end
            end

            local boundKey = default
            local isListening = false

            local card = Creator.New("Frame", {
                Name = "Keybind_" .. title,
                Size = UDim2.new(1, 0, 0, desc and 48 or 38),
                BackgroundColor3 = Creator.GetThemeProperty("CardBackground"),
                ThemeTag = { BackgroundColor3 = "CardBackground" },
                Parent = pageScroll
            })
            Creator.AddCorner(card, 8)
            Creator.AddStroke(card, "Border", 1)

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(0.6, 0, 0, 16),
                Position = UDim2.new(0, 12, 0, desc and 8 or 11),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = Creator.GetThemeProperty("Text"),
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ThemeTag = { TextColor3 = "Text" },
                Parent = card
            })

            if desc then
                Creator.New("TextLabel", {
                    Name = "Desc",
                    Size = UDim2.new(0.6, 0, 0, 14),
                    Position = UDim2.new(0, 12, 0, 26),
                    BackgroundTransparency = 1,
                    Text = desc,
                    TextColor3 = Creator.GetThemeProperty("SubText"),
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ThemeTag = { TextColor3 = "SubText" },
                    Parent = card
                })
            end

            local bindBtn = Creator.New("TextButton", {
                Name = "BindButton",
                Size = UDim2.new(0, 75, 0, 24),
                Position = UDim2.new(1, -87, 0.5, -12),
                BackgroundColor3 = Creator.GetThemeProperty("ToggleOff"),
                AutoButtonColor = false,
                Text = typeof(boundKey) == "EnumItem" and boundKey.Name or tostring(boundKey),
                TextColor3 = Creator.GetThemeProperty("Accent"),
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                ThemeTag = { BackgroundColor3 = "ToggleOff", TextColor3 = "Accent" },
                Parent = card
            })
            Creator.AddCorner(bindBtn, 6)

            bindBtn.MouseButton1Click:Connect(function()
                isListening = true
                bindBtn.Text = "..."
                Creator.Tween(bindBtn, { BackgroundColor3 = Creator.GetThemeProperty("CardHover") }, 0.15)
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if isListening and input.UserInputType == Enum.UserInputType.Keyboard then
                    isListening = false
                    boundKey = input.KeyCode
                    bindBtn.Text = boundKey.Name
                    Creator.Tween(bindBtn, { BackgroundColor3 = Creator.GetThemeProperty("ToggleOff") }, 0.15)
                    if flag then ConfigManager:Set(flag, boundKey) end
                    pcall(callback, boundKey)
                elseif not gpe and not isListening and input.KeyCode == boundKey then
                    pcall(callback, boundKey)
                end
            end)

            return {
                Set = function(newKey)
                    boundKey = newKey
                    bindBtn.Text = typeof(boundKey) == "EnumItem" and boundKey.Name or tostring(boundKey)
                    if flag then ConfigManager:Set(flag, boundKey) end
                end,
                GetValue = function() return boundKey end
            }
        end

        function Tab:CreateColorPicker(colorConfig)
            colorConfig = colorConfig or {}
            local title = colorConfig.Title or "Color Picker"
            local desc = colorConfig.Desc
            local default = colorConfig.Default or Color3.fromRGB(247, 230, 185)
            local flag = colorConfig.Flag
            local callback = colorConfig.Callback or function() end

            if flag then
                local saved = ConfigManager:Get(flag)
                if saved ~= nil then default = saved else ConfigManager:Set(flag, default) end
            end

            local currentColor = default

            local card = Creator.New("TextButton", {
                Name = "ColorPicker_" .. title,
                Size = UDim2.new(1, 0, 0, desc and 48 or 38),
                BackgroundColor3 = Creator.GetThemeProperty("CardBackground"),
                AutoButtonColor = false,
                Text = "",
                ThemeTag = { BackgroundColor3 = "CardBackground" },
                Parent = pageScroll
            })
            Creator.AddCorner(card, 8)
            Creator.AddStroke(card, "Border", 1)

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -70, 0, 16),
                Position = UDim2.new(0, 12, 0, desc and 8 or 11),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = Creator.GetThemeProperty("Text"),
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ThemeTag = { TextColor3 = "Text" },
                Parent = card
            })

            if desc then
                Creator.New("TextLabel", {
                    Name = "Desc",
                    Size = UDim2.new(1, -70, 0, 14),
                    Position = UDim2.new(0, 12, 0, 26),
                    BackgroundTransparency = 1,
                    Text = desc,
                    TextColor3 = Creator.GetThemeProperty("SubText"),
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ThemeTag = { TextColor3 = "SubText" },
                    Parent = card
                })
            end

            local colorPreview = Creator.New("Frame", {
                Name = "ColorPreview",
                Size = UDim2.new(0, 28, 0, 20),
                Position = UDim2.new(1, -40, 0.5, -10),
                BackgroundColor3 = currentColor,
                Parent = card
            })
            Creator.AddCorner(colorPreview, 4)
            Creator.AddStroke(colorPreview, "Border", 1)

            local function setColor(newCol)
                currentColor = newCol
                colorPreview.BackgroundColor3 = currentColor
                if flag then ConfigManager:Set(flag, currentColor) end
                pcall(callback, currentColor)
            end

            card.MouseButton1Click:Connect(function()
                Window:Dialog({
                    Title = "Select Color Preset",
                    Content = "Pick a theme-synced or primary palette color:",
                    Buttons = {
                        { Text = "Gold", Variant = "Primary", Callback = function() setColor(Color3.fromRGB(247, 230, 185)) end },
                        { Text = "Blue", Variant = "Primary", Callback = function() setColor(Color3.fromRGB(75, 130, 255)) end },
                        { Text = "Emerald", Variant = "Primary", Callback = function() setColor(Color3.fromRGB(16, 185, 129)) end },
                        { Text = "Rose", Variant = "Danger", Callback = function() setColor(Color3.fromRGB(244, 63, 94)) end },
                        { Text = "Close", Variant = "Secondary" }
                    }
                })
            end)

            return {
                Set = setColor,
                GetValue = function() return currentColor end
            }
        end

        return Tab
    end

    table.insert(HoshiUI.Windows, Window)
    return Window
end

function HoshiUI:AddWindow(config) return self:CreateWindow(config) end

return HoshiUI
