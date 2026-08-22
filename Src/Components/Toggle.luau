-- ==============================================================================
-- HoshiUI Component: Toggle (Spring Physics Switch Pill & Flag Persistence)
-- ==============================================================================

local ToggleComponent = {}

function ToggleComponent.New(parent, config, Creator, ConfigManager, theme)
    config = config or {}
    local title = config.Title or "Toggle"
    local desc = config.Desc or ""
    local flag = config.Flag
    local default = config.Default or false
    local callback = config.Callback or function() end

    if flag then
        local saved = ConfigManager:Get(flag)
        if saved ~= nil then
            default = saved
        else
            ConfigManager:Set(flag, default)
        end
    end

    local state = default

    local toggleCard = Creator.New("TextButton", {
        Name = "Toggle_" .. title,
        Size = UDim2.new(1, 0, 0, desc ~= "" and 52 or 42),
        BackgroundColor3 = theme.CardBackground,
        AutoButtonColor = false,
        Text = "",
        Parent = parent
    })
    Creator.AddCorner(toggleCard, 8)
    Creator.AddStroke(toggleCard, theme.Border, 1)

    local titleLabel = Creator.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -70, 0, desc ~= "" and 20 or 42),
        Position = UDim2.new(0, 14, 0, desc ~= "" and 8 or 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = toggleCard
    })

    if desc ~= "" then
        Creator.New("TextLabel", {
            Name = "Desc",
            Size = UDim2.new(1, -70, 0, 16),
            Position = UDim2.new(0, 14, 0, 28),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = theme.SubText,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = toggleCard
        })
    end

    -- Switch Pill Container
    local pill = Creator.New("Frame", {
        Name = "Pill",
        Size = UDim2.new(0, 40, 0, 22),
        Position = UDim2.new(1, -54, 0.5, -11),
        BackgroundColor3 = state and theme.Accent or theme.ToggleOff,
        Parent = toggleCard
    })
    Creator.AddCorner(pill, 11)

    local knob = Creator.New("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = pill
    })
    Creator.AddCorner(knob, 8)

    local function updateVisual(newState)
        if newState then
            Creator.Tween(pill, { BackgroundColor3 = theme.Accent }, 0.2)
            Creator.Tween(knob, { Position = UDim2.new(1, -19, 0.5, -8) }, 0.2, Enum.EasingStyle.Back)
        else
            Creator.Tween(pill, { BackgroundColor3 = theme.ToggleOff }, 0.2)
            Creator.Tween(knob, { Position = UDim2.new(0, 3, 0.5, -8) }, 0.2, Enum.EasingStyle.Back)
        end
    end

    local function setState(newState, callCallback)
        state = newState
        updateVisual(state)
        if flag then
            ConfigManager:Set(flag, state)
        end
        if callCallback ~= false then
            pcall(callback, state)
        end
    end

    toggleCard.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    toggleCard.MouseEnter:Connect(function()
        Creator.Tween(toggleCard, { BackgroundColor3 = theme.CardHover }, 0.15)
    end)
    toggleCard.MouseLeave:Connect(function()
        Creator.Tween(toggleCard, { BackgroundColor3 = theme.CardBackground }, 0.15)
    end)

    return {
        Instance = toggleCard,
        Value = state,
        Set = function(_, val) setState(val) end,
        SetValue = function(_, val) setState(val) end
    }
end

return ToggleComponent
