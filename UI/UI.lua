--!nolint
--!nocheck
--!native
--!optimize 2

-- ==============================================================================
-- HoshiUI — Next-Gen High-Performance Roblox UI Library (Compiled Release)
-- Native JIT Optimized • 0ms Startup • 1-Request Execution • Flipper Spring Physics
-- ==============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==============================================================================
-- 1. PACKAGES: FAST LINKED-LIST SIGNAL
-- ==============================================================================
local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
    return setmetatable({
        _signal = signal,
        _fn = fn,
        _next = nil,
        _prev = nil,
        Connected = true,
    }, Connection)
end

function Connection:Disconnect()
    if not self.Connected then return end
    self.Connected = false
    if self._signal._head == self then self._signal._head = self._next end
    if self._signal._tail == self then self._signal._tail = self._prev end
    if self._prev then self._prev._next = self._next end
    if self._next then self._next._prev = self._prev end
    self._signal = nil
    self._fn = nil
    self._next = nil
    self._prev = nil
end

function Connection:Destroy() self:Disconnect() end

function Signal.new()
    return setmetatable({ _head = nil, _tail = nil }, Signal)
end

function Signal:Connect(fn)
    local conn = Connection.new(self, fn)
    if not self._head then
        self._head = conn
        self._tail = conn
    else
        conn._prev = self._tail
        self._tail._next = conn
        self._tail = conn
    end
    return conn
end

function Signal:Fire(...)
    local node = self._head
    while node do
        local nextNode = node._next
        if node.Connected and node._fn then
            task.spawn(node._fn, ...)
        end
        node = nextNode
    end
end

function Signal:Destroy()
    local node = self._head
    while node do
        local nextNode = node._next
        node.Connected = false
        node._signal = nil
        node._fn = nil
        node._next = nil
        node._prev = nil
        node = nextNode
    end
    self._head = nil
    self._tail = nil
end

-- ==============================================================================
-- 2. PACKAGES: FLIPPER SPRING PHYSICS ENGINE
-- ==============================================================================
local Flipper = {}

local Spring = {}
Spring.__index = Spring

function Spring.new(targetValue, options)
    options = options or {}
    return setmetatable({
        _targetValue = targetValue,
        _frequency = options.frequency or 4,
        _dampingRatio = options.dampingRatio or 1,
    }, Spring)
end

function Spring:step(state, dt)
    local d = self._dampingRatio
    local f = self._frequency * 2 * math.pi
    local g = self._targetValue
    local p0 = state.position
    local v0 = state.velocity
    local offset = p0 - g
    local decay = math.exp(-d * f * dt)

    local p1, v1
    if d == 1 then
        p1 = (offset * (1 + f * dt) + v0 * dt) * decay + g
        v1 = (v0 * (1 - f * dt) - offset * (f * f * dt)) * decay
    elseif d < 1 then
        local c = math.sqrt(1 - d * d)
        local i = math.cos(f * c * dt)
        local j = math.sin(f * c * dt)
        local z = (v0 + offset * (d * f)) / (f * c)
        p1 = (offset * i + z * j) * decay + g
        v1 = (v0 * (i - d * f * dt) - (offset * (f * c) + z * (d * f)) * j) * decay
    else
        local c = math.sqrt(d * d - 1)
        local r1 = -f * (d - c)
        local r2 = -f * (d + c)
        local co2 = (v0 - offset * r1) / (2 * f * c)
        local co1 = offset - co2
        local e1 = math.exp(r1 * dt)
        local e2 = math.exp(r2 * dt)
        p1 = co1 * e1 + co2 * e2 + g
        v1 = co1 * r1 * e1 + co2 * r2 * e2
    end

    local complete = math.abs(v1) < 0.001 and math.abs(p1 - g) < 0.001
    if complete then p1 = g v1 = 0 end
    return { position = p1, velocity = v1, complete = complete }
end

local SingleMotor = {}
SingleMotor.__index = SingleMotor

function SingleMotor.new(initialValue)
    return setmetatable({
        _state = { position = initialValue or 0, velocity = 0, complete = true },
        _goal = nil,
        _connections = {},
        _running = false,
        _connection = nil,
    }, SingleMotor)
end

function SingleMotor:onStep(fn)
    table.insert(self._connections, fn)
    fn(self._state.position)
    return {
        Disconnect = function()
            local idx = table.find(self._connections, fn)
            if idx then table.remove(self._connections, idx) end
        end
    }
end

function SingleMotor:setGoal(goal)
    self._goal = goal
    self._state.complete = false
    if not self._running then
        self._running = true
        self._connection = RunService.RenderStepped:Connect(function(dt)
            if not self._goal then self:stop() return end
            local newState = self._goal:step(self._state, dt)
            self._state = newState
            for _, fn in ipairs(self._connections) do fn(newState.position) end
            if newState.complete then self:stop() end
        end)
    end
end

function SingleMotor:stop()
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
    self._running = false
end

function SingleMotor:destroy()
    self:stop()
    self._connections = {}
end

Flipper.Spring = Spring
Flipper.SingleMotor = SingleMotor

-- ==============================================================================
-- 3. THEMES REGISTRY
-- ==============================================================================
local Themes = {
    ["Hoshi"] = {
        Background = Color3.fromRGB(15, 20, 29),       -- Deep cosmic navy
        CardBackground = Color3.fromRGB(24, 32, 45),   -- Atmospheric starry twilight slate
        CardHover = Color3.fromRGB(33, 44, 61),        -- Celestial luminous hover
        CardStroke = Color3.fromRGB(48, 64, 88),       -- Star-tinted stroke
        Border = Color3.fromRGB(40, 54, 74),           -- Twilight slate border
        Accent = Color3.fromRGB(247, 230, 185),        -- Cosmic champagne starlight gold (from planet/rings)
        AccentHover = Color3.fromRGB(255, 243, 212),   -- Luminous starlight shine
        AccentGlow = Color3.fromRGB(247, 230, 185),    -- Warm planetary halo glow
        Text = Color3.fromRGB(250, 248, 244),          -- Celestial ivory white
        SubText = Color3.fromRGB(156, 178, 198),       -- Muted twilight blue-gray (sky background)
        Success = Color3.fromRGB(120, 215, 175),       -- Aurora mint
        Warning = Color3.fromRGB(247, 205, 125),       -- Starburst amber
        Danger = Color3.fromRGB(245, 100, 120),        -- Supernova rose
        Sidebar = Color3.fromRGB(11, 15, 22),          -- Deep midnight sidebar
        ToggleOff = Color3.fromRGB(36, 48, 66),        -- Muted cosmic toggle
    },
    ["Dark"] = {
        Background = Color3.fromRGB(16, 17, 22),
        CardBackground = Color3.fromRGB(24, 25, 33),
        CardHover = Color3.fromRGB(30, 32, 42),
        CardStroke = Color3.fromRGB(42, 44, 58),
        Border = Color3.fromRGB(38, 40, 52),
        Accent = Color3.fromRGB(75, 130, 255),
        AccentHover = Color3.fromRGB(95, 145, 255),
        AccentGlow = Color3.fromRGB(75, 130, 255),
        Text = Color3.fromRGB(240, 242, 248),
        SubText = Color3.fromRGB(150, 155, 175),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Danger = Color3.fromRGB(231, 76, 60),
        Sidebar = Color3.fromRGB(13, 14, 18),
        ToggleOff = Color3.fromRGB(45, 48, 62),
    },
    ["Midnight"] = {
        Background = Color3.fromRGB(10, 11, 15),
        CardBackground = Color3.fromRGB(17, 18, 26),
        CardHover = Color3.fromRGB(23, 25, 36),
        CardStroke = Color3.fromRGB(32, 35, 50),
        Border = Color3.fromRGB(28, 30, 44),
        Accent = Color3.fromRGB(114, 90, 242),
        AccentHover = Color3.fromRGB(135, 112, 255),
        AccentGlow = Color3.fromRGB(114, 90, 242),
        Text = Color3.fromRGB(245, 246, 250),
        SubText = Color3.fromRGB(140, 145, 168),
        Success = Color3.fromRGB(50, 215, 130),
        Warning = Color3.fromRGB(255, 190, 30),
        Danger = Color3.fromRGB(255, 75, 75),
        Sidebar = Color3.fromRGB(7, 8, 12),
        ToggleOff = Color3.fromRGB(38, 40, 56),
    },
    ["Amethyst"] = {
        Background = Color3.fromRGB(18, 14, 26),
        CardBackground = Color3.fromRGB(27, 21, 39),
        CardHover = Color3.fromRGB(36, 28, 52),
        CardStroke = Color3.fromRGB(52, 40, 75),
        Border = Color3.fromRGB(46, 35, 66),
        Accent = Color3.fromRGB(168, 85, 247),
        AccentHover = Color3.fromRGB(192, 120, 255),
        AccentGlow = Color3.fromRGB(168, 85, 247),
        Text = Color3.fromRGB(248, 245, 255),
        SubText = Color3.fromRGB(170, 155, 195),
        Success = Color3.fromRGB(52, 211, 153),
        Warning = Color3.fromRGB(251, 191, 36),
        Danger = Color3.fromRGB(248, 113, 113),
        Sidebar = Color3.fromRGB(13, 10, 20),
        ToggleOff = Color3.fromRGB(50, 40, 68),
    },
    ["Emerald"] = {
        Background = Color3.fromRGB(12, 19, 16),
        CardBackground = Color3.fromRGB(18, 29, 24),
        CardHover = Color3.fromRGB(24, 39, 32),
        CardStroke = Color3.fromRGB(36, 58, 48),
        Border = Color3.fromRGB(30, 50, 40),
        Accent = Color3.fromRGB(16, 185, 129),
        AccentHover = Color3.fromRGB(52, 211, 153),
        AccentGlow = Color3.fromRGB(16, 185, 129),
        Text = Color3.fromRGB(240, 253, 244),
        SubText = Color3.fromRGB(140, 175, 155),
        Success = Color3.fromRGB(16, 185, 129),
        Warning = Color3.fromRGB(245, 158, 11),
        Danger = Color3.fromRGB(239, 68, 68),
        Sidebar = Color3.fromRGB(8, 14, 12),
        ToggleOff = Color3.fromRGB(35, 52, 44),
    },
    ["Rose"] = {
        Background = Color3.fromRGB(20, 13, 16),
        CardBackground = Color3.fromRGB(31, 20, 25),
        CardHover = Color3.fromRGB(42, 27, 34),
        CardStroke = Color3.fromRGB(62, 40, 50),
        Border = Color3.fromRGB(54, 34, 44),
        Accent = Color3.fromRGB(244, 63, 94),
        AccentHover = Color3.fromRGB(251, 113, 133),
        AccentGlow = Color3.fromRGB(244, 63, 94),
        Text = Color3.fromRGB(255, 241, 242),
        SubText = Color3.fromRGB(185, 145, 155),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(245, 158, 11),
        Danger = Color3.fromRGB(244, 63, 94),
        Sidebar = Color3.fromRGB(15, 9, 12),
        ToggleOff = Color3.fromRGB(58, 38, 48),
    },
    ["Cyberpunk"] = {
        Background = Color3.fromRGB(11, 12, 16),
        CardBackground = Color3.fromRGB(19, 20, 28),
        CardHover = Color3.fromRGB(26, 28, 38),
        CardStroke = Color3.fromRGB(45, 48, 66),
        Border = Color3.fromRGB(38, 42, 58),
        Accent = Color3.fromRGB(0, 230, 200),
        AccentHover = Color3.fromRGB(40, 255, 225),
        AccentGlow = Color3.fromRGB(0, 230, 200),
        Text = Color3.fromRGB(245, 250, 255),
        SubText = Color3.fromRGB(135, 150, 175),
        Success = Color3.fromRGB(0, 230, 200),
        Warning = Color3.fromRGB(255, 215, 0),
        Danger = Color3.fromRGB(255, 45, 85),
        Sidebar = Color3.fromRGB(8, 9, 12),
        ToggleOff = Color3.fromRGB(40, 44, 60),
    }
}

