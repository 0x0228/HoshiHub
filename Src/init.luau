--!strict
-- ==============================================================================
-- HoshiUI — Next-Gen Luau UI Library (Modular Core Entrypoint)
-- High Performance • 0ms Startup • Mobile Optimized • Spring Physics
-- ==============================================================================

local env = getfenv() :: any
local loadfile: any = rawget(env, "loadfile") or rawget(_G :: any, "loadfile") or (rawget(env, "getgenv") and env.getgenv().loadfile)

local Packages = {
    Signal = loadfile and loadfile("Src/Packages/Signal.luau")() or nil,
    Flipper = loadfile and loadfile("Src/Packages/Flipper.luau")() or nil,
}

local Modules = {
    Creator = loadfile and loadfile("Src/Modules/Creator.luau")() or nil,
    Icons = loadfile and loadfile("Src/Modules/Icons.luau")() or nil,
    ConfigManager = loadfile and loadfile("Src/Modules/ConfigManager.luau")() or nil,
    Acrylic = loadfile and loadfile("Src/Modules/Acrylic.luau")() or nil,
    Themes = loadfile and loadfile("Src/Themes/Themes.luau")() or nil,
}

local Components = {
    Button = loadfile and loadfile("Src/Components/Button.luau")() or nil,
    Toggle = loadfile and loadfile("Src/Components/Toggle.luau")() or nil,
    Slider = loadfile and loadfile("Src/Components/Slider.luau")() or nil,
    Dropdown = loadfile and loadfile("Src/Components/Dropdown.luau")() or nil,
    ColorPicker = loadfile and loadfile("Src/Components/ColorPicker.luau")() or nil,
    Keybind = loadfile and loadfile("Src/Components/Keybind.luau")() or nil,
    Input = loadfile and loadfile("Src/Components/Input.luau")() or nil,
    Notification = loadfile and loadfile("Src/Components/Notification.luau")() or nil,
    Dialog = loadfile and loadfile("Src/Components/Dialog.luau")() or nil,
    Tab = loadfile and loadfile("Src/Components/Tab.luau")() or nil,
    Window = loadfile and loadfile("Src/Components/Window.luau")() or nil,
}

local HoshiUI = {
    Version = "2.0.0",
    Windows = {},
    Packages = Packages,
    Modules = Modules,
    Components = Components,
}

function HoshiUI:CreateWindow(config)
    local Window = Components.Window.New(config, self, Modules, Packages, Components)
    table.insert(self.Windows, Window)
    return Window
end

function HoshiUI:AddWindow(config)
    return self:CreateWindow(config)
end

return HoshiUI
