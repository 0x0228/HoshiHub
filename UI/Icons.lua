-- ==============================================================================
-- HoshiUI — Icon Engine (Footagesus/Icons Integration & Multi-Set Resolver)
-- Supports: Lucide • Solar • Craft • Geist • SFSymbols • Custom Asset IDs
-- Features: Instant Local Caching • Zero Startup Stutter • Offline Fallbacks
-- ==============================================================================

local HttpService = game:GetService("HttpService")

local IconEngine = {
    DefaultType = "lucide",
    CacheFolder = "HoshiHub/Icons",
    LoadedSets = {},
    Urls = {
        ["lucide"] = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua",
        ["solar"] = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/solar/dist/Icons.lua",
        ["craft"] = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua",
        ["geist"] = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua",
        ["sfsymbols"] = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/sfsymbols/dist/Icons.lua",
    },
}

-- Built-in Essential Offline Fallbacks (Instant 0ms availability)
local CoreFallbackIcons = {
    ["home"] = "rbxassetid://10723407389",
    ["house"] = "rbxassetid://10723407389",
    ["settings"] = "rbxassetid://10734950309",
    ["shield"] = "rbxassetid://10734951847",
    ["zap"] = "rbxassetid://10709819149",
    ["swords"] = "rbxassetid://10734975692",
    ["sword"] = "rbxassetid://10734975486",
    ["flame"] = "rbxassetid://10709768641",
    ["sparkles"] = "rbxassetid://10734974297",
    ["sliders"] = "rbxassetid://10734973474",
    ["palette"] = "rbxassetid://10723387841",
    ["bell"] = "rbxassetid://10709752405",
    ["code"] = "rbxassetid://10709756479",
    ["terminal"] = "rbxassetid://10734982144",
    ["cpu"] = "rbxassetid://10709757657",
    ["database"] = "rbxassetid://10709758504",
    ["heart"] = "rbxassetid://10723354141",
    ["star"] = "rbxassetid://10734974984",
    ["user"] = "rbxassetid://10734988677",
    ["users"] = "rbxassetid://10734989047",
    ["folder"] = "rbxassetid://10723346158",
    ["file"] = "rbxassetid://10723344158",
    ["save"] = "rbxassetid://10734967396",
    ["refresh-cw"] = "rbxassetid://10734963384",
    ["search"] = "rbxassetid://10734965287",
    ["eye"] = "rbxassetid://10723342088",
    ["eye-off"] = "rbxassetid://10723341857",
    ["lock"] = "rbxassetid://10723374276",
    ["unlock"] = "rbxassetid://10734987768",
    ["check"] = "rbxassetid://10709755100",
    ["x"] = "rbxassetid://10734991278",
    ["chevron-down"] = "rbxassetid://10709755832",
    ["chevron-right"] = "rbxassetid://10709756012",
    ["chevron-up"] = "rbxassetid://10709756182",
    ["chevron-left"] = "rbxassetid://10709755928",
    ["play"] = "rbxassetid://10734940376",
    ["pause"] = "rbxassetid://10734939886",
    ["info"] = "rbxassetid://10723362141",
    ["alert-triangle"] = "rbxassetid://10709751935",
    ["alert-circle"] = "rbxassetid://10709751753",
    ["crosshair"] = "rbxassetid://10709757962",
    ["target"] = "rbxassetid://10734979144",
    ["compass"] = "rbxassetid://10709756783",
    ["sun"] = "rbxassetid://10734975252",
    ["moon"] = "rbxassetid://10723381442",
    ["hash"] = "rbxassetid://10723353457",
    ["activity"] = "rbxassetid://10709751410",
    ["box"] = "rbxassetid://10709753443",
    ["layers"] = "rbxassetid://10723373759",
    ["layout-grid"] = "rbxassetid://10723373997",
    ["mouse-pointer"] = "rbxassetid://10723381787",
    ["rocket"] = "rbxassetid://10734966755",
    ["globe"] = "rbxassetid://10723351058",
    ["wrench"] = "rbxassetid://10734990924",
    ["key"] = "rbxassetid://10723373407",
    ["trash"] = "rbxassetid://10734983637",
    ["copy"] = "rbxassetid://10709757364",
    ["navigation"] = "rbxassetid://10723383020",
}

IconEngine.LoadedSets["lucide"] = CoreFallbackIcons

-- Helper to safely make cache folder
local function ensureCacheFolder()
    if makefolder and isfolder then
        pcall(function()
            if not isfolder("HoshiHub") then makefolder("HoshiHub") end
            if not isfolder(IconEngine.CacheFolder) then makefolder(IconEngine.CacheFolder) end
        end)
    end
end

