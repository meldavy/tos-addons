--dofile("../data/addon_d/autogoddessprotection/autogoddessprotection.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'autogoddessprotection'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local AutoGoddessProtection = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

AutoGoddessProtection.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

AutoGoddessProtection.Settings = {
    Position = {
        X = 400,
        Y = 400
    },
    Enabled = false
};

AutoGoddessProtection.Default = {
    Height = 0,
    Width = 0,
    IsVisible = 0,
    Movable = 1,
    Enabled = 1, -- Hittest
};

function AUTOGODDESSPROTECTION_ON_INIT(addon, frame)
    AutoGoddessProtection.addon = addon;
    AutoGoddessProtection.frame = frame;
    -- load settings
    if not AutoGoddessProtection.Loaded then
        local t, err = acutil.loadJSON(AutoGoddessProtection.SettingsFileLoc, AutoGoddessProtection.Settings);
        if err then
        else
            AutoGoddessProtection.Settings = t;
            AutoGoddessProtection.Loaded = true;
        end
    end
    local state = "OFF";
    if (AutoGoddessProtection.Settings.Enabled == true) then
        state = "ON";
    end
    CHAT_SYSTEM(string.format(AutoGoddessProtection:GetTranslatedString("message"), state));
    -- initialize frame
    AUTOGODDESSPROTECTION_ON_FRAME_INIT(frame);
    addon:RegisterMsg('FIELD_BOSS_WORLD_EVENT_START', 'AUTOGODDESSPROTECTION_START');
    addon:RegisterMsg('FIELD_BOSS_WORLD_EVENT_END', 'AUTOGODDESSPROTECTION_END');
    acutil.slashCommand('/afk', AUTOGODDESSPROTECTION_PROCESS_COMMAND)
end

function AUTOGODDESSPROTECTION_PROCESS_COMMAND()
    if (AutoGoddessProtection.Settings.Enabled == true) then
        AutoGoddessProtection.Settings.Enabled = false;
    else
        AutoGoddessProtection.Settings.Enabled = true;
    end
    local state = "OFF";
    if (AutoGoddessProtection.Settings.Enabled == true) then
        state = "ON";
    end
    ui.SysMsg(string.format(AutoGoddessProtection:GetTranslatedString("message"), state));
    acutil.saveJSON(AutoGoddessProtection.SettingsFileLoc, AutoGoddessProtection.Settings);
end

function AUTOGODDESSPROTECTION_START(frame)
    ReserveScript("GODPROTECTION_DO_OPEN()", 2); -- open god protection after a delay to complete any pre-loading
    ReserveScript("AUTOGODDESSPROTECTION_RUN()", 3); -- invoke
end

function AUTOGODDESSPROTECTION_RUN()
    local frame = ui.GetFrame("godprotection");
    local edit = GET_CHILD_RECURSIVELY(frame, "auto_edit");
    AUTO_CAST(edit);
    edit:SetText(5000);
    local parent = GET_CHILD_RECURSIVELY(frame, "auto_gb");
    local auto_text = GET_CHILD(parent, "auto_text");
    auto_text:ShowWindow(0);
    local btn = GET_CHILD_RECURSIVELY(frame, "auto_btn");
    GODPROTECTION_AUTO_START_BTN_CLICK(parent, btn);
end

function AUTOGODDESSPROTECTION_END(frame)
    local frame = ui.GetFrame("godprotection");
    GODPROTECTION_CLOSE(frame);
    -- turn off auto
    AutoGoddessProtection.Settings.Enabled = false;
    local state = "OFF";
    ui.SysMsg(string.format(AutoGoddessProtection:GetTranslatedString("message"), state));
    acutil.saveJSON(AutoGoddessProtection.SettingsFileLoc, AutoGoddessProtection.Settings);
end

function AUTOGODDESSPROTECTION_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(AutoGoddessProtection.Default.Movable);
    frame:EnableHitTest(AutoGoddessProtection.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "AUTOGODDESSPROTECTION_END_DRAG");

    -- draw the frame
    frame:SetSkinName('chat_window');

    -- set default position of frame
    frame:Move(AutoGoddessProtection.Settings.Position.X, AutoGoddessProtection.Settings.Position.Y);
    frame:SetOffset(AutoGoddessProtection.Settings.Position.X, AutoGoddessProtection.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(AutoGoddessProtection.Default.Width, AutoGoddessProtection.Default.Height);
    frame:ShowWindow(AutoGoddessProtection.Default.IsVisible);
end

function AUTOGODDESSPROTECTION_END_DRAG(frame, ctrl)
    AutoGoddessProtection.Settings.Position.X = AutoGoddessProtection.frame:GetX();
    AutoGoddessProtection.Settings.Position.Y = AutoGoddessProtection.frame:GetY();
    AUTOGODDESSPROTECTION_SAVE_SETTINGS();
end

function AUTOGODDESSPROTECTION_SAVE_SETTINGS()
    acutil.saveJSON(AutoGoddessProtection.SettingsFileLoc, AutoGoddessProtection.Settings);
end

-- general utilities

AutoGoddessProtection.Strings = {
    ["string_name"] = {
        ['kr'] = "안녕 세상아",
        ['en'] = "Hello World"
    },
    ["message"] = {
        ['kr'] = "자동 봉헌 애드온이 %s 상태입니다. /afk 명령어로 변경 가능합니다.",
        ['en'] = "Auto Goddess Protection addon is in %s state. Use the /afk command to change settings."
    }
}

function AutoGoddessProtection.GetTranslatedString(self, strName)
    local countrycode = option.GetCurrentCountry()
    local language = 'kr'
    if countrycode == 'kr' then
        language = 'kr'
    else
        language = 'en'
    end

    if (self.Strings[strName] == nil) then
        return nil
    else
        return self.Strings[strName][language]
    end
end

function AutoGoddessProtection.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end