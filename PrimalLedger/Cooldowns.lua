-- PrimalLedger Cooldowns
-- Cooldown detection and tracking logic

local addonName, PL = ...

-- Cooldown definitions
-- Format: spellID = { name, cooldownType, duration (seconds) }
PL.COOLDOWNS = {
    -- Tailoring cooldowns (92 hours = 331200 seconds)
    [36686] = { name = "Shadowcloth", type = "shadowcloth", duration = 331200 },
    [26751] = { name = "Primal Mooncloth", type = "primalMooncloth", duration = 331200 },
    [31373] = { name = "Spellcloth", type = "spellcloth", duration = 331200 },
    [18560] = { name = "Mooncloth", type = "mooncloth", duration = 0 }, -- No cooldown in TBC Anniversary

    -- Alchemy cooldowns
    [29688] = { name = "Transmute: Primal Might", type = "primalMight", duration = 72000 },           -- 20 hours
    [17187] = { name = "Transmute: Arcanite", type = "transmuteArcanite", duration = 172800 },        -- 48 hours
    [17561] = { name = "Transmute: Undeath to Water", type = "transmuteUndeathToWater", duration = 86400 }, -- 24 hours
    [11480] = { name = "Transmute: Mithril to Truesilver", type = "transmuteMithrilToTruesilver", duration = 72000 }, -- 20 hours
    [11479] = { name = "Transmute: Iron to Gold", type = "transmuteIronToGold", duration = 72000 }, -- 20 hours
}

-- Profession names for detection
-- Primary professions
local TAILORING = "Tailoring"
local ALCHEMY = "Alchemy"
local ENCHANTING = "Enchanting"
local LEATHERWORKING = "Leatherworking"
local BLACKSMITHING = "Blacksmithing"
local JEWELCRAFTING = "Jewelcrafting"
local ENGINEERING = "Engineering"
local MINING = "Mining"
local HERBALISM = "Herbalism"
local SKINNING = "Skinning"
-- Secondary professions
local COOKING = "Cooking"
local FISHING = "Fishing"
local FIRST_AID = "First Aid"

-- Helper to check if a profession is known (handles both boolean and number values)
local function hasProfession(value)
    if type(value) == "number" then
        return value > 0
    end
    return value == true
end

-- Cooldown types by profession
PL.PROFESSION_COOLDOWNS = {
    tailoring = { "shadowcloth", "primalMooncloth", "spellcloth", "mooncloth" },
    alchemy = { "primalMight", "transmuteArcanite", "transmuteUndeathToWater", "transmuteMithrilToTruesilver", "transmuteIronToGold" }
}

-- Friendly names for cooldown types
PL.COOLDOWN_NAMES = {
    shadowcloth = "Shadowcloth",
    primalMooncloth = "Primal Mooncloth",
    spellcloth = "Spellcloth",
    mooncloth = "Mooncloth",
    primalMight = "Transmute: Primal Might",
    transmuteArcanite = "Transmute: Arcanite",
    transmuteUndeathToWater = "Transmute: Undeath to Water",
    transmuteMithrilToTruesilver = "Transmute: Mithril to Truesilver",
    transmuteIronToGold = "Transmute: Iron to Gold"
}

-- Spell IDs for each cooldown type (used to check if player knows the craft)
PL.COOLDOWN_SPELLS = {
    shadowcloth = 36686,
    primalMooncloth = 26751,
    spellcloth = 31373,
    mooncloth = 18560,
    primalMight = 29688,
    transmuteArcanite = 17187,
    transmuteUndeathToWater = 17561,
    transmuteMithrilToTruesilver = 11480,
    transmuteIronToGold = 11479
}

-- Cooldown durations
PL.COOLDOWN_DURATIONS = {
    shadowcloth = 331200, -- 92 hours
    primalMooncloth = 331200, -- 92 hours
    spellcloth = 331200, -- 92 hours
    mooncloth = 0, -- No cooldown in TBC Anniversary
    primalMight = 72000,
    transmuteArcanite = 0, -- No cooldown in TBC Anniversary
    transmuteUndeathToWater = 86400,
    transmuteMithrilToTruesilver = 72000,
    transmuteIronToGold = 72000
}

