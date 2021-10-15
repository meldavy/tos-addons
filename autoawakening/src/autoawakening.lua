--dofile("../data/addon_d/autoawakening/autoawakening.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'autoawakening'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local AutoAwakening = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

local isPerformingAuto = false;

-- from AwakenRoller addon
local MARKET_OPTION_GROUP_PROP_LIST = {

    DEF = {
        'ADD_DEF',        --物理防御力
        'ADD_MDEF',       --魔法防御力
        'ResAdd_Damage',  --追加ダメージ抵抗
        'CRTDR',          --クリティカル抵抗
        'ADD_DR',         --回避
        'MHP',            --MaxHP
        'MSP',            --MaxSP
        'BLK',            --블럭
        'RHP',            --HP回復力
        'RSP',            --SP回復力
    },
    WEAPON = {
        'CRTHR',          --クリティカル発生
        'PATK',           --物理攻撃力
        'ADD_MATK',       --魔法攻撃力
        'CRTATK',         --物理クリティカル攻撃力
        'CRTMATK',        --魔法クリティカル攻撃力
        'Add_Damage_Atk', --追加ダメージ
        'ADD_HR',         --命中
    }
}

function AUTOAWAKENING_ON_INIT(addon, frame)
    AutoAwakening.addon = addon;
    AutoAwakening.frame = frame;
    AutoAwakening.SetupHook(AUTOAWAKENING_SUCCESS_ITEM_AWAKENING, 'SUCCESS_ITEM_AWAKENING')
    AutoAwakening.SetupHook(AUTOAWAKENING_OPEN_ITEMDUNGEON_BUYER, 'OPEN_ITEMDUNGEON_BUYER')
    AutoAwakening.SetupHook(AUTOAWAKENING_DROP_WEALTH_ITEM, 'ITEMDUNGEON_DROP_WEALTH_ITEM')
    AutoAwakening.SetupHook(AUTOAWAKENING_RESET_ABRASIVE, 'ITEMDUNGEON_RESET_ABRASIVE')
    AutoAwakening.SetupHook(AUTOAWAKENING_RESET_STONE, 'ITEMDUNGEON_RESET_STONE')
    AutoAwakening.SetupHook(AUTOAWAKENING_DROP_ITEM, 'ITEMDUNGEON_DROP_ITEM')
    AutoAwakening.SetupHook(AUTOAWAKENING_INV_RBTN, 'ITEMDUNGEON_INV_RBTN')
    AutoAwakening.SetupHook(AUTOAWAKENING_CLEARUI, 'ITEMDUNGEON_CLEARUI')
    AutoAwakening.SetupHook(AUTOAWAKENING_INIT_FOR_BUYER, 'ITEMDUNGEON_INIT_FOR_BUYER')
end

function AUTOAWAKENING_INIT_FOR_BUYER(frame, isSeller)
    AutoAwakening.ProcessInitForBuyer(frame, isSeller)
end

function AutoAwakening.ProcessInitForBuyer(frame, isSeller)
    base["ITEMDUNGEON_INIT_FOR_BUYER"](frame, isSeller)
    -- vars
    isPerformingAuto = false;
end

-- 인벤 우클릭으로 아이템 등록 (장비 재료 둘다)
function AUTOAWAKENING_INV_RBTN(itemobj, invslot, invguid)
    AutoAwakening.ProcessInvRbtn(itemobj, invslot, invguid)
end

function AutoAwakening.ProcessInvRbtn(itemobj, invslot, invguid)
    base["ITEMDUNGEON_INV_RBTN"](itemobj, invslot, invguid)
    AutoAwakening:RedrawSlots();
    -- 장비가 등록 되었으면 옵션 선택 목록 드로우
    if (AutoAwakening:IsTargetItemSlotted() == true) then
        local invItem, isEquip = GET_PC_ITEM_BY_GUID(invguid);
        local itemObj = GetIES(invItem:GetObject());
        if IS_EQUIP(itemObj) == true then
            AutoAwakening:RedrawDroplist();
        end
    end
end


-- 드래그로 재료 등록
function AUTOAWAKENING_DROP_WEALTH_ITEM(parent, ctrl)
    AutoAwakening.ProcessDropWealthItem(parent, ctrl)
end

function AutoAwakening.ProcessDropWealthItem(parent, ctrl)
    base["ITEMDUNGEON_DROP_WEALTH_ITEM"](parent, ctrl)
    AutoAwakening:RedrawSlots();
end

-- 드래그로 장비 등록
function AUTOAWAKENING_DROP_ITEM(parent, ctrl)
    AutoAwakening.ProcessDropItem(parent, ctrl)
end

function AutoAwakening.ProcessDropItem(parent, ctrl)
    base["ITEMDUNGEON_DROP_ITEM"](parent, ctrl)
    AutoAwakening:RedrawSlots();
    -- 장비가 등록 되있으면 옵션 선택 목록 드로우
    if (AutoAwakening:IsTargetItemSlotted() == true) then
        AutoAwakening:RedrawDroplist();
    end
end

-- 프레임 종료, 혹은 장비 우클릭으로 등록 해제 할경우 클리어 발생.
function AUTOAWAKENING_CLEARUI(frame)
    AutoAwakening.ProcessClearUI(frame)
end

function AutoAwakening.ProcessClearUI(frame)
    AutoAwakening:ClearTimers();
    -- 커스텀 컨트롤들 전부 클리어
    local itemdungeonFrame = ui.GetFrame('itemdungeon')
    if (itemdungeonFrame ~= nil and itemdungeonFrame:IsVisible() == 1) then
        local targetSlot = GET_CHILD_RECURSIVELY(itemdungeonFrame, 'targetSlot');
        local droplist = GET_CHILD_RECURSIVELY(itemdungeonFrame, 'droplist');
        local countedit = GET_CHILD_RECURSIVELY(itemdungeonFrame, 'countedit');
        AUTO_CAST(targetSlot);
        AUTO_CAST(droplist);
        AUTO_CAST(countedit);
        targetSlot:ClearIcon(); -- IMC 버그 대신 고쳐줌 ㅋㅋ
        droplist:ClearItems();
        countedit:SetText(1);
    end
    -- 기존 UI클리어 함수
    base["ITEMDUNGEON_CLEARUI"](frame)
    -- 아이콘 클리어
    if (itemdungeonFrame ~= nil and itemdungeonFrame:IsVisible() == 1) then
        AutoAwakening:RedrawTargetSlot();
        AUTOAWAKENING_REDRAW_SLOTS();
    end
end

-- 연마제 등록 해제 될때 슬롯 다시 그림
function AUTOAWAKENING_RESET_ABRASIVE(frame)
    AutoAwakening.ProcessResetAbrasive(frame)
end

function AutoAwakening.ProcessResetAbrasive(frame)
    base["ITEMDUNGEON_RESET_ABRASIVE"](frame);
    AutoAwakening:RedrawSlots();
end

-- 각성석 등록 해제 될때 슬롯 다시 그림
function AUTOAWAKENING_RESET_STONE(frame)
    AutoAwakening.ProcessResetStone(frame)
end

function AutoAwakening.ProcessResetStone(frame)
    base["ITEMDUNGEON_RESET_STONE"](frame);
    AutoAwakening:RedrawSlots();
end

-- 커스텀 ui 컨트롤들 그림
function AUTOAWAKENING_OPEN_ITEMDUNGEON_BUYER(groupName, sellType, handle)
    AutoAwakening.ProcessOpenItemdungeonBuyer(groupName, sellType, handle)
end

function AutoAwakening.ProcessOpenItemdungeonBuyer(groupName, sellType, handle)
    base["OPEN_ITEMDUNGEON_BUYER"](groupName, sellType, handle)
    local frame = ui.GetFrame('itemdungeon')
    -- containers
    local bgbox = GET_CHILD_RECURSIVELY(frame, 'bg3');
    local mainBox = GET_CHILD_RECURSIVELY(frame, 'mainBox');
    local buttonbox = GET_CHILD_RECURSIVELY(frame, 'buyerBtnBox');
    local buyerBox = GET_CHILD_RECURSIVELY(frame, 'buyerBox');
    AUTO_CAST(buyerBox);
    buyerBox:SetMargin(0, 200, 0, 70);

    -- create timers
    local addontimer = frame:CreateOrGetControl("timer", "addontimer", 10, 10);

    -- attempt selection controls
    local countselectgroup = bgbox:CreateOrGetControl("groupbox", "countselectgroup", 280, 80, ui.LEFT, ui.TOP, 20, 20, 0, 0);
    local countselecttext = countselectgroup:CreateOrGetControl("richtext", "countselecttext", 40, 40, ui.LEFT, ui.TOP, 0, 7, 0, 0);
    local numupdowngroup = countselectgroup:CreateOrGetControl("groupbox", "numupdowngroup", 100, 40, ui.LEFT, ui.TOP, 90, 0, 0, 0);
    local countedit = numupdowngroup:CreateOrGetControl("edit", "countedit", 60, 32, ui.RIGHT, ui.TOP, 0, 0, 0, 0);
    local countupbtn = numupdowngroup:CreateOrGetControl("button", "countupbtn", 60, 60, ui.LEFT, ui.TOP, 0, 1, 0, 0);
    local countdownbtn = numupdowngroup:CreateOrGetControl("button", "coutdownbtn", 60, 60, ui.LEFT, ui.TOP, 0, 16, 0, 0);
    local selectionlabelline = bgbox:CreateOrGetControl("labelline", "labelline1_1", 420, 1, ui.LEFT, ui.TOP, 0, 60, 0, 0);
    AUTO_CAST(countedit);
    AUTO_CAST(countupbtn);
    AUTO_CAST(countdownbtn);
    AUTO_CAST(countselecttext);

    countselecttext:SetFontName("white_16_ol");
    countselecttext:SetText("{@st41}자동 횟수");
    countupbtn:SetImage("test_up_w_btn");
    countdownbtn:SetImage("test_down_w_btn");
    countupbtn:EnableImageStretch(1);
    countdownbtn:EnableImageStretch(1);

    countupbtn:SetEventScript(ui.LBUTTONUP, "AUTOAWAKENING_UP_BUTTON");
    countdownbtn:SetEventScript(ui.LBUTTONUP, "AUTOAWAKENING_DOWN_BUTTON");

    countedit:SetNumberMode(1);
    countedit:SetOffsetYForDraw(-1);
    countedit:SetMinNumber(1);
    countedit:SetText(1);
    countedit:SetMaxNumber(9999);
    countedit:SetFontName("white_18_ol");
    countedit:SetSkinName("test_weight_skin");
    countedit:SetTextAlign("center", "center");

    -- option selection
    local optionselecttext = bgbox:CreateOrGetControl("richtext", "countselecttext", 40, 40, ui.LEFT, ui.TOP, 20, 74, 0, 0);
    local droplist = bgbox:CreateOrGetControl("droplist", "droplist", 190, 30, ui.LEFT, ui.TOP, 110, 74, 0, 0);
    local optionlabelline = bgbox:CreateOrGetControl("labelline", "labelline2_1", 420, 1, ui.LEFT, ui.TOP, 0, 108, 0, 0);
    local valueedittext = bgbox:CreateOrGetControl("richtext", "valueedittext", 40, 40, ui.LEFT, ui.TOP, 20, 121, 0, 0);
    local valueedit = bgbox:CreateOrGetControl("edit", "valueedit", 60, 32, ui.LEFT, ui.TOP, 110, 118, 0, 0);
    local valuelabelline = bgbox:CreateOrGetControl("labelline", "labelline3_1", 420, 1, ui.LEFT, ui.TOP, 0, 159, 0, 0);
    -- TODO: add edit field for attempt count
    AUTO_CAST(optionselecttext);
    AUTO_CAST(droplist);
    AUTO_CAST(valueedit);
    AUTO_CAST(valueedittext);

    optionselecttext:SetFontName("white_16_ol");
    optionselecttext:SetText("{@st41}옵션 선택");
    droplist:SetTextAlign('center','top');
    droplist:SetSkinName('droplist_normal');
    droplist:ClearItems();

    valueedittext:SetFontName("white_16_ol");
    valueedittext:SetText("{@st41}최소 수치");
    valueedit:SetNumberMode(1);
    valueedit:SetOffsetYForDraw(-1);
    valueedit:SetMinNumber(1);
    valueedit:SetText(0);
    valueedit:SetMaxNumber(9999);
    valueedit:SetFontName("white_18_ol");
    valueedit:SetSkinName("test_weight_skin");
    valueedit:SetTextAlign("center", "center");

    -- Awakening option display
    local optiontext = mainBox:CreateOrGetControl("richtext", "optiontext", 343, 48, ui.CENTER_HORZ, ui.TOP, 0, 400, 0, 0)
    AUTO_CAST(optiontext);

    optiontext:SetFontName("white_16_ol");
    optiontext:SetText("");
    optiontext:SetTextAlign("center", "center");
    optiontext:SetColorTone('FF0083FF');

    -- buttons
    local buyBtn = GET_CHILD_RECURSIVELY(buttonbox, 'buyBtn');
    local autoBtn = buttonbox:CreateOrGetControl("button", "autoBtn", 140, 50, ui.LEFT, ui.TOP, 250, 20, 0, 0)
    local cancelBtn = buttonbox:CreateOrGetControl("button", "cancelBtn", 140, 50, ui.CENTER_HORZ, ui.TOP, 0, 20, 0, 0)
    AUTO_CAST(autoBtn);
    AUTO_CAST(buyBtn);
    AUTO_CAST(cancelBtn);

    buyBtn:SetMargin(60, 20, 0, 0)

    autoBtn:SetText("{@st42}자 동")
    autoBtn:SetSkinName("test_red_button")
    autoBtn:SetEventScript(ui.LBUTTONUP, "AUTOAWAKENING_CONFIRM_START_AUTO")

    cancelBtn:SetText("{@st42}취 소")
    cancelBtn:SetSkinName("test_gray_button")
    cancelBtn:SetEventScript(ui.LBUTTONUP, "AUTOAWAKENING_CANCEL_AUTO")
    cancelBtn:SetVisible(0);
end

-- 자동각성 시작 전에 확인메시지 띄움
function AUTOAWAKENING_CONFIRM_START_AUTO(parent, ctrl)
    ui.MsgBox("입력된 설정으로 실행 하겠습니까?", 'AUTOAWAKENING_START_AUTO()', 'None')
end

-- 오토 시작
function AUTOAWAKENING_START_AUTO()
    local frame = ui.GetFrame('itemdungeon')
    local buyBtn = GET_CHILD_RECURSIVELY(frame, 'buyBtn');
    local autoBtn = GET_CHILD_RECURSIVELY(frame, 'autoBtn');
    local cancelBtn = GET_CHILD_RECURSIVELY(frame, 'cancelBtn');
    local droplist = GET_CHILD_RECURSIVELY(frame, 'droplist');
    local countedit = GET_CHILD_RECURSIVELY(frame, 'countedit');
    AUTO_CAST(buyBtn);
    AUTO_CAST(autoBtn);
    AUTO_CAST(cancelBtn);
    AUTO_CAST(droplist);
    AUTO_CAST(countedit);
    buyBtn:SetVisible(0);
    autoBtn:SetVisible(0);
    cancelBtn:SetVisible(1);
    droplist:EnableHitTest(0);
    countedit:EnableHitTest(0);

    local timer = frame:GetChild("addontimer");
    AUTO_CAST(timer)
    timer:Stop();
    isPerformingAuto = true;
    timer:SetUpdateScript("AUTOAWAKENING_ON_AUTO_ATTEMPT_TIMER_TICK");
    timer:Start(1);
end

-- 오토 멈쳐
function AUTOAWAKENING_CANCEL_AUTO(parent, ctrl)
    isPerformingAuto = false;
    local frame = ui.GetFrame('itemdungeon')
    if (frame ~= nil) then
        local buyBtn = GET_CHILD_RECURSIVELY(frame, 'buyBtn');
        local autoBtn = GET_CHILD_RECURSIVELY(frame, 'autoBtn');
        local cancelBtn = GET_CHILD_RECURSIVELY(frame, 'cancelBtn');
        local droplist = GET_CHILD_RECURSIVELY(frame, 'droplist');
        local countedit = GET_CHILD_RECURSIVELY(frame, 'countedit');
        if (autoBtn ~= nil) then
            ITEMDUNGEON_BUY_ITEM_ENABLEHITTEST();
            AUTO_CAST(buyBtn);
            AUTO_CAST(autoBtn);
            AUTO_CAST(cancelBtn);
            AUTO_CAST(droplist);
            AUTO_CAST(countedit);
            buyBtn:SetVisible(1);
            autoBtn:SetVisible(1);
            cancelBtn:SetVisible(0);
            droplist:EnableHitTest(1);
            countedit:EnableHitTest(1);
        end
    end
    AutoAwakening:ClearTimers();
end

-- 1초마다 마구 각성해
function AUTOAWAKENING_ON_AUTO_ATTEMPT_TIMER_TICK(frame)
    local awakeningFrame = ui.GetFrame('itemdungeon');
    local edit = GET_CHILD_RECURSIVELY(awakeningFrame, "countedit");
    AUTO_CAST(edit)
    local curCnt = tonumber(edit:GetText());
    if (curCnt > 0) then
        local _, cnt = GET_ITEM_AWAKENING_PRICE(AutoAwakening:GetTargetItem())
        local groupInfo = session.autoSeller.GetByIndex('Awakening', 0)
        local price = tostring(cnt * groupInfo.price)
        local money = GET_TOTAL_MONEY_STR()
        if IsGreaterThanForBigNumber(price, money) == 1 then
            ui.SysMsg(ScpArgMsg('NotEnoughMoney'));
            AUTOAWAKENING_CANCEL_AUTO();
        else
            -- 대상 장비가 등록 안되있으면 실행 취소
            local targetSlot = GET_CHILD_RECURSIVELY(awakeningFrame, 'targetSlot');
            local targetIcon = targetSlot:GetIcon();
            if targetIcon == nil then
                ui.SysMsg(ClMsg('NotExistTargetItem'));
                AUTOAWAKENING_CANCEL_AUTO();
                return;
            end
            local targetItemGuid = targetIcon:GetInfo():GetIESID();
            local targetItem = session.GetInvItemByGuid(targetItemGuid);
            if targetItem == nil then
                ui.SysMsg(ClMsg('NotExistTargetItem'));
                AUTOAWAKENING_CANCEL_AUTO();
                return;
            end

            -- 각성석 등록 안되있으면 실행 취소
            local stoneSlot = GET_CHILD_RECURSIVELY(awakeningFrame, 'stoneSlot');
            local stoneIcon = stoneSlot:GetIcon();
            local materialItemGuid = '0';
            if stoneIcon ~= nil then
                materialItemGuid = stoneIcon:GetInfo():GetIESID();
            else
                ui.SysMsg(ClMsg('NotEnoughMaterial'));
                AUTOAWAKENING_CANCEL_AUTO();
                return;
            end

            -- 연마제 등록 안되있으면 실행 취소
            local abrasiveSlot = GET_CHILD_RECURSIVELY(awakeningFrame, 'abrasiveSlot');
            local abrasiveIcon = abrasiveSlot:GetIcon();
            local secondmaterialItemGuid = '0';
            if abrasiveIcon ~= nil then
                secondmaterialItemGuid = abrasiveIcon:GetInfo():GetIESID();
            else
                ui.SysMsg(ClMsg('NotEnoughMaterial'));
                AUTOAWAKENING_CANCEL_AUTO();
                return;
            end

            -- 실행
            local sklCls = GetClass('Skill', 'Alchemist_ItemAwakening');
            local handle = awakeningFrame:GetUserIValue('HANDLE');
            edit:SetText(curCnt - 1);
            session.autoSeller.BuyWithPluralMaterialItem(handle, sklCls.ClassID, AUTO_SELL_AWAKENING, targetItemGuid, materialItemGuid, secondmaterialItemGuid);
            if (curCnt - 1 == 0) then
                AUTOAWAKENING_CANCEL_AUTO();
            end
        end
    else
        AUTOAWAKENING_CANCEL_AUTO();
    end

end

-- 각성시 본인이 정한 옵션인지 확인
function AUTOAWAKENING_SUCCESS_ITEM_AWAKENING(frame)
    AutoAwakening.ProcessSuccessItemAwakening(frame)
end

function AutoAwakening.ProcessSuccessItemAwakening(frame)
    local edit = GET_CHILD_RECURSIVELY(frame, "countedit");
    AUTO_CAST(edit)
    local curCnt = tonumber(edit:GetText());
    -- 오토 실행이 아니였을시 다시 구매 클릭 가능하게 해줌.
    -- 오토 실행일때는 오토 실행 중지
    if (isPerformingAuto == false or curCnt == 0) then
        ITEMDUNGEON_BUY_ITEM_ENABLEHITTEST();
    end
    --ITEMDUNGEON_RESET_STONE(frame);
    --ITEMDUNGEON_RESET_ABRASIVE(frame);
    UPDATE_ITEMDUNGEON_CURRENT_ITEM(frame);
    AutoAwakening:RedrawSlots();
    AutoAwakening:RedrawTargetSlot();

    -- 오토 실행중일시 자동 설정에 맞춰 성공여부 계산
    if (isPerformingAuto == true) then
        local droplist = GET_CHILD_RECURSIVELY(frame, 'droplist');
        local valueedit = GET_CHILD_RECURSIVELY(frame, "valueedit");
        AUTO_CAST(droplist)
        AUTO_CAST(valueedit)

        local invItem = AutoAwakening:GetTargetItem();
        local item = GetIES(invItem:GetObject());
        local targetType = AutoAwakening:GetSelectedTargetType();

        local actualType = item.HiddenProp
        local targetValue = tonumber(valueedit:GetText());
        local actualValue = item.HiddenPropValue

        if (actualValue >= targetValue and actualType == targetType) then
            local optiontext = GET_CHILD_RECURSIVELY(frame, 'optiontext');
            AUTO_CAST(optiontext)
            local subtext = ScpArgMsg(actualType) .. ": " .. item.HiddenPropValue
            optiontext:SetText("{@st41}" .. subtext)
            optiontext:SetTextAlign("left", "center");
            optiontext:SetMargin(0, 400, 0, 0);
            optiontext:SetColorTone('FFFC7F03');
            imcSound.PlaySoundEvent('sys_transcend_success');
            ITEMDUNGEON_RESET_ABRASIVE(frame);
            ITEMDUNGEON_RESET_STONE(frame);
            edit:SetText(1);
            AUTOAWAKENING_CANCEL_AUTO()
        end
    end
end

function AUTOAWAKENING_DOWN_BUTTON(parent, ctrl)
    local edit = GET_CHILD_RECURSIVELY(ui.GetFrame('itemdungeon'), "countedit");
    AUTO_CAST(edit)
    local curCnt = tonumber(edit:GetText());
    local downCnt = curCnt - 1;
    if edit:GetMinNumber() > downCnt then
        downCnt = edit:GetMinNumber();
    end

    edit:SetText(downCnt);
end

function AUTOAWAKENING_UP_BUTTON(parent, ctrl)
    local edit = GET_CHILD_RECURSIVELY(ui.GetFrame('itemdungeon'), "countedit");
    AUTO_CAST(edit)
    local curCnt = tonumber(edit:GetText());
    local upCnt = curCnt + 1;
    if edit:GetMaxNumber() < upCnt then
        upCnt = edit:GetMaxNumber();
    end

    edit:SetText(upCnt);
end

function AutoAwakening:GetSelectedTargetType(self)
    local invItem = AutoAwakening:GetTargetItem();
    local item = GetIES(invItem:GetObject());
    local frame = ui.GetFrame('itemdungeon');
    local droplist = GET_CHILD_RECURSIVELY(frame, 'droplist');
    AUTO_CAST(droplist)

    local equipGroup = TryGetProp(item, 'EquipGroup');
    local itemClassType = TryGetProp(item, 'ClassType');

    local props = {}
    -- get prop list
    if equipGroup == 'Weapon' or equipGroup == 'THWeapon' or (equipGroup == 'SubWeapon' and itemClassType ~= 'Shield') then
        props = MARKET_OPTION_GROUP_PROP_LIST.WEAPON
    elseif equipGroup == 'SHIRT' or equipGroup == 'PANTS' or equipGroup == 'BOOTS' or equipGroup == 'GLOVES' then
        props = MARKET_OPTION_GROUP_PROP_LIST.DEF
    elseif itemClassType == 'Neck' or itemClassType == 'Ring' then
        props = MARKET_OPTION_GROUP_PROP_LIST.DEF
    elseif itemClassType == 'Shield' then
        props = MARKET_OPTION_GROUP_PROP_LIST.WEAPON
    else
        return nil
    end

    local i = 0
    local targetType
    for k, v in pairs(props) do
        if droplist:GetSelItemIndex() == i then
            targetType = v
        end
        i = i + 1
    end
    return targetType
end

-- Redraw the droplist
function AutoAwakening.RedrawDroplist(self)
    local frame = ui.GetFrame('itemdungeon');
    -- clear existing list
    local optionList = GET_CHILD_RECURSIVELY(frame, 'droplist');
    AUTO_CAST(optionList);
    optionList:ClearItems();

    -- redraw target slot
    AutoAwakening:RedrawTargetSlot();

    local invItem = AutoAwakening:GetTargetItem();
    if (invItem ~= nil) then
        local item = GetIES(invItem:GetObject());
        local equipGroup = TryGetProp(item, 'EquipGroup');
        local itemClassType = TryGetProp(item, 'ClassType');
        local props = {}
        -- get prop list
        if equipGroup == 'Weapon' or equipGroup == 'THWeapon' or (equipGroup == 'SubWeapon' and itemClassType ~= 'Shield') then
            props = MARKET_OPTION_GROUP_PROP_LIST.WEAPON
        elseif equipGroup == 'SHIRT' or equipGroup == 'PANTS' or equipGroup == 'BOOTS' or equipGroup == 'GLOVES' then
            props = MARKET_OPTION_GROUP_PROP_LIST.DEF
        elseif itemClassType == 'Shield' then
            props = MARKET_OPTION_GROUP_PROP_LIST.WEAPON
        elseif itemClassType == 'Neck' or itemClassType == 'Ring' then
            props = MARKET_OPTION_GROUP_PROP_LIST.DEF
        else
            -- this shouldn't happen
        end
        -- populate option list
        local i = 0
        for k, v in pairs(props) do
            optionList:AddItem(i, ScpArgMsg(v))
            i = i + 1
        end
        optionList:SetTextAlign('center','top');
    end
end

function AutoAwakening.RedrawTargetSlot(self)
    local frame = ui.GetFrame('itemdungeon');
    local optiontext = GET_CHILD_RECURSIVELY(frame, 'optiontext');
    AUTO_CAST(optiontext)
    local invItem = AutoAwakening:GetTargetItem();
    if (invItem ~= nil) then
        local item = GetIES(invItem:GetObject());

        -- get awakening value from weapon and display it on the frame
        local hiddenProp = item.HiddenProp;
        if (hiddenProp ~= nil and tostring(hiddenProp) ~= "YES") then
            local subtext = ScpArgMsg(hiddenProp) .. ": " .. item.HiddenPropValue
            optiontext:SetText(subtext)
            optiontext:SetTextAlign("left", "center");
            optiontext:SetMargin(0, 400, 0, 0);
            optiontext:SetColorTone('FF0083FF');
        else
            optiontext:SetText("")
        end
    else
        optiontext:SetText("")
    end
end

function AutoAwakening.RedrawSlots(self)
    local frame = ui.GetFrame('itemdungeon');
    if (frame == nil) then
        return;
    end

    -- redraw stoneSlot
    local stoneSlot = GET_CHILD_RECURSIVELY(frame, 'stoneSlot');
    AUTO_CAST(stoneSlot)
    local stoneIcon = stoneSlot:GetIcon();
    if (stoneIcon ~= nil) then
        local stoneNameText = GET_CHILD_RECURSIVELY(frame, 'stoneNameText');
        if (stoneNameText:IsVisible() == 0) then
            SET_SLOT_COUNT_TEXT(stoneSlot, "");
            base["ITEMDUNGEON_RESET_STONE"](frame);
        else
            local invStoneItem, isEquip  = GET_PC_ITEM_BY_GUID(stoneIcon:GetInfo():GetIESID());
            if (invStoneItem ~= nil) then
                SET_SLOT_COUNT_TEXT(stoneSlot, invStoneItem.count);
            else
                SET_SLOT_COUNT_TEXT(stoneSlot, "");
                base["ITEMDUNGEON_RESET_STONE"](frame);
            end
        end
    else
        SET_SLOT_COUNT_TEXT(stoneSlot, "");
        base["ITEMDUNGEON_RESET_STONE"](frame);
    end

    -- redraw the abrasiveSlot
    local abrasiveSlot = GET_CHILD_RECURSIVELY(frame, 'abrasiveSlot');
    AUTO_CAST(abrasiveSlot)
    local abrasiveIcon = abrasiveSlot:GetIcon();
    if (abrasiveIcon ~= nil) then
        local abrasiveNameText = GET_CHILD_RECURSIVELY(frame, 'abrasiveNameText');
        if (abrasiveNameText:IsVisible() == 0) then
            SET_SLOT_COUNT_TEXT(abrasiveSlot, "");
            base["ITEMDUNGEON_RESET_ABRASIVE"](frame);
        else
            local invAbrasiveItem, isEquip  = GET_PC_ITEM_BY_GUID(abrasiveIcon:GetInfo():GetIESID());
            if (invAbrasiveItem ~= nil) then
                SET_SLOT_COUNT_TEXT(abrasiveSlot, invAbrasiveItem.count);
            else
                SET_SLOT_COUNT_TEXT(abrasiveSlot, "");
                base["ITEMDUNGEON_RESET_ABRASIVE"](frame);
            end
        end
    else
        SET_SLOT_COUNT_TEXT(abrasiveSlot, "");
        base["ITEMDUNGEON_RESET_ABRASIVE"](frame);
    end
end

function AutoAwakening:GetTargetItem(self)
    local frame = ui.GetFrame('itemdungeon');
    if (frame == nil or frame:IsVisible() ~= 1) then
        return nil;
    end
    local targetSlot = GET_CHILD_RECURSIVELY(frame, 'targetSlot');
    local targetIcon = targetSlot:GetIcon();
    if targetIcon == nil then
        return nil;
    end
    local targetItemGuid = targetIcon:GetInfo():GetIESID();
    local targetItem = session.GetInvItemByGuid(targetItemGuid);
    return targetItem;
end

function AutoAwakening:IsTargetItemSlotted(self)
    local frame = ui.GetFrame('itemdungeon');
    if (frame == nil or frame:IsVisible() ~= 1) then
        return false;
    end
    local targetSlot = GET_CHILD_RECURSIVELY(frame, 'targetSlot');
    local targetIcon = targetSlot:GetIcon();
    if targetIcon == nil then
        return false;
    end
    local targetItemGuid = targetIcon:GetInfo():GetIESID();
    local targetItem = session.GetInvItemByGuid(targetItemGuid);
    if targetItem == nil then
        return false;
    end
    local targetItemObj = targetItem:GetObject();
    if targetItemObj == nil then
        return false;
    end
    return true;
end

function AutoAwakening:ClearTimers(self)
    isPerformingAuto = false;
    local frame = ui.GetFrame('itemdungeon');
    if (frame ~= nil) then
        local addontimer = frame:GetChild("addontimer");
        if (addontimer ~= nil) then
            AUTO_CAST(addontimer)
            addontimer:Stop();
        end
    end
end

function AutoAwakening.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end