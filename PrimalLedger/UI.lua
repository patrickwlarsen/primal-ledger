-- PrimalLedger UI
-- Main display window

local addonName, PL = ...

-- Static popup for reset data confirmation
StaticPopupDialogs["PRIMAL_LEDGER_RESET_CONFIRM"] = {
    text = "Are you sure you want to reset all Primal Ledger data? This will remove all tracked characters and cooldowns.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        PL:ResetData()
        PL:Print("All data has been reset.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

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

-- Color palette (Outland / Dark Portal theme)
local COLORS = {
    bg =            { 0.08, 0.05, 0.03, 1 },         -- dark brown-black
    border =        { 0.35, 0.22, 0.10, 1 },         -- dark bronze
    separator =     { 0.40, 0.30, 0.20, 1 },         -- warm brown
    separatorFaint ={ 0.30, 0.22, 0.15, 1 },         -- faint brown
    highlight =     { 0.80, 0.50, 0.20, 0.08 },      -- warm highlight
    accent =        { 0.85, 0.45, 0.15 },             -- orange (title, headers, links)
    accentHover =   { 1.00, 0.60, 0.20 },             -- brighter orange hover
    accentMuted =   { 0.75, 0.55, 0.30 },             -- muted orange
    textNormal =    { 0.85, 0.80, 0.70 },             -- warm off-white
    textDim =       { 0.60, 0.50, 0.35 },             -- warm gray
    textFaint =     { 0.45, 0.38, 0.28 },             -- faint warm gray
    ready =         { 0.20, 0.80, 0.20 },             -- fel green
    readyHover =    { 0.40, 1.00, 0.40 },             -- lighter fel green
    closeHover =    { 0.90, 0.40, 0.10 },             -- orange-red
    tabSelectedBg = { 0.15, 0.10, 0.05, 1 },          -- dark warm bg
    btnBg =         { 0.60, 0.15, 0.15, 1 },          -- red button
    btnBgHover =    { 0.80, 0.20, 0.20, 1 },          -- red button hover
}

-- Apply UI scale to the tracker window only
function PL:ApplyUIScale()
    local scale = (self.db and self.db.settings.uiScale or 100) / 100
    if self.trackerFrame then
        self.trackerFrame:SetScale(scale)
        -- Lock button is parented to UIParent, scale it separately
        if self.trackerFrame.lockBtn then
            self.trackerFrame.lockBtn:SetScale(scale)
        end
    end
end

-- Frame dimensions
local FRAME_WIDTH = 300   -- Default width
local FRAME_HEIGHT = 400  -- Default height
local MIN_WIDTH = 250
local MIN_HEIGHT = 200
local ROW_HEIGHT = 16
local HEADER_HEIGHT = 24
local PADDING = 10

-- Get the tracker transparency setting as an alpha value (0.0 to 1.0)
function PL:GetTrackerAlpha()
    local pct = self.db.settings.trackerOpacity
    if pct == nil then pct = 100 end
    return pct / 100
end

-- Apply transparency to the tracker window (background only, not text)
function PL:ApplyTrackerAlpha()
    if self.trackerFrame then
        local alpha = self:GetTrackerAlpha()
        self.trackerFrame:SetBackdropColor(0.08, 0.05, 0.03, alpha)
        self.trackerFrame:SetBackdropBorderColor(0.35, 0.22, 0.10, alpha)
    end
end

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
    tinsert(UISpecialFrames, "PrimalLedgerFrame") -- Close on ESC
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

    -- Backdrop - dark Outland theme
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(unpack(COLORS.bg))
    frame:SetBackdropBorderColor(unpack(COLORS.border))

    -- Header image
    local headerImage = frame:CreateTexture(nil, "ARTWORK")
    headerImage:SetHeight(60)
    headerImage:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    headerImage:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    headerImage:SetTexture("Interface\\AddOns\\PrimalLedger\\assets\\header")
    headerImage:SetTexCoord(0, 1, 0.05, 0.95)

    -- Title bar (anchored over the header image)
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetHeight(HEADER_HEIGHT)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -PADDING)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -PADDING)

    -- Version text overlay
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("BOTTOMRIGHT", headerImage, "BOTTOMRIGHT", -PADDING, 4)
    title:SetText("v" .. (PL.version or "1.0.0"))
    title:SetTextColor(COLORS.textDim[1], COLORS.textDim[2], COLORS.textDim[3], 0.8)

    -- Title separator line
    local titleSeparator = frame:CreateTexture(nil, "ARTWORK")
    titleSeparator:SetHeight(1)
    titleSeparator:SetPoint("TOPLEFT", headerImage, "BOTTOMLEFT", PADDING, 0)
    titleSeparator:SetPoint("TOPRIGHT", headerImage, "BOTTOMRIGHT", -PADDING, 0)
    titleSeparator:SetColorTexture(unpack(COLORS.separator))

    -- Tab bar
    local tabBar = CreateFrame("Frame", nil, frame)
    tabBar:SetHeight(22)
    tabBar:SetPoint("TOPLEFT", titleSeparator, "BOTTOMLEFT", 0, -4)
    tabBar:SetPoint("TOPRIGHT", titleSeparator, "BOTTOMRIGHT", 0, -4)

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
        tab.selectedBg:SetColorTexture(unpack(COLORS.tabSelectedBg))
        tab.selectedBg:Hide()

        -- Underline for selected state
        tab.underline = tab:CreateTexture(nil, "ARTWORK")
        tab.underline:SetHeight(2)
        tab.underline:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
        tab.underline:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
        tab.underline:SetColorTexture(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 1)
        tab.underline:Hide()

        tab.tabIndex = tabIndex

        tab:SetScript("OnEnter", function(self)
            if not self.isSelected then
                self.text:SetTextColor(unpack(COLORS.accentMuted))
            end
        end)

        tab:SetScript("OnLeave", function(self)
            if not self.isSelected then
                self.text:SetTextColor(unpack(COLORS.textDim))
            end
        end)

        tab:SetScript("OnClick", function(self)
            PL:SelectTab(self.tabIndex)
        end)

        -- Initial state
        tab.text:SetTextColor(unpack(COLORS.textDim))
        tab:SetWidth(tab.text:GetStringWidth() + 16)

        return tab
    end

    -- Create tabs
    local overviewTab = CreateTab(tabBar, "Overview", 1)
    overviewTab:SetPoint("LEFT", tabBar, "LEFT", 0, 0)

    local cooldownsTab = CreateTab(tabBar, "Cooldowns", 2)
    cooldownsTab:SetPoint("LEFT", overviewTab, "RIGHT", 8, 0)

    local sourcesTab = CreateTab(tabBar, "Sources", 3)
    sourcesTab:SetPoint("LEFT", cooldownsTab, "RIGHT", 8, 0)

    local settingsTab = CreateTab(tabBar, "Settings", 4)
    settingsTab:SetPoint("LEFT", sourcesTab, "RIGHT", 8, 0)

    frame.tabs = { overviewTab, cooldownsTab, sourcesTab, settingsTab }
    frame.tabBar = tabBar
    frame.selectedTab = 1

    -- Calculate total tab bar width for minimum window size
    local totalTabWidth = 0
    for i, tab in ipairs(frame.tabs) do
        totalTabWidth = totalTabWidth + tab:GetWidth()
        if i > 1 then
            totalTabWidth = totalTabWidth + 8 -- tab spacing
        end
    end
    frame.tabBarWidth = totalTabWidth + PADDING * 2
    frame:SetResizeBounds(math.max(MIN_WIDTH, frame.tabBarWidth), MIN_HEIGHT)

    -- Tab separator line
    local tabSeparator = frame:CreateTexture(nil, "ARTWORK")
    tabSeparator:SetHeight(1)
    tabSeparator:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -2)
    tabSeparator:SetPoint("TOPRIGHT", tabBar, "BOTTOMRIGHT", 0, -2)
    tabSeparator:SetColorTexture(unpack(COLORS.separator))

    frame.tabSeparator = tabSeparator

    -- Custom close button
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -PADDING)

    local closeBtnText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeBtnText:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
    closeBtnText:SetText("X")
    closeBtnText:SetTextColor(unpack(COLORS.textDim))

    closeBtn:SetScript("OnEnter", function()
        closeBtnText:SetTextColor(unpack(COLORS.closeHover))
    end)
    closeBtn:SetScript("OnLeave", function()
        closeBtnText:SetTextColor(unpack(COLORS.textDim))
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

    -- Update timer (skip settings tab - it's static content and re-rendering closes dropdowns)
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.timeSinceUpdate = (self.timeSinceUpdate or 0) + elapsed
        if self.timeSinceUpdate >= 1 then
            self.timeSinceUpdate = 0
            if self:IsShown() and PL.mainFrame.selectedTab ~= 4 then
                PL:UpdateMainFrame()
            end
        end
    end)

    self.mainFrame = frame
    self:ApplyUIScale()

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
    row.highlight:SetColorTexture(unpack(COLORS.highlight))
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
            row.time:SetTextColor(unpack(COLORS.readyHover)) -- Lighter green on hover
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
            row.time:SetTextColor(unpack(COLORS.ready)) -- Back to green
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
    separator:SetColorTexture(unpack(COLORS.separatorFaint))
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

    -- Adjust minimum width based on tab bar
    local tabBarWidth = self.mainFrame.tabBarWidth or 0
    local minWidth = math.max(MIN_WIDTH, tabBarWidth)
    self.mainFrame:SetResizeBounds(minWidth, MIN_HEIGHT)

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
        -- Hide TomTom button and vendor button
        if row.tomtomBtn then
            row.tomtomBtn:Hide()
        end
        if row.vendorBtn then
            row.vendorBtn:Hide()
        end
        if row.separatorText then
            row.separatorText:Hide()
        end
        -- Reset text field positioning to default (left-aligned at row start)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row, "LEFT", 0, 0)
        -- Reset time field positioning to default (right-aligned)
        row.time:ClearAllPoints()
        row.time:SetPoint("RIGHT", row.timeBtn, "RIGHT", 0, 0)
        row.time:SetJustifyH("RIGHT")
        -- Clear item link scripts
        row:SetScript("OnMouseUp", nil)
        row:SetScript("OnEnter", function(self) self.highlight:Show() end)
        row:SetScript("OnLeave", function(self) self.highlight:Hide() end)
    end

    -- Clear existing separators
    for _, sep in pairs(self.mainFrame.separators) do
        sep:Hide()
    end

    -- Hide settings widgets when not on settings tab
    if self.mainFrame.settingsWidgets then
        for _, widget in pairs(self.mainFrame.settingsWidgets) do
            widget:Hide()
        end
    end

    local selectedTab = self.mainFrame.selectedTab or 1

    -- OVERVIEW TAB: Show all characters with their professions (icons aligned in columns)
    if selectedTab == 1 then
        -- First pass: measure the widest character name
        local nameWidth = 0
        for _, charInfo in ipairs(characters) do
            rowIndex = rowIndex + 1
            local charRow = self.mainFrame.rows[rowIndex]
            if not charRow then
                charRow = CreateRow(content, rowIndex)
                self.mainFrame.rows[rowIndex] = charRow
            end
            charRow.text:SetText(charInfo.data.name)
            local w = charRow.text:GetStringWidth()
            if w > nameWidth then nameWidth = w end
        end
        local iconStartX = nameWidth + 10
        local iconSize = 14
        local iconSpacing = 3

        -- Second pass: position rows and icons
        rowIndex = 0
        charCount = 0
        for _, charInfo in ipairs(characters) do
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
                rowIndex = rowIndex + 0.5
            end

            rowIndex = rowIndex + 1
            local charRow = self.mainFrame.rows[rowIndex]
            if not charRow then
                charRow = CreateRow(content, rowIndex)
                self.mainFrame.rows[rowIndex] = charRow
            end

            charRow:ClearAllPoints()
            charRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((rowIndex - 1) * ROW_HEIGHT))
            charRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -((rowIndex - 1) * ROW_HEIGHT))

            local classColor = CLASS_COLORS[charData.class] or { r = 1, g = 1, b = 1 }
            charRow.text:SetTextColor(classColor.r, classColor.g, classColor.b)
            charRow.text:SetText(charData.name)

            -- Show profession icons aligned to a fixed start position
            local cp = charData.professions or {}
            local iconIndex = 0
            for _, profKey in ipairs(PROFESSION_ORDER) do
                local value = cp[profKey]
                if value and value ~= false and (type(value) ~= "number" or value > 0) then
                    local iconFrame = charRow.profIcons[profKey]
                    iconFrame.profName = PROFESSION_NAMES[profKey]
                    iconFrame.profLevel = type(value) == "number" and value or nil

                    iconFrame:ClearAllPoints()
                    iconFrame:SetPoint("TOPLEFT", charRow, "TOPLEFT", iconStartX + iconIndex * (iconSize + iconSpacing), -1)
                    iconFrame:Show()
                    iconIndex = iconIndex + 1
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
            emptyRow.text:SetTextColor(unpack(COLORS.textFaint))
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

                    -- Show profession icon next to cooldown name
                    local profession = self.COOLDOWN_TO_PROFESSION and self.COOLDOWN_TO_PROFESSION[cd.type]
                    if profession and cdRow.profIcons[profession] then
                        local iconFrame = cdRow.profIcons[profession]
                        iconFrame.profName = PROFESSION_NAMES[profession]
                        iconFrame.profLevel = nil
                        iconFrame:ClearAllPoints()
                        iconFrame:SetPoint("LEFT", cdRow, "LEFT", 4, 0)
                        iconFrame:Show()
                    end

                    cdRow.text:SetTextColor(0.85, 0.78, 0.65) -- #d9c6a5
                    cdRow.text:ClearAllPoints()
                    cdRow.text:SetPoint("LEFT", cdRow, "LEFT", 22, 0)
                    cdRow.text:SetText(cd.name)

                    -- Color the time based on ready status (matching tracker window)
                    if cd.remaining == nil then
                        cdRow.time:SetTextColor(0.60, 0.53, 0.47) -- #998877
                        cdRow.time:SetText("Unknown")
                        cdRow.timeBtn.isClickable = false
                    elseif cd.remaining <= 0 then
                        cdRow.time:SetTextColor(0.20, 0.80, 0.20) -- #33cc33
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
                        cdRow.time:SetTextColor(0.87, 0.80, 0.60) -- #ddcc99
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
            emptyRow.text:SetTextColor(unpack(COLORS.textFaint))
            emptyRow.text:SetText("No characters with Tailoring or Alchemy found.")
            emptyRow.time:SetText("")
            emptyRow.timeBtn.isClickable = false
            emptyRow:Show()
        end

    -- SOURCES TAB: Show craft source information grouped by profession accordion
    elseif selectedTab == 3 then
        local sources = self.COOLDOWN_SOURCES or {}

        -- Profession groups for accordion display
        local sourceGroups = {
            { key = "tailoring", name = "Tailoring", items = { "primalMooncloth", "shadowcloth", "spellcloth" } },
            { key = "leatherworking", name = "Leatherworking", items = { "saltShaker" } },
            { key = "alchemy", name = "Alchemy", items = { "primalMight", "transmutePrimalAirToFire", "transmutePrimalEarthToWater", "transmutePrimalWaterToAir", "transmutePrimalLifeToEarth", "transmuteEarthstormDiamond", "transmuteSkyfireDiamond" } },
            { key = "enchanting", name = "Enchanting", items = { "voidSphere" } },
            { key = "jewelcrafting", name = "Jewelcrafting", items = { "brilliantGlass" } },
        }

        -- Initialize accordion state (all collapsed by default)
        self.mainFrame.sourceAccordions = self.mainFrame.sourceAccordions or {}

        for _, group in ipairs(sourceGroups) do
            local isExpanded = self.mainFrame.sourceAccordions[group.key] or false
            local arrow = isExpanded and "- " or "+ "

            -- Profession accordion header
            rowIndex = rowIndex + 1
            local headerRow = self.mainFrame.rows[rowIndex]
            if not headerRow then
                headerRow = CreateRow(content, rowIndex)
                self.mainFrame.rows[rowIndex] = headerRow
            end
            headerRow:ClearAllPoints()
            headerRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((rowIndex - 1) * ROW_HEIGHT))
            headerRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -((rowIndex - 1) * ROW_HEIGHT))
            headerRow.text:SetTextColor(unpack(COLORS.accent))
            headerRow.text:SetText(arrow .. group.name)
            headerRow.time:SetText("")
            headerRow.timeBtn.isClickable = false
            headerRow:SetScript("OnMouseUp", function()
                PL.mainFrame.sourceAccordions[group.key] = not PL.mainFrame.sourceAccordions[group.key]
                PL:UpdateMainFrame()
            end)
            headerRow:Show()

            -- Render child rows only if expanded
            if isExpanded then
                for _, cdType in ipairs(group.items) do
                    local source = sources[cdType]
                    if source then
                        local craftName = self.COOLDOWN_NAMES[cdType]

                        -- Craft name sub-header
                        rowIndex = rowIndex + 1
                        local nameRow = self.mainFrame.rows[rowIndex]
                        if not nameRow then
                            nameRow = CreateRow(content, rowIndex)
                            self.mainFrame.rows[rowIndex] = nameRow
                        end
                        nameRow:ClearAllPoints()
                        nameRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((rowIndex - 1) * ROW_HEIGHT))
                        nameRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -((rowIndex - 1) * ROW_HEIGHT))
                        nameRow.text:SetTextColor(unpack(COLORS.accentMuted))
                        nameRow.text:SetText("  " .. craftName)
                        nameRow.time:SetText("")
                        nameRow.timeBtn.isClickable = false
                        nameRow:Show()

                        -- Link row (clickable item link or discovery/trainer text)
                        rowIndex = rowIndex + 1
                        local linkRow = self.mainFrame.rows[rowIndex]
                        if not linkRow then
                            linkRow = CreateRow(content, rowIndex)
                            self.mainFrame.rows[rowIndex] = linkRow
                        end
                        linkRow:ClearAllPoints()
                        linkRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((rowIndex - 1) * ROW_HEIGHT))
                        linkRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -((rowIndex - 1) * ROW_HEIGHT))
                        linkRow.time:SetText("")
                        linkRow.timeBtn.isClickable = false

                        if source.discovery then
                            linkRow.text:SetTextColor(unpack(COLORS.textNormal))
                            linkRow.text:SetText("    Learned via Discovery")
                            linkRow.itemLink = nil
                            linkRow.itemId = nil
                            linkRow:SetScript("OnMouseUp", nil)
                            linkRow:SetScript("OnEnter", nil)
                            linkRow:SetScript("OnLeave", nil)
                        elseif source.trainer then
                            linkRow.text:SetTextColor(unpack(COLORS.textNormal))
                            linkRow.text:SetText("    Learned from trainer")
                            linkRow.itemLink = nil
                            linkRow.itemId = nil
                            linkRow:SetScript("OnMouseUp", nil)
                            linkRow:SetScript("OnEnter", nil)
                            linkRow:SetScript("OnLeave", nil)
                        elseif source.engineeringCraft then
                            local itemLink = "|cff1eff00|Hitem:" .. source.item.itemId .. "::::::::70:::::|h[" .. source.item.name .. "]|h|r"
                            linkRow.text:SetTextColor(unpack(COLORS.textNormal))
                            linkRow.text:SetText("    Item: " .. itemLink)
                            linkRow.itemLink = itemLink
                            linkRow.itemId = source.item.itemId
                            linkRow:SetScript("OnMouseUp", function(self, button)
                                if button == "LeftButton" and IsShiftKeyDown() and ChatFrame1EditBox:IsShown() then
                                    ChatFrame1EditBox:Insert(self.itemLink)
                                end
                            end)
                            linkRow:SetScript("OnEnter", function(self)
                                self.highlight:Show()
                                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                GameTooltip:SetHyperlink("item:" .. self.itemId)
                                GameTooltip:Show()
                            end)
                            linkRow:SetScript("OnLeave", function(self)
                                self.highlight:Hide()
                                GameTooltip:Hide()
                            end)
                        else
                            local itemLink = "|cff0070dd|Hitem:" .. source.pattern.itemId .. "::::::::70:::::|h[" .. source.pattern.name .. "]|h|r"
                            linkRow.text:SetTextColor(unpack(COLORS.textNormal))
                            linkRow.text:SetText("    Link: " .. itemLink)
                            linkRow.itemLink = itemLink
                            linkRow.itemId = source.pattern.itemId
                            linkRow:SetScript("OnMouseUp", function(self, button)
                                if button == "LeftButton" and IsShiftKeyDown() and ChatFrame1EditBox:IsShown() then
                                    ChatFrame1EditBox:Insert(self.itemLink)
                                end
                            end)
                            linkRow:SetScript("OnEnter", function(self)
                                self.highlight:Show()
                                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                GameTooltip:SetHyperlink("item:" .. self.itemId)
                                GameTooltip:Show()
                            end)
                            linkRow:SetScript("OnLeave", function(self)
                                self.highlight:Hide()
                                GameTooltip:Hide()
                            end)
                        end
                        linkRow:Show()

                        -- Source row (vendor name with TomTom link, or hint text)
                        rowIndex = rowIndex + 1
                        local sourceRow = self.mainFrame.rows[rowIndex]
                        if not sourceRow then
                            sourceRow = CreateRow(content, rowIndex)
                            self.mainFrame.rows[rowIndex] = sourceRow
                        end
                        sourceRow:ClearAllPoints()
                        sourceRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((rowIndex - 1) * ROW_HEIGHT))
                        sourceRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -((rowIndex - 1) * ROW_HEIGHT))
                        sourceRow.text:SetTextColor(unpack(COLORS.textNormal))
                        sourceRow.time:SetText("")
                        sourceRow.timeBtn.isClickable = false

                        if source.engineeringCraft then
                            sourceRow.text:SetText("    Crafted by Engineers (250) or buy from AH")
                            if sourceRow.vendorBtn then sourceRow.vendorBtn:Hide() end
                            if sourceRow.separatorText then sourceRow.separatorText:Hide() end
                            if sourceRow.tomtomBtn then sourceRow.tomtomBtn:Hide() end
                        elseif source.trainer then
                            sourceRow.text:SetText("    Requires " .. (source.skillRequired or "??") .. " skill")
                            if sourceRow.vendorBtn then sourceRow.vendorBtn:Hide() end
                            if sourceRow.separatorText then sourceRow.separatorText:Hide() end
                            if sourceRow.tomtomBtn then sourceRow.tomtomBtn:Hide() end
                        elseif source.discovery then
                            sourceRow.text:SetText("    Perform other TBC transmutes to discover")
                            if sourceRow.vendorBtn then sourceRow.vendorBtn:Hide() end
                            if sourceRow.separatorText then sourceRow.separatorText:Hide() end
                            if sourceRow.tomtomBtn then sourceRow.tomtomBtn:Hide() end
                        else
                            sourceRow.text:SetText("    Source: ")

                            if not sourceRow.vendorBtn then
                                sourceRow.vendorBtn = CreateFrame("Button", nil, sourceRow)
                                sourceRow.vendorBtn:SetHeight(ROW_HEIGHT)
                                sourceRow.vendorBtn.text = sourceRow.vendorBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                                sourceRow.vendorBtn.text:SetPoint("LEFT", sourceRow.vendorBtn, "LEFT", 0, 0)
                                sourceRow.vendorBtn.text:SetTextColor(unpack(COLORS.accentMuted))

                                sourceRow.vendorBtn:SetScript("OnEnter", function(self)
                                    self.text:SetTextColor(unpack(COLORS.accentHover))
                                    sourceRow.highlight:Show()
                                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                    GameTooltip:AddLine("Target " .. (self.vendorName or "NPC"))
                                    GameTooltip:AddLine("Click to target this NPC", 0.8, 0.8, 0.8)
                                    GameTooltip:Show()
                                end)
                                sourceRow.vendorBtn:SetScript("OnLeave", function(self)
                                    self.text:SetTextColor(unpack(COLORS.accentMuted))
                                    sourceRow.highlight:Hide()
                                    GameTooltip:Hide()
                                end)
                            end

                            sourceRow.vendorBtn.text:SetText(source.vendor.name)
                            sourceRow.vendorBtn:SetWidth(sourceRow.vendorBtn.text:GetStringWidth() + 4)
                            sourceRow.vendorBtn:SetPoint("LEFT", sourceRow.text, "RIGHT", 0, 0)
                            sourceRow.vendorBtn.vendorName = source.vendor.name
                            sourceRow.vendorBtn:SetScript("OnClick", function(self)
                                if self.vendorName then
                                    TargetUnit(self.vendorName)
                                end
                            end)
                            sourceRow.vendorBtn:Show()

                            if not sourceRow.separatorText then
                                sourceRow.separatorText = sourceRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                                sourceRow.separatorText:SetTextColor(unpack(COLORS.textNormal))
                                sourceRow.separatorText:SetText(" - ")
                            end
                            sourceRow.separatorText:SetPoint("LEFT", sourceRow.vendorBtn, "RIGHT", 0, 0)
                            sourceRow.separatorText:Show()

                            if not sourceRow.tomtomBtn then
                                sourceRow.tomtomBtn = CreateFrame("Button", nil, sourceRow)
                                sourceRow.tomtomBtn:SetHeight(ROW_HEIGHT)
                                sourceRow.tomtomBtn.text = sourceRow.tomtomBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                                sourceRow.tomtomBtn.text:SetPoint("LEFT", sourceRow.tomtomBtn, "LEFT", 0, 0)
                                sourceRow.tomtomBtn.text:SetText("TomTom")
                                sourceRow.tomtomBtn.text:SetTextColor(unpack(COLORS.accentMuted))
                                sourceRow.tomtomBtn:SetWidth(sourceRow.tomtomBtn.text:GetStringWidth() + 4)

                                sourceRow.tomtomBtn:SetScript("OnEnter", function(self)
                                    self.text:SetTextColor(unpack(COLORS.accentHover))
                                    sourceRow.highlight:Show()
                                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                    GameTooltip:AddLine("Add TomTom waypoint")
                                    GameTooltip:AddLine("Click to set waypoint", 0.8, 0.8, 0.8)
                                    GameTooltip:Show()
                                end)
                                sourceRow.tomtomBtn:SetScript("OnLeave", function(self)
                                    self.text:SetTextColor(unpack(COLORS.accentMuted))
                                    sourceRow.highlight:Hide()
                                    GameTooltip:Hide()
                                end)
                            end

                            sourceRow.tomtomBtn:SetPoint("LEFT", sourceRow.separatorText, "RIGHT", 0, 0)
                            sourceRow.tomtomBtn.tomtomCommand = source.vendor.tomtom
                            sourceRow.tomtomBtn:SetScript("OnClick", function(self)
                                if self.tomtomCommand then
                                    DEFAULT_CHAT_FRAME.editBox:SetText(self.tomtomCommand)
                                    ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox)
                                end
                            end)
                            sourceRow.tomtomBtn:Show()
                        end
                        sourceRow:Show()

                        -- Add spacing between crafts within the group
                        rowIndex = rowIndex + 0.5
                    end
                end
            end

            -- Add spacing after each profession group
            rowIndex = rowIndex + 0.5
        end

        -- Show message if no sources defined
        if rowIndex == 0 then
            rowIndex = 1
            local emptyRow = self.mainFrame.rows[1]
            if not emptyRow then
                emptyRow = CreateRow(content, 1)
                self.mainFrame.rows[1] = emptyRow
            end
            emptyRow.text:SetTextColor(unpack(COLORS.textFaint))
            emptyRow.text:SetText("No source information available.")
            emptyRow.time:SetText("")
            emptyRow.timeBtn.isClickable = false
            emptyRow:Show()
        end

    -- SETTINGS TAB
    elseif selectedTab == 4 then
        -- Hide settings widgets from previous render if they exist
        if self.mainFrame.settingsWidgets then
            for _, widget in pairs(self.mainFrame.settingsWidgets) do
                widget:Hide()
            end
        end
        self.mainFrame.settingsWidgets = {}

        local yOffset = -PADDING

        -- Tracker window checkbox
        local checkBtn = self.mainFrame.settingsCheckBtn
        if not checkBtn then
            checkBtn = CreateFrame("CheckButton", "PrimalLedgerTrackerCheck", content, "UICheckButtonTemplate")
            checkBtn:SetSize(24, 24)
            self.mainFrame.settingsCheckBtn = checkBtn
        end
        checkBtn:ClearAllPoints()
        checkBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        checkBtn:SetChecked(self.db.settings.showTrackerWindow ~= false)
        checkBtn:SetScript("OnClick", function(self)
            PL.db.settings.showTrackerWindow = self:GetChecked()
            if self:GetChecked() then
                PL:ShowTrackerWindow()
            else
                PL:HideTrackerWindow()
            end
        end)
        checkBtn:Show()
        table.insert(self.mainFrame.settingsWidgets, checkBtn)

        local checkLabel = self.mainFrame.settingsCheckLabel
        if not checkLabel then
            checkLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            self.mainFrame.settingsCheckLabel = checkLabel
        end
        checkLabel:ClearAllPoints()
        checkLabel:SetPoint("LEFT", checkBtn, "RIGHT", 4, 0)
        checkLabel:SetText("Show cooldown tracker window")
        checkLabel:SetTextColor(unpack(COLORS.textNormal))
        checkLabel:Show()
        table.insert(self.mainFrame.settingsWidgets, checkLabel)

        yOffset = yOffset - 26

        -- Show in combat checkbox (indented)
        local combatCheck = self.mainFrame.settingsCombatCheck
        if not combatCheck then
            combatCheck = CreateFrame("CheckButton", "PrimalLedgerCombatCheck", content, "UICheckButtonTemplate")
            combatCheck:SetSize(24, 24)
            self.mainFrame.settingsCombatCheck = combatCheck
        end
        combatCheck:ClearAllPoints()
        combatCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
        combatCheck:SetChecked(self.db.settings.trackerShowInCombat ~= false)
        combatCheck:SetScript("OnClick", function(self)
            PL.db.settings.trackerShowInCombat = self:GetChecked() and true or false
            PL:EvaluateTrackerVisibility()
        end)
        combatCheck:Show()
        table.insert(self.mainFrame.settingsWidgets, combatCheck)

        local combatLabel = self.mainFrame.settingsCombatLabel
        if not combatLabel then
            combatLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            self.mainFrame.settingsCombatLabel = combatLabel
        end
        combatLabel:ClearAllPoints()
        combatLabel:SetPoint("LEFT", combatCheck, "RIGHT", 4, 0)
        combatLabel:SetText("Show in combat")
        combatLabel:SetTextColor(unpack(COLORS.textNormal))
        combatLabel:Show()
        table.insert(self.mainFrame.settingsWidgets, combatLabel)

        yOffset = yOffset - 26

        -- Show in party/raid checkbox (indented)
        local groupCheck = self.mainFrame.settingsGroupCheck
        if not groupCheck then
            groupCheck = CreateFrame("CheckButton", "PrimalLedgerGroupCheck", content, "UICheckButtonTemplate")
            groupCheck:SetSize(24, 24)
            self.mainFrame.settingsGroupCheck = groupCheck
        end
        groupCheck:ClearAllPoints()
        groupCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
        groupCheck:SetChecked(self.db.settings.trackerShowInGroup ~= false)
        groupCheck:SetScript("OnClick", function(self)
            PL.db.settings.trackerShowInGroup = self:GetChecked() and true or false
            PL:EvaluateTrackerVisibility()
        end)
        groupCheck:Show()
        table.insert(self.mainFrame.settingsWidgets, groupCheck)

        local groupLabel = self.mainFrame.settingsGroupLabel
        if not groupLabel then
            groupLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            self.mainFrame.settingsGroupLabel = groupLabel
        end
        groupLabel:ClearAllPoints()
        groupLabel:SetPoint("LEFT", groupCheck, "RIGHT", 4, 0)
        groupLabel:SetText("Show in party/raid")
        groupLabel:SetTextColor(unpack(COLORS.textNormal))
        groupLabel:Show()
        table.insert(self.mainFrame.settingsWidgets, groupLabel)

        yOffset = yOffset - 26

        -- Show seconds checkbox (top-level)
        local secondsCheck = self.mainFrame.settingsSecondsCheck
        if not secondsCheck then
            secondsCheck = CreateFrame("CheckButton", "PrimalLedgerSecondsCheck", content, "UICheckButtonTemplate")
            secondsCheck:SetSize(24, 24)
            self.mainFrame.settingsSecondsCheck = secondsCheck
        end
        secondsCheck:ClearAllPoints()
        secondsCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        secondsCheck:SetChecked(self.db.settings.showSeconds == true)
        secondsCheck:SetScript("OnClick", function(self)
            PL.db.settings.showSeconds = self:GetChecked()
        end)
        secondsCheck:Show()
        table.insert(self.mainFrame.settingsWidgets, secondsCheck)

        local secondsLabel = self.mainFrame.settingsSecondsLabel
        if not secondsLabel then
            secondsLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            self.mainFrame.settingsSecondsLabel = secondsLabel
        end
        secondsLabel:ClearAllPoints()
        secondsLabel:SetPoint("LEFT", secondsCheck, "RIGHT", 4, 0)
        secondsLabel:SetText("Show seconds remaining")
        secondsLabel:SetTextColor(unpack(COLORS.textNormal))
        secondsLabel:Show()
        table.insert(self.mainFrame.settingsWidgets, secondsLabel)

        yOffset = yOffset - 26

        -- Group shared cooldowns checkbox (top-level)
        local groupCDCheck = self.mainFrame.settingsGroupCDCheck
        if not groupCDCheck then
            groupCDCheck = CreateFrame("CheckButton", "PrimalLedgerGroupCDCheck", content, "UICheckButtonTemplate")
            groupCDCheck:SetSize(24, 24)
            self.mainFrame.settingsGroupCDCheck = groupCDCheck
        end
        groupCDCheck:ClearAllPoints()
        groupCDCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        groupCDCheck:SetChecked(self.db.settings.groupSharedCooldowns == true)
        groupCDCheck:SetScript("OnClick", function(self)
            PL.db.settings.groupSharedCooldowns = self:GetChecked() and true or false
        end)
        groupCDCheck:Show()
        table.insert(self.mainFrame.settingsWidgets, groupCDCheck)

        local groupCDLabel = self.mainFrame.settingsGroupCDLabel
        if not groupCDLabel then
            groupCDLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            self.mainFrame.settingsGroupCDLabel = groupCDLabel
        end
        groupCDLabel:ClearAllPoints()
        groupCDLabel:SetPoint("LEFT", groupCDCheck, "RIGHT", 4, 0)
        groupCDLabel:SetText("Group shared cooldowns")
        groupCDLabel:SetTextColor(unpack(COLORS.textNormal))
        groupCDLabel:Show()
        table.insert(self.mainFrame.settingsWidgets, groupCDLabel)

        yOffset = yOffset - 26

        -- Show tracker window title checkbox (top-level)
        local titleCheck = self.mainFrame.settingsTitleCheck
        if not titleCheck then
            titleCheck = CreateFrame("CheckButton", "PrimalLedgerTitleCheck", content, "UICheckButtonTemplate")
            titleCheck:SetSize(24, 24)
            self.mainFrame.settingsTitleCheck = titleCheck
        end
        titleCheck:ClearAllPoints()
        titleCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        titleCheck:SetChecked(self.db.settings.showTrackerTitle ~= false)
        titleCheck:SetScript("OnClick", function(self)
            PL.db.settings.showTrackerTitle = self:GetChecked() and true or false
            PL:UpdateTrackerWindow()
        end)
        titleCheck:Show()
        table.insert(self.mainFrame.settingsWidgets, titleCheck)

        local titleCheckLabel = self.mainFrame.settingsTitleCheckLabel
        if not titleCheckLabel then
            titleCheckLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            self.mainFrame.settingsTitleCheckLabel = titleCheckLabel
        end
        titleCheckLabel:ClearAllPoints()
        titleCheckLabel:SetPoint("LEFT", titleCheck, "RIGHT", 4, 0)
        titleCheckLabel:SetText("Show tracker window title")
        titleCheckLabel:SetTextColor(unpack(COLORS.textNormal))
        titleCheckLabel:Show()
        table.insert(self.mainFrame.settingsWidgets, titleCheckLabel)

        yOffset = yOffset - 28

        -- Custom tracker window title input
        local customTitleLabel = self.mainFrame.settingsCustomTitleLabel
        if not customTitleLabel then
            customTitleLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            self.mainFrame.settingsCustomTitleLabel = customTitleLabel
        end
        customTitleLabel:ClearAllPoints()
        customTitleLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        customTitleLabel:SetText("Custom tracker window title")
        customTitleLabel:SetTextColor(unpack(COLORS.textNormal))
        customTitleLabel:Show()
        table.insert(self.mainFrame.settingsWidgets, customTitleLabel)

        local customTitleHint = self.mainFrame.settingsCustomTitleHint
        if not customTitleHint then
            customTitleHint = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            self.mainFrame.settingsCustomTitleHint = customTitleHint
        end
        customTitleHint:ClearAllPoints()
        customTitleHint:SetPoint("LEFT", customTitleLabel, "RIGHT", 8, 0)
        customTitleHint:SetText("(Leave blank for default)")
        customTitleHint:SetTextColor(unpack(COLORS.textFaint))
        customTitleHint:Show()
        table.insert(self.mainFrame.settingsWidgets, customTitleHint)

        yOffset = yOffset - 20

        local customTitleInput = self.mainFrame.settingsCustomTitleInput
        if not customTitleInput then
            customTitleInput = CreateFrame("EditBox", "PrimalLedgerCustomTitleInput", content, "BackdropTemplate")
            customTitleInput:SetSize(200, 20)
            customTitleInput:SetFontObject(GameFontNormalSmall)
            customTitleInput:SetTextColor(unpack(COLORS.textNormal))
            customTitleInput:SetAutoFocus(false)
            customTitleInput:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
                insets = { left = 4, right = 4, top = 2, bottom = 2 }
            })
            customTitleInput:SetBackdropColor(0.05, 0.03, 0.02, 1)
            customTitleInput:SetBackdropBorderColor(unpack(COLORS.border))
            customTitleInput:SetTextInsets(4, 4, 0, 0)
            self.mainFrame.settingsCustomTitleInput = customTitleInput

            customTitleInput:SetScript("OnEnterPressed", function(self)
                PL.db.settings.customTrackerTitle = self:GetText()
                self:ClearFocus()
                PL:UpdateTrackerWindow()
            end)
            customTitleInput:SetScript("OnEscapePressed", function(self)
                self:SetText(PL.db.settings.customTrackerTitle or "")
                self:ClearFocus()
            end)
        end
        customTitleInput:ClearAllPoints()
        customTitleInput:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        customTitleInput:SetText(self.db.settings.customTrackerTitle or "")
        customTitleInput:Show()
        table.insert(self.mainFrame.settingsWidgets, customTitleInput)

        yOffset = yOffset - 34

        -- Window transparency slider
        local opacityLabel = self.mainFrame.settingsOpacityLabel
        if not opacityLabel then
            opacityLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            self.mainFrame.settingsOpacityLabel = opacityLabel
        end
        opacityLabel:ClearAllPoints()
        opacityLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        opacityLabel:SetTextColor(unpack(COLORS.textNormal))
        opacityLabel:Show()
        table.insert(self.mainFrame.settingsWidgets, opacityLabel)

        local currentOpacity = self.db.settings.trackerOpacity or 100
        opacityLabel:SetText("Tracker transparency: " .. currentOpacity .. "%")

        yOffset = yOffset - 20

        local opacitySlider = self.mainFrame.settingsOpacitySlider
        if not opacitySlider then
            opacitySlider = CreateFrame("Slider", "PrimalLedgerOpacitySlider", content, "OptionsSliderTemplate")
            opacitySlider:SetSize(180, 16)
            opacitySlider:SetMinMaxValues(0, 100)
            opacitySlider:SetValueStep(5)
            opacitySlider:SetObeyStepOnDrag(true)
            self.mainFrame.settingsOpacitySlider = opacitySlider

            -- Hide the default template text
            opacitySlider.Low = opacitySlider.Low or _G[opacitySlider:GetName() .. "Low"]
            opacitySlider.High = opacitySlider.High or _G[opacitySlider:GetName() .. "High"]
            opacitySlider.Text = opacitySlider.Text or _G[opacitySlider:GetName() .. "Text"]
            if opacitySlider.Low then opacitySlider.Low:SetText("10%") opacitySlider.Low:SetTextColor(unpack(COLORS.textDim)) end
            if opacitySlider.High then opacitySlider.High:SetText("100%") opacitySlider.High:SetTextColor(unpack(COLORS.textDim)) end
            if opacitySlider.Text then opacitySlider.Text:SetText("") end
        end
        opacitySlider:ClearAllPoints()
        opacitySlider:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        opacitySlider:SetValue(currentOpacity)
        opacitySlider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value + 0.5)
            PL.db.settings.trackerOpacity = value
            opacityLabel:SetText("Tracker transparency: " .. value .. "%")
            PL:ApplyTrackerAlpha()
        end)
        opacitySlider:Show()
        table.insert(self.mainFrame.settingsWidgets, opacitySlider)

        yOffset = yOffset - 36

        -- UI scale slider
        local scaleLabel = self.mainFrame.settingsScaleLabel
        if not scaleLabel then
            scaleLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            self.mainFrame.settingsScaleLabel = scaleLabel
        end
        scaleLabel:ClearAllPoints()
        scaleLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        scaleLabel:SetTextColor(unpack(COLORS.textNormal))
        scaleLabel:Show()
        table.insert(self.mainFrame.settingsWidgets, scaleLabel)

        local currentScale = self.db.settings.uiScale or 100
        scaleLabel:SetText("Tracker UI scale: " .. currentScale .. "%")

        yOffset = yOffset - 20

        local scaleSlider = self.mainFrame.settingsScaleSlider
        if not scaleSlider then
            scaleSlider = CreateFrame("Slider", "PrimalLedgerScaleSlider", content, "OptionsSliderTemplate")
            scaleSlider:SetSize(180, 16)
            scaleSlider:SetMinMaxValues(50, 200)
            scaleSlider:SetValueStep(5)
            scaleSlider:SetObeyStepOnDrag(true)
            self.mainFrame.settingsScaleSlider = scaleSlider

            scaleSlider.Low = scaleSlider.Low or _G[scaleSlider:GetName() .. "Low"]
            scaleSlider.High = scaleSlider.High or _G[scaleSlider:GetName() .. "High"]
            scaleSlider.Text = scaleSlider.Text or _G[scaleSlider:GetName() .. "Text"]
            if scaleSlider.Low then scaleSlider.Low:SetText("50%") scaleSlider.Low:SetTextColor(unpack(COLORS.textDim)) end
            if scaleSlider.High then scaleSlider.High:SetText("200%") scaleSlider.High:SetTextColor(unpack(COLORS.textDim)) end
            if scaleSlider.Text then scaleSlider.Text:SetText("") end
        end
        scaleSlider:ClearAllPoints()
        scaleSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        scaleSlider:SetValue(currentScale)
        scaleSlider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value + 0.5)
            PL.db.settings.uiScale = value
            scaleLabel:SetText("Tracker UI scale: " .. value .. "%")
            PL:ApplyUIScale()
        end)
        scaleSlider:Show()
        table.insert(self.mainFrame.settingsWidgets, scaleSlider)

        yOffset = yOffset - 36

        -- Reset Data button
        local resetBtn = self.mainFrame.settingsResetBtn
        if not resetBtn then
            resetBtn = CreateFrame("Button", "PrimalLedgerResetBtn", content, "BackdropTemplate")
            resetBtn:SetSize(100, 24)
            resetBtn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 }
            })
            resetBtn:SetBackdropColor(unpack(COLORS.btnBg))
            resetBtn:SetBackdropBorderColor(unpack(COLORS.border))

            local btnText = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btnText:SetPoint("CENTER", 0, 0)
            btnText:SetText("Reset Data")
            btnText:SetTextColor(1, 1, 1)
            resetBtn.btnText = btnText

            resetBtn:SetScript("OnEnter", function(self)
                self:SetBackdropColor(unpack(COLORS.btnBgHover))
            end)
            resetBtn:SetScript("OnLeave", function(self)
                self:SetBackdropColor(unpack(COLORS.btnBg))
            end)
            self.mainFrame.settingsResetBtn = resetBtn
        end
        resetBtn:ClearAllPoints()
        resetBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        resetBtn:SetScript("OnClick", function()
            StaticPopup_Show("PRIMAL_LEDGER_RESET_CONFIRM")
        end)
        resetBtn:Show()
        table.insert(self.mainFrame.settingsWidgets, resetBtn)

        yOffset = yOffset - 40

        -- CD Tracking button
        local trackingBtn = self.mainFrame.settingsTrackingBtn
        if not trackingBtn then
            trackingBtn = CreateFrame("Button", "PrimalLedgerTrackingBtn", content, "BackdropTemplate")
            trackingBtn:SetSize(100, 24)
            trackingBtn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 }
            })
            trackingBtn:SetBackdropColor(COLORS.tabSelectedBg[1], COLORS.tabSelectedBg[2], COLORS.tabSelectedBg[3], 1)
            trackingBtn:SetBackdropBorderColor(unpack(COLORS.border))

            local tBtnText = trackingBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            tBtnText:SetPoint("CENTER", 0, 0)
            tBtnText:SetText("CD Tracking")
            tBtnText:SetTextColor(unpack(COLORS.textNormal))
            trackingBtn.btnText = tBtnText

            trackingBtn:SetScript("OnEnter", function(self)
                self:SetBackdropColor(COLORS.separator[1], COLORS.separator[2], COLORS.separator[3], 1)
                self.btnText:SetTextColor(unpack(COLORS.accentHover))
            end)
            trackingBtn:SetScript("OnLeave", function(self)
                self:SetBackdropColor(COLORS.tabSelectedBg[1], COLORS.tabSelectedBg[2], COLORS.tabSelectedBg[3], 1)
                self.btnText:SetTextColor(unpack(COLORS.textNormal))
            end)
            self.mainFrame.settingsTrackingBtn = trackingBtn
        end
        trackingBtn:ClearAllPoints()
        trackingBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        trackingBtn:SetScript("OnClick", function()
            PL:ShowTrackingWindow()
        end)
        trackingBtn:Show()
        table.insert(self.mainFrame.settingsWidgets, trackingBtn)

        yOffset = yOffset - 40

        -- Guild and credits section
        local guildLabel = self.mainFrame.settingsGuildLabel
        if not guildLabel then
            guildLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
            self.mainFrame.settingsGuildLabel = guildLabel
        end
        guildLabel:ClearAllPoints()
        guildLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        guildLabel:SetTextColor(unpack(COLORS.textDim))
        guildLabel:SetText('Developed by members of "From the Ashes" on Thunderstrike EU.')
        guildLabel:Show()
        table.insert(self.mainFrame.settingsWidgets, guildLabel)

        yOffset = yOffset - 16

        local creditsCols = {
            { "Emsworth (Mehndi)", "Ideation, Development, Testing" },
            { "Mysticas (Mystibloom)", "Ideation, Testing" },
        }
        if not self.mainFrame.creditsRows then self.mainFrame.creditsRows = {} end
        for i, entry in ipairs(creditsCols) do
            local row = self.mainFrame.creditsRows[i]
            if not row then
                row = {
                    name = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"),
                    role = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"),
                }
                self.mainFrame.creditsRows[i] = row
            end
            row.name:ClearAllPoints()
            row.name:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
            row.name:SetTextColor(unpack(COLORS.textDim))
            row.name:SetText(entry[1])
            row.name:Show()
            table.insert(self.mainFrame.settingsWidgets, row.name)

            row.role:ClearAllPoints()
            row.role:SetPoint("TOPLEFT", content, "TOPLEFT", 120, yOffset)
            row.role:SetTextColor(unpack(COLORS.textFaint))
            row.role:SetText(entry[2])
            row.role:Show()
            table.insert(self.mainFrame.settingsWidgets, row.role)

            yOffset = yOffset - 14
        end

        -- Content height for settings
        content:SetHeight(math.abs(yOffset) + 10)
    end

    -- Update content height
    if selectedTab <= 3 then
        content:SetHeight(rowIndex * ROW_HEIGHT + 10)
    end

    -- Auto-size frame height to fit content (if user hasn't manually resized)
    if not self.db.settings.frameSize then
        local contentHeight = content:GetHeight()
        local scrollFrame = self.mainFrame.scrollFrame
        local frameTop = self.mainFrame:GetTop()
        local scrollTop = scrollFrame:GetTop()
        if frameTop and scrollTop then
            local headerHeight = frameTop - scrollTop
            local bottomPad = PADDING + 16
            local neededHeight = headerHeight + contentHeight + bottomPad
            self.mainFrame:SetHeight(math.max(MIN_HEIGHT, neededHeight))
        end
    end
end

-- Toggle main frame visibility
-- Select a tab
function PL:SelectTab(tabIndex)
    if not self.mainFrame or not self.mainFrame.tabs then return end

    -- Update tab appearances
    for i, tab in ipairs(self.mainFrame.tabs) do
        if i == tabIndex then
            tab.isSelected = true
            tab.text:SetTextColor(unpack(COLORS.textNormal))
            tab.selectedBg:Show()
            tab.underline:Show()
        else
            tab.isSelected = false
            tab.text:SetTextColor(unpack(COLORS.textDim))
            tab.selectedBg:Hide()
            tab.underline:Hide()
        end
    end

    self.mainFrame.selectedTab = tabIndex

    -- Update content based on selected tab
    self:UpdateMainFrame()
end

-- Tracker window for cooldown countdowns
function PL:CreateTrackerWindow()
    if self.trackerFrame then return end

    local TRACKER_PADDING = 8
    local TRACKER_ROW_HEIGHT = 14

    local frame = CreateFrame("Frame", "PrimalLedgerTracker", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("BACKGROUND")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local point, _, _, x, y = f:GetPoint()
        PL.db.settings.trackerPosition = { point = point, x = x, y = y }
    end)
    frame:SetResizable(true)

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    local trackerAlpha = self:GetTrackerAlpha()
    frame:SetBackdropColor(0.08, 0.05, 0.03, trackerAlpha)
    frame:SetBackdropBorderColor(0.35, 0.22, 0.10, trackerAlpha)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", TRACKER_PADDING, -TRACKER_PADDING)
    title:SetText("Cooldowns")
    title:SetTextColor(unpack(COLORS.accent))

    -- Close button (top-right, hidden when locked)
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(12, 12)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -TRACKER_PADDING + 2, -TRACKER_PADDING + 2)

    local closeBtnText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeBtnText:SetPoint("CENTER", 0, 0)
    closeBtnText:SetText("X")
    closeBtnText:SetTextColor(unpack(COLORS.textDim))

    closeBtn:SetScript("OnEnter", function() closeBtnText:SetTextColor(unpack(COLORS.closeHover)) end)
    closeBtn:SetScript("OnLeave", function() closeBtnText:SetTextColor(unpack(COLORS.textDim)) end)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
        PL.trackerManuallyHidden = true
    end)

    frame.closeBtn = closeBtn

    -- Enable clipping so content outside the frame is hidden when resized smaller
    frame:SetClipsChildren(true)

    -- Lock/Unlock button (bottom-right, shown on hover — parented to UIParent to avoid clipping)
    local lockBtn = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    lockBtn:SetSize(46, 16)
    lockBtn:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -2, 0)
    lockBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    lockBtn:SetBackdropColor(COLORS.bg[1], COLORS.bg[2], COLORS.bg[3], 1)
    lockBtn:SetBackdropBorderColor(unpack(COLORS.border))

    local lockIcon = lockBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lockIcon:SetPoint("CENTER", 0, 0)
    lockBtn.icon = lockIcon

    lockBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(COLORS.accent))
    end)
    lockBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(COLORS.border))
    end)
    lockBtn:SetScript("OnClick", function()
        PL.db.settings.trackerLocked = not (PL.db.settings.trackerLocked == true)
        PL:ApplyTrackerLock()
    end)
    lockBtn:Hide()

    frame.lockBtn = lockBtn

    -- Resize grip (bottom-right corner)
    local resizeGrip = CreateFrame("Button", nil, frame)
    resizeGrip:SetSize(12, 12)
    resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function()
        if not (PL.db.settings.trackerLocked == true) then
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        PL.db.settings.trackerSize = { width = frame:GetWidth(), height = frame:GetHeight() }
        PL:UpdateTrackerWindow()
    end)
    frame.resizeGrip = resizeGrip

    -- Hover detection for showing lock button
    local function IsMouseOverTracker()
        return frame:IsMouseOver() or lockBtn:IsMouseOver()
    end

    frame:SetScript("OnEnter", function()
        frame.lockBtn:Show()
    end)
    frame:SetScript("OnLeave", function()
        if not IsMouseOverTracker() then
            frame.lockBtn:Hide()
        end
    end)
    lockBtn:HookScript("OnLeave", function()
        if not IsMouseOverTracker() then
            frame.lockBtn:Hide()
        end
    end)

    -- Keep lock button visibility in sync with tracker frame
    frame:HookScript("OnHide", function() lockBtn:Hide() end)

    -- Store elements for reuse
    frame.rows = {}
    frame.separators = {}
    frame.title = title
    frame.padding = TRACKER_PADDING
    frame.rowHeight = TRACKER_ROW_HEIGHT

    self.trackerFrame = frame

    -- Restore saved position or default to center
    if self.db.settings.trackerPosition then
        local pos = self.db.settings.trackerPosition
        frame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    -- Restore saved size if any
    if self.db.settings.trackerSize then
        local size = self.db.settings.trackerSize
        frame:SetSize(size.width, size.height)
    end

    -- Update cooldown text every second and handle hover hide
    frame:SetScript("OnUpdate", function(f, elapsed)
        f.elapsed = (f.elapsed or 0) + elapsed
        if f.elapsed < 1 then return end
        f.elapsed = 0
        PL:UpdateTrackerWindow()
    end)

    self:ApplyTrackerLock()
    self:ApplyUIScale()
    self:UpdateTrackerWindow()
