-- ==============================================================================
-- HoshiHub — Pantai Voice Chat Dedicated Suite
-- Game: PANTAI VOICE CHAT (PlaceId: 126463495082631)
-- Developer: JANUARY STUDIO
-- Loaded via HoshiHub Gateway
-- ==============================================================================

local GITHUB_RAW = "https://raw.githubusercontent.com/0x0228/HoshiHub/master"

-- Load HoshiUI Library
local HoshiUI = loadstring(game:HttpGet(GITHUB_RAW .. "/UI/UI.lua"))()

-- Roblox Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==============================================================================
-- 1. INITIALIZE WINDOW
-- ==============================================================================
local Window = HoshiUI:CreateWindow({
    Title = "Hoshi Hub",
    SubTitle = "Pantai Voice Chat • Fishing & Social Suite",
    Icon = "95445676600352",
    Size = UDim2.new(0, 680, 0, 440),
    Theme = "Hoshi",
    ToggleKey = Enum.KeyCode.RightControl,
    FloatingButton = true,
    FloatingIcon = "95445676600352",
    Folder = "HoshiHub_Pantai",
    ConfigFile = "Config.json",
    AutoSave = true,
    Resizable = true,
})

-- Welcome Toast
Window:Notify({
    Title = "Pantai Voice Chat Loaded",
    Content = "Welcome " .. LocalPlayer.DisplayName .. "! Auto-fishing and map tools initialized.",
    Duration = 4,
})

-- ==============================================================================
-- 2. STATE & CORE AUTOMATION LOGIC
-- ==============================================================================
local State = {
    -- Fishing
    AutoFish = false,
    InstantReel = true,
    CastDelay = 1.2,
    SelectedRod = "NormalRod",
    
    -- Player
    WalkSpeed = 16,
    JumpPower = 50,
    InfJump = false,
    Noclip = false,
    Fly = false,
    FlySpeed = 50,
    AntiAFK = true,
    AntiJahil = false,
    
    -- Visuals
    Fullbright = false,
    PlayerESP = false,
    ESPColor = Color3.fromRGB(247, 230, 185),
    FOV = 70,
}

-- Character Utility Helper
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid()
    local char = getCharacter()
    return char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
    local char = getCharacter()
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end

-- Find Equipped or Backpack Fishing Rod
local function getActiveRod()
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and (item.Name:find("Rod") or item:FindFirstChild("CastToPosition")) then
                return item
            end
        end
    end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and (item.Name:find("Rod") or item:FindFirstChild("CastToPosition")) then
                return item
            end
        end
    end
    return nil
end

-- ==============================================================================
-- 3. FISHING AUTOMATION THREAD
-- ==============================================================================
task.spawn(function()
    while true do
        task.wait(State.CastDelay)
        if State.AutoFish then
            pcall(function()
                local rod = getActiveRod()
                if rod then
                    -- Equip if in backpack
                    if rod.Parent ~= LocalPlayer.Character then
                        local hum = getHumanoid()
                        if hum then hum:EquipTool(rod) end
                        task.wait(0.3)
                    end

                    local hrp = getRootPart()
                    local castRemote = rod:FindFirstChild("CastToPosition")
                    local miniGameRemote = rod:FindFirstChild("MiniGame")

                    if castRemote and hrp then
                        -- Cast in front of player
                        local castTarget = hrp.Position + (hrp.CFrame.LookVector * 18) + Vector3.new(0, -3, 0)
                        castRemote:FireServer(castTarget)
                        
                        -- Wait for bite & solve minigame
                        if State.InstantReel and miniGameRemote then
                            task.wait(0.4)
                            miniGameRemote:FireServer(true)
                            miniGameRemote:FireServer(100)
                        end
                    end
                end
            end)
        end
    end
end)

-- Instant Hook Listener on MiniGame Remote
task.spawn(function()
    while true do
        task.wait(0.5)
        if State.AutoFish and State.InstantReel then
            pcall(function()
                local rod = getActiveRod()
                if rod then
                    local mg = rod:FindFirstChild("MiniGame")
                    if mg and mg:IsA("RemoteEvent") then
                        mg:FireServer(true)
                    end
                end
            end)
        end
    end
end)

