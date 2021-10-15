-- areas defined
local author = 'meldavy'
local addonName = 'infernalshadow'
-- 가까운 보스 검색, 그리고 탐색 기능은 https://github.com/ebisuke/TosAddons/tree/master/enhancedtargetlock 에서 따옴
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local InfernalShadow = _G['ADDONS'][author][addonName]
local acutil = require('acutil')

InfernalShadow.SearchForBoss = false

ui.SysMsg("인퍼널 애드온이 작동중입니다. /인퍼널 off 혹은 /infernal off 로 보스 탐색 기능을 해제 할수있습니다.")
CHAT_SYSTEM("인퍼널 애드온이 작동중입니다. /인퍼널 off 혹은 /infernal off 로 보스 탐색 기능을 해제 할수있습니다.")

local infernalshadowskillid = 21613
local infernalshadowdebuffid = 2201
local searchhandle = nil
local infernalshadowsearchlock = 0
local testbox = {
    {0, 0, 0},
    {-12, 0, 0},
    {12, 0, 0},

    {0, 5, 0},
    {-12, 5, 0},
    {12, 5, 0},

    {0, 10, 0},
    {-12, 10, 0},
    {12, 10, 0},
}
local searchattempts = 1
local firstpos = nil
function INFERNALSHADOW_ON_INIT(addon, frame)
    InfernalShadow.addon = addon;
    InfernalShadow.frame = frame;

    -- 스킬 사용 훅
    acutil.setupHook(INFERNALSHADOW_USE_SKILL, 'QUICKSLOTNEXPBAR_SLOT_USE');
    -- 타겟 변경
    addon:RegisterMsg('TARGET_SET', 'INFERNALSHADOW_ON_TARGET_SET');
    addon:RegisterMsg('TARGET_UPDATE', 'INFERNALSHADOW_ON_TARGET_UPDATE');
    -- 명령어
    acutil.slashCommand('/infernal', INFERNALSHADOW_PROCESS_COMMAND)
    acutil.slashCommand('/인퍼널', INFERNALSHADOW_PROCESS_COMMAND)

    local addontimer = frame:CreateOrGetControl("timer", "addontimer", 10, 10);
end

function INFERNALSHADOW_PROCESS_COMMAND(command)
    local cmd = '';
    if #command > 0 then
        cmd = table.remove(command, 1);
    end
    if cmd == 'on' then
        InfernalShadow.SearchForBoss = true
        ui.SysMsg("인퍼널섀도우 보스 탐색 기능 활성화됨")
    elseif cmd == 'off' then
        InfernalShadow.SearchForBoss = false
        ui.SysMsg("인퍼널섀도우 보스 탐색 기능 비활성화됨")
    else
        ui.SysMsg("인퍼널 애드온이 작동중입니다. /인퍼널 off 혹은 /infernal off 로 보스 탐색 기능을 해제 할수있습니다.")
    end
end

-- 인퍼널 섀도우로 타겟이 변경 완료 확인시 실행 멈춤
function INFERNALSHADOW_ON_TARGET_SET(msgFrame, msg, argStr)
    local handle = session.GetTargetHandle();
    -- 타겟이 인퍼널 섀도우던가, 주변에 인퍼널 섀도우가 없을때
    if handle == searchhandle or searchhandle == nil then
        END_INFERNAL_TARGET_SEARCH_ACTIVITY()
    end
end

-- 인퍼널 섀도우로 타겟이 변경 완료 확인시 실행 멈춤
function INFERNALSHADOW_ON_TARGET_UPDATE(msgFrame, msg, argStr, argNum)
    local handle = session.GetTargetHandle();
    if handle == searchhandle or searchhandle == nil then
        END_INFERNAL_TARGET_SEARCH_ACTIVITY()
    end
end

-- 인퍼널 섀도우 사용 확인
function INFERNALSHADOW_USE_SKILL(frame, slot, argStr, argNum)
    local icon = slot:GetIcon();
    if icon ~= nil then
        local iconInfo = icon:GetInfo();
        if iconInfo:GetCategory() == 'Skill' then
            if (iconInfo.type == infernalshadowskillid) then
                -- 인퍼널 사용 확인 완료
                InfernalShadow:ProcessInfernalShadow()
            end
        end
    end
    QUICKSLOTNEXPBAR_SLOT_USE_OLD(frame, slot, argStr, argNum)
end

