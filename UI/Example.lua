-- ==============================================================================
-- HoshiUI — Ultimate Feature Showcase & Component Playground
-- Demonstrates every single UI component, icon pack, theme, modal & auto-save flag
-- Loaded directly from GitHub: 0x0228/HoshiHub (master branch)
-- ==============================================================================

local HoshiUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/0x0228/HoshiHub/master/UI/UI.lua"))()

-- 1. Initialize Window with Mobile & Desktop Floating Toggle
local Window = HoshiUI:CreateWindow({
    Title = "Hoshi Hub",
    SubTitle = "v2.0 • Complete Feature Showcase",
    Icon = "lucide:sparkles",
    Size = UDim2.new(0, 680, 0, 440),
    Theme = "Dark",                 -- "Dark", "Midnight", "Amethyst", "Emerald", "Rose", "Cyberpunk"
    ToggleKey = Enum.KeyCode.RightControl, -- Key to toggle on PC
    FloatingButton = true,          -- Draggable mobile floating toggle
    FloatingIcon = "lucide:sparkles",
    Folder = "HoshiHub",            -- Auto-Save folder name
    ConfigFile = "FeatureShowcase.json",
    AutoSave = true,                -- Automatic config persistence
    IconsType = "lucide"
})

-- Welcome Notification
Window:Notify({
    Title = "HoshiUI Loaded",
    Content = "All components, icon engines, and auto-save configs initialized!",
    Icon = "lucide:sparkles",
    Type = "Success",
    Duration = 4
})

-- ==============================================================================
-- TAB 1: 🎛️ CORE INTERACTIVE CONTROLS
-- ==============================================================================
local ControlsTab = Window:CreateTab({
    Title = "Controls",
    Icon = "lucide:sliders"
})

ControlsTab:CreateSection("Toggles & Switches", "Smooth animated pills with auto-save")

local Toggle1 = ControlsTab:CreateToggle({
    Title = "Auto Farm Mobs",
    Desc = "Target and defeat nearest enemies automatically",
    Default = false,
    Flag = "Demo_AutoFarm",
    Callback = function(state)
        Window:Notify({
            Title = "Toggle Changed",
            Content = "Auto Farm is now: " .. (state and "ENABLED" or "DISABLED"),
            Icon = state and "lucide:check" or "lucide:x",
            Type = state and "Success" or "Danger",
            Duration = 2
        })
    end
})

local Toggle2 = ControlsTab:CreateToggle({
    Title = "Silent Aim & Bullet Redirect",
    Desc = "Redirect projectiles to targets without moving camera",
    Default = true,
    Flag = "Demo_SilentAim",
    Callback = function(state)
        print("[Showcase] Silent Aim:", state)
    end
})

ControlsTab:CreateDivider()
ControlsTab:CreateSection("Sliders & Range Inputs", "Precision sliders with format strings and touch support")

local Slider1 = ControlsTab:CreateSlider({
    Title = "Player WalkSpeed",
    Desc = "Adjust character movement velocity in real-time",
    Min = 16,
    Max = 250,
    Default = 16,
    Step = 1,
    Format = "{value} studs/s",
    Flag = "Demo_WalkSpeed",
    Callback = function(val)
        local char = game.Players.LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
})

local Slider2 = ControlsTab:CreateSlider({
    Title = "Field of View (FOV)",
    Desc = "Camera viewing angle",
    Min = 60,
    Max = 120,
    Default = 70,
    Step = 5,
    Format = "{value}° FOV",
    Flag = "Demo_CameraFOV",
    Callback = function(val)
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = val end
    end
})

ControlsTab:CreateDivider()
ControlsTab:CreateSection("Dropdown Selectors", "Single & Multi-selection with live updating")

-- Single Select Dropdown
local SingleDropdown = ControlsTab:CreateDropdown({
    Title = "Weapon Priority",
    Options = { "Katana", "Dragon Slayer", "Blaster Pistol", "Shadow Dagger", "Magic Staff" },
    Default = "Katana",
    Flag = "Demo_WeaponSelect",
    Callback = function(selected)
        Window:Notify({
            Title = "Weapon Selected",
            Content = "Equipped weapon priority: " .. tostring(selected),
            Icon = "craft:sword",
            Type = "Info",
            Duration = 2.5
        })
    end
})