end

function PL:ApplyTrackerLock()
    if not self.trackerFrame then return end
    local locked = self.db.settings.trackerLocked == true
    local frame = self.trackerFrame

    frame:SetMovable(not locked)
    frame:EnableMouse(true) -- always enabled for hover detection

    if locked then
        frame:RegisterForDrag()
        frame.closeBtn:Hide()
        if frame.resizeGrip then frame.resizeGrip:Hide() end
        frame.lockBtn.icon:SetText("|cffddcc99Unlock|r")
        frame.lockBtn:SetSize(46, 16)
    else
        frame:RegisterForDrag("LeftButton")
        frame.closeBtn:Show()
        if frame.resizeGrip then frame.resizeGrip:Show() end
        frame.lockBtn.icon:SetText("|cff33cc33Lock|r")
        frame.lockBtn:SetSize(36, 16)
    end
end

function PL:UpdateTrackerWindow()
    if not self.trackerFrame then return end
    local frame = self.trackerFrame

    local PAD = frame.padding
    local ROW_H = frame.rowHeight
    local COL_GAP = 8  -- gap between columns

    -- Hide all existing elements
    for _, row in ipairs(frame.rows) do
        if row.charText then row.charText:Hide() end
        if row.craftText then row.craftText:Hide() end
        if row.cdText then row.cdText:Hide() end
        if row.cdBtn then row.cdBtn:Hide() end
        if row.profIcon then row.profIcon:Hide() end
    end
    for _, sep in ipairs(frame.separators) do
        sep:Hide()
    end

    -- Gather all cooldowns across all characters
    local entries = {}
    local characters = self:GetAllCharacters()

    for _, charInfo in ipairs(characters) do
        if self:HasRelevantProfessions(charInfo.key) then
            local cooldowns = self:GetCharacterCooldowns(charInfo.key)
            for _, cd in ipairs(cooldowns) do
                table.insert(entries, {
                    charKey = charInfo.key,
                    charName = charInfo.data.name,
                    charClass = charInfo.data.class,
                    craftName = cd.name,
                    remaining = cd.remaining,
                    cdType = cd.type,
                })
            end
        end
    end

    -- Group shared alchemy transmute cooldowns
    if self.db.settings.groupSharedCooldowns then
        local groupTypes = {
            primalMight = true,
            transmuteEarthstormDiamond = true,
            transmuteSkyfireDiamond = true,
            transmutePrimalManaToFire = true,
            transmutePrimalShadowToWater = true,
            transmutePrimalAirToFire = true,
            transmutePrimalWaterToShadow = true,
            transmutePrimalEarthToWater = true,
            transmutePrimalWaterToAir = true,
            transmutePrimalLifeToEarth = true,
        }
        local grouped = {}
        local charGrouped = {} -- charKey -> grouped entry
        for _, entry in ipairs(entries) do
            if groupTypes[entry.cdType] then
                local existing = charGrouped[entry.charKey]
                if existing then
                    -- Use the longest remaining cooldown for the group
                    if entry.remaining == nil then
                        -- keep existing
                    elseif existing.remaining == nil then
                        existing.remaining = entry.remaining
                    elseif entry.remaining > existing.remaining then
                        existing.remaining = entry.remaining
                    end
                else
                    local g = {
                        charKey = entry.charKey,
                        charName = entry.charName,
                        charClass = entry.charClass,
                        craftName = "Transmutes",
                        remaining = entry.remaining,
                        cdType = entry.cdType,
                        isGroup = true,
                    }
                    charGrouped[entry.charKey] = g
                    table.insert(grouped, g)
                end
            else
                table.insert(grouped, entry)
            end
        end
        entries = grouped
    end

    if #entries == 0 then
        if not self.db.settings.trackerSize then
            frame:SetSize(160, PAD * 2 + 14 + 16)
        end
        local row = frame.rows[1]
        if not row then
            row = { charText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") }
            frame.rows[1] = row
        end
        row.charText:ClearAllPoints()
        row.charText:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -(PAD + 16))
        row.charText:SetText("|cff998877No tracked cooldowns|r")
        row.charText:Show()
        return
    end

    -- Measure column widths
    local colCharW, colCraftW, colCdW = 0, 0, 0

    -- Pre-compute display data and measure
    for i, entry in ipairs(entries) do
        local row = frame.rows[i]
        if not row then
            row = {}
            frame.rows[i] = row
        end
        if not row.charText then
            row.charText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        end
        if not row.profIcon then
            row.profIcon = frame:CreateTexture(nil, "ARTWORK")
            row.profIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
        if not row.craftText then
            row.craftText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        end
        if not row.cdText then
            row.cdText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        end
        if not row.cdBtn then
            row.cdBtn = CreateFrame("Button", nil, frame)
            row.cdBtn:SetHeight(ROW_H)
            row.cdBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        end

        -- Set profession icon for this cooldown
        local profession = self.COOLDOWN_TO_PROFESSION and self.COOLDOWN_TO_PROFESSION[entry.cdType]
        local iconPath = profession and PROFESSION_ICONS[profession]
        if iconPath then
            row.profIcon:SetTexture(iconPath)
            row.profIcon:Show()
        else
            row.profIcon:Hide()
        end

        local classColor = CLASS_COLORS[entry.charClass] or { r = 1, g = 1, b = 1 }
        local colorCode = string.format("|cff%02x%02x%02x",
            math.floor(classColor.r * 255),
            math.floor(classColor.g * 255),
            math.floor(classColor.b * 255))

        row.charText:SetText(colorCode .. entry.charName .. "|r")

        row.craftText:SetText("|cff" .. "d9c6a5" .. entry.craftName .. "|r")

        if entry.remaining == nil then
            row.cdText:SetText("|cff998877Unknown|r")
        elseif entry.remaining <= 0 then
            row.cdText:SetText("|cff33cc33Ready!|r")
        else
            row.cdText:SetText("|cffddcc99" .. self:FormatTimeRemaining(entry.remaining) .. "|r")
        end

        local cw = row.charText:GetStringWidth()
        local fw = row.craftText:GetStringWidth()
        local dw = row.cdText:GetStringWidth()
        if cw > colCharW then colCharW = cw end
        if fw > colCraftW then colCraftW = fw end
        if dw > colCdW then colCdW = dw end
    end

    -- Layout
    local ICON_SIZE = ROW_H - 2
    local ICON_GAP = 3
    local totalWidth = PAD + colCharW + COL_GAP + ICON_SIZE + ICON_GAP + colCraftW + COL_GAP + colCdW + PAD
    totalWidth = math.max(totalWidth, 160)

    local col1X = PAD
    local iconX = PAD + colCharW + COL_GAP
    local col2X = iconX + ICON_SIZE + ICON_GAP

    -- Set minimum resize bounds to fit content width
    frame:SetResizeBounds(totalWidth, 60)

    -- Use the frame's actual width so content follows window resizing
    local frameWidth = math.max(frame:GetWidth(), totalWidth)

    -- Helper to get or create a separator texture
    local sepIdx = 0
    local function GetSeparator()
        sepIdx = sepIdx + 1
        local sep = frame.separators[sepIdx]
        if not sep then
            sep = frame:CreateTexture(nil, "ARTWORK")
            sep:SetTexture("Interface\\Buttons\\WHITE8x8")
            frame.separators[sepIdx] = sep
        end
        sep:ClearAllPoints()
        return sep
    end

    -- Update tracker title visibility and text
    local showTitle = self.db.settings.showTrackerTitle ~= false
    if showTitle then
        local customTitle = self.db.settings.customTrackerTitle or ""
        if customTitle == "" then
            frame.title:SetText("Primal Ledger Cooldown Tracker")
        else
            frame.title:SetText(customTitle)
        end
        frame.title:Show()
    else
        frame.title:Hide()
    end

    local yOffset = showTitle and -(PAD + 16) or -PAD

    -- Top bold separator (header line) - only show when title is visible
    if showTitle then
        local topSep = GetSeparator()
        topSep:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, yOffset)
        topSep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, yOffset)
        topSep:SetHeight(1)
        topSep:SetColorTexture(unpack(COLORS.separator))
        topSep:SetAlpha(1)
        topSep:Show()
        yOffset = yOffset - 4
    end

    -- Draw rows with separators
    for i, entry in ipairs(entries) do
        local row = frame.rows[i]

        row.charText:ClearAllPoints()
        row.charText:SetPoint("TOPLEFT", frame, "TOPLEFT", col1X, yOffset)
        row.charText:Show()

        if row.profIcon:IsShown() then
            row.profIcon:SetSize(ICON_SIZE, ICON_SIZE)
            row.profIcon:ClearAllPoints()
            row.profIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", iconX, yOffset - 1)
        end

        row.craftText:ClearAllPoints()
        row.craftText:SetPoint("TOPLEFT", frame, "TOPLEFT", col2X, yOffset)
        row.craftText:Show()

        row.cdText:ClearAllPoints()
        row.cdText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, yOffset)
        row.cdText:Show()

        -- Make "Ready!" clickable for the current character
        local isCurrentChar = (entry.charKey == self:GetCharacterKey())
        if isCurrentChar and entry.remaining ~= nil and entry.remaining <= 0 then
            local cdType = entry.cdType
            row.cdBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, yOffset)
            row.cdBtn:SetWidth(row.cdText:GetStringWidth() + 4)
            row.cdBtn:SetScript("OnClick", function(_, button)
                if button == "LeftButton" then
                    PL:OpenCraftingSpell(cdType)
                elseif button == "RightButton" then
                    PL:SelectCraftingSpell(cdType)
                end
            end)
            row.cdBtn:SetScript("OnEnter", function()
                row.cdText:SetTextColor(unpack(COLORS.readyHover))
                GameTooltip:SetOwner(row.cdBtn, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Ready to craft!")
                GameTooltip:AddLine("|cffffffffLeft-click:|r Open profession and select recipe", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("|cffffffffRight-click:|r Open profession window", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            row.cdBtn:SetScript("OnLeave", function()
                row.cdText:SetTextColor(0.2, 0.8, 0.2) -- back to ready green
                GameTooltip:Hide()
            end)
            row.cdBtn:Show()
        else
            row.cdBtn:Hide()
        end

        yOffset = yOffset - ROW_H

        -- Separator after this row (but not after the last row)
        local nextEntry = entries[i + 1]
        if nextEntry then
            local sep = GetSeparator()
            sep:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, yOffset)
            sep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, yOffset)
            sep:SetHeight(1)

            if nextEntry.charName == entry.charName then
                -- Faint line between same character rows
                sep:SetColorTexture(COLORS.separatorFaint[1], COLORS.separatorFaint[2], COLORS.separatorFaint[3], 0.4)
            else
                -- Bold line between different characters
                sep:SetColorTexture(unpack(COLORS.separator))
            end
            sep:Show()
            yOffset = yOffset - 4
        end
    end

    -- Auto-size the frame if user hasn't manually resized
    if not self.db.settings.trackerSize then
        local frameHeight = math.abs(yOffset) + PAD
        frame:SetSize(totalWidth, frameHeight)
    end
end

function PL:ShowTrackerWindow()
    if self.db.settings.showTrackerWindow == false then return end
    self.trackerManuallyHidden = false
    self:CreateTrackerWindow()
    self:EvaluateTrackerVisibility()
end

function PL:HideTrackerWindow()
    if self.trackerFrame then
        self.trackerFrame:Hide()
    end
end

function PL:ShouldTrackerBeVisible()
    if self.db.settings.showTrackerWindow == false then return false end
    if self.trackerManuallyHidden then return false end

    local inCombat = self.inCombat or InCombatLockdown()
    local groupCount = (GetNumGroupMembers or GetNumRaidMembers or function() return 0 end)()
    local partyCount = (GetNumSubgroupMembers or GetNumPartyMembers or function() return 0 end)()
    local inGroup = groupCount > 0 or partyCount > 0

    -- Hide in combat if "show in combat" is unchecked (default true)
    if self.db.settings.trackerShowInCombat == false and inCombat then
        return false
    end
    -- Hide in group if "show in party/raid" is unchecked (default true)
    if self.db.settings.trackerShowInGroup == false and inGroup then
        return false
    end

    return true
end

function PL:EvaluateTrackerVisibility()
    if not self.trackerFrame then return end
    if self:ShouldTrackerBeVisible() then
        self.trackerFrame:Show()
    else
        self.trackerFrame:Hide()
    end
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

-- CD Tracking standalone window
function PL:ShowTrackingWindow()
    if self.trackingFrame then
        self.trackingFrame:Show()
        self:UpdateTrackingWindow()
        return
    end

    local TRACK_PADDING = 12

    local frame = CreateFrame("Frame", "PrimalLedgerTrackingFrame", UIParent, "BackdropTemplate")
    frame:SetSize(250, 400)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(unpack(COLORS.bg))
    frame:SetBackdropBorderColor(unpack(COLORS.border))

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", TRACK_PADDING, -TRACK_PADDING)
    title:SetText("CD Tracking")
    title:SetTextColor(unpack(COLORS.accent))

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -TRACK_PADDING, -TRACK_PADDING)
    local closeBtnText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeBtnText:SetPoint("CENTER", 0, 0)
    closeBtnText:SetText("X")
    closeBtnText:SetTextColor(unpack(COLORS.textDim))
    closeBtn:SetScript("OnEnter", function() closeBtnText:SetTextColor(unpack(COLORS.closeHover)) end)
    closeBtn:SetScript("OnLeave", function() closeBtnText:SetTextColor(unpack(COLORS.textDim)) end)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Separator
    local sep = frame:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", frame, "TOPLEFT", TRACK_PADDING, -(TRACK_PADDING + 20))
    sep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -TRACK_PADDING, -(TRACK_PADDING + 20))
    sep:SetColorTexture(unpack(COLORS.separator))

    -- Scroll frame for content
    local scrollFrame = CreateFrame("ScrollFrame", "PrimalLedgerTrackingScroll", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", TRACK_PADDING, -(TRACK_PADDING + 24))
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -TRACK_PADDING - 20, TRACK_PADDING)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(scrollFrame:GetWidth())
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)

    frame.content = content
    frame.checkboxes = {}
    self.trackingFrame = frame

    self:UpdateTrackingWindow()