-- ==============================================================================
-- 4. EMBEDDED 0MS VERIFIED LUCIDE ICON REGISTRY
-- ==============================================================================
local BuiltinIcons = {
    -- Navigation, Sliders & Controls
    ["sliders"] = "rbxassetid://10734963400",
    ["sliders-horizontal"] = "rbxassetid://10734963191",
    ["slider"] = "rbxassetid://10734963400",
    ["controls"] = "rbxassetid://10734963400",
    ["settings"] = "rbxassetid://10734950309",
    ["settings-2"] = "rbxassetid://10734950309",
    ["gear"] = "rbxassetid://10734950309",
    ["cog"] = "rbxassetid://10734950309",
    ["config"] = "rbxassetid://10734950309",
    ["home"] = "rbxassetid://10723407389",
    ["house"] = "rbxassetid://10723407389",
    ["main"] = "rbxassetid://10723407389",
    ["palette"] = "rbxassetid://10723387841",
    ["theme"] = "rbxassetid://10723387841",
    ["colors"] = "rbxassetid://10723387841",
    ["color"] = "rbxassetid://10723387841",
    ["bell"] = "rbxassetid://10709775704",
    ["notification"] = "rbxassetid://10709775704",
    ["bell-ring"] = "rbxassetid://10709775560",
    ["bell-off"] = "rbxassetid://10709775320",

    -- Window, Modal & Actions
    ["x"] = "rbxassetid://9886659671",
    ["close"] = "rbxassetid://9886659671",
    ["cancel"] = "rbxassetid://9886659671",
    ["chevron-up"] = "rbxassetid://9886659276",
    ["minimize"] = "rbxassetid://9886659276",
    ["min"] = "rbxassetid://9886659276",
    ["chevron-down"] = "rbxassetid://10709790948",
    ["chevron-left"] = "rbxassetid://10709791024",
    ["chevron-right"] = "rbxassetid://10709791175",
    ["chevrons-up"] = "rbxassetid://10709791750",
    ["chevrons-down"] = "rbxassetid://10709791437",
    ["chevrons-left"] = "rbxassetid://10709791532",
    ["chevrons-right"] = "rbxassetid://10709791624",
    ["check"] = "rbxassetid://10709790644",
    ["check-circle"] = "rbxassetid://10709790387",
    ["check-square"] = "rbxassetid://10709790537",

    -- Core UI Symbols
    ["sparkles"] = "rbxassetid://10734974297",
    ["sparkle"] = "rbxassetid://10734974297",
    ["star"] = "rbxassetid://10709804513",
    ["box"] = "rbxassetid://10709782497",
    ["boxes"] = "rbxassetid://10709782582",
    ["cube"] = "rbxassetid://10709782497",
    ["layers"] = "rbxassetid://10709798201",
    ["layout"] = "rbxassetid://10709798317",
    ["layout-grid"] = "rbxassetid://10723373997",
    ["grid"] = "rbxassetid://10709796853",
    ["mouse-pointer"] = "rbxassetid://10709801003",
    ["cursor"] = "rbxassetid://10709801003",
    ["pointer"] = "rbxassetid://10709801003",

    -- Combat, Game & Exploits
    ["shield"] = "rbxassetid://10734951847",
    ["shield-check"] = "rbxassetid://10734952136",
    ["shield-alert"] = "rbxassetid://10734952044",
    ["shield-off"] = "rbxassetid://10709803577",
    ["swords"] = "rbxassetid://10734975692",
    ["sword"] = "rbxassetid://10734975486",
    ["axe"] = "rbxassetid://10709769508",
    ["zap"] = "rbxassetid://10709819149",
    ["lightning"] = "rbxassetid://10709819149",
    ["flame"] = "rbxassetid://10723376114",
    ["fire"] = "rbxassetid://10723376114",
    ["target"] = "rbxassetid://10734979144",
    ["crosshair"] = "rbxassetid://10709794464",
    ["aim"] = "rbxassetid://10734979144",
    ["eye"] = "rbxassetid://10709795498",
    ["eye-off"] = "rbxassetid://10709795415",
    ["esp"] = "rbxassetid://10709795498",
    ["heart"] = "rbxassetid://10709797316",
    ["hp"] = "rbxassetid://10709797316",
    ["health"] = "rbxassetid://10709797316",

    -- Dev & System
    ["code"] = "rbxassetid://10709793413",
    ["terminal"] = "rbxassetid://10734982144",
    ["cli"] = "rbxassetid://10734982144",
    ["console"] = "rbxassetid://10734982144",
    ["cpu"] = "rbxassetid://10709794132",
    ["chip"] = "rbxassetid://10709794132",
    ["database"] = "rbxassetid://10709794585",
    ["storage"] = "rbxassetid://10709794585",
    ["db"] = "rbxassetid://10709794585",
    ["server"] = "rbxassetid://10709803109",
    ["activity"] = "rbxassetid://10709752035",
    ["pulse"] = "rbxassetid://10709752035",
    ["stats"] = "rbxassetid://10709752035",
    ["gauge"] = "rbxassetid://10709796495",
    ["speed"] = "rbxassetid://10709796495",

    -- Files, Cloud & Data
    ["folder"] = "rbxassetid://10709796387",
    ["folder-plus"] = "rbxassetid://10709796280",
    ["file"] = "rbxassetid://10709795643",
    ["file-text"] = "rbxassetid://10709795777",
    ["save"] = "rbxassetid://10709802641",
    ["cloud"] = "rbxassetid://10709793102",
    ["cloud-rain"] = "rbxassetid://10709792874",
    ["refresh-cw"] = "rbxassetid://10709802290",
    ["refresh"] = "rbxassetid://10709802290",
    ["reload"] = "rbxassetid://10709802290",
    ["sync"] = "rbxassetid://10709802290",
    ["search"] = "rbxassetid://10709802875",
    ["find"] = "rbxassetid://10709802875",
    ["trash"] = "rbxassetid://10734983637",
    ["trash-2"] = "rbxassetid://10709805449",
    ["delete"] = "rbxassetid://10734983637",
    ["copy"] = "rbxassetid://10709793917",
    ["clipboard"] = "rbxassetid://10709792158",
    ["download"] = "rbxassetid://10709794964",
    ["upload"] = "rbxassetid://10709805917",

    -- Users & Social
    ["user"] = "rbxassetid://10734988677",
    ["user-check"] = "rbxassetid://10709806034",
    ["user-plus"] = "rbxassetid://10709806268",
    ["user-minus"] = "rbxassetid://10709806151",
    ["user-x"] = "rbxassetid://10709806385",
    ["users"] = "rbxassetid://10734989047",
    ["player"] = "rbxassetid://10734988677",
    ["players"] = "rbxassetid://10734989047",
    ["team"] = "rbxassetid://10734989047",
    ["group"] = "rbxassetid://10734989047",

    -- Media & Playback
    ["play"] = "rbxassetid://10709801822",
    ["pause"] = "rbxassetid://10709801588",
    ["volume"] = "rbxassetid://10709806736",
    ["volume-1"] = "rbxassetid://10709806853",
    ["volume-2"] = "rbxassetid://10709806970",
    ["volume-x"] = "rbxassetid://10709807087",
    ["music"] = "rbxassetid://10709801120",
    ["video"] = "rbxassetid://10709806502",
    ["camera"] = "rbxassetid://10709789686",
    ["mic"] = "rbxassetid://10709800067",
    ["mic-off"] = "rbxassetid://10709800184",

    -- Status & Alerts
    ["info"] = "rbxassetid://10709797960",
    ["alert-triangle"] = "rbxassetid://10709753149",
    ["warning"] = "rbxassetid://10709753149",
    ["warn"] = "rbxassetid://10709753149",
    ["alert-circle"] = "rbxassetid://10709752996",
    ["danger"] = "rbxassetid://10709752996",
    ["error"] = "rbxassetid://10709752996",
    ["help-circle"] = "rbxassetid://10709797430",
    ["question"] = "rbxassetid://10709797430",
    ["help"] = "rbxassetid://10709797430",

    -- Utilities & Misc
    ["lock"] = "rbxassetid://10709798779",
    ["unlock"] = "rbxassetid://10734987768",
    ["key"] = "rbxassetid://10709798082",
    ["wrench"] = "rbxassetid://10734990924",
    ["tool"] = "rbxassetid://10734990924",
    ["tools"] = "rbxassetid://10734990924",
    ["rocket"] = "rbxassetid://10709802524",
    ["globe"] = "rbxassetid://10709796727",
    ["sun"] = "rbxassetid://10734975252",
    ["moon"] = "rbxassetid://10709800652",
    ["compass"] = "rbxassetid://10709793737",
    ["navigation"] = "rbxassetid://10709801237",
    ["map"] = "rbxassetid://10709799248",
    ["map-pin"] = "rbxassetid://10709799365",
    ["hash"] = "rbxassetid://10709797086",
    ["tag"] = "rbxassetid://10709804864",
    ["external-link"] = "rbxassetid://10709795324",
    ["link"] = "rbxassetid://10709798544",
    ["gift"] = "rbxassetid://10709796614",
    ["book"] = "rbxassetid://10709781824",
    ["book-open"] = "rbxassetid://10709781717",
    ["clock"] = "rbxassetid://10709792629",
    ["time"] = "rbxassetid://10709792629",
    ["timer"] = "rbxassetid://10709792629",
    ["power"] = "rbxassetid://10709802056",
    ["wifi"] = "rbxassetid://10709807204",
    ["wifi-off"] = "rbxassetid://10709807321",
    ["bluetooth"] = "rbxassetid://10709776655",
    ["message-circle"] = "rbxassetid://10709799833",
    ["message-square"] = "rbxassetid://10709799950",
    ["chat"] = "rbxassetid://10709799950",
    ["coins"] = "rbxassetid://10709770178",
    ["dollar-sign"] = "rbxassetid://10709794833",
    ["credit-card"] = "rbxassetid://10709794247",
    ["edit"] = "rbxassetid://10709795100",
    ["edit-2"] = "rbxassetid://10709795032",
    ["edit-3"] = "rbxassetid://10709795175",
    ["maximize"] = "rbxassetid://9886659406",
    ["menu"] = "rbxassetid://10709799716",
    ["more-horizontal"] = "rbxassetid://10709800769",
    ["more-vertical"] = "rbxassetid://10709800886",
    ["minus"] = "rbxassetid://10709800535",
    ["plus"] = "rbxassetid://10709801939",
    ["package"] = "rbxassetid://10709801354",
    ["send"] = "rbxassetid://10709802992",
    ["shopping-bag"] = "rbxassetid://10709803694",
    ["shopping-cart"] = "rbxassetid://10709803811",
    ["shuffle"] = "rbxassetid://10709803928",
    ["smartphone"] = "rbxassetid://10709804045",
    ["smile"] = "rbxassetid://10709804162",
    ["speaker"] = "rbxassetid://10709804279",
    ["square"] = "rbxassetid://10709804396",
    ["circle"] = "rbxassetid://10709791873",
    ["circle-dot"] = "rbxassetid://10709791873",
    ["table"] = "rbxassetid://10709804630",
    ["tablet"] = "rbxassetid://10709804747",
    ["thumbs-up"] = "rbxassetid://10709805098",
    ["thumbs-down"] = "rbxassetid://10709804981",
    ["toggle-left"] = "rbxassetid://10709805215",
    ["toggle-right"] = "rbxassetid://10709805332",
    ["trending-up"] = "rbxassetid://10709805683",
    ["trending-down"] = "rbxassetid://10709805566",
    ["tv"] = "rbxassetid://10709805800",
    ["zoom-in"] = "rbxassetid://10709807906",
    ["zoom-out"] = "rbxassetid://10709808023",
}

