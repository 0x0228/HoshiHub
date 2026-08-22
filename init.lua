-- ==============================================================================
-- HoshiHub — Main Repository Entry Point & Auto-Loader
-- Load with: loadstring(game:HttpGet("https://raw.githubusercontent.com/0x0228/HoshiHub/master/init.lua"))()
-- ==============================================================================

local GITHUB_RAW = "https://raw.githubusercontent.com/0x0228/HoshiHub/master"

local function loadHubModule(subPath)
    local url = GITHUB_RAW .. "/" .. subPath
    local success, content = pcall(game.HttpGet, game, url)
    if not success or not content or type(content) ~= "string" or #content < 100 then
        error("[HoshiHub] Failed to fetch " .. subPath .. " (" .. url .. "): " .. tostring(content))
    end

    local fn, parseErr = loadstring(content)
    if not fn then
        error("[HoshiHub] Compile error in " .. subPath .. ": " .. tostring(parseErr))
    end

    local runSuccess, result = pcall(fn)
    if not runSuccess then
        error("[HoshiHub] Runtime error in " .. subPath .. ": " .. tostring(result))
    end

    return result
end

-- Launch the official HoshiHub Loader & Gateway
return loadHubModule("Loader.lua")