end

function PL:UpdateTrackingWindow()
    if not self.trackingFrame then return end

    local content = self.trackingFrame.content
    local TRACK_PADDING = 12

    -- Clear old checkboxes
    if self.trackingFrame.checkboxes then
        for _, widget in pairs(self.trackingFrame.checkboxes) do
            widget:Hide()
        end
    end
    self.trackingFrame.checkboxes = {}

    local yOffset = 0

    -- Helper to create a profession section
    local function CreateSection(profName, profKey)
        local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        header:SetText(profName)
        header:SetTextColor(unpack(COLORS.accent))
        header:Show()
        table.insert(self.trackingFrame.checkboxes, header)

        yOffset = yOffset - 20

        for _, cdType in ipairs(self.PROFESSION_COOLDOWNS[profKey]) do
            local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
            cb:SetSize(24, 24)
            cb:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
            cb:SetChecked(self:IsCooldownEnabled(cdType))
            local capturedType = cdType
            cb:SetScript("OnClick", function(self)
                if self:GetChecked() then
                    PL.db.settings.disabledCooldowns[capturedType] = nil
                else
                    PL.db.settings.disabledCooldowns[capturedType] = true
                end
            end)
            cb:Show()
            table.insert(self.trackingFrame.checkboxes, cb)

            local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            label:SetText(self.COOLDOWN_NAMES[cdType])
            label:SetTextColor(unpack(COLORS.textNormal))
            label:Show()
            table.insert(self.trackingFrame.checkboxes, label)

            yOffset = yOffset - 24
        end

        yOffset = yOffset - 8
    end

    CreateSection("Tailoring", "tailoring")
    CreateSection("Alchemy", "alchemy")
    CreateSection("Jewelcrafting", "jewelcrafting")

    content:SetHeight(math.abs(yOffset) + 10)
