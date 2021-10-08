--dofile("../data/addon_d/easycardequip/easycardequip.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'easycardequip'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local EasyCardEquip = _G['ADDONS'][author][addonName]
local acutil = require('acutil')

EasyCardEquip.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

EasyCardEquip.Settings = {
    Position = {
        X = 400,
        Y = 400
    }
};

EasyCardEquip.Default = {
    Height = 0,
    Width = 0,
    IsVisible = 1,
    Movable = 0,
    Enabled = 0, -- Hittest
};

function EASYCARDEQUIP_ON_INIT(addon, frame)
    EasyCardEquip.addon = addon;
    EasyCardEquip.frame = frame;
    -- load settings
    if not EasyCardEquip.Loaded then
        local t, err = acutil.loadJSON(EasyCardEquip.SettingsFileLoc, EasyCardEquip.Settings);
        if err then
        else
            EasyCardEquip.Settings = t;
            EasyCardEquip.Loaded = true;
        end
    end
    -- initialize frame
    EASYCARDEQUIP_ON_FRAME_INIT(frame)

    acutil.setupHook(EASYCARDEQUIP_EQUIP_CARDSLOT_INFO_OPEN, 'EQUIP_CARDSLOT_INFO_OPEN')
    acutil.setupHook(EASYCARDEQUIP_MONSTERCARDSLOT_FRAME_OPEN, 'MONSTERCARDSLOT_FRAME_OPEN')
    acutil.setupHook(EASYCARDEQUIP_MONSTERCARDSLOT_FRAME_CLOSE, 'MONSTERCARDSLOT_FRAME_CLOSE')
end

-- 카드 ui 실행했을때 인벤토리 아이템 우클릭 훅 활성화
function EASYCARDEQUIP_MONSTERCARDSLOT_FRAME_OPEN()
    -- 일단 카드 ui 실행
    MONSTERCARDSLOT_FRAME_OPEN_OLD();
    -- 카드 우클릭은 고전식 코드를 사용함. 그래서 따로 우클릭 커스텀 스크립트를 설정해줘야함.
    INVENTORY_SET_CUSTOM_RBTNDOWN("EASYCARDEQUIP_INV_RBTN");
end

-- 창 닫힐때 커스텀 스크립트 제거
function EASYCARDEQUIP_MONSTERCARDSLOT_FRAME_CLOSE(frame)
    local frame = ui.GetFrame("accountwarehouse");
    if (frame ~= nil and frame:IsVisible() == 1) then
        -- 만약 창고 사용중에 카드 관리중이였다면 템 우클릭을 창고등록으로 바꿔줌
        INVENTORY_SET_CUSTOM_RBTNDOWN("ACCOUNT_WAREHOUSE_INV_RBTN")
    else
        -- 제거 안해주면 인벤 한번 닫았다 다시 열때까지 우클릭 먹통됨
        INVENTORY_SET_CUSTOM_RBTNDOWN("None");
    end
    MONSTERCARDSLOT_FRAME_CLOSE_OLD(frame);
end

-- 인벤에서 카드 우클릭시
function EASYCARDEQUIP_INV_RBTN(itemobj, invslot, invguid)
    -- 일단 ui 열려있는지 확인
    local moncardFrame = ui.GetFrame("monstercardslot");
    local goddesscardFrame = ui.GetFrame("goddesscardslot");
    if (moncardFrame == nil and goddesscardFrame == nil) then
        return
    end
    -- 카드인지 확인
    if itemobj.GroupName == "Card" and (goddesscardFrame:IsVisible() == 1 or moncardFrame:IsVisible() == 1) then
        imcSound.PlaySoundEvent("icon_get_down");
        local groupNameStr = itemobj.CardGroupName
        -- 강화용 카드는 불가능
        if groupNameStr == "REINFORCE_CARD" then
            ui.SysMsg(ClMsg("LegendReinforceCard_Not_Equip"));
            return
        end
        if groupNameStr == "REINFORCE_GODDESS_CARD" then
            ui.SysMsg(ClMsg("GoddessReinforceCard_Not_Equip"));
            return
        end
        -- 여신카드는 원래대로 착용
        if goddesscardFrame:IsVisible() == 1 and groupNameStr=="GODDESS" then
            local goddesscardSlot = GET_CHILD_RECURSIVELY(goddesscardFrame,'cardSlot');
            local invitem = session.GetInvItemByGuid(invguid);
            GODDESSCARD_SLOT_EQUIP(goddesscardSlot, invitem, groupNameStr)
        elseif moncardFrame:IsVisible() == 1 then
            -- 그 외 카드는 같은종류카드 장착 시도
            local textmsg = "같은 종류의 카드를 전부 장착 하시겠습니까?";
            local invFrame = ui.GetFrame("inventory");
            invFrame:SetUserValue("EQUIP_CARD_GUID", invguid);
            invFrame:SetUserValue("EQUIP_CARD_GROUPNAME", groupNameStr);
            -- 메시지 박스로 한번더 확인
            ui.MsgBox_NonNested(textmsg, invFrame:GetName(), "EASYCARDEQUIP_ON_EQUIP_MESSAGE_OK", "None");
        end
    end
end

-- 확인창 동의시
function EASYCARDEQUIP_ON_EQUIP_MESSAGE_OK()
    local invFrame = ui.GetFrame("inventory");
    local itemGuid = invFrame:GetUserValue("EQUIP_CARD_GUID");
    local groupNameStr = invFrame:GetUserValue("EQUIP_CARD_GROUPNAME");
    invFrame:SetUserValue("EQUIP_CARD_TYPE", "");
    invFrame:SetUserValue("EQUIP_CARD_GROUPNAME", "");
    local actualInvItem = session.GetInvItemByGuid(itemGuid);
    if (actualInvItem == nil) then
        ui.SysMsg(ClMsg("CantEquipMonsterCard"));
        return;
    end
    local actualObject = GetIES(actualInvItem:GetObject());
    local type = actualObject.ClassID
    local cardLv = TryGetProp(actualObject, 'Level', 1)
    local moncardFrame = ui.GetFrame("monstercardslot");
    local moncardGbox = GET_CHILD_RECURSIVELY(moncardFrame, groupNameStr .. 'cardGbox');
    local card_slotset = GET_CHILD_RECURSIVELY(moncardGbox, groupNameStr .. "card_slotset");
    if card_slotset ~= nil then
        moncardFrame:SetUserValue("easycardequip_groupNameStr", groupNameStr)
        moncardFrame:SetUserValue("easycardequip_cardType", type)
        moncardFrame:SetUserValue("easycardequip_cardLv", cardLv)
        -- 장착 시작
        moncardFrame:RunUpdateScript("EASYCARDEQUIP_EQUIP_SIMILAR_CARDS", 0.2)
    end;
end

function EASYCARDEQUIP_EQUIP_SIMILAR_CARDS(frame)
    local groupNameStr = frame:GetUserValue("easycardequip_groupNameStr")
    local type = frame:GetUserIValue("easycardequip_cardType")
    local cardLv = frame:GetUserIValue("easycardequip_cardLv")

    local moncardFrame = ui.GetFrame("monstercardslot");
    local moncardGbox = GET_CHILD_RECURSIVELY(moncardFrame, groupNameStr .. 'cardGbox');
    local card_slotset = GET_CHILD_RECURSIVELY(moncardGbox, groupNameStr .. "card_slotset");
    -- 각 카드 그룹당 슬롯이 3개 (0 ~ 2) 가 있음. 하나씩 확인하면서 비어있는 슬롯 확인
    local equippedCardCount = 0;
    for i = 0, 2 do
        local slot = card_slotset:GetSlotByIndex(i);
        -- 레전드카드는 슬롯이 하나밖에 없기때문에 slot == nil 이면 더이상 착용 가능한 슬롯이 없다는뜻
        if slot == nil then
            if groupNameStr == 'LEG' then
                ui.SysMsg(ClMsg("LegendCard_Only_One"));
            end
            frame:SetUserValue("easycardequip_groupNameStr", "")
            frame:SetUserValue("easycardequip_cardType", "")
            frame:SetUserValue("easycardequip_cardLv", "")
            return 0;
        end
        local icon = slot:GetIcon();
        -- 슬롯이 비어있을시
        if icon == nil then
            local invitem = EasyCardEquip:GetCardInvItem(type, cardLv)
            if (invitem ~= nil) then
                EasyCardEquip:EquipCard(groupNameStr, i, invitem:GetIESID())
                equippedCardCount = equippedCardCount + 1
                return 1;
                -- 장착 성공, 다음 틱까지 기달
            else
                -- 더이상 이 종류의 카드 없음.
                frame:SetUserValue("easycardequip_groupNameStr", "")
                frame:SetUserValue("easycardequip_cardType", "")
                frame:SetUserValue("easycardequip_cardLv", "")
                return 0;
            end
        end;
    end
    -- 모든 슬롯을 다 뒤져봤는데 장착한 카드가 없다면 더이상 장착할 슬롯이 없다는뜻
    return 0;
end

-- 인벤토리에서 동일 카드 검색
function EasyCardEquip.GetCardInvItem(self, type, lv)
    local itemList = session.GetInvItemList();
    local guidList = itemList:GetGuidList();
    local cnt = guidList:Count();
    for i = 0, cnt - 1 do
        local guid = guidList:Get(i);
        local invItem = session.GetInvItemByGuid(guid);
        local actualObject = GetIES(invItem:GetObject());
        local itemType = actualObject.ClassID
        if (itemType == type) then
            local cardLevel = TryGetProp(actualObject, 'Level', 1)
            if (cardLevel == lv) then
                return invItem
            end
        end
    end
    return nil
end

-- 몬스터 카드 장착 요청
function EasyCardEquip.EquipCard(self, groupNameStr, index, itemGuid)
    local slotIndex = index;
    if groupNameStr == 'ATK' then
        slotIndex = slotIndex + (0 * MONSTER_CARD_SLOT_COUNT_PER_TYPE)
    elseif groupNameStr == 'DEF' then
        slotIndex = slotIndex + (1 * MONSTER_CARD_SLOT_COUNT_PER_TYPE)
    elseif groupNameStr == 'UTIL' then
        slotIndex = slotIndex + (2 * MONSTER_CARD_SLOT_COUNT_PER_TYPE)
    elseif groupNameStr == 'STAT' then
        slotIndex = slotIndex + (3 * MONSTER_CARD_SLOT_COUNT_PER_TYPE)
    elseif groupNameStr == 'LEG' then
        slotIndex = 4 * MONSTER_CARD_SLOT_COUNT_PER_TYPE
        -- leg 카드는 slotindex = 12, 13번째 슬롯
    end

    -- 이미 장착된슬롯
    local cardInfo = equipcard.GetCardInfo(slotIndex + 1);
    if cardInfo ~= nil then
        ui.SysMsg(ClMsg("AlreadyEquippedThatCardSlot"));
        return;
    end

    if groupNameStr == 'LEG' then
        local pcEtc = GetMyEtcObject();
        if pcEtc.IS_LEGEND_CARD_OPEN ~= 1 then
            ui.SysMsg(ClMsg("LegendCard_Slot_NotOpen"))
            return
        end
    end

    if item.isLockState == true then
        ui.SysMsg(ClMsg("MaterialItemIsLock"));
        return
    end

    local argStr = string.format("%d#%s", slotIndex, itemGuid);
    pc.ReqExecuteTx("SCR_TX_EQUIP_CARD_SLOT", argStr);
end

-- 같은카드 전부 장착 해제 버튼 클릭시
function EASYCARDEQUIP_ON_UNEQUIP_BUTTON_CLICK(frame)
    local slotIndex = frame:GetUserIValue("REMOVE_CARD_SLOTINDEX")
    local moncardFrame = ui.GetFrame("monstercardslot");
    local cardType, cardLv, exp = GETMYCARD_INFO(slotIndex)
    moncardFrame:SetUserValue("easycardequip_unequip_cardType", cardType)
    moncardFrame:RunUpdateScript("EASYCARDEQUIP_UNEQUIP_SIMILAR_CARDS", 0.2)
end;

-- 동일 카드 장착 해제 시작
function EASYCARDEQUIP_UNEQUIP_SIMILAR_CARDS(frame)
    local cardType = frame:GetUserIValue("easycardequip_unequip_cardType")
    for i = 0, 13 do
        local cardID, cardLv, cardExp = GETMYCARD_INFO(i);
        if (cardID == cardType) then
            local argStr = string.format("%d", i);
            argStr = argStr .. " 1"
            pc.ReqExecuteTx_NumArgs("SCR_TX_UNEQUIP_CARD_SLOT", argStr);
            return 1;
        end
    end
    return 0;
end

function EASYCARDEQUIP_EQUIP_CARDSLOT_INFO_OPEN(slotIndex)
    EQUIP_CARDSLOT_INFO_OPEN_OLD(slotIndex)
    local frame = ui.GetFrame('equip_cardslot_info');
    if (frame:IsVisible() == 0) then
        return;
    end
    local cardID, cardLv, cardExp = GETMYCARD_INFO(slotIndex);
    if cardID == 0 then
        return;
    end

    local prop = geItemTable.GetProp(cardID);
    if prop ~= nil then
        cardLv = prop:GetLevel(cardExp);
    end

    local extractAllButton = frame:GetChild("extractall");
    if (extractAllButton == nil) then
        -- 한번도 그린적이 없다면 전체 해제 버튼 삽입
        local needSilverText = GET_CHILD_RECURSIVELY(frame, "button_3")
        needSilverText:SetGravity(ui.LEFT, ui.BOTTOM);
        needSilverText:Resize(needSilverText:GetWidth(), needSilverText:GetHeight() // 2);
        needSilverText:SetMargin(25, 0, 0, 150);
        -- 그려지자마자 Resize를 하게되면 텍스트가 제대로 출력이 안됨. 텍스트 그리기를 다시 실행해야하지만 최소 시간을 줘야됨.
        ReserveScript("EASYCARDEQUIP_INVALIDATE_BUTTON_TEXT()", 0.01);
        extractAllButton = frame:CreateOrGetControl("button", "extractall", 0, 0, 0, 0);
        extractAllButton:SetEventScript(ui.LBUTTONUP, "EASYCARDEQUIP_ON_UNEQUIP_BUTTON_CLICK")
        extractAllButton:SetPos(needSilverText:GetX(), needSilverText:GetY() + needSilverText:GetHeight() + 5);
        extractAllButton:Resize(needSilverText:GetWidth(), needSilverText:GetHeight());
    end

    -- 전체 해제 값 계산
    local totalPrice = 0;
    local cls = GetClassByType("Item", cardID);
    for i = 0, 13 do
        local tempCardID, tempCardLv, tempCardExp = GETMYCARD_INFO(i);
        if (cardID == tempCardID) then
            local needSilver = tonumber(CALC_NEED_SILVER(cls, tempCardLv))
            totalPrice = totalPrice + needSilver
        end
    end
    extractAllButton:SetText(string.format("{img icon_item_silver 24 24}{@st41b}%s실버 소모{nl}카드 전부 해제", GET_COMMAED_STRING(totalPrice)));
end

function EASYCARDEQUIP_INVALIDATE_BUTTON_TEXT()
    local frame = ui.GetFrame('equip_cardslot_info');
    if (frame ~= nil) then
        local needSilverText = GET_CHILD_RECURSIVELY(frame, "button_3")
        needSilverText:Invalidate();
    end
end

function EASYCARDEQUIP_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(EasyCardEquip.Default.Movable);
    frame:EnableHitTest(EasyCardEquip.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "EASYCARDEQUIP_END_DRAG");

    -- draw the frame
    frame:SetSkinName('chat_window');

    -- set default position of frame
    frame:Move(EasyCardEquip.Settings.Position.X, EasyCardEquip.Settings.Position.Y);
    frame:SetOffset(EasyCardEquip.Settings.Position.X, EasyCardEquip.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(EasyCardEquip.Default.Width, EasyCardEquip.Default.Height);
    frame:ShowWindow(EasyCardEquip.Default.IsVisible);
end

function EASYCARDEQUIP_END_DRAG(frame, ctrl)
    EasyCardEquip.Settings.Position.X = EasyCardEquip.frame:GetX();
    EasyCardEquip.Settings.Position.Y = EasyCardEquip.frame:GetY();
    EASYCARDEQUIP_SAVE_SETTINGS();
end

function EASYCARDEQUIP_SAVE_SETTINGS()
    acutil.saveJSON(EasyCardEquip.SettingsFileLoc, EasyCardEquip.Settings);
end