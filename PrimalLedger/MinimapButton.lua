-- PrimalLedger Minimap Button
-- Minimap button for toggling the main window

local addonName, PL = ...

-- Create minimap button
function PL:CreateMinimapButton()
    if self.minimapButton then return end

    local button = CreateFrame("Button", "PrimalLedgerMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)

    -- Button textures
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\AddOns\\PrimalLedger\\assets\\icon_map")
    icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Border overlay
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    -- Position around minimap
    button:SetScript("OnUpdate", nil)

    local function UpdatePosition()
        local angle = math.rad(self.db.settings.minimapPosition)
        local x = math.cos(angle) * 80
        local y = math.sin(angle) * 80
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    -- Dragging functionality
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)

    button:SetScript("OnDragStart", function(self)
        self.isDragging = true
    end)

    button:SetScript("OnDragStop", function(self)
        self.isDragging = false
    end)

    button:SetScript("OnUpdate", function(self)
        if self.isDragging then
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale

            local angle = math.deg(math.atan2(cy - my, cx - mx))
            PL.db.settings.minimapPosition = angle
            UpdatePosition()
        end
    end)

    -- Click handlers
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button:SetScript("OnClick", function(self, btn)
        if btn == "LeftButton" then
            PL:ToggleMainFrame()
        end
    end)

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Primal Ledger")
        GameTooltip:AddLine("|cffffffffLeft-click:|r Toggle window", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Initial position
    UpdatePosition()

    self.minimapButton = button
end