-- Multi-Select Dropdown
local MultiDropdown = ControlsTab:CreateDropdown({
    Title = "Active ESP Features (Multi-Select)",
    Options = { "Boxes", "Tracers", "Name Tags", "Health Bars", "Chams", "Distances" },
    Default = { "Boxes", "Name Tags" },
    Multi = true,
    Flag = "Demo_ESPMulti",
    Callback = function(selectedTable)
        print("[Showcase] Multi-Selected:", table.concat(selectedTable, ", "))
    end
})

ControlsTab:CreateDivider()
ControlsTab:CreateSection("Inputs & Keybinds", "Text boxes, numeric filters, and dynamic key listeners")

local TextInput = ControlsTab:CreateInput({
    Title = "Target Player Username",
    Placeholder = "Enter exact username...",
    Default = "",
    Flag = "Demo_TargetPlayer",
    Callback = function(text, enterPressed)
        if enterPressed then
            Window:Notify({
                Title = "Target Locked",
                Content = "Target set to: " .. text,
                Icon = "lucide:target",
                Type = "Success",
                Duration = 2
            })
        end
    end
})

local NumericInput = ControlsTab:CreateInput({
    Title = "Teleport Delay (Numeric Filter)",
    Placeholder = "e.g. 500",
    Default = "250",
    NumericOnly = true,
    Flag = "Demo_DelayNum",
    Callback = function(numText)
        print("[Showcase] Numeric Input:", numText)
    end
})

local TeleportKeybind = ControlsTab:CreateKeybind({
    Title = "Instant Teleport Keybind",
    Default = Enum.KeyCode.E,
    Flag = "Demo_TeleportKey",
    Callback = function()
        Window:Notify({
            Title = "Keybind Triggered",
            Content = "Instant Teleport key (E) was pressed!",
            Icon = "lucide:zap",
            Type = "Info",
            Duration = 2
        })
    end
})

-- ==============================================================================
-- TAB 2: 🎨 VISUALS, BUTTONS & COLOR PICKERS
-- ==============================================================================
local VisualsTab = Window:CreateTab({
    Title = "Visuals & Colors",
    Icon = "lucide:palette"
})

VisualsTab:CreateSection("Color Pickers", "Live preview color swatches and preset modals")

local EnemyColor = VisualsTab:CreateColorPicker({
    Title = "Enemy Highlight Color",
    Default = Color3.fromRGB(244, 63, 94),
    Flag = "Demo_EnemyColor",
    Callback = function(col)
        print("[Showcase] Enemy Color changed:", col)
    end
})

local TeamColor = VisualsTab:CreateColorPicker({
    Title = "Team Highlight Color",
    Default = Color3.fromRGB(16, 185, 129),
    Flag = "Demo_TeamColor",
    Callback = function(col)
        print("[Showcase] Team Color changed:", col)
    end
})

local AccentColor = VisualsTab:CreateColorPicker({
    Title = "Custom Crosshair Color",
    Default = Color3.fromRGB(0, 230, 200),
    Flag = "Demo_CrosshairColor",
    Callback = function(col)
        print("[Showcase] Crosshair Color changed:", col)
    end
})

VisualsTab:CreateDivider()
VisualsTab:CreateSection("Button Variants", "Primary, Secondary, and Danger styled action buttons")

VisualsTab:CreateButton({
    Title = "Primary Action Button",
    Desc = "Highlighted accent button with ripple feedback",
    Icon = "lucide:play",
    Variant = "Primary",
    Callback = function()
        Window:Notify({
            Title = "Primary Button",
            Content = "You clicked the Primary action button!",
            Icon = "lucide:play",
            Type = "Success",
            Duration = 2.5
        })
    end
})

VisualsTab:CreateButton({
    Title = "Secondary Action Button",
    Desc = "Standard neutral surface button",
    Icon = "lucide:box",
    Variant = "Secondary",
    Callback = function()
        Window:Notify({
            Title = "Secondary Button",
            Content = "You clicked the Secondary button.",
            Icon = "lucide:box",
            Type = "Info",
            Duration = 2
        })
    end
})

