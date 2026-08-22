-- ==============================================================================
-- HoshiHub — Official Multi-Game Script Loader & Authentication Gateway
-- Cosmic Aesthetic • Saturn Emblem • Password & Game Dispatcher
-- Repository: 0x0228/HoshiHub
-- ==============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local MarketPlaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local GameId = game.GameId

-- ==============================================================================
-- 1. LOADER CONFIGURATION
-- ==============================================================================
local LoaderConfig = {
    HubTitle = "Hoshi Hub",
    HubSubTitle = "Cosmic Script Suite • Access Gateway",
    LogoAssetId = "95445676600352",
    DiscordLink = "https://discord.gg/hoshihub",
    Password = "0228",             -- Current authentication password
    SaveAuth = true,               -- Remember key on local disk
    AuthFolder = "HoshiHub",
    AuthFile = "Auth.json",
    GitHubRaw = "https://raw.githubusercontent.com/0x0228/HoshiHub/master",
}

-- Game Mapping Table (PlaceId -> Script Path)
local GameTable = {
    [126463495082631] = {
        Name = "Pantai Voice Chat",
        Script = "UI/Example.lua", -- Can be routed to Experiences/PantaiVoiceChat.lua
    },
    ["Universal"] = {
        Name = "Universal Feature Showcase",
        Script = "UI/Example.lua",
    }
}

-- ==============================================================================
-- 2. COSMIC PALETTE
-- ==============================================================================
local Theme = {
    Background = Color3.fromRGB(15, 20, 29),       -- Deep cosmic navy
    Card = Color3.fromRGB(24, 32, 45),             -- Starry slate container
    CardHover = Color3.fromRGB(33, 44, 61),        -- Celestial luminous hover
    Border = Color3.fromRGB(48, 64, 88),           -- Twilight border
    Accent = Color3.fromRGB(247, 230, 185),        -- Cosmic champagne gold
    AccentHover = Color3.fromRGB(255, 243, 212),   -- Luminous starlight shine
    Text = Color3.fromRGB(250, 248, 244),          -- Celestial ivory
    SubText = Color3.fromRGB(156, 178, 198),       -- Muted twilight blue-gray
    Success = Color3.fromRGB(120, 215, 175),       -- Aurora mint
    Danger = Color3.fromRGB(245, 100, 120),        -- Supernova red
    InputBg = Color3.fromRGB(18, 24, 34),          -- Deep inset background
}

-- Safe Parent Resolver
local function getSafeGuiParent()
    local success, hui = pcall(function() return (gethui or get_hidden_ui)() end)
    if success and hui then return hui end
    local cSuccess, coregui = pcall(function() return CoreGui end)
    if cSuccess and coregui then return coregui end
    return LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("StarterGui")
end

-- Close Existing Loader
local safeParent = getSafeGuiParent()
local existing = safeParent:FindFirstChild("HoshiHub_Loader")
if existing then pcall(existing.Destroy, existing) end

-- Detect Game Name
local detectedGameName = "Universal Game"
local targetScript = GameTable["Universal"].Script

if GameTable[PlaceId] then
    detectedGameName = GameTable[PlaceId].Name
    targetScript = GameTable[PlaceId].Script
else
    local s, info = pcall(function() return MarketPlaceService:GetProductInfo(PlaceId) end)
    if s and info and info.Name then
        detectedGameName = info.Name
    end
end

-- ==============================================================================
-- 3. LOCAL ASSET CACHING ENGINE
-- ==============================================================================
local function applyDecal(imageLabel, rawQuery)
    if not imageLabel then return end
    local cleanNum = tostring(rawQuery):match("%d+")
    imageLabel.Image = cleanNum and ("rbxthumb://type=Asset&id=" .. cleanNum .. "&w=420&h=420") or "rbxassetid://10734974297"

    local customAssetFn = getcustomasset or getsynasset
    if cleanNum and customAssetFn and writefile and readfile and isfile and makefolder then
        local cacheFolder = LoaderConfig.AuthFolder
        if isfolder and not isfolder(cacheFolder) then pcall(makefolder, cacheFolder) end
        local cacheFile = cacheFolder .. "/Asset_" .. cleanNum .. ".png"

        if isfile(cacheFile) then
            local s, asset = pcall(customAssetFn, cacheFile)
            if s and asset then imageLabel.Image = asset return end
        end

        task.spawn(function()
            local cdnUrl = "https://tr.rbxcdn.com/180DAY-299908871c7597ad2f85e220058de002/420/420/Decal/Png/noFilter"
            local imgSuccess, imgBytes = pcall(function() return game:HttpGet(cdnUrl) end)
            if imgSuccess and imgBytes and #imgBytes > 0 then
                pcall(writefile, cacheFile, imgBytes)
                local s, asset = pcall(customAssetFn, cacheFile)
                if s and asset and imageLabel and imageLabel.Parent then
                    imageLabel.Image = asset
                end
            end
        end)
    end