end

-- Helper: create a styled button on a profession frame
local function CreateProfFrameExportButton(parent, globalName, onClick)
    local btn = CreateFrame("Button", globalName, parent, "BackdropTemplate")
    btn:SetSize(60, 22)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -60, -4)
    btn:SetFrameStrata("HIGH")
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    btn:SetBackdropColor(COLORS.bg[1], COLORS.bg[2], COLORS.bg[3], 1)
    btn:SetBackdropBorderColor(unpack(COLORS.border))

    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btnText:SetPoint("CENTER", 0, 0)
    btnText:SetText("Export")
    btnText:SetTextColor(unpack(COLORS.textNormal))

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(COLORS.tabSelectedBg[1], COLORS.tabSelectedBg[2], COLORS.tabSelectedBg[3], 1)
        btnText:SetTextColor(unpack(COLORS.accentHover))
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(COLORS.bg[1], COLORS.bg[2], COLORS.bg[3], 1)
        btnText:SetTextColor(unpack(COLORS.textNormal))
    end)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- Export button on the TradeSkill frame
function PL:CreateExportButton()
    if self.exportBtn then return end
    if not TradeSkillFrame then return end
    self.exportBtn = CreateProfFrameExportButton(TradeSkillFrame, "PrimalLedgerExportBtn", function()
        PL:ShowExportSelectionWindow("tradeskill")
    end)