-- Source information for cooldown crafts
-- Format: cooldownType = { spellId, skillRequired, pattern = { itemId, name }, vendor = { npcId, name, tomtom } }
PL.COOLDOWN_SOURCES = {
    primalMooncloth = {
        spellId = 26751,
        skillRequired = 350,
        pattern = { itemId = 21895, name = "Pattern: Primal Mooncloth" },
        vendor = { npcId = 22208, name = "Nasmara Moonsong", tomtom = "/way #1955 66.6 68.8 Nasmara Moonsong" }
    },
    shadowcloth = {
        spellId = 36686,
        skillRequired = 350,
        pattern = { itemId = 30483, name = "Pattern: Shadowcloth" },
        vendor = { npcId = 22212, name = "Andrion Darkspinner", tomtom = "/way #1955 66.6 68.2 Andrion Darkspinner" }
    },
    spellcloth = {
        spellId = 31373,
        skillRequired = 350,
        pattern = { itemId = 24316, name = "Pattern: Spellcloth" },
        vendor = { npcId = 22213, name = "Gidge Spellweaver", tomtom = "/way #1955 66.6 68.6 Gidge Spellweaver" }
    }
}

-- Profession spell names (for opening the tradeskill window)
PL.PROFESSION_SPELLS = {
    tailoring = "Tailoring",
    alchemy = "Alchemy"
}

-- Map cooldown types to their profession
PL.COOLDOWN_TO_PROFESSION = {
    shadowcloth = "tailoring",
    primalMooncloth = "tailoring",
    spellcloth = "tailoring",
    mooncloth = "tailoring",
    primalMight = "alchemy",
    transmuteArcanite = "alchemy",
    transmuteUndeathToWater = "alchemy",
    transmuteMithrilToTruesilver = "alchemy",
    transmuteIronToGold = "alchemy"
}

-- Detect professions for a character (TBC Classic API)
function PL:DetectProfessions(charKey)
    local charData = self.db.characters[charKey]
    if not charData then return end

    charData.professions = {
        -- Primary professions (stores skill level or false)
        tailoring = false,
        alchemy = false,
        enchanting = false,
        leatherworking = false,
        blacksmithing = false,
        jewelcrafting = false,
        engineering = false,
        mining = false,
        herbalism = false,
        skinning = false,
        -- Secondary professions
        cooking = false,
        fishing = false,
        firstAid = false
    }

    -- TBC Classic uses the skill system for professions
    local numSkills = GetNumSkillLines()
    for i = 1, numSkills do
        local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
        if not isHeader and skillName then
            -- Primary professions
            if skillName == TAILORING then
                charData.professions.tailoring = skillRank
            elseif skillName == ALCHEMY then
                charData.professions.alchemy = skillRank
            elseif skillName == ENCHANTING then
                charData.professions.enchanting = skillRank
            elseif skillName == LEATHERWORKING then
                charData.professions.leatherworking = skillRank
            elseif skillName == BLACKSMITHING then
                charData.professions.blacksmithing = skillRank
            elseif skillName == JEWELCRAFTING then
                charData.professions.jewelcrafting = skillRank
            elseif skillName == ENGINEERING then
                charData.professions.engineering = skillRank
            elseif skillName == MINING then
                charData.professions.mining = skillRank
            elseif skillName == HERBALISM then
                charData.professions.herbalism = skillRank
            elseif skillName == SKINNING then
                charData.professions.skinning = skillRank
            -- Secondary professions
            elseif skillName == COOKING then
                charData.professions.cooking = skillRank
            elseif skillName == FISHING then
                charData.professions.fishing = skillRank
            elseif skillName == FIRST_AID then
                charData.professions.firstAid = skillRank
            end
        end
    end

    -- Detect known crafts
    self:DetectKnownCrafts(charKey)
end