end

-- ==============================================================================
-- 4. SAVED AUTHENTICATION (AUTO-LOGIN)
-- ==============================================================================
local function getSavedKey()
    if not isfile or not readfile then return nil end
    local path = LoaderConfig.AuthFolder .. "/" .. LoaderConfig.AuthFile
    if not isfile(path) then return nil end
    local s, data = pcall(readfile, path)
    if s and data and data ~= "" then
        local ps, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if ps and type(decoded) == "table" and decoded.Key then
            return decoded.Key
        end
    end
    return nil
end

local function saveKey(key)
    if not writefile or not makefolder then return end
    if isfolder and not isfolder(LoaderConfig.AuthFolder) then
        pcall(makefolder, LoaderConfig.AuthFolder)
    end
    local path = LoaderConfig.AuthFolder .. "/" .. LoaderConfig.AuthFile
    local payload = HttpService:JSONEncode({ Key = key, Time = os.time() })
    pcall(writefile, path, payload)
end

-- ==============================================================================
-- 5. GUI BUILDER
-- ==============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HoshiHub_Loader"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = safeParent

local mainCard = Instance.new("Frame")
mainCard.Name = "LoaderCard"
mainCard.Size = UDim2.new(0, 440, 0, 310)
mainCard.Position = UDim2.new(0.5, 0, 0.5, 0)
mainCard.AnchorPoint = Vector2.new(0.5, 0.5)
mainCard.BackgroundColor3 = Theme.Background
mainCard.ClipsDescendants = true
mainCard.Parent = screenGui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 14)
cardCorner.Parent = mainCard

local cardStroke = Instance.new("UIStroke")
cardStroke.Thickness = 1.5
cardStroke.Color = Theme.Border
cardStroke.Parent = mainCard

local cardScale = Instance.new("UIScale")
cardScale.Scale = 0.85
cardScale.Parent = mainCard

-- Ambient Shadow
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 40, 1, 40)
shadow.Position = UDim2.new(0, -20, 0, -20)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://6015897843"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.4
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
shadow.ScaleType = Enum.ScaleType.Slice
shadow.ZIndex = 0
shadow.Parent = mainCard

-- Top Bar & Dragging
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 52)
topBar.BackgroundTransparency = 1
topBar.Parent = mainCard

local logoImg = Instance.new("ImageLabel")
logoImg.Name = "Logo"
logoImg.Size = UDim2.new(0, 32, 0, 32)
logoImg.Position = UDim2.new(0, 16, 0.5, -16)
logoImg.BackgroundTransparency = 1
logoImg.Parent = topBar
local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(0, 8)
logoCorner.Parent = logoImg
applyDecal(logoImg, LoaderConfig.LogoAssetId)

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -120, 0, 20)
titleLabel.Position = UDim2.new(0, 56, 0, 8)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = LoaderConfig.HubTitle
titleLabel.TextColor3 = Theme.Text
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local subTitleLabel = Instance.new("TextLabel")
subTitleLabel.Name = "SubTitle"
subTitleLabel.Size = UDim2.new(1, -120, 0, 14)
subTitleLabel.Position = UDim2.new(0, 56, 0, 28)
subTitleLabel.BackgroundTransparency = 1
subTitleLabel.Text = LoaderConfig.HubSubTitle
subTitleLabel.TextColor3 = Theme.SubText
subTitleLabel.TextSize = 10
subTitleLabel.Font = Enum.Font.GothamMedium
subTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subTitleLabel.Parent = topBar

