-- ==============================================================================
-- HoshiUI Component: Tab & Section Sub-Component Factory
-- ==============================================================================

local ButtonComponent = loadstring and nil -- injected in bundled or modular mode
local ToggleComponent = nil
local SliderComponent = nil
local DropdownComponent = nil
local ColorPickerComponent = nil
local KeybindComponent = nil
local InputComponent = nil

local TabComponent = {}

function TabComponent.New(tabListScroll, contentArea, tabConfig, Window, Creator, Icons, ConfigManager, theme, Components)
    tabConfig = tabConfig or {}
    local tabTitle = tabConfig.Title or "Tab"
    local tabIcon = Icons.GetIcon(tabConfig.Icon or "folder")

    local ButtonMod = Components.Button
    local ToggleMod = Components.Toggle
    local SliderMod = Components.Slider
    local DropdownMod = Components.Dropdown
    local ColorPickerMod = Components.ColorPicker
    local KeybindMod = Components.Keybind
    local InputMod = Components.Input

    local tabBtn = Creator.New("TextButton", {
        Name = "TabBtn_" .. tabTitle,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = theme.Sidebar,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Parent = tabListScroll
    })
    Creator.AddCorner(tabBtn, 8)

    local tabIconImg = Creator.New("ImageLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 10, 0.5, -8),
        BackgroundTransparency = 1,
        Image = tabIcon,
        ImageColor3 = theme.SubText,
        Parent = tabBtn
    })

    local tabLabel = Creator.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 34, 0, 0),
        BackgroundTransparency = 1,
        Text = tabTitle,
        TextColor3 = theme.SubText,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = tabBtn
    })

    local activeBar = Creator.New("Frame", {
        Name = "ActiveBar",
        Size = UDim2.new(0, 3, 0, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = tabBtn
    })
    Creator.AddCorner(activeBar, 2)

    local page = Creator.New("ScrollingFrame", {
        Name = "Page_" .. tabTitle,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = contentArea
    })
    Creator.AddPadding(page, 12, 12, 12, 12)
    Creator.New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = page
    })

    local Tab = {
        Button = tabBtn,
        Page = page,
        Window = Window
    }

    local function activateTab()
        for _, otherTab in pairs(Window.Tabs) do
            otherTab.Page.Visible = false
            Creator.Tween(otherTab.Button, { BackgroundTransparency = 1 }, 0.18)
            local oIco = otherTab.Button:FindFirstChild("Icon")
            if oIco then Creator.Tween(oIco, { ImageColor3 = theme.SubText }, 0.18) end
            local oTitle = otherTab.Button:FindFirstChild("Title")
            if oTitle then Creator.Tween(oTitle, { TextColor3 = theme.SubText }, 0.18) end
            local oBar = otherTab.Button:FindFirstChild("ActiveBar")
            if oBar then Creator.Tween(oBar, { BackgroundTransparency = 1 }, 0.18) end
        end

        page.Visible = true
        Creator.Tween(tabBtn, { BackgroundTransparency = 0.8 }, 0.18)
        Creator.Tween(tabIconImg, { ImageColor3 = theme.Accent }, 0.18)
        Creator.Tween(tabLabel, { TextColor3 = theme.Text }, 0.18)
        Creator.Tween(activeBar, { BackgroundTransparency = 0 }, 0.18)
    end

    tabBtn.MouseButton1Click:Connect(activateTab)

    -- Component Factory Methods
    function Tab:CreateSection(title, desc)
        local secFrame = Creator.New("Frame", {
            Name = "Section_" .. (title or "Sec"),
            Size = UDim2.new(1, 0, 0, desc and 34 or 24),
            BackgroundTransparency = 1,
            Parent = page
        })
        Creator.New("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = (title or "SECTION"):upper(),
            TextColor3 = theme.Accent,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = secFrame
        })
        if desc and desc ~= "" then
            Creator.New("TextLabel", {
                Name = "Desc",
                Size = UDim2.new(1, 0, 0, 14),
                Position = UDim2.new(0, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = desc,
                TextColor3 = theme.SubText,
                TextSize = 10,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = secFrame
            })
        end
        return secFrame
    end

    function Tab:CreateDivider()
        local div = Creator.New("Frame", {
            Name = "Divider",
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = theme.Border,
            BorderSizePixel = 0,
            Parent = page
        })
        return div
    end

    function Tab:CreateParagraph(paraConfig)
        paraConfig = paraConfig or {}
        local pTitle = paraConfig.Title or "Information"
        local pContent = paraConfig.Content or ""
        local pIcon = paraConfig.Icon and Icons.GetIcon(paraConfig.Icon) or Icons.GetIcon("info")

        local pCard = Creator.New("Frame", {
            Name = "Paragraph_" .. pTitle,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = theme.CardBackground,
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = page
        })
        Creator.AddCorner(pCard, 8)
        Creator.AddStroke(pCard, theme.Border, 1)
        Creator.AddPadding(pCard, 10, 10, 12, 12)

        local pLayout = Creator.New("UIListLayout", {
            Padding = UDim.new(0, 4),
            Parent = pCard
        })

        local headerHolder = Creator.New("Frame", {
            Name = "HeaderHolder",
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Parent = pCard
        })

        Creator.New("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 0, 0.5, -8),
            BackgroundTransparency = 1,
            Image = pIcon,
            ImageColor3 = theme.Accent,
            Parent = headerHolder
        })

        Creator.New("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -22, 1, 0),
            Position = UDim2.new(0, 22, 0, 0),
            BackgroundTransparency = 1,
            Text = pTitle,
            TextColor3 = theme.Text,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = headerHolder
        })

        Creator.New("TextLabel", {
            Name = "Content",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = pContent,
            TextColor3 = theme.SubText,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = pCard
        })

        return pCard
    end

    function Tab:CreateButton(btnConfig)
        return ButtonMod.New(page, btnConfig, Creator, Icons, theme)
    end

    function Tab:CreateToggle(toggleConfig)
        return ToggleMod.New(page, toggleConfig, Creator, ConfigManager, theme)
    end

    function Tab:CreateSlider(sliderConfig)
        return SliderMod.New(page, sliderConfig, Creator, ConfigManager, theme)
    end

    function Tab:CreateDropdown(dropdownConfig)
        return DropdownMod.New(page, dropdownConfig, Creator, Icons, ConfigManager, theme)
    end

    function Tab:CreateColorPicker(colorConfig)
        return ColorPickerMod.New(page, colorConfig, Creator, ConfigManager, theme, function(dConfig)
            Window:Dialog(dConfig)
        end)
    end

    function Tab:CreateKeybind(keyConfig)
        return KeybindMod.New(page, keyConfig, Creator, ConfigManager, theme)
    end

    function Tab:CreateInput(inputConfig)
        return InputMod.New(page, inputConfig, Creator, ConfigManager, theme)
    end

    -- First tab is automatically activated
    if #Window.Tabs == 0 then
        task.spawn(activateTab)
    end

    table.insert(Window.Tabs, Tab)
    return Tab
end

return TabComponent
