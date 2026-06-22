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

    -- Leatherworking cooldowns
    [19566] = { name = "Salt Shaker", type = "saltShaker", duration = 255600 },                        -- 2d 23h

    -- Alchemy cooldowns
    [29688] = { name = "Transmute: Primal Might", type = "primalMight", duration = 72000 },           -- 20 hours
    [28582] = { name = "Transmute: Primal Mana to Fire", type = "transmutePrimalManaToFire", duration = 72000 }, -- 20 hours
    [28580] = { name = "Transmute: Primal Shadow to Water", type = "transmutePrimalShadowToWater", duration = 72000 }, -- 20 hours
    [28566] = { name = "Transmute: Primal Air to Fire", type = "transmutePrimalAirToFire", duration = 72000 }, -- 20 hours
    [28581] = { name = "Transmute: Primal Water to Shadow", type = "transmutePrimalWaterToShadow", duration = 72000 }, -- 20 hours
    [28567] = { name = "Transmute: Primal Earth to Water", type = "transmutePrimalEarthToWater", duration = 72000 }, -- 20 hours
    [28569] = { name = "Transmute: Primal Water to Air", type = "transmutePrimalWaterToAir", duration = 72000 }, -- 20 hours
    [28584] = { name = "Transmute: Primal Life to Earth", type = "transmutePrimalLifeToEarth", duration = 72000 }, -- 20 hours
    [32765] = { name = "Transmute: Earthstorm Diamond", type = "transmuteEarthstormDiamond", duration = 72000 }, -- 20 hours
    [32766] = { name = "Transmute: Skyfire Diamond", type = "transmuteSkyfireDiamond", duration = 72000 }, -- 20 hours
    [17561] = { name = "Transmute: Undeath to Water", type = "transmuteUndeathToWater", duration = 86400 }, -- 24 hours

    -- Enchanting cooldowns
    [28028] = { name = "Void Sphere", type = "voidSphere", duration = 172800 },                              -- 48 hours

    -- Jewelcrafting cooldowns
    [47280] = { name = "Brilliant Glass", type = "brilliantGlass", duration = 72000 },                       -- 20 hours
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
    tailoring = { "shadowcloth", "primalMooncloth", "spellcloth" },
    leatherworking = { "saltShaker" },
    alchemy = { "primalMight", "transmuteUndeathToWater", "transmutePrimalManaToFire", "transmutePrimalShadowToWater", "transmutePrimalAirToFire", "transmutePrimalWaterToShadow", "transmutePrimalEarthToWater", "transmutePrimalWaterToAir", "transmutePrimalLifeToEarth", "transmuteEarthstormDiamond", "transmuteSkyfireDiamond" },
    enchanting = { "voidSphere" },
    jewelcrafting = { "brilliantGlass" }
}

-- Friendly names for cooldown types
PL.COOLDOWN_NAMES = {
    shadowcloth = "Shadowcloth",
    primalMooncloth = "Primal Mooncloth",
    spellcloth = "Spellcloth",

    saltShaker = "Salt Shaker",

    primalMight = "Transmute: Primal Might",
    transmuteUndeathToWater = "Transmute: Undeath to Water",
    transmutePrimalManaToFire = "Transmute: Primal Mana to Fire",
    transmutePrimalShadowToWater = "Transmute: Primal Shadow to Water",
    transmutePrimalAirToFire = "Transmute: Primal Air to Fire",
    transmutePrimalWaterToShadow = "Transmute: Primal Water to Shadow",
    transmutePrimalEarthToWater = "Transmute: Primal Earth to Water",
    transmutePrimalWaterToAir = "Transmute: Primal Water to Air",
    transmutePrimalLifeToEarth = "Transmute: Primal Life to Earth",
    transmuteEarthstormDiamond = "Transmute: Earthstorm Diamond",
    transmuteSkyfireDiamond = "Transmute: Skyfire Diamond",

    voidSphere = "Void Sphere",

    brilliantGlass = "Brilliant Glass"
}