local closeBtn = Instance.new("ImageButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -40, 0.5, -14)
closeBtn.BackgroundColor3 = Theme.Card
closeBtn.AutoButtonColor = false
closeBtn.Parent = topBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn
local closeStroke = Instance.new("UIStroke")
closeStroke.Color = Theme.Border
closeStroke.Parent = closeBtn

local closeIcon = Instance.new("ImageLabel")
closeIcon.Size = UDim2.new(0, 14, 0, 14)
closeIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
closeIcon.BackgroundTransparency = 1
closeIcon.Image = "rbxassetid://9886659671"
closeIcon.ImageColor3 = Theme.SubText
closeIcon.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.CardHover }):Play()
    TweenService:Create(closeIcon, TweenInfo.new(0.15), { ImageColor3 = Theme.Text }):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Card }):Play()
    TweenService:Create(closeIcon, TweenInfo.new(0.15), { ImageColor3 = Theme.SubText }):Play()
end)
closeBtn.MouseButton1Click:Connect(function()
    local anim = TweenService:Create(cardScale, TweenInfo.new(0.15, Enum.EasingStyle.Sine), { Scale = 0.85 })
    anim:Play()
    anim.Completed:Connect(function() screenGui:Destroy() end)
end)

-- Draggable Logic
local dragging, dragStart, startPos
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainCard.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainCard.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Game Detection Badge
local gameBadge = Instance.new("Frame")
gameBadge.Name = "GameBadge"
gameBadge.Size = UDim2.new(1, -32, 0, 36)
gameBadge.Position = UDim2.new(0, 16, 0, 60)
gameBadge.BackgroundColor3 = Theme.Card
gameBadge.Parent = mainCard
local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 8)
badgeCorner.Parent = gameBadge
local badgeStroke = Instance.new("UIStroke")
badgeStroke.Color = Theme.Border
badgeStroke.Parent = gameBadge

local gameIcon = Instance.new("ImageLabel")
gameIcon.Size = UDim2.new(0, 16, 0, 16)
gameIcon.Position = UDim2.new(0, 10, 0.5, -8)
gameIcon.BackgroundTransparency = 1
gameIcon.Image = "rbxassetid://10734974297"
gameIcon.ImageColor3 = Theme.Accent
gameIcon.Parent = gameBadge

local gameBadgeText = Instance.new("TextLabel")
gameBadgeText.Size = UDim2.new(1, -36, 1, 0)
gameBadgeText.Position = UDim2.new(0, 32, 0, 0)
gameBadgeText.BackgroundTransparency = 1
gameBadgeText.Text = "Target Game: " .. detectedGameName .. " (" .. tostring(PlaceId) .. ")"
gameBadgeText.TextColor3 = Theme.Text
gameBadgeText.TextSize = 11
gameBadgeText.Font = Enum.Font.GothamMedium
gameBadgeText.TextXAlignment = Enum.TextXAlignment.Left
gameBadgeText.TextTruncate = Enum.TextTruncate.AtEnd
gameBadgeText.Parent = gameBadge

-- Password Input Field
local inputContainer = Instance.new("Frame")
inputContainer.Name = "InputContainer"
inputContainer.Size = UDim2.new(1, -32, 0, 44)
inputContainer.Position = UDim2.new(0, 16, 0, 108)
inputContainer.BackgroundColor3 = Theme.InputBg
inputContainer.Parent = mainCard
local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = inputContainer
local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Theme.Border
inputStroke.Thickness = 1
inputStroke.Parent = inputContainer

local keyIcon = Instance.new("ImageLabel")
keyIcon.Size = UDim2.new(0, 18, 0, 18)
keyIcon.Position = UDim2.new(0, 12, 0.5, -9)
keyIcon.BackgroundTransparency = 1
keyIcon.Image = "rbxassetid://7733964719" -- Lucide Key icon
keyIcon.ImageColor3 = Theme.SubText
keyIcon.Parent = inputContainer

local textBox = Instance.new("TextBox")
textBox.Name = "KeyBox"
textBox.Size = UDim2.new(1, -44, 1, 0)
textBox.Position = UDim2.new(0, 38, 0, 0)
textBox.BackgroundTransparency = 1
textBox.Text = ""
textBox.PlaceholderText = "Enter Access Password..."
textBox.PlaceholderColor3 = Theme.SubText
textBox.TextColor3 = Theme.Text
textBox.TextSize = 12
textBox.Font = Enum.Font.GothamMedium
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.ClearTextOnFocus = false
textBox.Parent = inputContainer