end

-- Export button for the Craft frame (Enchanting)
function PL:CreateCraftExportButton()
    if self.craftExportBtn then return end
    if not CraftFrame then return end
    self.craftExportBtn = CreateProfFrameExportButton(CraftFrame, "PrimalLedgerCraftExportBtn", function()
        PL:ShowExportSelectionWindow("craft")
    end)
end

-- Gather crafts from the currently open profession window
-- Returns: professionName, list of { index, name, header (string or nil) }
function PL:GetRecipeRequiredLevel(link)
    if not link then return nil end
    if not self.scanTooltip then
        self.scanTooltip = CreateFrame("GameTooltip", "PrimalLedgerScanTooltip", nil, "GameTooltipTemplate")
        self.scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    local tip = self.scanTooltip
    tip:ClearLines()
    tip:SetHyperlink(link)
    for i = 1, tip:NumLines() do
        local text = _G["PrimalLedgerScanTooltipTextLeft" .. i]:GetText()
        if text then
            local level = text:match("Requires.-%((%d+)%)")
            if level then return tonumber(level) end
        end
    end
    return nil
end

function PL:GetOpenProfessionCrafts(source)
    local crafts = {}

    if source == "craft" then
        local numCrafts = GetNumCrafts()
        if not numCrafts or numCrafts == 0 then return nil, nil end
        local profName = GetCraftDisplaySkillLine()
        if not profName then return nil, nil end

        local currentHeader = nil
        for i = 1, numCrafts do
            local name, _, craftType = GetCraftInfo(i)
            if name then
                if craftType == "header" then
                    currentHeader = name
                elseif craftType ~= "subheader" then
                    local link = GetCraftRecipeLink(i)
                    local reqLevel = self:GetRecipeRequiredLevel(link)
                    table.insert(crafts, { index = i, name = name, header = currentHeader, requiredLevel = reqLevel })
                end
            end
        end
        return profName, crafts
    else
        local numSkills = GetNumTradeSkills()
        if not numSkills or numSkills == 0 then return nil, nil end
        local profName = GetTradeSkillLine()
        if not profName then return nil, nil end

        local currentHeader = nil
        for i = 1, numSkills do
            local name, skillType = GetTradeSkillInfo(i)
            if name then
                if skillType == "header" then
                    currentHeader = name
                elseif skillType ~= "subheader" then
                    local link = GetTradeSkillRecipeLink(i)
                    local reqLevel = self:GetRecipeRequiredLevel(link)
                    table.insert(crafts, { index = i, name = name, header = currentHeader, requiredLevel = reqLevel })
                end
            end
        end
        return profName, crafts
    end
