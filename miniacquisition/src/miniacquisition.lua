--dofile("../data/addon_d/miniacquisition/miniacquisition.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'miniacquisition'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local Miniacquisition = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

Miniacquisition.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

Miniacquisition.Settings = {
    Position = {
        X = 420,
        Y = 120
    }
};

Miniacquisition.Default = {
    Height = 40,
    Width = 250,
    IsVisible = 1,
    Movable = 0,
    Enabled = 0, -- Hittest
};

function MINIACQUISITION_ON_INIT(addon, frame)
    Miniacquisition.addon = addon;
    Miniacquisition.frame = frame;
    -- load settings
    if not Miniacquisition.Loaded then
        local t, err = acutil.loadJSON(Miniacquisition.SettingsFileLoc, Miniacquisition.Settings);
        if err then
        else
            Miniacquisition.Settings = t;
            Miniacquisition.Loaded = true;
        end
    end
    -- initialize frame
    Miniacquisition.SetupHook(MINIACQUISITION_ADD_SEQUENTIAL_PICKITEM, 'ADD_SEQUENTIAL_PICKITEM')
end

function MINIACQUISITION_ADD_SEQUENTIAL_PICKITEM(frame, msg, itemGuid, itemCount, class, tablekey, fromWareHouse, addMsg)
    if class.ItemType == 'Unused' then
        return
    end

    if config.GetPopupPickItem() == 1 then
        SEQUENTIALPICKITEM_openCount = SEQUENTIALPICKITEM_openCount + 1;
        local frameName = "SEQUENTIAL_PICKITEM_"..tostring(SEQUENTIALPICKITEM_openCount);

        ui.DestroyFrame(frameName);

        local frame = ui.CreateNewFrame("miniacquisition", frameName);
        if frame == nil then
            return nil;
        end
        MINIACQUISITION_ON_FRAME_INIT(frame, itemGuid, itemCount)
        frame:SetUserValue("ITEMGUID_N_COUNT",tablekey)
    end
end

function MINIACQUISITION_ON_FRAME_INIT(frame, itemGuid, itemCount)
    -- enable frame reposition through drag and move
    frame:EnableMove(Miniacquisition.Default.Movable);
    frame:EnableHitTest(Miniacquisition.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "MINIACQUISITION_END_DRAG");

    local xPos = Miniacquisition.Settings.Position.X
    local yPos = Miniacquisition.Settings.Position.Y
    if (IsJoyStickMode() == 1) then
        yPos = yPos + 90 -- raise ui a bit when joystick mode
    end
    frame:SetGravity(ui.RIGHT, ui.BOTTOM);
    frame:SetMargin(0, 0, xPos, yPos);

    -- draw the frame
    frame:SetSkinName('chat_window_2');

    frame:SetOpenScript("SEQUENTIALPICKITEM_OPEN")
    frame:SetCloseScript("SEQUENTIALPICKITEM_CLOSE")

    frame:SetAnimation("closeAnim", "sequentialpickitem_close")
    frame:SetAnimation("openAnim", "sequentialpickitem_open");

    -- set default size and visibility
    frame:Resize(Miniacquisition.Default.Width, Miniacquisition.Default.Height);

    -- controls
    local slot = frame:CreateOrGetControl("slot", "slot", 40, 40, ui.LEFT, ui.TOP, 0, 0, 0, 0);
    slot:EnableHitTest(0);
    local invItem = session.GetInvItemByGuid(itemGuid);
    imcSlot:SetItemInfo(slot, invItem, 1);
    if (itemCount > 1) then
        SET_SLOT_COUNT_TEXT(slot, itemCount);
    else
        SET_SLOT_COUNT_TEXT(slot, "");
    end

    local itemCls = GetClassByType("Item", invItem.type)

    -- 아이템 이름과 획득량 출력
    local printName	 = itemCls.Name;

    local titleText = frame:CreateOrGetControl("richtext", "name", 50, 10, 0, 0);
    titleText:SetFontName("white_16_ol");

    -- <userconfig GRADE_TEXT_FONT="{#ffffff}" NORMAL_GRADE_TEXT="{@st41b}{s14}{#ffffff}노말" MAGIC_GRADE_TEXT="{@st41b}{s14}{#0e7fe8}매직" RARE_GRADE_TEXT="{@st41b}{s14}{#a124d0}레어" UNIQUE_GRADE_TEXT="{@st41b}{s14}{#d92400}유니크" LEGEND_GRADE_TEXT="{@st41b}{s14}{#ffa800}레전드" GODDESS_GRADE_TEXT="{@st41b}{s14}{#009999}가디스" CANNOT_EQUIP_LEVEL_FONT="{#62100c}"/>
    local grade = TryGetProp(itemCls, 'ItemGrade', 0)
    if (grade > 5) then
        printName = '{#009999}' .. printName
    elseif (grade == 5) then
        printName = '{#ffa800}' .. printName
    elseif (grade == 4) then
        printName = '{#d92400}' .. printName
    elseif (grade == 3) then
        printName = '{#a124d0}' .. printName
    elseif (grade == 2) then
        printName = '{#0e7fe8}' .. printName
    elseif (grade == 1) then
    end

    titleText:SetText(printName);
    titleText:EnableHitTest(0);

    --display
    local duration = 2.5
    frame:ShowWindow(1);
    frame:SetDuration(duration);
    frame:Invalidate();
    MINIACQUISITION_ON_OPEN(frame);
end

function MINIACQUISITION_ON_OPEN(frame)
    local index = string.find(frame:GetName(), "SEQUENTIAL_PICKITEM_");
    local frameindex = string.sub(frame:GetName(), index + string.len("SEQUENTIAL_PICKITEM_"), string.len(frame:GetName()))
    local nowcount = tonumber(frameindex) - 1;
    for i = nowcount, 0, -1 do
        local beforeFrameName = "SEQUENTIAL_PICKITEM_"..tostring(i);
        local beforeframe = ui.GetFrame(beforeFrameName)
        if beforeframe == nil then
            break;
        end
        beforeframe:MoveFrame(beforeframe:GetX(), beforeframe:GetY() - 42);
        -- UI_PLAYFORCE(beforeframe, "slotsetUpMove");
    end
end

function MINIACQUISITION_END_DRAG(frame, ctrl)
    Miniacquisition.Settings.Position.X = Miniacquisition.frame:GetX();
    Miniacquisition.Settings.Position.Y = Miniacquisition.frame:GetY();
    MINIACQUISITION_SAVE_SETTINGS();
end

function MINIACQUISITION_SAVE_SETTINGS()
    acutil.saveJSON(Miniacquisition.SettingsFileLoc, Miniacquisition.Settings);
end

function Miniacquisition.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end