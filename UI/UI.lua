-- ==============================================================================
-- HoshiUI — Next-Gen Roblox UI Library (WindUI Remake)
-- High Performance • Mobile Optimized • Perfect Centering • Footagesus/Icons
-- ==============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Safe Parent Detection
local function getSafeGuiParent()
    local success, coregui = pcall(function()
        return CoreGui
    end)
    if success and coregui then
        return coregui
    end
    return LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("StarterGui")
end

-- ==============================================================================
-- ICON ENGINE (Footagesus/Icons Multi-Set Resolver & Fast Cache)
-- ==============================================================================
local IconEngine = {
    DefaultType = "lucide",
    CacheFolder = "HoshiHub/Icons",
    LoadedSets = {},
    Urls = {
        ["lucide"] = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua",
        ["solar"] = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/solar/dist/Icons.lua",
        ["craft"] = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua",
        ["geist"] = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua",
        ["sfsymbols"] = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/sfsymbols/dist/Icons.lua",
    },
}

-- Built-in Essential Offline Fallbacks (Instant 0ms availability)
local CoreFallbackIcons = {
    ["home"] = "rbxassetid://10723407389",
    ["house"] = "rbxassetid://10723407389",
    ["settings"] = "rbxassetid://10734950309",
    ["settings-2"] = "rbxassetid://10734950309",
    ["shield"] = "rbxassetid://10734951847",
    ["zap"] = "rbxassetid://10709819149",
    ["swords"] = "rbxassetid://10734975692",
    ["sword"] = "rbxassetid://10734975486",
    ["flame"] = "rbxassetid://10709768641",
    ["sparkles"] = "rbxassetid://10734974297",
    ["sparkle"] = "rbxassetid://10734974297",
    ["sliders"] = "rbxassetid://10734973474",
    ["sliders-horizontal"] = "rbxassetid://10734973474",
    ["slider"] = "rbxassetid://10734973474",
    ["controls"] = "rbxassetid://10734973474",
    ["palette"] = "rbxassetid://10723387841",
    ["bell"] = "rbxassetid://10709752405",
    ["code"] = "rbxassetid://10709756479",
    ["terminal"] = "rbxassetid://10734982144",
    ["cpu"] = "rbxassetid://10709757657",
    ["database"] = "rbxassetid://10709758504",
    ["heart"] = "rbxassetid://10723354141",
    ["star"] = "rbxassetid://10734974984",
    ["user"] = "rbxassetid://10734988677",
    ["users"] = "rbxassetid://10734989047",
    ["folder"] = "rbxassetid://10723346158",
    ["file"] = "rbxassetid://10723344158",
    ["save"] = "rbxassetid://10734967396",
    ["refresh-cw"] = "rbxassetid://10734963384",
    ["search"] = "rbxassetid://10734965287",
    ["eye"] = "rbxassetid://10723342088",
    ["eye-off"] = "rbxassetid://10723341857",
    ["lock"] = "rbxassetid://10723374276",
    ["unlock"] = "rbxassetid://10734987768",
    ["check"] = "rbxassetid://10709755100",
    ["x"] = "rbxassetid://10734991278",
    ["chevron-down"] = "rbxassetid://10709755832",
    ["chevron-right"] = "rbxassetid://10709756012",
    ["chevron-up"] = "rbxassetid://10709756182",
    ["chevron-left"] = "rbxassetid://10709755928",
    ["play"] = "rbxassetid://10734940376",
    ["pause"] = "rbxassetid://10734939886",
    ["info"] = "rbxassetid://10723362141",
    ["alert-triangle"] = "rbxassetid://10709751935",
    ["alert-circle"] = "rbxassetid://10709751753",
    ["crosshair"] = "rbxassetid://10709757962",
    ["target"] = "rbxassetid://10734979144",
    ["compass"] = "rbxassetid://10709756783",
    ["sun"] = "rbxassetid://10734975252",
    ["moon"] = "rbxassetid://10723381442",
    ["hash"] = "rbxassetid://10723353457",
    ["activity"] = "rbxassetid://10709751410",
    ["box"] = "rbxassetid://10709753443",
    ["layers"] = "rbxassetid://10723373759",
    ["layout-grid"] = "rbxassetid://10723373997",
    ["mouse-pointer"] = "rbxassetid://10723381787",
    ["rocket"] = "rbxassetid://10734966755",
    ["globe"] = "rbxassetid://10723351058",
    ["wrench"] = "rbxassetid://10734990924",
    ["key"] = "rbxassetid://10723373407",
    ["trash"] = "rbxassetid://10734983637",
    ["copy"] = "rbxassetid://10709757364",
    ["navigation"] = "rbxassetid://10723383020",
    ["external-link"] = "rbxassetid://10709765823",
}

IconEngine.LoadedSets["lucide"] = CoreFallbackIcons

function IconEngine.LoadSet(setName)
    setName = setName:lower()
    if IconEngine.LoadedSets[setName] and IconEngine.LoadedSets[setName] ~= CoreFallbackIcons then
        return IconEngine.LoadedSets[setName]
    end

    local url = IconEngine.Urls[setName]
    if url then
        local fetchSuccess, rawLua = pcall(function()
            if game.HttpGetAsync then
                return game:HttpGetAsync(url)
            elseif game.HttpGet then
                return game:HttpGet(url)
            end
            return nil
        end)

        if fetchSuccess and rawLua and rawLua ~= "" then
            local loadSuccess, parsedTable = pcall(function()
                return loadstring(rawLua)()
            end)
            if loadSuccess and type(parsedTable) == "table" then
                IconEngine.LoadedSets[setName] = parsedTable
                return parsedTable
            end
        end
    end

    if setName == "lucide" then
        return CoreFallbackIcons
    end
    return nil
end

function IconEngine.PreloadAsync(setName)
    task.spawn(function()
        IconEngine.LoadSet(setName or IconEngine.DefaultType)
    end)
end

function IconEngine.SetIconsType(iconType)
    IconEngine.DefaultType = iconType:lower()
    IconEngine.PreloadAsync(IconEngine.DefaultType)
end

function IconEngine.GetIcon(iconQuery)
    if not iconQuery or iconQuery == "" then return nil end
    if type(iconQuery) ~= "string" then
        if tonumber(iconQuery) then return "rbxassetid://" .. tostring(iconQuery) end
        return nil
    end

    if iconQuery:sub(1, 13) == "rbxassetid://" then
        return iconQuery
    end
    if tonumber(iconQuery) then
        return "rbxassetid://" .. iconQuery
    end

    local pack = IconEngine.DefaultType
    local iconName = iconQuery

    if iconQuery:find(":") then
        local parts = iconQuery:split(":")
        pack = parts[1]:lower()
        iconName = parts[2]
    elseif iconQuery:find("^lucide%-") then
        pack = "lucide"
        iconName = iconQuery:gsub("^lucide%-", "")
    elseif iconQuery:find("^solar%-") then
        pack = "solar"
        iconName = iconQuery:gsub("^solar%-", "")
    elseif iconQuery:find("^craft%-") then
        pack = "craft"
        iconName = iconQuery:gsub("^craft%-", "")
    elseif iconQuery:find("^geist%-") then
        pack = "geist"
        iconName = iconQuery:gsub("^geist%-", "")
    elseif iconQuery:find("^sfsymbols%-") then
        pack = "sfsymbols"
        iconName = iconQuery:gsub("^sfsymbols%-", "")
    end

    local cleanName = iconName:lower():gsub("_", "-")
    local set = IconEngine.LoadedSets[pack] or IconEngine.LoadSet(pack)

    if set and set[cleanName] then
        return set[cleanName]
    end
    if CoreFallbackIcons[cleanName] then
        return CoreFallbackIcons[cleanName]
    end
    if pack ~= "lucide" then
        local lucideSet = IconEngine.LoadedSets["lucide"] or IconEngine.LoadSet("lucide")
        if lucideSet and lucideSet[cleanName] then
            return lucideSet[cleanName]
        end
    end
    return nil
end

IconEngine.PreloadAsync("lucide")