local CommonAliases = {
    ["slider"] = "sliders",
    ["control"] = "sliders",
    ["swords"] = "sword",
    ["close"] = "x",
    ["cancel"] = "x",
    ["minimize"] = "chevron-up",
    ["min"] = "chevron-up",
    ["maximize"] = "maximize",
    ["gear"] = "settings",
    ["cog"] = "settings",
    ["warn"] = "alert-triangle",
    ["warning"] = "alert-triangle",
    ["danger"] = "alert-circle",
    ["error"] = "alert-circle",
    ["hp"] = "heart",
    ["health"] = "heart",
    ["boxes"] = "box",
    ["cube"] = "box",
    ["fire"] = "flame",
    ["lightning"] = "zap",
    ["pointer"] = "mouse-pointer",
}

local IconEngine = {
    DefaultType = "lucide",
    Icons = BuiltinIcons,
}

function IconEngine.SetIconsType(iconType)
    IconEngine.DefaultType = iconType and iconType:lower() or "lucide"
end

function IconEngine.PreloadAsync(setName) end
function IconEngine.LoadSet(setName) return BuiltinIcons end

function IconEngine.GetIcon(iconQuery)
    if not iconQuery or iconQuery == "" then return BuiltinIcons["sparkles"] end
    if type(iconQuery) ~= "string" then
        if tonumber(iconQuery) then
            return "rbxthumb://type=Decal&id=" .. tostring(iconQuery) .. "&w=420&h=420"
        end
        return BuiltinIcons["sparkles"]
    end
    if iconQuery:sub(1, 12) == "rbxthumb://" then return iconQuery end
    if iconQuery:sub(1, 13) == "rbxassetid://" then
        local rawNum = iconQuery:sub(14)
        if tonumber(rawNum) and #rawNum >= 10 then
            return "rbxthumb://type=Decal&id=" .. rawNum .. "&w=420&h=420"
        end
        return iconQuery
    end
    if tonumber(iconQuery) then
        return "rbxthumb://type=Decal&id=" .. iconQuery .. "&w=420&h=420"
    end

    local iconName = iconQuery
    if iconQuery:find(":") then
        local parts = iconQuery:split(":")
        iconName = parts[2] or parts[1]
    elseif iconQuery:find("^lucide%-") then
        iconName = iconQuery:gsub("^lucide%-", "")
    elseif iconQuery:find("^solar%-") then
        iconName = iconQuery:gsub("^solar%-", "")
    elseif iconQuery:find("^craft%-") then
        iconName = iconQuery:gsub("^craft%-", "")
    elseif iconQuery:find("^geist%-") then
        iconName = iconQuery:gsub("^geist%-", "")
    elseif iconQuery:find("^sfsymbols%-") then
        iconName = iconQuery:gsub("^sfsymbols%-", "")
    end

    local cleanName = iconName:lower():gsub("_", "-"):gsub("%s+", "-")
    if BuiltinIcons[cleanName] then return BuiltinIcons[cleanName] end
    if CommonAliases[cleanName] and BuiltinIcons[CommonAliases[cleanName]] then
        return BuiltinIcons[CommonAliases[cleanName]]
    end
    return BuiltinIcons["sparkles"]
end

function IconEngine.ApplyDecal(imageLabel, rawQuery)
    if not imageLabel then return end
    local queryStr = tostring(rawQuery or "")
    local cleanNum = queryStr:gsub("rbxassetid://", ""):gsub("rbxthumb://type=%a+&id=", ""):gsub("&.*", ""):match("%d+")
    
    if cleanNum and #cleanNum >= 6 then
        imageLabel.Image = "rbxthumb://type=Decal&id=" .. cleanNum .. "&w=420&h=420"
    else
        imageLabel.Image = IconEngine.GetIcon(rawQuery)
    end

    local customAssetFn = getcustomasset or getsynasset
    if cleanNum and customAssetFn and writefile and readfile and isfile and makefolder then
        local cacheFolder = "HoshiHub"
        if isfolder and not isfolder(cacheFolder) then pcall(makefolder, cacheFolder) end
        local cacheFile = cacheFolder .. "/Asset_" .. cleanNum .. ".png"

        if isfile(cacheFile) then
            local s, asset = pcall(customAssetFn, cacheFile)
            if s and asset then
                imageLabel.Image = asset
                return
            end
        end

        task.spawn(function()
            local cdnUrl
            if cleanNum == "95445676600352" then
                cdnUrl = "https://tr.rbxcdn.com/180DAY-299908871c7597ad2f85e220058de002/420/420/Decal/Png/noFilter"
            else
                local apiSuccess, response = pcall(function()
                    return game:HttpGet("https://thumbnails.roblox.com/v1/assets?assetIds=" .. cleanNum .. "&size=420x420&format=Png&isCircular=false")
                end)
                if apiSuccess and response then
                    local decodeSuccess, parsed = pcall(function() return HttpService:JSONDecode(response) end)
                    if decodeSuccess and parsed and parsed.data and parsed.data[1] and parsed.data[1].imageUrl then
                        cdnUrl = parsed.data[1].imageUrl
                    end
                end
            end

            if cdnUrl then
                local imgSuccess, imgBytes = pcall(function() return game:HttpGet(cdnUrl) end)
                if imgSuccess and imgBytes and #imgBytes > 0 then
                    pcall(writefile, cacheFile, imgBytes)
                    local s, asset = pcall(customAssetFn, cacheFile)
                    if s and asset and imageLabel and imageLabel.Parent then
                        imageLabel.Image = asset
                    end
                end
            end
        end)
    end
