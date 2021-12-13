--dofile("../data/addon_d/quickjobchange/quickjobchange.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'quickjobchange'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local QuickJobChange = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

QuickJobChange.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

QuickJobChange.Settings = {
    Position = {
        X = 400,
        Y = 400
    }
};

QuickJobChange.Default = {
    Height = 0,
    Width = 0,
    IsVisible = 1,
    Movable = 1,
    Enabled = 1, -- Hittest
};

function QUICKJOBCHANGE_ON_INIT(addon, frame)
    QuickJobChange.addon = addon;
    QuickJobChange.frame = frame;
    -- load settings
    if not QuickJobChange.Loaded then
        local t, err = acutil.loadJSON(QuickJobChange.SettingsFileLoc, QuickJobChange.Settings);
        if err then
        else
            QuickJobChange.Settings = t;
            QuickJobChange.Loaded = true;
        end
    end
    -- initialize frame
    QUICKJOBCHANGE_ON_FRAME_INIT(frame)

    QuickJobChange.SetupHook(QUICKJOBCHANGE_RANKROLLBACK_CHECK_PLAYER_STATE, "RANKROLLBACK_CHECK_PLAYER_STATE")


end

function QUICKJOBCHANGE_RANKROLLBACK_CHECK_PLAYER_STATE(frame)
    QuickJobChange.RankRollbackCheckPlayerState(frame)
end

function QuickJobChange.RankRollbackCheckPlayerState(frame)
    local canChangeJob = session.CanChangeJob();
    if (canChangeJob == false) then
        ui.SysMsg(QuickJobChange:GetTranslatedString("change_unavailable"))
        return
    end
    local mapProp = session.GetCurrentMapProp()
    local mapCls = GetClassByType('Map', mapProp.type)
    local isTownMap = IS_TOWN_MAP(mapCls)
    if (isTownMap == false) then
        ui.SysMsg(QuickJobChange:GetTranslatedString("only_in_town"))
    end
    -- 매 확인
    local hawk = GET_SUMMONED_PET_HAWK();
    if (hawk ~= nil) then
        ui.SysMsg(QuickJobChange:GetTranslatedString("hawk_equipped"))
    end

    -- 펫 자동 해제
    local summonedPet = session.pet.GetSummonedPet();
    if summonedPet ~= nil then
        control.SummonPet(0,0,0)
    end

    local delay = 0.27
    local index = 1

    ui.SysMsg(QuickJobChange:GetTranslatedString("unequipping"))

    -- 장비 자동 해제
    local equipList = session.GetEquipItemList();
    for i = 0, equipList:Count() - 1 do
        local equipItem = equipList:GetEquipItemByIndex(i);
        local spotName = item.GetEquipSpotName(equipItem.equipSpot);
        if  equipItem.type  ~=  item.GetNoneItem(equipItem.equipSpot)  then
            -- 장비 해제
            ReserveScript( string.format("item.UnEquip(\"%s\")", equipItem.equipSpot) , index * delay);
            index = index + 1
        end
    end
    ReserveScript("QUICKJOBCHANGE_EXEC_BASE_FUNC()", index * delay);
end

function QUICKJOBCHANGE_EXEC_BASE_FUNC()
    local frame = ui.GetFrame("rankrollback");
    base["RANKROLLBACK_CHECK_PLAYER_STATE"](frame);
end

function QUICKJOBCHANGE_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(QuickJobChange.Default.Movable);
    frame:EnableHitTest(QuickJobChange.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "QUICKJOBCHANGE_END_DRAG");

    -- draw the frame
    frame:SetSkinName('chat_window');

    -- set default position of frame
    frame:Move(QuickJobChange.Settings.Position.X, QuickJobChange.Settings.Position.Y);
    frame:SetOffset(QuickJobChange.Settings.Position.X, QuickJobChange.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(QuickJobChange.Default.Width, QuickJobChange.Default.Height);
    frame:ShowWindow(QuickJobChange.Default.IsVisible);
end

function QUICKJOBCHANGE_END_DRAG(frame, ctrl)
    QuickJobChange.Settings.Position.X = QuickJobChange.frame:GetX();
    QuickJobChange.Settings.Position.Y = QuickJobChange.frame:GetY();
    QUICKJOBCHANGE_SAVE_SETTINGS();
end

function QUICKJOBCHANGE_SAVE_SETTINGS()
    acutil.saveJSON(QuickJobChange.SettingsFileLoc, QuickJobChange.Settings);
end

-- general utilities

QuickJobChange.Strings = {
    ["change_unavailable"] = {
        ['kr'] = "직업 변경이 불가능한 상태입니다",
        ['en'] = "You cannot change classes right now"
    },
    ["only_in_town"] = {
        ['kr'] = "마을에서만 가능합니다",
        ['en'] = "This action is only available in town"
    },
    ["hawk_equipped"] = {
        ['kr'] = "매는 배럭화면에서 해제 해야 합니다",
        ['en'] = "You must unequip your hawk at the barrack screen"
    },
    ["unequipping"] = {
        ['kr'] = "장비 착용 해제중, 잠시만 기달려주세요",
        ['en'] = "Unequipping items, please wait..."
    },
}

function QuickJobChange.GetTranslatedString(self, strName)
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

function QuickJobChange.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end