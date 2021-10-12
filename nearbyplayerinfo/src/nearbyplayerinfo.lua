--dofile("../data/addon_d/nearbyplayerinfo/nearbyplayerinfo.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'nearbyplayerinfo'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local NearbyPlayerInfo = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

local seenMembers = {}
local playerDetails = {}

NearbyPlayerInfo.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

NearbyPlayerInfo.Settings = {
    Visible = 1,
    Position = {
        X = 400,
        Y = 400
    },
    ExtraRows = 0
};

NearbyPlayerInfo.Default = {
    MaxRows = 10,
    RowHeight = 26,
    Width = 350,
    Height = 250,
    IsVisible = 1,
    Movable = 1,
    Enabled = 1, -- Hittest
};

function NEARBYPLAYERINFO_ON_INIT(addon, frame)
    NearbyPlayerInfo.addon = addon;
    NearbyPlayerInfo.frame = frame;
    -- load settings
    if not NearbyPlayerInfo.Loaded then
        local t, err = acutil.loadJSON(NearbyPlayerInfo.SettingsFileLoc, NearbyPlayerInfo.Settings);
        if err then
        else
            NearbyPlayerInfo.Settings = t;
            NearbyPlayerInfo.Loaded = true;
        end
    end
    if (NearbyPlayerInfo.Settings.ExtraRows == nil) then
        NearbyPlayerInfo.Settings.ExtraRows = 0
    end

    seenMembers = {}
    playerDetails = {}
    acutil.slashCommand('/nearbyplayers', NEARBYPLAYERINFO_PROCESS_COMMAND)
    acutil.slashCommand('/np', NEARBYPLAYERINFO_PROCESS_COMMAND)
    NearbyPlayerInfo.SetupHook(NEARBYPLAYERINFO_ON_PC_COMPARE, "SHOW_PC_COMPARE")

    -- initialize frame
    NEARBYPLAYERINFO_ON_FRAME_INIT(frame)
end

function NEARBYPLAYERINFO_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(NearbyPlayerInfo.Default.Movable);
    frame:EnableHitTest(NearbyPlayerInfo.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "NEARBYPLAYERINFO_END_DRAG");

    -- draw the frame
    frame:SetSkinName('chat_window_2');

    -- set default position of frame
    frame:Move(NearbyPlayerInfo.Settings.Position.X, NearbyPlayerInfo.Settings.Position.Y);
    frame:SetOffset(NearbyPlayerInfo.Settings.Position.X, NearbyPlayerInfo.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(NearbyPlayerInfo.Default.Width, NearbyPlayerInfo.Default.Height + (NearbyPlayerInfo.Settings.ExtraRows * NearbyPlayerInfo.Default.RowHeight));
    frame:ShowWindow(NearbyPlayerInfo.Settings.Visible);

    -- controls
    local title = frame:CreateOrGetControl("richtext", "title", NearbyPlayerInfo.Default.Width - 20, 20, ui.LEFT, ui.TOP, 10, 10, 0, 0);
    title:SetFontName("white_16_ol")
    title:SetText("/nearbyplayers")
    title:EnableHitTest(0)
    local expandButton = frame:CreateOrGetControl("button", "expandBtn", 30, 30, ui.RIGHT, ui.TOP, 0, 5, 40, 0);
    expandButton:SetFontName("white_16_ol")
    expandButton:SetText("+")
    expandButton:EnableHitTest(1)
    expandButton:SetTextTooltip("크기 증가")
    expandButton:SetEventScript(ui.LBUTTONUP, "NEARBYPLAYERINFO_EXPAND_ROW");
    local contractButton = frame:CreateOrGetControl("button", "contractBtn", 30, 30, ui.RIGHT, ui.TOP, 0, 5, 5, 0);
    contractButton:SetFontName("white_16_ol")
    contractButton:SetText("-")
    contractButton:EnableHitTest(1)
    contractButton:SetTextTooltip("크기 축소")
    contractButton:SetEventScript(ui.LBUTTONUP, "NEARBYPLAYERINFO_CONTRACT_ROW");

    local pclist = frame:CreateOrGetControl("groupbox", "pclist", NearbyPlayerInfo.Default.Width - 15, (NearbyPlayerInfo.Default.Height - 50) + (NearbyPlayerInfo.Settings.ExtraRows * NearbyPlayerInfo.Default.RowHeight), ui.LEFT, ui.TOP, 10, 40, 0, 0);
    AUTO_CAST(pclist)
    pclist:EnableScrollBar(1);
    -- pclist:EnableHitTest(1);
    ReserveScript("NEARBYPLAYERINFO_ON_TICK()", 1)
    frame:RunUpdateScript("NEARBYPLAYERINFO_ON_TICK", 3)
end

function NEARBYPLAYERINFO_EXPAND_ROW(frame)
    if (NearbyPlayerInfo.Settings.ExtraRows < NearbyPlayerInfo.Default.MaxRows) then
        NearbyPlayerInfo.Settings.ExtraRows = NearbyPlayerInfo.Settings.ExtraRows + 1
        frame:Resize(NearbyPlayerInfo.Default.Width, NearbyPlayerInfo.Default.Height + (NearbyPlayerInfo.Settings.ExtraRows * NearbyPlayerInfo.Default.RowHeight));
        local pclist = frame:GetChild("pclist")
        pclist:Resize(NearbyPlayerInfo.Default.Width - 15, (NearbyPlayerInfo.Default.Height - 50) + (NearbyPlayerInfo.Settings.ExtraRows * NearbyPlayerInfo.Default.RowHeight));
        NEARBYPLAYERINFO_SAVE_SETTINGS()
    end
end
function NEARBYPLAYERINFO_CONTRACT_ROW(frame)
    if (NearbyPlayerInfo.Settings.ExtraRows > 0) then
        NearbyPlayerInfo.Settings.ExtraRows = NearbyPlayerInfo.Settings.ExtraRows - 1
        frame:Resize(NearbyPlayerInfo.Default.Width, NearbyPlayerInfo.Default.Height + (NearbyPlayerInfo.Settings.ExtraRows * NearbyPlayerInfo.Default.RowHeight));
        local pclist = frame:GetChild("pclist")
        pclist:Resize(NearbyPlayerInfo.Default.Width - 15, (NearbyPlayerInfo.Default.Height - 50) + (NearbyPlayerInfo.Settings.ExtraRows * NearbyPlayerInfo.Default.RowHeight));
        NEARBYPLAYERINFO_SAVE_SETTINGS()
    end
end


function NEARBYPLAYERINFO_ON_TICK(frame)
    NearbyPlayerInfo:FindNearbyObjects()
    return 1
end

function NearbyPlayerInfo.FindNearbyObjects(self)
    local myHandle = session.GetMyHandle()
    local frame = ui.GetFrame('nearbyplayerinfo')
    local groupbox = frame:GetChildRecursively('pclist')
    groupbox:RemoveAllChild()
    local objList, objCount = SelectObject(GetMyActor(), 10000, 'ALL')
    local handles = {}
    for i = 1, objCount do
        local targetHandle = GetHandle(objList[i])
        if (objList[i].ClassName == 'PC') then
            local pchud = ui.GetFrame('charbaseinfo1_' .. targetHandle);
            if (pchud ~= nil) then
                if (targetHandle ~= myHandle) then
                    table.insert(handles, targetHandle)
                end
            end
        end
    end

    table.sort(handles, function(a, b)
        local hud_a = ui.GetFrame('charbaseinfo1_' .. a);
        local hud_b = ui.GetFrame('charbaseinfo1_' .. b);
        if (hud_a ~= nil and hud_b ~= nil) then
            local name_a_control = hud_a:GetChildRecursively('guildName')
            local name_b_control = hud_b:GetChildRecursively('guildName')
            if (name_a_control ~= nil and name_b_control ~= nil) then
                local name_a = name_a_control:GetText()
                local name_b = name_b_control:GetText()
                if (name_a == 'None') then
                    name_a = ""
                end
                if (name_b == 'None') then
                    name_b = ""
                end
                return name_a > name_b
            end
        end
        return true
    end)

    for k, targetHandle in pairs(handles) do
        NearbyPlayerInfo:DrawUserInfo(targetHandle)
        if (playerDetails[targetHandle] == nil) then
            -- only make network call if we haven't already memberinfo'd this player
            local cid = info.GetCID(targetHandle);
            seenMembers[cid] = 1
            ui.PropertyCompare(targetHandle, 1);
        end
    end
end

function NEARBYPLAYERINFO_ON_PC_COMPARE(cid)
    NearbyPlayerInfo.ProcessPCCompare(cid)
end

function NearbyPlayerInfo.ProcessPCCompare(cid)
    if (seenMembers[cid] == nil) then
        base["SHOW_PC_COMPARE"](cid)
        return
    end
    seenMembers[cid] = nil
    local otherpcinfo = session.otherPC.GetByStrCID(cid);
    NearbyPlayerInfo:DrawAdditionalInfo(otherpcinfo)
end

function NearbyPlayerInfo.DrawUserInfo(self, handle)
    local emblemFolderPath = filefind.GetBinPath("GuildEmblem"):c_str()

    local frame = ui.GetFrame('nearbyplayerinfo')
    local groupbox = frame:GetChildRecursively('pclist')
    -- local targetName = info.GetFamilyName(targetHandle);

    local actor = world.GetActor(handle)
    local targetName = info.GetFamilyName(handle);
    local targetInfo = info.GetTargetInfo(handle);
    --local otherpcinfo = session.otherPC.GetByFamilyName(targetName);

    -- get the hud of PC to get guild data
    local pchud = ui.GetFrame('charbaseinfo1_' .. handle);
    -- check to see if we already have an entry for this player
    local pcinfo = groupbox:CreateOrGetControl("groupbox", "pcinfo_" .. handle, NearbyPlayerInfo.Default.Width - 15, NearbyPlayerInfo.Default.RowHeight, ui.LEFT, ui.TOP, 0, ((groupbox:GetChildCount() - 1) * 22), 0, 0);
    if (pchud ~= nil) then
        AUTO_CAST(pcinfo)
        pcinfo:SetEventScript(ui.LBUTTONUP, "NEARBYPLAYERINFO_MEMBERINFO");
        pcinfo:SetEventScriptArgNumber(ui.LBUTTONUP, handle);
        pcinfo:EnableScrollBar(0)
        pcinfo:SetTextTooltip("클릭하여 {#fad014}" .. targetName .. "{/} 인포 보기");

        -- set name
        local pcname = pcinfo:CreateOrGetControl("richtext", "pcname",  145, 20, ui.LEFT, ui.TOP, 25, 3, 0, 0);
        pcname:EnableHitTest(0)
        pcname:SetFontName("white_16_ol");
        pcname:SetText(targetName)

        -- joblist control
        local joblist = pcinfo:CreateOrGetControl("richtext", "joblist",  100, 20, ui.LEFT, ui.TOP, 180, 0, 0, 0);
        joblist:EnableHitTest(0)
        joblist:SetFontName("white_16_ol")
        if (playerDetails[handle] ~= nil) then
            joblist:SetText(tostring(playerDetails[handle].Job))
            joblist:SetText(tostring(playerDetails[handle].Job))
        end

        -- create or update guild emblem
        local emblem = pcinfo:CreateOrGetControl("picture", "guildemblem",  23, 23, ui.LEFT, ui.TOP, 0, 0, 0, 0);
        AUTO_CAST(emblem)
        local guildName = pchud:GetChildRecursively('guildName'):GetText()
        emblem:SetTextTooltip(guildName)
        if (guildName ~= 'None') then
            local guildImage = pchud:GetChildRecursively('guildEmblem')
            AUTO_CAST(guildImage)
            local imageName = guildImage:GetImageName()
            local emblemFileName = emblemFolderPath .. "\\" .. imageName
            emblem:SetEnableStretch(1);
            emblem:SetFileName(emblemFileName)
        end
    end
end

function NearbyPlayerInfo.DrawAdditionalInfo(self, otherinfo)
    local targetHandle = otherinfo:GetHandleVal();
    local frame = ui.GetFrame('nearbyplayerinfo')
    local groupbox = frame:GetChildRecursively('pclist')

    -- get the hud of PC to get guild data
    local pchud = ui.GetFrame('charbaseinfo1_' .. targetHandle);
    local jobStr = NearbyPlayerInfo:GenerateJobStr(otherinfo)
    if (playerDetails[targetHandle] == nil) then
        playerDetails[targetHandle] = {}
    end
    playerDetails[targetHandle].Job = jobStr

    -- check to see if we already have an entry for this player
    local pcinfo = groupbox:GetChild("pcinfo_" .. targetHandle)
    if (pchud ~= nil and pcinfo ~= nil) then
        local joblist = pcinfo:GetChild("joblist");
        joblist:SetText(jobStr)
    end
end

function NearbyPlayerInfo.GenerateJobStr(self, otherpcinfo)
    local handle = otherpcinfo:GetHandleVal()
    local namestr = ""
    for i = 0, otherpcinfo:GetJobCount()-1 do
        local jobinfo = otherpcinfo:GetJobInfoByIndex(i);
        local iconName = GET_JOB_ICON(jobinfo.jobID)
        namestr = namestr .. "{img " .. iconName .. " 28 28}"
    end
    return namestr
end

function NEARBYPLAYERINFO_PROCESS_COMMAND(command)
    local isVisible = ui.GetFrame('nearbyplayerinfo'):IsVisible()
    ui.ToggleFrame('nearbyplayerinfo')
    if (isVisible == 1) then
        NearbyPlayerInfo.Settings.Visible = 0
    else
        NearbyPlayerInfo.Settings.Visible = 1
    end
    NEARBYPLAYERINFO_SAVE_SETTINGS()
end

function NEARBYPLAYERINFO_MEMBERINFO(frame, ctrl, argStr, handle)
    ui.PropertyCompare(handle, 1);
end

function NEARBYPLAYERINFO_END_DRAG(frame, ctrl)
    NearbyPlayerInfo.Settings.Position.X = NearbyPlayerInfo.frame:GetX();
    NearbyPlayerInfo.Settings.Position.Y = NearbyPlayerInfo.frame:GetY();
    NEARBYPLAYERINFO_SAVE_SETTINGS();
end

function NEARBYPLAYERINFO_SAVE_SETTINGS()
    acutil.saveJSON(NearbyPlayerInfo.SettingsFileLoc, NearbyPlayerInfo.Settings);
end

function NearbyPlayerInfo.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end