-- Detect which cooldown crafts the current character knows (without wiping existing data)
function PL:DetectKnownCrafts(charKey)
    local charData = self.db.characters[charKey]
    if not charData then return end

    -- Initialize tables if they don't exist (but don't wipe existing data)
    charData.knownCrafts = charData.knownCrafts or {}
    charData.cooldowns = charData.cooldowns or {}

    -- Use IsSpellKnown to detect which crafts the character knows
    -- Only ADD data here, don't remove - removal happens when scanning tradeskill window
    for cdType, spellID in pairs(self.COOLDOWN_SPELLS) do
        if IsSpellKnown(spellID) then
            charData.knownCrafts[cdType] = true
        end
    end
end

-- Scan the tradeskill window for cooldown data
-- This wipes and re-fetches data for the currently open profession only
function PL:ScanTradeSkillWindow(charKey)
    local charData = self.db.characters[charKey]
    if not charData then return end

    local numSkills = GetNumTradeSkills()
    if not numSkills or numSkills == 0 then return end

    -- Detect which profession is open
    local tradeskillName = GetTradeSkillLine()
    if not tradeskillName then return end

    local professionKey = nil
    if tradeskillName == "Alchemy" then
        professionKey = "alchemy"
    elseif tradeskillName == "Tailoring" then
        professionKey = "tailoring"
    else
        return -- Not a profession we track
    end

    -- Wipe existing data for this profession's crafts
    local professionCooldowns = self.PROFESSION_COOLDOWNS[professionKey]
    if professionCooldowns then
        for _, cdType in ipairs(professionCooldowns) do
            charData.knownCrafts[cdType] = nil
            charData.cooldowns[cdType] = nil
        end
    end

    -- Re-fetch known crafts and cooldowns from the tradeskill window
    for i = 1, numSkills do
        local name, skillType = GetTradeSkillInfo(i)
        if name and skillType ~= "header" then
            -- Check if this exactly matches any of our tracked cooldowns
            for cdType, cdName in pairs(self.COOLDOWN_NAMES) do
                -- Use exact matching to avoid "Mooncloth" matching "Primal Mooncloth"
                if name == cdName then
                    charData.knownCrafts[cdType] = true

                    -- Get cooldown using GetTradeSkillCooldown (returns seconds remaining)
                    local cooldownRemaining = GetTradeSkillCooldown(i)
                    if cooldownRemaining and cooldownRemaining > 0 then
                        -- Spell is on cooldown - calculate expiration time
                        local expirationTime = GetTime() + cooldownRemaining
                        charData.cooldowns[cdType] = expirationTime
                    else
                        -- Spell is ready
                        charData.cooldowns[cdType] = 0
                    end
                    break -- Found exact match, no need to check other cooldown types
                end
            end
        end
    end
end

-- Check if a spell cast triggers a cooldown
function PL:CheckCooldownSpell(spellID)
    local cooldownInfo = self.COOLDOWNS[spellID]
    if cooldownInfo then
        local expirationTime = GetTime() + cooldownInfo.duration
        self:SaveCooldown(cooldownInfo.type, expirationTime)
        self:Print(cooldownInfo.name .. " crafted! Cooldown expires in " ..
            self:FormatTimeRemaining(cooldownInfo.duration))

        -- Update UI if visible
        if self.mainFrame and self.mainFrame:IsShown() then
            self:UpdateMainFrame()
        end
    end
end

-- Get remaining time for a cooldown
function PL:GetCooldownRemaining(charKey, cooldownType)
    local expirationTime = self:GetCooldown(charKey, cooldownType)
    if expirationTime == nil then
        return nil -- Never crafted/tracked
    end

    if expirationTime == 0 then
        return 0 -- Ready (synced from game)
    end

    local remaining = expirationTime - GetTime()
    if remaining <= 0 then
        return 0 -- Ready
    end

    return remaining
end

-- Format time remaining as a readable string
function PL:FormatTimeRemaining(seconds)
    if seconds == nil then
        return "Unknown"
    end

    if seconds <= 0 then
        return "|cff00ff00Ready!|r"
    end

    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)

    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, minutes)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

