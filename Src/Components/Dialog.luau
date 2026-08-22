-- ==============================================================================
-- HoshiUI Component: Dialog (Centered Modal Overlay & Dynamic Action Buttons)
-- ==============================================================================

local DialogComponent = {}

function DialogComponent.Open(screenGui, dialogConfig, Creator, theme)
    dialogConfig = dialogConfig or {}
    local title = dialogConfig.Title or "Dialog"
    local content = dialogConfig.Content or ""
    local buttons = dialogConfig.Buttons or { { Text = "OK", Variant = "Primary" } }

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

    local dialogBox = Creator.New("Frame", {
        Name = "DialogBox",
        Size = UDim2.new(0, 360, 0, 170),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.CardBackground,
        ZIndex = 101,
        Parent = modalOverlay
    })
    Creator.AddCorner(dialogBox, 10)
    Creator.AddStroke(dialogBox, theme.Border, 1)

    local dScale = Creator.New("UIScale", {
        Scale = 0.85,
        Parent = dialogBox
    })

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
        Padding = UDim.new(0, 8),
        Parent = btnContainer
    })

    local function closeDialog()
        Creator.Tween(modalOverlay, { BackgroundTransparency = 1 }, 0.15)
        local anim = Creator.Tween(dScale, { Scale = 0.85 }, 0.15, Enum.EasingStyle.Sine)
        if anim then
            anim.Completed:Connect(function()
                modalOverlay:Destroy()
            end)
        else
            modalOverlay:Destroy()
        end
    end

    for _, btnData in ipairs(buttons) do
        local bVariant = btnData.Variant or "Secondary"
        local bBg = theme.Background
        local bText = theme.Text

        if bVariant == "Primary" then
            bBg = theme.Accent
            bText = Color3.fromRGB(255, 255, 255)
        elseif bVariant == "Danger" then
            bBg = theme.Danger
            bText = Color3.fromRGB(255, 255, 255)
        end

        local dBtn = Creator.New("TextButton", {
            Name = "Btn_" .. (btnData.Text or "Action"),
            Size = UDim2.new(0, 90, 1, 0),
            BackgroundColor3 = bBg,
            AutoButtonColor = false,
            Text = btnData.Text or "Action",
            TextColor3 = bText,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            ZIndex = 103,
            Parent = btnContainer
        })
        Creator.AddCorner(dBtn, 6)

        dBtn.MouseButton1Click:Connect(function()
            closeDialog()
            if btnData.Callback then
                pcall(btnData.Callback)
            end
        end)
    end

    Creator.Tween(modalOverlay, { BackgroundTransparency = 0.5 }, 0.2)
    Creator.Tween(dScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back)
end

return DialogComponent
