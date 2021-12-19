--dofile("../data/addon_d/quickcardenhance/quickcardenhance.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'quickcardenhance'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local QuickCardEnhance = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

QuickCardEnhance.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

QuickCardEnhance.Settings = {
    Position = {
        X = 400,
        Y = 400
    }
};

QuickCardEnhance.Default = {
    Height = 0,
    Width = 0,
    IsVisible = 1,
    Movable = 1,
    Enabled = 1, -- Hittest
};

QuickCardEnhance.EXPCardTypes = {
    [641821] = 1,
    [641822] = 1,
    [10003222] = 1,
    [10003338] = 1,
    [10003174] = 1,
    [10003303] = 1,
    [10003352] = 1,
    [10003413] = 1,
    [10003432] = 1,
    [10003547] = 1,
    [904220] = 1,
}

function QUICKCARDENHANCE_ON_INIT(addon, frame)
    QuickCardEnhance.addon = addon;
    QuickCardEnhance.frame = frame;
    -- load settings
    if not QuickCardEnhance.Loaded then
        local t, err = acutil.loadJSON(QuickCardEnhance.SettingsFileLoc, QuickCardEnhance.Settings);
        if err then
        else
            QuickCardEnhance.Settings = t;
            QuickCardEnhance.Loaded = true;
        end
    end
    -- initialize frame
    QUICKCARDENHANCE_ON_FRAME_INIT(frame)

    QuickCardEnhance.SetupHook(QUICKCARDENHANCE_INVENTORY_RBDC_ITEMUSE, 'INVENTORY_RBDC_ITEMUSE');
end

function QUICKCARDENHANCE_INVENTORY_RBDC_ITEMUSE(frame, object, argStr, argNum)
    QuickCardEnhance.InventoryRBDCItemUse(frame, object, argStr, argNum)
end

function QuickCardEnhance.InventoryRBDCItemUse(frame, object, argStr, argNum)
    local reinforceFrame = ui.GetFrame("reinforce_by_mix");
    if (reinforceFrame ~= nil and reinforceFrame:IsVisible() == 1) then
        -- 이미 인던창이 열려있다면 아이템 사용
        base["INVENTORY_RBDC_ITEMUSE"](frame, object, argStr, argNum)
        return;
    end
    local warehouseFrame = ui.GetFrame("accountwarehouse");
    if (warehouseFrame ~= nil and warehouseFrame:IsVisible() == 1) then
        -- 이미 인던창이 열려있다면 아이템 사용
        base["INVENTORY_RBDC_ITEMUSE"](frame, object, argStr, argNum)
        return;
    end
    local cardFrame = ui.GetFrame("monstercardslot");
    if (cardFrame ~= nil and cardFrame:IsVisible() == 1) then
        -- 이미 인던창이 열려있다면 아이템 사용
        base["INVENTORY_RBDC_ITEMUSE"](frame, object, argStr, argNum)
        return;
    end


    local invItem = GET_SLOT_ITEM(object);
    if ((invItem ~= nil) and (keyboard.IsKeyPressed("LSHIFT") == 1)) then
        local obj = GetIES(invItem:GetObject());
        if (obj.Reinforce_Type == "Card") then
            local lv, curExp, maxExp = GET_ITEM_LEVEL_EXP(obj);
            if lv > 1 and maxExp == 0 then
                ui.SysMsg(ClMsg("CanNotEnchantMore"));
                return;
            elseif maxExp == 0 then
                ui.SysMsg(ClMsg("ThisGemCantReinforce"));
                return;
            end

            session.ResetItemList();
            session.AddItemID(invItem:GetIESID());

            local matItem = nil
            for k, v in pairs(QuickCardEnhance.EXPCardTypes) do
                local item = session.GetInvItemByType(k);
                if (item ~= nil) then
                    matItem = item
                    break
                end
            end
            if (matItem ~= nil) then
                session.AddItemID(matItem:GetIESID(), 1)
                local resultlist = session.GetItemIDList();
                if resultlist:Count() > 1 then
                    --SetCraftState(1);
                    --ui.SetHoldUI(true);
                    item.DialogTransaction("SCR_ITEM_EXP_UP", resultlist);
                    return;
                end
            else
                ui.SysMsg(QuickCardEnhance:GetTranslatedString("no_enhance_card_in_inv"))
            end
        end
    end
    base["INVENTORY_RBDC_ITEMUSE"](frame, object, argStr, argNum)
end

function QUICKCARDENHANCE_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(QuickCardEnhance.Default.Movable);
    frame:EnableHitTest(QuickCardEnhance.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "QUICKCARDENHANCE_END_DRAG");

    -- draw the frame
    frame:SetSkinName('chat_window');

    -- set default position of frame
    frame:Move(QuickCardEnhance.Settings.Position.X, QuickCardEnhance.Settings.Position.Y);
    frame:SetOffset(QuickCardEnhance.Settings.Position.X, QuickCardEnhance.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(QuickCardEnhance.Default.Width, QuickCardEnhance.Default.Height);
    frame:ShowWindow(QuickCardEnhance.Default.IsVisible);
end

function QUICKCARDENHANCE_END_DRAG(frame, ctrl)
    QuickCardEnhance.Settings.Position.X = QuickCardEnhance.frame:GetX();
    QuickCardEnhance.Settings.Position.Y = QuickCardEnhance.frame:GetY();
    QUICKCARDENHANCE_SAVE_SETTINGS();
end

function QUICKCARDENHANCE_SAVE_SETTINGS()
    acutil.saveJSON(QuickCardEnhance.SettingsFileLoc, QuickCardEnhance.Settings);
end

-- general utilities

QuickCardEnhance.Strings = {
    ["no_enhance_card_in_inv"] = {
        ['kr'] = "인벤에 Lv10 강화용 카드가 없습니다",
        ['en'] = "You do not have a lv 10 enhance card in your inventory"
    }
}

function QuickCardEnhance.GetTranslatedString(self, strName)
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

function QuickCardEnhance.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end