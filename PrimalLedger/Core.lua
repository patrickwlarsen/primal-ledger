-- PrimalLedger Core
-- Main addon initialization and event handling

local addonName, PL = ...

-- Addon namespace
PL.version = "1.0.0"
PL.addonLoaded = false
PL.playerLoggedIn = false

-- Create main frame for event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
eventFrame:RegisterEvent("TRADE_SKILL_UPDATE")

-- Event handler
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            PL:OnAddonLoaded()
        end
    elseif event == "PLAYER_LOGIN" then
        PL:OnPlayerLogin()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" then
            PL:OnSpellCast(spellID)
        end
    elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE" then
        PL:OnTradeSkillUpdate()
    end
end)

-- Called when addon is loaded
function PL:OnAddonLoaded()
    self.addonLoaded = true
    self:InitializeData()
    self:Print("v" .. self.version .. " loaded. Type /pl to open.")
end

-- Called when player logs in
function PL:OnPlayerLogin()
    self.playerLoggedIn = true
    self:UpdateCurrentCharacter()
    self:CreateMinimapButton()
    self:CreateMainFrame()
end

-- Called when player casts a spell
function PL:OnSpellCast(spellID)
    self:CheckCooldownSpell(spellID)
end

-- Called when tradeskill window is shown or updated
function PL:OnTradeSkillUpdate()
    if not self.playerLoggedIn then return end
    local charKey = self:GetCharacterKey()
    self:ScanTradeSkillWindow(charKey)
end

-- Print helper
function PL:Print(msg)
    print("|cff00ff00[PrimalLedger]|r " .. msg)
end

-- Slash commands
SLASH_PRIMALLEDGER1 = "/primalledger"
SLASH_PRIMALLEDGER2 = "/pl"
SlashCmdList["PRIMALLEDGER"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "reset" then
        PL:ResetData()
        PL:Print("Data has been reset.")
    elseif msg == "remove" then
        PL:RemoveCurrentCharacter()
    else
        PL:ToggleMainFrame()
    end
end

-- Export addon table
_G["PrimalLedger"] = PL
