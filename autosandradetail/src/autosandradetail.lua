--dofile("../data/addon_d/autosandradetail/autosandradetail.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'autosandradetail'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local AutoSandraDetail = _G['ADDONS'][author][addonName]
local acutil = require('acutil')

AutoSandraDetail.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

AutoSandraDetail.Settings = {
    Position = {
        X = 0,
        Y = 0
    }
};

AutoSandraDetail.Default = {
    Height = 0,
    Width = 0,
    IsVisible = 1,
    Movable = 0,
    Enabled = 0, -- Hittest
};

function AUTOSANDRADETAIL_ON_INIT(addon, frame)
    AutoSandraDetail.addon = addon;
    AutoSandraDetail.frame = frame;
    -- load settings
    if not AutoSandraDetail.Loaded then
        local t, err = acutil.loadJSON(AutoSandraDetail.SettingsFileLoc, AutoSandraDetail.Settings);
        if err then
        else
            AutoSandraDetail.Settings = t;
            AutoSandraDetail.Loaded = true;
        end
    end
    -- initialize frame
    AUTOSANDRADETAIL_ON_FRAME_INIT(frame)

    -- 미세돋 ui 실행
    acutil.setupHook(AUTOSANDRADETAIL_ON_SANDRA_OPEN, 'ITEM_SANDRA_ONELINE_REVERT_RANDOM_OPEN');
    -- 템 등록
    acutil.setupHook(AUTOSANDRADETAIL_ON_ITEM_REGISTER, 'ITEM_SANDRA_ONELINE_REVERT_RANDOM_REG_TARGETITEM');
    -- 산드라 누른 이후 0.5초 딜레이 훅 (확인버튼 뜨는거)
    acutil.setupHook(AUTOSANDRADETAIL_AFTER_SUCCESS_ANIM, '_SUCCESS_SANDRA_ONELINE_REVERT_RANDOM_OPTION');
    -- 일반 클릭
    acutil.setupHook(AUTOSANDRADETAIL_ON_NORMAL_SANDRA_CLICK, '_ITEM_SANDRA_ONELINE_REVERT_RANDOM_EXEC');
    -- 산드라 성공
    addon:RegisterMsg("SUCCESS_SANDRA_ONELINE_REVERT_RANDOM_OPTION", "AUTOSANDRADETAIL_ON_SUCCESS");
end

function AUTOSANDRADETAIL_ON_SANDRA_OPEN(frame)
    -- 일단 기존 함수 실행
    ITEM_SANDRA_ONELINE_REVERT_RANDOM_OPEN_OLD(frame)

    -- 버튼 구현
    local button = frame:GetChildRecursively('do_sandrarevertrandom')
    button:SetGravity(ui.LEFT, ui.BOTTOM);
    button:SetMargin(20, 0, 0, 20);
    button:Resize(170, button:GetHeight());
    local autoButton = frame:CreateOrGetControl("button", "autoButton", 170, button:GetHeight(), ui.RIGHT, ui.BOTTOM, 0, 0, 20, 20);
    autoButton:SetText("{@st41b}{s18}자동 재감정")
    autoButton:SetEventScript(ui.LBUTTONUP, "AUTOSANDRADETAIL_ON_AUTO_CLICK");
    autoButton:SetSkinName("test_red_button")
    local cancelButton = frame:CreateOrGetControl("button", "cancelButton", 170, button:GetHeight(), ui.RIGHT, ui.BOTTOM, 0, 0, 100, 20);
    cancelButton:SetSkinName("test_gray_button")
    cancelButton:SetText("{@st41b}{s18}자동 재감정 취소")
    cancelButton:SetEventScript(ui.LBUTTONUP, "AUTOSANDRADETAIL_ON_CANCEL_CLICK");
    cancelButton:ShowWindow(0);
end

function AUTOSANDRADETAIL_ON_AUTO_CLICK(frame, ctrl)
    -- 자동버튼 숨김
    local autoButton = GET_CHILD_RECURSIVELY(frame, "autoButton")
    autoButton:ShowWindow(0)
    -- 취소버튼 보여줌
    local cancelButton = GET_CHILD_RECURSIVELY(frame, "cancelButton")
    cancelButton:ShowWindow(1)
    -- 실행 버튼도 숨김
    local do_sandrarevertrandom = GET_CHILD_RECURSIVELY(frame, "do_sandrarevertrandom")
    do_sandrarevertrandom:ShowWindow(0)
    -- 자동 실행
    frame:RunUpdateScript("AUTOSANDRADETAIL_ONELINE_REVERT_RANDOM_EXEC", 0.8)
end

function AUTOSANDRADETAIL_ON_CANCEL_CLICK(frame, ctrl)
    frame:StopUpdateScript("AUTOSANDRADETAIL_ONELINE_REVERT_RANDOM_EXEC")
    SENDOK_ITEM_SANDRA_ONELINE_REVERT_RANDOM_UI()
end

function AUTOSANDRADETAIL_ON_NORMAL_SANDRA_CLICK()
    -- 기본 sanity 체크
    local frame = ui.GetFrame("itemsandraoneline_revert_random");
    local gBox = GET_CHILD_RECURSIVELY(frame, "bodyGbox1_1");
    local cnt = frame:GetUserIValue("RANDOM_PROP_CNT");
    local checkcnt = 0;
    local checkindex = 0;
    for i = 1, cnt do
        local controlset = GET_CHILD_RECURSIVELY(gBox, "PROPERTY_CSET_"..i);
        if controlset ~= nil then
            local checkbox = GET_CHILD_RECURSIVELY(controlset, "checkbox");
            if checkbox:IsChecked() == 1 then
                checkindex = i;
                checkcnt = checkcnt + 1;
            end
        end
    end

    if checkcnt == 0 then
        ui.SysMsg(ClMsg("PleaseSlectChangeProperty"));
        frame:StopUpdateScript("AUTOSANDRADETAIL_ONELINE_REVERT_RANDOM_EXEC")
        SENDOK_ITEM_SANDRA_ONELINE_REVERT_RANDOM_UI()
        return;
    end

    if 1 < checkcnt then
        ui.SysMsg(ClMsg("PleaseSlectChangePropertyOnlyOne"));
        frame:StopUpdateScript("AUTOSANDRADETAIL_ONELINE_REVERT_RANDOM_EXEC")
        SENDOK_ITEM_SANDRA_ONELINE_REVERT_RANDOM_UI()
        return;
    end



    local frame = ui.GetFrame('itemsandraoneline_revert_random');
    local autoButton = GET_CHILD_RECURSIVELY(frame, "autoButton")
    autoButton:ShowWindow(0)
    -- 실행 버튼도 숨김
    local do_sandrarevertrandom = GET_CHILD_RECURSIVELY(frame, "do_sandrarevertrandom")
    do_sandrarevertrandom:ShowWindow(0)
    _ITEM_SANDRA_ONELINE_REVERT_RANDOM_EXEC_OLD(frame)
end

-- 슬롯에 아이템 등록 시 아이템 옵션 관련 UI 정보 갱신
function AUTOSANDRADETAIL_ON_ITEM_REGISTER(frame, itemID)
    -- 일단 기존 함수 실행
    ITEM_SANDRA_ONELINE_REVERT_RANDOM_REG_TARGETITEM_OLD(frame, itemID)

    -- 버튼 리셋
    local frame = ui.GetFrame('itemsandraoneline_revert_random');
    local autoButton = GET_CHILD_RECURSIVELY(frame, "autoButton")
    autoButton:ShowWindow(1)
    local cancelButton = GET_CHILD_RECURSIVELY(frame, "cancelButton")
    cancelButton:ShowWindow(0)

    -- 등록된 아이템
    local slot = GET_CHILD_RECURSIVELY(frame, "slot");
    local invItem = GET_SLOT_ITEM(slot);
    if (invItem == nil) then
        return;
    end
    local obj = GetIES(invItem:GetObject());
    local gBox = GET_CHILD_RECURSIVELY(frame, "bodyGbox1_1");
    local cnt = 0;
    for i = 1, MAX_RANDOM_OPTION_COUNT do
        local propName = "RandomOption_" .. i;
        local propValue = "RandomOptionValue_" .. i;
        if obj[propValue] ~= 0 and obj[propName] ~= "None" then
            local isMax = 0;
            local min, max = GET_RANDOM_OPTION_VALUE_VER2(obj, obj[propName])
            if obj[propValue] == max then
                isMax = 1;
            end
            local itemClsCtrl = gBox:GetChildRecursively('PROPERTY_CSET_'..i);

            local checkbox = GET_CHILD_RECURSIVELY(itemClsCtrl, "checkbox", "ui::CCheckBox");
            checkbox:SetMargin(84, 2, 0, 0)

            local propertyList = GET_CHILD_RECURSIVELY(itemClsCtrl, "property_name", "ui::CRichText");
            propertyList:SetMargin(105, 5, 0, 0)
            cnt = cnt + 1;

            local valueedit = itemClsCtrl:CreateOrGetControl("edit", "valueedit", 55, 22, ui.LEFT, ui.TOP, 24, 2, 0, 0);
            AUTO_CAST(valueedit);
            valueedit:SetNumberMode(1);
            valueedit:SetMinNumber(0);
            valueedit:SetText(min);
            valueedit:SetMaxNumber(max);
            valueedit:SetFontName("white_12_ol")
            valueedit:SetSkinName("test_weight_skin");
            valueedit:SetTextAlign("center", "center");
            valueedit:SetTextTooltip(string.format("최소치: %d{nl}최대치: %d", min, max));
        end
    end
    ReserveScript("AUTOSANDRADETAIL_INVALIDATE_FRAME()", 0.01);
end

function AUTOSANDRADETAIL_INVALIDATE_FRAME()
    local frame = ui.GetFrame('itemsandraoneline_revert_random');
    frame:Invalidate();
end

function AUTOSANDRADETAIL_ONELINE_REVERT_RANDOM_EXEC(frame)
    frame = frame:GetTopParentFrame();

    local slot = GET_CHILD_RECURSIVELY(frame, "slot");
    local invItem = GET_SLOT_ITEM(slot);

    if invItem == nil then
        -- 프레임 리셋하고 자동 멈춤
        SENDOK_ITEM_SANDRA_ONELINE_REVERT_RANDOM_UI()
        return 0;
    end

    local text_havematerial = GET_CHILD_RECURSIVELY(frame, "text_havematerial");
    local materialCnt = text_havematerial:GetTextByKey("count");
    if materialCnt == '0' then
        ui.SysMsg(ClMsg("LackOfSandraOnelineRevertRandomMaterial"));
        -- 프레임 리셋하고 자동 멈춤
        SENDOK_ITEM_SANDRA_ONELINE_REVERT_RANDOM_UI()
        return 0;
    end

    if invItem.isLockState == true then
        ui.SysMsg(ClMsg("MaterialItemIsLock"));
        -- 프레임 리셋하고 자동 멈춤
        SENDOK_ITEM_SANDRA_ONELINE_REVERT_RANDOM_UI()
        return 0;
    end

    _ITEM_SANDRA_ONELINE_REVERT_RANDOM_EXEC()
    return 1;
end

function AUTOSANDRADETAIL_AFTER_SUCCESS_ANIM()
    local frame = ui.GetFrame("itemsandraoneline_revert_random");
    if frame:IsVisible() == 0 then
        return;
    end
    -- 일단 기존 함수 실행
    _SUCCESS_SANDRA_ONELINE_REVERT_RANDOM_OPTION_OLD()
    if (frame:HaveUpdateScript("AUTOSANDRADETAIL_ONELINE_REVERT_RANDOM_EXEC") == true) then
        -- send 버튼은 자동중일땐 숨김
        local sendOK = GET_CHILD_RECURSIVELY(frame, "send_ok")
        sendOK:ShowWindow(0)
        -- 취소버튼은 무조건 보여지고있어야되니 혹시모르니 보여지도록 설정
        local cancelButton = GET_CHILD_RECURSIVELY(frame, "cancelButton")
        cancelButton:ShowWindow(1)
        -- 혹시 모르니 프레임 업데이트
        ReserveScript("AUTOSANDRADETAIL_INVALIDATE_FRAME()", 0.01);
    else
        -- 자동이 아니던가 자동을 멈췄을때 캔슬버튼 숨김
        local cancelButton = GET_CHILD_RECURSIVELY(frame, "cancelButton")
        cancelButton:ShowWindow(0)
    end
end

function AUTOSANDRADETAIL_ON_SUCCESS(frame, msg, argStr, argNum)
    local frame = ui.GetFrame("itemsandraoneline_revert_random");
    -- 가끔식 취소 타이밍에 꼬여서 오토버튼이 깝툭튀 할때 있음. 낄끼빠빠 잘하도록 숨김
    local autoButton = GET_CHILD_RECURSIVELY(frame, "autoButton")
    autoButton:ShowWindow(0)

    if (frame:HaveUpdateScript("AUTOSANDRADETAIL_ONELINE_REVERT_RANDOM_EXEC") == false) then
        -- 자동 아닐때는 밑에 암것도 실행 안해도됨
        return;
    end
    local gBox = GET_CHILD_RECURSIVELY(frame, "bodyGbox1_1");
    if gBox == nil then
        frame:StopUpdateScript("AUTOSANDRADETAIL_ONELINE_REVERT_RANDOM_EXEC")
        return;
    end
    -- 체크된 옵션 찾음
    local cnt = frame:GetUserIValue("RANDOM_PROP_CNT");
    local checkcnt = 0;
    local checkindex = 0;
    local targetOptionValue = 0;
    for i = 1, cnt do
        local controlset = GET_CHILD_RECURSIVELY(gBox, "PROPERTY_CSET_"..i);
        if controlset ~= nil then
            local checkbox = GET_CHILD_RECURSIVELY(controlset, "checkbox");
            if checkbox:IsChecked() == 1 then
                checkindex = i;
                checkcnt = checkcnt + 1;
                local valueedit = controlset:GetChild("valueedit");
                targetOptionValue = tonumber(valueedit:GetText());
            end
        end
    end

    local cancelButton = GET_CHILD_RECURSIVELY(frame, "cancelButton")

    -- 체크 옵션이 없을시
    if checkcnt == 0 then
        frame:StopUpdateScript("AUTOSANDRADETAIL_ONELINE_REVERT_RANDOM_EXEC")
        cancelButton:ShowWindow(0)
        ui.SysMsg(ClMsg("PleaseSlectChangeProperty"));
        return;
    end
    -- 아이템 랜덤 옵션 확인
    local slot = GET_CHILD_RECURSIVELY(frame, "slot");
    local invItem = GET_SLOT_ITEM(slot);
    if (invItem == nil) then
        frame:StopUpdateScript("AUTOSANDRADETAIL_ONELINE_REVERT_RANDOM_EXEC")
        cancelButton:ShowWindow(0)
        return;
    end
    local obj = GetIES(invItem:GetObject());
    local propValue = "RandomOptionValue_" .. checkindex;
    local actualOptionValue =  obj[propValue]
    -- 신규옵션이 입력 수치보다 같거나 높은지 확인
    if (actualOptionValue >= targetOptionValue) then
        imcSound.PlaySoundEvent('sys_transcend_success');
        frame:StopUpdateScript("AUTOSANDRADETAIL_ONELINE_REVERT_RANDOM_EXEC")
        cancelButton:ShowWindow(0)
    end
end

function AUTOSANDRADETAIL_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(AutoSandraDetail.Default.Movable);
    frame:EnableHitTest(AutoSandraDetail.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "AUTOSANDRADETAIL_END_DRAG");

    -- draw the frame
    frame:SetSkinName('chat_window');

    -- set default position of frame
    frame:Move(AutoSandraDetail.Settings.Position.X, AutoSandraDetail.Settings.Position.Y);
    frame:SetOffset(AutoSandraDetail.Settings.Position.X, AutoSandraDetail.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(AutoSandraDetail.Default.Width, AutoSandraDetail.Default.Height);
    frame:ShowWindow(AutoSandraDetail.Default.IsVisible);
end

function AUTOSANDRADETAIL_END_DRAG(frame, ctrl)
    AutoSandraDetail.Settings.Position.X = AutoSandraDetail.frame:GetX();
    AutoSandraDetail.Settings.Position.Y = AutoSandraDetail.frame:GetY();
    AUTOSANDRADETAIL_SAVE_SETTINGS();
end

function AUTOSANDRADETAIL_SAVE_SETTINGS()
    acutil.saveJSON(AutoSandraDetail.SettingsFileLoc, AutoSandraDetail.Settings);
end