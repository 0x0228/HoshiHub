-- ==============================================================================
-- HoshiUI — Config Persistence Engine
-- Features: Real-time Auto-Save • Executor storage (writefile/readfile) • Flag system
-- ==============================================================================

local HttpService = game:GetService("HttpService")

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

    if makefolder and not isfolder(self.Folder) then
        pcall(makefolder, self.Folder)
    end
end

function ConfigManager:Set(flag, value)
    if not flag then return end
    self.Flags[flag] = value
    if self.Signals[flag] then
        self.Signals[flag]:Fire(value)
    end
    if self.AutoSave then
        self:Save()
    end
end

function ConfigManager:Get(flag, defaultValue)
    if self.Flags[flag] ~= nil then
        return self.Flags[flag]
    end
    return defaultValue
end

function ConfigManager:Save()
    if not writefile then return end
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

    local success, json = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if success and json then
        pcall(writefile, filePath, json)
    end
end

function ConfigManager:Load()
    if not readfile or not isfile then return false end
    local filePath = self.Folder .. "/" .. self.File
    if not isfile(filePath) then return false end

    local success, content = pcall(readfile, filePath)
    if not success or not content or content == "" then return false end

    local parseSuccess, parsed = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not parseSuccess or type(parsed) ~= "table" then return false end

    for k, v in pairs(parsed) do
        if type(v) == "table" and v.__type == "Color3" then
            self.Flags[k] = Color3.new(v.r, v.g, v.b)
        elseif type(v) == "table" and v.__type == "EnumItem" then
            local enumType = Enum[v.enum]
            if enumType and enumType[v.name] then
                self.Flags[k] = enumType[v.name]
            end
        else
            self.Flags[k] = v
        end
        if self.Signals[k] then
            self.Signals[k]:Fire(self.Flags[k])
        end
    end
    return true
end

function ConfigManager:Export()
    local success, json = pcall(function()
        return HttpService:JSONEncode(self.Flags)
    end)
    return success and json or "{}"
end

return ConfigManager
