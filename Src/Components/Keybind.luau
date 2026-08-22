-- ==============================================================================
-- HoshiUI Component: Keybind (Interactive Key Listener & Rebinding System)
-- ==============================================================================

local UserInputService = game:GetService("UserInputService")

local KeybindComponent = {}

function KeybindComponent.New(parent, config, Creator, ConfigManager, theme)
    config = config or {}
    local title = config.Title or "Keybind"
    local desc = config.Desc or ""
    local default = config.Default or Enum.KeyCode.E
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

    local key = default
    local isListening = false

    local cardHeight = desc ~= "" and 52 or 42
    local keybindCard = Creator.New("TextButton", {
        Name = "Keybind_" .. title,
        Size = UDim2.new(1, 0, 0, cardHeight),
        BackgroundColor3 = theme.CardBackground,
        AutoButtonColor = false,
        Text = "",
        Parent = parent
    })
    Creator.AddCorner(keybindCard, 8)
    Creator.AddStroke(keybindCard, theme.Border, 1)

    local titleLabel = Creator.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -90, 0, desc ~= "" and 20 or cardHeight),
        Position = UDim2.new(0, 14, 0, desc ~= "" and 8 or 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = keybindCard
    })

    if desc ~= "" then
        Creator.New("TextLabel", {
            Name = "Desc",
            Size = UDim2.new(1, -90, 0, 16),
            Position = UDim2.new(0, 14, 0, 28),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = theme.SubText,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = keybindCard
        })
    end

    local function getKeyName(k)
        if typeof(k) == "EnumItem" then
            return k.Name
        end
        return tostring(k or "None")
    end

    local badge = Creator.New("Frame", {
        Name = "Badge",
        Size = UDim2.new(0, 64, 0, 24),
        Position = UDim2.new(1, -78, 0.5, -12),
        BackgroundColor3 = theme.Background,
        Parent = keybindCard
    })
    Creator.AddCorner(badge, 6)
    local badgeStroke = Creator.AddStroke(badge, theme.Border, 1)

    local keyLabel = Creator.New("TextLabel", {
        Name = "KeyText",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = getKeyName(key),
        TextColor3 = theme.Accent,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Parent = badge
    })

    local function setKey(newKey, callCallback)
        key = newKey
        keyLabel.Text = getKeyName(key)
        if flag then
            ConfigManager:Set(flag, key)
        end
        if callCallback ~= false then
            pcall(callback, key)
        end
    end

    keybindCard.MouseButton1Click:Connect(function()
        if isListening then return end
        isListening = true
        keyLabel.Text = "..."
        badgeStroke.Color = theme.Accent

        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gpe)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                connection:Disconnect()
                isListening = false
                badgeStroke.Color = theme.Border
                if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.Escape then
                    setKey(input.KeyCode)
                else
                    keyLabel.Text = getKeyName(key)
                end
            end
        end)
    end)

    Creator.AddSignal(UserInputService.InputBegan, function(input, gpe)
        if gpe or isListening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key then
            pcall(callback)
        end
    end)

    keybindCard.MouseEnter:Connect(function()
        Creator.Tween(keybindCard, { BackgroundColor3 = theme.CardHover }, 0.15)
    end)
    keybindCard.MouseLeave:Connect(function()
        Creator.Tween(keybindCard, { BackgroundColor3 = theme.CardBackground }, 0.15)
    end)

    return {
        Instance = keybindCard,
        Value = key,
        Set = function(_, k) setKey(k) end,
        SetValue = function(_, k) setKey(k) end
    }
end

return KeybindComponent
