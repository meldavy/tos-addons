--dofile("../data/addon_d/summontracker/summontracker.lua")

-- areas defined
local author = 'meldavy'
local addonName = 'summontracker'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local SummonTracker = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

SummonTracker.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

SummonTracker.Settings = {
    Position = {
        X = 400,
        Y = 400
    }
}

SummonTracker.Default = {
    Height = 0,
    Width = 0,
    IsVisible = 1,
    Movable = 1,
    Enabled = 1, -- Hittest
}

SummonTracker.SummonSkills = {
    [20701] = 1,    -- 서모닝
    [20707] = 1,    -- 살라미온
    [20909] = 1,    -- 해골병사
    [20911] = 1,    -- 해골궁수
    [20912] = 1,    -- 해골법사
    [20902] = 1,    -- 쇼고스
    [20908] = 1,    -- 콥스타워
    [51401] = 1,    -- 바롱
    [21607] = 1,    -- 여우
    [41406] = 1,    -- 브레이킹 휠
    [40401] = 1,    -- 바카리네
    [40402] = 1,    -- 제미나
    [40403] = 1,    -- 라이마
    [40407] = 1,    -- 아우슈
    [40405] = 1,    -- 부엉이
    [30201] = 1,    -- 파비스
}

SummonTracker.SummonClasses = {
    ["pc_summon_Legend_card_Avataras"] = {
        Icon = "icon_wizar_summon"
    },
    ["Saloon"] = {
        Icon = "icon_wizar_Summonsalamion"
    },
    ["pcskill_skullarcher"] = {
        Icon = "icon_wizar_RaiseSkullarcher"
    },
    ["pcskill_skullwizard"] = {
        Icon = "icon_wizar_RaiseSkullwizard"
    },
    ["pcskill_skullsoldier"] = {
        Icon = "icon_wizar_RaiseDead"
    },
    ["pcskill_skullelitesoldier"] = {
        Icon = "icon_wizar_RaiseDead"
    },
    ["Vibora_Spiritwizard"] = {
        Icon = "icon_wizar_RaiseSkullwizard"
    },
    ["Vibora_Spiritsoldier"] = {
        Icon = "icon_wizar_RaiseDead"
    },
    ["Vibora_Spiritelitesoldier"] = {
        Icon = "icon_wizar_RaiseDead"
    },
    ["Vibora_Spiritarcher"] = {
        Icon = "icon_wizar_RaiseSkullarcher"
    },
    ["pcskill_CorpseTower"] = {
        Icon = "icon_wizar_CorpseTower"
    },
    ["pcskill_shogogoth"] = {
        Icon = "icon_wizar_Shoggoth"
    },
    ["pcskill_Barong"] = {
        Icon = "icon_scout_Barong"
    },
    ["pcskill_FireFoxShikigami"] = {
        Icon = "icon_wizar_FireFoxShikigami"
    },
    ["pcskill_Big_FireFoxShikigami"] = {
        Icon = "icon_wizar_FireFoxShikigami"
    },
    ["pcskill_Breaking_wheel"] = {
        Icon = "icon_cler_BreakingWheel"
    },
    ["pcskill_HengeStone"] = {
        Icon = "icon_cler_Hengestone"
    },
    ["pcskill_leghold_trap"] = {
        Icon = "icon_arc_LegHoldTrap"
    },
    ["pcskill_spring_trap"] = {
        Icon = "icon_arc_SpringTrap"
    },
    ["skill_sapper_trap1"] = {
        Icon = "icon_arch_punjistake"
    },
    ["skill_sapper_trap2"] = {
        Icon = "icon_arch_Broom_trap"
    },
    ["skill_sapper_trap4"] = {
        Icon = "icon_arch_Claymore"
    },
    ["pcskill_stake_stockades"] = {
        Icon = "icon_arch_StakeStockades"
    },
    ["pcskill_wood_ausrine2"] = {
        Icon = "icon_cler_craveAusirine"
    },
    ["pcskill_wood_bakarine2"] = {
        Icon = "icon_cler_craveVakarine"
    },
    ["pcskill_wood_laima2"] = {
        Icon = "icon_cler_craveLaima"
    },
    ["pcskill_wood_owl2"] = {
        Icon = "icon_cler_craveOwl"
    },
    ["pcskill_wood_zemina2"] = {
        Icon = "icon_cler_craveZemyna"
    },
    ["pcskill_wood_AustrasKoks2"] = {
        Icon = "icon_cler_craveAustrasKoks"
    },
    ["pcskill_wood_ausrine"] = {
        Icon = "icon_cler_craveAusirine"
    },
    ["pcskill_wood_bakarine"] = {
        Icon = "icon_cler_craveVakarine"
    },
    ["pcskill_wood_laima"] = {
        Icon = "icon_cler_craveLaima"
    },
    ["pcskill_wood_owl"] = {
        Icon = "icon_cler_craveOwl"
    },
    ["pcskill_wood_zemina"] = {
        Icon = "icon_cler_craveZemyna"
    },
    ["pcskill_wood_AustrasKoks"] = {
        Icon = "icon_cler_craveAustrasKoks"
    },
    ["pavise"] = {
        Icon = "icon_arch_DeployPavise"
    },
}