end

-- ==============================================================================
-- 5. CONFIG PERSISTENCE ENGINE
-- ==============================================================================
local ConfigManager = {
    Folder = "HoshiHub",
    File = "Config.json",
    AutoSave = true,
    Flags = {},
    Signals = {}
}

function ConfigManager:Init(folderName, fileName, autoSave)
    self.Folder = folderName or "HoshiHub"
    self.File = fileName or "Config.json"
    self.AutoSave = (autoSave ~= false)
    if makefolder and isfolder and not isfolder(self.Folder) then
        pcall(makefolder, self.Folder)
    end
    if self.AutoSave then
        self:Load()
    end
end

function ConfigManager:Set(flag, value)
    if not flag then return end
    self.Flags[flag] = value
    if self.Signals[flag] then self.Signals[flag]:Fire(value) end
    if self.AutoSave then self:Save() end
end

function ConfigManager:Get(flag, defaultValue)
    if self.Flags[flag] ~= nil then return self.Flags[flag] end
    return defaultValue
end

function ConfigManager:Save()
    if not writefile then return end
    if makefolder and isfolder and not isfolder(self.Folder) then
        pcall(makefolder, self.Folder)
    end
    local filePath = self.Folder .. "/" .. self.File
    local data = {}
    for k, v in pairs(self.Flags) do
        if typeof(v) == "Color3" then
            data[k] = { __type = "Color3", r = v.R, g = v.G, b = v.B }
        elseif typeof(v) == "EnumItem" then
            data[k] = { __type = "EnumItem", enum = tostring(v.EnumType), name = v.Name }
        else
            data[k] = v
        end
    end
    local success, json = pcall(function() return HttpService:JSONEncode(data) end)
    if success and json then pcall(writefile, filePath, json) end
end

function ConfigManager:Load()
    if not readfile or not isfile then return false end
    local filePath = self.Folder .. "/" .. self.File
    if not isfile(filePath) then return false end
    local success, content = pcall(readfile, filePath)
    if not success or not content or content == "" then return false end
    local parseSuccess, parsed = pcall(function() return HttpService:JSONDecode(content) end)
    if not parseSuccess or type(parsed) ~= "table" then return false end
    for k, v in pairs(parsed) do
        if type(v) == "table" and v.__type == "Color3" then
            self.Flags[k] = Color3.new(v.r, v.g, v.b)
        elseif type(v) == "table" and v.__type == "EnumItem" then
            local enumType = Enum[v.enum]
            if enumType and enumType[v.name] then self.Flags[k] = enumType[v.name] end
        else
            self.Flags[k] = v
        end
        if self.Signals[k] then self.Signals[k]:Fire(self.Flags[k]) end
    end
    return true
end

function ConfigManager:Export()
    local success, json = pcall(function() return HttpService:JSONEncode(self.Flags) end)
    return success and json or "{}"
end

-- ==============================================================================
-- 6. CREATOR ENGINE FACTORY
-- ==============================================================================
local Creator = {
    ThemeTags = {},
    Signals = {},
    ActiveTheme = nil,
    ActiveThemeName = "Dark",
}

function Creator.GetSafeGuiParent()
    local success, hui = pcall(function() return (gethui or get_hidden_ui)() end)
    if success and hui then return hui end
    local cSuccess, coregui = pcall(function() return CoreGui end)
    if cSuccess and coregui then return coregui end
    return LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("StarterGui")
end

function Creator.New(className, properties, children)
    local instance = Instance.new(className)
    properties = properties or {}
    children = children or {}
    local themeTag = properties.ThemeTag
    properties.ThemeTag = nil

    for prop, val in pairs(properties) do
        pcall(function() instance[prop] = val end)
    end
    for _, child in ipairs(children) do
        if typeof(child) == "Instance" then child.Parent = instance end
    end
    if themeTag and type(themeTag) == "table" then
        Creator.ThemeTags[instance] = themeTag
        if Creator.ActiveTheme then
            Creator.ApplyThemeTag(instance, themeTag, Creator.ActiveTheme)
        end
    end
    return instance
end

function Creator.AddCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
    return corner
end

function Creator.AddStroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = color or Color3.fromRGB(40, 44, 58)
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.Parent = instance
    return stroke
end

function Creator.AddPadding(instance, top, bottom, left, right)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, top or 0)
    pad.PaddingBottom = UDim.new(0, bottom or top or 0)
    pad.PaddingLeft = UDim.new(0, left or top or 0)
    pad.PaddingRight = UDim.new(0, right or left or top or 0)
    pad.Parent = instance
    return pad
end

function Creator.Tween(instance, properties, duration, style, direction)
    if not instance then return nil end
    local tweenInfo = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local anim = TweenService:Create(instance, tweenInfo, properties)
    anim:Play()
    return anim
end

function Creator.AddSignal(rbxSignal, fn)
    local connection = rbxSignal:Connect(fn)
    table.insert(Creator.Signals, connection)
    return connection
end

function Creator.Disconnect()
    for _, conn in ipairs(Creator.Signals) do
        if typeof(conn) == "RBXScriptConnection" and conn.Connected then
            conn:Disconnect()
        elseif conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    Creator.Signals = {}
end