-- ==============================================================================
-- THEMES DEFINITION & ENGINE
-- ==============================================================================
local Themes = {
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
        Sidebar = Color3.fromRGB(8, 9, 12),
        ToggleOff = Color3.fromRGB(35, 38, 52),
    },
    ["Amethyst"] = {
        Background = Color3.fromRGB(18, 14, 26),
        CardBackground = Color3.fromRGB(28, 22, 40),
        CardHover = Color3.fromRGB(36, 28, 52),
        CardStroke = Color3.fromRGB(52, 40, 75),
        Border = Color3.fromRGB(46, 36, 68),
        Accent = Color3.fromRGB(175, 82, 222),
        AccentHover = Color3.fromRGB(195, 105, 240),
        AccentGlow = Color3.fromRGB(175, 82, 222),
        Text = Color3.fromRGB(250, 244, 255),
        SubText = Color3.fromRGB(170, 155, 190),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(245, 180, 50),
        Danger = Color3.fromRGB(255, 85, 105),
        Sidebar = Color3.fromRGB(14, 10, 20),
        ToggleOff = Color3.fromRGB(50, 40, 70),
    },
    ["Emerald"] = {
        Background = Color3.fromRGB(12, 20, 18),
        CardBackground = Color3.fromRGB(18, 30, 27),
        CardHover = Color3.fromRGB(24, 40, 36),
        CardStroke = Color3.fromRGB(36, 60, 54),
        Border = Color3.fromRGB(30, 52, 46),
        Accent = Color3.fromRGB(16, 185, 129),
        AccentHover = Color3.fromRGB(34, 205, 148),
        AccentGlow = Color3.fromRGB(16, 185, 129),
        Text = Color3.fromRGB(240, 250, 245),
        SubText = Color3.fromRGB(145, 175, 165),
        Success = Color3.fromRGB(52, 211, 153),
        Warning = Color3.fromRGB(251, 191, 36),
        Danger = Color3.fromRGB(239, 68, 68),
        Sidebar = Color3.fromRGB(9, 15, 13),
        ToggleOff = Color3.fromRGB(35, 55, 48),
    },
    ["Rose"] = {
        Background = Color3.fromRGB(22, 14, 18),
        CardBackground = Color3.fromRGB(34, 22, 28),
        CardHover = Color3.fromRGB(44, 28, 36),
        CardStroke = Color3.fromRGB(65, 40, 52),
        Border = Color3.fromRGB(55, 34, 44),
        Accent = Color3.fromRGB(244, 63, 94),
        AccentHover = Color3.fromRGB(251, 113, 133),
        AccentGlow = Color3.fromRGB(244, 63, 94),
        Text = Color3.fromRGB(255, 242, 246),
        SubText = Color3.fromRGB(185, 155, 165),
        Success = Color3.fromRGB(52, 211, 153),
        Warning = Color3.fromRGB(251, 191, 36),
        Danger = Color3.fromRGB(244, 63, 94),
        Sidebar = Color3.fromRGB(16, 10, 13),
        ToggleOff = Color3.fromRGB(60, 38, 48),
    },
    ["Cyberpunk"] = {
        Background = Color3.fromRGB(12, 12, 18),
        CardBackground = Color3.fromRGB(20, 20, 30),
        CardHover = Color3.fromRGB(26, 26, 40),
        CardStroke = Color3.fromRGB(0, 230, 200),
        Border = Color3.fromRGB(40, 40, 60),
        Accent = Color3.fromRGB(255, 230, 0),
        AccentHover = Color3.fromRGB(255, 240, 60),
        AccentGlow = Color3.fromRGB(255, 230, 0),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(160, 170, 190),
        Success = Color3.fromRGB(0, 255, 170),
        Warning = Color3.fromRGB(255, 200, 0),
        Danger = Color3.fromRGB(255, 50, 100),
        Sidebar = Color3.fromRGB(8, 8, 14),
        ToggleOff = Color3.fromRGB(40, 40, 55),
    }
}

-- ==============================================================================
-- UTILITY & TWEEN ENGINE
-- ==============================================================================
local HoshiUI = {
    Themes = Themes,
    ActiveTheme = Themes["Dark"],
    ActiveThemeName = "Dark",
    Icons = IconEngine,
    GetIcon = IconEngine.GetIcon,
    SetIconsType = IconEngine.SetIconsType,
    Windows = {},
    Flags = {},
}

local function tween(object, goal, duration, easingStyle, easingDirection)
    if not object then return nil end
    local info = TweenInfo.new(
        duration or 0.22,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    local anim = TweenService:Create(object, info, goal)
    anim:Play()
    return anim
end

local function createInstance(className, properties, children)
    local inst = Instance.new(className)
    for prop, val in pairs(properties or {}) do
        inst[prop] = val
    end
    for _, child in pairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function addCorner(parent, radius)
    return createInstance("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent
    })
end

local function addStroke(parent, color, thickness, transparency)
    return createInstance("UIStroke", {
        Color = color or HoshiUI.ActiveTheme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function addPadding(parent, top, bottom, left, right)
    return createInstance("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        Parent = parent
    })
end

-- ==============================================================================
-- SMOOTH DRAGGING ENGINE (Supports Mouse & Touch with Screen Clamping)
-- ==============================================================================
local function makeDraggable(handle, targetFrame)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            tween(targetFrame, { Position = newPos }, 0.04, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        end
    end)
end

-- ==============================================================================
-- AUTO-SAVE & CONFIG MANAGER
-- ==============================================================================
local ConfigManager = {
    Folder = "HoshiHub",
    File = "DefaultConfig.json",
    AutoSaveEnabled = true,
    SaveDebounceTime = 0.35,
    _saveThread = nil,
    _data = {},
    _elements = {},
}

function ConfigManager:Init(folderName, fileName, autoSave)
    self.Folder = folderName or "HoshiHub"
    self.File = fileName or "DefaultConfig.json"
    self.AutoSaveEnabled = autoSave ~= false

    if writefile and readfile and isfile and makefolder then
        pcall(function()
            if not isfolder(self.Folder) then
                makefolder(self.Folder)
            end
        end)
        self:Load()
    end
end

function ConfigManager:RegisterFlag(flag, component, initialValue)
    if not flag or flag == "" then return initialValue end
    if component then
        self._elements[flag] = component
    end

    if self._data[flag] ~= nil then
        return self._data[flag]
    else
        self._data[flag] = initialValue
    end
    return initialValue
end

function ConfigManager:Set(flag, value)
    if not flag or flag == "" then return end
    self._data[flag] = value

    if self.AutoSaveEnabled then
        self:DebouncedSave()
    end
end

function ConfigManager:Get(flag, default)
    if self._data[flag] ~= nil then
        return self._data[flag]
    end
    return default
end

function ConfigManager:DebouncedSave()
    if self._saveThread then
        task.cancel(self._saveThread)
        self._saveThread = nil
    end

    self._saveThread = task.delay(self.SaveDebounceTime, function()
        self:Save()
    end)
end

function ConfigManager:Save(customFileName)
    local targetFile = customFileName or self.File
    if not writefile then return false end

    local success, _ = pcall(function()
        local sanitized = {}
        for k, v in pairs(self._data) do
            if typeof(v) == "Color3" then
                sanitized[k] = { __type = "Color3", r = v.R, g = v.G, b = v.B }
            elseif typeof(v) == "EnumItem" then
                sanitized[k] = { __type = "EnumItem", enum = tostring(v.EnumType), name = v.Name }
            else
                sanitized[k] = v
            end
        end
        local json = HttpService:JSONEncode(sanitized)
        local path = self.Folder .. "/" .. targetFile
        if not path:find("%.json$") then path = path .. ".json" end
        writefile(path, json)
    end)

    return success
end

function ConfigManager:Load(customFileName)
    local targetFile = customFileName or self.File
    if not readfile or not isfile then return false end

    local path = self.Folder .. "/" .. targetFile
    if not path:find("%.json$") then path = path .. ".json" end

    if not isfile(path) then return false end

    local success, content = pcall(function()
        return readfile(path)
    end)

    if not success or not content then return false end

    local decodeSuccess, decoded = pcall(function()
        return HttpService:JSONDecode(content)
    end)

    if not decodeSuccess or type(decoded) ~= "table" then return false end

    for k, v in pairs(decoded) do
        if type(v) == "table" and v.__type == "Color3" then
            self._data[k] = Color3.new(v.r, v.g, v.b)
        elseif type(v) == "table" and v.__type == "EnumItem" then
            local enumType = Enum[v.enum]
            if enumType and enumType[v.name] then
                self._data[k] = enumType[v.name]
            end
        else
            self._data[k] = v
        end

        local comp = self._elements[k]
        if comp and comp.SetValue then
            pcall(function()
                comp:SetValue(self._data[k], true)
            end)
        end
    end

    return true
end

function ConfigManager:Export()
    local sanitized = {}
    for k, v in pairs(self._data) do
        if typeof(v) == "Color3" then
            sanitized[k] = { __type = "Color3", r = v.R, g = v.G, b = v.B }
        elseif typeof(v) == "EnumItem" then
            sanitized[k] = { __type = "EnumItem", enum = tostring(v.EnumType), name = v.Name }
        else
            sanitized[k] = v
        end
    end
    return HttpService:JSONEncode(sanitized)
end

-- ==============================================================================
-- NOTIFICATION SYSTEM (Bottom-Right Floating Alerts)
-- ==============================================================================
local function createNotificationHolder(screenGui)
    local holder = createInstance("Frame", {
        Name = "NotificationHolder",
        Size = UDim2.new(0, 300, 1, -40),
        Position = UDim2.new(1, -315, 0, 20),
        BackgroundTransparency = 1,
        ZIndex = 200,
        Parent = screenGui
    }, {
        createInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 8)
        })
    })
    return holder