local activeHandles = {}

function SUMMONTRACKER_ON_INIT(addon, frame)
    SummonTracker.addon = addon
    SummonTracker.frame = frame
    -- load settings
    if not SummonTracker.Loaded then
        local t, err = acutil.loadJSON(SummonTracker.SettingsFileLoc, SummonTracker.Settings)
        if err then
        else
            SummonTracker.Settings = t
            SummonTracker.Loaded = true
        end
    end
    activeHandles = {}
    -- initialize frame
    SUMMONTRACKER_ON_FRAME_INIT(frame)
    addon:RegisterMsg('GAME_START', 'SUMMONTRACKER_ON_GAME_START');
end

function SUMMONTRACKER_ON_GAME_START()
    SummonTracker.frame:RunUpdateScript("SUMMONTRACKER_ON_TICK", 0.5)
end

function SUMMONTRACKER_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(SummonTracker.Default.Movable)
    frame:EnableHitTest(SummonTracker.Default.Enabled)
    frame:SetEventScript(ui.LBUTTONUP, "SUMMONTRACKER_END_DRAG")

    -- draw the frame
    frame:SetSkinName('chat_window')

    -- set default position of frame
    frame:Move(SummonTracker.Settings.Position.X, SummonTracker.Settings.Position.Y)
    frame:SetOffset(SummonTracker.Settings.Position.X, SummonTracker.Settings.Position.Y)

    -- set default size and visibility
    frame:Resize(SummonTracker.Default.Width, SummonTracker.Default.Height)
    frame:ShowWindow(SummonTracker.Default.IsVisible)
end

function SUMMONTRACKER_END_DRAG(frame, ctrl)
    SummonTracker.Settings.Position.X = SummonTracker.frame:GetX()
    SummonTracker.Settings.Position.Y = SummonTracker.frame:GetY()
    SUMMONTRACKER_SAVE_SETTINGS()
end

function SUMMONTRACKER_SAVE_SETTINGS()
    acutil.saveJSON(SummonTracker.SettingsFileLoc, SummonTracker.Settings)
end

function SUMMONTRACKER_CLOSE(frame)
    local handle = frame:GetUserIValue("HANDLE")
    activeHandles[handle] = nil
    SUMMONTRACKER_INVALIDATE()
end

