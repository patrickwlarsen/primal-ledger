-- PrimalLedger UI
-- Main display window

local addonName, PL = ...

-- Profession icons
local PROFESSION_ICONS = {
    alchemy = "Interface\\Icons\\Trade_Alchemy",
    blacksmithing = "Interface\\Icons\\Trade_BlackSmithing",
    enchanting = "Interface\\Icons\\Trade_Engraving",
    engineering = "Interface\\Icons\\Trade_Engineering",
    herbalism = "Interface\\Icons\\Spell_Nature_NatureTouchGrow",
    jewelcrafting = "Interface\\Icons\\INV_Misc_Gem_02",
    leatherworking = "Interface\\Icons\\Trade_LeatherWorking",
    mining = "Interface\\Icons\\Trade_Mining",
    skinning = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    tailoring = "Interface\\Icons\\Trade_Tailoring",
    cooking = "Interface\\Icons\\INV_Misc_Food_15",
    fishing = "Interface\\Icons\\Trade_Fishing",
    firstAid = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
}

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
local FRAME_WIDTH = 300   -- Default width
local FRAME_HEIGHT = 400  -- Default height
local MIN_WIDTH = 250
local MIN_HEIGHT = 200
local ROW_HEIGHT = 16
local HEADER_HEIGHT = 24
local PADDING = 10

