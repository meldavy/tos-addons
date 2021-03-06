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
        X = 1050,
        Y = 550
    },
    Visible = 1,
    Blacklist = {
    }
};

BuffNotifier.DefaultBlacklist = {
    ["4397"] = "hide",  -- 집방
    ["40023"] = "hide", -- 주오다
    ["4417"] = "hide",  -- 카랄 주오다
    ["3171"] = "hide",  -- 천벌
    ["3023"] = "hide",  -- 힐
    ["310"] = "hide",   -- 힐
    ["3020"] = "hide",  -- 리스토레이션
};

BuffNotifier.Default = {
    Height = 40,
    Width = 230,
    IsVisible = 0,
    Movable = 1,
    Enabled = 1, -- Hittest
};

BuffNotifier.addedbuffcount = 0;
BuffNotifier.alreadyDisplayedIndex = {};
BuffNotifier.buffLock = {};
BuffNotifier.buffBalancer = {};
BuffNotifier.removedbuffcount = 0;
BuffNotifier.enabled = false;

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
    if (BuffNotifier.Settings.Blacklist == nil) then
        BuffNotifier.Settings.Blacklist = {}
    end
    BUFFNOTIFIER_SAVE_SETTINGS()
    BuffNotifier.removedbuffcount = 0;
    BuffNotifier.addedbuffcount = 0;
    BuffNotifier.alreadyDisplayedIndex = {};
    BuffNotifier.buffLock = {};
    BuffNotifier.buffBalancer = {};
    BuffNotifier.enabled = false;
    addon:RegisterMsg('BUFF_ADD', 'BUFFNOTIFIER_ON_BUFF_ADD');
    addon:RegisterMsg('BUFF_REMOVE', 'BUFFNOTIFIER_ON_BUFF_REMOVE');
    -- 맵이동시 첫 3초동안엔 비활성화 합니다. 안그러면 밥차, 기본버프, 등등이 자꾸 떠요
    addon:RegisterMsg('GAME_START_3SEC', 'BUFFNOTIFIER_ON_GAME_START');

    acutil.slashCommand('/bn', BUFFNOTIFIER_PROCESS_COMMAND)
    acutil.slashCommand('/buffnotifier', BUFFNOTIFIER_PROCESS_COMMAND)

    BUFFNOTIFIER_INIT_POSITION_HANDLE(frame)
end

function BUFFNOTIFIER_PROCESS_COMMAND(command)
    local cmd = '';
    if #command > 0 then
        cmd = table.remove(command, 1);
    end
    if cmd == '' then
        local frame = ui.GetFrame('buffnotifier')
        local visible = BuffNotifier.Settings.Visible;
        if (visible == 1) then
            frame:ShowWindow(0);
            BuffNotifier.Settings.Visible = 0
        else
            frame:ShowWindow(1);
            BuffNotifier.Settings.Visible = 1
        end
        BUFFNOTIFIER_SAVE_SETTINGS();
    end
    if cmd == 'hide' then
        local id = table.remove(command, 1);
        BuffNotifier.Settings.Blacklist[id] = "hide"
        BUFFNOTIFIER_SAVE_SETTINGS();
    elseif cmd == 'unhide' then
        local id = table.remove(command, 1);
        BuffNotifier.Settings.Blacklist[id] = nil
        BUFFNOTIFIER_SAVE_SETTINGS();
    end
end