end

-- Step 1: Show selection window with checkboxes for each craft
function PL:ShowExportSelectionWindow(source)
    local profName, crafts = self:GetOpenProfessionCrafts(source)
    if not profName or not crafts or #crafts == 0 then
        self:Print("No profession window open.")
        return
    end

    -- Hide text window if open
    if self.exportTextFrame then self.exportTextFrame:Hide() end

    local EXP_PADDING = 10

    -- Reuse or create selection frame
    if not self.exportSelFrame then
        local frame = CreateFrame("Frame", "PrimalLedgerExportSelFrame", UIParent, "BackdropTemplate")
        frame:SetSize(350, 420)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:SetFrameStrata("DIALOG")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetClampedToScreen(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        frame:SetBackdropColor(unpack(COLORS.bg))
        frame:SetBackdropBorderColor(unpack(COLORS.border))

        -- Title
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", EXP_PADDING, -EXP_PADDING)
        frame.title:SetTextColor(unpack(COLORS.accent))

        -- Close button
        local closeBtn = CreateFrame("Button", nil, frame)
        closeBtn:SetSize(16, 16)
        closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -EXP_PADDING, -EXP_PADDING)
        local closeBtnText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        closeBtnText:SetPoint("CENTER", 0, 0)
        closeBtnText:SetText("X")
        closeBtnText:SetTextColor(unpack(COLORS.textDim))
        closeBtn:SetScript("OnEnter", function() closeBtnText:SetTextColor(unpack(COLORS.closeHover)) end)
        closeBtn:SetScript("OnLeave", function() closeBtnText:SetTextColor(unpack(COLORS.textDim)) end)
        closeBtn:SetScript("OnClick", function() frame:Hide() end)

        -- Separator
        local sep = frame:CreateTexture(nil, "ARTWORK")
        sep:SetHeight(1)
        sep:SetPoint("TOPLEFT", frame, "TOPLEFT", EXP_PADDING, -(EXP_PADDING + 20))
        sep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -EXP_PADDING, -(EXP_PADDING + 20))
        sep:SetColorTexture(unpack(COLORS.separator))

        -- Scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", "PrimalLedgerExportSelScroll", frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", EXP_PADDING, -(EXP_PADDING + 24))
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -EXP_PADDING - 20, EXP_PADDING + 30)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetWidth(scrollFrame:GetWidth())
        content:SetHeight(1)
        scrollFrame:SetScrollChild(content)

        frame.scrollFrame = scrollFrame
        frame.content = content

        -- Select 300+ button (bottom-left, static)
        local sel300Btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        sel300Btn:SetSize(100, 24)
        sel300Btn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", EXP_PADDING, EXP_PADDING)
        sel300Btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        sel300Btn:SetBackdropColor(COLORS.tabSelectedBg[1], COLORS.tabSelectedBg[2], COLORS.tabSelectedBg[3], 1)
        sel300Btn:SetBackdropBorderColor(unpack(COLORS.border))

        local sel300Text = sel300Btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sel300Text:SetPoint("CENTER", 0, 0)
        sel300Text:SetText("Select 300+")
        sel300Text:SetTextColor(unpack(COLORS.textNormal))

        sel300Btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(COLORS.separator[1], COLORS.separator[2], COLORS.separator[3], 1)
            sel300Text:SetTextColor(unpack(COLORS.accentHover))
        end)
        sel300Btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(COLORS.tabSelectedBg[1], COLORS.tabSelectedBg[2], COLORS.tabSelectedBg[3], 1)
            sel300Text:SetTextColor(unpack(COLORS.textNormal))
        end)
        sel300Btn:SetScript("OnClick", function()
            if not frame.craftCheckboxes then return end
            for _, entry in ipairs(frame.craftCheckboxes) do
                entry.cb:SetChecked(entry.requiredLevel and entry.requiredLevel >= 300)
            end
        end)

        -- Export button (bottom-right, static)
        local exportBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        exportBtn:SetSize(80, 24)
        exportBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -EXP_PADDING, EXP_PADDING)
        exportBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        exportBtn:SetBackdropColor(COLORS.tabSelectedBg[1], COLORS.tabSelectedBg[2], COLORS.tabSelectedBg[3], 1)
        exportBtn:SetBackdropBorderColor(unpack(COLORS.border))

        local eBtnText = exportBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        eBtnText:SetPoint("CENTER", 0, 0)
        eBtnText:SetText("Export")
        eBtnText:SetTextColor(unpack(COLORS.textNormal))

        exportBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(COLORS.separator[1], COLORS.separator[2], COLORS.separator[3], 1)
            eBtnText:SetTextColor(unpack(COLORS.accentHover))
        end)
        exportBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(COLORS.tabSelectedBg[1], COLORS.tabSelectedBg[2], COLORS.tabSelectedBg[3], 1)
            eBtnText:SetTextColor(unpack(COLORS.textNormal))
        end)
        exportBtn:SetScript("OnClick", function()
            PL:ExportSelectedCrafts()
        end)

        frame.widgets = {}
        self.exportSelFrame = frame
    end

    local frame = self.exportSelFrame
    local content = frame.content

    -- Clear old widgets
    for _, widget in pairs(frame.widgets) do
        widget:Hide()
    end
    frame.widgets = {}
    frame.craftCheckboxes = {}

    frame.title:SetText("Export - " .. profName)
    frame.profName = profName

    local yOffset = 0
    local lastHeader = nil

    for _, craft in ipairs(crafts) do
        -- Show header if new category
        if craft.header and craft.header ~= lastHeader then
            if lastHeader then
                yOffset = yOffset - 4
            end
            local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
            header:SetText(craft.header)
            header:SetTextColor(unpack(COLORS.accent))
            header:Show()
            table.insert(frame.widgets, header)
            lastHeader = craft.header
            yOffset = yOffset - 18
        end

        local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
        cb:SetChecked(true)
        cb:Show()
        table.insert(frame.widgets, cb)

        local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        label:SetText(craft.name)
        label:SetTextColor(unpack(COLORS.textNormal))
        label:Show()
        table.insert(frame.widgets, label)

        table.insert(frame.craftCheckboxes, { cb = cb, name = craft.name, header = craft.header, requiredLevel = craft.requiredLevel })

        yOffset = yOffset - 24
    end

    content:SetHeight(math.abs(yOffset) + 10)
    frame:Show()
