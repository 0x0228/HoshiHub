-- ==============================================================================
-- HoshiHub — Main Repository Entry Point & Auto-Loader
-- Load with: loadstring(game:HttpGet("https://raw.githubusercontent.com/0x0228/HoshiHub/master/init.lua"))()
-- ==============================================================================

local GITHUB_RAW = "https://raw.githubusercontent.com/0x0228/HoshiHub/master"

local function loadHubModule(subPath)
    local url = GITHUB_RAW .. "/" .. subPath
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    if success and content and content ~= "" and not content:find("404: Not Found") then
        return loadstring(content)()
    end
    error("[HoshiHub] Could not load module from GitHub: " .. url)
end

-- Launch the official HoshiHub Loader & Gateway
return loadHubModule("Loader.lua")
