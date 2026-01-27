-- PrimalLedger UI
-- Main display window

local addonName, PL = ...

-- Class colors for character names
local CLASS_COLORS = {
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
    ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
    PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
    SHAMAN = { r = 0.00, g = 0.44, b = 0.87 },
    MAGE = { r = 0.41, g = 0.80, b = 0.94 },
    WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
    DRUID = { r = 1.00, g = 0.49, b = 0.04 },
}

-- Frame dimensions
local FRAME_WIDTH = 300
local FRAME_HEIGHT = 400
local ROW_HEIGHT = 16
local HEADER_HEIGHT = 24
local PADDING = 10

-- Create the main frame
function PL:CreateMainFrame()
    if self.mainFrame then return end

    -- Main frame
    local frame = CreateFrame("Frame", "PrimalLedgerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, _, x, y = self:GetPoint()
        PL.db.settings.framePosition = { point = point, x = x, y = y }
    end)

    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetHeight(HEADER_HEIGHT)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -PADDING)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -PADDING)

    -- Title text
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleBar, "LEFT", 0, 0)
    title:SetText("Primal Ledger")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        PL:ToggleMainFrame()
    end)

    -- Scroll frame for character list
    local scrollFrame = CreateFrame("ScrollFrame", "PrimalLedgerScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -PADDING)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, PADDING)

    -- Content frame inside scroll frame
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(FRAME_WIDTH - 40, 1) -- Height will be set dynamically
    scrollFrame:SetScrollChild(content)

    frame.content = content
    frame.rows = {}

    -- Hide by default
    frame:Hide()

    -- Restore saved position
    if self.db.settings.framePosition then
        local pos = self.db.settings.framePosition
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    end

    -- Update timer
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.timeSinceUpdate = (self.timeSinceUpdate or 0) + elapsed
        if self.timeSinceUpdate >= 1 then
            self.timeSinceUpdate = 0
            if self:IsShown() then
                PL:UpdateMainFrame()
            end
        end
    end)

    self.mainFrame = frame
end

-- Create a row for displaying cooldown info
local function CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -((index - 1) * ROW_HEIGHT))

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.text:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.text:SetJustifyH("LEFT")

    -- Create a button for the time/status (for clickable "Ready!" text)
    row.timeBtn = CreateFrame("Button", nil, row)
    row.timeBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.timeBtn:SetHeight(ROW_HEIGHT)
    row.timeBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    row.time = row.timeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.time:SetPoint("RIGHT", row.timeBtn, "RIGHT", 0, 0)
    row.time:SetJustifyH("RIGHT")

    -- Highlight on hover when clickable
    row.timeBtn:SetScript("OnEnter", function(self)
        if self.isClickable then
            row.time:SetTextColor(0.5, 1, 0.5) -- Lighter green on hover
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Ready to craft!")
            GameTooltip:AddLine("|cffffffffLeft-click:|r Open profession window", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("|cffffffffRight-click:|r Select recipe", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end
    end)

    row.timeBtn:SetScript("OnLeave", function(self)
        if self.isClickable then
            row.time:SetTextColor(0, 1, 0) -- Back to green
        end
        GameTooltip:Hide()
    end)

    return row
end

-- Update the main frame content
function PL:UpdateMainFrame()
    if not self.mainFrame then return end

    local content = self.mainFrame.content
    local characters = self:GetAllCharacters()
    local currentCharKey = self:GetCharacterKey()
    local rowIndex = 0

    -- Clear existing rows
    for _, row in ipairs(self.mainFrame.rows) do
        row:Hide()
        if row.timeBtn then
            row.timeBtn.isClickable = false
            row.timeBtn:SetScript("OnClick", nil)
        end
    end

    -- Display characters with relevant professions
    for _, charInfo in ipairs(characters) do
        local charKey = charInfo.key
        local charData = charInfo.data
        local isCurrentChar = (charKey == currentCharKey)

        if self:HasRelevantProfessions(charKey) then
            -- Character header row
            rowIndex = rowIndex + 1
            local headerRow = self.mainFrame.rows[rowIndex]
            if not headerRow then
                headerRow = CreateRow(content, rowIndex)
                self.mainFrame.rows[rowIndex] = headerRow
            end

            -- Set character name with class color
            local classColor = CLASS_COLORS[charData.class] or { r = 1, g = 1, b = 1 }
            headerRow.text:SetTextColor(classColor.r, classColor.g, classColor.b)
            headerRow.text:SetText(charData.name)

            -- Show professions on the right
            local profs = {}
            if charData.professions.tailoring then table.insert(profs, "Tailoring") end
            if charData.professions.alchemy then table.insert(profs, "Alchemy") end
            headerRow.time:SetTextColor(0.6, 0.6, 0.6)
            headerRow.time:SetText(table.concat(profs, ", "))
            headerRow.timeBtn.isClickable = false
            headerRow:Show()

            -- Cooldown rows
            local cooldowns = self:GetCharacterCooldowns(charKey)
            for _, cd in ipairs(cooldowns) do
                rowIndex = rowIndex + 1
                local cdRow = self.mainFrame.rows[rowIndex]
                if not cdRow then
                    cdRow = CreateRow(content, rowIndex)
                    self.mainFrame.rows[rowIndex] = cdRow
                end

                cdRow.text:SetTextColor(0.8, 0.8, 0.8)
                cdRow.text:SetText("  " .. cd.name)

                -- Color the time based on ready status
                if cd.remaining == nil then
                    cdRow.time:SetTextColor(0.5, 0.5, 0.5)
                    cdRow.time:SetText("--")
                    cdRow.timeBtn.isClickable = false
                elseif cd.remaining <= 0 then
                    cdRow.time:SetTextColor(0, 1, 0)
                    cdRow.time:SetText("Ready!")

                    -- Make clickable only for current character
                    if isCurrentChar then
                        cdRow.timeBtn.isClickable = true
                        local cdType = cd.type
                        cdRow.timeBtn:SetScript("OnClick", function(self, button)
                            if button == "LeftButton" then
                                PL:OpenCraftingSpell(cdType)
                            elseif button == "RightButton" then
                                PL:SelectCraftingSpell(cdType)
                            end
                        end)
                    else
                        cdRow.timeBtn.isClickable = false
                    end
                else
                    cdRow.time:SetTextColor(1, 0.82, 0)
                    cdRow.time:SetText(cd.formattedTime)
                    cdRow.timeBtn.isClickable = false
                end

                -- Adjust button width to fit text
                cdRow.timeBtn:SetWidth(cdRow.time:GetStringWidth() + 4)

                cdRow:Show()
            end
        end
    end

    -- Show message if no characters tracked
    if rowIndex == 0 then
        rowIndex = 1
        local emptyRow = self.mainFrame.rows[1]
        if not emptyRow then
            emptyRow = CreateRow(content, 1)
            self.mainFrame.rows[1] = emptyRow
        end
        emptyRow.text:SetTextColor(0.5, 0.5, 0.5)
        emptyRow.text:SetText("No characters with Tailoring or Alchemy found.")
        emptyRow.time:SetText("")
        emptyRow.timeBtn.isClickable = false
        emptyRow:Show()
    end

    -- Update content height
    content:SetHeight(rowIndex * ROW_HEIGHT)
end

-- Toggle main frame visibility
function PL:ToggleMainFrame()
    if not self.mainFrame then
        self:CreateMainFrame()
    end

    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
    else
        -- Refresh current character's known crafts
        local charKey = self:GetCharacterKey()
        self:DetectKnownCrafts(charKey)

        self:UpdateMainFrame()
        self.mainFrame:Show()
    end
end