VisualsTab:CreateButton({
    Title = "Danger Action Button",
    Desc = "Destructive action trigger with red warning styling",
    Icon = "lucide:trash",
    Variant = "Danger",
    Callback = function()
        Window:Notify({
            Title = "Danger Button",
            Content = "Warning: Danger action executed!",
            Icon = "lucide:alert-triangle",
            Type = "Danger",
            Duration = 3
        })
    end
})

-- ==============================================================================
-- TAB 3: 🔔 NOTIFICATIONS & MODAL DIALOGS
-- ==============================================================================
local PopupsTab = Window:CreateTab({
    Title = "Alerts & Modals",
    Icon = "lucide:bell"
})

PopupsTab:CreateSection("Toast Notification Types", "Test bottom-right stacking toasts with animated progress timers")

PopupsTab:CreateButton({
    Title = "Trigger Success Toast",
    Desc = "Displays green success notification (3s)",
    Icon = "lucide:check",
    Variant = "Secondary",
    Callback = function()
        Window:Notify({
            Title = "Quest Completed!",
            Content = "You earned +500 XP and unlocked Dragon Sword.",
            Icon = "lucide:check",
            Type = "Success",
            Duration = 3
        })
    end
})

PopupsTab:CreateButton({
    Title = "Trigger Info Toast",
    Desc = "Displays blue info notification (3s)",
    Icon = "lucide:info",
    Variant = "Secondary",
    Callback = function()
        Window:Notify({
            Title = "Game Server Info",
            Content = "Connected to Region: US-East • Ping: 32ms",
            Icon = "lucide:info",
            Type = "Info",
            Duration = 3
        })
    end
})

PopupsTab:CreateButton({
    Title = "Trigger Warning Toast",
    Desc = "Displays amber warning notification (4s)",
    Icon = "lucide:alert-triangle",
    Variant = "Secondary",
    Callback = function()
        Window:Notify({
            Title = "Anti-Cheat Alert",
            Content = "High speed anomaly detected. Smoothing enabled.",
            Icon = "lucide:alert-triangle",
            Type = "Warning",
            Duration = 4
        })
    end
})

PopupsTab:CreateButton({
    Title = "Trigger Danger Toast",
    Desc = "Displays red danger notification (4s)",
    Icon = "lucide:alert-circle",
    Variant = "Danger",
    Callback = function()
        Window:Notify({
            Title = "Critical Health!",
            Content = "Your health is below 15%! Auto-Heal triggered.",
            Icon = "lucide:flame",
            Type = "Danger",
            Duration = 4
        })
    end
})

PopupsTab:CreateDivider()
PopupsTab:CreateSection("Modal Confirmation Dialogs", "Interactive modal popups with custom action callbacks")

PopupsTab:CreateButton({
    Title = "Open Confirmation Dialog",
    Desc = "Opens a modal popup requiring user choice",
    Icon = "lucide:external-link",
    Variant = "Primary",
    Callback = function()
        Window:Dialog({
            Title = "Upgrade Weapon?",
            Content = "Do you wish to spend 1,000 Gold Coins to upgrade your Katana to Tier 5?",
            Buttons = {
                {
                    Text = "Upgrade",
                    Variant = "Primary",
                    Callback = function()
                        Window:Notify({
                            Title = "Upgraded!",
                            Content = "Your Katana is now Tier 5!",
                            Icon = "craft:sword",
                            Type = "Success",
                            Duration = 3
                        })
                    end
                },
                {
                    Text = "Cancel",
                    Variant = "Secondary",
                    Callback = function()
                        Window:Notify({
                            Title = "Cancelled",
                            Content = "Upgrade was cancelled.",
                            Icon = "lucide:x",
                            Type = "Info",
                            Duration = 2
                        })
                    end
                }
            }
        })
    end
})

-- ==============================================================================
-- TAB 4: 💎 MULTI-PACK ICONS (Footagesus/Icons)
-- ==============================================================================
local IconsTab = Window:CreateTab({
    Title = "Icon Engine",
    Icon = "lucide:box"
})

IconsTab:CreateSection("Multi-Pack Icon Showcase", "Direct resolver for Lucide, Solar, Craft, Geist, and SFSymbols")