-- Helper to fetch set from local cache or Footagesus GitHub
function IconEngine.LoadSet(setName)
    setName = setName:lower()
    if IconEngine.LoadedSets[setName] and IconEngine.LoadedSets[setName] ~= CoreFallbackIcons then
        return IconEngine.LoadedSets[setName]
    end

    ensureCacheFolder()
    local cacheFilePath = IconEngine.CacheFolder .. "/" .. setName .. ".json"

    -- 1. Try reading from executor local file cache (Instant 0ms)
    if readfile and isfile and isfile(cacheFilePath) then
        local success, cachedData = pcall(function()
            local raw = readfile(cacheFilePath)
            return HttpService:JSONDecode(raw)
        end)
        if success and type(cachedData) == "table" then
            IconEngine.LoadedSets[setName] = cachedData
            return cachedData
        end
    end

    -- 2. Fetch from Footagesus GitHub repo asynchronously/synchronously
    local url = IconEngine.Urls[setName]
    if url then
        local fetchSuccess, rawLua = pcall(function()
            if game.HttpGetAsync then
                return game:HttpGetAsync(url)
            elseif game.HttpGet then
                return game:HttpGet(url)
            end
            return nil
        end)

        if fetchSuccess and rawLua and rawLua ~= "" then
            local loadSuccess, parsedTable = pcall(function()
                return loadstring(rawLua)()
            end)

            if loadSuccess and type(parsedTable) == "table" then
                IconEngine.LoadedSets[setName] = parsedTable

                -- Save to local cache for instant future loads
                if writefile then
                    pcall(function()
                        writefile(cacheFilePath, HttpService:JSONEncode(parsedTable))
                    end)
                end

                return parsedTable
            end
        end
    end

    -- Fallback to core icons if lucide
    if setName == "lucide" then
        return CoreFallbackIcons
    end
    return nil
end

-- Preload icon set in background without lagging main thread
function IconEngine.PreloadAsync(setName)
    task.spawn(function()
        IconEngine.LoadSet(setName or IconEngine.DefaultType)
    end)
end

-- Set active default pack (e.g. "lucide", "solar", "craft", "geist", "sfsymbols")
function IconEngine.SetIconsType(iconType)
    IconEngine.DefaultType = iconType:lower()
    IconEngine.PreloadAsync(IconEngine.DefaultType)
end

-- Resolve Icon string to "rbxassetid://..."
-- Accepts:
--   "house" (uses DefaultType)
--   "lucide:house", "solar:bell", "craft:sword", "geist:terminal", "sfsymbols:house.fill"
--   "rbxassetid://123456" or "123456"
function IconEngine.GetIcon(iconQuery)
    if not iconQuery or iconQuery == "" then
        return nil
    end

    if type(iconQuery) ~= "string" then
        if tonumber(iconQuery) then
            return "rbxassetid://" .. tostring(iconQuery)
        end
        return nil
    end

    -- Direct Roblox asset format
    if iconQuery:sub(1, 13) == "rbxassetid://" then
        return iconQuery
    end
    if tonumber(iconQuery) then
        return "rbxassetid://" .. iconQuery
    end

    -- Parse pack prefix (e.g., "lucide:home", "solar:shield", "craft-sword")
    local pack = IconEngine.DefaultType
    local iconName = iconQuery

    if iconQuery:find(":") then
        local parts = iconQuery:split(":")
        pack = parts[1]:lower()
        iconName = parts[2]
    elseif iconQuery:find("^lucide%-") then
        pack = "lucide"
        iconName = iconQuery:gsub("^lucide%-", "")
    elseif iconQuery:find("^solar%-") then
        pack = "solar"
        iconName = iconQuery:gsub("^solar%-", "")
    elseif iconQuery:find("^craft%-") then
        pack = "craft"
        iconName = iconQuery:gsub("^craft%-", "")
    elseif iconQuery:find("^geist%-") then
        pack = "geist"
        iconName = iconQuery:gsub("^geist%-", "")
    elseif iconQuery:find("^sfsymbols%-") then
        pack = "sfsymbols"
        iconName = iconQuery:gsub("^sfsymbols%-", "")
    end

    -- Normalize icon name
    local cleanName = iconName:lower():gsub("_", "-")

    -- Check active set
    local set = IconEngine.LoadedSets[pack]
    if not set then
        set = IconEngine.LoadSet(pack)
    end

    if set and set[cleanName] then
        return set[cleanName]
    end

    -- Fallback checks
    if CoreFallbackIcons[cleanName] then
        return CoreFallbackIcons[cleanName]
    end

    -- Try lucide if another pack failed
    if pack ~= "lucide" then
        local lucideSet = IconEngine.LoadedSets["lucide"] or IconEngine.LoadSet("lucide")
        if lucideSet and lucideSet[cleanName] then
            return lucideSet[cleanName]
        end
    end

    return nil
end

-- Preload default pack immediately
IconEngine.PreloadAsync("lucide")

return IconEngine
