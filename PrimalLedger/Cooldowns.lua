-- PrimalLedger Cooldowns
-- Cooldown detection and tracking logic

local addonName, PL = ...

-- Cooldown definitions
-- Format: spellID = { name, cooldownType, duration (seconds) }
PL.COOLDOWNS = {
    -- Tailoring cooldowns (4 days = 345600 seconds)
    [36686] = { name = "Shadowcloth", type = "shadowcloth", duration = 345600 },
    [26751] = { name = "Primal Mooncloth", type = "primalMooncloth", duration = 345600 },
    [31373] = { name = "Spellcloth", type = "spellcloth", duration = 345600 },
    [18560] = { name = "Mooncloth", type = "mooncloth", duration = 0 }, -- No cooldown in TBC Anniversary

    -- Alchemy cooldowns
    [29688] = { name = "Transmute: Primal Might", type = "primalMight", duration = 72000 },           -- 20 hours
    [17187] = { name = "Transmute: Arcanite", type = "transmuteArcanite", duration = 172800 },        -- 48 hours
    [17561] = { name = "Transmute: Undeath to Water", type = "transmuteUndeathToWater", duration = 86400 }, -- 24 hours
    [11480] = { name = "Transmute: Mithril to Truesilver", type = "transmuteMithrilToTruesilver", duration = 72000 }, -- 20 hours
    [11479] = { name = "Transmute: Iron to Gold", type = "transmuteIronToGold", duration = 72000 }, -- 20 hours
}

-- Profession names for detection
local TAILORING = "Tailoring"
local ALCHEMY = "Alchemy"

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
    shadowcloth = 345600,
    primalMooncloth = 345600,
    spellcloth = 345600,
    mooncloth = 0, -- No cooldown in TBC Anniversary
    primalMight = 72000,
    transmuteArcanite = 0, -- No cooldown in TBC Anniversary
    transmuteUndeathToWater = 86400,
    transmuteMithrilToTruesilver = 72000,
    transmuteIronToGold = 72000
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
        tailoring = false,
        alchemy = false
    }

    -- TBC Classic uses the skill system for professions
    local numSkills = GetNumSkillLines()
    for i = 1, numSkills do
        local skillName, isHeader = GetSkillLineInfo(i)
        if not isHeader and skillName then
            if skillName == TAILORING then
                charData.professions.tailoring = true
            elseif skillName == ALCHEMY then
                charData.professions.alchemy = true
            end
        end
    end

    -- Detect known crafts
    self:DetectKnownCrafts(charKey)
end

-- Detect which cooldown crafts the current character knows
function PL:DetectKnownCrafts(charKey)
    local charData = self.db.characters[charKey]
    if not charData then return end

    -- Completely wipe existing data for this character's crafts
    charData.knownCrafts = {}
    charData.cooldowns = {}

    -- Use IsSpellKnown to detect which crafts the character knows
    for cdType, spellID in pairs(self.COOLDOWN_SPELLS) do
        if IsSpellKnown(spellID) then
            charData.knownCrafts[cdType] = true
            -- Default to unknown cooldown state (will be updated when tradeskill window opens)
            -- Keep existing cooldown data if we have it
        end
    end

    -- Scan the tradeskill window for cooldown data (if open)
    self:ScanTradeSkillWindow(charKey)
end

-- Scan the tradeskill window for cooldown data
function PL:ScanTradeSkillWindow(charKey)
    local charData = self.db.characters[charKey]
    if not charData then return end

    local numSkills = GetNumTradeSkills()
    if not numSkills or numSkills == 0 then return end

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
    if charData.professions.tailoring then
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
    if charData.professions.alchemy then
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

    return charData.professions.tailoring or charData.professions.alchemy
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
