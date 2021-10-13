--dofile("../data/addon_d/banderilla/banderilla.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'banderilla'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local Banderilla = _G['ADDONS'][author][addonName]
local acutil = require('acutil')

Banderilla.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)
Banderilla.BUFF_ID = 4606
Banderilla.DEBUFF_ID = 4607
Banderilla.CAPOTE_ID = 11701
Banderilla.OLE_ID = 11704

Banderilla.Defaults = {}
Banderilla.Defaults.Pos = {
    X = 470,
    Y = 30
}

function BANDERILLA_ON_INIT(addon, frame)
    Banderilla.addon = addon;
    Banderilla.frame = frame;

    if not Banderilla.Loaded then
        local t, err = acutil.loadJSON(Banderilla.SettingsFileLoc, Banderilla.Defaults);
        if err then
            Banderilla.Settings = Banderilla.Defaults
            Banderilla.Loaded = true;
        else
            Banderilla.Settings = t;
            Banderilla.Loaded = true;
        end
    end
    frame:ShowWindow(0)

    frame:Move(Banderilla.Settings.Pos.X, Banderilla.Settings.Pos.Y);
    frame:SetOffset(Banderilla.Settings.Pos.X, Banderilla.Settings.Pos.Y);

    addon:RegisterMsg('BUFF_REMOVE', 'BANDERILLA_ON_BUFF_REMOVE');
    addon:RegisterMsg('TARGET_BUFF_ADD', 'BANDERILLA_ON_TARGET_BUFF_ADD');
    addon:RegisterMsg('TARGET_BUFF_UPDATE', 'BANDERILLA_ON_TARGET_BUFF_UPDATE');
end

-- 반대릴라 게이지 ui 위치 저장
function BANDERILLA_LBTN_UP(frame, msg, argStr, argNum)
    if not Banderilla.Loaded then
        local t, err = acutil.loadJSON(Banderilla.SettingsFileLoc, Banderilla.Defaults);
        if err then
            Banderilla.Settings = Banderilla.Defaults
            Banderilla.Loaded = true;
        else
            Banderilla.Settings = t;
            Banderilla.Loaded = true;
        end
    end
    local X = frame:GetX();
    local Y = frame:GetY();
    Banderilla.Settings.Pos.X = X;
    Banderilla.Settings.Pos.Y = Y;
    acutil.saveJSON(Banderilla.SettingsFileLoc, Banderilla.Settings)
end

-- 본인의 반데릴라 버프가 소모됐을때
function BANDERILLA_ON_BUFF_REMOVE(frame, msg, argStr, argNum)
    if (argNum == Banderilla.BUFF_ID) then
        -- 0.01초 기달렸다가 시도, pvp에서는 딜레이가 있는듯
        ReserveScript("BANDERILLA_MESSAGE_HANDLER()", 0.01)
    end
end

-- 현 타겟의 버프가 업데이트 됐을때
function BANDERILLA_ON_TARGET_BUFF_UPDATE(frame, timer, argstr, argNum, passedtime)
    if (argNum == Banderilla.DEBUFF_ID) then
        Banderilla:ProcessBanderillaDebuff(frame)
    end
end

-- 현 타겟의 버프가 추가 됐을때
function BANDERILLA_ON_TARGET_BUFF_ADD(frame, msg, argStr, argNum)
    if (argNum == Banderilla.DEBUFF_ID) then
        Banderilla:ProcessBanderillaDebuff(frame)
    end
end

function BANDERILLA_MESSAGE_HANDLER()
    Banderilla:ProcessBanderillaDebuff(Banderilla.frame)
end

-- 반데릴라 애드온 실행
function Banderilla.ProcessBanderillaDebuff(self, frame)
    local target = session.GetTargetHandle();
    -- 현 타겟의 반데릴라 디버프 확인
    local buff = Banderilla:GetBanderillaDebuff(target);
    -- 현 타겟이 반데릴라 디버프가 없을때 주변 몬스터들에게 반데릴라 디버프 확인
    if (buff == nil) then
        buff = Banderilla:FindNearbyDebuffTarget()
    end
    -- 반데릴라 디버프가 있는 타겟을 찾았고 내 케릭터의 반데릴라 효과일경우 (파티원 반데릴라 효과 걸러내기)
    if (buff ~= nil and buff:GetHandle() == session.GetMyHandle()) then
        local gauge = GET_CHILD_RECURSIVELY(frame, 'banderillaGauge');
        local caption = GET_CHILD_RECURSIVELY(frame, 'infoText');
        -- 현 반데릴라 중첩에 비례해 게이지 색상과 텍스트 변경
        if (buff.over == 3) then
            gauge:SetSkinName("banderilla_gauge_green");
        elseif (buff.over == 2) then
            gauge:SetSkinName("banderilla_gauge_orange");
        else
            gauge:SetSkinName("banderilla_gauge_yellow");
        end
        caption:SetText(string.format("{@st42}반데릴라 지속 %d단{/}", buff.over))
        -- 타이머 시작
        local __timer = frame:GetChild("debufftimer");
        local timer = tolua.cast(__timer, "ui::CAddOnTimer");
        timer:Stop();
        timer:SetUpdateScript("BANDERILLA_ON_TIMER_UPDATE");
        timer:Start(0.1);
        frame:ShowWindow(1);
    end