end

-- ==============================================================================
-- FLOATING TOGGLE BUTTON (Mobile & Desktop Floating Icon)
-- ==============================================================================
local function createFloatingButton(screenGui, theme, iconAsset, onClick)
    local floatBtn = createInstance("ImageButton", {
        Name = "FloatingToggleButton",
        Size = UDim2.new(0, 46, 0, 46),
        Position = UDim2.new(0, 20, 0.5, -23),
        BackgroundColor3 = theme.Background,
        AutoButtonColor = false,
        ZIndex = 50,
        Parent = screenGui
    })
    addCorner(floatBtn, 23)
    local stroke = addStroke(floatBtn, theme.Accent, 1.5)

    createInstance("ImageLabel", {
        Name = "Shadow",
        Size = UDim2.new(1, 24, 1, 24),
        Position = UDim2.new(0, -12, 0, -12),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = theme.Accent,
        ImageTransparency = 0.65,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ScaleType = Enum.ScaleType.Slice,
        ZIndex = 49,
        Parent = floatBtn
    })

    createInstance("ImageLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0.5, -11, 0.5, -11),
        BackgroundTransparency = 1,
        Image = iconAsset or IconEngine.GetIcon("sparkles"),
        ImageColor3 = theme.Accent,
        ZIndex = 51,
        Parent = floatBtn
    })

    local dragging = false
    local dragStart = nil
    local startPos = nil
    local wasDragged = false

    floatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            wasDragged = false
            dragStart = input.Position
            startPos = floatBtn.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then
                wasDragged = true
                local newPos = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
                tween(floatBtn, { Position = newPos }, 0.04, Enum.EasingStyle.Sine)
            end
        end
    end)

    floatBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                if not wasDragged then
                    -- Direct tap/click on floating button
                    tween(floatBtn, { Size = UDim2.new(0, 40, 0, 40) }, 0.08)
                    task.wait(0.08)
                    tween(floatBtn, { Size = UDim2.new(0, 46, 0, 46) }, 0.12, Enum.EasingStyle.Back)
                    pcall(onClick)
                end
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
            end
        end
    end)

    floatBtn.MouseEnter:Connect(function()
        tween(floatBtn, { BackgroundColor3 = theme.CardHover }, 0.15)
        tween(stroke, { Color = theme.AccentHover }, 0.15)
    end)
    floatBtn.MouseLeave:Connect(function()
        tween(floatBtn, { BackgroundColor3 = theme.Background }, 0.15)
        tween(stroke, { Color = theme.Accent }, 0.15)
    end)

    return floatBtn
end

