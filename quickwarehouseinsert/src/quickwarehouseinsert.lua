--dofile("../data/addon_d/quickwarehouseinsert/quickwarehouseinsert.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'quickwarehouseinsert'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local QuickWarehouseInsert = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

QuickWarehouseInsert.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

QuickWarehouseInsert.Settings = {
    Position = {
        X = 400,
        Y = 400
    }
};

QuickWarehouseInsert.Default = {
    Height = 0,
    Width = 0,
    IsVisible = 0,
    Movable = 1,
    Enabled = 1, -- Hittest
};

function QUICKWAREHOUSEINSERT_ON_INIT(addon, frame)
    QuickWarehouseInsert.addon = addon;
    QuickWarehouseInsert.frame = frame;
    -- load settings
    if not QuickWarehouseInsert.Loaded then
        local t, err = acutil.loadJSON(QuickWarehouseInsert.SettingsFileLoc, QuickWarehouseInsert.Settings);
        if err then
        else
            QuickWarehouseInsert.Settings = t;
            QuickWarehouseInsert.Loaded = true;
        end
    end
    QuickWarehouseInsert.SetupHook(QUICKWAREHOUSEINSERT_PUT_ACCOUNT_ITEM_TO_WAREHOUSE_BY_INVITEM, "PUT_ACCOUNT_ITEM_TO_WAREHOUSE_BY_INVITEM")
    -- initialize frame
    QUICKWAREHOUSEINSERT_ON_FRAME_INIT(frame)
end

local function get_exist_item_index(insertItem)
    local ret1 = false
    local ret2 = -1

    if geItemTable.IsStack(insertItem.ClassID) == 1 then
        local itemList = session.GetEtcItemList(IT_ACCOUNT_WAREHOUSE);
        local sortedGuidList = itemList:GetSortedGuidList();
        local sortedCnt = sortedGuidList:Count();

        for i = 0, sortedCnt - 1 do
            local guid = sortedGuidList:Get(i);
            local invItem = itemList:GetItemByGuid(guid)
            local invItem_obj = GetIES(invItem:GetObject());
            if insertItem.ClassID == invItem_obj.ClassID then
                ret1 = true
                ret2 = invItem.invIndex
                break
            end
        end
        return ret1, ret2
    else
        return false, -1
    end
end

function QUICKWAREHOUSEINSERT_PUT_ACCOUNT_ITEM_TO_WAREHOUSE_BY_INVITEM(frame, invItem, slot, fromFrame)
    QuickWarehouseInsert.PutAccountItemToWarehouseByInvItem(frame, invItem, slot, fromFrame)
end

function QuickWarehouseInsert.PutAccountItemToWarehouseByInvItem(frame, invItem, slot, fromFrame)
    local obj = GetIES(invItem:GetObject())
    if CHECK_EMPTYSLOT(frame, obj) == 1 then
        return
    end
    if true == invItem.isLockState then
        ui.SysMsg(ClMsg("MaterialItemIsLock"));
        return;
    end
    local itemCls = GetClassByType("Item", invItem.type);
    if itemCls.ItemType == 'Quest' then
        ui.MsgBox(ScpArgMsg("IT_ISNT_REINFORCEABLE_ITEM"));
        return;
    end
    local enableTeamTrade = TryGetProp(itemCls, "TeamTrade");
    if enableTeamTrade ~= nil and enableTeamTrade == "NO" then
        ui.SysMsg(ClMsg("ItemIsNotTradable"));
        return;
    end
    local belongingCount = TryGetProp(obj, 'BelongingCount', 0)
    if belongingCount > 0 and belongingCount >= invItem.count then
        ui.SysMsg(ClMsg("ItemIsNotTradable"));
        return;
    end
    if TryGetProp(obj, 'CharacterBelonging', 0) == 1 then
        ui.SysMsg(ClMsg("ItemIsNotTradable"));
        return;
    end
    if (keyboard.IsKeyPressed("LSHIFT") == 1) then
        if fromFrame:GetName() == "inventory" then
            local maxCnt = invItem.count;
            if belongingCount > 0 then
                maxCnt = invItem.count - obj.BelongingCount;
                if maxCnt <= 0 then
                    maxCnt = 0;
                end
            end
            -- 스택형 아이템
            if invItem.count > 1 or geItemTable.IsStack(obj.ClassID) == 1 then
                local iesId = invItem:GetIESID();
                local tempFrame = ui.GetFrame("quickwarehouseinsert");
                tempFrame:SetUserValue("ArgString", tostring(iesId));
                EXEC_PUT_ITEM_TO_ACCOUNT_WAREHOUSE(frame, maxCnt, tempFrame);
                return
            end
            -- 기간제 아이템
            if invItem.hasLifeTime == true then
                local iesId = invItem:GetIESID();
                PUT_ACCOUNT_ITEM_TO_WAREHOUSE_BY_INVITEM_MSG_YESSCP(iesId, tostring(maxCnt))
                return
            end
        end
    end
    base["PUT_ACCOUNT_ITEM_TO_WAREHOUSE_BY_INVITEM"](frame, invItem, slot, fromFrame)
end

function QUICKWAREHOUSEINSERT_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(QuickWarehouseInsert.Default.Movable);
    frame:EnableHitTest(QuickWarehouseInsert.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "QUICKWAREHOUSEINSERT_END_DRAG");

    -- draw the frame
    frame:SetSkinName('chat_window');

    -- set default position of frame
    frame:Move(QuickWarehouseInsert.Settings.Position.X, QuickWarehouseInsert.Settings.Position.Y);
    frame:SetOffset(QuickWarehouseInsert.Settings.Position.X, QuickWarehouseInsert.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(QuickWarehouseInsert.Default.Width, QuickWarehouseInsert.Default.Height);
    frame:ShowWindow(QuickWarehouseInsert.Default.IsVisible);
end

function QUICKWAREHOUSEINSERT_END_DRAG(frame, ctrl)
    QuickWarehouseInsert.Settings.Position.X = QuickWarehouseInsert.frame:GetX();
    QuickWarehouseInsert.Settings.Position.Y = QuickWarehouseInsert.frame:GetY();
    QUICKWAREHOUSEINSERT_SAVE_SETTINGS();
end

function QUICKWAREHOUSEINSERT_SAVE_SETTINGS()
    acutil.saveJSON(QuickWarehouseInsert.SettingsFileLoc, QuickWarehouseInsert.Settings);
end

-- general utilities

QuickWarehouseInsert.Strings = {
    ["string_name"] = {
        ['kr'] = "안녕 세상아",
        ['en'] = "Hello World"
    }
}

function QuickWarehouseInsert.GetTranslatedString(self, strName)
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

function QuickWarehouseInsert.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end