-- ==============================================================================
-- 4. NOCLIP & INFINITE JUMP
-- ==============================================================================
RunService.Stepped:Connect(function()
    if State.Noclip then
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

UserInputService.JumpRequest:Connect(function()
    if State.InfJump then
        pcall(function()
            local hum = getHumanoid()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

-- ==============================================================================
-- 5. FLY ENGINE
-- ==============================================================================
local flyBodyGyro, flyBodyVel
local function updateFly()
    local char = LocalPlayer.Character
    local hrp = getRootPart()
    if not char or not hrp then return end

    if State.Fly then
        if not flyBodyGyro then
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.P = 9e4
            flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            flyBodyGyro.CFrame = hrp.CFrame
            flyBodyGyro.Parent = hrp
        end
        if not flyBodyVel then
            flyBodyVel = Instance.new("BodyVelocity")
            flyBodyVel.Velocity = Vector3.zero
            flyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            flyBodyVel.Parent = hrp
        end
        
        local hum = getHumanoid()
        if hum then hum.PlatformStand = true end
    else
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
        local hum = getHumanoid()
        if hum then hum.PlatformStand = false end
    end
end

RunService.RenderStepped:Connect(function()
    if State.Fly and flyBodyVel and flyBodyGyro then
        local hrp = getRootPart()
        if not hrp then return end
        
        flyBodyGyro.CFrame = Camera.CFrame
        local moveDir = Vector3.zero
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        
        flyBodyVel.Velocity = moveDir.Unit == moveDir.Unit and (moveDir.Unit * State.FlySpeed) or Vector3.zero
    end
end)

-- Character Added Persistence
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = State.WalkSpeed
        hum.JumpPower = State.JumpPower
    end
    if State.Fly then updateFly() end
end)

-- ==============================================================================
-- 6. FULLBRIGHT & FOV
-- ==============================================================================
local defaultBrightness = Lighting.Brightness
local defaultClock = Lighting.ClockTime
local defaultFog = Lighting.FogEnd

local function applyFullbright(enabled)
    if enabled then
        Lighting.Brightness = 2.5
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e5
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = defaultBrightness
        Lighting.ClockTime = defaultClock
        Lighting.FogEnd = defaultFog
        Lighting.GlobalShadows = true
    end
end

-- ==============================================================================
-- 7. PLAYER ESP ENGINE
-- ==============================================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "HoshiESP_Pantai"
ESPFolder.Parent = Workspace

local function createESP(player)
    if player == LocalPlayer then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_" .. player.Name
    highlight.FillColor = State.ESPColor
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    highlight.Enabled = State.PlayerESP

    local function updateAdornee()
        if player.Character then
            highlight.Adornee = player.Character
            highlight.Parent = ESPFolder
        end
    end
    updateAdornee()
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        updateAdornee()
    end)
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    local h = ESPFolder:FindFirstChild("ESP_" .. p.Name)
    if h then h:Destroy() end
end)

local function updateESPState(enabled)
    for _, h in ipairs(ESPFolder:GetChildren()) do
        if h:IsA("Highlight") then h.Enabled = enabled end
    end
end

local function updateESPColor(color)
    for _, h in ipairs(ESPFolder:GetChildren()) do
        if h:IsA("Highlight") then h.FillColor = color end
    end
end

-- Anti-AFK Connection
LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end
end)

-- ==============================================================================
-- 8. MAP LANDMARKS & LOCATIONS
-- ==============================================================================
local Locations = {
    ["Dermaga Mancing (Fishing Pier)"] = Vector3.new(18.5, 4.2, -85.6),
    ["Air Terjun (Waterfall)"] = Vector3.new(-120.4, 8.5, 142.1),
    ["Gazebo Pantai Utama"] = Vector3.new(45.2, 5.0, 30.8),
    ["Area Batu Karang"] = Vector3.new(98.6, 6.2, -145.3),
    ["Mesin ATM / Bank"] = Vector3.new(-15.8, 4.5, 65.2),
    ["Meja Catur & Game"] = Vector3.new(-65.0, 5.1, -12.4),
    ["Panggung Top Donatur"] = Vector3.new(12.0, 7.5, 110.0),
    ["Spot VIP Lounge"] = Vector3.new(-88.5, 12.0, 85.0),
}

-- ==============================================================================
-- 9. CREATE TABS & COMPONENTS
-- ==============================================================================

-- TAB 1: FISHING (MANCING)
local TabFishing = Window:CreateTab({ Title = "Fishing", Icon = "sparkles" })

TabFishing:CreateSection("Auto-Fishing Automation")