function BUFFNOTIFIER_INIT_POSITION_HANDLE(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(BuffNotifier.Default.Movable);
    frame:EnableHitTest(BuffNotifier.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "BUFFNOTIFIER_END_DRAG");

    -- show frame
    local xPos = BuffNotifier.Settings.Position.X
    local yPos = BuffNotifier.Settings.Position.Y
    frame:Move(xPos, yPos);
    frame:SetOffset(xPos, yPos);

    -- draw the frame
    frame:SetSkinName('None');

    -- set default size and visibility
    frame:Resize(40, 40);

    -- controls
    local icon = frame:CreateOrGetControl("picture", "icon", 36, 36, ui.LEFT, ui.BOTTOM, 0, 0, 0, 0);
    local buffCls = GetClassByType('Buff', 620040);
    AUTO_CAST(icon)
    icon:SetImage("icon_" .. buffCls.Icon);
    icon:SetEnableStretch(1)
    icon:EnableHitTest(0)
    icon:SetColorTone("99FFFFFF")

    local tooltipicon = frame:CreateOrGetControl("picture", "tooltipicon", 20, 20, ui.RIGHT, ui.TOP, 0, 0, 0, 0);
    AUTO_CAST(tooltipicon)
    tooltipicon:SetImage("button_chat_scale");
    tooltipicon:SetEnableStretch(1)
    tooltipicon:EnableHitTest(1)

    -- tooltip
    tooltipicon:SetTextTooltip("드래그 하여 이동 후 /buffnotifier로 숨김");

    --display
    frame:SetLayerLevel(10);
    frame:ShowWindow(BuffNotifier.Settings.Visible);
end

function BUFFNOTIFIER_ON_GAME_START(frame)
    local handle = session.GetMyHandle()
    local buffCount = info.GetBuffCount(handle);
    for i = 0, buffCount - 1 do
        local buff = info.GetBuffIndexed(handle, i);
        if buff ~= nil then
            BuffNotifier.alreadyDisplayedIndex["REMOVE" .. buff.index] = 1
            BuffNotifier.buffBalancer[buff.buffID] = 1
        end
    end
    BuffNotifier.enabled = true;
end

function BUFFNOTIFIER_ON_BUFF_ADD(frame, msg, buffIndex, buffID)
    if (BuffNotifier.enabled ~= true) then
        return
    end
    local buffCls = GetClassByType('Buff', buffID);
    -- 표시 할 버프만 보여줌
    if (BuffNotifier:FilterBuff(buffCls) ~= 1) then
        return
    end
    if (BuffNotifier.buffBalancer[buffID] ~= nil) then
        -- this is most likely a redraw of an existing buff, we dont' display it.
        return
    end

    local key = "ADD" .. buffIndex
    if BuffNotifier.alreadyDisplayedIndex[key] == nil then
        -- 중복으로 안보이게
        BuffNotifier.alreadyDisplayedIndex[key] = 1

        if (BuffNotifier.buffLock[buffID] == nil) then
            BuffNotifier.buffLock[buffID] = 0
        end
        BuffNotifier.buffLock[buffID] = BuffNotifier.buffLock[buffID] + 1
        -- add
        ReserveScript(string.format("BUFFNOTIFIER_DELAYED_BUFF_ADD(%d)", buffID), 0.03)
    end
end

function BUFFNOTIFIER_DELAYED_BUFF_ADD(buffID)
    if (BuffNotifier.buffLock[buffID] == 1) then
        local handle = session.GetMyHandle()
        local addedBuff = info.GetBuff(handle, buffID);
        if (addedBuff ~= nil) then
            local buffCls = GetClassByType('Buff', buffID);
            BuffNotifier.addedbuffcount = BuffNotifier.addedbuffcount + 1;
            local frameName = "BUFFNOTIFIER_ADD_"..BuffNotifier.addedbuffcount;
            ui.DestroyFrame(frameName);
            local frame = ui.CreateNewFrame("buffnotifier", frameName);
            BUFFNOTIFIER_ON_FRAME_INIT(frame, buffCls, 1)
            BUFFNOTIFIER_BUFF_ADD_OPEN(frame);
        end
        BuffNotifier.buffLock[buffID] = BuffNotifier.buffLock[buffID] - 1
    end
end

function BUFFNOTIFIER_BUFF_ADD_OPEN(frame)
    BuffNotifier:PushBuff(frame, "BUFFNOTIFIER_ADD_", -42);
end

function BUFFNOTIFIER_ON_BUFF_REMOVE(frame, msg, buffIndex, buffID)
    if (BuffNotifier.enabled ~= true) then
        return
    end
    local buffCls = GetClassByType('Buff', buffID);
    -- 표시 할 버프만 보여줌
    if (BuffNotifier:FilterBuff(buffCls) ~= 1) then
        return
    end

    BuffNotifier.buffBalancer[buffID] = nil

    local key = "REMOVE" .. buffIndex
    if BuffNotifier.alreadyDisplayedIndex[key] == nil then
        -- 중복으로 안보이게
        BuffNotifier.alreadyDisplayedIndex[key] = 1

        if (BuffNotifier.buffLock[buffID] == nil) then
            BuffNotifier.buffLock[buffID] = 0
        end
        BuffNotifier.buffLock[buffID] = BuffNotifier.buffLock[buffID] - 1
        -- remove
        ReserveScript(string.format("BUFFNOTIFIER_DELAYED_BUFF_REMOVE(%d)", buffID), 0.03)
    end
end

function BUFFNOTIFIER_DELAYED_BUFF_REMOVE(buffID)
    local buffFrame = ui.GetFrame('buff')
    if (buffFrame == nil or buffFrame:IsVisible() == 0) then
        return
    end
    if (BuffNotifier.buffLock[buffID] == -1) then
        -- 분명 REMOVE 이벤트인데 REMOVE 가 발생 안하는 경우가 있음... 망겜
        local handle = session.GetMyHandle()
        local removedBuff = info.GetBuff(handle, buffID);
        if (removedBuff == nil) then
            local buffCls = GetClassByType('Buff', buffID);
            BuffNotifier.removedbuffcount = BuffNotifier.removedbuffcount + 1;
            local frameName = "BUFFNOTIFIER_REMOVE_"..BuffNotifier.removedbuffcount;
            ui.DestroyFrame(frameName);
            local frame = ui.CreateNewFrame("buffnotifier", frameName);
            BUFFNOTIFIER_ON_FRAME_INIT(frame, buffCls, 0)
            BUFFNOTIFIER_BUFF_REMOVE_OPEN(frame);
        end
        BuffNotifier.buffLock[buffID] = BuffNotifier.buffLock[buffID] + 1
    end
end

function BUFFNOTIFIER_BUFF_REMOVE_OPEN(frame)
    BuffNotifier:PushBuff(frame, "BUFFNOTIFIER_REMOVE_", 42);
end

function BUFFNOTIFIER_CLOSE(frame)
    local key = frame:GetUserValue("buffID")
    ui.DestroyFrame(frame:GetName());
end

function BUFFNOTIFIER_ON_FRAME_INIT(frame, buffCls, type)
    -- enable frame reposition through drag and move
    frame:EnableMove(0);
    frame:EnableHitTest(0);

    -- show frame relative to center screen
    local screenWidth = ui.GetSceneWidth();
    local xPos = BuffNotifier.Settings.Position.X + 45
    local yPos = BuffNotifier.Settings.Position.Y - 20
    if (type == 0) then
        yPos = yPos + 40
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
    if (BuffNotifier.Settings.Blacklist[tostring(buffID)] ~= nil) then
        return
    end
    if (BuffNotifier.DefaultBlacklist[tostring(buffID)] ~= nil) then
        return
    end
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
    --if (BUFF_CHECK_SEPARATELIST(buffID) == true) then
    --    -- 중앙 버프 윈도우에 들어가는 버프 표시 안함
    --    return
    --end
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