function SUMMONTRACKER_INVALIDATE()
    -- redraw frame
    local summontrackerframe = ui.GetFrame("summontrackerframe")
    if (summontrackerframe == nil) then
        -- create base frame
        summontrackerframe = ui.CreateNewFrame("summontracker", "summontrackerframe")
        summontrackerframe:Resize(180, 80)
        summontrackerframe:SetSkinName("None")
        summontrackerframe:SetLayerLevel(22) -- 콜리니 hud 위에 표시
        summontrackerframe:EnableHitTest(0)
        local slotset = summontrackerframe:CreateOrGetControl("slotset", "slotset", 180, 100, ui.CENTER_HORZ, ui.TOP, 0, 0, 0, 0)
        slotset:EnableHitTest(0)
        AUTO_CAST(slotset)
        slotset:EnablePop(0)
        slotset:EnableDrag(0)
        slotset:EnableDrop(0)
        slotset:SetSlotSize(24, 24)
        slotset:SetColRow(5, 3)
        slotset:SetSpc(1, 1)
        slotset:SetSkinName('None')
        slotset:EnableSelection(0)
        slotset:CreateSlots()
        local offsetY = -75
        summontrackerframe:ShowWindow(1)
        FRAME_AUTO_POS_TO_OBJ(summontrackerframe, session.GetMyHandle(), -summontrackerframe:GetWidth() / 2, offsetY, 0, 1, 1)
    elseif (summontrackerframe:IsVisible() == 0) then
        summontrackerframe:ShowWindow(1)
    end
    -- invalidate icons
    local summonTypes = {}
    for handle, className in pairs(activeHandles) do
        if (className ~= nil) then
            if (summonTypes[className] == nil) then
                summonTypes[className] = 0
            end
            summonTypes[className] = summonTypes[className] + 1
        end
    end
    local slotset = summontrackerframe:GetChildRecursively("slotset")
    AUTO_CAST(slotset)
    local slotIndex = slotset:GetSlotCount() - 1
    for className, count in pairs(summonTypes) do
        if (slotIndex < 0) then
            return
        end
        local slot = slotset:GetSlotByIndex(slotIndex)
        if (slot ~= nil) then
            AUTO_CAST(slot)
            local icon = CreateIcon(slot);
            local iconName = ""
            if (SummonTracker.TextStartsWith(className, "pc_summon_Legend_card") == true) then
                iconName = "icon_wizar_summon"
            elseif (SummonTracker.TextStartsWith(className, "ancient") == true) then
                iconName = "icon_common_SummonMonster"
            else
                iconName = SummonTracker.SummonClasses[className].Icon;
            end
            icon:SetImage(iconName);
            slot:SetText('{s12}{ol}{b}'..count, 'count', ui.RIGHT, ui.BOTTOM, -1, -1)
        end
        slotIndex = slotIndex - 1
    end
    -- cleanup unused slots
    for i = 0, slotIndex do
        local slot = slotset:GetSlotByIndex(i)
        AUTO_CAST(slot)
        slot:ClearIcon();
        slot:SetText("");
    end
end

function SUMMONTRACKER_ON_TICK(frame)
    local list, count = SelectObject(GetMyPCObject(), 500, 'ALL')
    local myHandle = session.GetMyHandle()
    for i = 1, count do
        local handle = GetHandle(list[i])
        local className = list[i].ClassName
        local ownerHandle = info.GetOwner(handle)
        if (SummonTracker.SummonClasses[className] ~= nil or SummonTracker.TextStartsWith(className, "pc_summon_Legend_card") == true or SummonTracker.TextStartsWith(className, "ancient") == true) then
            -- is a tracked summon
            if (myHandle == ownerHandle) then
                -- this is PC's summon
                activeHandles[handle] = className -- persist handle
                local summonframe = ui.GetFrame("summontracker_" .. handle)
                if (summonframe == nil) then
                    summonframe = ui.CreateNewFrame("summontracker", "summontracker_" .. handle)
                    summonframe:SetUserValue("HANDLE", handle)
                    summonframe:SetCloseScript("SUMMONTRACKER_CLOSE")
                    summonframe:Resize(0, 0)
                    summonframe:SetSkinName("None")
                    summonframe:SetLayerLevel(22) -- 콜리니 hud 위에 표시
                    summonframe:EnableHitTest(0)
                    local name = summonframe:CreateOrGetControl("richtext", "name", 200, 40, ui.CENTER_HORZ, ui.TOP, 0, 0, 0, 0)
                    name:SetFontName("white_16_ol")
                    name:SetText(className)
                    summonframe:ShowWindow(1)
                elseif (summonframe:IsVisible() == 0) then
                    summonframe:ShowWindow(1)
                end
                local offsetY = -10
                SUMMONTRACKER_INVALIDATE()
                FRAME_AUTO_POS_TO_OBJ(summonframe, handle, -summonframe:GetWidth() / 2, offsetY, 3, 1)
            end
        end
    end
    return 1
end

-- general utilities

SummonTracker.Strings = {
    ["string_name"] = {
        ['kr'] = "안녕 세상아",
        ['en'] = "Hello World"
    }
}

function SummonTracker.TextStartsWith(text, prefix)
    return string.lower(text):find(string.lower(prefix), 1, true) == 1
end

function SummonTracker.GetTranslatedString(self, strName)
    local countrycode = option.GetCurrentCountry()
    local language = 'kr'
    if countrycode == 'kr' then
        language = 'kr'
    else
        language = 'en'
    end

    if (self.Strings[strName] == nil) then
        return nil
    else
        return self.Strings[strName][language]
    end
end

function SummonTracker.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName]
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end