end

-- Step 2: Build text from selected crafts and show text window
function PL:ExportSelectedCrafts()
    if not self.exportSelFrame or not self.exportSelFrame.craftCheckboxes then return end

    local playerName = UnitName("player")
    local profName = self.exportSelFrame.profName or "Unknown"
    local lines = {}

    table.insert(lines, "**" .. playerName .. " - " .. profName .. "**")
    table.insert(lines, "```")

    local lastHeader = nil
    for _, entry in ipairs(self.exportSelFrame.craftCheckboxes) do
        if entry.cb:GetChecked() then
            if entry.header and entry.header ~= lastHeader then
                if lastHeader then
                    table.insert(lines, "")
                end
                table.insert(lines, "[ " .. entry.header .. " ]")
                lastHeader = entry.header
            end
            table.insert(lines, "  " .. entry.name)
        end
    end

    table.insert(lines, "```")

    local exportText = table.concat(lines, "\n")

    -- Hide selection window
    self.exportSelFrame:Hide()

    -- Show text window
    self:ShowExportTextWindow(exportText)
end

-- Show the final copyable export text window
function PL:ShowExportTextWindow(exportText)
    if not self.exportTextFrame then
        local frame = CreateFrame("Frame", "PrimalLedgerExportTextFrame", UIParent, "BackdropTemplate")
        frame:SetSize(400, 350)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:SetFrameStrata("DIALOG")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetClampedToScreen(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        frame:SetBackdropColor(unpack(COLORS.bg))
        frame:SetBackdropBorderColor(unpack(COLORS.border))

        -- Title
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
        title:SetText("Export Crafts")
        title:SetTextColor(unpack(COLORS.accent))

        -- Close button
        local closeBtn = CreateFrame("Button", nil, frame)
        closeBtn:SetSize(16, 16)
        closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
        local closeBtnText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        closeBtnText:SetPoint("CENTER", 0, 0)
        closeBtnText:SetText("X")
        closeBtnText:SetTextColor(unpack(COLORS.textDim))
        closeBtn:SetScript("OnEnter", function() closeBtnText:SetTextColor(unpack(COLORS.closeHover)) end)
        closeBtn:SetScript("OnLeave", function() closeBtnText:SetTextColor(unpack(COLORS.textDim)) end)
        closeBtn:SetScript("OnClick", function() frame:Hide() end)

        -- Hint text
        local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        hint:SetText("Press Ctrl+A to select all, then Ctrl+C to copy")
        hint:SetTextColor(unpack(COLORS.textFaint))

        -- Scroll frame for the edit box
        local scrollFrame = CreateFrame("ScrollFrame", "PrimalLedgerExportTextScroll", frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -48)
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

        local editBox = CreateFrame("EditBox", "PrimalLedgerExportTextEditBox", scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject(GameFontHighlightSmall)
        editBox:SetWidth(scrollFrame:GetWidth())
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        editBox:SetScript("OnChar", function(self) self:SetText(PL.exportTextFrame.currentText or "") end)
        editBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput then
                self:SetText(PL.exportTextFrame.currentText or "")
            end
        end)

        scrollFrame:SetScrollChild(editBox)

        frame.editBox = editBox
        self.exportTextFrame = frame
    end

    self.exportTextFrame.currentText = exportText
    self.exportTextFrame.editBox:SetText(exportText)
    self.exportTextFrame.editBox:SetWidth(self.exportTextFrame:GetWidth() - 40)
    self.exportTextFrame:Show()
    self.exportTextFrame.editBox:HighlightText()
    self.exportTextFrame.editBox:SetFocus()
end
