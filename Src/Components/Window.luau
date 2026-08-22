-- ==============================================================================
-- HoshiUI Component: Window (Centered Layout, Draggable Topbar, Floating Button)
-- ==============================================================================

local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local WindowComponent = {}

function WindowComponent.New(config, HoshiUI, Modules, Packages, Components)
    config = config or {}
    local Creator = Modules.Creator
    local Icons = Modules.Icons
    local ConfigManager = Modules.ConfigManager
    local Themes = Modules.Themes
    local Notification = Components.Notification
    local Dialog = Components.Dialog
    local TabComponent = Components.Tab

    local windowTitle = config.Title or "Hoshi Hub"
    local windowSubTitle = config.SubTitle or "v2.0"
    local themeName = config.Theme or "Dark"
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightControl
    local hasFloating = config.FloatingButton or false
    local configFolder = config.Folder or "HoshiHub"
    local configFile = config.ConfigFile or "Config.json"
    local autoSave = (config.AutoSave ~= false)

    -- Hot reload clean up
    if getgenv then
        local active = getgenv().HoshiHub_ActiveWindow
        if active and active.Destroy then
            pcall(active.Destroy, active)
        end
    end

    local safeParent = Creator.GetSafeGuiParent()
    local existingGui = safeParent:FindFirstChild("HoshiUI_Root")
    if existingGui then
        pcall(existingGui.Destroy, existingGui)
    end

    local theme = Themes[themeName] or Themes["Dark"]
    Creator.ActiveTheme = theme
    Creator.ActiveThemeName = themeName

    local viewport = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
    local defaultW = math.min(config.Size and config.Size.X.Offset or 680, viewport.X - 24)
    local defaultH = math.min(config.Size and config.Size.Y.Offset or 440, viewport.Y - 30)
    local windowSize = UDim2.new(0, defaultW, 0, defaultH)

    ConfigManager:Init(configFolder, configFile, autoSave)

    local screenGui = Creator.New("ScreenGui", {
        Name = "HoshiUI_Root",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = safeParent
    })

    local notifHolder = Notification.Init(screenGui, Creator)

    local mainFrame = Creator.New("Frame", {
        Name = "MainFrame",
        Size = windowSize,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Background,
        ClipsDescendants = false,
        Parent = screenGui
    })
    Creator.AddCorner(mainFrame, 12)
    local mainStroke = Creator.AddStroke(mainFrame, theme.Border, 1)

    local uiScale = Creator.New("UIScale", {
        Scale = 1,
        Parent = mainFrame
    })

    -- Drop Shadow
    Creator.New("ImageLabel", {
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

    -- Top Header Bar
    local topBar = Creator.New("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 1,
        Parent = mainFrame
    })

    local headerIcon = Icons.GetIcon(config.Icon or "sparkles")
    Creator.New("ImageLabel", {
        Name = "HeaderIcon",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0, 14, 0.5, -11),
        BackgroundTransparency = 1,
        Image = headerIcon,
        ImageColor3 = theme.Accent,
        Parent = topBar
    })

    local titleContainer = Creator.New("Frame", {
        Name = "TitleContainer",
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(0, 42, 0, 0),
        BackgroundTransparency = 1,
        Parent = topBar
    })

    Creator.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0, 6),
        BackgroundTransparency = 1,
        Text = windowTitle,
        TextColor3 = theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleContainer
    })

    Creator.New("TextLabel", {
        Name = "SubTitle",
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundTransparency = 1,
        Text = windowSubTitle,
        TextColor3 = theme.SubText,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleContainer
    })

    -- Topbar Control Buttons (Minimize & Close)
    local actionsContainer = Creator.New("Frame", {
        Name = "Actions",
        Size = UDim2.new(0, 75, 1, 0),
        Position = UDim2.new(1, -12, 0, 0),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Parent = topBar
    })
    Creator.New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = actionsContainer
    })

    local function createTopBarButton(name, iconId, hoverColor, onClick)
        local btn = Creator.New("ImageButton", {
            Name = name,
            Size = UDim2.new(0, 28, 0, 28),
            BackgroundColor3 = theme.CardBackground,
            AutoButtonColor = false,
            Parent = actionsContainer
        })
        Creator.AddCorner(btn, 6)
        Creator.AddStroke(btn, theme.Border, 1)

        local ico = Creator.New("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0.5, -7, 0.5, -7),
            BackgroundTransparency = 1,
            Image = Icons.GetIcon(iconId) or iconId,
            ImageColor3 = theme.SubText,
            Parent = btn
        })

        btn.MouseEnter:Connect(function()
            Creator.Tween(btn, { BackgroundColor3 = hoverColor or theme.CardHover }, 0.15)
            Creator.Tween(ico, { ImageColor3 = theme.Text }, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            Creator.Tween(btn, { BackgroundColor3 = theme.CardBackground }, 0.15)
            Creator.Tween(ico, { ImageColor3 = theme.SubText }, 0.15)
        end)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    local isMinimized = false
    local originalSize = windowSize
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
            Creator.Tween(uiScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back)
        else
            local anim = Creator.Tween(uiScale, { Scale = 0.88 }, 0.15, Enum.EasingStyle.Sine)
            if anim then
                anim.Completed:Connect(function()
                    if not isVisible then mainFrame.Visible = false end
                end)
            else
                mainFrame.Visible = false
            end
        end
    end

    createTopBarButton("Minimize", "chevron-up", theme.CardHover, function()
        isMinimized = not isMinimized
        if isMinimized then
            Creator.Tween(mainFrame, { Size = UDim2.new(0, defaultW, 0, 48) }, 0.22)
        else
            Creator.Tween(mainFrame, { Size = originalSize }, 0.22)
        end
    end)

    createTopBarButton("Close", "x", Color3.fromRGB(180, 40, 50), function()
        toggleWindow(false)
    end)

    Creator.MakeDraggable(topBar, mainFrame)

    -- Body Container
    local body = Creator.New("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -48),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = mainFrame
    })

    -- Left Sidebar
    local sidebar = Creator.New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 175, 1, 0),
        BackgroundColor3 = theme.Sidebar,
        Parent = body
    })
    Creator.AddCorner(sidebar, 8)
    Creator.AddStroke(sidebar, theme.Border, 1)

    local tabListScroll = Creator.New("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = sidebar
    })
    Creator.AddPadding(tabListScroll, 8, 8, 8, 8)
    Creator.New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = tabListScroll
    })

    -- Right Content Area
    local contentArea = Creator.New("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -183, 1, 0),
        Position = UDim2.new(0, 183, 0, 0),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 1,
        Parent = body
    })

    -- Draggable Floating Action Button
    local floatingBtn = nil
    if hasFloating then
        floatingBtn = Creator.New("ImageButton", {
            Name = "FloatingToggle",
            Size = UDim2.new(0, 44, 0, 44),
            Position = UDim2.new(0, 24, 0.5, -22),
            BackgroundColor3 = theme.Background,
            AutoButtonColor = false,
            Parent = screenGui
        })
        Creator.AddCorner(floatingBtn, 22)
        Creator.AddStroke(floatingBtn, theme.Accent, 1.5)

        local floatingIco = Icons.GetIcon(config.FloatingIcon or config.Icon or "sparkles")
        Creator.New("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0.5, -10, 0.5, -10),
            BackgroundTransparency = 1,
            Image = floatingIco,
            ImageColor3 = theme.Accent,
            Parent = floatingBtn
        })

        Creator.MakeDraggable(floatingBtn, floatingBtn)
        floatingBtn.MouseButton1Click:Connect(function()
            toggleWindow()
        end)
    end

    -- Toggle Key Listener
    Creator.AddSignal(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            toggleWindow()
        end
    end)

    local Window = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        Tabs = {},
        ConfigManager = ConfigManager,
        Themes = Themes,
        ActiveTheme = theme,
        ActiveThemeName = themeName,
    }

    if getgenv then
        getgenv().HoshiHub_ActiveWindow = Window
    end

    function Window:CreateTab(tabConfig)
        return TabComponent.New(tabListScroll, contentArea, tabConfig, Window, Creator, Icons, ConfigManager, theme, Components)
    end

    function Window:AddTab(tabConfig)
        return self:CreateTab(tabConfig)
    end

    function Window:Notify(notifConfig)
        Notification.Notify(notifHolder, notifConfig, Creator, Icons, theme)
    end

    function Window:Dialog(dialogConfig)
        Dialog.Open(screenGui, dialogConfig, Creator, theme)
    end

    function Window:SetFloatingVisible(visible)
        if floatingBtn then floatingBtn.Visible = visible end
    end

    function Window:Toggle()
        toggleWindow()
    end

    function Window:SetTheme(newThemeName)
        local targetTheme = Themes[newThemeName]
        if not targetTheme then return end

        theme = targetTheme
        self.ActiveTheme = targetTheme
        self.ActiveThemeName = newThemeName
        Creator.UpdateTheme(targetTheme, newThemeName)

        mainFrame.BackgroundColor3 = targetTheme.Background
        mainStroke.Color = targetTheme.Border
        sidebar.BackgroundColor3 = targetTheme.Sidebar
        if floatingBtn then
            floatingBtn.BackgroundColor3 = targetTheme.Background
            local fStroke = floatingBtn:FindFirstChildOfClass("UIStroke")
            if fStroke then fStroke.Color = targetTheme.Accent end
            local fIco = floatingBtn:FindFirstChild("Icon")
            if fIco then fIco.ImageColor3 = targetTheme.Accent end
        end
    end

    function Window:Destroy()
        Creator.Disconnect()
        screenGui:Destroy()
    end

    return Window
end

return WindowComponent
