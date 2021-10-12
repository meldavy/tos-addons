-- areas defined
local author = 'meldavy'
local addonName = 'stopnalmuk'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

CHAT_SYSTEM("/nm 혹은 /날먹 명령어로 날먹멈춰 애드온 설정 확인하세요!")
-- get a pointer to the area
local g = _G['ADDONS'][author][addonName]
g.autoBarrackSelect = false
local acutil = require('acutil')
local base = {}
-- 힐러들은 봐주자
local jobWhitelist = {"프리스트", "카발리스트", "팔라딘"}
local accWhitelist = {"카랄", "루시"}
local jobList, jobListCount  = GetClassList("Job");

-- 자동으로 맵이동시 실행되는 멤버인포만 1회 창이 안뜨게끔 관리
local seen = {}
local checkself = false -- 디버그용
local maps = {
    11243  -- 기도소
    --     11230,  -- 길티네 (실험용)
    --     1001,   -- 클페는 실험용
    --     1006    -- 오르샤도 실험용
}

local debugenableallmaps = false -- 실험용, 모든맵에 날먹감지 활성화
local autoBarrackSelect = true -- 날먹 감지시 자동 캐선

-- 인장컷
local sealCeiling = 3
-- 아크컷
local arkCeiling = 3
-- 마젠타컷
local gemCeiling = 2

function STOPNALMUK_ON_INIT(addon, frame)
    g.addon = addon;
    g.frame = frame;
    -- 맵 로딩시 애드온이 실행됩니다
    addon:RegisterMsg('GAME_START_3SEC', 'CHECK_NALMUK_INFO')
    -- 멤버인포 훅
    g.SetupHook(NALMUK_MEMBER_INFO, 'SHOW_PC_COMPARE')
    acutil.slashCommand('/nm', NALMUK_PROCESS_COMMAND)
    acutil.slashCommand('/날먹', NALMUK_PROCESS_COMMAND)
end

function NALMUK_PROCESS_COMMAND(command)
    local cmd = '';
    if #command > 0 then
        cmd = table.remove(command, 1);
    end
    if cmd == 'on' then
        g.autoBarrackSelect = true
        ui.SysMsg("날먹감지 자동캐선설정 활성화됨")
    elseif cmd == 'off' then
        g.autoBarrackSelect = false
        ui.SysMsg("날먹감지 자동캐선설정 비활성화됨")
    else
        ui.SysMsg("/nm 혹은 /날먹 이후 on/off 설정으로 자동 캐선 기능을 설정할수있습니다.")
    end
end

-- 맵 이동시 모든 파티원에게 멤버인포 신청
-- 멤버인포 신청을 해야 파티원들의 장비 데이터가 로딩 됨
function CHECK_NALMUK_INFO(frame)
    -- 자동 멤버인포 목록 초기화
    seen = {}
    -- 성자의 기도소 맵 확인
    local curMapID = session.GetMapID()
    local myAid = session.loginInfo.GetAID();
    if (debugenableallmaps or in_array(curMapID, maps) > -1) then
        -- 파티원 값
        local pcparty = session.party.GetPartyInfo();
        local memberlist = session.party.GetPartyMemberList(PARTY_NORMAL);
        local count = memberlist:Count();
        for i = 0 , count - 1 do
            local partyMemberInfo = memberlist:Element(i);
            local isSelf = (partyMemberInfo:GetAID() == myAid)
            print(tostring(isSelf))
            -- if (partyMemberInfo:GetAID() ~= myAid) then
            -- 파티원 로그인상태 확인
            if (partyMemberInfo:GetMapID() > 0 and not isSelf) then
                -- 파티원 자동 멤버 인포 목록에 등록
                local memberName = partyMemberInfo:GetName();
                table.insert(seen, tostring(memberName))

                local aid = partyMemberInfo:GetAID()
                local handle = partyMemberInfo:GetHandle()
                local otherpcinfo = session.otherPC.GetByStrAID(aid);
                local gender = otherpcinfo:GetIconInfo().gender;
                -- 파티원 직업 확인
                local isWhitelisted = isJobWhitelisted(otherpcinfo, gender);
                if (not isWhitelisted) then
                    -- 힐러가 아닐 시 자동 멤버 인포 실행
                    ui.PropertyCompare(handle, 1);
                end
            end
        end
    end
end