-- Create the main frame
function PL:CreateMainFrame()
    if self.mainFrame then return end

    -- Determine initial size (from saved settings or defaults)
    local initialWidth = FRAME_WIDTH
    local initialHeight = FRAME_HEIGHT
    if self.db.settings.frameSize then
        initialWidth = self.db.settings.frameSize.width or FRAME_WIDTH
        initialHeight = self.db.settings.frameSize.height or FRAME_HEIGHT
    end

    -- Main frame
    local frame = CreateFrame("Frame", "PrimalLedgerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(initialWidth, initialHeight)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT)
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

    -- Modern backdrop - semi-transparent dark background with subtle border
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetHeight(HEADER_HEIGHT)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -PADDING)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -PADDING)

    -- Title icon
    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(20, 20)
    titleIcon:SetPoint("LEFT", titleBar, "LEFT", 0, 0)
    titleIcon:SetTexture("Interface\\AddOns\\PrimalLedger\\assets\\icon_map")
    titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Title text
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", titleIcon, "RIGHT", 6, 0)
    title:SetText("Primal Ledger - v" .. (PL.version or "1.0.0"))
    title:SetTextColor(0.9, 0.9, 0.9)

    -- Title separator line
    local titleSeparator = frame:CreateTexture(nil, "ARTWORK")
    titleSeparator:SetHeight(1)
    titleSeparator:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -4)
    titleSeparator:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, -4)
    titleSeparator:SetColorTexture(0.3, 0.3, 0.3, 1)

    -- Character info header
    local charHeader = CreateFrame("Frame", nil, frame)
    charHeader:SetHeight(ROW_HEIGHT)
    charHeader:SetPoint("TOPLEFT", titleSeparator, "BOTTOMLEFT", 0, -6)
    charHeader:SetPoint("TOPRIGHT", titleSeparator, "BOTTOMRIGHT", 0, -6)

    local charName = charHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charName:SetPoint("LEFT", charHeader, "LEFT", 0, 0)
    charName:SetJustifyH("LEFT")

    -- Create profession icon frames
    local iconSize = 16
    local iconSpacing = 4
    local professionIcons = {}
    local professionOrder = {
        "alchemy", "blacksmithing", "enchanting", "engineering", "herbalism",
        "jewelcrafting", "leatherworking", "mining", "skinning", "tailoring",
        "cooking", "fishing", "firstAid"
    }

    for i, profKey in ipairs(professionOrder) do
        local iconFrame = CreateFrame("Frame", nil, charHeader)
        iconFrame:SetSize(iconSize, iconSize)

        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture(PROFESSION_ICONS[profKey])
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim icon borders

        iconFrame.icon = icon
        iconFrame.profKey = profKey
        iconFrame:Hide()

        -- Tooltip on hover
        iconFrame:EnableMouse(true)
        iconFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.profName or profKey)
            if self.profLevel then
                GameTooltip:AddLine("Level: " .. self.profLevel, 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        iconFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        professionIcons[profKey] = iconFrame
    end

    frame.charHeader = charHeader
    frame.charName = charName
    frame.professionIcons = professionIcons
    frame.professionOrder = professionOrder

    -- Header separator line
    local headerSeparator = frame:CreateTexture(nil, "ARTWORK")
    headerSeparator:SetHeight(1)
    headerSeparator:SetPoint("TOPLEFT", charHeader, "BOTTOMLEFT", 0, -6)
    headerSeparator:SetPoint("TOPRIGHT", charHeader, "BOTTOMRIGHT", 0, -6)
    headerSeparator:SetColorTexture(0.3, 0.3, 0.3, 1)

    frame.headerSeparator = headerSeparator

    -- Tab bar
    local tabBar = CreateFrame("Frame", nil, frame)
    tabBar:SetHeight(22)
    tabBar:SetPoint("TOPLEFT", headerSeparator, "BOTTOMLEFT", 0, -4)
    tabBar:SetPoint("TOPRIGHT", headerSeparator, "BOTTOMRIGHT", 0, -4)

    -- Tab button creation helper
    local function CreateTab(parent, name, tabIndex)
        local tab = CreateFrame("Button", nil, parent)
        tab:SetHeight(20)

        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tab.text:SetPoint("CENTER", tab, "CENTER", 0, 0)
        tab.text:SetText(name)

        -- Background for selected state
        tab.selectedBg = tab:CreateTexture(nil, "BACKGROUND")
        tab.selectedBg:SetAllPoints()
        tab.selectedBg:SetColorTexture(0.2, 0.2, 0.2, 1)
        tab.selectedBg:Hide()

        -- Underline for selected state
        tab.underline = tab:CreateTexture(nil, "ARTWORK")
        tab.underline:SetHeight(2)
        tab.underline:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
        tab.underline:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
        tab.underline:SetColorTexture(0.4, 0.6, 1, 1)
        tab.underline:Hide()

        tab.tabIndex = tabIndex

        tab:SetScript("OnEnter", function(self)
            if not self.isSelected then
                self.text:SetTextColor(1, 1, 1)
            end
        end)

        tab:SetScript("OnLeave", function(self)
            if not self.isSelected then
                self.text:SetTextColor(0.6, 0.6, 0.6)
            end
        end)

        tab:SetScript("OnClick", function(self)
            PL:SelectTab(self.tabIndex)
        end)

        -- Initial state
        tab.text:SetTextColor(0.6, 0.6, 0.6)
        tab:SetWidth(tab.text:GetStringWidth() + 16)

        return tab
    end

    -- Create tabs
    local overviewTab = CreateTab(tabBar, "Overview", 1)
    overviewTab:SetPoint("LEFT", tabBar, "LEFT", 0, 0)

    local cooldownsTab = CreateTab(tabBar, "Cooldowns", 2)
    cooldownsTab:SetPoint("LEFT", overviewTab, "RIGHT", 8, 0)

    frame.tabs = { overviewTab, cooldownsTab }
    frame.tabBar = tabBar
    frame.selectedTab = 1

    -- Tab separator line
    local tabSeparator = frame:CreateTexture(nil, "ARTWORK")
    tabSeparator:SetHeight(1)
    tabSeparator:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -2)
    tabSeparator:SetPoint("TOPRIGHT", tabBar, "BOTTOMRIGHT", 0, -2)
    tabSeparator:SetColorTexture(0.3, 0.3, 0.3, 1)

    frame.tabSeparator = tabSeparator

    -- Custom close button
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -PADDING)

    local closeBtnText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeBtnText:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
    closeBtnText:SetText("X")
    closeBtnText:SetTextColor(0.6, 0.6, 0.6)

    closeBtn:SetScript("OnEnter", function()
        closeBtnText:SetTextColor(1, 0.3, 0.3)
    end)
    closeBtn:SetScript("OnLeave", function()
        closeBtnText:SetTextColor(0.6, 0.6, 0.6)
    end)
    closeBtn:SetScript("OnClick", function()
        PL:ToggleMainFrame()
    end)

    -- Resize grip
    local resizeBtn = CreateFrame("Button", nil, frame)
    resizeBtn:SetSize(16, 16)
    resizeBtn:SetPoint("BOTTOMRIGHT", -2, 2)
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeBtn:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    resizeBtn:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        -- Save new size
        PL.db.settings.frameSize = { width = frame:GetWidth(), height = frame:GetHeight() }
        -- Update content width for scroll child
        if frame.content then
            frame.content:SetWidth(frame:GetWidth() - 40)
        end
    end)

    frame.resizeBtn = resizeBtn

    -- Scroll frame for character list
    local scrollFrame = CreateFrame("ScrollFrame", "PrimalLedgerScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", tabSeparator, "BOTTOMLEFT", 0, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, PADDING + 16)

    -- Content frame inside scroll frame
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(frame:GetWidth() - 40, 1) -- Height will be set dynamically
    scrollFrame:SetScrollChild(content)

    frame.scrollFrame = scrollFrame
    frame.content = content
    frame.rows = {}
    frame.separators = {}

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

    -- Select first tab by default
    self:SelectTab(1)