IconsTab:CreateParagraph({
    Title = "Footagesus/Icons Multi-Pack Support",
    Content = "Use prefixes to access thousands of icons seamlessly: 'lucide:name', 'solar:name', 'craft:name', 'geist:name', or 'sfsymbols:name'.",
    Icon = "lucide:sparkles"
})

IconsTab:CreateButton({
    Title = "Solar Pack Icon",
    Desc = "Using prefix 'solar:shield-check'",
    Icon = "solar:shield-check",
    Variant = "Secondary"
})

IconsTab:CreateButton({
    Title = "Craft Pack Icon",
    Desc = "Using prefix 'craft:sword'",
    Icon = "craft:sword",
    Variant = "Secondary"
})

IconsTab:CreateButton({
    Title = "Geist Pack Icon",
    Desc = "Using prefix 'geist:terminal'",
    Icon = "geist:terminal",
    Variant = "Secondary"
})

IconsTab:CreateButton({
    Title = "Lucide Pack Icon",
    Desc = "Using prefix 'lucide:flame'",
    Icon = "lucide:flame",
    Variant = "Secondary"
})

-- ==============================================================================
-- TAB 5: ⚙️ THEMES & CONFIG PERSISTENCE
-- ==============================================================================
local SettingsTab = Window:CreateTab({
    Title = "Settings & Cloud",
    Icon = "lucide:settings"
})

SettingsTab:CreateSection("Theme Engine", "Switch themes live across the entire interface")

SettingsTab:CreateDropdown({
    Title = "Select Theme Preset",
    Options = { "Dark", "Midnight", "Amethyst", "Emerald", "Rose", "Cyberpunk" },
    Default = "Dark",
    Flag = "Showcase_Theme",
    Callback = function(selectedTheme)
        Window:SetTheme(selectedTheme)
        Window:Notify({
            Title = "Theme Applied",
            Content = "Switched to theme: " .. selectedTheme,
            Icon = "lucide:palette",
            Type = "Info",
            Duration = 2
        })
    end
})

SettingsTab:CreateDivider()
SettingsTab:CreateSection("Mobile & Floating Action Button", "Control the floating circular toggle")

SettingsTab:CreateToggle({
    Title = "Show Floating Toggle Button",
    Desc = "Show or hide the on-screen draggable circle button",
    Default = true,
    Flag = "Showcase_ShowFloating",
    Callback = function(state)
        Window:SetFloatingVisible(state)
    end
})

SettingsTab:CreateDivider()
SettingsTab:CreateSection("Auto-Save Config Engine", "Real-time state persistence to executor storage")

SettingsTab:CreateParagraph({
    Title = "Zero-Effort Auto-Save",
    Content = "All controls on every tab with a 'Flag' are automatically saved to 'HoshiHub/FeatureShowcase.json'. When you re-execute, all values restore automatically without manual loading!",
    Icon = "lucide:database"
})

SettingsTab:CreateButton({
    Title = "Export Active Config JSON",
    Desc = "Copies current settings JSON string to your clipboard",
    Icon = "lucide:copy",
    Variant = "Secondary",
    Callback = function()
        if setclipboard then
            local json = Window.ConfigManager:Export()
            setclipboard(json)
            Window:Notify({
                Title = "Copied to Clipboard!",
                Content = "Configuration JSON copied successfully.",
                Icon = "lucide:check",
                Type = "Success",
                Duration = 3
            })
        else
            print("[HoshiHub] Config JSON:", Window.ConfigManager:Export())
        end
    end
})

SettingsTab:CreateButton({
    Title = "Reset All Settings to Defaults",
    Desc = "Opens a confirmation dialog to wipe saved configs",
    Icon = "lucide:trash",
    Variant = "Danger",
    Callback = function()
        Window:Dialog({
            Title = "Reset Configuration?",
            Content = "Are you sure you want to reset all features to default values? This cannot be undone.",
            Buttons = {
                {
                    Text = "Reset All",
                    Variant = "Danger",
                    Callback = function()
                        Window:Notify({
                            Title = "Settings Reset",
                            Content = "Configurations have been reset.",
                            Icon = "lucide:refresh-cw",
                            Type = "Warning",
                            Duration = 3
                        })
                    end
                },
                {
                    Text = "Cancel",
                    Variant = "Secondary"
                }
            }
        })
    end
})
