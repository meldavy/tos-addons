--dofile("../data/addon_d/hwarangtracker/hwarangtracker.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'hwarangtracker'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local HwarangTracker = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

HwarangTracker.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

HwarangTracker.Settings = {
    Position = {
        X = 400,
        Y = 400
    }
};

HwarangTracker.Default = {
    Height = 150,
    Width = 150,
    IsVisible = 0,
    Movable = 1,
    Enabled = 1, -- Hittest
};

HwarangTracker.BUFF_ID = 478;     -- 기백
HwarangTracker.DEBUFF_ID = 479;   -- 여흔

HwarangTracker.DO_NOT_RETREAT_ID = 32204; -- 임전무퇴
HwarangTracker.ARROW_DANCING_ID = 32206;  -- 궁무
HwarangTracker.PYEONJEON_ID = 32201;      -- 애기살

function HWARANGTRACKER_ON_INIT(addon, frame)
    HwarangTracker.addon = addon;
    HwarangTracker.frame = frame;
    -- load settings
    if not HwarangTracker.Loaded then
        local t, err = acutil.loadJSON(HwarangTracker.SettingsFileLoc, HwarangTracker.Settings);
        if err then
        else
            HwarangTracker.Settings = t;
            HwarangTracker.Loaded = true;
        end
    end
    -- initialize frame
    HWARANGTRACKER_ON_FRAME_INIT(frame)

    addon:RegisterMsg('BUFF_UPDATE', 'HWARANGTRACKER_ON_BUFF_MSG');
    addon:RegisterMsg('BUFF_ADD', 'HWARANGTRACKER_ON_BUFF_MSG');
    addon:RegisterMsg('BUFF_REMOVE', 'HWARANGTRACKER_ON_BUFF_MSG');
end

function HWARANGTRACKER_ON_BUFF_MSG(frame, msg, buffIndex, buffType)
    local myHandle = session.GetMyHandle()
    if (buffType == HwarangTracker.BUFF_ID) then
        local buff = info.GetBuff(myHandle, buffType);
        local buffOver;
        local buffTime;
        if buff ~= nil then
            buffOver = buff.over
            buffTime = buff.time
            local retreatCooldown = HWARANGTRACKER_GET_SKILL_COOLDOWN(HwarangTracker.DO_NOT_RETREAT_ID)
            local pyeonjeonCooldown = HWARANGTRACKER_GET_SKILL_COOLDOWN(HwarangTracker.PYEONJEON_ID)
            local arrowDancingCooldown = HWARANGTRACKER_GET_SKILL_COOLDOWN(HwarangTracker.ARROW_DANCING_ID)
            local useCount = 0

            if (arrowDancingCooldown <= retreatCooldown) then
                useCount = math.max(buffOver - 2, 0)
            end

            if (pyeonjeonCooldown <= retreatCooldown) then
                useCount = buffOver
            end

            local countText = frame:GetChildRecursively("buffCount");
            countText:SetText("{@st43}{s60}" .. useCount .. "{/}")

            local buffIconText = "{img icon_Hwarang_Skillcost_Buff 24 24}"
            if (useCount > 1) then
                for index = 1, useCount - 1 do
                    buffIconText = buffIconText .. " {img icon_Hwarang_Skillcost_Buff 24 24}"
                end
            end
            local buffIcons = frame:GetChildRecursively("buffIcons");
            buffIcons:SetText(buffIconText)

            if (useCount > 0) then
                frame:ShowWindow(1)
            else
                frame:ShowWindow(0)
            end
        else
            frame:ShowWindow(0)
        end
    end
end

function HWARANGTRACKER_GET_SKILL_COOLDOWN(type)
    local totalTime = 0;
    local curTime = 0;
    local skillInfo = session.GetSkill(type);
    if skillInfo ~= nil then
        local remainRefresh = skillInfo:GetRemainRefreshTimeMS();
        if remainRefresh > 0 then
            return remainRefresh, skillInfo:GetMaxRefreshTimeMS();
        end
        curTime = skillInfo:GetCurrentCoolDownTime();
        totalTime = skillInfo:GetTotalCoolDownTime();
    end
    return curTime, totalTime;
end

function HWARANGTRACKER_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(HwarangTracker.Default.Movable);
    frame:EnableHitTest(HwarangTracker.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "HWARANGTRACKER_END_DRAG");

    -- draw the frame
    frame:SetSkinName('chat_window');

    -- set default position of frame
    frame:Move(HwarangTracker.Settings.Position.X, HwarangTracker.Settings.Position.Y);
    frame:SetOffset(HwarangTracker.Settings.Position.X, HwarangTracker.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(HwarangTracker.Default.Width, HwarangTracker.Default.Height);

    local title = frame:CreateOrGetControl("richtext", "title", 100, 30, ui.CENTER_HORZ, ui.TOP, 0, 4, 0, 0);
    title:SetFontName("white_16_ol")
    title:SetText("Hwarang Tracker")
    title:EnableHitTest(0)

    local buffCount = frame:CreateOrGetControl("richtext", "buffCount", 100, 100, ui.CENTER_HORZ, ui.TOP, 0, 30, 0, 0);
    buffCount:SetText("{@st43}{s60}4{/}")
    buffCount:EnableHitTest(0)

    local buffIcons = frame:CreateOrGetControl("richtext", "buffIcons", 100, 30, ui.CENTER_HORZ, ui.BOTTOM, 0, 0, 0, 10);
    buffIcons:SetFontName("white_16_ol")
    buffIcons:SetText("{img icon_Hwarang_Skillcost_Buff 24 24} {img icon_Hwarang_Skillcost_Buff 24 24} {img icon_Hwarang_Skillcost_Buff 24 24} {img icon_Hwarang_Skillcost_Buff 24 24}")
    buffIcons:EnableHitTest(0)

    frame:ShowWindow(HwarangTracker.Default.IsVisible);
end

function HWARANGTRACKER_END_DRAG(frame, ctrl)
    HwarangTracker.Settings.Position.X = HwarangTracker.frame:GetX();
    HwarangTracker.Settings.Position.Y = HwarangTracker.frame:GetY();
    HWARANGTRACKER_SAVE_SETTINGS();
end

function HWARANGTRACKER_SAVE_SETTINGS()
    acutil.saveJSON(HwarangTracker.SettingsFileLoc, HwarangTracker.Settings);
end

-- general utilities

HwarangTracker.Strings = {
    ["string_name"] = {
        ['kr'] = "안녕 세상아",
        ['en'] = "Hello World"
    }
}

function HwarangTracker.GetTranslatedString(self, strName)
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

function HwarangTracker.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end