end

-- Profession order for icon display
local PROFESSION_ORDER = {
    "alchemy", "blacksmithing", "enchanting", "engineering", "herbalism",
    "jewelcrafting", "leatherworking", "mining", "skinning", "tailoring",
    "cooking", "fishing", "firstAid"
}

local PROFESSION_NAMES = {
    alchemy = "Alchemy", blacksmithing = "Blacksmithing", enchanting = "Enchanting",
    engineering = "Engineering", herbalism = "Herbalism", jewelcrafting = "Jewelcrafting",
    leatherworking = "Leatherworking", mining = "Mining", skinning = "Skinning",
    tailoring = "Tailoring", cooking = "Cooking", fishing = "Fishing", firstAid = "First Aid"
}

-- Create a row for displaying cooldown info
local function CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -((index - 1) * ROW_HEIGHT))

    -- Hover highlight background
    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints(row)
    row.highlight:SetColorTexture(1, 1, 1, 0.05)
    row.highlight:Hide()

    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        self.highlight:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.highlight:Hide()
    end)

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.text:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.text:SetJustifyH("LEFT")

    -- Create profession icons for character header rows
    local iconSize = 14
    row.profIcons = {}
    for _, profKey in ipairs(PROFESSION_ORDER) do
        local iconFrame = CreateFrame("Frame", nil, row)
        iconFrame:SetSize(iconSize, iconSize)

        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture(PROFESSION_ICONS[profKey])
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        iconFrame.icon = icon
        iconFrame.profKey = profKey
        iconFrame:Hide()

        iconFrame:EnableMouse(true)
        iconFrame:SetScript("OnEnter", function(self)
            row.highlight:Show()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.profName or PROFESSION_NAMES[profKey])
            if self.profLevel then
                GameTooltip:AddLine("Level: " .. self.profLevel, 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        iconFrame:SetScript("OnLeave", function(self)
            row.highlight:Hide()
            GameTooltip:Hide()
        end)

        row.profIcons[profKey] = iconFrame
    end

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
        row.highlight:Show()
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
        row.highlight:Hide()
        if self.isClickable then
            row.time:SetTextColor(0, 1, 0) -- Back to green
        end
        GameTooltip:Hide()
    end)

    return row
end

-- Create a separator line between character sections
local function CreateSeparator(parent, yOffset)
    local separator = parent:CreateTexture(nil, "ARTWORK")
    separator:SetHeight(1)
    separator:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
    separator:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, yOffset)
    separator:SetColorTexture(0.25, 0.25, 0.25, 0.8)
    return separator
end

