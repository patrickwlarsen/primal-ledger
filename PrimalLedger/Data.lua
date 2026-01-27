-- PrimalLedger Data
-- Saved variables and character data management

local addonName, PL = ...

-- Default saved variables structure
local defaults = {
    characters = {},
    settings = {
        minimapPosition = 45,
        framePosition = { point = "CENTER", x = 0, y = 0 },
    }
}

-- Initialize saved variables
function PL:InitializeData()
    if not PrimalLedgerDB then
        PrimalLedgerDB = {}
    end

    -- Ensure all default keys exist
    for key, value in pairs(defaults) do
        if PrimalLedgerDB[key] == nil then
            PrimalLedgerDB[key] = value
        end
    end

    self.db = PrimalLedgerDB
end

-- Get character key (CharName-RealmName)
function PL:GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

-- Get or create character data
function PL:GetCharacterData(charKey)
    charKey = charKey or self:GetCharacterKey()
    return self.db.characters[charKey]
end

-- Update current character's data
function PL:UpdateCurrentCharacter()
    local charKey = self:GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    local _, class = UnitClass("player")

    -- Create or update character entry
    if not self.db.characters[charKey] then
        self.db.characters[charKey] = {
            name = name,
            realm = realm,
            class = class,
            professions = {},
            cooldowns = {}
        }
    else
        -- Update class in case it wasn't set
        self.db.characters[charKey].class = class
    end

    -- Detect professions
    self:DetectProfessions(charKey)
end

-- Remove current character from tracking
function PL:RemoveCurrentCharacter()
    local charKey = self:GetCharacterKey()
    if self.db.characters[charKey] then
        self.db.characters[charKey] = nil
        self:Print("Removed " .. charKey .. " from tracking.")
        if self.mainFrame and self.mainFrame:IsShown() then
            self:UpdateMainFrame()
        end
    else
        self:Print("Character not found in tracking.")
    end
end

-- Reset all data
function PL:ResetData()
    PrimalLedgerDB = nil
    self:InitializeData()
    self:UpdateCurrentCharacter()
    if self.mainFrame and self.mainFrame:IsShown() then
        self:UpdateMainFrame()
    end
end

-- Get all tracked characters sorted with current character first, then by name
function PL:GetAllCharacters()
    local characters = {}
    local currentCharKey = self:GetCharacterKey()

    for key, data in pairs(self.db.characters) do
        table.insert(characters, { key = key, data = data })
    end

    table.sort(characters, function(a, b)
        -- Current character always comes first
        if a.key == currentCharKey then return true end
        if b.key == currentCharKey then return false end
        -- Otherwise sort alphabetically by name
        return a.data.name < b.data.name
    end)

    return characters
end

-- Save cooldown timestamp for current character
function PL:SaveCooldown(cooldownType, expirationTime)
    local charKey = self:GetCharacterKey()
    local charData = self.db.characters[charKey]

    if charData then
        charData.cooldowns[cooldownType] = expirationTime
    end
end

-- Get cooldown expiration time
function PL:GetCooldown(charKey, cooldownType)
    local charData = self.db.characters[charKey]
    if charData and charData.cooldowns then
        return charData.cooldowns[cooldownType]
    end
    return nil
end
