--dofile("../data/addon_d/farmtracker/farmtracker.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'farmtracker'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local FarmTracker = _G['ADDONS'][author][addonName]
local acutil = require('acutil')

FarmTracker.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

FarmTracker.Settings = {
    EnabledMaps = {},
    Position = {
        X = 500,
        Y = 500
    }
};

FarmTracker.Default = {
    Width = 438,
    Height = 137
}

local trackedItems = {}

FarmTracker.SilverID = 900011;

function FARMTRACKER_ON_INIT(addon, frame)
    FarmTracker.addon = addon;
    FarmTracker.frame = frame;

    frame:ShowWindow(0);
    acutil.slashCommand("/ft", FARMTRACKER_TOGGLE_FRAME);
    acutil.slashCommand("/farmtracker", FARMTRACKER_TOGGLE_FRAME);
    acutil.slashCommand("/파밍", FARMTRACKER_TOGGLE_FRAME);
    if not FarmTracker.Loaded then
        local t, err = acutil.loadJSON(FarmTracker.SettingsFileLoc, FarmTracker.Settings);
        if err then
        else
            FarmTracker.Settings = t;
            FarmTracker.Loaded = true;
        end
    end
    FARMTRACKER_SAVE_SETTINGS();

    acutil.setupHook(FARMTRACKER_SEQUENTIAL_PICKITEMON_MSG, 'SEQUENTIAL_PICKITEMON_MSG');
    addon:RegisterMsg('GAME_START', 'FARMTRACKER_GAME_START');

    FARMTRACKER_INIT_FRAME(frame);
end

function FARMTRACKER_GAME_START(frame)
    local mapId = session.GetMapID();
    local enabled = FarmTracker.Settings.EnabledMaps[tostring(mapId)];
    if (enabled == 1) then
        frame:ShowWindow(1);
        FarmTracker:DrawSlots()
    end
end

function FARMTRACKER_END_DRAG()
    FarmTracker.Settings.Position.X = FarmTracker.frame:GetX();
    FarmTracker.Settings.Position.Y = FarmTracker.frame:GetY();
    FARMTRACKER_SAVE_SETTINGS();
end

function FARMTRACKER_INIT_FRAME(frame)
    if (frame == nil) then
        frame = ui.GetFrame('farmtracker')
    end
    frame:EnableMove(1);
    frame:SetEventScript(ui.LBUTTONUP, "FARMTRACKER_END_DRAG");
    frame:Move(FarmTracker.Settings.Position.X, FarmTracker.Settings.Position.Y);
    frame:SetOffset(FarmTracker.Settings.Position.X, FarmTracker.Settings.Position.Y);
    frame:Resize(FarmTracker.Default.Width, FarmTracker.Default.Height);

    local titleText = frame:CreateOrGetControl("richtext", "title", 10, 10, 0, 0);
    titleText:SetFontName("white_16_ol");
    titleText:SetText("/farmtracker");
    titleText:EnableHitTest(0);

    local slotset = frame:CreateOrGetControl("slotset", "slotset", 10, 35, 0, 0);
    slotset:EnableHitTest(1);
    AUTO_CAST(slotset)
    slotset:EnablePop(0)
    slotset:EnableDrag(0)
    slotset:EnableDrop(0)
    slotset:SetSlotSize(57, 57)
    slotset:SetColRow(7, 1)
    slotset:SetSpc(2, 2)
    slotset:SetSkinName('invenslot2')
    slotset:EnableSelection(0)
    slotset:CreateSlots()

    local btnReset = frame:CreateOrGetControl("button", "reset", 60, 30, ui.RIGHT, ui.BOTTOM, 0, 0, 15, 8);
    AUTO_CAST(btnReset);
    btnReset:SetText("{@sti7}{s16}Reset");
    btnReset:SetEventScript(ui.LBUTTONUP, "FARMTRACKER_RESET");

    local itemPic = frame:CreateOrGetControl("picture", "silver", 30, 30, ui.LEFT, ui.BOTTOM, 15, 0, 0, 8);
    AUTO_CAST(itemPic)
    local silverCls = GetClassByType('Item', FarmTracker.SilverID);
    itemPic:SetImage(silverCls.Icon);
    itemPic:SetEnableStretch(1)

    local silvercount = frame:CreateOrGetControl("richtext", "silvercount", 200, 30, ui.LEFT, ui.BOTTOM, 50, 0, 0, 12);
    silvercount:SetFontName("white_16_ol");
    silvercount:SetText("0");
    silvercount:EnableHitTest(0);

    FARMTRACKER_RESET()
end

function FARMTRACKER_RESET()
    trackedItems = {}
    local frame = FarmTracker.frame

    -- reset frame size
    frame:Resize(FarmTracker.Default.Width, FarmTracker.Default.Height);

    -- reset slots and slot count
    local slotset = frame:GetChild("slotset");
    AUTO_CAST(slotset)
    slotset:RemoveAllChild();
    slotset:SetColRow(7, 1)
    slotset:CreateSlots()

    -- reset silver text
    local silvercount = frame:GetChild("silvercount");
    silvercount:SetText("0");
end

function FARMTRACKER_SAVE_SETTINGS()
    acutil.saveJSON(FarmTracker.SettingsFileLoc, FarmTracker.Settings);
end

function FARMTRACKER_TOGGLE_FRAME()
    local frame = FarmTracker.frame
    local mapId = session.GetMapID();
    local enabled = FarmTracker.Settings.EnabledMaps[tostring(mapId)];
    if (enabled == 1) then
        frame:ShowWindow(0);
        FarmTracker.Settings.EnabledMaps[tostring(mapId)] = 0
    else
        frame:ShowWindow(1);
        FarmTracker.Settings.EnabledMaps[tostring(mapId)] = 1
        FarmTracker:DrawSlots();
    end
    FARMTRACKER_SAVE_SETTINGS()
end

function FARMTRACKER_SEQUENTIAL_PICKITEMON_MSG(frame, msg, arg1, type, class)
    local trackerFrame = FarmTracker.frame
    if (trackerFrame ~= nil and trackerFrame:IsVisible() == 1) then
        if msg == 'INV_ITEM_ADD' then
            if arg1 == 'UNEQUIP' then
                SEQUENTIAL_PICKITEMON_MSG_OLD(frame, msg, arg1, type, class)
                return
            end
        elseif msg == 'INV_ITEM_IN' then
            local count = type
            local invitem = session.GetInvItemByGuid(arg1);

            local itemID = invitem.type
            if (trackedItems[itemID] ~= nil) then
                trackedItems[itemID] = trackedItems[itemID] + count
            else
                trackedItems[itemID] = count
            end
        end
    end
    FarmTracker:DrawSlots()
    SEQUENTIAL_PICKITEMON_MSG_OLD(frame, msg, arg1, type, class)
end

function FarmTracker.ExpandRow(self)
    local frame = FarmTracker.frame
    local slotset = frame:GetChild("slotset");
    AUTO_CAST(slotset);
    slotset:ExpandRow();
    frame:Resize(frame:GetWidth(), frame:GetHeight() + 59);
    slotset:CreateSlots();
end

function FarmTracker.DrawSlots(self)
    local frame = FarmTracker.frame
    if (frame ~= nil and frame:IsVisible() == 1) then
        local slotset = frame:GetChild("slotset");
        AUTO_CAST(slotset);
        local index = 0;
        for itemID, count in pairs(trackedItems) do
            if (itemID == FarmTracker.SilverID) then
                -- do nothing
            else
                if (index >= slotset:GetSlotCount() - 1) then
                    FarmTracker:ExpandRow()
                end
                local availableCount = slotset:GetSlotCount();
                if (index >= availableCount) then
                    slotset:ExpandRow();
                    frame:Resize(frame:GetWidth(), frame:GetHeight() + 59);
                end
                local slot = slotset:GetSlotByIndex(index)
                local item = session.GetInvItemByType(itemID);
                if (item ~= nil) then
                    imcSlot:SetItemInfo(slot, item, 1);
                else
                    slot:ClearIcon();
                    local itemCls = GetClassByType('Item', itemID);
                    imcSlot:SetImage(slot, itemCls.Icon);
                    local icon = slot:GetIcon();
                    icon:SetTooltipType("wholeitem");
                    icon:SetTooltipArg("", itemID, 0);
                end
                local countStr = tostring(count)
                if (count > 99999) then
                    countStr = "{s12}" .. countStr
                end
                slot:SetEventScript(ui.LBUTTONDOWN, "FARMTRACKER_ON_SLOT_CLICK");
                slot:SetEventScriptArgNumber(ui.LBUTTONDOWN, itemID);
                SET_SLOT_COUNT_TEXT(slot, countStr);
                index = index + 1;
            end
        end
        -- cleanup icons
        for i = index, slotset:GetSlotCount() - 1 do
            local slot = slotset:GetSlotByIndex(i)
            slot:ClearIcon();
            slot:SetEventScriptArgNumber(ui.LBUTTONDOWN, nil);
            SET_SLOT_COUNT_TEXT(slot, "");
        end
        -- draw silver
        local invsilver = 0;
        if (trackedItems[FarmTracker.SilverID] ~= nil) then
            invsilver = trackedItems[FarmTracker.SilverID]
        end
        local silvercount = frame:GetChild("silvercount");
        silvercount:SetText(FarmTracker:FormatNumber(invsilver));
    end
end

function FARMTRACKER_ON_SLOT_CLICK(frame, ctrl, argStr, itemID)
    if (itemID ~= nil) then
        if keyboard.IsKeyPressed("LCTRL") == 1 then
            local invitem = session.GetInvItemByType(itemID);
            if (invitem ~= nil) then
                LINK_ITEM_TEXT(invitem);
            else
                ui.MsgBox("해당 아이템이 인벤토리에 없어 링크가 불가능합니다.")
            end
        end
    end
end

function FarmTracker.FormatNumber(self, i)
    return tostring(i):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end