-- Update the main frame content
function PL:UpdateMainFrame()
    if not self.mainFrame then return end

    local content = self.mainFrame.content
    local characters = self:GetAllCharacters()
    local currentCharKey = self:GetCharacterKey()
    local rowIndex = 0
    local charCount = 0

    -- Update character header
    local currentCharData = self.db.characters[currentCharKey]
    if currentCharData then
        local classColor = CLASS_COLORS[currentCharData.class] or { r = 1, g = 1, b = 1 }
        self.mainFrame.charName:SetText(currentCharData.name)
        self.mainFrame.charName:SetTextColor(classColor.r, classColor.g, classColor.b)

        -- Display profession icons
        local iconSize = 16
        local iconSpacing = 4
        local lastIcon = nil
        local iconCount = 0

        local profNames = {
            alchemy = "Alchemy", blacksmithing = "Blacksmithing", enchanting = "Enchanting",
            engineering = "Engineering", herbalism = "Herbalism", jewelcrafting = "Jewelcrafting",
            leatherworking = "Leatherworking", mining = "Mining", skinning = "Skinning",
            tailoring = "Tailoring", cooking = "Cooking", fishing = "Fishing", firstAid = "First Aid"
        }

        -- Hide all icons first
        for _, iconFrame in pairs(self.mainFrame.professionIcons) do
            iconFrame:Hide()
        end

        -- Show and position icons for known professions
        if currentCharData.professions then
            local p = currentCharData.professions
            for _, profKey in ipairs(self.mainFrame.professionOrder) do
                local value = p[profKey]
                if value and value ~= false and (type(value) ~= "number" or value > 0) then
                    local iconFrame = self.mainFrame.professionIcons[profKey]
                    iconFrame.profName = profNames[profKey]
                    iconFrame.profLevel = type(value) == "number" and value or nil

                    if lastIcon then
                        iconFrame:SetPoint("LEFT", lastIcon, "RIGHT", iconSpacing, 0)
                    else
                        iconFrame:SetPoint("LEFT", self.mainFrame.charName, "RIGHT", 8, 0)
                    end

                    iconFrame:Show()
                    lastIcon = iconFrame
                    iconCount = iconCount + 1
                end
            end
        end
    else
        self.mainFrame.charName:SetText("Unknown")
        self.mainFrame.charName:SetTextColor(0.5, 0.5, 0.5)
        -- Hide all icons
        for _, iconFrame in pairs(self.mainFrame.professionIcons) do
            iconFrame:Hide()
        end
    end

    -- Adjust minimum width based on header content
    local iconCount = 0
    for _, iconFrame in pairs(self.mainFrame.professionIcons) do
        if iconFrame:IsShown() then
            iconCount = iconCount + 1
        end
    end
    local headerWidth = self.mainFrame.charName:GetStringWidth() + (iconCount * 20) + PADDING * 3 + 16
    local minWidth = math.max(MIN_WIDTH, headerWidth)
    self.mainFrame:SetResizeBounds(minWidth, MIN_HEIGHT)

    -- If current width is less than new minimum, resize the frame
    if self.mainFrame:GetWidth() < minWidth then
        self.mainFrame:SetWidth(minWidth)
        if self.mainFrame.content then
            self.mainFrame.content:SetWidth(minWidth - 40)
        end
    end

    -- Clear existing rows
    for _, row in pairs(self.mainFrame.rows) do
        row:Hide()
        if row.timeBtn then
            row.timeBtn.isClickable = false
            row.timeBtn:SetScript("OnClick", nil)
        end
        -- Hide profession icons
        if row.profIcons then
            for _, iconFrame in pairs(row.profIcons) do
                iconFrame:Hide()
            end
        end
    end

    -- Clear existing separators
    for _, sep in pairs(self.mainFrame.separators) do
        sep:Hide()
    end

    local selectedTab = self.mainFrame.selectedTab or 1

    -- OVERVIEW TAB: Show all characters with their professions
    if selectedTab == 1 then
        for _, charInfo in ipairs(characters) do
            local charKey = charInfo.key
            local charData = charInfo.data
            charCount = charCount + 1

            -- Add separator before character (except first one)
            if charCount > 1 then
                local sepIndex = charCount - 1
                local separator = self.mainFrame.separators[sepIndex]
                if not separator then
                    separator = CreateSeparator(content, -(rowIndex * ROW_HEIGHT) - 2)
                    self.mainFrame.separators[sepIndex] = separator
                else
                    separator:ClearAllPoints()
                    separator:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(rowIndex * ROW_HEIGHT) - 2)
                    separator:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(rowIndex * ROW_HEIGHT) - 2)
                end
                separator:Show()

                -- Add extra spacing for separator
                rowIndex = rowIndex + 0.5
            end

            -- Character row
            rowIndex = rowIndex + 1
            local charRow = self.mainFrame.rows[rowIndex]
            if not charRow then
                charRow = CreateRow(content, rowIndex)
                self.mainFrame.rows[rowIndex] = charRow
            end

            -- Update row position
            charRow:ClearAllPoints()
            charRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((rowIndex - 1) * ROW_HEIGHT))
            charRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -((rowIndex - 1) * ROW_HEIGHT))

            -- Set character name with class color
            local classColor = CLASS_COLORS[charData.class] or { r = 1, g = 1, b = 1 }
            charRow.text:SetTextColor(classColor.r, classColor.g, classColor.b)
            charRow.text:SetText(charData.name)

            -- Show profession icons
            local cp = charData.professions or {}
            local iconSpacing = 3
            local lastIcon = nil

            for _, profKey in ipairs(PROFESSION_ORDER) do
                local value = cp[profKey]
                if value and value ~= false and (type(value) ~= "number" or value > 0) then
                    local iconFrame = charRow.profIcons[profKey]
                    iconFrame.profName = PROFESSION_NAMES[profKey]
                    iconFrame.profLevel = type(value) == "number" and value or nil

                    iconFrame:ClearAllPoints()
                    if lastIcon then
                        iconFrame:SetPoint("LEFT", lastIcon, "RIGHT", iconSpacing, 0)
                    else
                        iconFrame:SetPoint("LEFT", charRow.text, "RIGHT", 6, 0)
                    end

                    iconFrame:Show()
                    lastIcon = iconFrame
                end
            end

            charRow.time:SetText("")
            charRow.timeBtn.isClickable = false
            charRow:Show()
        end

        -- Show message if no characters
        if rowIndex == 0 then
            rowIndex = 1
            local emptyRow = self.mainFrame.rows[1]
            if not emptyRow then
                emptyRow = CreateRow(content, 1)
                self.mainFrame.rows[1] = emptyRow
            end
            emptyRow.text:SetTextColor(0.5, 0.5, 0.5)
            emptyRow.text:SetText("No characters found.")
            emptyRow.time:SetText("")
            emptyRow.timeBtn.isClickable = false
            emptyRow:Show()
        end

    -- COOLDOWNS TAB: Show characters with cooldowns (no profession icons)
    elseif selectedTab == 2 then
        for _, charInfo in ipairs(characters) do
            local charKey = charInfo.key
            local charData = charInfo.data
            local isCurrentChar = (charKey == currentCharKey)

            if self:HasRelevantProfessions(charKey) then
                charCount = charCount + 1

                -- Add separator before character (except first one)
                if charCount > 1 then
                    local sepIndex = charCount - 1
                    local separator = self.mainFrame.separators[sepIndex]
                    if not separator then
                        separator = CreateSeparator(content, -(rowIndex * ROW_HEIGHT) - 2)
                        self.mainFrame.separators[sepIndex] = separator
                    else
                        separator:ClearAllPoints()
                        separator:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(rowIndex * ROW_HEIGHT) - 2)
                        separator:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(rowIndex * ROW_HEIGHT) - 2)
                    end
                    separator:Show()

                    -- Add extra spacing for separator
                    rowIndex = rowIndex + 0.5
                end

                -- Character header row
                rowIndex = rowIndex + 1
                local headerRow = self.mainFrame.rows[rowIndex]
                if not headerRow then
                    headerRow = CreateRow(content, rowIndex)
                    self.mainFrame.rows[rowIndex] = headerRow
                end

                -- Update row position
                headerRow:ClearAllPoints()
                headerRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((rowIndex - 1) * ROW_HEIGHT))
                headerRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -((rowIndex - 1) * ROW_HEIGHT))

                -- Set character name with class color
                local classColor = CLASS_COLORS[charData.class] or { r = 1, g = 1, b = 1 }
                headerRow.text:SetTextColor(classColor.r, classColor.g, classColor.b)
                headerRow.text:SetText(charData.name)

                headerRow.time:SetText("")
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

                    -- Update row position
                    cdRow:ClearAllPoints()
                    cdRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((rowIndex - 1) * ROW_HEIGHT))
                    cdRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -((rowIndex - 1) * ROW_HEIGHT))

                    cdRow.text:SetTextColor(0.7, 0.7, 0.7)
                    cdRow.text:SetText("  " .. cd.name)

                    -- Color the time based on ready status
                    if cd.remaining == nil then
                        cdRow.time:SetTextColor(0.4, 0.4, 0.4)
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

        -- Show message if no characters with cooldowns
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
    end

    -- Update content height
    content:SetHeight(rowIndex * ROW_HEIGHT + 10)
end

-- Toggle main frame visibility
-- Select a tab
function PL:SelectTab(tabIndex)
    if not self.mainFrame or not self.mainFrame.tabs then return end

    -- Update tab appearances
    for i, tab in ipairs(self.mainFrame.tabs) do
        if i == tabIndex then
            tab.isSelected = true
            tab.text:SetTextColor(1, 1, 1)
            tab.selectedBg:Show()
            tab.underline:Show()
        else
            tab.isSelected = false
            tab.text:SetTextColor(0.6, 0.6, 0.6)
            tab.selectedBg:Hide()
            tab.underline:Hide()
        end
    end

    self.mainFrame.selectedTab = tabIndex

    -- Update content based on selected tab
    self:UpdateMainFrame()
end

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