-- 멤버인포 실행시 실행
function NALMUK_MEMBER_INFO(cid)
    g.ProcessMemberInfo(cid)
end

function g.ProcessMemberInfo(cid)
    local otherpcinfo = session.otherPC.GetByStrCID(cid);

    -- 이미 날먹 감지 테스트가 실행됐는지 확인.
    -- 이미 실행이 됐다면 이번 훅 발동은 날먹감지 애드온의 자동 멤버인포 실행이 아닌 유저의 수동 멤버인포
    -- 즉 멤버 인포 창을 띄워줘야한다
    local memberName = otherpcinfo:GetIconInfo():GetFamilyName()
    local seenIndex = in_array(tostring(memberName), seen)
    if (seenIndex == -1) then
        -- 멤버 인포 실행
        base["SHOW_PC_COMPARE"](cid)
        return
    end

    -- 날먹 감지 테스트가 실행이 되지 않았다면 이번 훅 발동은 날먹감지 애드온의 자동 멤버인포 실행이다.
    -- 즉 멤버 인포 창이 안띄워지도록 하고 백그라운드에서 날먹감지 연산을 실행합니다
    table.remove(seen, seenIndex)

    local equiplist = otherpcinfo:GetEquipList();
    local isnalmuk = false
    local reason = ""

    for k = 0, equiplist:Count() - 1 do
        local equipItem = equiplist:GetEquipItemByIndex(k)
        local tempobj = equipItem:GetObject()
        -- 악세사리 확인. 카랄, 루시 이상이여야함미다. 악세 확인은 그래도 어느정도 용서 가능한 날먹이니 확인 안하는걸로...
        --         local check_equip_list_2 = {'RING1', 'RING2', 'NECK'}
        --         if (in_array(item.GetEquipSpotName(equipItem.equipSpot), check_equip_list_2) > -1) then
        --             if tempobj == nil then
        --                 -- 악세 미착용
        --                 isnalmuk = true
        --                 reason = reason .. "악세사리를 착용하고있지 않습니다. "
        --             else
        --                 -- 악세 착용중
        --                 local obj = GetIES(tempobj)
        --                 local accname = obj.Name
        --                 local isAccWhitelisted = false
        --                 for l = 1, #accWhitelist do
        --                     if (accname:find(accWhitelist[l], 1, true)) then
        --                         -- 카랄 혹은 루시
        --                         isAccWhitelisted = true
        --                     end
        --                 end
        --                 if (not isAccWhitelisted) then
        --                     isnalmuk = true
        --                     local message = string.format("[%s] 착용중. ", accname)
        --                     reason = reason .. message
        --                 end
        --             end
        --         else
        -- 착용중인 아크 확인
        if item.GetEquipSpotName(equipItem.equipSpot) == 'ARK' then
            if tempobj == nil then
                -- 아크 미착용
                isnalmuk = true
                reason = reason .. "아크를 착용하고있지 않습니다. "
            else
                -- 아크 착용중
                local obj = GetIES(tempobj)
                local uselv = TryGetProp(obj, 'UseLv', 0)
                if (uselv < 420) then
                    -- 아크 미착용
                    isnalmuk = true
                    reason = reason .. "아크를 착용하고있지 않습니다. "
                else
                    local arklv = TryGetProp(obj, 'ArkLevel', 0)
                    local arkname = obj.Name;
                    if (arklv < arkCeiling) then
                        -- 3레벨 미만이면 아크 효과가 발동도 안되는 레벨입니다. 이새끼는 날먹입니다.
                        isnalmuk = true
                        local message = string.format("[%s] 레벨이 [%d]입니다. ", arkname, arklv)
                        reason = reason .. message
                    end
                end
            end
            -- 착용중인 성물 확인
        elseif item.GetEquipSpotName(equipItem.equipSpot) == 'RELIC' then
            if tempobj == nil then
                -- 성물 미착용
                isnalmuk = true
                reason = reason .. "성물을 착용하고있지 않습니다. "
            else
                -- 성물 착용중
                local obj = GetIES(tempobj)
                local uselv = TryGetProp(obj, 'UseLv', 0)
                if (uselv < 458) then
                    -- 성물 미착용
                    isnalmuk = true
                    reason = reason .. "성물을 착용하고있지 않습니다. "
                else
                    local reliclv = TryGetProp(obj, 'Relic_LV', 0)
                    for _name, _type in pairs(relic_gem_type) do
                        local gem_id = equipItem:GetEquipGemID(_type)
                        local gem_cls = GetClassByType('Item', gem_id)
                        if (_type == 0 and gem_id == 0) then
                            -- 시안젬 미착용. 시안젬을 착용 안하면 해방을 못하니 이새끼 날먹
                            isnalmuk = true
                            reason = reason .. "시안젬을 착용하고있지 않습니다. "
                        elseif(_type == 1 and gem_id == 0) then
                            -- 마젠타젬 미착용. 마젠타젬을 착용 안하면 해방을 못하니 이새끼 날먹
                            isnalmuk = true
                            reason = reason .. "마젠타젬을 착용하고있지 않습니다. "
                        elseif(_type == 1 and gem_id ~= 0) then
                            -- _type == 1은 마젠타젬을 뜻합니다. (시안은0, 블랙은2) gem ~= 0 은 착용 상태를 뜻합니다.
                            -- 마젠타젬 착용중일시 마젠타젬 레벨 확인
                            local gemname = tostring(GET_RELIC_GEM_NAME_WITH_FONT(gem_cls))
                            -- 면류관 레벨이 4 미만이면 뉴비라 가정하고 봐주자. 하지만 면류관렙이 4 이상이지만
                            -- 마젠타 젬 레벨이 2이하면 이새끼는 무조건 날먹입니다
                            local gemlv = equipItem:GetEquipGemLv(_type)
                            if (reliclv > 4 and gemlv < gemCeiling) then
                                isnalmuk = true
                                local message = string.format("[%s] 레벨이 [%d]입니다. ", gemname, gemlv)
                                reason = reason .. message
                            end
                        end
                    end
                end
            end
        elseif item.GetEquipSpotName(equipItem.equipSpot) == 'SEAL' then
            if tempobj == nil then
                -- 인장 미착용
                isnalmuk = true
                reason = reason .. "인장을 착용하고있지 않습니다. "
            else
                -- 인장 착용중
                local obj = GetIES(tempobj)
                local uselv = TryGetProp(obj, 'UseLv', 0)
                if (uselv < 380) then
                    -- 인장 미착용
                    isnalmuk = true
                    reason = reason .. "인장을 착용하고있지 않습니다. "
                else
                    -- 인장 강화 확인
                    local seallv = GET_CURRENT_SEAL_LEVEL(obj)
                    -- 프던 2시간이면 3인장인데 3인장 미만은 무조건 날먹이지~
                    if (seallv < sealCeiling) then
                        isnalmuk = true
                        local message = string.format("[%s] 레벨이 [%d] 입니다. ", obj.Name, seallv)
                        reason = reason .. message
                    end
                end
            end
        end
    end
    if (isnalmuk == true) then
        local nalmukmessage = string.format("[%s] 날먹 검거 완료: %s", memberName, reason)
        CHAT_SYSTEM(nalmukmessage)
        ui.SysMsg(nalmukmessage)
        -- 자동 캐선 설정
        if (g.autoBarrackSelect == true) then
            ui.MsgBox(string.format("날먹러 [%s]님이 검거됐습니다.{nl}탈주하겠습니까?", memberName), 'NALMUK_OUT_PARTY()', 'None')
        end
    end
    -- 혹시라도 버그로 인해 멤버인포 창이 띄워진다면 닫아주자
    ui.CloseFrame('compare')
end

-- 자동 탈주
function NALMUK_OUT_PARTY()
    OUT_PARTY() -- 파탈
    app.GameToBarrack() -- 캐선
end

function isJobWhitelisted(info, gender)
    local jobs = {};
    for j = 0, info:GetJobCount()-1 do
        local tempjobinfo = info:GetJobInfoByIndex(j);
        if jobs[tempjobinfo.jobID] == nil then
            jobs[tempjobinfo.jobID] = 1;
        end
    end
    for jobid, grade in pairs(jobs) do
        local cls = GetClassByTypeFromList(jobList, jobid);
        local jobName = GET_JOB_NAME(cls, gender);
        if (in_array(jobName, jobWhitelist) > -1) then
            return true
        end
    end
    return false
end

function in_array(value, array)
    for index = 1, #array do
        if array[index] == value then
            return index
        end
    end
    return -1
end

function g.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end