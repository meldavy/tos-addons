-- areas defined
local author = 'meldavy'
local addonName = 'ticketentry'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local TicketEntry = _G['ADDONS'][author][addonName]
local acutil = require('acutil')

TicketEntry.TICKETS = {
    [11030197] = 656, -- 거불 바실리사 입장권
    [11030198] = 656, -- 7일 기간제 바실리사 입장권
    [11030208] = 656, -- 마켓거래 바실리사 입장권
    [10600181] = 656, -- 달토끼 이벤트 바실리사 입장권
    [10600185] = 656, -- 이벤트 바실리사 입장권
    [11030094] = 635, -- 7일 기간제 길티네 입장권
    [11030134] = 635, -- 마켓거래 길티네 입장권
    [11030146] = 635, -- 거불 길티네 입장권
    [10000472] = 635, -- 이벤트 길티네 입장권
    [11030084] = 636, -- 7일 기간제 성물노말 입장권
    [11030117] = 636, -- 마켓거래 성물노말 입장권
    [11030144] = 636, -- 거불 성물노말 입장권
    [10000450] = 636, -- 전야제 성물노말 입장권
    [10000458] = 636, -- 달토끼 성물노말 입장권
    [10000473] = 636, -- 이벤트 성물노말 입장권
    [10000474] = 640, -- 이벤트 성물하드 입장권
    [11030129] = 640, -- 마켓거래 성물하드 입장권
    [11030114] = 640, -- 거불 성물하드 입장권
    [11030090] = 640, -- 7일 기간제 성물하드 입장권
    [689002] = 640,   -- ? 성물하드 입장권
}

function TICKETENTRY_ON_INIT(addon, frame)
    TicketEntry.addon = addon;
    TicketEntry.frame = frame;

    acutil.setupHook(TICKETENTRY_ICON_USE, 'ICON_USE');
    acutil.setupHook(TICKETENTRY_INVENTORY_RBDC_ITEMUSE, 'INVENTORY_RBDC_ITEMUSE');
end

-- 핫키 슬롯 사용
function TICKETENTRY_ICON_USE(object, reAction)
    local indenEnterFrame = ui.GetFrame("indunenter");
    if (indenEnterFrame ~= nil and indenEnterFrame:IsVisible() == 1) then
        -- 이미 인던창이 열려있다면 아이템 사용
        ICON_USE_OLD(object, reAction)
        return;
    end
    if ((TicketEntry:IsTownMap() == true) and (keyboard.IsKeyPressed("LSHIFT") == 1)) then
        -- 마을이고 쉬프트 누른 상태에서 아이템 사용
        if object  ~=  nil then
            local icon = tolua.cast(object, 'ui::CIcon');
            local iconInfo = icon:GetInfo();
            if iconInfo:GetCategory() == 'Item' then
                local invItem = GET_ICON_ITEM(iconInfo);
                if invItem ~= nil then
                    local contentID = TicketEntry:GetContentIDForItem(invItem)
                    if (contentID ~= nil) then
                        -- 성소, 기도소 입장권이면 자동매칭 창 열어줌
                        ReqRaidAutoUIOpen(contentID);
                        return;
                    end
                end
            end
        end
    end
    ICON_USE_OLD(object, reAction)
end

-- 인벤토리 아이템 사용
function TICKETENTRY_INVENTORY_RBDC_ITEMUSE(frame, object, argStr, argNum)
    local indenEnterFrame = ui.GetFrame("indunenter");
    if (indenEnterFrame ~= nil and indenEnterFrame:IsVisible() == 1) then
        -- 이미 인던창이 열려있다면 아이템 사용
        INVENTORY_RBDC_ITEMUSE_OLD(frame, object, argStr, argNum)
        return;
    end
    local invItem = GET_SLOT_ITEM(object);
    if ((invItem ~= nil) and (TicketEntry:IsTownMap() == true) and (keyboard.IsKeyPressed("LSHIFT") == 1)) then
        -- 마을이고 쉬프트 누른 상태에서 아이템 사용
        local contentID = TicketEntry:GetContentIDForItem(invItem)
        if (contentID ~= nil) then
            -- 성소, 기도소 입장권이면 자동매칭 창 열어줌
            ReqRaidAutoUIOpen(contentID);
            return;
        end
    end
    INVENTORY_RBDC_ITEMUSE_OLD(frame, object, argStr, argNum)
end

-- 입장권
function TicketEntry.GetContentIDForItem(self, invItem)
    local cls = invItem.type
    return TicketEntry.TICKETS[cls]
end

-- 마을맵 확인
function TicketEntry.IsTownMap(self)
    local mapProp = session.GetCurrentMapProp()
    local mapCls = GetClassByType('Map', mapProp.type)
    return IS_TOWN_MAP(mapCls)
end