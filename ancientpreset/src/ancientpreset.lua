--dofile("../data/addon_d/ancientpreset/ancientpreset.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'ancientpreset'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local AncientPreset = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

AncientPreset.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

AncientPreset.Settings = {
    Position = {
        X = 900,
        Y = 100
    },
    Presets = {}
};

AncientPreset.Default = {
    Height = 400,
    Width = 707,
    IsVisible = 0,
    Movable = 1,
    Enabled = 1, -- Hittest
};

function ANCIENTPRESET_ON_INIT(addon, frame)
    AncientPreset.addon = addon;
    AncientPreset.frame = frame;
    -- load settings
    if not AncientPreset.Loaded then
        local t, err = acutil.loadJSON(AncientPreset.SettingsFileLoc);
        if err then
        else
            for k, v in pairs(t) do
                if (AncientPreset.Settings.Presets[tonumber(k)] == nil) then
                    AncientPreset.Settings.Presets[tonumber(k)] = {}
                end
                if (v ~= nil) then
                    for k2, v2 in pairs(v) do
                        AncientPreset.Settings.Presets[tonumber(k)][tonumber(k2)] = v2
                    end
                end
            end
            AncientPreset.Loaded = true;
        end
    end
    ANCIENTPRESET_SAVE_SETTINGS()
    -- initialize frame

    AncientPreset.SetupHook(ANCIENTPRESET_OPEN, "ANCIENT_CARD_LIST_OPEN")
    AncientPreset.SetupHook(ANCIENTPRESET_CLOSE, "ANCIENT_CARD_LIST_CLOSE")

    ANCIENTPRESET_ON_FRAME_INIT(frame)
    ANCIENTPRESET_ON_TAB_CHANGE(frame)
end


function ANCIENTPRESET_REMOVE_CARD_IN_SLOT(slotIndex)
    local card = session.ancient.GetAncientCardBySlot(slotIndex)
    if (card ~= nil) then
        local emptySlot = ANCIENT_CARD_GET_EMPTY_SLOT(4)
        ReqSwapAncientCard(card:GetGuid(), emptySlot)
    end
end

function ANCIENTPRESET_PUT_CARD_IN_SLOT(slotIndex)
    local frame = AncientPreset.frame
    local tab = frame:GetChild("tab")
    AUTO_CAST(tab)
    local tabIndex = tab:GetSelectItemIndex();
    if (AncientPreset.Settings.Presets[tabIndex] ~= nil) then
        if (AncientPreset.Settings.Presets[tabIndex][slotIndex] ~= nil) then
            local guid = AncientPreset.Settings.Presets[tabIndex][slotIndex]
            if (guid ~= nil) then
                local card = session.ancient.GetAncientCardByGuid(guid)
                if (card ~= nil) then
                    ReqSwapAncientCard(card:GetGuid(), slotIndex)
                end
            end
        else
            local card = session.ancient.GetAncientCardBySlot(slotIndex)
            if (card ~= nil) then
                local emptySlot = ANCIENT_CARD_GET_EMPTY_SLOT(4)
                ReqSwapAncientCard(card:GetGuid(), emptySlot)
            end
        end
    end
end

function ANCIENTPRESET_ON_SWAP_CLICK(parent, ctrl)
    if IS_ANCIENT_ENABLE_MAP() == "YES" then
        addon.BroadMsg("NOTICE_Dm_!", ClMsg("ImpossibleInCurrentMap"), 3);
        return
    end
    -- local frame = ui.GetFrame("ancient_card_list")

    local frame = parent:GetTopParentFrame();
    local tab = frame:GetChild("tab")
    AUTO_CAST(tab)
    local tabIndex = tab:GetSelectItemIndex();

    local operationCount = 0
    for index = 0, 3 do
        local equippedCard = session.ancient.GetAncientCardBySlot(index)
        if (equippedCard ~= nil) then
            ReserveScript(string.format("ANCIENTPRESET_REMOVE_CARD_IN_SLOT(%d)", index), 0.2 * operationCount)
            operationCount = operationCount + 1
        end
    end
    for index = 0, 3 do
        if (AncientPreset.Settings.Presets[tabIndex] == nil) then
            AncientPreset.Settings.Presets[tabIndex] = {}
        end
        local guid = AncientPreset.Settings.Presets[tabIndex][index]
        if (guid ~= nil) then
            local card = session.ancient.GetAncientCardByGuid(guid)
            if (card == nil) then
                -- if guid points to a card no longer available, we invalidate it
                AncientPreset.Settings.Presets[tabIndex][index] = nil
            end
        end
        ReserveScript(string.format("ANCIENTPRESET_PUT_CARD_IN_SLOT(%d)", index), 0.2 * (index + operationCount))
    end
end

function ANCIENTPRESET_ON_TAB_CHANGE(parent, ctrl)
    local frame = parent:GetTopParentFrame();
    local tab = frame:GetChild("tab")
    AUTO_CAST(tab)
    local index = tab:GetSelectItemIndex();
    ANCIENTPRESET_LOAD_SLOTS_BY_INDEX(frame, index)
end

function ANCIENTPRESET_LOAD_SLOTS_BY_INDEX(frame, tabIndex)
    local gbox =  GET_CHILD_RECURSIVELY(frame,'ancient_card_slot_Gbox')
    gbox:RemoveAllChild()
    local width = 4
    for index = 0, 3 do
        local ctrlSet = gbox:CreateControlSet("ancient_card_item_slot", "SLOT_"..index, width, 4);
        width = width + ctrlSet:GetWidth() + 2
        local ancient_card_gbox = GET_CHILD_RECURSIVELY(ctrlSet,"ancient_card_gbox")
        ancient_card_gbox:SetVisible(0)
        ctrlSet:SetUserValue("INDEX",index)
        ctrlSet:EnableHitTest(1)
        local slot = GET_CHILD_RECURSIVELY(ctrlSet,"ancient_card_slot")
        AUTO_CAST(slot)
        local icon = CreateIcon(slot);
        slot:EnableHitTest(1)
        ctrlSet:SetEventScript(ui.DROP, 'ANCIENTPRESET_CARD_SWAP_ON_DROP');
        ctrlSet:SetEventScript(ui.RBUTTONDOWN, 'ANCIENTPRESET_CARD_SWAP_RBTNDOWN');
        ctrlSet:SetEventScriptArgNumber(ui.RBUTTONDOWN, -1);
        if index == 0 then
            local gold_border = GET_CHILD_RECURSIVELY(ctrlSet,"gold_border")
            AUTO_CAST(gold_border)
            gold_border:SetImage('monster_card_g_frame_02')
        end

        if (AncientPreset.Settings.Presets[tabIndex] ~= nil) then
            if (AncientPreset.Settings.Presets[tabIndex][index] ~= nil) then
                local guid = AncientPreset.Settings.Presets[tabIndex][index]
                if (guid ~= nil) then
                    local card = session.ancient.GetAncientCardByGuid(guid)
                    if (card ~= nil) then
                        SET_ANCIENT_CARD_SLOT(ctrlSet, card)
                    end
                end
            end
        end
        local default_image = GET_CHILD_RECURSIVELY(ctrlSet,"default_image")
        AUTO_CAST(default_image)
        default_image:SetImage("socket_slot_bg")
    end
end

function ANCIENTPRESET_CARD_SWAP_RBTNDOWN(parent,ctrlSet,argStr,argNum)
    local toIndex = tonumber(ctrlSet:GetUserValue("INDEX"))
    local frame = parent:GetTopParentFrame();
    local tab = frame:GetChild("tab")
    AUTO_CAST(tab)
    local tabIndex = tab:GetSelectItemIndex();
    if (AncientPreset.Settings.Presets[tabIndex] == nil) then
        AncientPreset.Settings.Presets[tabIndex] = {}
    end
    AncientPreset.Settings.Presets[tabIndex][toIndex] = nil
    ANCIENTPRESET_SAVE_SETTINGS()
    ANCIENTPRESET_ON_TAB_CHANGE(frame) -- redraw
end

function ANCIENTPRESET_CARD_SWAP_ON_DROP(parent,toCtrlSet, argStr, argNum)
    local toIndex = tonumber(toCtrlSet:GetUserValue("INDEX"))
    local ancientFrame = ui.GetFrame("ancient_card_list")

    local frame = parent:GetTopParentFrame();
    local tab = frame:GetChild("tab")
    AUTO_CAST(tab)
    local tabIndex = tab:GetSelectItemIndex();

    local guid = ancientFrame:GetUserValue("LIFTED_GUID")
    if guid == "None" or guid == nil or tonumber == nil then
        guid = frame:GetUserValue("LIFTED_GUID")
        if guid == "None" or guid == nil or tonumber == nil then
            return;
        end
    end
    local card = session.ancient.GetAncientCardByGuid(guid)
    if card == nil then
        return;
    end
    if (AncientPreset.Settings.Presets[tabIndex] == nil) then
        AncientPreset.Settings.Presets[tabIndex] = {}
    end
    local prevIndex = -1
    for slotIndex = 0, 3 do
        if (AncientPreset.Settings.Presets[tabIndex][slotIndex] == guid) then
            prevIndex = slotIndex
            AncientPreset.Settings.Presets[tabIndex][slotIndex] = nil
        end
    end
    if (AncientPreset.Settings.Presets[tabIndex][toIndex] ~= nil) then
        if (prevIndex > -1) then
            AncientPreset.Settings.Presets[tabIndex][prevIndex] = AncientPreset.Settings.Presets[tabIndex][toIndex]
        end
    end
    AncientPreset.Settings.Presets[tabIndex][toIndex] = guid
    ANCIENTPRESET_SAVE_SETTINGS()
    ANCIENTPRESET_ON_TAB_CHANGE(frame) -- redraw
    ancientFrame:SetUserValue("LIFTED_GUID","None")
    frame:SetUserValue("LIFTED_GUID","None")
end

function ANCIENTPRESET_OPEN(frame)
    AncientPreset.AncientPresetOpen(frame)
end

function AncientPreset.AncientPresetOpen(frame)
    ANCIENTPRESET_ON_TAB_CHANGE(AncientPreset.frame)
    AncientPreset.frame:ShowWindow(1)
    base["ANCIENT_CARD_LIST_OPEN"](frame)
end

function ANCIENTPRESET_CLOSE(frame)
    AncientPreset.AncientPresetClose(frame)
end

function AncientPreset.AncientPresetClose(frame)
    AncientPreset.frame:ShowWindow(0)
    base["ANCIENT_CARD_LIST_CLOSE"](frame)
end

function ANCIENTPRESET_CLOSE_FRAME(frame)
    ui.CloseFrame('ancientpreset')
end

function ANCIENTPRESET_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(AncientPreset.Default.Movable);
    frame:EnableHitTest(AncientPreset.Default.Enabled);
    frame:SetLayerLevel(82); -- 1 higher than ancient_card_list
    -- draw the frame
    frame:SetSkinName('None');

    -- set default position of frame
    frame:Move(AncientPreset.Settings.Position.X, AncientPreset.Settings.Position.Y);
    frame:SetOffset(AncientPreset.Settings.Position.X, AncientPreset.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(AncientPreset.Default.Width, AncientPreset.Default.Height);
    frame:ShowWindow(AncientPreset.Default.IsVisible);

    frame:SetAnimation("frameOpenAnim", "chat_balloon_start")
    frame:SetAnimation("frameCloseAnim", "chat_balloon_end");

    local bg = frame:CreateOrGetControl("groupbox", "bg", 705, 360, ui.LEFT, ui.TOP, 0, 40, 0, 0);
    AUTO_CAST(bg)
    bg:SetSkinName("test_frame_low")
    bg:EnableHittestGroupBox(false)

    local title_bg = frame:CreateOrGetControl("groupbox", "title_bg", 705, 61, ui.LEFT, ui.TOP, 0, 0, 0, 0);
    AUTO_CAST(title_bg)
    title_bg:SetSkinName("test_frame_top")
    title_bg:EnableHittestGroupBox(false)

    local title = frame:CreateOrGetControl("richtext", "title", 100, 30, ui.CENTER_HORZ, ui.TOP, 0, 18, 0, 0);
    title:SetText("{@st43}{s22}어시스터 프리셋{/}")
    title:EnableHitTest(false)

    local close = frame:CreateOrGetControl("button", "close", 44, 44, ui.RIGHT, ui.TOP, 0, 20, 17, 0);
    AUTO_CAST(close)
    close:SetImage("testclose_button")
    close:SetTextTooltip("{@st59}어시스터 프리셋 창을 닫습니다.{/}")
    close:SetEventScript(ui.LBUTTONUP, "ANCIENTPRESET_CLOSE_FRAME");

    local topbg = frame:CreateOrGetControl("groupbox", "topbg", 665, 315, ui.LEFT, ui.TOP, 20, 100, 0, 0);
    AUTO_CAST(topbg)
    topbg:EnableHittestGroupBox(false)

    local ancient_card_slot_Gbox = topbg:CreateOrGetControl("groupbox", "ancient_card_slot_Gbox", 665, 275, ui.LEFT, ui.TOP, 0, 0, 0, 0);
    AUTO_CAST(ancient_card_slot_Gbox)
    ancient_card_slot_Gbox:EnableHittestGroupBox(false)
    ancient_card_slot_Gbox:SetSkinName("test_frame_midle")

    local tab = frame:CreateOrGetControl("tab", "tab", 665, 40, ui.LEFT, ui.TOP, 20, 61, 0, 0);
    tab:SetEventScript(ui.LBUTTONUP, "ANCIENTPRESET_ON_TAB_CHANGE");
    AUTO_CAST(tab)
    tab:SetSkinName("tab2")
    for i = 1, 7 do
        tab:AddItem("{@st66b}{s16}프리셋 " .. i, true, "", "", "", "","", false)
        -- tab:AddItemWithName("{@st66b}{s16}프리셋 " .. i, "preset_" .. i)
    end
    tab:SetItemsFixWidth(90)
    tab:SetItemsAdjustFontSizeByWidth(90);
    tab:SetEventScript(ui.MOUSEMOVE, "")

    local swap = frame:CreateOrGetControl("button", "swap", 100, 45,ui.RIGHT, ui.TOP, 0, 325, 30 , 0);
    swap:SetSkinName("test_pvp_btn")
    swap:SetText("{@st42}{s18}변경")
    swap:SetEventScript(ui.LBUTTONUP, "ANCIENTPRESET_ON_SWAP_CLICK");
end

function ANCIENTPRESET_END_DRAG(frame, ctrl)
    AncientPreset.Settings.Position.X = AncientPreset.frame:GetX();
    AncientPreset.Settings.Position.Y = AncientPreset.frame:GetY();
    ANCIENTPRESET_SAVE_SETTINGS();
end

function ANCIENTPRESET_SAVE_SETTINGS()
    local strPresetTable = {}
    for k, v in pairs(AncientPreset.Settings.Presets) do
        strPresetTable[tostring(k)] = {}
        if (v ~= nil) then
            for k2, v2 in pairs(v) do
                strPresetTable[tostring(k)][tostring(k2)] = v2
            end
        end
    end
    acutil.saveJSON(AncientPreset.SettingsFileLoc, strPresetTable);
end

-- general utilities

AncientPreset.Strings = {
    ["string_name"] = {
        ['kr'] = "안녕 세상아",
        ['en'] = "Hello World"
    }
}

function AncientPreset.GetTranslatedString(self, strName)
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

function AncientPreset.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end