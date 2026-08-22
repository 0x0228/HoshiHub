-- ==============================================================================
-- HoshiUI Component: Button (Primary, Secondary, Danger Variants)
-- ==============================================================================

local ButtonComponent = {}

function ButtonComponent.New(parent, config, Creator, Icons, theme)
    config = config or {}
    local title = config.Title or "Button"
    local desc = config.Desc or ""
    local icon = config.Icon and Icons.GetIcon(config.Icon) or nil
    local variant = config.Variant or "Secondary" -- "Primary", "Secondary", "Danger"
    local callback = config.Callback or function() end

    local bgColor = theme.CardBackground
    local hoverColor = theme.CardHover
    local strokeColor = theme.Border
    local textColor = theme.Text

    if variant == "Primary" then
        bgColor = theme.Accent
        hoverColor = theme.AccentHover
        strokeColor = theme.AccentHover
        textColor = Color3.fromRGB(255, 255, 255)
    elseif variant == "Danger" then
        bgColor = Color3.fromRGB(180, 40, 50)
        hoverColor = Color3.fromRGB(210, 50, 60)
        strokeColor = Color3.fromRGB(230, 60, 70)
        textColor = Color3.fromRGB(255, 255, 255)
    end

    local btnFrame = Creator.New("TextButton", {
        Name = "Button_" .. title,
        Size = UDim2.new(1, 0, 0, desc ~= "" and 48 or 38),
        BackgroundColor3 = bgColor,
        AutoButtonColor = false,
        Text = "",
        Parent = parent
    })
    Creator.AddCorner(btnFrame, 8)
    local stroke = Creator.AddStroke(btnFrame, strokeColor, 1)

    local contentOffset = 12
    if icon then
        local ico = Creator.New("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 12, 0.5, -9),
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = textColor,
            Parent = btnFrame
        })
        contentOffset = 38
    end

    local titleLabel = Creator.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -contentOffset - 12, 0, desc ~= "" and 20 or 38),
        Position = UDim2.new(0, contentOffset, 0, desc ~= "" and 6 or 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = textColor,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = btnFrame
    })

    if desc ~= "" then
        Creator.New("TextLabel", {
            Name = "Desc",
            Size = UDim2.new(1, -contentOffset - 12, 0, 16),
            Position = UDim2.new(0, contentOffset, 0, 24),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = variant == "Secondary" and theme.SubText or Color3.fromRGB(220, 220, 230),
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = btnFrame
        })
    end

    btnFrame.MouseEnter:Connect(function()
        Creator.Tween(btnFrame, { BackgroundColor3 = hoverColor }, 0.15)
    end)
    btnFrame.MouseLeave:Connect(function()
        Creator.Tween(btnFrame, { BackgroundColor3 = bgColor }, 0.15)
    end)
    btnFrame.MouseButton1Down:Connect(function()
        Creator.Tween(btnFrame, { Size = UDim2.new(1, -4, 0, (desc ~= "" and 48 or 38) - 2) }, 0.08)
    end)
    btnFrame.MouseButton1Up:Connect(function()
        Creator.Tween(btnFrame, { Size = UDim2.new(1, 0, 0, desc ~= "" and 48 or 38) }, 0.08)
    end)
    btnFrame.MouseButton1Click:Connect(function()
        pcall(callback)
    end)

    return {
        Instance = btnFrame,
        SetTitle = function(_, newT) titleLabel.Text = newT end,
        SetCallback = function(_, newCb) callback = newCb end
    }
end

return ButtonComponent
