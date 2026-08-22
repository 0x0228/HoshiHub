-- ==============================================================================
-- HoshiUI Component: Dropdown (Single & Multi-Selection, Animated Expand)
-- ==============================================================================

local DropdownComponent = {}

function DropdownComponent.New(parent, config, Creator, Icons, ConfigManager, theme)
    config = config or {}
    local title = config.Title or "Dropdown"
    local desc = config.Desc or ""
    local options = config.Options or {}
    local isMulti = config.Multi or false
    local default = config.Default or (isMulti and {} or options[1] or "")
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

    local selected = default
    local isOpen = false

    local cardHeight = desc ~= "" and 60 or 44
    local dropdownCard = Creator.New("Frame", {
        Name = "Dropdown_" .. title,
        Size = UDim2.new(1, 0, 0, cardHeight),
        BackgroundColor3 = theme.CardBackground,
        ClipsDescendants = true,
        Parent = parent
    })
    Creator.AddCorner(dropdownCard, 8)
    local stroke = Creator.AddStroke(dropdownCard, theme.Border, 1)

    local headerBtn = Creator.New("TextButton", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, cardHeight),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Parent = dropdownCard
    })

    local titleLabel = Creator.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -180, 0, desc ~= "" and 20 or cardHeight),
        Position = UDim2.new(0, 14, 0, desc ~= "" and 8 or 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = headerBtn
    })

    if desc ~= "" then
        Creator.New("TextLabel", {
            Name = "Desc",
            Size = UDim2.new(1, -180, 0, 16),
            Position = UDim2.new(0, 14, 0, 28),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = theme.SubText,
            TextSize = 10,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = headerBtn
        })
    end

    local selectedBadge = Creator.New("Frame", {
        Name = "Badge",
        Size = UDim2.new(0, 140, 0, 28),
        Position = UDim2.new(1, -154, 0.5, -14),
        BackgroundColor3 = theme.Background,
        Parent = headerBtn
    })
    Creator.AddCorner(selectedBadge, 6)
    Creator.AddStroke(selectedBadge, theme.Border, 1)

    local function getSelectedText()
        if isMulti then
            if type(selected) == "table" and #selected > 0 then
                return table.concat(selected, ", ")
            end
            return "None selected"
        end
        return tostring(selected or "Select...")
    end

    local selectedLabel = Creator.New("TextLabel", {
        Name = "SelectedText",
        Size = UDim2.new(1, -28, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = getSelectedText(),
        TextColor3 = theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = selectedBadge
    })

    local chevron = Creator.New("ImageLabel", {
        Name = "Chevron",
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(1, -18, 0.5, -6),
        BackgroundTransparency = 1,
        Image = Icons.GetIcon("chevron-down"),
        ImageColor3 = theme.SubText,
        Parent = selectedBadge
    })

    -- Options List Container
    local listContainer = Creator.New("Frame", {
        Name = "List",
        Size = UDim2.new(1, -28, 0, 0),
        Position = UDim2.new(0, 14, 0, cardHeight + 4),
        BackgroundTransparency = 1,
        Parent = dropdownCard
    })
    local listLayout = Creator.New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = listContainer
    })

    local optionButtons = {}

    local function updateSelection(newVal, callCallback)
        selected = newVal
        selectedLabel.Text = getSelectedText()

        for optName, btnData in pairs(optionButtons) do
            local isSel = false
            if isMulti then
                isSel = (type(selected) == "table" and table.find(selected, optName) ~= nil)
            else
                isSel = (selected == optName)
            end

            btnData.Indicator.Visible = isSel
            btnData.Label.TextColor3 = isSel and theme.Accent or theme.Text
            Creator.Tween(btnData.Button, { BackgroundColor3 = isSel and theme.Background or theme.CardHover }, 0.15)
        end

        if flag then
            ConfigManager:Set(flag, selected)
        end
        if callCallback ~= false then
            pcall(callback, selected)
        end
    end

    local function refreshOptions(newOptions)
        options = newOptions or {}
        for _, child in ipairs(listContainer:GetChildren()) do
            if child:IsA("GuiObject") and child ~= listLayout then
                child:Destroy()
            end
        end
        optionButtons = {}

        for _, opt in ipairs(options) do
            local optBtn = Creator.New("TextButton", {
                Name = "Option_" .. opt,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = theme.CardHover,
                AutoButtonColor = false,
                Text = "",
                Parent = listContainer
            })
            Creator.AddCorner(optBtn, 6)

            local optLabel = Creator.New("TextLabel", {
                Name = "Label",
                Size = UDim2.new(1, -30, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = opt,
                TextColor3 = theme.Text,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = optBtn
            })

            local checkIco = Creator.New("ImageLabel", {
                Name = "Check",
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(1, -22, 0.5, -7),
                BackgroundTransparency = 1,
                Image = Icons.GetIcon("check"),
                ImageColor3 = theme.Accent,
                Visible = false,
                Parent = optBtn
            })

            optionButtons[opt] = {
                Button = optBtn,
                Label = optLabel,
                Indicator = checkIco
            }

            optBtn.MouseButton1Click:Connect(function()
                if isMulti then
                    local curTable = type(selected) == "table" and selected or {}
                    local existingIdx = table.find(curTable, opt)
                    if existingIdx then
                        table.remove(curTable, existingIdx)
                    else
                        table.insert(curTable, opt)
                    end
                    updateSelection(curTable)
                else
                    updateSelection(opt)
                    -- Auto collapse on single select
                    isOpen = false
                    Creator.Tween(chevron, { Rotation = 0 }, 0.2)
                    Creator.Tween(dropdownCard, { Size = UDim2.new(1, 0, 0, cardHeight) }, 0.2)
                end
            end)
        end
        updateSelection(selected, false)
    end

    refreshOptions(options)

    local function toggleDropdown()
        isOpen = not isOpen
        local targetHeight = cardHeight
        if isOpen then
            local listH = (#options * 34) + 10
            targetHeight = cardHeight + listH
            Creator.Tween(chevron, { Rotation = 180 }, 0.2)
        else
            Creator.Tween(chevron, { Rotation = 0 }, 0.2)
        end
        Creator.Tween(dropdownCard, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.22)
    end

    headerBtn.MouseButton1Click:Connect(toggleDropdown)

    return {
        Instance = dropdownCard,
        Value = selected,
        Set = function(_, val) updateSelection(val) end,
        SetOptions = function(_, newOpts) refreshOptions(newOpts) end
    }
end

return DropdownComponent
