-- ==============================================================================
-- HoshiUI — Acrylic Blur & Glassmorphism Shaders
-- ==============================================================================

local Acrylic = {}

function Acrylic.createGlass(parent, cornerRadius)
    local glass = Instance.new("Frame")
    glass.Name = "AcrylicGlass"
    glass.Size = UDim2.new(1, 0, 1, 0)
    glass.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    glass.BackgroundTransparency = 0.25
    glass.BorderSizePixel = 0
    glass.ZIndex = 0
    glass.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius or 12)
    corner.Parent = glass

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.92
    stroke.Thickness = 1
    stroke.Parent = glass

    return glass
end

return Acrylic
