--dofile("../data/addon_d/soulmaster/soulmaster.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'soulmaster'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local Soulmaster = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

Soulmaster.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

Soulmaster.Settings = {
    Position = {
        X = 400,
        Y = 400
    }
};

Soulmaster.Default = {
    Height = 60,
    Width = 250,
    IsVisible = 0,
    Movable = 1,
    Enabled = 1, -- Hittest
};

Soulmaster.SpiritBuffs = {}
Soulmaster.SpiritBuffID = 1140
Soulmaster.AutoSpiritBuffID = 1141

Soulmaster.SpiritBuffDuration = 10
Soulmaster.AutoSpiritBuffDuration = 3

Soulmaster.GaugeHeight = 27

function SOULMASTER_ON_INIT(addon, frame)
    Soulmaster.addon = addon;
    Soulmaster.frame = frame;
    -- load settings
    if not Soulmaster.Loaded then
        local t, err = acutil.loadJSON(Soulmaster.SettingsFileLoc, Soulmaster.Settings);
        if err then
        else
            Soulmaster.Settings = t;
            Soulmaster.Loaded = true;
        end
    end

    Soulmaster.SpiritBuffs = {
        [1134] = 0, --포제션
        [1135] = 0, --프라크리티
        [1136] = 0, --애니라
        [1137] = 0, --타노티
        [1138] = 0, --파타티
        [1139] = 0, --모크샤
    }

    -- initialize frame
    SOULMASTER_ON_FRAME_INIT(frame)
    addon:RegisterMsg('BUFF_REMOVE', 'SOULMASTER_ON_BUFF_REMOVE');
    addon:RegisterMsg('BUFF_ADD', 'SOULMASTER_ON_BUFF_ADD');
end

function SOULMASTER_ON_BUFF_ADD(frame, msg, buffIndex, buffType)
    if (Soulmaster.SpiritBuffs[buffType] ~= nil) then
        frame:ShowWindow(1)
        if (Soulmaster.SpiritBuffs[buffType] == 0) then
            Soulmaster.SpiritBuffs[buffType] = 1
            Soulmaster:AddSpiritBuff(frame, buffType)
        end
    end
end

function SOULMASTER_ON_BUFF_REMOVE(frame, msg, buffIndex, buffType)
    if (Soulmaster.SpiritBuffs[buffType] ~= nil) then
        if (Soulmaster.SpiritBuffs[buffType] == 1) then
            Soulmaster.SpiritBuffs[buffType] = 0
            Soulmaster:RemoveSpiritBuff(frame, buffType)
        end
    end
end

function SOULMASTER_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(Soulmaster.Default.Movable);
    frame:EnableHitTest(Soulmaster.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "SOULMASTER_END_DRAG");

    -- draw the frame
    frame:SetSkinName('None');

    -- set default position of frame
    frame:Move(Soulmaster.Settings.Position.X, Soulmaster.Settings.Position.Y);
    frame:SetOffset(Soulmaster.Settings.Position.X, Soulmaster.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(Soulmaster.Default.Width, Soulmaster.Default.Height);

    local infoText = frame:CreateOrGetControl("richtext", "infoText", 200, 20, ui.LEFT, ui.TOP, 10, 0, 0, 0);
    local label = Soulmaster:GetTranslatedString("soulmaster")
    infoText:SetText("{@st42}".. label .. "{/}")
    infoText:EnableHitTest(0)

    frame:ShowWindow(Soulmaster.Default.IsVisible);
end

function SOULMASTER_INVALIDATE_SPIRIT_GAUGE(frame)
    local myHandle = session.GetMyHandle()
    local buffDuration = Soulmaster.SpiritBuffDuration -- 수동 유체
    local buff = info.GetBuff(myHandle, Soulmaster.AutoSpiritBuffID);
    if buff ~= nil then
        buffDuration = Soulmaster.AutoSpiritBuffDuration    -- 떠도는 유체
    end
    -- redraw all gauges
    for buffId, count in pairs(Soulmaster.SpiritBuffs) do
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

function Soulmaster.AddSpiritBuff(self, frame, cls)
    local myHandle = session.GetMyHandle()
    local buffDuration = Soulmaster.SpiritBuffDuration -- 수동 유체
    local buff = info.GetBuff(myHandle, Soulmaster.AutoSpiritBuffID);
    if buff ~= nil then
        buffDuration = Soulmaster.AutoSpiritBuffDuration    -- 떠도는 유체
    end

    -- reposition all gauges
    local totalCount = 0
    for buffId, count in pairs(Soulmaster.SpiritBuffs) do
        totalCount = totalCount + count
        if (count > 0) then
            local yPos = (totalCount - 1) * Soulmaster.GaugeHeight + 25
            local gaugeBox = frame:CreateOrGetControl("groupbox", "gauge_" .. tostring(buffId), 250, 60, ui.LEFT, ui.TOP, 10, yPos, 0, 0);
            AUTO_CAST(gaugeBox)
            gaugeBox:SetPos(10, yPos)
        end
    end

    frame:Resize(Soulmaster.Default.Width, 25 + totalCount * 60);

    -- draw
    local gaugeBox = frame:GetChildRecursively("gauge_" .. cls);
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
    local spiritgauge = gaugeBox:CreateOrGetControl("gauge", "spiritgauge", 187, 25, ui.LEFT, ui.TOP, 34, 0, 0, 0);
    AUTO_CAST(spiritgauge)
    spiritgauge:SetSkinName("soulmaster_gauge_yellow")
    spiritgauge:SetPoint(buffDuration, buffDuration);
    spiritgauge:AddStat('{s13}%v');
    spiritgauge:SetStatFont(0, 'quickiconfont');
    spiritgauge:SetStatOffset(0, 0, 0);
    spiritgauge:SetStatAlign(0, ui.CENTER_HORZ, ui.CENTER_VERT);
    spiritgauge:EnableHitTest(0)
    local image = gaugeBox:CreateOrGetControl("picture", "image", 25, 25, ui.LEFT, ui.TOP, 0, 0, 0, 0);
    AUTO_CAST(image)
    image:SetEnableStretch(1)
    local buffCls = GetClassByType('Buff', cls);
    image:SetImage("icon_" .. buffCls.Icon)
    image:EnableHitTest(0)

    if (totalCount > 0) then
        frame:RunUpdateScript("SOULMASTER_INVALIDATE_SPIRIT_GAUGE", 0.05)
    end
end

function Soulmaster.RemoveSpiritBuff(self, frame, cls)
    -- remove child
    if (frame:GetChildRecursively("gauge_" .. cls) ~= nil) then
        frame:RemoveChild("gauge_" .. cls)

        -- reposition all gauges
        local totalCount = 0
        for buffId, count in pairs(Soulmaster.SpiritBuffs) do
            totalCount = totalCount + count
            if (count > 0) then
                local yPos = (totalCount - 1) * Soulmaster.GaugeHeight + 25
                local gaugeBox = frame:CreateOrGetControl("groupbox", "gauge_" .. buffId, 250, Soulmaster.GaugeHeight, ui.LEFT, ui.TOP, 10, yPos, 0, 0);
                AUTO_CAST(gaugeBox)
                gaugeBox:SetPos(10, yPos)
            end
        end
        frame:Resize(Soulmaster.Default.Width, 25 + totalCount * 60);

        if (totalCount == 0) then
            frame:StopUpdateScript("SOULMASTER_INVALIDATE_SPIRIT_GAUGE")
            frame:ShowWindow(0)
        end
    end
end

function SOULMASTER_END_DRAG(frame, ctrl)
    Soulmaster.Settings.Position.X = Soulmaster.frame:GetX();
    Soulmaster.Settings.Position.Y = Soulmaster.frame:GetY();
    SOULMASTER_SAVE_SETTINGS();
end

function SOULMASTER_SAVE_SETTINGS()
    acutil.saveJSON(Soulmaster.SettingsFileLoc, Soulmaster.Settings);
end

-- general utilities

Soulmaster.Strings = {
    ["soulmaster"] = {
        ['kr'] = "유체 숙련",
        ['en'] = "Soul Master"
    }
}

function Soulmaster.GetTranslatedString(self, strName)
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

function Soulmaster.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end