-- ==============================================================================
-- MAIN WINDOW CONSTRUCTOR (Perfect Centering & High Performance)
-- ==============================================================================
function HoshiUI:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "Hoshi UI"
    local windowSubTitle = config.SubTitle or "WindUI Remake v2.0"
    local windowIcon = IconEngine.GetIcon(config.Icon or "sparkles")
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightControl
    local themeName = config.Theme or "Dark"
    local configFolder = config.Folder or "HoshiHub"
    local configFile = config.ConfigFile or "Config.json"
    local autoSave = config.AutoSave ~= false
    local showFloatingBtn = config.FloatingButton ~= false
    local floatingIcon = IconEngine.GetIcon(config.FloatingIcon or config.Icon or "sparkles")
    local iconSet = config.IconsType or config.IconType

    if iconSet then
        IconEngine.SetIconsType(iconSet)
    end

    -- ==========================================================================
    -- 1. INSTANT ZERO-OVERHEAD HOT-RELOAD PROTECTION (O(1) C++ Pointer Lookup)
    -- ==========================================================================
    if getgenv then
        local active = getgenv().HoshiHub_ActiveWindow
        if active and active.Destroy then
            pcall(active.Destroy, active)
        end
    end

    local safeParent = getSafeGuiParent()
    local existingGui = safeParent:FindFirstChild("HoshiUI_Root")
    if existingGui then
        pcall(existingGui.Destroy, existingGui)
    end

    local theme = Themes[themeName] or Themes["Dark"]
    HoshiUI.ActiveTheme = theme
    HoshiUI.ActiveThemeName = themeName

    -- Responsive Window Sizing
    local viewport = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
    local defaultW = math.min(config.Size and config.Size.X.Offset or 680, viewport.X - 24)
    local defaultH = math.min(config.Size and config.Size.Y.Offset or 440, viewport.Y - 30)
    local windowSize = UDim2.new(0, defaultW, 0, defaultH)

    -- Initialize Config
    ConfigManager:Init(configFolder, configFile, autoSave)

    -- Create ScreenGui
    local screenGui = createInstance("ScreenGui", {
        Name = "HoshiUI_Root",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = safeParent
    })

    local notifHolder = createNotificationHolder(screenGui)

    -- Window Frame (PERFECTLY CENTERED WITH ANCHORPOINT (0.5, 0.5))
    local mainFrame = createInstance("Frame", {
        Name = "MainFrame",
        Size = windowSize,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Background,
        ClipsDescendants = false,
        Parent = screenGui
    })
    addCorner(mainFrame, 12)
    local mainStroke = addStroke(mainFrame, theme.Border, 1)

    local uiScale = createInstance("UIScale", {
        Scale = 1,
        Parent = mainFrame
    })

    createInstance("ImageLabel", {
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

    -- Topbar Header
    local topBar = createInstance("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    addCorner(topBar, 12)

    local topBarCover = createInstance("Frame", {
        Name = "Cover",
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        Parent = topBar
    })

    local topBarLine = createInstance("Frame", {
        Name = "Line",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = theme.Border,
        BorderSizePixel = 0,
        Parent = topBar
    })

    local topIcon = nil
    local titleOffset = 16
    if windowIcon then
        topIcon = createInstance("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(0, 14, 0.5, -11),
            BackgroundTransparency = 1,
            Image = windowIcon,
            ImageColor3 = theme.Accent,
            Parent = topBar
        })
        titleOffset = 44
    end

    local titleContainer = createInstance("Frame", {
        Name = "TitleContainer",
        Size = UDim2.new(1, -titleOffset - 90, 1, 0),
        Position = UDim2.new(0, titleOffset, 0, 0),
        BackgroundTransparency = 1,
        Parent = topBar
    })

    local titleLabel = createInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0, 6),
        BackgroundTransparency = 1,
        Text = windowTitle,
        TextColor3 = theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = titleContainer
    })

    local subTitleLabel = createInstance("TextLabel", {
        Name = "SubTitle",
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundTransparency = 1,
        Text = windowSubTitle,
        TextColor3 = theme.SubText,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = titleContainer
    })

    -- Topbar Action Buttons (Anchored cleanly to top right)
    local actionsContainer = createInstance("Frame", {
        Name = "Actions",
        Size = UDim2.new(0, 75, 1, 0),
        Position = UDim2.new(1, -12, 0, 0),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Parent = topBar
    })
    createInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = actionsContainer
    })

    local function createTopBarButton(name, iconId, hoverColor, onClick)
        local btn = createInstance("ImageButton", {
            Name = name,
            Size = UDim2.new(0, 28, 0, 28),
            BackgroundColor3 = theme.CardBackground,
            AutoButtonColor = false,
            Parent = actionsContainer
        })
        addCorner(btn, 6)
        addStroke(btn, theme.Border, 1)

        local ico = createInstance("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0.5, -7, 0.5, -7),
            BackgroundTransparency = 1,
            Image = IconEngine.GetIcon(iconId) or iconId,
            ImageColor3 = theme.SubText,
            Parent = btn
        })

        btn.MouseEnter:Connect(function()
            tween(btn, { BackgroundColor3 = hoverColor or theme.CardHover }, 0.15)
            tween(ico, { ImageColor3 = theme.Text }, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, { BackgroundColor3 = theme.CardBackground }, 0.15)
            tween(ico, { ImageColor3 = theme.SubText }, 0.15)
        end)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    local isMinimized = false
    local originalSize = windowSize

    createTopBarButton("Minimize", "chevron-up", theme.CardHover, function()
        isMinimized = not isMinimized
        if isMinimized then
            tween(mainFrame, { Size = UDim2.new(0, defaultW, 0, 48) }, 0.22)
        else
            tween(mainFrame, { Size = originalSize }, 0.22)
        end
    end)

    local isVisible = true

    local function toggleWindow(forcedState)
        if forcedState ~= nil then
            isVisible = forcedState
        else
            isVisible = not isVisible
        end

        if isVisible then
            mainFrame.Visible = true
            uiScale.Scale = 0.88
            tween(uiScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            local anim = tween(uiScale, { Scale = 0.88 }, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
            if anim then
                anim.Completed:Connect(function()
                    if not isVisible then
                        mainFrame.Visible = false
                    end
                end)
            else
                mainFrame.Visible = false
            end
        end
    end

    createTopBarButton("Close", "x", Color3.fromRGB(180, 40, 50), function()
        toggleWindow(false)
    end)

    makeDraggable(topBar, mainFrame)

    local body = createInstance("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -48),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = mainFrame
    })

    local sidebarWidth = math.clamp(math.floor(defaultW * 0.27), 150, 185)

    local sidebar = createInstance("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        Parent = body
    })
    addCorner(sidebar, 12)

    createInstance("Frame", {
        Name = "Cover",
        Size = UDim2.new(0, 12, 1, 0),
        Position = UDim2.new(1, -12, 0, 0),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        Parent = sidebar
    })

    createInstance("Frame", {
        Name = "Line",
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.Border,
        BorderSizePixel = 0,
        Parent = sidebar
    })

    local tabListScroll = createInstance("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, 0, 1, -10),
        Position = UDim2.new(0, 0, 0, 5),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = sidebar
    })
    addPadding(tabListScroll, 6, 6, 6, 6)
    createInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = tabListScroll
    })

    local contentArea = createInstance("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -sidebarWidth - 1, 1, 0),
        Position = UDim2.new(0, sidebarWidth + 1, 0, 0),
        BackgroundTransparency = 1,
        Parent = body
    })

    local floatingBtn = nil
    if showFloatingBtn then
        floatingBtn = createFloatingButton(screenGui, theme, floatingIcon, function()
            toggleWindow()
        end)
    end

    local windowConnections = {}

    -- Window Object
    local Window = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        FloatingButton = floatingBtn,
        Tabs = {},
        ActiveTab = nil,
        ConfigManager = ConfigManager,
        Icons = IconEngine,
        Theme = theme,
        _connections = windowConnections
    }

    function Window:Toggle(state)
        toggleWindow(state)
    end

    function Window:Show()
        toggleWindow(true)
    end

    function Window:Hide()
        toggleWindow(false)
    end

    function Window:SetFloatingVisible(visible)
        if floatingBtn then
            floatingBtn.Visible = visible
        end
    end

    function Window:Destroy()
        for _, conn in pairs(self._connections) do
            pcall(function()
                conn:Disconnect()
            end)
        end
        if self.ScreenGui and self.ScreenGui.Parent then
            pcall(function()
                self.ScreenGui:Destroy()
            end)
        end
        if getgenv and getgenv().HoshiHub_ActiveWindow == self then
            getgenv().HoshiHub_ActiveWindow = nil
        end
    end

    table.insert(windowConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == toggleKey then
            toggleWindow()
        end
    end))

    if getgenv then
        getgenv().HoshiHub_ActiveWindow = Window
    end

    -- ==============================================================================
    -- NOTIFICATION METHOD
    -- ==============================================================================
    function Window:Notify(notifConfig)
        notifConfig = notifConfig or {}
        local nTitle = notifConfig.Title or "Notification"
        local nContent = notifConfig.Content or notifConfig.Text or ""
        local nIcon = IconEngine.GetIcon(notifConfig.Icon or "bell") or IconEngine.GetIcon("info")
        local nDuration = notifConfig.Duration or 4
        local nType = notifConfig.Type or "Info"

        local typeColor = theme.Accent
        if nType == "Success" then typeColor = theme.Success
        elseif nType == "Warning" then typeColor = theme.Warning
        elseif nType == "Danger" then typeColor = theme.Danger end

        local card = createInstance("Frame", {
            Name = "NotificationCard",
            Size = UDim2.new(1, 0, 0, 68),
            BackgroundColor3 = theme.CardBackground,
            ClipsDescendants = true,
            Parent = notifHolder
        })
        addCorner(card, 8)
        addStroke(card, theme.Border, 1)

        local iconImg = createInstance("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 12, 0, 12),
            BackgroundTransparency = 1,
            Image = nIcon,
            ImageColor3 = typeColor,
            Parent = card
        })

        local cardTitle = createInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -42, 0, 18),
            Position = UDim2.new(0, 38, 0, 10),
            BackgroundTransparency = 1,
            Text = nTitle,
            TextColor3 = theme.Text,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card
        })

        local cardDesc = createInstance("TextLabel", {
            Name = "Content",
            Size = UDim2.new(1, -42, 0, 28),
            Position = UDim2.new(0, 38, 0, 28),
            BackgroundTransparency = 1,
            Text = nContent,
            TextColor3 = theme.SubText,
            TextSize = 10,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Parent = card
        })

        local progressBg = createInstance("Frame", {
            Name = "ProgressBg",
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = theme.Border,
            BorderSizePixel = 0,
            Parent = card
        })

        local progressFill = createInstance("Frame", {
            Name = "ProgressFill",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = typeColor,
            BorderSizePixel = 0,
            Parent = progressBg
        })

        card.Position = UDim2.new(1, 300, 0, 0)
        tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.22, Enum.EasingStyle.Sine)
        tween(progressFill, { Size = UDim2.new(0, 0, 1, 0) }, nDuration, Enum.EasingStyle.Linear)

        task.delay(nDuration, function()
            if card and card.Parent then
                tween(card, { BackgroundTransparency = 1 }, 0.18)
                tween(cardTitle, { TextTransparency = 1 }, 0.18)
                tween(cardDesc, { TextTransparency = 1 }, 0.18)
                tween(iconImg, { ImageTransparency = 1 }, 0.18)
                task.wait(0.18)
                card:Destroy()
            end
        end)
    end

    -- ==============================================================================
    -- MODAL / CONFIRMATION DIALOG
    -- ==============================================================================
    function Window:Dialog(dialogConfig)
        dialogConfig = dialogConfig or {}
        local dTitle = dialogConfig.Title or "Confirmation"
        local dContent = dialogConfig.Content or "Are you sure you want to proceed?"
        local dButtons = dialogConfig.Buttons or {
            { Text = "Confirm", Variant = "Primary" },
            { Text = "Cancel", Variant = "Secondary" }
        }

        local modalOverlay = createInstance("TextButton", {
            Name = "DialogOverlay",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.45,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 100,
            Parent = mainFrame
        })
        addCorner(modalOverlay, 12)

        local dialogBox = createInstance("Frame", {
            Name = "DialogBox",
            Size = UDim2.new(0, math.min(340, defaultW - 30), 0, 160),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme.CardBackground,
            ZIndex = 101,
            Parent = modalOverlay
        })
        addCorner(dialogBox, 10)
        addStroke(dialogBox, theme.Border, 1)

        createInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -30, 0, 24),
            Position = UDim2.new(0, 16, 0, 12),
            BackgroundTransparency = 1,
            Text = dTitle,
            TextColor3 = theme.Text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 102,
            Parent = dialogBox
        })

        createInstance("TextLabel", {
            Name = "Content",
            Size = UDim2.new(1, -32, 0, 48),
            Position = UDim2.new(0, 16, 0, 38),
            BackgroundTransparency = 1,
            Text = dContent,
            TextColor3 = theme.SubText,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            ZIndex = 102,
            Parent = dialogBox
        })

        local btnContainer = createInstance("Frame", {
            Name = "Buttons",
            Size = UDim2.new(1, -32, 0, 32),
            Position = UDim2.new(0, 16, 1, -44),
            BackgroundTransparency = 1,
            ZIndex = 102,
            Parent = dialogBox
        })
        createInstance("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 8),
            Parent = btnContainer
        })

        for _, btnData in ipairs(dButtons) do
            local isPrimary = btnData.Variant == "Primary"
            local isDanger = btnData.Variant == "Danger"
            local btnBgColor = isPrimary and theme.Accent or (isDanger and theme.Danger or theme.CardHover)

            local dBtn = createInstance("TextButton", {
                Name = "Btn_" .. btnData.Text,
                Size = UDim2.new(0, 85, 1, 0),
                BackgroundColor3 = btnBgColor,
                Text = btnData.Text,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = false,
                ZIndex = 103,
                Parent = btnContainer
            })
            addCorner(dBtn, 6)

            dBtn.MouseButton1Click:Connect(function()
                modalOverlay:Destroy()
                if btnData.Callback then
                    btnData.Callback()
                end
            end)
        end
    end

    -- ==============================================================================
    -- TAB CREATION (Consistent Icon Spacing & Active Indicator)
    -- ==============================================================================
    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabTitle = tabConfig.Title or "Tab"
        local tabIcon = IconEngine.GetIcon(tabConfig.Icon or "folder") or IconEngine.GetIcon("folder")

        local tabBtn = createInstance("TextButton", {
            Name = "TabBtn_" .. tabTitle,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = theme.Sidebar,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            Parent = tabListScroll
        })
        addCorner(tabBtn, 8)

        local tabIconImg = createInstance("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 10, 0.5, -8),
            BackgroundTransparency = 1,
            Image = tabIcon,
            ImageColor3 = theme.SubText,
            Parent = tabBtn
        })

        local tabLabel = createInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -40, 1, 0),
            Position = UDim2.new(0, 34, 0, 0),
            BackgroundTransparency = 1,
            Text = tabTitle,
            TextColor3 = theme.SubText,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = tabBtn
        })

        local activeBar = createInstance("Frame", {
            Name = "ActiveBar",
            Size = UDim2.new(0, 3, 0, 16),
            Position = UDim2.new(0, 0, 0.5, -8),
            BackgroundColor3 = theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = tabBtn
        })
        addCorner(activeBar, 2)

        local page = createInstance("ScrollingFrame", {
            Name = "Page_" .. tabTitle,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = contentArea
        })
        addPadding(page, 12, 12, 12, 12)
        createInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = page
        })

        local Tab = {
            Button = tabBtn,
            Page = page,
            Window = Window
        }

        local function activateTab()
            for _, otherTab in pairs(Window.Tabs) do
                otherTab.Page.Visible = false
                tween(otherTab.Button, { BackgroundTransparency = 1 }, 0.18)
                local otherIco = otherTab.Button:FindFirstChild("Icon")
                if otherIco then tween(otherIco, { ImageColor3 = theme.SubText }, 0.18) end
                local otherTitle = otherTab.Button:FindFirstChild("Title")
                if otherTitle then tween(otherTitle, { TextColor3 = theme.SubText }, 0.18) end
                local otherBar = otherTab.Button:FindFirstChild("ActiveBar")
                if otherBar then tween(otherBar, { BackgroundTransparency = 1 }, 0.18) end
            end

            page.Visible = true
            Window.ActiveTab = Tab
            tween(tabBtn, { BackgroundTransparency = 0.85, BackgroundColor3 = theme.Accent }, 0.18)
            if tabIconImg then tween(tabIconImg, { ImageColor3 = theme.Accent }, 0.18) end
            tween(tabLabel, { TextColor3 = theme.Text }, 0.18)
            tween(activeBar, { BackgroundTransparency = 0 }, 0.18)
        end

        tabBtn.MouseButton1Click:Connect(activateTab)

        tabBtn.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                tween(tabBtn, { BackgroundTransparency = 0.9, BackgroundColor3 = theme.CardHover }, 0.15)
                tween(tabLabel, { TextColor3 = theme.Text }, 0.15)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                tween(tabBtn, { BackgroundTransparency = 1 }, 0.15)
                tween(tabLabel, { TextColor3 = theme.SubText }, 0.15)
            end
        end)

        table.insert(Window.Tabs, Tab)

        if #Window.Tabs == 1 then
            activateTab()
        end

        -- ==========================================================================
        -- TAB INTERACTIVE COMPONENTS BUILDER
        -- ==========================================================================

        -- 1. SECTION
        function Tab:CreateSection(title, subTitle)
            local secFrame = createInstance("Frame", {
                Name = "Section_" .. title,
                Size = UDim2.new(1, 0, 0, subTitle and 34 or 22),
                BackgroundTransparency = 1,
                Parent = page
            })

            createInstance("TextLabel", {
                Name = "SectionTitle",
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                Text = title:upper(),
                TextColor3 = theme.Accent,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = secFrame
            })

            if subTitle then
                createInstance("TextLabel", {
                    Name = "SectionSubTitle",
                    Size = UDim2.new(1, 0, 0, 14),
                    Position = UDim2.new(0, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Text = subTitle,
                    TextColor3 = theme.SubText,
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = secFrame
                })
            end
            return secFrame
        end

        -- 2. BUTTON
        function Tab:CreateButton(btnConfig)
            btnConfig = btnConfig or {}
            local title = btnConfig.Title or "Button"
            local desc = btnConfig.Desc or btnConfig.SubTitle
            local icon = IconEngine.GetIcon(btnConfig.Icon)
            local callback = btnConfig.Callback or function() end
            local variant = btnConfig.Variant or "Secondary"

            local bgColor = variant == "Primary" and theme.Accent or theme.CardBackground

            local btnCard = createInstance("TextButton", {
                Name = "Button_" .. title,
                Size = UDim2.new(1, 0, 0, desc and 46 or 36),
                BackgroundColor3 = bgColor,
                AutoButtonColor = false,
                Text = "",
                Parent = page
            })
            addCorner(btnCard, 8)
            addStroke(btnCard, theme.Border, 1)

            local textOffset = 12
            if icon then
                createInstance("ImageLabel", {
                    Name = "Icon",
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0, 12, 0.5, -8),
                    BackgroundTransparency = 1,
                    Image = icon,
                    ImageColor3 = variant == "Primary" and Color3.fromRGB(255, 255, 255) or theme.Accent,
                    Parent = btnCard
                })
                textOffset = 36
            end

            local btnTitle = createInstance("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -textOffset - 12, 0, 16),
                Position = UDim2.new(0, textOffset, 0, desc and 6 or 10),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = btnCard
            })

            if desc then
                createInstance("TextLabel", {
                    Name = "Desc",
                    Size = UDim2.new(1, -textOffset - 12, 0, 14),
                    Position = UDim2.new(0, textOffset, 0, 24),
                    BackgroundTransparency = 1,
                    Text = desc,
                    TextColor3 = variant == "Primary" and Color3.fromRGB(220, 230, 255) or theme.SubText,
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = btnCard
                })
            end

            btnCard.MouseButton1Click:Connect(function()
                tween(btnCard, { Size = UDim2.new(1, -4, 0, desc and 44 or 34) }, 0.08)
                task.wait(0.08)
                tween(btnCard, { Size = UDim2.new(1, 0, 0, desc and 46 or 36) }, 0.08)
                pcall(callback)
            end)

            btnCard.MouseEnter:Connect(function()
                tween(btnCard, { BackgroundColor3 = variant == "Primary" and theme.AccentHover or theme.CardHover }, 0.15)
            end)
            btnCard.MouseLeave:Connect(function()
                tween(btnCard, { BackgroundColor3 = bgColor }, 0.15)
            end)

            return {
                SetTitle = function(_, newTitle) btnTitle.Text = newTitle end,
                Instance = btnCard
            }
        end

        -- 3. TOGGLE
        function Tab:CreateToggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            local title = toggleConfig.Title or "Toggle"
            local desc = toggleConfig.Desc or toggleConfig.SubTitle
            local flag = toggleConfig.Flag
            local default = toggleConfig.Default or false
            local callback = toggleConfig.Callback or function() end

            local value = ConfigManager:RegisterFlag(flag, nil, default)
            if value == nil then value = default end

            local card = createInstance("TextButton", {
                Name = "Toggle_" .. title,
                Size = UDim2.new(1, 0, 0, desc and 46 or 38),
                BackgroundColor3 = theme.CardBackground,
                AutoButtonColor = false,
                Text = "",
                Parent = page
            })
            addCorner(card, 8)
            addStroke(card, theme.Border, 1)

            createInstance("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -65, 0, 16),
                Position = UDim2.new(0, 12, 0, desc and 6 or 11),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card
            })

            if desc then
                createInstance("TextLabel", {
                    Name = "Desc",
                    Size = UDim2.new(1, -65, 0, 14),
                    Position = UDim2.new(0, 12, 0, 24),
                    BackgroundTransparency = 1,
                    Text = desc,
                    TextColor3 = theme.SubText,
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = card
                })
            end

            local switchTrack = createInstance("Frame", {
                Name = "SwitchTrack",
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -52, 0.5, -10),
                BackgroundColor3 = value and theme.Accent or theme.ToggleOff,
                Parent = card
            })
            addCorner(switchTrack, 10)

            local switchKnob = createInstance("Frame", {
                Name = "Knob",
                Size = UDim2.new(0, 14, 0, 14),
                Position = value and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = switchTrack
            })
            addCorner(switchKnob, 7)

            local ToggleObj = {}

            local function updateToggle(newVal, silent)
                value = newVal
                if flag then ConfigManager:Set(flag, value) end

                if value then
                    tween(switchTrack, { BackgroundColor3 = theme.Accent }, 0.18)
                    tween(switchKnob, { Position = UDim2.new(1, -17, 0.5, -7) }, 0.18, Enum.EasingStyle.Back)
                else
                    tween(switchTrack, { BackgroundColor3 = theme.ToggleOff }, 0.18)
                    tween(switchKnob, { Position = UDim2.new(0, 3, 0.5, -7) }, 0.18, Enum.EasingStyle.Back)
                end

                if not silent then
                    pcall(callback, value)
                end
            end

            card.MouseButton1Click:Connect(function()
                updateToggle(not value)
            end)

            card.MouseEnter:Connect(function()
                tween(card, { BackgroundColor3 = theme.CardHover }, 0.15)
            end)
            card.MouseLeave:Connect(function()
                tween(card, { BackgroundColor3 = theme.CardBackground }, 0.15)
            end)

            if value ~= default then
                task.spawn(function()
                    pcall(callback, value)
                end)
            end

            ToggleObj.SetValue = function(_, newVal, silent)
                updateToggle(newVal, silent)
            end
            ToggleObj.GetValue = function(_)
                return value
            end
            ToggleObj.Instance = card

            if flag then ConfigManager._elements[flag] = ToggleObj end

            return ToggleObj
        end

        -- 4. SLIDER
        function Tab:CreateSlider(sliderConfig)
            sliderConfig = sliderConfig or {}
            local title = sliderConfig.Title or "Slider"
            local desc = sliderConfig.Desc or sliderConfig.SubTitle
            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local step = sliderConfig.Step or 1
            local default = sliderConfig.Default or min
            local formatStr = sliderConfig.Format or "{value}"
            local flag = sliderConfig.Flag
            local callback = sliderConfig.Callback or function() end

            local value = ConfigManager:RegisterFlag(flag, nil, default)
            if value == nil then value = default end
            value = math.clamp(value, min, max)

            local card = createInstance("Frame", {
                Name = "Slider_" .. title,
                Size = UDim2.new(1, 0, 0, desc and 54 or 44),
                BackgroundColor3 = theme.CardBackground,
                Parent = page
            })
            addCorner(card, 8)
            addStroke(card, theme.Border, 1)

            createInstance("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -85, 0, 16),
                Position = UDim2.new(0, 12, 0, 7),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card
            })

            local function formatValue(v)
                return formatStr:gsub("{value}", tostring(v))
            end

            local valueDisplay = createInstance("TextLabel", {
                Name = "ValueDisplay",
                Size = UDim2.new(0, 70, 0, 16),
                Position = UDim2.new(1, -80, 0, 7),
                BackgroundTransparency = 1,
                Text = formatValue(value),
                TextColor3 = theme.Accent,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = card
            })

            local trackHitbox = createInstance("ImageButton", {
                Name = "TrackHitbox",
                Size = UDim2.new(1, -24, 0, 20),
                Position = UDim2.new(0, 12, 1, -24),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Parent = card
            })

            local track = createInstance("Frame", {
                Name = "Track",
                Size = UDim2.new(1, 0, 0, 6),
                Position = UDim2.new(0, 0, 0.5, -3),
                BackgroundColor3 = theme.ToggleOff,
                BorderSizePixel = 0,
                Parent = trackHitbox
            })
            addCorner(track, 3)

            local pct = (value - min) / (max - min)
            local fill = createInstance("Frame", {
                Name = "Fill",
                Size = UDim2.new(pct, 0, 1, 0),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                Parent = track
            })
            addCorner(fill, 3)

            local knob = createInstance("Frame", {
                Name = "Knob",
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(1, -7, 0.5, -7),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = fill
            })
            addCorner(knob, 7)

            local SliderObj = {}
            local isDragging = false

            local function updateFromValue(v, silent)
                v = math.clamp(v, min, max)
                if step > 0 then
                    v = math.floor((v - min) / step + 0.5) * step + min
                end
                value = v
                local newPct = (value - min) / (max - min)

                tween(fill, { Size = UDim2.new(newPct, 0, 1, 0) }, 0.04)
                valueDisplay.Text = formatValue(value)

                if flag then ConfigManager:Set(flag, value) end

                if not silent then
                    pcall(callback, value)
                end
            end

            local function updateFromInput(input)
                local posX = input.Position.X - track.AbsolutePosition.X
                local newPct = math.clamp(posX / track.AbsoluteSize.X, 0, 1)
                local calculated = min + (max - min) * newPct
                updateFromValue(calculated)
            end

            trackHitbox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = true
                    updateFromInput(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromInput(input)
                end
            end)

            SliderObj.SetValue = function(_, newVal, silent)
                updateFromValue(newVal, silent)
            end
            SliderObj.GetValue = function(_)
                return value
            end
            SliderObj.Instance = card

            if flag then ConfigManager._elements[flag] = SliderObj end

            return SliderObj
        end

        -- 5. DROPDOWN (Expandable with Auto-Layout)
        function Tab:CreateDropdown(dropConfig)
            dropConfig = dropConfig or {}
            local title = dropConfig.Title or "Dropdown"
            local options = dropConfig.Options or dropConfig.Values or {}
            local isMulti = dropConfig.Multi or false
            local default = dropConfig.Default or (isMulti and {} or options[1])
            local flag = dropConfig.Flag
            local callback = dropConfig.Callback or function() end

            local currentVal = ConfigManager:RegisterFlag(flag, nil, default)
            if currentVal == nil then currentVal = default end

            local isExpanded = false
            local card = createInstance("Frame", {
                Name = "Dropdown_" .. title,
                Size = UDim2.new(1, 0, 0, 44),
                BackgroundColor3 = theme.CardBackground,
                ClipsDescendants = true,
                Parent = page
            })
            addCorner(card, 8)
            addStroke(card, theme.Border, 1)

            local headerBtn = createInstance("TextButton", {
                Name = "HeaderBtn",
                Size = UDim2.new(1, 0, 0, 44),
                BackgroundTransparency = 1,
                Text = "",
                Parent = card
            })

            createInstance("TextLabel", {
                Name = "Title",
                Size = UDim2.new(0.5, 0, 0, 16),
                Position = UDim2.new(0, 12, 0, 8),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = headerBtn
            })

            local function getDisplayString()
                if isMulti then
                    if type(currentVal) == "table" and #currentVal > 0 then
                        return table.concat(currentVal, ", ")
                    end
                    return "None"
                end
                return tostring(currentVal or "Select...")
            end

            local valLabel = createInstance("TextLabel", {
                Name = "ValLabel",
                Size = UDim2.new(0.4, 0, 0, 16),
                Position = UDim2.new(0.6, -30, 0, 14),
                BackgroundTransparency = 1,
                Text = getDisplayString(),
                TextColor3 = theme.Accent,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = headerBtn
            })

            local arrowIco = createInstance("ImageLabel", {
                Name = "Arrow",
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(1, -26, 0.5, -7),
                BackgroundTransparency = 1,
                Image = IconEngine.GetIcon("chevron-down"),
                ImageColor3 = theme.SubText,
                Parent = headerBtn
            })

            local optContainer = createInstance("ScrollingFrame", {
                Name = "OptionsList",
                Size = UDim2.new(1, -20, 0, 110),
                Position = UDim2.new(0, 10, 0, 46),
                BackgroundTransparency = 1,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = theme.Border,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Parent = card
            })
            createInstance("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = optContainer
            })

            local DropdownObj = {}

            local function renderOptions()
                for _, child in pairs(optContainer:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end

                for _, opt in ipairs(options) do
                    local isSelected = false
                    if isMulti and type(currentVal) == "table" then
                        isSelected = table.find(currentVal, opt) ~= nil
                    else
                        isSelected = (currentVal == opt)
                    end

                    local optBtn = createInstance("TextButton", {
                        Name = "Opt_" .. opt,
                        Size = UDim2.new(1, 0, 0, 26),
                        BackgroundColor3 = isSelected and theme.CardHover or theme.Sidebar,
                        AutoButtonColor = false,
                        Text = "",
                        Parent = optContainer
                    })
                    addCorner(optBtn, 6)

                    createInstance("TextLabel", {
                        Name = "Label",
                        Size = UDim2.new(1, -28, 1, 0),
                        Position = UDim2.new(0, 8, 0, 0),
                        BackgroundTransparency = 1,
                        Text = tostring(opt),
                        TextColor3 = isSelected and theme.Accent or theme.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = optBtn
                    })

                    if isSelected then
                        createInstance("ImageLabel", {
                            Name = "Check",
                            Size = UDim2.new(0, 12, 0, 12),
                            Position = UDim2.new(1, -20, 0.5, -6),
                            BackgroundTransparency = 1,
                            Image = IconEngine.GetIcon("check"),
                            ImageColor3 = theme.Accent,
                            Parent = optBtn
                        })
                    end

                    optBtn.MouseButton1Click:Connect(function()
                        if isMulti then
                            if type(currentVal) ~= "table" then currentVal = {} end
                            local idx = table.find(currentVal, opt)
                            if idx then
                                table.remove(currentVal, idx)
                            else
                                table.insert(currentVal, opt)
                            end
                        else
                            currentVal = opt
                            isExpanded = false
                            tween(card, { Size = UDim2.new(1, 0, 0, 44) }, 0.18)
                            tween(arrowIco, { Rotation = 0 }, 0.18)
                        end

                        valLabel.Text = getDisplayString()
                        if flag then ConfigManager:Set(flag, currentVal) end
                        renderOptions()
                        pcall(callback, currentVal)
                    end)
                end
            end

            headerBtn.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                if isExpanded then
                    local targetH = math.min(46 + #options * 30, 160)
                    tween(card, { Size = UDim2.new(1, 0, 0, targetH) }, 0.18)
                    tween(arrowIco, { Rotation = 180 }, 0.18)
                else
                    tween(card, { Size = UDim2.new(1, 0, 0, 44) }, 0.18)
                    tween(arrowIco, { Rotation = 0 }, 0.18)
                end
            end)

            renderOptions()

            DropdownObj.SetValue = function(_, newVal, silent)
                currentVal = newVal
                valLabel.Text = getDisplayString()
                renderOptions()
                if not silent then pcall(callback, currentVal) end
            end
            DropdownObj.SetOptions = function(_, newOptions)
                options = newOptions
                renderOptions()
            end
            DropdownObj.GetValue = function(_)
                return currentVal
            end
            DropdownObj.Instance = card

            if flag then ConfigManager._elements[flag] = DropdownObj end

            return DropdownObj
        end

        -- 6. COLOR PICKER
        function Tab:CreateColorPicker(colorConfig)
            colorConfig = colorConfig or {}
            local title = colorConfig.Title or "Color Picker"
            local default = colorConfig.Default or Color3.fromRGB(75, 130, 255)
            local flag = colorConfig.Flag
            local callback = colorConfig.Callback or function() end

            local currentColor = ConfigManager:RegisterFlag(flag, nil, default)
            if currentColor == nil then currentColor = default end

            local card = createInstance("Frame", {
                Name = "ColorPicker_" .. title,
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = theme.CardBackground,
                Parent = page
            })
            addCorner(card, 8)
            addStroke(card, theme.Border, 1)

            createInstance("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -75, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card
            })

            local colorPill = createInstance("TextButton", {
                Name = "ColorPill",
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -52, 0.5, -10),
                BackgroundColor3 = currentColor,
                AutoButtonColor = false,
                Text = "",
                Parent = card
            })
            addCorner(colorPill, 6)
            addStroke(colorPill, theme.Border, 1)

            local ColorObj = {}

            colorPill.MouseButton1Click:Connect(function()
                Window:Dialog({
                    Title = "Color: " .. title,
                    Content = "Choose an accent preset:",
                    Buttons = {
                        { Text = "Blue", Callback = function() ColorObj:SetValue(Color3.fromRGB(75, 130, 255)) end },
                        { Text = "Green", Callback = function() ColorObj:SetValue(Color3.fromRGB(46, 204, 113)) end },
                        { Text = "Purple", Callback = function() ColorObj:SetValue(Color3.fromRGB(175, 82, 222)) end },
                        { Text = "Red", Variant = "Danger", Callback = function() ColorObj:SetValue(Color3.fromRGB(231, 76, 60)) end },
                        { Text = "Close", Variant = "Secondary" }
                    }
                })
            end)

            ColorObj.SetValue = function(_, newColor, silent)
                currentColor = newColor
                colorPill.BackgroundColor3 = currentColor
                if flag then ConfigManager:Set(flag, currentColor) end
                if not silent then pcall(callback, currentColor) end
            end
            ColorObj.GetValue = function(_)
                return currentColor
            end
            ColorObj.Instance = card

            if flag then ConfigManager._elements[flag] = ColorObj end

            return ColorObj
        end

        -- 7. KEYBIND
        function Tab:CreateKeybind(keyConfig)
            keyConfig = keyConfig or {}
            local title = keyConfig.Title or "Keybind"
            local default = keyConfig.Default or Enum.KeyCode.E
            local flag = keyConfig.Flag
            local callback = keyConfig.Callback or function() end

            local currentKey = ConfigManager:RegisterFlag(flag, nil, default)
            if currentKey == nil then currentKey = default end

            local isListening = false

            local card = createInstance("Frame", {
                Name = "Keybind_" .. title,
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = theme.CardBackground,
                Parent = page
            })
            addCorner(card, 8)
            addStroke(card, theme.Border, 1)

            createInstance("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -100, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card
            })

            local keyBadge = createInstance("TextButton", {
                Name = "Badge",
                Size = UDim2.new(0, 70, 0, 22),
                Position = UDim2.new(1, -82, 0.5, -11),
                BackgroundColor3 = theme.Sidebar,
                AutoButtonColor = false,
                Text = currentKey.Name,
                TextColor3 = theme.Accent,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                Parent = card
            })
            addCorner(keyBadge, 6)
            addStroke(keyBadge, theme.Border, 1)

            keyBadge.MouseButton1Click:Connect(function()
                isListening = true
                keyBadge.Text = "..."
                tween(keyBadge, { TextColor3 = theme.Warning }, 0.15)
            end)

            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if isListening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        keyBadge.Text = currentKey.Name
                        isListening = false
                        tween(keyBadge, { TextColor3 = theme.Accent }, 0.15)
                        if flag then ConfigManager:Set(flag, currentKey) end
                    end
                elseif not gameProcessed and input.KeyCode == currentKey then
                    pcall(callback)
                end
            end)

            local KeybindObj = {}
            KeybindObj.SetValue = function(_, newKey)
                currentKey = newKey
                keyBadge.Text = currentKey.Name
                if flag then ConfigManager:Set(flag, currentKey) end
            end
            KeybindObj.GetValue = function(_)
                return currentKey
            end
            KeybindObj.Instance = card

            if flag then ConfigManager._elements[flag] = KeybindObj end

            return KeybindObj
        end

        -- 8. INPUT
        function Tab:CreateInput(inputConfig)
            inputConfig = inputConfig or {}
            local title = inputConfig.Title or "Input"
            local placeholder = inputConfig.Placeholder or "Type here..."
            local default = inputConfig.Default or ""
            local numericOnly = inputConfig.NumericOnly or false
            local flag = inputConfig.Flag
            local callback = inputConfig.Callback or function() end

            local currentText = ConfigManager:RegisterFlag(flag, nil, default)
            if currentText == nil then currentText = default end

            local card = createInstance("Frame", {
                Name = "Input_" .. title,
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = theme.CardBackground,
                Parent = page
            })
            addCorner(card, 8)
            addStroke(card, theme.Border, 1)

            createInstance("TextLabel", {
                Name = "Title",
                Size = UDim2.new(0.4, 0, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card
            })

            local boxContainer = createInstance("Frame", {
                Name = "BoxContainer",
                Size = UDim2.new(0.55, 0, 0, 24),
                Position = UDim2.new(0.45, -12, 0.5, -12),
                BackgroundColor3 = theme.Sidebar,
                Parent = card
            })
            addCorner(boxContainer, 6)
            local boxStroke = addStroke(boxContainer, theme.Border, 1)

            local textBox = createInstance("TextBox", {
                Name = "TextBox",
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                BackgroundTransparency = 1,
                Text = currentText,
                PlaceholderText = placeholder,
                PlaceholderColor3 = theme.SubText,
                TextColor3 = theme.Text,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = boxContainer
            })

            textBox.Focused:Connect(function()
                tween(boxStroke, { Color = theme.Accent }, 0.15)
            end)

            textBox.FocusLost:Connect(function(enterPressed)
                tween(boxStroke, { Color = theme.Border }, 0.15)
                local txt = textBox.Text
                if numericOnly then
                    txt = txt:gsub("%D+", "")
                    textBox.Text = txt
                end
                currentText = txt
                if flag then ConfigManager:Set(flag, currentText) end
                pcall(callback, currentText, enterPressed)
            end)

            local InputObj = {}
            InputObj.SetValue = function(_, newText, silent)
                currentText = newText
                textBox.Text = currentText
                if flag then ConfigManager:Set(flag, currentText) end
                if not silent then pcall(callback, currentText, false) end
            end
            InputObj.GetValue = function(_)
                return currentText
            end
            InputObj.Instance = card

            if flag then ConfigManager._elements[flag] = InputObj end

            return InputObj
        end

        -- 9. PARAGRAPH
        function Tab:CreateParagraph(paraConfig)
            paraConfig = paraConfig or {}
            local title = paraConfig.Title or "Information"
            local content = paraConfig.Content or ""
            local icon = IconEngine.GetIcon(paraConfig.Icon or "info")

            local card = createInstance("Frame", {
                Name = "Paragraph_" .. title,
                Size = UDim2.new(1, 0, 0, 58),
                BackgroundColor3 = theme.CardBackground,
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = page
            })
            addCorner(card, 8)
            addStroke(card, theme.Border, 1)
            addPadding(card, 10, 10, 10, 10)

            local textOffset = 0
            if icon then
                createInstance("ImageLabel", {
                    Name = "Icon",
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0, 0, 0, 2),
                    BackgroundTransparency = 1,
                    Image = icon,
                    ImageColor3 = theme.Accent,
                    Parent = card
                })
                textOffset = 24
            end

            local pTitle = createInstance("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -textOffset, 0, 16),
                Position = UDim2.new(0, textOffset, 0, 0),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card
            })

            local pContent = createInstance("TextLabel", {
                Name = "Content",
                Size = UDim2.new(1, -textOffset, 0, 0),
                Position = UDim2.new(0, textOffset, 0, 18),
                BackgroundTransparency = 1,
                Text = content,
                TextColor3 = theme.SubText,
                TextSize = 10,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = card
            })

            return {
                SetContent = function(_, newContent) pContent.Text = newContent end,
                SetTitle = function(_, newTitle) pTitle.Text = newTitle end,
                Instance = card
            }
        end

        -- 10. DIVIDER
        function Tab:CreateDivider(text)
            local divFrame = createInstance("Frame", {
                Name = "Divider",
                Size = UDim2.new(1, 0, 0, text and 20 or 8),
                BackgroundTransparency = 1,
                Parent = page
            })

            if text then
                createInstance("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = theme.SubText,
                    TextSize = 10,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = divFrame
                })
            else
                createInstance("Frame", {
                    Name = "Line",
                    Size = UDim2.new(1, 0, 0, 1),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    BackgroundColor3 = theme.Border,
                    BorderSizePixel = 0,
                    Parent = divFrame
                })
            end

            return divFrame
        end

        return Tab
    end

    -- ==============================================================================
    -- THEME SWITCHER
    -- ==============================================================================
    function Window:SetTheme(nameOrTable)
        local targetTheme = type(nameOrTable) == "string" and Themes[nameOrTable] or nameOrTable
        if not targetTheme then return end

        HoshiUI.ActiveTheme = targetTheme
        mainFrame.BackgroundColor3 = targetTheme.Background
        mainStroke.Color = targetTheme.Border
        topBar.BackgroundColor3 = targetTheme.Sidebar
        topBarCover.BackgroundColor3 = targetTheme.Sidebar
        topBarLine.BackgroundColor3 = targetTheme.Border
        titleLabel.TextColor3 = targetTheme.Text
        subTitleLabel.TextColor3 = targetTheme.SubText
        if topIcon then topIcon.ImageColor3 = targetTheme.Accent end
        sidebar.BackgroundColor3 = targetTheme.Sidebar
        if floatingBtn then
            floatingBtn.BackgroundColor3 = targetTheme.Background
            local fStroke = floatingBtn:FindFirstChildOfClass("UIStroke")
            if fStroke then fStroke.Color = targetTheme.Accent end
            local fIco = floatingBtn:FindFirstChild("Icon")
            if fIco then fIco.ImageColor3 = targetTheme.Accent end
        end
    end

    table.insert(HoshiUI.Windows, Window)
    return Window
end

return HoshiUI
