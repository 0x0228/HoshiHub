-- ==============================================================================
-- HoshiUI Component: Input (Text & Numeric Filtering with Focus States)
-- ==============================================================================

local InputComponent = {}

function InputComponent.New(parent, config, Creator, ConfigManager, theme)
    config = config or {}
    local title = config.Title or "Input"
    local desc = config.Desc or ""
    local placeholder = config.Placeholder or "Enter text..."
    local default = config.Default or ""
    local numericOnly = config.NumericOnly or false
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

    local text = tostring(default)

    local cardHeight = desc ~= "" and 58 or 46
    local inputCard = Creator.New("Frame", {
        Name = "Input_" .. title,
        Size = UDim2.new(1, 0, 0, cardHeight),
        BackgroundColor3 = theme.CardBackground,
        Parent = parent
    })
    Creator.AddCorner(inputCard, 8)
    Creator.AddStroke(inputCard, theme.Border, 1)

    local titleLabel = Creator.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -160, 0, desc ~= "" and 20 or cardHeight),
        Position = UDim2.new(0, 14, 0, desc ~= "" and 8 or 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = inputCard
    })

    if desc ~= "" then
        Creator.New("TextLabel", {
            Name = "Desc",
            Size = UDim2.new(1, -160, 0, 16),
            Position = UDim2.new(0, 14, 0, 28),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = theme.SubText,
            TextSize = 10,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = inputCard
        })
    end

    local boxContainer = Creator.New("Frame", {
        Name = "BoxContainer",
        Size = UDim2.new(0, 140, 0, 28),
        Position = UDim2.new(1, -154, 0.5, -14),
        BackgroundColor3 = theme.Background,
        Parent = inputCard
    })
    Creator.AddCorner(boxContainer, 6)
    local boxStroke = Creator.AddStroke(boxContainer, theme.Border, 1)

    local textBox = Creator.New("TextBox", {
        Name = "TextBox",
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        PlaceholderText = placeholder,
        TextColor3 = theme.Text,
        PlaceholderColor3 = theme.SubText,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = boxContainer
    })

    local function setText(newText, callCallback, enterPressed)
        if numericOnly then
            newText = newText:gsub("%D+", "")
        end
        text = newText
        textBox.Text = text

        if flag then
            ConfigManager:Set(flag, text)
        end
        if callCallback ~= false then
            pcall(callback, text, enterPressed)
        end
    end

    textBox.Focused:Connect(function()
        Creator.Tween(boxStroke, { Color = theme.Accent }, 0.15)
    end)

    textBox.FocusLost:Connect(function(enterPressed)
        Creator.Tween(boxStroke, { Color = theme.Border }, 0.15)
        setText(textBox.Text, true, enterPressed)
    end)

    if numericOnly then
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            local clean = textBox.Text:gsub("%D+", "")
            if clean ~= textBox.Text then
                textBox.Text = clean
            end
        end)
    end

    return {
        Instance = inputCard,
        Value = text,
        Set = function(_, t) setText(t) end,
        SetValue = function(_, t) setText(t) end
    }
end

return InputComponent
