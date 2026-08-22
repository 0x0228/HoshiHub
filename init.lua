-- ==============================================================================
-- HoshiHub — Main Repository Entry Point & Auto-Loader
-- Load with: loadstring(game:HttpGet("https://raw.githubusercontent.com/0x0228/HoshiHub/master/init.lua"))()
-- ==============================================================================

local Mirrors = {
    "https://raw.githubusercontent.com/0x0228/HoshiHub/master",
    "https://cdn.jsdelivr.net/gh/0x0228/HoshiHub@master",
    "https://raw.githubusercontent.com/0x0228/HoshiHub/refs/heads/master"
}

local function loadHubModule(subPath)
    local lastError = "No mirror reachable"
    for _, base in ipairs(Mirrors) do
        local url = base .. "/" .. subPath
        local success, content = pcall(function()
            return game:HttpGet(url)
        end)
        if success and content and #content > 50 and not content:find("404: Not Found") and not content:find("404 Not Found") then
            local fn, parseErr = loadstring(content)
            if fn then
                local runSuccess, result = pcall(fn)
                if runSuccess then
                    return result
                else
                    lastError = "Runtime error in " .. subPath .. ": " .. tostring(result)
                end
            else
                lastError = "Compile error in " .. subPath .. ": " .. tostring(parseErr)
            end
        else
            lastError = "HTTP fetch failed: " .. tostring(content)
        end
    end
    error("[HoshiHub] Could not load module '" .. subPath .. "': " .. lastError)
end

-- Launch the official HoshiHub Loader & Gateway
return loadHubModule("Loader.lua")