end

-- 타이머 틱
function BANDERILLA_ON_TIMER_UPDATE(frame)
    -- 타겟의 반데릴라 디버프 확인
    local buff = Banderilla:GetBanderillaDebuff(session.GetTargetHandle())
    -- 타겟에 반데릴라 디버프가 없을경우 주변 몬스터의 반데릴라 중첩 확인
    if (buff == nil) then
        buff = Banderilla:FindNearbyDebuffTarget()
    end
    -- 내 캐릭터가 묻힌 반데릴라 디버프일경우
    if (buff ~= nil and buff:GetHandle() == session.GetMyHandle()) then
        local time = buff.time
        local gauge = GET_CHILD_RECURSIVELY(frame, 'banderillaGauge');
        -- 게이지 수치 업데이트
        gauge:SetPoint((time / 1000), 10);
    else
        -- 주변에 반데릴라 적용된 몹이 아예 없을시 게이지 숨기고 타이머 실행 중지
        local __timer = frame:GetChild("debufftimer");
        local timer = tolua.cast (__timer, "ui::CAddOnTimer");
        timer:Stop()
        frame:ShowWindow(0);
    end
end

local lastSeenIndex = -1

-- 본인이 시전한 반데릴라 디버프 찾아봄
function Banderilla.GetBanderillaDebuff(self, handle)
    -- 일단 있는지 없는지 확인
    local buff = info.GetBuff(handle, Banderilla.DEBUFF_ID)
    if (buff == nil) then
        return
    end
    local myHandle = session.GetMyHandle()
    local casterHandle = buff:GetHandle();
    -- 만약 본인의 반데릴라 디버프라면 이걸로 선택
    if (casterHandle == myHandle) then
        lastSeenIndex = buff.index
        return buff
    end
    -- 만약 본인의 반데릴라가 아니였다면 (반데 유저가 본인 외에도 있을때)
    -- 이전에 찾아둔 반데 디버프 아이디가 있다면 그거 써서 찾아봄
    if (lastSeenIndex > -1) then
        buff = info.GetBuff(handle, Banderilla.DEBUFF_ID, lastSeenIndex)
        if (buff ~= nil) then
            -- 이게 맞다면 선택
            return buff
        end
    end
    -- 만약 이전에 찾아뒀던 반데 아이디로도 본인의 반데 디버프를 못찾았다면...
    -- 디버프 찾기 시작
    if (buff == nil or lastSeenIndex == -1) then
        -- 적의 모든 버프 확인
        local buffCount = info.GetBuffCount(handle);
        for i = 0, buffCount - 1 do
            local targetBuff = info.GetBuffIndexed(handle, i);
            if targetBuff ~= nil then
                -- 버프가 반데릴라라면
                if (targetBuff.buffID == Banderilla.DEBUFF_ID) then
                    local targetBuffCaster = targetBuff:GetHandle();
                    -- 시전자가 본인이라면
                    if (targetBuffCaster == myHandle) then
                        lastSeenIndex = targetBuff.index
                        return targetBuff
                    end
                end
            end
        end
    end
end

function Banderilla.FindNearbyDebuffTarget(self)
    local list, count = SelectObject(GetMyPCObject(), 500, 'ENEMY')
    for i = 1, count do
        local handle = GetHandle(list[i])
        local buff = info.GetBuff(handle, Banderilla.DEBUFF_ID)
        -- 만약 반데 버프가 있다면
        if (buff ~= nil) then
            -- 본인이 시전한것인지 확인
            buff = Banderilla:GetBanderillaDebuff(handle)
            if (buff ~= nil) then
                -- 맞다면 그걸로 선택
                return buff
            end
        end
    end
    return nil
end