-- 탐색 실행
function BEGIN_INFERNAL_TARGET_SEARCH_ACTIVITY(frame)
    if (session.GetTargetHandle() == searchhandle or searchhandle == nil) then
        -- short circuit
        END_INFERNAL_TARGET_SEARCH_ACTIVITY()
        return
    end
    -- enhancedtargetlock 에서 따온 코드, 인퍼널 위치로 마우스 고정 시도
    local cur = testbox[searchattempts]
    local targetactor = world.GetActor(searchhandle)
    local pos = targetactor:GetPos()
    local pts = world.ToScreenPos(pos.x + cur[1], pos.y + cur[2], pos.z + cur[3]);
    local crx = pts.x
    local cry = pts.y
    if (option.GetClientWidth() >= 3000) then
        --4k対応
        crx = crx * 2
        cry = cry * 2
    end
    if (crx >= 0 and cry >= 0 and crx < option.GetClientWidth() and cry < option.GetClientHeight()) then
        mouse.SetPos(crx, cry)
    end
    --ensure
    if infernalshadowsearchlock == 1 then
        searchattempts = searchattempts + 1
        -- 횟수 초과시 실행 멈춤
        if (searchattempts > #testbox) then
            END_INFERNAL_TARGET_SEARCH_ACTIVITY()
        end
    end
end

function END_INFERNAL_TARGET_SEARCH_ACTIVITY()
    -- 끝났다면 다시 키보드모드로 전환, 함수들 리셋
    if (infernalshadowsearchlock == 1) then
        infernalshadowsearchlock = 0
        mouse.SetPos(firstpos[1], firstpos[2]);
    end
    local frame = ui.GetFrame("infernalshadow");
    local __timer = frame:GetChild("addontimer");
    local timer = tolua.cast(__timer, "ui::CAddOnTimer");
    timer:Stop();
    session.config.SetMouseMode(false)
    mouse.SetHidable(0);
    searchhandle = nil
    searchattempts = 1
end

function InfernalShadow.ProcessInfernalShadow(self)
    -- 인퍼널 섀도우 검색
    local infernalhandle = InfernalShadow:FindNearbyInfernalShadow()
    if (infernalhandle ~= nil) then
        searchhandle = infernalhandle
    else
        -- 검색 실패시 가장 가까운 보스 검색
        local bosshandle = InfernalShadow:FindNearbyBoss()
        if (bosshandle ~= nil) then
            searchhandle = bosshandle
        end
    end
    -- 검색 성공시
    if (searchhandle ~= nil) then
        -- 현타겟이 탐색 대상이 아니면 실행
        if (session.GetTargetHandle() ~= searchhandle) then
            -- 타겟 탐색 작업이 이미 진행중일땐 중복 실행 방지
            if infernalshadowsearchlock == 0 then
                -- 타겟 탐색 시작
                infernalshadowsearchlock = 1
                firstpos = {mouse.GetX(), mouse.GetY()}
                session.config.SetMouseMode(true)
                mouse.SetHidable(0);
                local frame = ui.GetFrame("infernalshadow");
                local __timer = frame:GetChild("addontimer");
                local timer = tolua.cast(__timer, "ui::CAddOnTimer");
                timer:Stop();
                timer:SetUpdateScript("BEGIN_INFERNAL_TARGET_SEARCH_ACTIVITY");
                timer:Start(0.02);
            else
                -- 이미 탐색 작업중일땐 실행 방지
                return
            end
        else
            -- 이미 타겟이 탐색 대상이라면 실행 중지
            END_INFERNAL_TARGET_SEARCH_ACTIVITY()
        end
        return
    else
        -- 주변에 탐색 대상(인퍼널이나 보스)이 없다면 실행 중지
        END_INFERNAL_TARGET_SEARCH_ACTIVITY()
    end
end

function InfernalShadow.FindNearbyInfernalShadow(self)
    local list, count = SelectObject(GetMyPCObject(), 500, 'ENEMY')
    for i = 1, count do
        local handle = GetHandle(list[i])
        -- 주변 오브젝트가 인퍼널섀도우인지 확인
        if (InfernalShadow:IsInfernalShadow(handle)) then
            return handle
        end
    end
    return nil
end

function InfernalShadow.FindNearbyBoss(self)
    local nearestdistance = 999999999
    local mypos = GetMyActor():GetPos()
    local nearestEnemy = nil
    local objList, objCount = SelectObject(GetMyActor(), 500, 'ENEMY')

    --ボスを検索
    for i = 1, objCount do
        local enemyHandle = GetHandle(objList[i])
        local enemyActor = world.GetActor(enemyHandle)
        local monsterClass = GetClassByType("Monster", enemyActor:GetType());

        if (monsterClass ~= nil) then
            if (monsterClass.MonRank == "Boss") then
                --死んでたら除外
                local stat = info.GetStat(enemyHandle)
                if (stat.HP > 0) then
                    local enemypos = enemyActor:GetPos()
                    --距離を測る
                    local dist = math.sqrt((mypos.x - enemypos.x) ^ 2 + (mypos.z - enemypos.z) ^ 2)
                    if (dist < nearestdistance) then
                        nearestEnemy = enemyHandle
                        nearestdistance = dist
                    end

                end
            end
        end
    end
    return nearestEnemy
end

function InfernalShadow.IsInfernalShadow(self, handle)
    local buff = info.GetBuff(handle, infernalshadowdebuffid)
    if buff == nil then
        return false
    else
        return true
    end
end
