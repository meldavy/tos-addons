--dofile("../data/addon_d/speedloader/speedloader.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'speedloader'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local SpeedLoader = _G['ADDONS'][author][addonName]
local acutil = require('acutil')

SpeedLoader.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)
SpeedLoader.BUFF_ID = 1112

SpeedLoader.Settings = {
    Position = {
        X = 400,
        Y = 400
    }
};

SpeedLoader.Default = {
    Height = 60,
    Width = 233,
    IsVisible = 0,
    Movable = 1,
    Enabled = 1, -- Hittest
};

local previousStackCount = 0

function SPEEDLOADER_ON_INIT(addon, frame)
    SpeedLoader.addon = addon;
    SpeedLoader.frame = frame;
    -- load settings
    if not SpeedLoader.Loaded then
        local t, err = acutil.loadJSON(SpeedLoader.SettingsFileLoc, SpeedLoader.Settings);
        if err then
        else
            SpeedLoader.Settings = t;
            SpeedLoader.Loaded = true;
        end
    end
    -- initialize frame
    SPEEDLOADER_ON_FRAME_INIT(frame)

    addon:RegisterMsg('BUFF_UPDATE', 'SPEEDLOADER_ON_BUFF_UPDATE');
    addon:RegisterMsg('BUFF_ADD', 'SPEEDLOADER_ON_BUFF_ADD');
    addon:RegisterMsg('BUFF_REMOVE', 'SPEEDLOADER_ON_BUFF_REMOVE');

end

function SPEEDLOADER_ON_BUFF_ADD(frame, msg, buffIndex, buffType)
    local myHandle = session.GetMyHandle()
    if (buffType == SpeedLoader.BUFF_ID) then
        frame:ShowWindow(1)
        local buff = info.GetBuff(myHandle, buffType);
        local buffOver;
        local buffTime;
        if buff ~= nil then
            buffOver = buff.over;
            buffTime = buff.time;
            if (buffOver ~= previousStackCount) then
                -- stack count changed
                previousStackCount = buffOver
                SpeedLoader:ProcessSpeedLoader(frame)
            end
        end
    end
end

function SPEEDLOADER_ON_BUFF_REMOVE(frame, msg, buffIndex, buffType)
    if (buffType == SpeedLoader.BUFF_ID) then
        frame:ShowWindow(0)
    end
end

function SPEEDLOADER_ON_BUFF_UPDATE(frame, msg, buffIndex, buffType)
    local myHandle = session.GetMyHandle()
    if (buffType == SpeedLoader.BUFF_ID) then
        frame:ShowWindow(1)
        local buff = info.GetBuff(myHandle, buffType);
        local buffOver;
        local buffTime;
        if buff ~= nil then
            buffOver = buff.over;
            buffTime = buff.time;
            if (buffOver ~= previousStackCount) then
                -- stack count changed
                previousStackCount = buffOver
                SpeedLoader:ProcessSpeedLoader(frame)
            end
        end
    end
end

function SPEEDLOADER_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(SpeedLoader.Default.Movable);
    frame:EnableHitTest(SpeedLoader.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "SPEEDLOADER_END_DRAG");

    -- draw the frame
    frame:SetSkinName('None');

    -- set default position of frame
    frame:Move(SpeedLoader.Settings.Position.X, SpeedLoader.Settings.Position.Y);
    frame:SetOffset(SpeedLoader.Settings.Position.X, SpeedLoader.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(SpeedLoader.Default.Width, SpeedLoader.Default.Height);
    frame:ShowWindow(SpeedLoader.Default.IsVisible);

    local skillgaugeleft = frame:CreateOrGetControl("picture", "skillgaugeleft", 4, 21, ui.LEFT, ui.TOP, 38, 21, 0, 0);
    AUTO_CAST(skillgaugeleft)
    skillgaugeleft:SetEnableStretch(1)
    skillgaugeleft:SetImage("skillgaugeleft")
    skillgaugeleft:EnableHitTest(0)
    local skillgaugeright = frame:CreateOrGetControl("picture", "skillgaugeright", 4, 21, ui.RIGHT, ui.TOP, 0, 21, 0, 0);
    AUTO_CAST(skillgaugeright)
    skillgaugeright:SetEnableStretch(1)
    skillgaugeright:SetImage("skillgaugeright")
    skillgaugeright:EnableHitTest(0)
    local reloadGauge = frame:CreateOrGetControl("gauge", "reloadGauge", 187, 50, ui.LEFT, ui.TOP, 42, 6, 0, 0);
    AUTO_CAST(reloadGauge)
    reloadGauge:SetSkinName("speedloader_gauge_yellow")
    reloadGauge:SetPoint(3, 10);
    reloadGauge:AddStat('{s13}%v/%m');
    reloadGauge:SetStatFont(0, 'quickiconfont');
    reloadGauge:SetStatOffset(0, 0, 0);
    reloadGauge:SetStatAlign(0, ui.CENTER_HORZ, ui.CENTER_VERT);
    local infoText = frame:CreateOrGetControl("richtext", "infoText", 200, 20, ui.LEFT, ui.TOP, 44, 0, 0, 0);
    infoText:SetText("{@st42}리로드{/}")
end

function SPEEDLOADER_END_DRAG(frame, ctrl)
    SpeedLoader.Settings.Position.X = SpeedLoader.frame:GetX();
    SpeedLoader.Settings.Position.Y = SpeedLoader.frame:GetY();
    SPEEDLOADER_SAVE_SETTINGS();
end

function SPEEDLOADER_SAVE_SETTINGS()
    acutil.saveJSON(SpeedLoader.SettingsFileLoc, SpeedLoader.Settings);
end

function SpeedLoader.ProcessSpeedLoader(self, frame)
    local myHandle = session.GetMyHandle();
    local buff = info.GetBuff(myHandle, SpeedLoader.BUFF_ID)
    if (buff ~= nil and buff:GetHandle() == session.GetMyHandle()) then
        local gauge = frame:GetChildRecursively('reloadGauge');
        AUTO_CAST(gauge)
        if (buff.over == 10) then
            gauge:SetSkinName("speedloader_gauge_green");
            local actor = world.GetActor(myHandle)
            effect.PlayActorEffect(actor, "F_spin019_1", 'None', 1.0, 4.0)
            imcSound.PlaySoundEvent('sys_tp_box_3');
        elseif (buff.over == 9) then
            gauge:SetSkinName("speedloader_gauge_orange");
        else
            gauge:SetSkinName("speedloader_gauge_yellow");
        end
        gauge:SetPoint(buff.over, 10);
    end
end