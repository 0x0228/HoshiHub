-- ==============================================================================
-- HoshiUI Component: Notification (Bottom-Right Stacking Toasts & Progress Bars)
-- ==============================================================================

local NotificationManager = {}

function NotificationManager.Init(screenGui, Creator)
    local holder = Creator.New("Frame", {
        Name = "NotificationHolder",
        Size = UDim2.new(0, 300, 1, -40),
        Position = UDim2.new(1, -320, 0, 20),
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

function NotificationManager.Notify(holder, notifConfig, Creator, Icons, theme)
    notifConfig = notifConfig or {}
    local title = notifConfig.Title or "Notification"
    local content = notifConfig.Content or ""
    local notifType = notifConfig.Type or "Info" -- "Info", "Success", "Warning", "Danger"
    local duration = notifConfig.Duration or 3.5
    local icon = notifConfig.Icon and Icons.GetIcon(notifConfig.Icon) or Icons.GetIcon("bell")

    local typeColor = theme.Accent
    if notifType == "Success" then typeColor = theme.Success
    elseif notifType == "Warning" then typeColor = theme.Warning
    elseif notifType == "Danger" then typeColor = theme.Danger end

    local notifFrame = Creator.New("Frame", {
        Name = "Toast",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.CardBackground,
        ClipsDescendants = true,
        Parent = holder
    })
    Creator.AddCorner(notifFrame, 8)
    Creator.AddStroke(notifFrame, theme.Border, 1)

    local sideBar = Creator.New("Frame", {
        Name = "SideBar",
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = typeColor,
        Parent = notifFrame
    })

    local iconLabel = Creator.New("ImageLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundTransparency = 1,
        Image = icon,
        ImageColor3 = typeColor,
        Parent = notifFrame
    })

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
        Parent = notifFrame
    })

    -- Progress Bar
    local progressBar = Creator.New("Frame", {
        Name = "Progress",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = typeColor,
        Parent = notifFrame
    })

    -- Animate Open
    task.spawn(function()
        task.wait(0.02)
        local targetH = math.max(60, descLabel.TextBounds.Y + 44)
        Creator.Tween(notifFrame, { Size = UDim2.new(1, 0, 0, targetH) }, 0.22, Enum.EasingStyle.Back)
        Creator.Tween(progressBar, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

        task.wait(duration)
        local closeAnim = Creator.Tween(notifFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.2, Enum.EasingStyle.Sine)
        if closeAnim then
            closeAnim.Completed:Connect(function()
                notifFrame:Destroy()
            end)
        else
            notifFrame:Destroy()
        end
    end)
end

return NotificationManager