-- Spell IDs for each cooldown type (used to check if player knows the craft)
PL.COOLDOWN_SPELLS = {
    shadowcloth = 36686,
    primalMooncloth = 26751,
    spellcloth = 31373,

    saltShaker = 19566,

    primalMight = 29688,
    transmuteUndeathToWater = 17561,
    transmutePrimalManaToFire = 28582,
    transmutePrimalShadowToWater = 28580,
    transmutePrimalAirToFire = 28566,
    transmutePrimalWaterToShadow = 28581,
    transmutePrimalEarthToWater = 28567,
    transmutePrimalWaterToAir = 28569,
    transmutePrimalLifeToEarth = 28584,
    transmuteEarthstormDiamond = 32765,
    transmuteSkyfireDiamond = 32766,

    voidSphere = 28028,

    brilliantGlass = 47280
}

-- Cooldown durations
PL.COOLDOWN_DURATIONS = {
    shadowcloth = 331200, -- 92 hours
    primalMooncloth = 331200, -- 92 hours
    spellcloth = 331200, -- 92 hours

    saltShaker = 255600, -- 2d 23h

    primalMight = 72000,
    transmuteUndeathToWater = 86400, -- 24 hours
    transmutePrimalManaToFire = 72000,
    transmutePrimalShadowToWater = 72000,
    transmutePrimalAirToFire = 72000,
    transmutePrimalWaterToShadow = 72000,
    transmutePrimalEarthToWater = 72000,
    transmutePrimalWaterToAir = 72000,
    transmutePrimalLifeToEarth = 72000,
    transmuteEarthstormDiamond = 72000,
    transmuteSkyfireDiamond = 72000,

    voidSphere = 172800, -- 48 hours

    brilliantGlass = 72000 -- 20 hours
}

-- Source information for cooldown crafts
-- Format: cooldownType = { spellId, skillRequired, pattern = { itemId, name }, vendor = { npcId, name, tomtom } }
PL.COOLDOWN_SOURCES = {
    -- Tailoring
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
    },

    -- Alchemy (vendor-sold recipes)
    primalMight = {
        spellId = 29688,
        skillRequired = 350,
        pattern = { itemId = 23574, name = "Recipe: Transmute Primal Might" },
        vendor = { npcId = 19074, name = "Skreah", tomtom = "/way #1955 45.4 19.0 Skreah" }
    },
    transmutePrimalAirToFire = {
        spellId = 28566,
        skillRequired = 350,
        pattern = { itemId = 22915, name = "Recipe: Transmute Primal Air to Fire" },
        vendor = { npcId = 21432, name = "Almaador", tomtom = "/way #1955 51.2 41.4 Almaador" }
    },
    transmutePrimalEarthToWater = {
        spellId = 28567,
        skillRequired = 350,
        pattern = { itemId = 22916, name = "Recipe: Transmute Primal Earth to Water" },
        vendor = { npcId = 18382, name = "Mycah", tomtom = "/way #1946 17.8 51.2 Mycah" }
    },
    transmutePrimalWaterToAir = {
        spellId = 28569,
        skillRequired = 350,
        pattern = { itemId = 22918, name = "Recipe: Transmute Primal Water to Air" },
        vendor = { npcId = 17904, name = "Fedryen Swiftspear", tomtom = "/way #1946 79.2 63.8 Fedryen Swiftspear" }
    },
    transmutePrimalLifeToEarth = {
        spellId = 28584,
        skillRequired = 350,
        discovery = true
    },
    transmuteEarthstormDiamond = {
        spellId = 32765,
        skillRequired = 350,
        pattern = { itemId = 25869, name = "Recipe: Transmute Earthstorm Diamond" },
        vendor = { npcId = 17904, name = "Fedryen Swiftspear", tomtom = "/way #1946 79.2 63.8 Fedryen Swiftspear" }
    },
    transmuteSkyfireDiamond = {
        spellId = 32766,
        skillRequired = 350,
        pattern = { itemId = 25870, name = "Recipe: Transmute Skyfire Diamond" },
        vendor = { npcId = 17657, name = "Logistics Officer Ulrike", tomtom = "/way #1944 56.6 62.4 Logistics Officer Ulrike" },
        vendorHorde = { npcId = 17585, name = "Quartermaster Urgronn", tomtom = "/way #1944 54.9 37.9 Quartermaster Urgronn" }
    },

    -- Leatherworking
    saltShaker = {
        spellId = 19566,
        skillRequired = 250,
        item = { itemId = 15846, name = "Salt Shaker" },
        engineeringCraft = true
    },

    -- Enchanting
    voidSphere = {
        spellId = 28028,
        skillRequired = 350,
        trainer = true
    },

    -- Jewelcrafting
    brilliantGlass = {
        spellId = 47280,
        skillRequired = 375,
        trainer = true
    },
}