local focusLine = Instance.new("Frame")
focusLine.Size = UDim2.new(0, 0, 0, 2)
focusLine.Position = UDim2.new(0, 0, 1, -2)
focusLine.BackgroundColor3 = Theme.Accent
focusLine.Parent = inputContainer

textBox.Focused:Connect(function()
    TweenService:Create(focusLine, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, 2) }):Play()
    TweenService:Create(inputStroke, TweenInfo.new(0.2), { Color = Theme.Accent }):Play()
    TweenService:Create(keyIcon, TweenInfo.new(0.2), { ImageColor3 = Theme.Accent }):Play()
end)

textBox.FocusLost:Connect(function()
    TweenService:Create(focusLine, TweenInfo.new(0.2), { Size = UDim2.new(0, 0, 0, 2) }):Play()
    TweenService:Create(inputStroke, TweenInfo.new(0.2), { Color = Theme.Border }):Play()
    TweenService:Create(keyIcon, TweenInfo.new(0.2), { ImageColor3 = Theme.SubText }):Play()
end)

-- Status / Error Feedback Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -32, 0, 16)
statusLabel.Position = UDim2.new(0, 16, 0, 158)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Please enter password to unlock and load HoshiHub."
statusLabel.TextColor3 = Theme.SubText
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainCard

-- Action Buttons Container
local btnRow = Instance.new("Frame")
btnRow.Name = "ButtonRow"
btnRow.Size = UDim2.new(1, -32, 0, 38)
btnRow.Position = UDim2.new(0, 16, 0, 182)
btnRow.BackgroundTransparency = 1
btnRow.Parent = mainCard

local enterBtn = Instance.new("TextButton")
enterBtn.Name = "EnterBtn"
enterBtn.Size = UDim2.new(0.62, -6, 1, 0)
enterBtn.Position = UDim2.new(0, 0, 0, 0)
enterBtn.BackgroundColor3 = Theme.Accent
enterBtn.AutoButtonColor = false
enterBtn.Text = "Enter Hub"
enterBtn.TextColor3 = Theme.Background
enterBtn.TextSize = 13
enterBtn.Font = Enum.Font.GothamBold
enterBtn.Parent = btnRow
local enterCorner = Instance.new("UICorner")
enterCorner.CornerRadius = UDim.new(0, 8)
enterCorner.Parent = enterBtn

local discordBtn = Instance.new("TextButton")
discordBtn.Name = "DiscordBtn"
discordBtn.Size = UDim2.new(0.38, 0, 1, 0)
discordBtn.Position = UDim2.new(0.62, 0, 0, 0)
discordBtn.BackgroundColor3 = Theme.Card
discordBtn.AutoButtonColor = false
discordBtn.Text = "Get Password"
discordBtn.TextColor3 = Theme.Text
discordBtn.TextSize = 11
discordBtn.Font = Enum.Font.GothamMedium
discordBtn.Parent = btnRow
local discCorner = Instance.new("UICorner")
discCorner.CornerRadius = UDim.new(0, 8)
discCorner.Parent = discordBtn
local discStroke = Instance.new("UIStroke")
discStroke.Color = Theme.Border
discStroke.Parent = discordBtn

enterBtn.MouseEnter:Connect(function()
    TweenService:Create(enterBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.AccentHover }):Play()
end)
enterBtn.MouseLeave:Connect(function()
    TweenService:Create(enterBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Accent }):Play()
end)

discordBtn.MouseEnter:Connect(function()
    TweenService:Create(discordBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.CardHover }):Play()
end)
discordBtn.MouseLeave:Connect(function()
    TweenService:Create(discordBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Card }):Play()
end)

discordBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(LoaderConfig.DiscordLink)
        statusLabel.TextColor3 = Theme.Success
        statusLabel.Text = "Discord link copied to clipboard!"
    else
        statusLabel.TextColor3 = Theme.Accent
        statusLabel.Text = "Discord: " .. LoaderConfig.DiscordLink
    end
