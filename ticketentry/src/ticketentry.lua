--dofile("../data/addon_d/ticketentry/ticketentry.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'ticketentry'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local TicketEntry = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

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

TicketEntry.CHALLENGE_TICKETS = {
    [11030080] = 1,
    [490363] = 1,
    [641953] = 1,
    [641963] = 1,
    [10000416] = 1,
    [641954] = 1,
    [641955] = 1,
    [641969] = 1,
}

TicketEntry.DIVISION_TICKETS = {
    [11030017] = 1,
    [11030021] = 1,
    [11030067] = 1,
    [10000470] = 1,
}

function TICKETENTRY_ON_INIT(addon, frame)
    TicketEntry.addon = addon;
    TicketEntry.frame = frame;

    TicketEntry.SetupHook(TICKETENTRY_ICON_USE, 'ICON_USE');
    TicketEntry.SetupHook(TICKETENTRY_INVENTORY_RBDC_ITEMUSE, 'INVENTORY_RBDC_ITEMUSE');
end

-- 핫키 슬롯 사용
function TICKETENTRY_ICON_USE(object, reAction)
    TicketEntry.ItemUse(object, reAction)
end

function TicketEntry.ItemUse(object, reAction)
    local indenEnterFrame = ui.GetFrame("indunenter");
    if (indenEnterFrame ~= nil and indenEnterFrame:IsVisible() == 1) then
        -- 이미 인던창이 열려있다면 아이템 사용
        base["ICON_USE"](object, reAction)
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
                    else

                    end
                end
            end
        end
    end
    base["ICON_USE"](object, reAction)
end

-- 인벤토리 아이템 사용
function TICKETENTRY_INVENTORY_RBDC_ITEMUSE(frame, object, argStr, argNum)
    TicketEntry.InventoryRBDCItemUse(frame, object, argStr, argNum)
end

function TicketEntry.InventoryRBDCItemUse(frame, object, argStr, argNum)
    local indenEnterFrame = ui.GetFrame("indunenter");
    if (indenEnterFrame ~= nil and indenEnterFrame:IsVisible() == 1) then
        -- 이미 인던창이 열려있다면 아이템 사용
        base["INVENTORY_RBDC_ITEMUSE"](frame, object, argStr, argNum)
        return;
    end
    local warehouseFrame = ui.GetFrame("accountwarehouse");
    if (warehouseFrame ~= nil and warehouseFrame:IsVisible() == 1) then
        -- 창고가 열려있다면 창고에 넣어줌
        base["INVENTORY_RBDC_ITEMUSE"](frame, object, argStr, argNum)
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
        elseif (TicketEntry:IsChallengeTicket(invItem) == 1) then
            -- 첼초권
            local frame = ui.GetFrame("ticketentry");
            frame:SetPos(mouse.GetX() - 105, mouse.GetY() - 35);
            frame:Resize(220, 70);
            local chal1 = frame:CreateOrGetControl("button", "chal1", 66, 66, ui.LEFT, ui.TOP, 2, 2, 0, 0);
            chal1:SetText("Lv 400{nl}1인 입장")
            chal1:SetEventScript(ui.LBUTTONUP, "TICKET_ENTRY_CHALLENGE_ENTER");
            chal1:SetEventScriptArgNumber(ui.LBUTTONUP, 644);

            local chal2 = frame:CreateOrGetControl("button", "chal2", 66, 66, ui.LEFT, ui.TOP, 74, 2, 0, 0);
            chal2:SetText("Lv 440{nl}1인 입장")
            chal2:SetEventScript(ui.LBUTTONUP, "TICKET_ENTRY_CHALLENGE_ENTER");
            chal2:SetEventScriptArgNumber(ui.LBUTTONUP, 645);

            local chal3 = frame:CreateOrGetControl("button", "chal3", 66, 66, ui.LEFT, ui.TOP, 146, 2, 0, 0);
            chal3:SetText("Lv 440{nl}자동 매칭")
            chal3:SetEventScript(ui.LBUTTONUP, "TICKET_ENTRY_CHALLENGE_ENTER");
            chal3:SetEventScriptArgNumber(ui.LBUTTONUP, 646);

            frame:ShowWindow(1);
            return;
        elseif (TicketEntry:IsDivisionTicket(invItem) == 1) then
            ReqChallengeAutoUIOpen(647);
            return;
        end
    end
    base["INVENTORY_RBDC_ITEMUSE"](frame, object, argStr, argNum)
end

function ON_TICKET_ENTRY_ON_LOST_FOCUS(frame)
    frame:ShowWindow(0);
end

function TICKET_ENTRY_CHALLENGE_ENTER(frame, ctrl, argStr, argNum)
    frame:ShowWindow(0);
    local contentID = argNum
    ReqChallengeAutoUIOpen(contentID);
end

-- 분열권
function TicketEntry.IsDivisionTicket(self, invItem)
    local cls = invItem.type
    return TicketEntry.DIVISION_TICKETS[cls]
end

-- 첼초권
function TicketEntry.IsChallengeTicket(self, invItem)
    local cls = invItem.type
    return TicketEntry.CHALLENGE_TICKETS[cls]
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

function TicketEntry.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end