-- Profession spell names (for opening the tradeskill window)
PL.PROFESSION_SPELLS = {
    tailoring = "Tailoring",
    leatherworking = "Leatherworking",
    alchemy = "Alchemy",
    enchanting = "Enchanting",
    jewelcrafting = "Jewelcrafting"
}

-- Map cooldown types to their profession
PL.COOLDOWN_TO_PROFESSION = {
    shadowcloth = "tailoring",
    primalMooncloth = "tailoring",
    spellcloth = "tailoring",

    saltShaker = "leatherworking",

    primalMight = "alchemy",
    transmuteUndeathToWater = "alchemy",
    transmutePrimalManaToFire = "alchemy",
    transmutePrimalShadowToWater = "alchemy",
    transmutePrimalAirToFire = "alchemy",
    transmutePrimalWaterToShadow = "alchemy",
    transmutePrimalEarthToWater = "alchemy",
    transmutePrimalWaterToAir = "alchemy",
    transmutePrimalLifeToEarth = "alchemy",
    transmuteEarthstormDiamond = "alchemy",
    transmuteSkyfireDiamond = "alchemy",

    voidSphere = "enchanting",

    brilliantGlass = "jewelcrafting"
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

    -- Known crafts are detected by scanning the profession window (ScanTradeSkillWindow)
    -- and by detecting items in bags (DetectItemCooldowns).
    -- We do NOT use IsSpellKnown or GetSpellCooldown to mark crafts as known,
    -- because shared cooldowns (e.g. alchemy transmutes) would incorrectly
    -- mark all transmutes as known when only one is.

    -- Detect item-based cooldowns (e.g. Salt Shaker) by scanning bags
    self:DetectItemCooldowns(charKey)

    -- Poll GetSpellCooldown for already-known spells to detect active cooldowns
    self:PollSpellCooldowns(charKey)
end

-- Poll GetSpellCooldown() for all tracked spells on the current character
-- This detects active cooldowns without needing to open the profession window,
-- catching cooldowns that were started before the addon was installed or
-- that the event system missed.
function PL:PollSpellCooldowns(charKey)
    local charData = self.db.characters[charKey]
    if not charData then return end

    charData.knownCrafts = charData.knownCrafts or {}
    charData.cooldowns = charData.cooldowns or {}

    for cdType, spellID in pairs(self.COOLDOWN_SPELLS) do
        -- Only poll cooldowns for crafts already known (detected via profession window scan
        -- or bag scanning for item-based cooldowns like Salt Shaker).
        if charData.knownCrafts[cdType] then
            local start, duration = GetSpellCooldown(spellID)
            start = start or 0
            duration = duration or 0

            -- Filter out short cooldowns (<60s) to ignore GCDs and spell locks
            if duration > 0 and duration < 60 then
                -- skip, this is a GCD or spell lock
            elseif duration > 604800 then
                -- skip, bogus value (>7 days)
            else
                local now = GetTime()

                -- Fix WoW client overflow: start times far in the future
                if start > now + 2147483.648 then
                    start = start - 4294967.296
                end

                if start > 0 and duration > 0 then
                    -- Spell is on cooldown — store as epoch time so it persists across sessions
                    local remaining = (start + duration) - now

                    -- Sanity: remaining should not exceed the cooldown's duration
                    -- (start should always be <= now for active cooldowns).
                    -- If it does, GetSpellCooldown returned a bogus start value.
                    if remaining > 0 and remaining <= duration + 1 then
                        local expirationTime = time() + remaining

                        -- Only update if we don't have data, existing data shows ready,
                        -- or the polled expiration is later (more accurate)
                        local existing = charData.cooldowns[cdType]
                        if not existing or existing == 0 or expirationTime > existing then
                            charData.cooldowns[cdType] = expirationTime
                        end
                    end
                else
                    -- Spell is not on cooldown — mark as ready
                    local existing = charData.cooldowns[cdType]
                    if not existing then
                        charData.cooldowns[cdType] = 0
                    elseif existing > 0 and existing <= time() then
                        -- Existing cooldown has expired, mark ready
                        charData.cooldowns[cdType] = 0
                    end
                end
            end
        end
    end
end

-- Item IDs for item-based cooldowns
PL.COOLDOWN_ITEMS = {
    saltShaker = 15846,
}

-- Container API compatibility (renamed in some client versions)
local GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots
local GetContainerItemID = GetContainerItemID or C_Container.GetContainerItemID
local GetContainerItemCooldown = GetContainerItemCooldown or C_Container.GetContainerItemCooldown

-- Detect item-based cooldowns by scanning bags
function PL:DetectItemCooldowns(charKey)
    local charData = self.db.characters[charKey]
    if not charData then return end

    charData.knownCrafts = charData.knownCrafts or {}
    charData.cooldowns = charData.cooldowns or {}

    for cdType, itemID in pairs(self.COOLDOWN_ITEMS) do
        local found = false
        for bag = 0, 4 do
            local numSlots = GetContainerNumSlots(bag)
            for slot = 1, numSlots do
                local itemId = GetContainerItemID(bag, slot)
                if itemId == itemID then
                    found = true
                    charData.knownCrafts[cdType] = true

                    -- Check item cooldown
                    local startTime, duration, isEnabled = GetContainerItemCooldown(bag, slot)
                    if startTime and startTime > 0 and duration > 0 and isEnabled == 1 then
                        -- Filter out short cooldowns (<60s) to ignore GCDs or
                        -- brief item-use cooldowns that aren't the profession CD
                        if duration >= 60 then
                            local remaining = (startTime + duration) - GetTime()
                            if remaining > 0 then
                                local expirationTime = time() + remaining
                                -- Only update if this expires later than what we already have
                                local existing = charData.cooldowns[cdType]
                                if not existing or existing == 0 or expirationTime > existing then
                                    charData.cooldowns[cdType] = expirationTime
                                end
                            else
                                -- Item cooldown expired — only mark ready if no saved cooldown is still active
                                local existing = charData.cooldowns[cdType]
                                if not existing or existing == 0 or existing <= time() then
                                    charData.cooldowns[cdType] = 0
                                end
                            end
                        end
                        -- Short cooldowns (<60s) are ignored entirely
                    else
                        -- No item cooldown reported — only mark ready if no saved cooldown is still active
                        local existing = charData.cooldowns[cdType]
                        if not existing then
                            charData.cooldowns[cdType] = 0
                        elseif existing > 0 and existing <= time() then
                            charData.cooldowns[cdType] = 0
                        end
                    end
                    break
                end
            end
            if found then break end
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
    elseif tradeskillName == "Jewelcrafting" then
        professionKey = "jewelcrafting"
    else
        return -- Not a profession we track (Enchanting uses ScanCraftWindow)
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
                        -- Spell is on cooldown - store as epoch time so it persists across sessions
                        local expirationTime = time() + cooldownRemaining
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

-- Scan the craft window for cooldown data (Enchanting uses Craft API, not TradeSkill API)
function PL:ScanCraftWindow(charKey)
    local charData = self.db.characters[charKey]
    if not charData then return end

    local numCrafts = GetNumCrafts()
    if not numCrafts or numCrafts == 0 then return end

    local craftName = GetCraftDisplaySkillLine()
    if not craftName then return end

    local professionKey = nil
    if craftName == "Enchanting" then
        professionKey = "enchanting"
    else
        return -- Not a craft profession we track
    end

    -- Wipe existing data for this profession's crafts
    local professionCooldowns = self.PROFESSION_COOLDOWNS[professionKey]
    if professionCooldowns then
        for _, cdType in ipairs(professionCooldowns) do
            charData.knownCrafts[cdType] = nil
            charData.cooldowns[cdType] = nil
        end
    end

    -- Re-fetch known crafts and cooldowns from the craft window
    for i = 1, numCrafts do
        local name, _, craftType = GetCraftInfo(i)
        if name and craftType ~= "header" then
            for cdType, cdName in pairs(self.COOLDOWN_NAMES) do
                if name == cdName then
                    charData.knownCrafts[cdType] = true

                    -- GetCraftCooldown returns seconds remaining (same as GetTradeSkillCooldown)
                    local cooldownRemaining = GetCraftCooldown(i)
                    if cooldownRemaining and cooldownRemaining > 0 then
                        local expirationTime = time() + cooldownRemaining
                        charData.cooldowns[cdType] = expirationTime
                    else
                        charData.cooldowns[cdType] = 0
                    end
                    break
                end
            end
        end
    end
end

-- Check if a spell cast triggers a cooldown
function PL:CheckCooldownSpell(spellID)
    local cooldownInfo = self.COOLDOWNS[spellID]
    if cooldownInfo then
        local expirationTime = time() + cooldownInfo.duration
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

    local remaining = expirationTime - time()
    if remaining <= 0 then
        return 0 -- Ready
    end

    -- Sanity: no tracked cooldown should exceed 7 days (604800 seconds).
    -- If it does, the stored value is corrupt (e.g. old GetTime()-based data).
    if remaining > 604800 then
        local charData = self.db.characters[charKey]
        if charData and charData.cooldowns then
            charData.cooldowns[cooldownType] = 0
        end
        return 0
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
    local secs = math.floor(seconds % 60)

    local showSecs = self.db and self.db.settings and self.db.settings.showSeconds

    if days > 0 then
        if showSecs then
            return string.format("%dd %dh %dm %ds", days, hours, minutes, secs)
        end
        return string.format("%dd %dh %dm", days, hours, minutes)
    elseif hours > 0 then
        if showSecs then
            return string.format("%dh %dm %ds", hours, minutes, secs)
        end
        return string.format("%dh %dm", hours, minutes)
    else
        if showSecs then
            return string.format("%dm %ds", minutes, secs)
        end
        return string.format("%dm", minutes)
    end
end

-- Check if a cooldown type is enabled for tracking
function PL:IsCooldownEnabled(cdType)
    if not self.db or not self.db.settings or not self.db.settings.disabledCooldowns then
        return true
    end
    return not self.db.settings.disabledCooldowns[cdType]
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
            if knownCrafts[cdType] and self:IsCooldownEnabled(cdType) then
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

    -- Check leatherworking cooldowns
    if hasProfession(charData.professions.leatherworking) then
        for _, cdType in ipairs(self.PROFESSION_COOLDOWNS.leatherworking) do
            if knownCrafts[cdType] and self:IsCooldownEnabled(cdType) then
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
            if knownCrafts[cdType] and self:IsCooldownEnabled(cdType) then
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

    -- Check enchanting cooldowns
    if hasProfession(charData.professions.enchanting) then
        for _, cdType in ipairs(self.PROFESSION_COOLDOWNS.enchanting) do
            if knownCrafts[cdType] and self:IsCooldownEnabled(cdType) then
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

    -- Check jewelcrafting cooldowns
    if hasProfession(charData.professions.jewelcrafting) then
        for _, cdType in ipairs(self.PROFESSION_COOLDOWNS.jewelcrafting) do
            if knownCrafts[cdType] and self:IsCooldownEnabled(cdType) then
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

-- Get all ready cooldowns across all characters (for login notification)
function PL:GetAllReadyCooldowns()
    local ready = {}
    local characters = self:GetAllCharacters()

    for _, charInfo in ipairs(characters) do
        local charKey = charInfo.key
        local charData = charInfo.data

        if self:HasRelevantProfessions(charKey) then
            local cooldowns = self:GetCharacterCooldowns(charKey)
            for _, cd in ipairs(cooldowns) do
                if cd.remaining ~= nil and cd.remaining <= 0 then
                    table.insert(ready, {
                        charName = charData.name,
                        charClass = charData.class,
                        craftName = cd.name
                    })
                end
            end
        end
    end

    return ready
end

-- Check if character has Tailoring or Alchemy profession
function PL:HasRelevantProfessions(charKey)
    local charData = self.db.characters[charKey]
    if not charData or not charData.professions then return false end

    return hasProfession(charData.professions.tailoring) or hasProfession(charData.professions.leatherworking) or hasProfession(charData.professions.alchemy) or hasProfession(charData.professions.enchanting) or hasProfession(charData.professions.jewelcrafting)
end

-- Open profession window and select a specific recipe
function PL:OpenCraftingSpell(cdType)
    local profession = self.COOLDOWN_TO_PROFESSION[cdType]
    if not profession then return end

    local professionSpell = self.PROFESSION_SPELLS[profession]
    if not professionSpell then return end

    local spellName = self.COOLDOWN_NAMES[cdType]
    local isEnchanting = (profession == "enchanting")

    -- Check if the profession window is already open
    if isEnchanting then
        if CraftFrame and CraftFrame:IsShown() then
            self:SelectRecipeByName(spellName, true)
            return
        end
    else
        if TradeSkillFrame and TradeSkillFrame:IsShown() then
            self:SelectRecipeByName(spellName, false)
            return
        end
    end

    -- Store the spell we want to select after the window opens
    self.pendingSpellSelection = spellName
    self.pendingIsEnchanting = isEnchanting

    -- Create event/timer frame if not already
    if not self.tradeskillEventFrame then
        self.tradeskillEventFrame = CreateFrame("Frame")
        self.tradeskillEventFrame:RegisterEvent("TRADE_SKILL_SHOW")
        self.tradeskillEventFrame:RegisterEvent("CRAFT_SHOW")
        self.tradeskillEventFrame:SetScript("OnEvent", function(self, event)
            if not PL.pendingSpellSelection then return end
            local expectEnchanting = PL.pendingIsEnchanting
            if (event == "CRAFT_SHOW" and expectEnchanting) or (event == "TRADE_SKILL_SHOW" and not expectEnchanting) then
                self.waitTime = 0
                self.targetSpell = PL.pendingSpellSelection
                self.targetIsEnchanting = expectEnchanting
                PL.pendingSpellSelection = nil
                PL.pendingIsEnchanting = nil
                self:SetScript("OnUpdate", function(self, elapsed)
                    self.waitTime = self.waitTime + elapsed
                    if self.waitTime >= 0.3 then
                        self:SetScript("OnUpdate", nil)
                        PL:SelectRecipeByName(self.targetSpell, self.targetIsEnchanting)
                    end
                end)
            end
        end)
    end

    -- Open the profession window
    CastSpellByName(professionSpell)
end

-- Open the profession window without selecting a recipe (right-click action)
function PL:SelectCraftingSpell(cdType)
    local profession = self.COOLDOWN_TO_PROFESSION[cdType]
    if not profession then return end

    local professionSpell = self.PROFESSION_SPELLS[profession]
    if not professionSpell then return end

    CastSpellByName(professionSpell)
end

-- Find and select a recipe by name in the tradeskill or craft window
function PL:SelectRecipeByName(spellName, isEnchanting)
    if isEnchanting then
        local numCrafts = GetNumCrafts()
        if not numCrafts then return end

        for i = 1, numCrafts do
            local name, _, craftType = GetCraftInfo(i)
            if name and craftType ~= "header" and string.find(name, spellName, 1, true) then
                CraftFrame_SetSelection(i)
                return
            end
        end
        -- Fallback: reverse match
        for i = 1, numCrafts do
            local name, _, craftType = GetCraftInfo(i)
            if name and craftType ~= "header" and string.find(spellName, name, 1, true) then
                CraftFrame_SetSelection(i)
                return
            end
        end
    else
        -- Expand all collapsed headers so recipes are visible
        for i = GetNumTradeSkills(), 1, -1 do
            local _, skillType, _, isExpanded = GetTradeSkillInfo(i)
            if skillType == "header" and not isExpanded then
                ExpandTradeSkillSubClass(i)
            end
        end

        local numSkills = GetNumTradeSkills()
        if not numSkills then return end

        for i = 1, numSkills do
            local name, skillType = GetTradeSkillInfo(i)
            if name and skillType ~= "header" and string.find(name, spellName, 1, true) then
                TradeSkillFrame_SetSelection(i)
                return
            end
        end
        -- Fallback: reverse match
        for i = 1, numSkills do
            local name, skillType = GetTradeSkillInfo(i)
            if name and skillType ~= "header" and string.find(spellName, name, 1, true) then
                TradeSkillFrame_SetSelection(i)
                return
            end
        end
    end
end