end)

-- Loading / Progress Bar
local progressBg = Instance.new("Frame")
progressBg.Name = "ProgressBg"
progressBg.Size = UDim2.new(1, -32, 0, 4)
progressBg.Position = UDim2.new(0, 16, 0, 232)
progressBg.BackgroundColor3 = Theme.Card
progressBg.Parent = mainCard
local progCorner = Instance.new("UICorner")
progCorner.CornerRadius = UDim.new(0, 2)
progCorner.Parent = progressBg

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Theme.Accent
progressFill.Parent = progressBg
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 2)
fillCorner.Parent = progressFill

-- Footer Info
local footerLabel = Instance.new("TextLabel")
footerLabel.Name = "Footer"
footerLabel.Size = UDim2.new(1, -32, 0, 18)
footerLabel.Position = UDim2.new(0, 16, 1, -26)
footerLabel.BackgroundTransparency = 1
footerLabel.Text = "HoshiHub v2.0 • Secured Gateway • " .. os.date("%Y")
footerLabel.TextColor3 = Theme.SubText
footerLabel.TextSize = 10
footerLabel.Font = Enum.Font.GothamMedium
footerLabel.TextXAlignment = Enum.TextXAlignment.Center
footerLabel.Parent = mainCard

-- ==============================================================================
-- 6. AUTHENTICATION & EXECUTION DISPATCHER
-- ==============================================================================
local isVerifying = false

local function executeScript()
    statusLabel.TextColor3 = Theme.Success
    statusLabel.Text = "Password Verified! Launching " .. detectedGameName .. "..."
    
    TweenService:Create(progressFill, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { Size = UDim2.new(1, 0, 1, 0) }):Play()
    task.wait(0.85)

    -- Animate card close
    local closeAnim = TweenService:Create(cardScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0.4 })
    closeAnim:Play()
    closeAnim.Completed:Connect(function()
        screenGui:Destroy()
        -- Load target script from GitHub repository
        local url = LoaderConfig.GitHubRaw .. "/" .. targetScript
        local success, scriptContent = pcall(game.HttpGet, game, url)
        if success and scriptContent and type(scriptContent) == "string" and #scriptContent > 100 then
            local fn, parseErr = loadstring(scriptContent)
            if fn then
                local execSuccess, execErr = pcall(fn)
                if not execSuccess then
                    warn("[HoshiHub Loader] Execution Error: " .. tostring(execErr))
                end
            else
                warn("[HoshiHub Loader] Compile Error: " .. tostring(parseErr))
            end
        else
            warn("[HoshiHub Loader] Failed to fetch script: " .. url)
        end
    end)
end

local function verifyPassword(inputKey)
    if isVerifying then return end
    isVerifying = true

    local cleanInput = tostring(inputKey or textBox.Text):gsub("%s+", "")
    if cleanInput == "" then
        statusLabel.TextColor3 = Theme.Danger
        statusLabel.Text = "Error: Password cannot be empty!"
        TweenService:Create(inputStroke, TweenInfo.new(0.15), { Color = Theme.Danger }):Play()
        isVerifying = false
        return
    end

    if cleanInput == LoaderConfig.Password then
        if LoaderConfig.SaveAuth then
            saveKey(cleanInput)
        end
        executeScript()
    else
        statusLabel.TextColor3 = Theme.Danger
        statusLabel.Text = "Invalid Password! Check Discord"
        TweenService:Create(inputStroke, TweenInfo.new(0.15), { Color = Theme.Danger }):Play()
        task.wait(1.5)
        TweenService:Create(inputStroke, TweenInfo.new(0.2), { Color = Theme.Border }):Play()
        isVerifying = false
    end
end

enterBtn.MouseButton1Click:Connect(function()
    verifyPassword()
end)

textBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        verifyPassword()
    end
end)

-- Entrance Animation
TweenService:Create(cardScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

-- Check Auto-Login with Saved Key
local saved = getSavedKey()
if saved and saved == LoaderConfig.Password then
    textBox.Text = saved
    statusLabel.TextColor3 = Theme.Success
    statusLabel.Text = "Saved password detected! Logging in automatically..."
    task.delay(0.4, function()
        verifyPassword(saved)
    end)
end

return screenGui
