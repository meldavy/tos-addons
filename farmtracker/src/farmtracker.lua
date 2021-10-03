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

local trackedItems = {}

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

    -- XML 로 수정하기 귀찮아서 코드로...
    frame:Resize(frame:GetWidth(), frame:GetHeight() + 35);
    local btnReset = frame:CreateOrGetControl("button", "reset", 60, 30, ui.RIGHT, ui.BOTTOM, 0, 0, 15, 8);
    AUTO_CAST(btnReset);
    btnReset:SetText("{@sti7}{s16}Reset");
    btnReset:SetEventScript(ui.LBUTTONUP, "FARMTRACKER_RESET");
    FARMTRACKER_RESET()
end

function FARMTRACKER_RESET()
    trackedItems = {}
    FarmTracker:DrawSlots()
end

function FARMTRACKER_SAVE_SETTINGS()
    acutil.saveJSON(FarmTracker.SettingsFileLoc, FarmTracker.Settings);
end

function FARMTRACKER_TOGGLE_FRAME()
    local frame = ui.GetFrame("farmtracker");
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
    local trackerFrame = ui.GetFrame('farmtracker')
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

function FarmTracker.DrawSlots(self)
    local trackerFrame = ui.GetFrame('farmtracker')
    if (trackerFrame ~= nil and trackerFrame:IsVisible() == 1) then
        local slotset = trackerFrame:GetChild("slotset");
        AUTO_CAST(slotset);
        local col = slotset:GetCol()
        local row = slotset:GetRow()
        local max = col * row
        local index = 0;
        for itemID, count in pairs(trackedItems) do
            local item = session.GetInvItemByType(itemID);
            if (index < max) then
                local slot = slotset:GetSlotByIndex(index)
                imcSlot:SetItemInfo(slot, item, 1);
                local countStr = tostring(count)
                if (count > 9999) then
                    countStr = "{s10}" .. countStr
                end
                SET_SLOT_COUNT_TEXT(slot, countStr);
            end
            index = index + 1;
        end
        -- cleanup icons
        for i = index, slotset:GetSlotCount() - 1 do
            local slot = slotset:GetSlotByIndex(i)
            slot:ClearIcon();
            SET_SLOT_COUNT_TEXT(slot, "");
        end
    end
end