-- Get all cooldowns for a character that should be displayed
function PL:GetCharacterCooldowns(charKey)
    local charData = self.db.characters[charKey]
    if not charData then return {} end

    local cooldowns = {}
    local knownCrafts = charData.knownCrafts or {}

    -- Check tailoring cooldowns
    if hasProfession(charData.professions.tailoring) then
        for _, cdType in ipairs(self.PROFESSION_COOLDOWNS.tailoring) do
            if knownCrafts[cdType] then
                local remaining = self:GetCooldownRemaining(charKey, cdType)
                table.insert(cooldowns, {
                    type = cdType,
                    name = self.COOLDOWN_NAMES[cdType],
                    remaining = remaining,
                    formattedTime = self:FormatTimeRemaining(remaining)
                })
            end
        end
    end

    -- Check alchemy cooldowns
    if hasProfession(charData.professions.alchemy) then
        for _, cdType in ipairs(self.PROFESSION_COOLDOWNS.alchemy) do
            if knownCrafts[cdType] then
                local remaining = self:GetCooldownRemaining(charKey, cdType)
                table.insert(cooldowns, {
                    type = cdType,
                    name = self.COOLDOWN_NAMES[cdType],
                    remaining = remaining,
                    formattedTime = self:FormatTimeRemaining(remaining)
                })
            end
        end
    end

    return cooldowns
end

-- Check if character has Tailoring or Alchemy profession
function PL:HasRelevantProfessions(charKey)
    local charData = self.db.characters[charKey]
    if not charData or not charData.professions then return false end

    return hasProfession(charData.professions.tailoring) or hasProfession(charData.professions.alchemy)
end

-- Open profession window and select a specific recipe
function PL:OpenCraftingSpell(cdType)
    local profession = self.COOLDOWN_TO_PROFESSION[cdType]
    if not profession then return end

    local professionSpell = self.PROFESSION_SPELLS[profession]
    if not professionSpell then return end

    local spellName = self.COOLDOWN_NAMES[cdType]

    -- Store the spell we want to select after the tradeskill window opens
    self.pendingSpellSelection = spellName

    -- Create event/timer frame if not already
    if not self.tradeskillEventFrame then
        self.tradeskillEventFrame = CreateFrame("Frame")
        self.tradeskillEventFrame:RegisterEvent("TRADE_SKILL_SHOW")
        self.tradeskillEventFrame:SetScript("OnEvent", function(self, event)
            if event == "TRADE_SKILL_SHOW" and PL.pendingSpellSelection then
                -- Add a small delay to let the tradeskill window populate
                self.waitTime = 0
                self.targetSpell = PL.pendingSpellSelection
                PL.pendingSpellSelection = nil
                self:SetScript("OnUpdate", function(self, elapsed)
                    self.waitTime = self.waitTime + elapsed
                    if self.waitTime >= 0.1 then
                        self:SetScript("OnUpdate", nil)
                        PL:SelectTradeSkillByName(self.targetSpell)
                    end
                end)
            end
        end)
    end

    -- Open the profession window
    CastSpellByName(professionSpell)
end

-- Select a recipe in an already-open tradeskill window (right-click action)
function PL:SelectCraftingSpell(cdType)
    local spellName = self.COOLDOWN_NAMES[cdType]
    if not spellName then return end

    -- Check if tradeskill window is open
    local numSkills = GetNumTradeSkills()
    if not numSkills or numSkills == 0 then
        self:Print("Open your profession window first!")
        return
    end

    -- Select the recipe
    self:SelectTradeSkillByName(spellName)
end

-- Find and select a recipe by name in the tradeskill window
function PL:SelectTradeSkillByName(spellName)
    local numSkills = GetNumTradeSkills()
    if not numSkills then return end

    for i = 1, numSkills do
        local name, skillType = GetTradeSkillInfo(i)
        -- Use partial match in case names differ slightly (e.g., "Transmute: Arcanite" vs "Transmute: Arcanite Bar")
        if name and skillType ~= "header" and string.find(name, spellName, 1, true) then
            SelectTradeSkill(i)
            return
        end
    end

    -- Fallback: try matching the other way (spellName contains recipe name)
    for i = 1, numSkills do
        local name, skillType = GetTradeSkillInfo(i)
        if name and skillType ~= "header" and string.find(spellName, name, 1, true) then
            SelectTradeSkill(i)
            return
        end
    end
end
