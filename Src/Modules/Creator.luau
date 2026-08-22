-- ==============================================================================
-- HoshiUI — Creator Engine (Factory, Spring Physics, Theme Reactive Bindings)
-- ==============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Creator = {
    ThemeTags = {},
    Signals = {},
    ActiveTheme = nil,
    ActiveThemeName = "Dark",
}

function Creator.GetSafeGuiParent()
    local success, hui = pcall(function()
        return (gethui or get_hidden_ui)()
    end)
    if success and hui then return hui end

    local cSuccess, coregui = pcall(function()
        return CoreGui
    end)
    if cSuccess and coregui then return coregui end

    return LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("StarterGui")
end

function Creator.New(className, properties, children)
    local instance = Instance.new(className)
    properties = properties or {}
    children = children or {}

    local themeTag = properties.ThemeTag
    properties.ThemeTag = nil

    for prop, val in pairs(properties) do
        pcall(function()
            instance[prop] = val
        end)
    end

    for _, child in ipairs(children) do
        if typeof(child) == "Instance" then
            child.Parent = instance
        end
    end

    if themeTag and type(themeTag) == "table" then
        Creator.ThemeTags[instance] = themeTag
        if Creator.ActiveTheme then
            Creator.ApplyThemeTag(instance, themeTag, Creator.ActiveTheme)
        end
    end

    return instance
end

function Creator.AddCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
    return corner
end

function Creator.AddStroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = color or Color3.fromRGB(40, 44, 58)
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
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

function Creator.AddSignal(rbxSignal, fn)
    local connection = rbxSignal:Connect(fn)
    table.insert(Creator.Signals, connection)
    return connection
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

function Creator.MakeDraggable(dragBar, mainFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    Creator.AddSignal(dragBar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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

function Creator.ApplyThemeTag(instance, themeTag, theme)
    for prop, themeKey in pairs(themeTag) do
        if theme[themeKey] then
            pcall(function()
                instance[prop] = theme[themeKey]
            end)
        end
    end
end

function Creator.UpdateTheme(newTheme, newThemeName)
    Creator.ActiveTheme = newTheme
    Creator.ActiveThemeName = newThemeName
    for inst, tag in pairs(Creator.ThemeTags) do
        if inst and inst.Parent then
            Creator.ApplyThemeTag(inst, tag, newTheme)
        else
            Creator.ThemeTags[inst] = nil
        end
    end
end

return Creator
