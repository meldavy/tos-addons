--dofile("../data/addon_d/quickdigest/quickdigest.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'quickdigest'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local QuickDigest = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

QuickDigest.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

QuickDigest.Settings = {
    Position = {
        X = 400,
        Y = 400
    }
};

QuickDigest.Default = {
    Height = 0,
    Width = 0,
    IsVisible = 1,
    Movable = 1,
    Enabled = 1, -- Hittest
};

QuickDigest.SquireBuffs = {
    [1] = 4022, -- sandwich
    [2] = 4023, -- soup
    [3] = 4024, -- yogurt
    [4] = 4021, -- salad
    [5] = 4087, -- BBQ
    [6] = 4136, -- champagne
}

function QUICKDIGEST_ON_INIT(addon, frame)
    QuickDigest.addon = addon;
    QuickDigest.frame = frame;
    -- load settings
    if not QuickDigest.Loaded then
        local t, err = acutil.loadJSON(QuickDigest.SettingsFileLoc, QuickDigest.Settings);
        if err then
        else
            QuickDigest.Settings = t;
            QuickDigest.Loaded = true;
        end
    end
    -- initialize frame
    QUICKDIGEST_ON_FRAME_INIT(frame)
    -- addon:RegisterMsg("OPEN_FOOD_TABLE_UI", "QUICKDIGEST_OPEN_FOOD_TABLE_UI")
    QuickDigest.SetupHook(QUICKDIGEST_ON_EAT_FOOD, "EAT_FOODTABLE")
end

function QUICKDIGEST_ON_EAT_FOOD(parent, ctrl)
    QuickDigest.EatFoodtable(parent, ctrl)
end

function QuickDigest.EatFoodtable(parent, ctrl)
    local frame = parent:GetTopParentFrame();
    if (frame == nil) then
        return
    end
    local groupName = frame:GetUserValue("GroupName");
    local index = parent:GetUserIValue("INDEX");
    local sellType = frame:GetUserIValue("SELLTYPE");
    local handle = frame:GetUserIValue("HANDLE");
    local foodItem = session.autoSeller.GetByIndex(groupName, index);
    if foodItem ~= nil and foodItem.remainCount > 0 then
        local cls = GetClassByType("FoodTable", foodItem.classID);
        local buffType = QuickDigest.SquireBuffs[foodItem.classID]
        local buff = info.GetBuff(session.GetMyHandle(), buffType)
        if (buff ~= nil) then
            packet.ReqRemoveBuff(buffType);
        end
        ReserveScript(string.format("QUICKDIGEST_BUY_FOOD(%d, %d, %d)", handle, index, sellType), 0.07)
    end
end

function QUICKDIGEST_BUY_FOOD(handle, index, sellType)
    session.autoSeller.Buy(handle, index, 1, sellType);
end

function QUICKDIGEST_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(QuickDigest.Default.Movable);
    frame:EnableHitTest(QuickDigest.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "QUICKDIGEST_END_DRAG");

    -- draw the frame
    frame:SetSkinName('chat_window');

    -- set default position of frame
    frame:Move(QuickDigest.Settings.Position.X, QuickDigest.Settings.Position.Y);
    frame:SetOffset(QuickDigest.Settings.Position.X, QuickDigest.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(QuickDigest.Default.Width, QuickDigest.Default.Height);
    frame:ShowWindow(QuickDigest.Default.IsVisible);
end

function QUICKDIGEST_END_DRAG(frame, ctrl)
    QuickDigest.Settings.Position.X = QuickDigest.frame:GetX();
    QuickDigest.Settings.Position.Y = QuickDigest.frame:GetY();
    QUICKDIGEST_SAVE_SETTINGS();
end

function QUICKDIGEST_SAVE_SETTINGS()
    acutil.saveJSON(QuickDigest.SettingsFileLoc, QuickDigest.Settings);
end

-- general utilities

QuickDigest.Strings = {
    ["string_name"] = {
        ['kr'] = "안녕 세상아",
        ['en'] = "Hello World"
    }
}

function QuickDigest.GetTranslatedString(self, strName)
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

function QuickDigest.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end