--dofile("../data/addon_d/template/template.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'template'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local Template = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

Template.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

Template.Settings = {
    Position = {
        X = 400,
        Y = 400
    }
};

Template.Default = {
    Height = 100,
    Width = 100,
    IsVisible = 1,
    Movable = 1,
    Enabled = 1, -- Hittest
};

function TEMPLATE_ON_INIT(addon, frame)
    Template.addon = addon;
    Template.frame = frame;
    -- load settings
    if not Template.Loaded then
        local t, err = acutil.loadJSON(Template.SettingsFileLoc, Template.Settings);
        if err then
        else
            Template.Settings = t;
            Template.Loaded = true;
        end
    end
    -- initialize frame
    TEMPLATE_ON_FRAME_INIT(frame)
end

function TEMPLATE_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(Template.Default.Movable);
    frame:EnableHitTest(Template.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "TEMPLATE_END_DRAG");

    -- draw the frame
    frame:SetSkinName('chat_window');

    -- set default position of frame
    frame:Move(Template.Settings.Position.X, Template.Settings.Position.Y);
    frame:SetOffset(Template.Settings.Position.X, Template.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(Template.Default.Width, Template.Default.Height);
    frame:ShowWindow(Template.Default.IsVisible);
end

function TEMPLATE_END_DRAG(frame, ctrl)
    Template.Settings.Position.X = Template.frame:GetX();
    Template.Settings.Position.Y = Template.frame:GetY();
    TEMPLATE_SAVE_SETTINGS();
end

function TEMPLATE_SAVE_SETTINGS()
    acutil.saveJSON(Template.SettingsFileLoc, Template.Settings);
end

function Template.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end