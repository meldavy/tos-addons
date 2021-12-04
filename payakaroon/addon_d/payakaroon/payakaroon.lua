--dofile("../data/addon_d/payakaroon/payakaroon.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'payakaroon'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local Payakaroon = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

Payakaroon.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

Payakaroon.Settings = {
    Position = {
        X = 400,
        Y = 400
    }
};

Payakaroon.Default = {
    Height = 60,
    Width = 250,
    IsVisible = 0,
    Movable = 1,
    Enabled = 1, -- Hittest
};

Payakaroon.NAKMUAY_ITEM_BUFF = 4628   -- 삭풍
Payakaroon.RAMMUAY_BUFF = 2137        -- 람무아이

Payakaroon.GaugeHeight = 27

Payakaroon.PreviousStackCount = 0

function PAYAKAROON_ON_INIT(addon, frame)
    Payakaroon.addon = addon;
    Payakaroon.frame = frame;
    -- load settings
    if not Payakaroon.Loaded then
        local t, err = acutil.loadJSON(Payakaroon.SettingsFileLoc, Payakaroon.Settings);
        if err then
        else
            Payakaroon.Settings = t;
            Payakaroon.Loaded = true;
        end
    end
    Payakaroon.PreviousStackCount = 0
    -- initialize frame
    PAYAKAROON_ON_FRAME_INIT(frame)
    addon:RegisterMsg('BUFF_REMOVE', 'PAYAKAROON_ON_BUFF_MSG');
    addon:RegisterMsg('BUFF_ADD', 'PAYAKAROON_ON_BUFF_MSG');
    addon:RegisterMsg('BUFF_UPDATE', 'PAYAKAROON_ON_BUFF_MSG');
end

function PAYAKAROON_ON_BUFF_MSG(frame, msg, buffIndex, buffType)
    local myHandle = session.GetMyHandle()
    if (buffType == Payakaroon.NAKMUAY_ITEM_BUFF) then
        local buff = info.GetBuff(myHandle, buffType);
        local buffOver;
        local buffTime;
        if buff ~= nil then
            buffOver = buff.over
            buffTime = buff.time

            local gauge = frame:GetChildRecursively("gauge")
            if (gauge ~= nil) then
                AUTO_CAST(gauge)
                if (buffOver == 12) then
                    gauge:SetSkinName('payakaroon_gauge_green')
                else
                    gauge:SetSkinName('payakaroon_gauge_yellow')
                end
                gauge:SetPoint(buffOver, 12);
            end

            if (Payakaroon.PreviousStackCount ~= buffOver) then
                Payakaroon.PreviousStackCount = buffOver
                if (buffOver == 12) then
                    local actor = world.GetActor(myHandle)
                    effect.PlayActorEffect(actor, "F_sys_TPBOX_great_300", 'None', 1.0, 4.0)
                end
            end

            if (buffOver > 0) then
                frame:ShowWindow(1)
            else
                frame:ShowWindow(0)
            end
        else
            Payakaroon.PreviousStackCount = 0
            frame:ShowWindow(0)
        end
    end
end

function PAYAKAROON_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(Payakaroon.Default.Movable);
    frame:EnableHitTest(Payakaroon.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "PAYAKAROON_END_DRAG");

    -- draw the frame
    frame:SetSkinName('None');

    -- set default position of frame
    frame:Move(Payakaroon.Settings.Position.X, Payakaroon.Settings.Position.Y);
    frame:SetOffset(Payakaroon.Settings.Position.X, Payakaroon.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(Payakaroon.Default.Width, Payakaroon.Default.Height);

    local infoText = frame:CreateOrGetControl("richtext", "infoText", 200, 20, ui.LEFT, ui.TOP, 10, 0, 0, 0);
    local label = Payakaroon:GetTranslatedString("payakaroon")
    infoText:SetText("{@st42}".. label .. "{/}")
    infoText:EnableHitTest(0)

    local gaugeBox = frame:CreateOrGetControl("groupbox", "gaugebox", 250, 60, ui.LEFT, ui.TOP, 10, 25, 0, 0);
    local skillgaugeleft = gaugeBox:CreateOrGetControl("picture", "skillgaugeleft", 4, 21, ui.LEFT, ui.TOP, 30, 2, 0, 0);
    AUTO_CAST(skillgaugeleft)
    skillgaugeleft:SetEnableStretch(1)
    skillgaugeleft:SetImage("skillgaugeleft")
    skillgaugeleft:EnableHitTest(0)
    local skillgaugeright = gaugeBox:CreateOrGetControl("picture", "skillgaugeright", 4, 21, ui.LEFT, ui.TOP, 34 + 187, 2, 0, 0);
    AUTO_CAST(skillgaugeright)
    skillgaugeright:SetEnableStretch(1)
    skillgaugeright:SetImage("skillgaugeright")
    skillgaugeright:EnableHitTest(0)
    local gauge = gaugeBox:CreateOrGetControl("gauge", "gauge", 187, 25, ui.LEFT, ui.TOP, 34, 0, 0, 0);
    AUTO_CAST(gauge)
    gauge:SetSkinName("payakaroon_gauge_yellow")
    gauge:SetPoint(0, 12);
    gauge:AddStat('{s13}%v');
    gauge:SetStatFont(0, 'quickiconfont');
    gauge:SetStatOffset(0, 0, 0);
    gauge:SetStatAlign(0, ui.CENTER_HORZ, ui.CENTER_VERT);
    gauge:EnableHitTest(0)
    local image = gaugeBox:CreateOrGetControl("picture", "image", 25, 25, ui.LEFT, ui.TOP, 0, 0, 0, 0);
    AUTO_CAST(image)
    image:SetEnableStretch(1)
    local buffCls = GetClassByType('Buff', Payakaroon.RAMMUAY_BUFF);
    image:SetImage("icon_" .. buffCls.Icon)
    image:EnableHitTest(0)

    frame:ShowWindow(Payakaroon.Default.IsVisible);
end

function PAYAKAROON_INVALIDATE_SPIRIT_GAUGE(frame)
    local myHandle = session.GetMyHandle()
    local buffDuration = Payakaroon.SpiritBuffDuration -- 수동 유체
    local buff = info.GetBuff(myHandle, Payakaroon.AutoSpiritBuffID);
    if buff ~= nil then
        buffDuration = Payakaroon.AutoSpiritBuffDuration    -- 떠도는 유체
    end
    -- redraw all gauges
    for buffId, count in pairs(Payakaroon.SpiritBuffs) do
        if (count > 0) then
            local buff = info.GetBuff(myHandle, buffId);
            if buff ~= nil then
                local gaugeBox = frame:GetChildRecursively("gauge_" .. tostring(buffId));
                if (gaugeBox ~= nil) then
                    local spiritGauge = gaugeBox:GetChildRecursively("spiritgauge")
                    if (spiritGauge ~= nil) then
                        AUTO_CAST(spiritGauge)
                        spiritGauge:SetPoint(buff.time / 1000, buffDuration);
                    end
                end
            end
        end
    end
    return 1
end

function PAYAKAROON_END_DRAG(frame, ctrl)
    Payakaroon.Settings.Position.X = Payakaroon.frame:GetX();
    Payakaroon.Settings.Position.Y = Payakaroon.frame:GetY();
    PAYAKAROON_SAVE_SETTINGS();
end

function PAYAKAROON_SAVE_SETTINGS()
    acutil.saveJSON(Payakaroon.SettingsFileLoc, Payakaroon.Settings);
end

-- general utilities

Payakaroon.Strings = {
    ["payakaroon"] = {
        ['kr'] = "삭풍",
        ['en'] = "Payakaroon"
    }
}

function Payakaroon.GetTranslatedString(self, strName)
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

function Payakaroon.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end