function Creator.MakeDraggable(dragBar, mainFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    Creator.AddSignal(dragBar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Creator.AddSignal(dragBar.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    Creator.AddSignal(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Creator.ApplyThemeTag(instance, themeTag, theme)
    for prop, themeKey in pairs(themeTag) do
        if theme[themeKey] then
            pcall(function() instance[prop] = theme[themeKey] end)
        end
    end
end

function Creator.UpdateTheme(newTheme, newThemeName)
    Creator.ActiveTheme = newTheme
    Creator.ActiveThemeName = newThemeName
    for inst, tag in pairs(Creator.ThemeTags) do
        if inst and inst.Parent then
            Creator.ApplyThemeTag(inst, tag, newTheme)
        else
            Creator.ThemeTags[inst] = nil
        end
    end
end

-- ==============================================================================
-- 7. NOTIFICATION MANAGER
-- ==============================================================================
local NotificationManager = {}

function NotificationManager.Init(screenGui)
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

function NotificationManager.Notify(holder, notifConfig, theme)
    notifConfig = notifConfig or {}
    local title = notifConfig.Title or "Notification"
    local content = notifConfig.Content or ""
    local notifType = notifConfig.Type or "Info"
    local duration = notifConfig.Duration or 3.5
    local rawIcon = notifConfig.Icon or "bell"
    local icon = IconEngine.GetIcon(rawIcon)
    local isCustomNotif = (type(rawIcon) == "number" or tonumber(rawIcon) or tostring(rawIcon):find("^rbxthumb://") or (tostring(rawIcon):find("^rbxassetid://") and tonumber(tostring(rawIcon):sub(14)))) ~= nil

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

    Creator.New("Frame", {
        Name = "SideBar",
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = typeColor,
        Parent = notifFrame
    })

    local notifIco = Creator.New("ImageLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundTransparency = 1,
        Image = icon,
        ImageColor3 = isCustomNotif and Color3.fromRGB(255, 255, 255) or typeColor,
        ScaleType = Enum.ScaleType.Fit,
        Parent = notifFrame
    })
    if isCustomNotif then
        Creator.AddCorner(notifIco, 4)
    end

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

    local progressBar = Creator.New("Frame", {
        Name = "Progress",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = typeColor,
        Parent = notifFrame
    })

    task.spawn(function()
        task.wait(0.02)
        local targetH = math.max(60, descLabel.TextBounds.Y + 44)
        Creator.Tween(notifFrame, { Size = UDim2.new(1, 0, 0, targetH) }, 0.22, Enum.EasingStyle.Back)
        Creator.Tween(progressBar, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)
        task.wait(duration)
        local closeAnim = Creator.Tween(notifFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.2, Enum.EasingStyle.Sine)
        if closeAnim then
            closeAnim.Completed:Connect(function() notifFrame:Destroy() end)
        else
            notifFrame:Destroy()
        end
    end)
end

-- ==============================================================================
-- 8. DIALOG MODAL COMPONENT (Adaptive Button Grid & Text Fitting)
-- ==============================================================================
local DialogManager = {}

function DialogManager.Open(screenGui, dialogConfig, theme)
    dialogConfig = dialogConfig or {}
    local title = dialogConfig.Title or "Dialog"
    local content = dialogConfig.Content or ""
    local buttons = dialogConfig.Buttons or { { Text = "OK", Variant = "Primary" } }
    local numButtons = math.max(1, #buttons)

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

    local dialogWidth = math.clamp(numButtons * 80 + 40, 360, 520)
    local dialogBox = Creator.New("Frame", {
        Name = "DialogBox",
        Size = UDim2.new(0, dialogWidth, 0, 175),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.CardBackground,
        ZIndex = 101,
        Parent = modalOverlay
    })
    Creator.AddCorner(dialogBox, 10)
    Creator.AddStroke(dialogBox, theme.Border, 1)

    local dScale = Creator.New("UIScale", { Scale = 0.85, Parent = dialogBox })

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
        Padding = UDim.new(0, 6),
        Parent = btnContainer
    })

    local function closeDialog()
        Creator.Tween(modalOverlay, { BackgroundTransparency = 1 }, 0.15)
        local anim = Creator.Tween(dScale, { Scale = 0.85 }, 0.15, Enum.EasingStyle.Sine)
        if anim then
            anim.Completed:Connect(function() modalOverlay:Destroy() end)
        else
            modalOverlay:Destroy()
        end
    end

    local btnWidthScale = 1 / numButtons
    local btnOffsetGap = numButtons > 1 and math.floor(((numButtons - 1) * 6) / numButtons) or 0

    for idx, btnData in ipairs(buttons) do
        local bVariant = btnData.Variant or "Secondary"
        local bBg = theme.Background
        local bText = theme.Text
        if bVariant == "Primary" then bBg = theme.Accent bText = Color3.fromRGB(255, 255, 255)
        elseif bVariant == "Danger" then bBg = theme.Danger bText = Color3.fromRGB(255, 255, 255) end

        local dBtn = Creator.New("TextButton", {
            Name = "Btn_" .. idx .. "_" .. (btnData.Text or "Action"),
            Size = UDim2.new(btnWidthScale, -btnOffsetGap, 1, 0),
            BackgroundColor3 = bBg,
            AutoButtonColor = false,
            Text = btnData.Text or "Action",
            TextColor3 = bText,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = idx,
            ZIndex = 103,
            Parent = btnContainer
        })
        Creator.AddCorner(dBtn, 6)
        dBtn.MouseButton1Click:Connect(function()
            closeDialog()
            if btnData.Callback then pcall(btnData.Callback) end
        end)
    end

    Creator.Tween(modalOverlay, { BackgroundTransparency = 0.5 }, 0.2)
    Creator.Tween(dScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back)
end

-- ==============================================================================
-- 9. MAIN WINDOW COMPONENT FACTORY (Resizable & Dynamic Scaling)
-- ==============================================================================
local HoshiUI = {
    Version = "2.0.0",
    Windows = {},
    Icons = IconEngine,
    Themes = Themes,
}

function HoshiUI:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "Hoshi Hub"
    local windowSubTitle = config.SubTitle or "v2.0"
    local themeName = config.Theme or "Dark"
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightControl
    local hasFloating = config.FloatingButton or false
    local configFolder = config.Folder or "HoshiHub"
    local configFile = config.ConfigFile or "Config.json"
    local autoSave = (config.AutoSave ~= false)
    local isResizable = (config.Resizable ~= false)
    local initialScale = config.Scale or 1.0

    if getgenv then
        local active = getgenv().HoshiHub_ActiveWindow
        if active and active.Destroy then pcall(active.Destroy, active) end
    end

    local safeParent = Creator.GetSafeGuiParent()
    local existingGui = safeParent:FindFirstChild("HoshiUI_Root")
    if existingGui then pcall(existingGui.Destroy, existingGui) end

    local defaultThemeName = config.Theme or "Hoshi"
    local theme = Themes[defaultThemeName] or Themes["Hoshi"] or Themes["Dark"]
    Creator.ActiveTheme = theme
    Creator.ActiveThemeName = defaultThemeName

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

    local notifHolder = NotificationManager.Init(screenGui)

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

    local uiScale = Creator.New("UIScale", { Scale = initialScale, Parent = mainFrame })

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

    local topBar = Creator.New("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 1,
        Parent = mainFrame
    })

    local rawHeaderIcon = config.Icon or "95445676600352"
    local isHeaderCustomAsset = type(rawHeaderIcon) == "number" or tonumber(rawHeaderIcon) ~= nil or tostring(rawHeaderIcon):find("^rbxthumb://") or tostring(rawHeaderIcon):find("^rbxassetid://") or tostring(rawHeaderIcon):find("%d%d%d%d%d%d")

    local headImg = Creator.New("ImageLabel", {
        Name = "HeaderIcon",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 14, 0.5, -12),
        BackgroundTransparency = 1,
        ImageColor3 = isHeaderCustomAsset and Color3.fromRGB(255, 255, 255) or theme.Accent,
        ScaleType = Enum.ScaleType.Fit,
        Parent = topBar
    })
    if isHeaderCustomAsset then
        Creator.AddCorner(headImg, 6)
        IconEngine.ApplyDecal(headImg, rawHeaderIcon)
    else
        headImg.Image = IconEngine.GetIcon(rawHeaderIcon)
    end

    local titleContainer = Creator.New("Frame", {
        Name = "TitleContainer",
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(0, 44, 0, 0),
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

    local function createTopBarButton(name, iconId, hoverColor, layoutOrder, onClick)
        local btn = Creator.New("ImageButton", {
            Name = name,
            Size = UDim2.new(0, 28, 0, 28),
            BackgroundColor3 = theme.CardBackground,
            AutoButtonColor = false,
            LayoutOrder = layoutOrder or 1,
            Parent = actionsContainer
        })
        Creator.AddCorner(btn, 6)
        Creator.AddStroke(btn, theme.Border, 1)

        local ico = Creator.New("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0.5, -7, 0.5, -7),
            BackgroundTransparency = 1,
            Image = IconEngine.GetIcon(iconId) or iconId,
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
        if forcedState ~= nil then isVisible = forcedState else isVisible = not isVisible end
        if isVisible then
            mainFrame.Visible = true
            uiScale.Scale = 0.88 * initialScale
            Creator.Tween(uiScale, { Scale = initialScale }, 0.2, Enum.EasingStyle.Back)
        else
            local anim = Creator.Tween(uiScale, { Scale = 0.88 * initialScale }, 0.15, Enum.EasingStyle.Sine)
            if anim then
                anim.Completed:Connect(function() if not isVisible then mainFrame.Visible = false end end)
            else
                mainFrame.Visible = false
            end
        end
    end

    -- Topbar Buttons (Minimize layoutOrder 1 = Left, Close layoutOrder 2 = Right)
    createTopBarButton("Minimize", "chevron-up", theme.CardHover, 1, function()
        isMinimized = not isMinimized
        if isMinimized then
            Creator.Tween(mainFrame, { Size = UDim2.new(0, mainFrame.AbsoluteSize.X, 0, 48) }, 0.22)
        else
            Creator.Tween(mainFrame, { Size = originalSize }, 0.22)
        end
    end)

    createTopBarButton("Close", "x", Color3.fromRGB(180, 40, 50), 2, function()
        toggleWindow(false)
    end)

    Creator.MakeDraggable(topBar, mainFrame)

    local body = Creator.New("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -48),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = mainFrame
    })

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

    local contentArea = Creator.New("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -183, 1, 0),
        Position = UDim2.new(0, 183, 0, 0),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 1,
        Parent = body
    })

    -- Interactive Resize Handle (Bottom-Right Drag Grip)
    if isResizable then
        local resizeHandle = Creator.New("ImageButton", {
            Name = "ResizeHandle",
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(1, -18, 1, -18),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            ZIndex = 40,
            Parent = mainFrame
        })

        Creator.New("ImageLabel", {
            Name = "Grip",
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(1, -12, 1, -12),
            BackgroundTransparency = 1,
            Image = "rbxassetid://10709791624",
            ImageColor3 = theme.SubText,
            ImageTransparency = 0.4,
            Rotation = 45,
            Parent = resizeHandle
        })

        local isResizing = false
        local resizeStartMouse, initialFrameSize

        Creator.AddSignal(resizeHandle.InputBegan, function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not isMinimized then
                isResizing = true
                resizeStartMouse = input.Position
                initialFrameSize = mainFrame.AbsoluteSize
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        isResizing = false
                    end
                end)
            end
        end)

        Creator.AddSignal(UserInputService.InputChanged, function(input)
            if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - resizeStartMouse
                local vp = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
                local minW, minH = 460, 320
                local maxW = math.max(minW, vp.X - 24)
                local maxH = math.max(minH, vp.Y - 24)

                local newW = math.clamp(initialFrameSize.X + delta.X, minW, maxW)
                local newH = math.clamp(initialFrameSize.Y + delta.Y, minH, maxH)

                mainFrame.Size = UDim2.new(0, newW, 0, newH)
                originalSize = mainFrame.Size
            end
        end)

        Creator.AddSignal(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isResizing = false
            end
        end)
    end

    local floatingBtn = nil
    if hasFloating then
        local rawFloatIcon = config.FloatingIcon or config.Icon or "95445676600352"
        local isFloatCustomAsset = type(rawFloatIcon) == "number" or tonumber(rawFloatIcon) ~= nil or tostring(rawFloatIcon):find("^rbxthumb://") or tostring(rawFloatIcon):find("^rbxassetid://") or tostring(rawFloatIcon):find("%d%d%d%d%d%d")

        floatingBtn = Creator.New("ImageButton", {
            Name = "FloatingToggle",
            Size = UDim2.new(0, 48, 0, 48),
            Position = UDim2.new(0, 24, 0.5, -24),
            BackgroundColor3 = theme.Background,
            AutoButtonColor = false,
            ZIndex = 50,
            Parent = screenGui
        })
        Creator.AddCorner(floatingBtn, 12)
        local floatStroke = Creator.AddStroke(floatingBtn, theme.Accent, 1.5)

        Creator.New("ImageLabel", {
            Name = "Shadow",
            Size = UDim2.new(1, 16, 1, 16),
            Position = UDim2.new(0, -8, 0, -8),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6015897843",
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = 0.5,
            SliceCenter = Rect.new(49, 49, 450, 450),
            ScaleType = Enum.ScaleType.Slice,
            ZIndex = 49,
            Parent = floatingBtn
        })

        local floatImg = Creator.New("ImageLabel", {
            Name = "Icon",
            Size = isFloatCustomAsset and UDim2.new(1, -4, 1, -4) or UDim2.new(0, 22, 0, 22),
            Position = isFloatCustomAsset and UDim2.new(0, 2, 0, 2) or UDim2.new(0.5, -11, 0.5, -11),
            BackgroundTransparency = 1,
            ImageColor3 = isFloatCustomAsset and Color3.fromRGB(255, 255, 255) or theme.Accent,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 51,
            Parent = floatingBtn
        })
        if isFloatCustomAsset then
            Creator.AddCorner(floatImg, 10)
            IconEngine.ApplyDecal(floatImg, rawFloatIcon)
        else
            floatImg.Image = IconEngine.GetIcon(rawFloatIcon)
        end

        floatingBtn.MouseEnter:Connect(function()
            Creator.Tween(floatingBtn, { Size = UDim2.new(0, 52, 0, 52), Position = UDim2.new(0, 22, 0.5, -26) }, 0.18, Enum.EasingStyle.Back)
            Creator.Tween(floatStroke, { Color = theme.AccentHover, Thickness = 2 }, 0.18)
        end)
        floatingBtn.MouseLeave:Connect(function()
            Creator.Tween(floatingBtn, { Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0, 24, 0.5, -24) }, 0.18, Enum.EasingStyle.Back)
            Creator.Tween(floatStroke, { Color = theme.Accent, Thickness = 1.5 }, 0.18)
        end)

        Creator.MakeDraggable(floatingBtn, floatingBtn)
        floatingBtn.MouseButton1Click:Connect(function() toggleWindow() end)
    end

    Creator.AddSignal(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then toggleWindow() end
    end)

    local Window = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        Scale = uiScale,
        Tabs = {},
        ConfigManager = ConfigManager,
        Themes = Themes,
        ActiveTheme = theme,
        ActiveThemeName = defaultThemeName,
    }

    function Window:SetScale(scaleValue)
        initialScale = math.clamp(scaleValue or 1.0, 0.5, 2.0)
        Creator.Tween(uiScale, { Scale = initialScale }, 0.18)
    end

    function Window:GetScale()
        return uiScale.Scale
    end

    function Window:SetTheme(themeInput)
        local targetTheme = Themes[themeInput]
        local targetName = themeInput
        if type(themeInput) == "table" then
            targetTheme = themeInput
            targetName = "Custom"
        elseif not targetTheme then
            targetTheme = Themes["Hoshi"] or Themes["Dark"]
            targetName = "Hoshi"
        end
        Window.ActiveTheme = targetTheme
        Window.ActiveThemeName = targetName
        Creator.UpdateTheme(targetTheme, targetName)
        mainFrame.BackgroundColor3 = targetTheme.Background
        mainStroke.Color = targetTheme.Border
        sidebar.BackgroundColor3 = targetTheme.Sidebar
    end

    function Window:SetFloatingVisible(visible)
        if floatingBtn then
            floatingBtn.Visible = (visible ~= false)
        end
    end

    if getgenv then getgenv().HoshiHub_ActiveWindow = Window end

    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabTitle = tabConfig.Title or "Tab"
        local tabIcon = IconEngine.GetIcon(tabConfig.Icon or "folder")

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

        local Tab = { Button = tabBtn, Page = page, Window = Window }

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

        -- Element: Section
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
            return Creator.New("Frame", {
                Name = "Divider",
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = theme.Border,
                BorderSizePixel = 0,
                Parent = page
            })
        end

        function Tab:CreateParagraph(paraConfig)
            paraConfig = paraConfig or {}
            local pTitle = paraConfig.Title or "Information"
            local pContent = paraConfig.Content or ""
            local pIcon = paraConfig.Icon and IconEngine.GetIcon(paraConfig.Icon) or IconEngine.GetIcon("info")

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
            Creator.New("UIListLayout", { Padding = UDim.new(0, 4), Parent = pCard })

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

        -- Element: Button
        function Tab:CreateButton(btnConfig)
            btnConfig = btnConfig or {}
            local bTitle = btnConfig.Title or "Button"
            local bDesc = btnConfig.Desc or ""
            local bIcon = btnConfig.Icon and IconEngine.GetIcon(btnConfig.Icon) or nil
            local variant = btnConfig.Variant or "Secondary"
            local callback = btnConfig.Callback or function() end

            local bgColor = theme.CardBackground
            local hoverColor = theme.CardHover
            local strokeColor = theme.Border
            local textColor = theme.Text

            if variant == "Primary" then
                bgColor = theme.Accent hoverColor = theme.AccentHover strokeColor = theme.AccentHover textColor = Color3.fromRGB(255, 255, 255)
            elseif variant == "Danger" then
                bgColor = Color3.fromRGB(180, 40, 50) hoverColor = Color3.fromRGB(210, 50, 60) strokeColor = Color3.fromRGB(230, 60, 70) textColor = Color3.fromRGB(255, 255, 255)
            end

            local btnFrame = Creator.New("TextButton", {
                Name = "Button_" .. bTitle,
                Size = UDim2.new(1, 0, 0, bDesc ~= "" and 48 or 38),
                BackgroundColor3 = bgColor,
                AutoButtonColor = false,
                Text = "",
                Parent = page
            })
            Creator.AddCorner(btnFrame, 8)
            Creator.AddStroke(btnFrame, strokeColor, 1)

            local offset = 12
            if bIcon then
                Creator.New("ImageLabel", {
                    Name = "Icon",
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(0, 12, 0.5, -9),
                    BackgroundTransparency = 1,
                    Image = bIcon,
                    ImageColor3 = textColor,
                    Parent = btnFrame
                })
                offset = 38
            end

            local tLabel = Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -offset - 12, 0, bDesc ~= "" and 20 or 38),
                Position = UDim2.new(0, offset, 0, bDesc ~= "" and 6 or 0),
                BackgroundTransparency = 1,
                Text = bTitle,
                TextColor3 = textColor,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = btnFrame
            })
            if bDesc ~= "" then
                Creator.New("TextLabel", {
                    Name = "Desc",
                    Size = UDim2.new(1, -offset - 12, 0, 16),
                    Position = UDim2.new(0, offset, 0, 24),
                    BackgroundTransparency = 1,
                    Text = bDesc,
                    TextColor3 = variant == "Secondary" and theme.SubText or Color3.fromRGB(220, 220, 230),
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = btnFrame
                })
            end

            btnFrame.MouseEnter:Connect(function() Creator.Tween(btnFrame, { BackgroundColor3 = hoverColor }, 0.15) end)
            btnFrame.MouseLeave:Connect(function() Creator.Tween(btnFrame, { BackgroundColor3 = bgColor }, 0.15) end)
            btnFrame.MouseButton1Click:Connect(function() pcall(callback) end)
            return {
                Instance = btnFrame,
                SetTitle = function(_, t) tLabel.Text = t end,
                SetCallback = function(_, cb) callback = cb end
            }
        end

        -- Element: Toggle
        function Tab:CreateToggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            local tTitle = toggleConfig.Title or "Toggle"
            local tDesc = toggleConfig.Desc or ""
            local flag = toggleConfig.Flag
            local default = toggleConfig.Default or false
            local callback = toggleConfig.Callback or function() end

            if flag then
                local saved = ConfigManager:Get(flag)
                if saved ~= nil then default = saved else ConfigManager:Set(flag, default) end
            end

            local state = default
            local toggleCard = Creator.New("TextButton", {
                Name = "Toggle_" .. tTitle,
                Size = UDim2.new(1, 0, 0, tDesc ~= "" and 52 or 42),
                BackgroundColor3 = theme.CardBackground,
                AutoButtonColor = false,
                Text = "",
                Parent = page
            })
            Creator.AddCorner(toggleCard, 8)
            Creator.AddStroke(toggleCard, theme.Border, 1)

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -70, 0, tDesc ~= "" and 20 or 42),
                Position = UDim2.new(0, 14, 0, tDesc ~= "" and 8 or 0),
                BackgroundTransparency = 1,
                Text = tTitle,
                TextColor3 = theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = toggleCard
            })
            if tDesc ~= "" then
                Creator.New("TextLabel", {
                    Name = "Desc",
                    Size = UDim2.new(1, -70, 0, 16),
                    Position = UDim2.new(0, 14, 0, 28),
                    BackgroundTransparency = 1,
                    Text = tDesc,
                    TextColor3 = theme.SubText,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = toggleCard
                })
            end

            local pill = Creator.New("Frame", {
                Name = "Pill",
                Size = UDim2.new(0, 40, 0, 22),
                Position = UDim2.new(1, -54, 0.5, -11),
                BackgroundColor3 = state and theme.Accent or theme.ToggleOff,
                Parent = toggleCard
            })
            Creator.AddCorner(pill, 11)

            local knob = Creator.New("Frame", {
                Name = "Knob",
                Size = UDim2.new(0, 16, 0, 16),
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = pill
            })
            Creator.AddCorner(knob, 8)

            local function setState(newState, callCallback)
                state = newState
                if state then
                    Creator.Tween(pill, { BackgroundColor3 = theme.Accent }, 0.2)
                    Creator.Tween(knob, { Position = UDim2.new(1, -19, 0.5, -8) }, 0.2, Enum.EasingStyle.Back)
                else
                    Creator.Tween(pill, { BackgroundColor3 = theme.ToggleOff }, 0.2)
                    Creator.Tween(knob, { Position = UDim2.new(0, 3, 0.5, -8) }, 0.2, Enum.EasingStyle.Back)
                end
                if flag then ConfigManager:Set(flag, state) end
                if callCallback ~= false then pcall(callback, state) end
            end

            toggleCard.MouseButton1Click:Connect(function() setState(not state) end)
            toggleCard.MouseEnter:Connect(function() Creator.Tween(toggleCard, { BackgroundColor3 = theme.CardHover }, 0.15) end)
            toggleCard.MouseLeave:Connect(function() Creator.Tween(toggleCard, { BackgroundColor3 = theme.CardBackground }, 0.15) end)

            return {
                Instance = toggleCard,
                Value = state,
                Set = function(_, v) setState(v) end,
                SetValue = function(_, v) setState(v) end
            }
        end

        -- Element: Slider
        function Tab:CreateSlider(sliderConfig)
            sliderConfig = sliderConfig or {}
            local sTitle = sliderConfig.Title or "Slider"
            local sDesc = sliderConfig.Desc or ""
            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local step = sliderConfig.Step or 1
            local default = sliderConfig.Default or min
            local formatStr = sliderConfig.Format or "{value}"
            local flag = sliderConfig.Flag
            local callback = sliderConfig.Callback or function() end

            if flag then
                local saved = ConfigManager:Get(flag)
                if saved ~= nil then default = saved else ConfigManager:Set(flag, default) end
            end

            local value = math.clamp(default, min, max)
            local sliderCard = Creator.New("Frame", {
                Name = "Slider_" .. sTitle,
                Size = UDim2.new(1, 0, 0, sDesc ~= "" and 62 or 52),
                BackgroundColor3 = theme.CardBackground,
                Parent = page
            })
            Creator.AddCorner(sliderCard, 8)
            Creator.AddStroke(sliderCard, theme.Border, 1)

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -90, 0, 20),
                Position = UDim2.new(0, 14, 0, 8),
                BackgroundTransparency = 1,
                Text = sTitle,
                TextColor3 = theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = sliderCard
            })

            local valueLabel = Creator.New("TextLabel", {
                Name = "Value",
                Size = UDim2.new(0, 80, 0, 20),
                Position = UDim2.new(1, -94, 0, 8),
                BackgroundTransparency = 1,
                Text = formatStr:gsub("{value}", tostring(value)),
                TextColor3 = theme.Accent,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = sliderCard
            })

            if sDesc ~= "" then
                Creator.New("TextLabel", {
                    Name = "Desc",
                    Size = UDim2.new(1, -28, 0, 14),
                    Position = UDim2.new(0, 14, 0, 26),
                    BackgroundTransparency = 1,
                    Text = sDesc,
                    TextColor3 = theme.SubText,
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = sliderCard
                })
            end

            local trackPos = sDesc ~= "" and 44 or 34
            local track = Creator.New("TextButton", {
                Name = "Track",
                Size = UDim2.new(1, -28, 0, 6),
                Position = UDim2.new(0, 14, 0, trackPos),
                BackgroundColor3 = theme.ToggleOff,
                AutoButtonColor = false,
                Text = "",
                Parent = sliderCard
            })
            Creator.AddCorner(track, 3)

            local alpha = (value - min) / (max - min)
            local fill = Creator.New("Frame", {
                Name = "Fill",
                Size = UDim2.new(alpha, 0, 1, 0),
                BackgroundColor3 = theme.Accent,
                Parent = track
            })
            Creator.AddCorner(fill, 3)

            local thumb = Creator.New("Frame", {
                Name = "Thumb",
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(alpha, -7, 0.5, -7),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = track
            })
            Creator.AddCorner(thumb, 7)

            local function updateValue(newVal, callCallback)
                newVal = math.clamp(newVal, min, max)
                if step > 0 then newVal = math.floor((newVal - min) / step + 0.5) * step + min end
                value = newVal
                local curAlpha = math.clamp((value - min) / (max - min), 0, 1)
                fill.Size = UDim2.new(curAlpha, 0, 1, 0)
                thumb.Position = UDim2.new(curAlpha, -7, 0.5, -7)
                valueLabel.Text = formatStr:gsub("{value}", tostring(value))
                if flag then ConfigManager:Set(flag, value) end
                if callCallback ~= false then pcall(callback, value) end
            end

            local isDragging = false
            local function handleInput(input)
                local absX = track.AbsolutePosition.X
                local absW = track.AbsoluteSize.X
                local relAlpha = math.clamp((input.Position.X - absX) / absW, 0, 1)
                updateValue(min + (max - min) * relAlpha)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = true
                    handleInput(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    handleInput(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                end
            end)

            return {
                Instance = sliderCard,
                Value = value,
                Set = function(_, v) updateValue(v) end,
                SetValue = function(_, v) updateValue(v) end
            }
        end

        -- Element: Dropdown
        function Tab:CreateDropdown(dropdownConfig)
            dropdownConfig = dropdownConfig or {}
            local dTitle = dropdownConfig.Title or "Dropdown"
            local dDesc = dropdownConfig.Desc or ""
            local options = dropdownConfig.Options or {}
            local isMulti = dropdownConfig.Multi or false
            local default = dropdownConfig.Default or (isMulti and {} or options[1] or "")
            local flag = dropdownConfig.Flag
            local callback = dropdownConfig.Callback or function() end

            if flag then
                local saved = ConfigManager:Get(flag)
                if saved ~= nil then default = saved else ConfigManager:Set(flag, default) end
            end

            local selected = default
            local isOpen = false
            local cardHeight = dDesc ~= "" and 60 or 44

            local dropdownCard = Creator.New("Frame", {
                Name = "Dropdown_" .. dTitle,
                Size = UDim2.new(1, 0, 0, cardHeight),
                BackgroundColor3 = theme.CardBackground,
                ClipsDescendants = true,
                Parent = page
            })
            Creator.AddCorner(dropdownCard, 8)
            Creator.AddStroke(dropdownCard, theme.Border, 1)

            local headerBtn = Creator.New("TextButton", {
                Name = "Header",
                Size = UDim2.new(1, 0, 0, cardHeight),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                Parent = dropdownCard
            })

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -180, 0, dDesc ~= "" and 20 or cardHeight),
                Position = UDim2.new(0, 14, 0, dDesc ~= "" and 8 or 0),
                BackgroundTransparency = 1,
                Text = dTitle,
                TextColor3 = theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = headerBtn
            })

            if dDesc ~= "" then
                Creator.New("TextLabel", {
                    Name = "Desc",
                    Size = UDim2.new(1, -180, 0, 16),
                    Position = UDim2.new(0, 14, 0, 28),
                    BackgroundTransparency = 1,
                    Text = dDesc,
                    TextColor3 = theme.SubText,
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
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
                Image = IconEngine.GetIcon("chevron-down"),
                ImageColor3 = theme.SubText,
                Parent = selectedBadge
            })

            local listContainer = Creator.New("Frame", {
                Name = "List",
                Size = UDim2.new(1, -28, 0, 0),
                Position = UDim2.new(0, 14, 0, cardHeight + 4),
                BackgroundTransparency = 1,
                Parent = dropdownCard
            })
            local listLayout = Creator.New("UIListLayout", { Padding = UDim.new(0, 4), Parent = listContainer })
            local optionButtons = {}

            local function updateSelection(newVal, callCallback)
                selected = newVal
                selectedLabel.Text = getSelectedText()
                for optName, btnData in pairs(optionButtons) do
                    local isSel = isMulti and (type(selected) == "table" and table.find(selected, optName) ~= nil) or (selected == optName)
                    btnData.Indicator.Visible = isSel
                    btnData.Label.TextColor3 = isSel and theme.Accent or theme.Text
                    Creator.Tween(btnData.Button, { BackgroundColor3 = isSel and theme.Background or theme.CardHover }, 0.15)
                end
                if flag then ConfigManager:Set(flag, selected) end
                if callCallback ~= false then pcall(callback, selected) end
            end

            local function refreshOptions(newOptions)
                options = newOptions or {}
                for _, child in ipairs(listContainer:GetChildren()) do
                    if child:IsA("GuiObject") and child ~= listLayout then child:Destroy() end
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
                        Image = IconEngine.GetIcon("check"),
                        ImageColor3 = theme.Accent,
                        Visible = false,
                        Parent = optBtn
                    })

                    optionButtons[opt] = { Button = optBtn, Label = optLabel, Indicator = checkIco }
                    optBtn.MouseButton1Click:Connect(function()
                        if isMulti then
                            local curTable = type(selected) == "table" and selected or {}
                            local idx = table.find(curTable, opt)
                            if idx then table.remove(curTable, idx) else table.insert(curTable, opt) end
                            updateSelection(curTable)
                        else
                            updateSelection(opt)
                            isOpen = false
                            Creator.Tween(chevron, { Rotation = 0 }, 0.2)
                            Creator.Tween(dropdownCard, { Size = UDim2.new(1, 0, 0, cardHeight) }, 0.2)
                        end
                    end)
                end
                updateSelection(selected, false)
            end

            refreshOptions(options)

            headerBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local targetHeight = isOpen and (cardHeight + (#options * 34) + 10) or cardHeight
                Creator.Tween(chevron, { Rotation = isOpen and 180 or 0 }, 0.2)
                Creator.Tween(dropdownCard, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.22)
            end)

            return {
                Instance = dropdownCard,
                Value = selected,
                Set = function(_, v) updateSelection(v) end,
                SetOptions = function(_, o) refreshOptions(o) end
            }
        end

        -- Element: ColorPicker
        function Tab:CreateColorPicker(colorConfig)
            colorConfig = colorConfig or {}
            local cTitle = colorConfig.Title or "Color Picker"
            local cDesc = colorConfig.Desc or ""
            local default = colorConfig.Default or Color3.fromRGB(75, 130, 255)
            local flag = colorConfig.Flag
            local callback = colorConfig.Callback or function() end

            if flag then
                local saved = ConfigManager:Get(flag)
                if saved ~= nil then default = saved else ConfigManager:Set(flag, default) end
            end

            local color = default
            local cardHeight = cDesc ~= "" and 52 or 42
            local pickerCard = Creator.New("TextButton", {
                Name = "ColorPicker_" .. cTitle,
                Size = UDim2.new(1, 0, 0, cardHeight),
                BackgroundColor3 = theme.CardBackground,
                AutoButtonColor = false,
                Text = "",
                Parent = page
            })
            Creator.AddCorner(pickerCard, 8)
            Creator.AddStroke(pickerCard, theme.Border, 1)

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -70, 0, cDesc ~= "" and 20 or cardHeight),
                Position = UDim2.new(0, 14, 0, cDesc ~= "" and 8 or 0),
                BackgroundTransparency = 1,
                Text = cTitle,
                TextColor3 = theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = pickerCard
            })

            local swatch = Creator.New("Frame", {
                Name = "Swatch",
                Size = UDim2.new(0, 32, 0, 22),
                Position = UDim2.new(1, -46, 0.5, -11),
                BackgroundColor3 = color,
                Parent = pickerCard
            })
            Creator.AddCorner(swatch, 6)
            Creator.AddStroke(swatch, Color3.fromRGB(255, 255, 255), 1, 0.75)

            local function setColor(newColor, callCallback)
                color = newColor
                swatch.BackgroundColor3 = color
                if flag then ConfigManager:Set(flag, color) end
                if callCallback ~= false then pcall(callback, color) end
            end

            pickerCard.MouseButton1Click:Connect(function()
                Window:Dialog({
                    Title = cTitle,
                    Content = "Choose a preset color swatch:",
                    Buttons = {
                        { Text = "Red", Variant = "Danger", Callback = function() setColor(Color3.fromRGB(244, 63, 94)) end },
                        { Text = "Green", Variant = "Primary", Callback = function() setColor(Color3.fromRGB(16, 185, 129)) end },
                        { Text = "Blue", Variant = "Primary", Callback = function() setColor(Color3.fromRGB(75, 130, 255)) end },
                        { Text = "Purple", Variant = "Primary", Callback = function() setColor(Color3.fromRGB(168, 85, 247)) end },
                        { Text = "Close", Variant = "Secondary" }
                    }
                })
            end)

            return {
                Instance = pickerCard,
                Value = color,
                Set = function(_, col) setColor(col) end,
                SetValue = function(_, col) setColor(col) end
            }
        end

        -- Element: Keybind
        function Tab:CreateKeybind(keyConfig)
            keyConfig = keyConfig or {}
            local kTitle = keyConfig.Title or "Keybind"
            local kDesc = keyConfig.Desc or ""
            local default = keyConfig.Default or Enum.KeyCode.E
            local flag = keyConfig.Flag
            local callback = keyConfig.Callback or function() end

            if flag then
                local saved = ConfigManager:Get(flag)
                if saved ~= nil then default = saved else ConfigManager:Set(flag, default) end
            end

            local key = default
            local isListening = false
            local cardHeight = kDesc ~= "" and 52 or 42

            local keybindCard = Creator.New("TextButton", {
                Name = "Keybind_" .. kTitle,
                Size = UDim2.new(1, 0, 0, cardHeight),
                BackgroundColor3 = theme.CardBackground,
                AutoButtonColor = false,
                Text = "",
                Parent = page
            })
            Creator.AddCorner(keybindCard, 8)
            Creator.AddStroke(keybindCard, theme.Border, 1)

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -90, 0, kDesc ~= "" and 20 or cardHeight),
                Position = UDim2.new(0, 14, 0, kDesc ~= "" and 8 or 0),
                BackgroundTransparency = 1,
                Text = kTitle,
                TextColor3 = theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = keybindCard
            })

            local badge = Creator.New("Frame", {
                Name = "Badge",
                Size = UDim2.new(0, 64, 0, 24),
                Position = UDim2.new(1, -78, 0.5, -12),
                BackgroundColor3 = theme.Background,
                Parent = keybindCard
            })
            Creator.AddCorner(badge, 6)
            local badgeStroke = Creator.AddStroke(badge, theme.Border, 1)

            local keyLabel = Creator.New("TextLabel", {
                Name = "KeyText",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = typeof(key) == "EnumItem" and key.Name or tostring(key),
                TextColor3 = theme.Accent,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                Parent = badge
            })

            local function setKey(newKey, callCallback)
                key = newKey
                keyLabel.Text = typeof(key) == "EnumItem" and key.Name or tostring(key)
                if flag then ConfigManager:Set(flag, key) end
                if callCallback ~= false then pcall(callback, key) end
            end

            keybindCard.MouseButton1Click:Connect(function()
                if isListening then return end
                isListening = true
                keyLabel.Text = "..."
                badgeStroke.Color = theme.Accent
                local conn
                conn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        conn:Disconnect()
                        isListening = false
                        badgeStroke.Color = theme.Border
                        if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.Escape then
                            setKey(input.KeyCode)
                        else
                            keyLabel.Text = typeof(key) == "EnumItem" and key.Name or tostring(key)
                        end
                    end
                end)
            end)

            Creator.AddSignal(UserInputService.InputBegan, function(input, gpe)
                if gpe or isListening then return end
                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key then
                    pcall(callback)
                end
            end)

            return {
                Instance = keybindCard,
                Value = key,
                Set = function(_, k) setKey(k) end,
                SetValue = function(_, k) setKey(k) end
            }
        end

        -- Element: Input
        function Tab:CreateInput(inputConfig)
            inputConfig = inputConfig or {}
            local iTitle = inputConfig.Title or "Input"
            local iDesc = inputConfig.Desc or ""
            local placeholder = inputConfig.Placeholder or "Enter text..."
            local default = inputConfig.Default or ""
            local numericOnly = inputConfig.NumericOnly or false
            local flag = inputConfig.Flag
            local callback = inputConfig.Callback or function() end

            if flag then
                local saved = ConfigManager:Get(flag)
                if saved ~= nil then default = saved else ConfigManager:Set(flag, default) end
            end

            local text = tostring(default)
            local cardHeight = iDesc ~= "" and 58 or 46
            local inputCard = Creator.New("Frame", {
                Name = "Input_" .. iTitle,
                Size = UDim2.new(1, 0, 0, cardHeight),
                BackgroundColor3 = theme.CardBackground,
                Parent = page
            })
            Creator.AddCorner(inputCard, 8)
            Creator.AddStroke(inputCard, theme.Border, 1)

            Creator.New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -160, 0, iDesc ~= "" and 20 or cardHeight),
                Position = UDim2.new(0, 14, 0, iDesc ~= "" and 8 or 0),
                BackgroundTransparency = 1,
                Text = iTitle,
                TextColor3 = theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = inputCard
            })

            local boxContainer = Creator.New("Frame", {
                Name = "BoxContainer",
                Size = UDim2.new(0, 140, 0, 28),
                Position = UDim2.new(1, -154, 0.5, -14),
                BackgroundColor3 = theme.Background,
                Parent = inputCard
            })
            Creator.AddCorner(boxContainer, 6)
            local boxStroke = Creator.AddStroke(boxContainer, theme.Border, 1)

            local textBox = Creator.New("TextBox", {
                Name = "TextBox",
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = text,
                PlaceholderText = placeholder,
                TextColor3 = theme.Text,
                PlaceholderColor3 = theme.SubText,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = boxContainer
            })

            local function setText(newText, callCallback, enterPressed)
                if numericOnly then newText = newText:gsub("%D+", "") end
                text = newText
                textBox.Text = text
                if flag then ConfigManager:Set(flag, text) end
                if callCallback ~= false then pcall(callback, text, enterPressed) end
            end

            textBox.Focused:Connect(function() Creator.Tween(boxStroke, { Color = theme.Accent }, 0.15) end)
            textBox.FocusLost:Connect(function(enterPressed)
                Creator.Tween(boxStroke, { Color = theme.Border }, 0.15)
                setText(textBox.Text, true, enterPressed)
            end)

            return {
                Instance = inputCard,
                Value = text,
                Set = function(_, t) setText(t) end,
                SetValue = function(_, t) setText(t) end
            }
        end

        if #Window.Tabs == 0 then task.spawn(activateTab) end
        table.insert(Window.Tabs, Tab)
        return Tab
    end

    function Window:AddTab(tabConfig) return self:CreateTab(tabConfig) end
    function Window:Notify(notifConfig) NotificationManager.Notify(notifHolder, notifConfig, theme) end
    function Window:Dialog(dialogConfig) DialogManager.Open(screenGui, dialogConfig, theme) end
    function Window:SetFloatingVisible(visible) if floatingBtn then floatingBtn.Visible = visible end end
    function Window:Toggle() toggleWindow() end

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

    table.insert(HoshiUI.Windows, Window)
    return Window
end

function HoshiUI:AddWindow(config) return self:CreateWindow(config) end

return HoshiUI
