--dofile("../data/addon_d/buffnotifier/buffnotifier.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'buffnotifier'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local BuffNotifier = _G['ADDONS'][author][addonName]
local acutil = require('acutil')

BuffNotifier.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

BuffNotifier.Settings = {
    Position = {
        X = 150,
        Y = 550
    }
};

BuffNotifier.Default = {
    Height = 40,
    Width = 230,
    IsVisible = 0,
    Movable = 0,
    Enabled = 0, -- Hittest
};

BuffNotifier.addedbuffcount = 0;
BuffNotifier.alreadyDisplayedIndex = {};
BuffNotifier.removedbuffcount = 0;

function BUFFNOTIFIER_ON_INIT(addon, frame)
    BuffNotifier.addon = addon;
    BuffNotifier.frame = frame;
    -- load settings
    if not BuffNotifier.Loaded then
        local t, err = acutil.loadJSON(BuffNotifier.SettingsFileLoc, BuffNotifier.Settings);
        if err then
        else
            BuffNotifier.Settings = t;
            BuffNotifier.Loaded = true;
        end
    end
    BuffNotifier.alreadyDisplayedIndex = {};
    addon:RegisterMsg('BUFF_ADD', 'BUFFNOTIFIER_ON_BUFF_ADD');
    addon:RegisterMsg('BUFF_REMOVE', 'BUFFNOTIFIER_ON_BUFF_REMOVE');
end

function BUFFNOTIFIER_ON_BUFF_ADD(frame, msg, buffIndex, buffID)
    local buffCls = GetClassByType('Buff', buffID);

    -- 표시 할 버프만 보여줌
    if (BuffNotifier:FilterBuff(buffCls) ~= 1) then
        return
    end
    local key = "ADD" .. buffID
    if BuffNotifier.alreadyDisplayedIndex[key] == nil then
        BuffNotifier.alreadyDisplayedIndex[key] = "AlreadyOpen"
        BuffNotifier.addedbuffcount = BuffNotifier.addedbuffcount + 1;
        local frameName = "BUFFNOTIFIER_ADD_"..BuffNotifier.addedbuffcount;
        ui.DestroyFrame(frameName);
        local frame = ui.CreateNewFrame("buffnotifier", frameName);
        frame:SetUserValue("buffID", key)
        BUFFNOTIFIER_ON_FRAME_INIT(frame, buffCls, 1)
        BUFFNOTIFIER_BUFF_ADD_OPEN(frame);
    end
end

function BUFFNOTIFIER_BUFF_ADD_OPEN(frame)
    BuffNotifier:PushBuff(frame, "BUFFNOTIFIER_ADD_", -42);
end

function BUFFNOTIFIER_ON_BUFF_REMOVE(frame, msg, buffIndex, buffID)
    local buffCls = GetClassByType('Buff', buffID);
    -- 표시 할 버프만 보여줌
    if (BuffNotifier:FilterBuff(buffCls) ~= 1) then
        return
    end
    local key = "REMOVE" .. buffID
    if BuffNotifier.alreadyDisplayedIndex[key] == nil then
        BuffNotifier.alreadyDisplayedIndex[key] = "AlreadyOpen"
        BuffNotifier.removedbuffcount = BuffNotifier.removedbuffcount + 1;
        local frameName = "BUFFNOTIFIER_REMOVE_"..BuffNotifier.removedbuffcount;
        ui.DestroyFrame(frameName);
        local frame = ui.CreateNewFrame("buffnotifier", frameName);
        frame:SetUserValue("buffID", key)
        BUFFNOTIFIER_ON_FRAME_INIT(frame, buffCls, 0)
        BUFFNOTIFIER_BUFF_REMOVE_OPEN(frame);
    end
end

function BUFFNOTIFIER_BUFF_REMOVE_OPEN(frame)
    BuffNotifier:PushBuff(frame, "BUFFNOTIFIER_REMOVE_", 42);
end

function BUFFNOTIFIER_CLOSE(frame)
    local key = frame:GetUserValue("buffID")
    BuffNotifier.alreadyDisplayedIndex[key] = nil
    ui.DestroyFrame(frame:GetName());
end

function BUFFNOTIFIER_ON_FRAME_INIT(frame, buffCls, type)
    -- enable frame reposition through drag and move
    frame:EnableMove(BuffNotifier.Default.Movable);
    frame:EnableHitTest(BuffNotifier.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "BUFFNOTIFIER_END_DRAG");

    -- show frame relative to center screen
    local screenWidth = ui.GetSceneWidth();
    local xPos = (screenWidth // 2) + BuffNotifier.Settings.Position.X
    local yPos = BuffNotifier.Settings.Position.Y
    if (type == 1) then
        yPos = yPos - 40
    end
    frame:Move(xPos, yPos);
    frame:SetOffset(xPos, yPos);

    -- draw the frame
    frame:SetSkinName('chat_window');

    frame:SetOpenScript("BUFFNOTIFIER_OPEN")
    frame:SetCloseScript("BUFFNOTIFIER_CLOSE")

    frame:SetAnimation("closeAnim", "sequentialpickitem_close")
    frame:SetAnimation("openAnim", "sequentialpickitem_open");

    -- set default size and visibility
    frame:Resize(BuffNotifier.Default.Width, BuffNotifier.Default.Height);

    -- controls
    local icon = frame:CreateOrGetControl("picture", "icon", 40, 40, ui.LEFT, ui.TOP, 0, 0, 0, 0);
    AUTO_CAST(icon)
    icon:SetImage("icon_" .. buffCls.Icon);
    icon:SetEnableStretch(1)

    local titleText = frame:CreateOrGetControl("richtext", "name", 50, 10, 0, 0);
    titleText:SetFontName("white_16_ol");
    if (type == 1) then
        titleText:SetText("{#45ff45}" .. buffCls.Name);
    else
        titleText:SetText("{#ff3d3d}" .. buffCls.Name);
    end
    titleText:EnableHitTest(0);

    --display
    local duration = 2.5
    frame:ShowWindow(1);
    frame:SetDuration(duration);
    frame:Invalidate();
end

function BuffNotifier.PushBuff(self, frame, prefix, push)
    local index = string.find(frame:GetName(), prefix);
    local frameindex = string.sub(frame:GetName(), index + string.len(prefix), string.len(frame:GetName()))
    local nowcount = tonumber(frameindex) - 1;
    for i = nowcount, 0, -1 do
        local beforeFrameName = prefix..tostring(i);
        local beforeframe = ui.GetFrame(beforeFrameName)
        if beforeframe == nil then
            break;
        end
        --if (push > 0) then
        --    UI_PLAYFORCE(beforeframe, "slotsetDownMove");
        --else
        --    UI_PLAYFORCE(beforeframe, "slotsetUpMove");
        --end

        beforeframe:MoveFrame(beforeframe:GetX(), beforeframe:GetY() + push);
    end
end

function BuffNotifier.FilterBuff(self, buffCls)
    local buffID = buffCls.ClassID
    -- 표시 할 버프만 보여줌
    local buffGroup1 = TryGetProp(buffCls, "Group1", "Buff");
    if (buffGroup1 ~= "Buff") then
        -- 버프가 아니면 실행 안함
        return
    end
    local buffShowIcon = TryGetProp(buffCls, "ShowIcon", "TRUE");
    if (buffShowIcon ~= "TRUE" and buffShowIcon ~= "None") then
        -- 공개적으로 보여지는 아이콘 외 처리 안함
        return
    end
    if (BUFF_CHECK_SEPARATELIST(buffID) == true) then
        -- 중앙 버프 윈도우에 들어가는 버프 표시 안함
        return
    end
    local tooltipType = TryGetProp(buffCls, "TooltipType");
    if (tooltipType == "Premium") then
        -- 중앙 버프 윈도우에 들어가는 버프 표시 안함
        return
    end
    return 1
end

function BUFFNOTIFIER_END_DRAG(frame, ctrl)
    BuffNotifier.Settings.Position.X = BuffNotifier.frame:GetX();
    BuffNotifier.Settings.Position.Y = BuffNotifier.frame:GetY();
    BUFFNOTIFIER_SAVE_SETTINGS();
end

function BUFFNOTIFIER_SAVE_SETTINGS()
    acutil.saveJSON(BuffNotifier.SettingsFileLoc, BuffNotifier.Settings);
end