-- areas defined
local author = 'meldavy'
local addonName = 'bettercrossguard'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local BetterCrossguard = _G['ADDONS'][author][addonName]
local acutil = require('acutil')

BetterCrossguard.CROSSGUARD_ID = 150
BetterCrossguard.CROSSGUARD_DEBUFF_ID = 203

function BETTERCROSSGUARD_ON_INIT(addon, frame)
    BetterCrossguard.addon = addon;
    BetterCrossguard.frame = frame;

    addon:RegisterMsg('TARGET_BUFF_ADD', 'CROSSGUARD_ON_TARGET_BUFF_ADD');
    addon:RegisterMsg('TARGET_BUFF_UPDATE', 'CROSSGUARD_ON_TARGET_BUFF_UPDATE');
end

function CROSSGUARD_ON_TARGET_BUFF_UPDATE(frame, timer, argstr, argNum, passedtime)
    if (BetterCrossguard:IsCrossguard()) then
        BetterCrossguard:PlayEffectOnCrossguard(argNum)
    end
end

function CROSSGUARD_ON_TARGET_BUFF_ADD(frame, msg, argStr, argNum)
    if (BetterCrossguard:IsCrossguard()) then
        BetterCrossguard:PlayEffectOnCrossguard(argNum)
    end
end

-- 크가 상태 확인
function BetterCrossguard.IsCrossguard(self)
    local handle = session.GetMyHandle()
    local buff = info.GetBuff(handle, self.CROSSGUARD_ID)
    return buff ~= nil
end

function BetterCrossguard.PlayEffectOnCrossguard(self, argNum)
    if argNum == self.CROSSGUARD_DEBUFF_ID then
        local myHandle = session.GetMyHandle()
        local actor = world.GetActor(myHandle)
        local targetHandle = session.GetTargetHandle()
        local target = world.GetActor(targetHandle)
        effect.PlayActorEffect(actor, 'F_warrior_shield002', 'None', 2.0, 15.0)
        effect.PlayActorEffect(actor, "F_sys_expcard_great", 'None', 1.0, 4.0)
        effect.PlayActorEffect(actor, "F_spin019_1", 'None', 1.0, 4.0)
    end
end