-- areas defined
local author = 'meldavy'
local addonName = 'infernalshadow'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

CHAT_SYSTEM("/infernal 혹은 /인퍼널 명령어로 인퍼널 섀도우 애드온 설정 확인하세요!")
-- get a pointer to the area
local InfernalShadow = _G['ADDONS'][author][addonName]
local acutil = require('acutil')

local infernalshadowid = 21613
local infernalshadowdebuffid = 2201
local infernalshadowhandle = -1
local infernalshadowsearchlock = 0
local testbox = {
    {0, 0, 0},
    {0, 5, 0},
    {0, 10, 0},
    {0, 15, 0},
    {0, 25, 0},
    {0, 35, 0},
    {0, 45, 0},
    {0, 55, 0},
}
local firstpos = nil
function INFERNALSHADOW_ON_INIT(addon, frame)
    InfernalShadow.addon = addon;
    InfernalShadow.frame = frame;

    -- 스킬 사용 훅
    acutil.setupHook(INFERNALSHADOW_USE_SKILL, 'QUICKSLOTNEXPBAR_SLOT_USE');
    -- 타겟 변경
    addon:RegisterMsg('TARGET_SET', 'INFERNALSHADOW_ON_TARGET_SET');
    addon:RegisterMsg('TARGET_UPDATE', 'INFERNALSHADOW_ON_TARGET_UPDATE');
end

-- 인퍼널 섀도우로 타겟이 변경 완료 확인시 실행 멈춤
function INFERNALSHADOW_ON_TARGET_SET(msgFrame, msg, argStr)
    local handle = session.GetTargetHandle();
    if handle == infernalshadowhandle or infernalshadowhandle > 0 then
        END_INFERNAL_TARGET_SEARCH_ACTIVITY()
    end
end

-- 인퍼널 섀도우로 타겟이 변경 완료 확인시 실행 멈춤
function INFERNALSHADOW_ON_TARGET_UPDATE(msgFrame, msg, argStr, argNum)
    local handle = session.GetTargetHandle();
    if handle == infernalshadowhandle or infernalshadowhandle > 0 then
        END_INFERNAL_TARGET_SEARCH_ACTIVITY()
    end
end

-- 인퍼널 섀도우 사용 확인
function INFERNALSHADOW_USE_SKILL(frame, slot, argStr, argNum)
    local icon = slot:GetIcon();
    if icon ~= nil then
        local iconInfo = icon:GetInfo();
        if iconInfo:GetCategory() == 'Skill' then
            if (iconInfo.type == infernalshadowid) then
                -- 인퍼널 사용 확인 완료
                InfernalShadow:ProcessInfernalShadow()
            end
        end
    end
    QUICKSLOTNEXPBAR_SLOT_USE_OLD(frame, slot, argStr, argNum)
end

function InfernalShadow.ProcessInfernalShadow(self)
    local list, count = SelectObject(GetMyPCObject(), 10000, 'ALL')
    for i = 1, count do
        local handle = GetHandle(list[i])
        -- 주변 오브젝트가 인퍼널섀도우인지 확인
        if (InfernalShadow:IsInfernalShadow(handle)) then
            infernalshadowhandle = handle
            -- 이미 타겟이 인퍼널 섀도우인지 확인
            if (session.GetTargetHandle() ~= handle) then
                firstpos = {mouse.GetX(), mouse.GetY()}
                -- 인퍼널 타겟 찾기 작업이 진행중일땐 실행 하지 말것
                if infernalshadowsearchlock == 0 then
                    infernalshadowsearchlock = 1
                    -- 찾기 과정 실행
                    BEGIN_INFERNAL_TARGET_SEARCH_ACTIVITY()
                else
                    return
                end
            else
                -- 만약 이미 타겟이라면 애드온 실행 취소
                END_INFERNAL_TARGET_SEARCH_ACTIVITY()
            end
            return
        end
    end
    -- 주변에 인퍼널 섀도우가 없다면 실행 취소
    END_INFERNAL_TARGET_SEARCH_ACTIVITY()
end

function BEGIN_INFERNAL_TARGET_SEARCH_ACTIVITY()
    if (session.GetTargetHandle() == infernalshadowhandle or infernalshadowhandle < 0) then
        -- short circuit
        END_INFERNAL_TARGET_SEARCH_ACTIVITY()
        return
    end
    -- enhancedtargetlock 에서 따온 코드, 인퍼널 위치로 마우스 고정 후, 마우스모드로 전환
    local handle = infernalshadowhandle
    session.config.SetMouseMode(true)
    mouse.SetHidable(0);
    local cur = testbox[1]
    local targetactor = world.GetActor(handle)
    local pos = targetactor:GetPos()
    local pts = world.ToScreenPos(pos.x + cur[1], pos.y + cur[2], pos.z + cur[3]);
    local crx = pts.x
    local cry = pts.y
    if (option.GetClientWidth() >= 3000) then
        --4k対応
        crx = crx * 2
        cry = cry * 2
    end

    --ensure
    if (crx >= 0 and cry >= 0 and crx < option.GetClientWidth() and cry < option.GetClientHeight()) then
        mouse.SetPos(crx, cry)
        if infernalshadowsearchlock == 1 then
            ReserveScript("BEGIN_INFERNAL_TARGET_SEARCH_ACTIVITY()", 0.01)
        end
    else
    end
end

function END_INFERNAL_TARGET_SEARCH_ACTIVITY()
    -- 끝났다면 다시 키보드모드로 전환, 함수들 리셋
    if (infernalshadowsearchlock == 1) then
        infernalshadowsearchlock = 0
        mouse.SetPos(firstpos[1], firstpos[2]);
    end
    session.config.SetMouseMode(false)
    mouse.SetHidable(0);
    infernalshadowhandle = -1
end

function InfernalShadow.IsInfernalShadow(self, handle)
    local buff = info.GetBuff(handle, infernalshadowdebuffid)
    if buff == nil then
        return false
    else
        return true
    end
end
