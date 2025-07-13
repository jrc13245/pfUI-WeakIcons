pfUI:RegisterModule("WeakIcons", "vanilla", function()
    -----------------------------------------------------------------------------
    -- Polyfill for GetSpellInfo in WoW Vanilla
    -----------------------------------------------------------------------------
    if not GetSpellInfo then
        function GetSpellInfo(spell)
            for i = 1, 200 do -- Adjust the limit if needed
                local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
                if not name then
                    break
                end
                if string.lower(name) == string.lower(spell) then
                    local icon = GetSpellTexture(i, BOOKTYPE_SPELL)
                    return name, rank, icon
                end
            end
            return nil
        end
    end

    local watcher = pfWeakIconsWatcherFrame

    -----------------------------------------------------------------------------
    -- Utility: split a string using a separator (using Lua 5.0's string.gfind)
    -----------------------------------------------------------------------------
    function string.split(inputstr, sep)
        local t = {}
        for token in string.gfind(inputstr, "([^" .. sep .. "]+)") do
            table.insert(t, token)
        end
        return t
    end

    -----------------------------------------------------------------------------
    -- Returns a colored time string using pfUI's API.
    -----------------------------------------------------------------------------
    local function GetColoredTimeString(remaining)
        return pfUI.api.GetColoredTimeString(remaining)
    end

    -----------------------------------------------------------------------------
    -- GUI Configuration
    -----------------------------------------------------------------------------
    pfUI.gui.CreateGUIEntry(T["Thirdparty"], T["Weak Icons"], function()
        -- Active icons settings
        pfUI.gui.CreateConfig(nil, T["Show buffs / debuffs when active"], nil, nil, "header")
        pfUI.gui.CreateConfig(nil, T["Own buffs to track"], C.weakicons.pbuff, "enabled", "list")
        pfUI.gui.CreateConfig(nil, T["Enemy debuffs to track"], C.weakicons.edebuff, "enabled", "list")
        pfUI.gui.CreateConfig(nil, T["Player debuffs to track"], C.weakicons.pdebuff, "enabled", "list") -- Added player debuff tracking
        pfUI.gui.CreateConfig(nil, T["Buff Font Size"], C.weakicons, "bufffontsize")
        pfUI.gui.CreateConfig(nil, T["Debuff Font Size"], C.weakicons, "debufffontsize")
        pfUI.gui.CreateConfig(nil, T["Stack font size"], C.weakicons, "stackfontsize")
        pfUI.gui.CreateConfig(nil, T["Buff icon size"], C.weakicons, "bufficonsize")
        pfUI.gui.CreateConfig(nil, T["Debuff icon size"], C.weakicons, "debufficonsize")
        pfUI.gui.CreateConfig(nil, T["Greyscale on inactive"], C.weakicons, "greyscale", "checkbox")

        -- Inactive icons settings
        pfUI.gui.CreateConfig(nil, T["Show buffs / debuffs when inactive"], nil, nil, "header")
        pfUI.gui.CreateConfig(nil, T["Own buffs to track"], C.weakicons.ipbuff, "enabled", "list")
        pfUI.gui.CreateConfig(nil, T["Enemy debuffs to track"], C.weakicons.iedebuff, "enabled", "list")
        pfUI.gui.CreateConfig(nil, T["Player debuffs to track"], C.weakicons.ipdebuff, "enabled", "list") -- Added inactive player debuff tracking
        pfUI.gui.CreateConfig(nil, T["Buff icon size"], C.weakicons, "ibufficonsize")
        pfUI.gui.CreateConfig(nil, T["Debuff icon size"], C.weakicons, "idebufficonsize")
    end
    )

    -----------------------------------------------------------------------------
    -- Default configuration for active icons.
    -----------------------------------------------------------------------------
    pfUI:UpdateConfig("weakicons", "pbuff", "enabled", "")
    pfUI:UpdateConfig("weakicons", "edebuff", "enabled", "")
    pfUI:UpdateConfig("weakicons", "pdebuff", "enabled", "") -- Added player debuff
    pfUI:UpdateConfig("weakicons", nil, "bufffontsize", "20")
    pfUI:UpdateConfig("weakicons", nil, "debufffontsize", "20")
    pfUI:UpdateConfig("weakicons", nil, "stackfontsize", "11")
    pfUI:UpdateConfig("weakicons", nil, "bufficonsize", "48")
    pfUI:UpdateConfig("weakicons", nil, "debufficonsize", "48")
    pfUI:UpdateConfig("weakicons", nil, "greyscale", "1")

    -----------------------------------------------------------------------------
    -- Default configuration for inactive icons.
    -----------------------------------------------------------------------------
    pfUI:UpdateConfig("weakicons", "ipbuff", "enabled", "")
    pfUI:UpdateConfig("weakicons", "iedebuff", "enabled", "")
    pfUI:UpdateConfig("weakicons", "ipdebuff", "enabled", "") -- Added inactive player debuff
    pfUI:UpdateConfig("weakicons", nil, "ibufficonsize", "48")
    pfUI:UpdateConfig("weakicons", nil, "idebufficonsize", "48")

    -----------------------------------------------------------------------------
    -- NewIcon: creates an aura icon frame.
    -- The 'inactive' flag determines which behavior/settings to use.
    -----------------------------------------------------------------------------
    local function NewIcon(args)
        args = args or {}
        local inactive = args.inactive or false

        -- Use default font.
        args.font = pfUI.font_default or "Fonts\\FRITZQT__.TTF"
        if inactive then
            args.bufffontsize = tonumber(C.weakicons.ibufffontsize) or 20
            args.debufffontsize = tonumber(C.weakicons.idebufffontsize) or 20
            args.size =
                (args.unit == "player") and (tonumber(C.weakicons.ibufficonsize) or 48) or
                (tonumber(C.weakicons.idebufficonsize) or 48)
        else
            args.bufffontsize = tonumber(C.weakicons.bufffontsize) or 20
            args.debufffontsize = tonumber(C.weakicons.debufffontsize) or 20
            args.size =
                (args.unit == "player") and (tonumber(C.weakicons.bufficonsize) or 48) or
                (tonumber(C.weakicons.debufficonsize) or 48)
        end
        args.stackfontsize = tonumber(C.weakicons.stackfontsize) or 11
        args.greyscale = C.weakicons.greyscale
        args.name = args.name or ""
        args.unit = args.unit or "player"

        local br, bg, bb, ba = GetStringColor(pfUI_config.appearance.border.color)
        local backdrop_highlight = {edgeFile = pfUI.media["img:glow"], edgeSize = 8}

        local frameName = "pfWeakIcon_" .. (inactive and "i" or "a") .. "_" .. args.name
        local f = CreateFrame("Frame", frameName, UIParent)
        f:SetWidth(args.size)
        f:SetHeight(args.size)
        f:SetPoint("CENTER", UIParent)

        f.texture = f:CreateTexture()
        f.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        f.texture:SetAllPoints(f)
        f.texture:SetTexture("")

        -- Main, single timer text (large and centered)
        f.text = f:CreateFontString(nil, "OVERLAY")
        f.text:SetPoint("CENTER", f)
        f.text:SetFont(args.font, (args.unit == "player") and args.bufffontsize or args.debufffontsize, "OUTLINE")

        -- Calculate a smaller font size for the dual timers
        local dualTimerFontSize = math.floor(((args.unit == "player") and args.bufffontsize or args.debufffontsize) * 0.8)

        -- Top timer text (smaller and offset)
        f.text_top = f:CreateFontString(nil, "OVERLAY")
        f.text_top:SetPoint("CENTER", f, 0, f:GetHeight() * 0.18)
        f.text_top:SetFont(args.font, dualTimerFontSize, "OUTLINE")

        -- Bottom timer text (smaller and offset)
        f.text_bottom = f:CreateFontString(nil, "OVERLAY")
        f.text_bottom:SetPoint("CENTER", f, 0, f:GetHeight() * -0.18)
        f.text_bottom:SetFont(args.font, dualTimerFontSize, "OUTLINE")

        f.smalltext = f:CreateFontString()
        f.smalltext:SetPoint("BOTTOMRIGHT", f)
        f.smalltext:SetFont(args.font, args.stackfontsize, "OUTLINE")

        f.backdrop = CreateFrame("Frame", nil, f)
        f.backdrop:SetBackdrop(backdrop_highlight)
        f.backdrop:SetBackdropBorderColor(br, bg, bb, ba)
        f.backdrop:SetAllPoints()

        -----------------------------------------------------------------------------
        -- OnUpdate: update icon based on current aura state.
        -----------------------------------------------------------------------------
        f:SetScript("OnUpdate", function()
            if (this.tick or 0) > GetTime() then
                return
            end
            this.tick = GetTime() + 0.2

            if not inactive then
                -- Active icons: show icon if buff is active; if not, optionally show a missing icon.
                local auraDataArray = watcher:fetch(args.name, args.unit, args.auraType)

                if auraDataArray then
                    local instanceCount = table.getn(auraDataArray)
                    local firstAura = auraDataArray[1]

                    -- Set texture from the first found aura
                    if firstAura[4] and firstAura[4] ~= "" then
                        this.texture:SetTexture(firstAura[4])
                    end

                    -- Sort auras by remaining duration, descending
                    table.sort(auraDataArray, function(a, b) return a[1] > b[1] end)

                    if instanceCount > 1 then
                        -- MULTIPLE AURAS (e.g., dual Crusader)
                        this.text:Hide() -- Hide the large central text

                        -- Show longest duration in top text
                        this.text_top:SetText(GetColoredTimeString(auraDataArray[1][1]))
                        this.text_top:Show()

                        -- Show second longest duration in bottom text
                        if auraDataArray[2] then
                            this.text_bottom:SetText(GetColoredTimeString(auraDataArray[2][1]))
                            this.text_bottom:Show()
                        else
                            this.text_bottom:Hide()
                        end
                    else
                        -- SINGLE AURA
                        this.text_top:Hide()
                        this.text_bottom:Hide()

                        -- Show the single timer in the large central text
                        this.text:SetText(GetColoredTimeString(firstAura[1]))
                        this.text:Show()
                    end

                    -- Handle stacks: use instanceCount for soft stacks, otherwise use the aura's own stack count
                    local stacks = (instanceCount > 1) and instanceCount or firstAura[5]
                    if stacks and stacks > 1 then
                        this.smalltext:SetText(stacks)
                    else
                        this.smalltext:SetText("")
                    end

                    this.texture:SetDesaturated(false)
                    this.texture:Show()
                    this.backdrop:Show()
                else
                    -- AURA NOT ACTIVE
                    if C.weakicons.greyscale == "1" then
                        if tonumber(args.name) then
                            local defaultTex = GetSpellTexture(tonumber(args.name)) or ""
                            this.texture:SetTexture(defaultTex)
                        else
                            local _, _, spellIcon = GetSpellInfo(args.name)
                            this.texture:SetTexture(spellIcon or "")
                        end
                        this.texture:SetDesaturated(true)
                        this.texture:Show()
                        this.backdrop:Show()
                    else
                        this.texture:Hide()
                        this.backdrop:Hide()
                    end
                    this.text:SetText("")
                    this.text_top:SetText("")
                    this.text_bottom:SetText("")
                    this.smalltext:SetText("")
                end
            else
                -- Inactive icons: show icon only when the buff is NOT active.
                local auraData = watcher:fetch(args.name, args.unit, args.auraType)
                if auraData then
                    -- Buff is active, so hide the inactive icon.
                    this.texture:Hide()
                    this.backdrop:Hide()
                else
                    -- Ensure we only show inactive debuffs if an enemy is targeted.
                    if args.unit == "target" and (not UnitExists("target") or not UnitCanAttack("player", "target")) then
                        this.texture:Hide()
                        this.backdrop:Hide()
                        return
                    end

                    -- Buff is inactive: show default texture.
                    local defaultTex = ""
                    if tonumber(args.name) then
                        defaultTex = GetSpellTexture(tonumber(args.name)) or ""
                    else
                        local _, _, spellIcon = GetSpellInfo(args.name)
                        defaultTex = spellIcon or ""
                    end
                    this.texture:SetTexture(defaultTex)
                    this.texture:SetDesaturated(false)
                    this.texture:Show()
                    this.backdrop:Show()
                end
            end
        end)

        return f
    end

    -----------------------------------------------------------------------------
    -- Spawn active icons.
    -----------------------------------------------------------------------------
    local pbuffs = string.split(C.weakicons.pbuff.enabled, "#")
    local edebuffs = string.split(C.weakicons.edebuff.enabled, "#")
    local pdebuffs = string.split(C.weakicons.pdebuff.enabled, "#")  -- Get player debuffs
    for _, name in ipairs(pbuffs) do
        if name and name ~= "" then
            local iconFrame = NewIcon({name = name, unit = "player", inactive = false, auraType = "HELPFUL"})
            pfUI.api.UpdateMovable(iconFrame)
        end
    end
    for _, name in ipairs(edebuffs) do
        if name and name ~= "" then
            local iconFrame = NewIcon({name = name, unit = "target", inactive = false})
            pfUI.api.UpdateMovable(iconFrame)
        end
    end
    for _, name in ipairs(pdebuffs) do
        if name and name ~= "" then
            local iconFrame = NewIcon({name = name, unit = "player", inactive = false, auraType = "HARMFUL"})
            pfUI.api.UpdateMovable(iconFrame)
        end
    end

    -----------------------------------------------------------------------------
    -- Spawn inactive icons.
    -----------------------------------------------------------------------------
    local ipbuffs = string.split(C.weakicons.ipbuff.enabled, "#")
    local iedebuffs = string.split(C.weakicons.iedebuff.enabled, "#")
    local ipdebuffs = string.split(C.weakicons.ipdebuff.enabled, "#") -- Get inactive player debuffs
    for _, name in ipairs(ipbuffs) do
        if name and name ~= "" then
            local iconFrame = NewIcon({name = name, unit = "player", inactive = true, auraType = "HELPFUL"})
            pfUI.api.UpdateMovable(iconFrame)
        end
    end
    for _, name in ipairs(iedebuffs) do
        if name and name ~= "" then
            local iconFrame = NewIcon({name = name, unit = "target", inactive = true})
            pfUI.api.UpdateMovable(iconFrame)
        end
    end
    for _, name in ipairs(ipdebuffs) do
        if name and name ~= "" then
            local iconFrame = NewIcon({name = name, unit = "player", inactive = true, auraType = "HARMFUL"})
            pfUI.api.UpdateMovable(iconFrame)
        end
    end
end
)