TabFishing:CreateToggle({
    Title = "Auto Cast & Reel (Auto-Mancing)",
    Default = false,
    Flag = "AutoFish",
    Callback = function(val)
        State.AutoFish = val
        if val then
            Window:Notify({ Title = "Auto Fish", Content = "Auto-fishing started. Pegang joran atau biarkan script equip otomatis.", Duration = 3 })
        end
    end
})

TabFishing:CreateToggle({
    Title = "Instant MiniGame Solver",
    Default = true,
    Flag = "InstantReel",
    Callback = function(val)
        State.InstantReel = val
    end
})

TabFishing:CreateSlider({
    Title = "Cast Delay Speed",
    Min = 0.5,
    Max = 4.0,
    Default = 1.2,
    Increment = 0.1,
    ValueName = "sec",
    Flag = "CastDelay",
    Callback = function(val)
        State.CastDelay = val
    end
})

TabFishing:CreateSection("Inventory & Rod Actions")

TabFishing:CreateDropdown({
    Title = "Select Target Rod",
    Values = { "NormalRod", "LovingRod", "ForestRod", "AngelRod", "CrystalizedRod", "SeaRod", "ZeusRod", "ZombieRod", "VIPRod" },
    Default = "NormalRod",
    Flag = "SelectedRod",
    Callback = function(val)
        State.SelectedRod = val
    end
})

TabFishing:CreateButton({
    Title = "Equip Selected Rod",
    Callback = function()
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        local char = LocalPlayer.Character
        local hum = getHumanoid()
        if bp and hum then
            local targetTool = bp:FindFirstChild(State.SelectedRod) or (char and char:FindFirstChild(State.SelectedRod))
            if targetTool then
                hum:EquipTool(targetTool)
                Window:Notify({ Title = "Inventory", Content = "Equipped: " .. targetTool.Name, Duration = 2 })
            else
                Window:Notify({ Title = "Not Found", Content = State.SelectedRod .. " tidak ditemukan di Backpack.", Duration = 3 })
            end
        end
    end
})

TabFishing:CreateButton({
    Title = "Open Fish Inventory (Ganti Ikan)",
    Callback = function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            local gi = pg:FindFirstChild("GantiIkan")
            if gi and gi:FindFirstChild("MainFrame") then
                gi.MainFrame.Visible = true
            end
        end
    end
})

TabFishing:CreateButton({
    Title = "Open Rod Color Customizer",
    Callback = function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            local cr = pg:FindFirstChild("ColorRodGui")
            if cr and cr:FindFirstChild("ColorFrame") then
                cr.ColorFrame.Visible = true
            end
        end
    end
})

-- TAB 2: PLAYER & MOVEMENT
local TabPlayer = Window:CreateTab({ Title = "Player", Icon = "user" })

TabPlayer:CreateSection("Movement Speeds")

TabPlayer:CreateSlider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 150,
    Default = 16,
    Increment = 1,
    ValueName = "studs/s",
    Flag = "WalkSpeed",
    Callback = function(val)
        State.WalkSpeed = val
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = val end
    end
})

TabPlayer:CreateSlider({
    Title = "JumpPower",
    Min = 50,
    Max = 250,
    Default = 50,
    Increment = 5,
    ValueName = "power",
    Flag = "JumpPower",
    Callback = function(val)
        State.JumpPower = val
        local hum = getHumanoid()
        if hum then hum.JumpPower = val end
    end
})

TabPlayer:CreateSection("Movement Abilities")

TabPlayer:CreateToggle({
    Title = "Infinite Jump",
    Default = false,
    Flag = "InfJump",
    Callback = function(val)
        State.InfJump = val
    end
})

TabPlayer:CreateToggle({
    Title = "Noclip (Walk Through Walls)",
    Default = false,
    Flag = "Noclip",
    Callback = function(val)
        State.Noclip = val
    end
})

TabPlayer:CreateToggle({
    Title = "Fly Mode (WASD + Space/Shift)",
    Default = false,
    Flag = "Fly",
    Callback = function(val)
        State.Fly = val
        updateFly()
    end
})

TabPlayer:CreateSlider({
    Title = "Fly Speed",
    Min = 15,
    Max = 150,
    Default = 50,
    Increment = 5,
    ValueName = "speed",
    Flag = "FlySpeed",
    Callback = function(val)
        State.FlySpeed = val
    end
})

-- TAB 3: TELEPORTS (LOKASI PANTAI)
local TabTeleport = Window:CreateTab({ Title = "Teleports", Icon = "target" })

TabTeleport:CreateSection("Beach Landmarks")

local locNames = {}
for name in pairs(Locations) do table.insert(locNames, name) end
table.sort(locNames)

