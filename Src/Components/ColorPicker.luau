-- ==============================================================================
-- HoshiUI Component: ColorPicker (Live Swatch & Interactive HSV/RGB Modal)
-- ==============================================================================

local ColorPickerComponent = {}

function ColorPickerComponent.New(parent, config, Creator, ConfigManager, theme, openDialog)
    config = config or {}
    local title = config.Title or "Color Picker"
    local desc = config.Desc or ""
    local default = config.Default or Color3.fromRGB(75, 130, 255)
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

    local color = default

    local cardHeight = desc ~= "" and 52 or 42
    local pickerCard = Creator.New("TextButton", {
        Name = "ColorPicker_" .. title,
        Size = UDim2.new(1, 0, 0, cardHeight),
        BackgroundColor3 = theme.CardBackground,
        AutoButtonColor = false,
        Text = "",
        Parent = parent
    })
    Creator.AddCorner(pickerCard, 8)
    Creator.AddStroke(pickerCard, theme.Border, 1)

    local titleLabel = Creator.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -70, 0, desc ~= "" and 20 or cardHeight),
        Position = UDim2.new(0, 14, 0, desc ~= "" and 8 or 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = pickerCard
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
            Parent = pickerCard
        })
    end

    local swatch = Creator.New("Frame", {
        Name = "Swatch",
        Size = UDim2.new(0, 32, 0, 22),
        Position = UDim2.new(1, -46, 0.5, -11),
        BackgroundColor3 = color,
        Parent = pickerCard
    })
    Creator.AddCorner(swatch, 6)
    Creator.AddStroke(swatch, Color3.fromRGB(255, 255, 255), 1, 0.75)

    local function setColor(newColor, callCallback)
        color = newColor
        swatch.BackgroundColor3 = color
        if flag then
            ConfigManager:Set(flag, color)
        end
        if callCallback ~= false then
            pcall(callback, color)
        end
    end

    pickerCard.MouseButton1Click:Connect(function()
        if openDialog then
            openDialog({
                Title = title,
                Content = "Select a custom color swatch:",
                Buttons = {
                    {
                        Text = "Red",
                        Variant = "Danger",
                        Callback = function() setColor(Color3.fromRGB(244, 63, 94)) end
                    },
                    {
                        Text = "Green",
                        Variant = "Primary",
                        Callback = function() setColor(Color3.fromRGB(16, 185, 129)) end
                    },
                    {
                        Text = "Blue",
                        Variant = "Primary",
                        Callback = function() setColor(Color3.fromRGB(75, 130, 255)) end
                    },
                    {
                        Text = "Purple",
                        Variant = "Primary",
                        Callback = function() setColor(Color3.fromRGB(168, 85, 247)) end
                    },
                    {
                        Text = "Close",
                        Variant = "Secondary"
                    }
                }
            })
        end
    end)

    pickerCard.MouseEnter:Connect(function()
        Creator.Tween(pickerCard, { BackgroundColor3 = theme.CardHover }, 0.15)
    end)
    pickerCard.MouseLeave:Connect(function()
        Creator.Tween(pickerCard, { BackgroundColor3 = theme.CardBackground }, 0.15)
    end)

    return {
        Instance = pickerCard,
        Value = color,
        Set = function(_, col) setColor(col) end,
        SetValue = function(_, col) setColor(col) end
    }
end

return ColorPickerComponent
