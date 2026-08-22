-- ==============================================================================
-- HoshiUI Component: Slider (Precision Dragging, Touch Tracking & Format Strings)
-- ==============================================================================

local UserInputService = game:GetService("UserInputService")

local SliderComponent = {}

function SliderComponent.New(parent, config, Creator, ConfigManager, theme)
    config = config or {}
    local title = config.Title or "Slider"
    local desc = config.Desc or ""
    local min = config.Min or 0
    local max = config.Max or 100
    local step = config.Step or 1
    local default = config.Default or min
    local formatStr = config.Format or "{value}"
    local flag = config.Flag
    local callback = config.Callback or function() end

    if flag then
        local saved = ConfigManager:Get(flag)
        if saved ~= nil then
            default = saved
        else
            ConfigManager:Set(flag, default)
        end
    end

    local value = math.clamp(default, min, max)

    local sliderCard = Creator.New("Frame", {
        Name = "Slider_" .. title,
        Size = UDim2.new(1, 0, 0, desc ~= "" and 62 or 52),
        BackgroundColor3 = theme.CardBackground,
        Parent = parent
    })
    Creator.AddCorner(sliderCard, 8)
    Creator.AddStroke(sliderCard, theme.Border, 1)

    local titleLabel = Creator.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -90, 0, 20),
        Position = UDim2.new(0, 14, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = sliderCard
    })

    local valueLabel = Creator.New("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0, 80, 0, 20),
        Position = UDim2.new(1, -94, 0, 8),
        BackgroundTransparency = 1,
        Text = formatStr:gsub("{value}", tostring(value)),
        TextColor3 = theme.Accent,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = sliderCard
    })

    if desc ~= "" then
        Creator.New("TextLabel", {
            Name = "Desc",
            Size = UDim2.new(1, -28, 0, 14),
            Position = UDim2.new(0, 14, 0, 26),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = theme.SubText,
            TextSize = 10,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = sliderCard
        })
    end

    -- Track Bar Container
    local trackPos = desc ~= "" and 44 or 34
    local track = Creator.New("TextButton", {
        Name = "Track",
        Size = UDim2.new(1, -28, 0, 6),
        Position = UDim2.new(0, 14, 0, trackPos),
        BackgroundColor3 = theme.ToggleOff,
        AutoButtonColor = false,
        Text = "",
        Parent = sliderCard
    })
    Creator.AddCorner(track, 3)

    local alpha = (value - min) / (max - min)
    local fill = Creator.New("Frame", {
        Name = "Fill",
        Size = UDim2.new(alpha, 0, 1, 0),
        BackgroundColor3 = theme.Accent,
        Parent = track
    })
    Creator.AddCorner(fill, 3)

    local thumb = Creator.New("Frame", {
        Name = "Thumb",
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(alpha, -7, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = track
    })
    Creator.AddCorner(thumb, 7)

    local function updateValue(newVal, callCallback)
        newVal = math.clamp(newVal, min, max)
        if step > 0 then
            newVal = math.floor((newVal - min) / step + 0.5) * step + min
        end
        value = newVal
        local curAlpha = math.clamp((value - min) / (max - min), 0, 1)

        fill.Size = UDim2.new(curAlpha, 0, 1, 0)
        thumb.Position = UDim2.new(curAlpha, -7, 0.5, -7)
        valueLabel.Text = formatStr:gsub("{value}", tostring(value))

        if flag then
            ConfigManager:Set(flag, value)
        end
        if callCallback ~= false then
            pcall(callback, value)
        end
    end

    local isDragging = false

    local function handleInput(input)
        local absX = track.AbsolutePosition.X
        local absW = track.AbsoluteSize.X
        local inputX = input.Position.X
        local relAlpha = math.clamp((inputX - absX) / absW, 0, 1)
        local calcVal = min + (max - min) * relAlpha
        updateValue(calcVal)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            handleInput(input)
            Creator.Tween(thumb, { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(thumb.Position.X.Scale, -9, 0.5, -9) }, 0.1)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            handleInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isDragging then
                isDragging = false
                local curAlpha = math.clamp((value - min) / (max - min), 0, 1)
                Creator.Tween(thumb, { Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(curAlpha, -7, 0.5, -7) }, 0.1)
            end
        end
    end)

    return {
        Instance = sliderCard,
        Value = value,
        Set = function(_, val) updateValue(val) end,
        SetValue = function(_, val) updateValue(val) end
    }
end

return SliderComponent