local selectedLocation = locNames[1]

TabTeleport:CreateDropdown({
    Title = "Choose Location",
    Values = locNames,
    Default = locNames[1],
    Callback = function(val)
        selectedLocation = val
    end
})

TabTeleport:CreateButton({
    Title = "Teleport to Landmark",
    Callback = function()
        local targetPos = Locations[selectedLocation]
        local hrp = getRootPart()
        if hrp and targetPos then
            hrp.CFrame = CFrame.new(targetPos) + Vector3.new(0, 3, 0)
            Window:Notify({ Title = "Teleport", Content = "Teleported to " .. selectedLocation, Duration = 2 })
        end
    end
})

TabTeleport:CreateSection("Player Teleport")

local function getPlayerNames()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    if #list == 0 then table.insert(list, "No other players") end
    return list
end

local targetPlayerName = getPlayerNames()[1]

local PlayerDropdown = TabTeleport:CreateDropdown({
    Title = "Select Player",
    Values = getPlayerNames(),
    Default = targetPlayerName,
    Callback = function(val)
        targetPlayerName = val
    end
})

TabTeleport:CreateButton({
    Title = "Teleport to Player",
    Callback = function()
        local target = Players:FindFirstChild(targetPlayerName)
        if target and target.Character then
            local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = getRootPart()
            if targetHrp and myHrp then
                myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, 2, 0)
                Window:Notify({ Title = "Teleport", Content = "Teleported to " .. target.DisplayName, Duration = 2 })
            end
        else
            Window:Notify({ Title = "Teleport Failed", Content = "Player tidak ditemukan atau belum spawn.", Duration = 3 })
        end
    end
})

TabTeleport:CreateButton({
    Title = "Refresh Players List",
    Callback = function()
        local updated = getPlayerNames()
        PlayerDropdown:SetValues(updated)
        Window:Notify({ Title = "Refreshed", Content = "Player list updated (" .. #updated .. " players).", Duration = 2 })
    end
})

-- TAB 4: VISUALS & ESP
local TabVisuals = Window:CreateTab({ Title = "Visuals", Icon = "eye" })

TabVisuals:CreateSection("ESP Highlights")

TabVisuals:CreateToggle({
    Title = "Player Highlights (ESP)",
    Default = false,
    Flag = "PlayerESP",
    Callback = function(val)
        State.PlayerESP = val
        updateESPState(val)
    end
})

TabVisuals:CreateColorPicker({
    Title = "ESP Highlight Color",
    Default = State.ESPColor,
    Flag = "ESPColor",
    Callback = function(color)
        State.ESPColor = color
        updateESPColor(color)
    end
})

TabVisuals:CreateSection("World & Camera")

TabVisuals:CreateToggle({
    Title = "Fullbright (Night Vision)",
    Default = false,
    Flag = "Fullbright",
    Callback = function(val)
        State.Fullbright = val
        applyFullbright(val)
    end
})

TabVisuals:CreateSlider({
    Title = "Field of View (FOV)",
    Min = 60,
    Max = 120,
    Default = 70,
    Increment = 1,
    ValueName = "°",
    Flag = "FOV",
    Callback = function(val)
        State.FOV = val
        Camera.FieldOfView = val
    end
})

-- TAB 5: UTILITY & SETTINGS
local TabUtility = Window:CreateTab({ Title = "Utility", Icon = "settings" })

TabUtility:CreateSection("Game Utility")

TabUtility:CreateButton({
    Title = "Open ATM Interface",
    Callback = function()
        local atmEvent = ReplicatedStorage:FindFirstChild("ATMGuiEvent")
        if atmEvent and atmEvent:IsA("RemoteEvent") then
            atmEvent:FireServer()
            Window:Notify({ Title = "ATM", Content = "Fired ATMGuiEvent to server.", Duration = 2 })
        end
    end
})

TabUtility:CreateToggle({
    Title = "Anti-AFK (20 Min Disconnect Protection)",
    Default = true,
    Flag = "AntiAFK",
    Callback = function(val)
        State.AntiAFK = val
    end
})

TabUtility:CreateButton({
    Title = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

TabUtility:CreateSection("About & Information")

TabUtility:CreateParagraph({
    Title = "PANTAI VOICE CHAT SUITE",
    Content = "Developed with HoshiUI v2.3. Created for Pantai Voice Chat by JANUARY STUDIO.\nFeaturing instant auto-fish, Landmark teleports, fullbright, and responsive spring controls."
})

return Window
