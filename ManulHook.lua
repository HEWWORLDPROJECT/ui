local DBG = { lines = {}, console = nil, lastFire = 0, idleUnitLogs = 0 }
local function dbgPush(...)
    local parts = table.pack(...)
    for i = 1, parts.n do parts[i] = tostring(parts[i]) end
    local line = os.date("%H:%M:%S") .. " " .. table.concat(parts, " ", 1, parts.n)
 local lines = DBG.lines
    lines[#lines + 1] = line
    if #lines > 300 then table.remove(lines, 1) end
    local con = DBG.console
    if con then pcall(function() con:AppendText(line) end) end
end
function DBG.log(...)
    local c = getgenv().RCConfig
    if not (c and c.DebugSilentAim) then return end
    dbgPush(...)
end
function DBG.force(...)
end

do
    local HIDDEN = {
        rconsoleprint = true, rconsoleinfo = true, rconsolewarn = true, rconsoleerr = true,
        rconsoleclear = true, rconsolename = true, rconsoleinput = true, consoleclear = true,
        consolecreate = true, consoledestroy = true, consoleinput = true, consoleprint = true,
        consolesettitle = true,
    }
    local proxyCache = setmetatable({}, { __mode = "k" })

 local function sanitize(env)
        local cached = proxyCache[env]
        if cached then return cached end
        local okLeak, leak = pcall(function()
            for name in pairs(HIDDEN) do
                if env[name] ~= nil then return true end
            end
            return false
        end)
        if not (okLeak and leak) then
            proxyCache[env] = env
            return env
        end
        local proxy = setmetatable({}, {
            __index = function(_, k)
                if HIDDEN[k] then return nil end
                return env[k]
            end,
            __newindex = function(_, k, v) env[k] = v end,
            __metatable = "The metatable is locked",
 })
        proxyCache[env] = proxy
        return proxy
    end

    local g = (getgenv and getgenv()) or _G
    if g.__DL_GETFENV_GUARD then

        DBG.force("[ManulHook] getfenv guard already installed")
 end
    if hookfunction and checkcaller and not g.__DL_GETFENV_GUARD then
        local oldGetfenv
        local ok = pcall(function()
            oldGetfenv = hookfunction(getfenv, function(...)
                local env = oldGetfenv(...)
                if checkcaller() or type(env) ~= "table" then
 return env
                end
                return sanitize(env)
            end)
        end)
        if ok and oldGetfenv then
            g.__DL_GETFENV_GUARD = true
            DBG.force("[ManulHook] getfenv guard enabled")
        else
            DBG.force("[ManulHook] getfenv guard failed")
 end
        elseif not (hookfunction and checkcaller) then
        DBG.force("[ManulHook] missing hookfunction/checkcaller")
 end

end

local EnvPack = {}
EnvPack.lib = (function(...)

local mode = ...
local HttpService = game:GetService("HttpService")

local EnvCheck = {}
EnvCheck.ManulUrl = "https://raw.githubusercontent.com/HEWWORLDPROJECT/ui/refs/heads/main/ManulUI.lua"

local function isFn(v)
 return type(v) == "function"
end

local function global(name)
    local ok, v = pcall(function()
        if type(getgenv) == "function" then
            local g = getgenv()
            if type(g) == "table" and g[name] ~= nil then
                return g[name]
            end
        end
        return _G[name]
    end)
    return ok and v or nil
end

local CATALOG = {
    { Id = "getgenv", Label = "getgenv", Test = function()
 return isFn(global("getgenv")) and type(getgenv()) == "table"
 end },
    { Id = "loadstring", Label = "loadstring", Test = function()
 local f = isFn(global("loadstring")) and loadstring("return 1")
 return f ~= nil and f() == 1
    end },
    { Id = "HttpGet", Label = "game:HttpGet", Test = function()
 local ok, f = pcall(function()
            return game.HttpGet
        end)
        return ok and f ~= nil
    end },
    { Id = "request", Label = "request / http_request", Test = function()
 return isFn(global("request")) or isFn(global("http_request")) or (type(global("syn")) == "table" and isFn(syn.request))
 end, Note = "no custom HTTP requests" },
 { Id = "file", Label = "writefile / readfile / isfile", Test = function()
 if not (isFn(global("writefile")) and isFn(global("readfile")) and isFn(global("isfile"))) then
 return false
        end
        local path = "envcheck_probe.txt"
 local ok = pcall(writefile, path, "ok")
 local same = ok and isfile(path) and readfile(path) == "ok"
 if isFn(global("delfile")) then
 pcall(delfile, path)
        end
        return same
    end, Note = "settings and cache can't be saved" },
 { Id = "folder", Label = "makefolder / isfolder / listfiles", Test = function()
 return isFn(global("makefolder")) and isFn(global("isfolder")) and isFn(global("listfiles"))
 end },
    { Id = "delfile", Label = "delfile", Test = function()
 return isFn(global("delfile"))
 end, Note = "cache files can't be deleted" },
 { Id = "getcustomasset", Label = "getcustomasset", Test = function()
 return isFn(global("getcustomasset")) or isFn(global("getsynasset"))
 end, Note = "downloaded images (wallpapers) can't be shown" },
 { Id = "gethui", Label = "gethui", Test = function()
 if not isFn(global("gethui")) then
 return false
        end
        local ok, h = pcall(gethui)
        return ok and typeof(h) == "Instance"
 end, Note = "UI goes to CoreGui instead" },
 { Id = "cloneref", Label = "cloneref", Test = function()
 return isFn(global("cloneref"))
 end },
    { Id = "Drawing", Label = "Drawing", Test = function()
 local D = global("Drawing")
 if type(D) ~= "table" or not isFn(D.new) then
 return false
        end
        local ok, line = pcall(D.new, "Line")
 if ok and line then
            pcall(function()
                line:Remove()
            end)
        end
        return ok
    end, Note = "no screen overlays (ESP, prediction lines)" },
 { Id = "getgc", Label = "getgc", Test = function()
 if not isFn(global("getgc")) then
 return false
        end
        local ok, t = pcall(getgc)
        return ok and type(t) == "table"
 end, Note = "can't scan objects in memory" },
 { Id = "getconnections", Label = "getconnections", Test = function()
 if not isFn(global("getconnections")) then
 return false
        end
        local ok, t = pcall(getconnections, game:GetService("RunService").Heartbeat)
 return ok and type(t) == "table"
 end, Note = "can't fire button / signal connections" },
 { Id = "firesignal", Label = "firesignal", Test = function()
 return isFn(global("firesignal"))
 end },
    { Id = "hookfunction", Label = "hookfunction", Test = function()
 return isFn(global("hookfunction")) or isFn(global("replaceclosure"))
 end, Note = "can't hook functions" },
 { Id = "hookmetamethod", Label = "hookmetamethod", Test = function()
 return isFn(global("hookmetamethod"))
 end },
    { Id = "getrawmetatable", Label = "getrawmetatable / setreadonly", Test = function()
 return isFn(global("getrawmetatable")) and (isFn(global("setreadonly")) or isFn(global("make_writeable")))
 end },
    { Id = "newcclosure", Label = "newcclosure", Test = function()
 return isFn(global("newcclosure"))
 end },
    { Id = "getnamecallmethod", Label = "getnamecallmethod", Test = function()
 return isFn(global("getnamecallmethod"))
 end },
    { Id = "checkcaller", Label = "checkcaller", Test = function()
 return isFn(global("checkcaller"))
 end },
    { Id = "getsenv", Label = "getsenv", Test = function()
 return isFn(global("getsenv"))
 end, Note = "can't read game script environments" },
 { Id = "debug", Label = "debug.getupvalue / getconstants", Test = function()
 local d = global("debug")
 return type(d) == "table" and isFn(d.getupvalue) and isFn(d.getconstants)
 end },
    { Id = "decompile", Label = "decompile", Test = function()
 return isFn(global("decompile"))
 end },
    { Id = "fireclickdetector", Label = "fireclickdetector", Test = function()
 return isFn(global("fireclickdetector"))
 end },
    { Id = "fireproximityprompt", Label = "fireproximityprompt", Test = function()
 return isFn(global("fireproximityprompt"))
 end },
    { Id = "firetouchinterest", Label = "firetouchinterest", Test = function()
 return isFn(global("firetouchinterest"))
 end },
    { Id = "setclipboard", Label = "setclipboard", Test = function()
 return isFn(global("setclipboard")) or isFn(global("toclipboard"))
 end },
    { Id = "queue_on_teleport", Label = "queue_on_teleport", Test = function()
 return isFn(global("queue_on_teleport")) or (type(global("syn")) == "table" and isFn(syn.queue_on_teleport))
 end },
}
EnvCheck.Catalog = CATALOG

local CATALOG_BY_ID = {}
for _, c in ipairs(CATALOG) do
    CATALOG_BY_ID[c.Id] = c
end

function EnvCheck.SharedRequire(module, isReady, wait)
    return function()
        local ok, m = pcall(require, module)
        if not ok or m == nil then
            return false
        end
        local deadline = os.clock() + (wait or 5)
        repeat
            local okReady, ready = pcall(isReady, m)
            if okReady and ready then
                return true
            end
            task.wait(0.2)
        until os.clock() > deadline
        return false
    end
end

local TEXT = {
    zh = {},
    en = {
        ok = "OK", missing = "Missing", missingReq = "MISSING (required)", available = "%d / %d available",
 tab = "Environment", caption = "Executor check", cannot = "Cannot run", close = "Close",
 cannotBody = "This executor lacks a required feature. The script stopped without changing anything in the game. Use an executor that supports the required items above.",
 notifyBlocked = "Missing a required executor feature – script not started", notifyDone = "Check done: %d / %d available",
 subtitle = "Environment check",
 },
}

local function executorName()
    local name = "?"
    pcall(function()
        if isFn(global("identifyexecutor")) then
            local n, v = identifyexecutor()
            name = tostring(n) .. (v and (" " .. tostring(v)) or "")
        elseif isFn(global("getexecutorname")) then
            name = tostring(getexecutorname())
        end
    end)
    return name
end

local function pick(note, lang)
    if type(note) == "table" then
 return note[lang] or note.zh or note.en
    end
    return note
end

function EnvCheck.Run(opts)
    opts = opts or {}
    local lang = "en"
 local env = {
        Language = "en",
 Executor = executorName(),
        Checks = {},
        Missing = {},
        Passed = 0,
        Total = 0,
        Blocked = false,
    }
    local function add(id, label, required, test, note)
        local ok, result = pcall(test)
        local pass = ok and result == true
        table.insert(env.Checks, { Id = id, Label = label, Required = required, Ok = pass, Note = note })
        env.Total += 1
        if pass then
            env.Passed += 1
        else
            env.Missing[id] = true
            if required then
                env.Blocked = true
            end
        end
    end
    local notes = opts.Notes or {}
    local function fromCatalog(id, required)
        local c = CATALOG_BY_ID[id]
        if not c then
            DBG.force("[EnvCheck] unknown check: " .. tostring(id))
 return
        end
        add(c.Id, c.Label, required, c.Test, pick(notes[id], lang) or pick(c.Note, lang))
    end
    local listed = opts.Required or opts.Optional or opts.Custom
    if not listed then
        for _, c in ipairs(CATALOG) do
            fromCatalog(c.Id, false)
        end
    else
        for _, id in ipairs(opts.Required or {}) do
            fromCatalog(id, true)
        end
        for _, id in ipairs(opts.Optional or {}) do
            fromCatalog(id, false)
        end
    end
    for _, c in ipairs(opts.Custom or {}) do
        add(c.Id, pick(c.Label, lang) or c.Id, c.Required == true, c.Test, pick(c.Note, lang))
    end
    return env
end

function EnvCheck.Section(env, tab)
    local L = TEXT[env.Language]
    local sec = tab:AddSection({ Title = "Environment", Caption = L.caption })
 sec:AddProgress({
        Title = env.Executor,
        Description = string.format(L.available, env.Passed, env.Total),
        Style = "Ring", Min = 0, Max = math.max(env.Total, 1), Default = env.Passed,
 Tone = env.Blocked and "warn" or (env.Passed == env.Total and "good" or "accent"),
 })
    local lines = {}
    for _, c in ipairs(env.Checks) do
        local color, state
        if c.Ok then
            color, state = "#3DDC97", L.ok
        elseif c.Required then
            color, state = "#FF6B6B", L.missingReq
        else
            color, state = "#FFB74D", L.missing
        end
        lines[#lines + 1] = string.format(
            '<font color="%s"><b>%s</b></font> %s%s',
            color,
            state,
            c.Label,
            (not c.Ok and c.Note) and ('<font transparency="0.35"> —  ' .. c.Note .. "</font>") or ""
        )
 end
    sec:AddLabel({ Text = table.concat(lines, "\n"), Size = 12, Tone = "text" })
 if env.Blocked then
        sec:AddParagraph({ Title = L.cannot, Content = L.cannotBody })
    end
    return sec
end

local function loadManul(opts)
    if opts.ManulUI then
        return opts.ManulUI
    end
    return loadstring(game:HttpGet(EnvCheck.ManulUrl))()
end

function EnvCheck.Show(env, opts)
    opts = opts or {}
    local L = TEXT[env.Language]
    local ManulUI = loadManul(opts)
    local footer = opts.Footer
    if footer == nil then
        footer = env.Executor
    end
    local W = ManulUI:CreateWindow({
        Title = opts.Title or "EnvCheck",
 Subtitle = opts.Subtitle or L.subtitle,
        Footer = footer,
        Size = opts.Size or Vector2.new(620, 440),
        Intro = opts.Intro == true,
        Theme = opts.Theme,
        ForceTheme = opts.ForceTheme,
        ToggleKey = opts.ToggleKey,
        SaveSettings = opts.SaveSettings,
        GuiName = opts.GuiName or "EnvCheck",
 })
    local tab = W:AddTab({ Title = L.tab, Subtitle = env.Executor, Icon = "activity" })
 EnvCheck.Section(env, tab)
    tab:AddButton({
        Title = L.close,
        Callback = function()
            W:Destroy()
            if type(opts.OnClose) == "function" then
 pcall(opts.OnClose)
            end
        end,
    })
    if opts.ThemeTab ~= false then
        W:AddThemeTab({ Configs = opts.Configs == true })
    end
    W:Notify({
        Title = opts.Title or "EnvCheck",
 Content = env.Blocked and L.notifyBlocked or string.format(L.notifyDone, env.Passed, env.Total),
        Duration = 4,
    })
    return W
end

function EnvCheck.ShowBlocked(env, opts)
        return EnvCheck.Show(env, opts)
end

if mode ~= "lib" then
 local lang = "zh"
 pcall(function()
        if isFn(global("isfile")) and isfile("ManulUI/settings.json") then
 local s = HttpService:JSONDecode(readfile("ManulUI/settings.json"))
 if s.language == "en" then
 lang = "en"
 end
        end
    end)
    local env = EnvCheck.Run({ Language = "en" })
 EnvCheck.Show(env, { Title = lang == "en" and "Executor check" or "" })
end

return EnvCheck
end)("lib")

local MANUL_URL = "https://raw.githubusercontent.com/HEWWORLDPROJECT/ui/refs/heads/main/ManulUI.lua"
local okUi, ManulUI = pcall(function() return loadstring(game:HttpGet(MANUL_URL))() end)
if not okUi or type(ManulUI) ~= "table" then
 DBG.force("[ManulHook] Manul UI load failed: " .. tostring(ManulUI))
 ManulUI = nil
end

local global_Drawing = Drawing

local cloneref = cloneref or function(obj) return obj end

local Players = cloneref(game:GetService("Players"))
local UIS = cloneref(game:GetService("UserInputService"))
local RunSvc = cloneref(game:GetService("RunService"))
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer
local LocalId = LP.UserId
local Lighting = cloneref(game:GetService("Lighting"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local _HttpService = cloneref(game:GetService("HttpService"))
local _ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local _CollectionService = cloneref(game:GetService("CollectionService"))

local DrawingGui = Instance.new("ScreenGui")
DrawingGui.Name = "DrawingGui_" .. tostring(math.random(100000, 999999))
DrawingGui.IgnoreGuiInset = true
DrawingGui.ResetOnSpawn = false
DrawingGui.DisplayOrder = 9999

local function getGuiContainer()
 if gethui then
        return gethui()
 elseif syn and syn.protect_gui then
        return CoreGui
 elseif protect_gui then
        return CoreGui
 else
        return CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")
 end
end

if syn and syn.protect_gui then
    syn.protect_gui(DrawingGui)
elseif protect_gui then
    protect_gui(DrawingGui)
end
DrawingGui.Parent = getGuiContainer()

local ROBLOX_FONT_MAP = {
    [0] = Enum.Font.GothamMedium,
    [1] = Enum.Font.Roboto,
    [2] = Enum.Font.Montserrat,
    [3] = Enum.Font.RobotoMono
}

local Drawing = {}
Drawing.Fonts = {
    UI = 0,
    System = 1,
    Plex = 2,
    Monospace = 3
}

local LineMT = {}
LineMT.__index = LineMT

function LineMT:Remove()
    self:Destroy()
end

function LineMT:Destroy()
    if self._frame then
        self._frame:Destroy()
        self._frame = nil
    end
end

function LineMT:__newindex(key, val)
    local frame = self._frame
    if not frame then return end

    if key == "Visible" then
 if frame.Visible ~= val then frame.Visible = val end
 elseif key == "Color" then
 if frame.BackgroundColor3 ~= val then frame.BackgroundColor3 = val end
 elseif key == "Transparency" then
 local bt = 1 - val
        if frame.BackgroundTransparency ~= bt then frame.BackgroundTransparency = bt end
        elseif key == "Thickness" then
 if self._thickness ~= val then
            self._thickness = val
            self:_update()
        end
 elseif key == "From" then
 if self._from ~= val then
            self._from = val
            self:_update()
        end
 elseif key == "To" then
 if self._to ~= val then
            self._to = val
            self:_update()
        end
 elseif key == "ZIndex" then
 frame.ZIndex = val
    end
end

function LineMT:_update()
    local frame = self._frame
    if not frame then return end
    local from = self._from or Vector2.new()
    local to = self._to or Vector2.new()
    local thickness = self._thickness or 1

    local diff = to - from
    local dist = diff.Magnitude
    local angle = math.atan2(diff.Y, diff.X)

    frame.Size = UDim2.fromOffset(dist, thickness)
    frame.Position = UDim2.fromOffset((from.X + to.X)/2, (from.Y + to.Y)/2)
    frame.Rotation = math.deg(angle)
end

function Drawing.newLine()
    local self = setmetatable({
        _frame = Instance.new("Frame"),
 _from = Vector2.new(),
        _to = Vector2.new(),
        _thickness = 1,
    }, LineMT)

    local frame = self._frame
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Visible = false
    frame.Parent = DrawingGui

    return self
end

local SquareMT = {}

function SquareMT:Remove()
    self:Destroy()
end

function SquareMT:Destroy()
    if self._frame then
        self._frame:Destroy()
        self._frame = nil
    end
end

function SquareMT:__index(key)
    local method = SquareMT[key]
    if method then return method end

    if key == "Visible" then
 return self._frame and self._frame.Visible
    elseif key == "Color" then
 return self._color
    elseif key == "Transparency" then
 return self._transparency
    elseif key == "Position" then
 return self._position
    elseif key == "Size" then
 return self._size
    elseif key == "Filled" then
 return self._filled
    elseif key == "Thickness" then
 return self._thickness
    end
    return nil
end

function SquareMT:__newindex(key, val)
    local frame = self._frame
    if not frame then return end

    if key == "Visible" then
 if frame.Visible ~= val then frame.Visible = val end
 elseif key == "Color" then
 if self._color ~= val then
            self._color = val
            self:_update()
        end
 elseif key == "Transparency" then
 if self._transparency ~= val then
            self._transparency = val
            self:_update()
        end
 elseif key == "Position" then
 if self._position ~= val then
            self._position = val
            frame.Position = UDim2.fromOffset(val.X, val.Y)
        end
 elseif key == "Size" then
 if self._size ~= val then
            self._size = val
            frame.Size = UDim2.fromOffset(val.X, val.Y)
        end
 elseif key == "Filled" then
 if self._filled ~= val then
            self._filled = val
            self:_update()
        end
 elseif key == "Thickness" then
 if self._thickness ~= val then
            self._thickness = val
            self:_update()
        end
 elseif key == "ZIndex" then
 frame.ZIndex = val
    end
end

function SquareMT:_update()
    local frame = self._frame
    if not frame then return end

    local filled = self._filled
    local color = self._color or Color3.new(1, 1, 1)
    local transparency = self._transparency or 1
    local thickness = self._thickness or 1

    if filled then
        frame.BackgroundTransparency = 1 - transparency
        frame.BackgroundColor3 = color
        local stroke = frame:FindFirstChild("UIStroke")
 if stroke then stroke.Enabled = false end
 else
        frame.BackgroundTransparency = 1
        local stroke = frame:FindFirstChild("UIStroke")
 if not stroke then
            stroke = Instance.new("UIStroke")
 stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Parent = frame
        end
        stroke.Thickness = thickness
        stroke.Color = color
        stroke.Transparency = 1 - transparency
        stroke.Enabled = true
    end
end

function Drawing.newSquare()
    local self = setmetatable({
        _frame = Instance.new("Frame"),
 _position = Vector2.new(),
        _size = Vector2.new(),
        _color = Color3.new(1,1,1),
        _transparency = 1,
        _thickness = 1,
        _filled = false,
    }, SquareMT)

    local frame = self._frame
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = DrawingGui

    local corner = Instance.new("UICorner")
 corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    self:_update()

    return self
end

local CircleMT = {}

function CircleMT:Remove()
    self:Destroy()
end

function CircleMT:Destroy()
    if self._frame then
        self._frame:Destroy()
        self._frame = nil
    end
end

function CircleMT:__index(key)
    local method = CircleMT[key]
    if method then return method end

    if key == "Visible" then
 return self._frame and self._frame.Visible
    elseif key == "Color" then
 return self._color
    elseif key == "Transparency" then
 return self._transparency
    elseif key == "Position" then
 return self._position
    elseif key == "Radius" then
 return self._radius
    elseif key == "Filled" then
 return self._filled
    elseif key == "Thickness" then
 return self._thickness
    end
    return nil
end

function CircleMT:__newindex(key, val)
    local frame = self._frame
    if not frame then return end

    if key == "Visible" then
 if frame.Visible ~= val then frame.Visible = val end
 elseif key == "Color" then
 if self._color ~= val then
            self._color = val
            self:_update()
        end
 elseif key == "Transparency" then
 if self._transparency ~= val then
            self._transparency = val
            self:_update()
        end
 elseif key == "Position" then
 if self._position ~= val then
            self._position = val
            self:_updatePosition()
        end
 elseif key == "Radius" then
 if self._radius ~= val then
            self._radius = val
            self:_updatePosition()
        end
 elseif key == "Filled" then
 if self._filled ~= val then
            self._filled = val
            self:_update()
        end
 elseif key == "Thickness" then
 if self._thickness ~= val then
            self._thickness = val
            self:_update()
        end
 elseif key == "ZIndex" then
 frame.ZIndex = val
    end
end

function CircleMT:_updatePosition()
    local frame = self._frame
    if not frame then return end
    local pos = self._position or Vector2.new()
    local r = self._radius or 0

    frame.Position = UDim2.fromOffset(pos.X, pos.Y)
    frame.Size = UDim2.fromOffset(r * 2, r * 2)
end

function CircleMT:_update()
    local frame = self._frame
    if not frame then return end

    local filled = self._filled
    local color = self._color or Color3.new(1, 1, 1)
    local transparency = self._transparency or 1
    local thickness = self._thickness or 1

    if filled then
        frame.BackgroundTransparency = 1 - transparency
        frame.BackgroundColor3 = color
        local stroke = frame:FindFirstChild("UIStroke")
 if stroke then stroke.Enabled = false end
 else
        frame.BackgroundTransparency = 1
        local stroke = frame:FindFirstChild("UIStroke")
 if not stroke then
            stroke = Instance.new("UIStroke")
 stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Parent = frame
        end
        stroke.Thickness = thickness
        stroke.Color = color
        stroke.Transparency = 1 - transparency
        stroke.Enabled = true
    end
end

function Drawing.newCircle()
    local self = setmetatable({
        _frame = Instance.new("Frame"),
 _position = Vector2.new(),
        _radius = 0,
        _color = Color3.new(1,1,1),
        _transparency = 1,
        _thickness = 1,
        _filled = false,
    }, CircleMT)

    local frame = self._frame
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Visible = false
    frame.Parent = DrawingGui

    local corner = Instance.new("UICorner")
 corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame
    self:_update()

    return self
end

local TextMT = {}

function TextMT:Remove()
    self:Destroy()
end

function TextMT:Destroy()
    if self._label then
        self._label:Destroy()
        self._label = nil
    end
end

function TextMT:__index(key)
    local method = TextMT[key]
    if method then return method end

    if key == "Visible" then
 return self._label and self._label.Visible
    elseif key == "Color" then
 return self._label and self._label.TextColor3
    elseif key == "Transparency" then
 return self._label and (1 - self._label.TextTransparency)
    elseif key == "Position" then
 return self._position
    elseif key == "Text" then
 return self._label and self._label.Text
    elseif key == "Size" then
 return self._label and self._label.TextSize
    elseif key == "Center" then
 return self._center
    elseif key == "Outline" then
 return self._outline
    elseif key == "OutlineColor" then
 return self._outlineColor
    elseif key == "Font" then
 return self._font
    end
    return nil
end

function TextMT:__newindex(key, val)
    local label = self._label
    if not label then return end

    if key == "Visible" then
 if label.Visible ~= val then label.Visible = val end
 elseif key == "Color" then
 if label.TextColor3 ~= val then label.TextColor3 = val end
 elseif key == "Transparency" then
 local tt = 1 - val
        if label.TextTransparency ~= tt then
            label.TextTransparency = tt
            local stroke = label:FindFirstChild("UIStroke")
 if stroke then stroke.Transparency = tt end
        end
 elseif key == "Position" then
 if self._position ~= val then
            self._position = val
            label.Position = UDim2.fromOffset(val.X, val.Y)
        end
 elseif key == "Text" then
 if label.Text ~= val then label.Text = val end
 elseif key == "Size" then
 if label.TextSize ~= val then label.TextSize = val end
 elseif key == "Center" then
 self._center = val
        label.AnchorPoint = Vector2.new(val and 0.5 or 0, 0)
        label.TextXAlignment = val and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
 elseif key == "Outline" then
 self._outline = val
        self:_updateOutline()
 elseif key == "OutlineColor" then
 self._outlineColor = val
        self:_updateOutline()
 elseif key == "Font" then
 self._font = val
        label.Font = ROBLOX_FONT_MAP[val] or Enum.Font.GothamMedium
 elseif key == "ZIndex" then
 label.ZIndex = val
    end
end

function TextMT:_updateOutline()
    local label = self._label
    if not label then return end

    local stroke = label:FindFirstChild("UIStroke")
 if self._outline then
        if not stroke then
            stroke = Instance.new("UIStroke")
 stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
            stroke.Parent = label
        end
        stroke.Thickness = 1.2
        stroke.Color = self._outlineColor or Color3.new(0, 0, 0)
        stroke.Transparency = label.TextTransparency
        stroke.Enabled = true
        else
        if stroke then stroke.Enabled = false end
    end
end

function Drawing.newText()
    local self = setmetatable({
        _label = Instance.new("TextLabel"),
 _position = Vector2.new(),
        _center = false,
        _outline = false,
        _outlineColor = Color3.new(0,0,0),
        _font = 0,
    }, TextMT)

    local label = self._label
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Visible = false
    label.Parent = DrawingGui
    label.AutomaticSize = Enum.AutomaticSize.XY
    label.Size = UDim2.fromOffset(0, 0)

    return self
end

local TriangleMT = {}

function TriangleMT:Remove()
    self:Destroy()
end

function TriangleMT:Destroy()
    if self._image then
        self._image:Destroy()
        self._image = nil
    end
end

function TriangleMT:__index(key)
    local method = TriangleMT[key]
    if method then return method end

    if key == "Visible" then
 return self._image and self._image.Visible
    elseif key == "Color" then
 return self._color
    elseif key == "Transparency" then
 return self._transparency
    elseif key == "PointA" then
 return self._pointA
    elseif key == "PointB" then
 return self._pointB
    elseif key == "PointC" then
 return self._pointC
    elseif key == "Filled" then
 return self._filled
    end
    return nil
end

function TriangleMT:__newindex(key, val)
    local img = self._image
    if not img then return end

    if key == "Visible" then
 if img.Visible ~= val then img.Visible = val end
 elseif key == "Color" then
 if self._color ~= val then
            self._color = val
            img.ImageColor3 = val
        end
 elseif key == "Transparency" then
 if self._transparency ~= val then
            self._transparency = val
            img.ImageTransparency = 1 - val
        end
 elseif key == "PointA" then
 if self._pointA ~= val then
            self._pointA = val
            self:_update()
        end
 elseif key == "PointB" then
 if self._pointB ~= val then
            self._pointB = val
            self:_update()
        end
 elseif key == "PointC" then
 if self._pointC ~= val then
            self._pointC = val
            self:_update()
        end
 elseif key == "Filled" then
 self._filled = val
 elseif key == "ZIndex" then
 img.ZIndex = val
    end
end

function TriangleMT:_update()
    local img = self._image
    if not img then return end

    local pa = self._pointA or Vector2.new()
    local pb = self._pointB or Vector2.new()
    local pc = self._pointC or Vector2.new()

    local mid = (pb + pc) / 2
    local heightVec = pa - mid
    local h = heightVec.Magnitude
    local w = (pb - pc).Magnitude

    if h < 0.1 or w < 0.1 then return end

    local center = mid + heightVec / 2
    local angle = math.deg(math.atan2(heightVec.Y, heightVec.X)) + 90

    img.Position = UDim2.fromOffset(center.X, center.Y)
    img.Size = UDim2.fromOffset(w, h)
    img.Rotation = angle
end

function Drawing.newTriangle()
    local self = setmetatable({
        _image = Instance.new("ImageLabel"),
 _pointA = Vector2.new(),
        _pointB = Vector2.new(),
        _pointC = Vector2.new(),
        _color = Color3.new(1,1,1),
        _transparency = 1,
        _filled = true,
    }, TriangleMT)

    local img = self._image
    img.BackgroundTransparency = 1
    img.BorderSizePixel = 0
    img.AnchorPoint = Vector2.new(0.5, 0.5)
    img.Image = "rbxassetid://7072704200"
 img.Visible = false
    img.Parent = DrawingGui

    return self
end

function Drawing.new(cls)
    if cls == "Line" then
 return Drawing.newLine()
    elseif cls == "Square" then
 return Drawing.newSquare()
    elseif cls == "Circle" then
 return Drawing.newCircle()
    elseif cls == "Text" then
 return Drawing.newText()
    elseif cls == "Triangle" then
 return Drawing.newTriangle()
    end
    return nil
end
local origLightingSettings = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Ambient = Lighting.Ambient,
    FogEnd = Lighting.FogEnd,
    ExposureCompensation = Lighting.ExposureCompensation,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
}

local flashCC = Lighting:FindFirstChild("IngameView, flash_color_correction")
local flashDesat = Lighting:FindFirstChild("IngameView, flash_desaturation")
local flashBlur = Lighting:FindFirstChild("IngameView, flash_blur_effect")
local expCC = Lighting:FindFirstChild("IngameView, explosion_color_correction")
local expBlur = Lighting:FindFirstChild("IngameView, explosion_blur_effect")
local supCC = Lighting:FindFirstChild("IngameView, suppression_color_correction")
local supBlur = Lighting:FindFirstChild("IngameView, suppression_blur_effect")

local RawLighting = game:GetService("Lighting")

local mt = getrawmetatable(game)
local old_newindex = mt.__newindex
setreadonly(mt, false)

mt.__newindex = newcclosure(function(self, idx, val)
 local cfg = getgenv().RCConfig
    if cfg and cfg.ForceDaylight and (self == RawLighting or (compareinstances and compareinstances(self, RawLighting))) then
        if idx == "ClockTime" or idx == "TimeOfDay" then
            return old_newindex(self, "ClockTime", 14)
        elseif idx == "Brightness" then
            return old_newindex(self, idx, 2)
        elseif idx == "OutdoorAmbient" or idx == "Ambient" then
            return old_newindex(self, idx, Color3.fromRGB(128, 128, 128))
        elseif idx == "ExposureCompensation" then

 return old_newindex(self, idx, 0.25)
        elseif idx == "EnvironmentDiffuseScale" then
 return old_newindex(self, idx, 1)
        elseif idx == "FogEnd" then
 return old_newindex(self, idx, 999999)
        end
    end
    return old_newindex(self, idx, val)
end)

setreadonly(mt, true)

math.randomseed(tick())


if getgenv()._MANULHOOK and getgenv()._MANULHOOK.Unload then
 pcall(getgenv()._MANULHOOK.Unload)
end
getgenv()._MANULHOOK = {}

getgenv().RCConfig = {

    EspEngine    = "ScreenGui",
 EspEnabled   = false,
    ForceDaylight = false,
    NoThrowables = false,
    AimWarningEnabled = true,
    GrenadeEspEnabled = true,
    GrenadeIgnoreAllies = true,
    GrenadeLandingEnabled = true,
    GrenadeBlastRadius = 30,
    GrenadeWarnDist  = 35,
    ShowBox      = false,
    ShowTracer   = false,
    ShowSkeleton = true,
    ShowName     = true,
    ShowDist     = true,
    ShowLookLine = true,
    ShowChams    = false,
    ShowWeapon   = true,
    ShowNVG      = true,
    ShowMoving   = true,
    ShowOffscreenArrow = true,
    BoxStyle     = "Corner",
 BoxFilled    = true,
    VisCheck     = true,
    TeamCheck    = true,

    AimbotEnabled  = false,
    AimKey         = Enum.UserInputType.MouseButton2,
    AimSmooth      = 5,
    AimAlgo        = "linear",
 AimCurveStrength = 2,
    AimPart        = "head",
 ShowAimFov     = true,
    AimFov         = 150,
    AimMaxDist     = 300,
    AimFovCenter   = "screen",
 AimWallCheck   = true,
    AimWallbang    = false,
    WallbangScale  = 1,
    DropCompEnabled = true,

    CrosshairEnabled = false,
    CrosshairType    = "Dot",
 CrosshairCenter  = "screen",
 CrosshairSize    = 5,
    CrosshairColor   = Color3.fromRGB(255, 0, 0),
    NoRecoilEnabled  = false,
    NoSpreadEnabled  = false,
    InfiniteArmStamina = false,

    SilentAimEnabled   = false,
    SilentAimPart      = "auto",
 ShowSilentFov      = false,
    SilentAimFov       = 150,
    SilentAimFovCenter = "screen",
 SilentAimWallCheck = true,
    SilentAimWallbang  = false,
    SilentAimMaxDist   = 200,
    DebugSilentAim     = false,

    MicroAimEnabled    = false,
    MicroAimPart       = "auto",
 MicroAimRadius     = 3,
    MicroAimMaxAngle   = 3,
    MicroAimMaxDist    = 300,
    MicroAimWallCheck  = true,

    TriggerEnabled     = false,
    TriggerRadius      = 1.5,
    TriggerMaxAngle    = 2,
    TriggerMaxDist     = 400,
    TriggerDelay       = 40,
    TriggerInterval    = 90,
    TriggerWallCheck   = true,
    TriggerNeedKey     = false,
    ShowSilentTargetLine = true,

    DisableMuzzleFlash = false,
    DisableTracers     = false,

    MaxDist      = 1500,
    Thickness    = 1,
    Opacity      = 1.0,
    TracerOrigin = "Bottom",
 EnemyColor   = Color3.fromRGB(255, 69, 69),
    VisibleColor = Color3.fromRGB(0, 255, 0),
    AllyColor    = Color3.fromRGB(69, 150, 255),
    ChamsFillTransparency = 0.55,
    BoxFillTransparency   = 0.25,
    OffscreenArrowRadius  = 190,

    EspFontSize  = 14,
    EspFont      = "Monospace",

 RadarEnabled = false,
    RadarSize    = 180,
    RadarRange   = 150,
    RadarDotSize = 3,
    ShowRadarHud = true,

    ShowAmmoBox  = false,
    AmmoBoxColor = Color3.fromRGB(0, 255, 150),

    NoLensFlare      = false,
    NoStaminaShake   = false,
    AutoLoadConfig = true,
    Language = "EN",
}

local config_filepath = "ManulHook\\config.json"
local rebuildGUI

local function saveConfig()
 local HS = game:GetService("HttpService")
 local saveTbl = {}
    for k, v in pairs(getgenv().RCConfig) do
        if typeof(v) == "Color3" then
 saveTbl[k] = { v.R, v.G, v.B }
        elseif typeof(v) == "EnumItem" then
 saveTbl[k] = tostring(v)
        else
            saveTbl[k] = v
        end
    end

    pcall(function()
        if not isfolder("ManulHook") then makefolder("ManulHook") end
 end)

    local ok, json = pcall(function() return HS:JSONEncode(saveTbl) end)
    if ok then
        local okWrite, err = pcall(writefile, config_filepath, json)
        if okWrite then
            DBG.force("[ManulHook] config saved -> " .. config_filepath)
        else
            DBG.force("[ManulHook] write failed: " .. tostring(err))
 end
        else
        DBG.force("[ManulHook] JSON encode failed")
 end
end

local function loadConfig(isStartup)
    if isfile(config_filepath) then
        local okRead, data = pcall(readfile, config_filepath)
        if okRead then
            local HS = game:GetService("HttpService")
 local okDecode, tbl = pcall(function() return HS:JSONDecode(data) end)
            if okDecode and type(tbl) == "table" then
 local cfg = getgenv().RCConfig

                if isStartup and tbl.AutoLoadConfig == false then
                    cfg.AutoLoadConfig = false
                    DBG.force("[ManulHook] auto-load off, skipped")
 return
                end

                for k, v in pairs(tbl) do
                    if cfg[k] ~= nil then
                        if type(v) == "table" and #v == 3 then
 cfg[k] = Color3.new(v[1], v[2], v[3])
                        elseif typeof(cfg[k]) == "EnumItem" and type(v) == "string" then
 local enumType, enumName = v:match("^Enum%.(%w+)%.(%w+)$")
 local okEnum, item = pcall(function() return Enum[enumType][enumName] end)
                            if okEnum and item then cfg[k] = item end
                            else
                            cfg[k] = v
                        end
                    end
                end
                DBG.force("[ManulHook] config loaded")
 if not isStartup and rebuildGUI then
                    rebuildGUI()
                end
            end
        end
    end
end

pcall(function() loadConfig(true) end)

do
    local function runEnv(lang)
        return EnvPack.lib.Run({
            Language = "en",
 Required = { "getgenv" },
 Optional = { "loadstring", "HttpGet", "file", "folder", "Drawing", "gethui", "cloneref", "newcclosure", "getrawmetatable" },
 Notes = {
                loadstring = "can't load the Manul UI",
 HttpGet = "can't load the Manul UI",
 file = "config can't be saved / loaded",
 Drawing = "falls back to ScreenGui emulation (slower)",
 newcclosure = "some hooks may be unstable",
 getrawmetatable = "flash / lens-effect removal may not work",
 },
            Custom = {
                { Id = "getupvalue", Required = true, Label = "debug.getupvalue",
 Test = function() return type(debug) == "table" and type(debug.getupvalue) == "function" end,
 Note = "can't read team / death data or module internals" },
 { Id = "getgc", Label = "getgc",
 Test = function() return type(getgc) == "function" end,
 Note = "radar HUD health / ammo unavailable" },
 { Id = "mousemoverel", Label = "mousemoverel",
 Test = function() return type(mousemoverel) == "function" end,
 Note = "camera aimbot can't move the mouse" },
 { Id = "mouse1click", Label = "mouse1click",
 Test = function() return type(mouse1click) == "function" end,
 Note = "triggerbot can't click" },
 { Id = "hookable", Label = "require",
 Test = function() return type(require) == "function" end,
 Note = "silent aim needs require on game modules" },
 },
        })
    end
    EnvPack.en = runEnv("en")
 local env = EnvPack.en
    if env.Blocked then
        local okShow, err = pcall(function()
            EnvPack.lib.ShowBlocked(env, { Title = "ManulHook", ManulUI = ManulUI })
 end)
        if not okShow then
            DBG.force("[ManulHook] missing required APIs: " .. tostring(err))
 end
        return
    end
    for id in pairs(env.Missing) do
        DBG.force("[ManulHook] missing " .. id .. ", feature degraded")
 end
end

local JOINTS = {
    "head", "neck", "spine", "waist",
 "l_shoulder", "l_elbow", "l_hand",
 "r_shoulder", "r_elbow", "r_hand",
 "l_hip", "l_knee", "l_foot",
 "r_hip", "r_knee", "r_foot"
}

local SKELETON = {
 { "head", "neck" },
 { "neck", "l_shoulder" },
 { "l_shoulder", "l_elbow" },
 { "l_elbow", "l_hand" },
 { "neck", "r_shoulder" },
 { "r_shoulder", "r_elbow" },
 { "r_elbow", "r_hand" },
 { "neck", "spine" },
 { "spine", "waist" },
 { "waist", "l_hip" },
 { "l_hip", "l_knee" },
 { "l_knee", "l_foot" },
 { "waist", "r_hip" },
 { "r_hip", "r_knee" },
 { "r_knee", "r_foot" }
}
local SKEL_LINE_COUNT = #SKELETON
local _JOINT_COUNT = #JOINTS

local partsCache = setmetatable({}, { __mode = "k" })

local function getCharParts(charModel)
 local p = partsCache[charModel]
    if p and p.head.Parent and p.torso.Parent and p.hrp.Parent
        and p.l_arm.Parent and p.r_arm.Parent and p.l_leg.Parent and p.r_leg.Parent then
        return p
    end
    local head = charModel:FindFirstChild("head")
 local torso = charModel:FindFirstChild("torso")
 local l_arm = charModel:FindFirstChild("left_arm_vis")
 local r_arm = charModel:FindFirstChild("right_arm_vis")
 local l_leg = charModel:FindFirstChild("left_leg_vis")
 local r_leg = charModel:FindFirstChild("right_leg_vis")
 local hrp = charModel:FindFirstChild("humanoid_root_part")
 if not (head and torso and l_arm and r_arm and l_leg and r_leg and hrp) then
        partsCache[charModel] = nil
        return nil
    end
    p = {
        head = head, torso = torso, l_arm = l_arm, r_arm = r_arm,
        l_leg = l_leg, r_leg = r_leg, hrp = hrp,
        l_shoulder_att = l_arm:FindFirstChild("LeftShoulderAttachment"),
 r_shoulder_att = r_arm:FindFirstChild("RightShoulderAttachment"),
 neck_att = torso:FindFirstChild("NeckAttachment"),
 }
    partsCache[charModel] = p
    return p
end

local function getJointPositions(charModel)
    local parts = getCharParts(charModel)
    if not parts then return nil end
    local head, torso, hrp = parts.head, parts.torso, parts.hrp
    local l_arm, r_arm, l_leg, r_leg = parts.l_arm, parts.r_arm, parts.l_leg, parts.r_leg

    local l_shoulder_att = parts.l_shoulder_att
    local r_shoulder_att = parts.r_shoulder_att
    local neck_att = parts.neck_att

    local l_shoulder = l_shoulder_att and l_shoulder_att.WorldPosition or (l_arm.CFrame * Vector3.new(0, 1, 0))
    local r_shoulder = r_shoulder_att and r_shoulder_att.WorldPosition or (r_arm.CFrame * Vector3.new(0, 1, 0))
    local neck = neck_att and neck_att.WorldPosition or (torso.CFrame * Vector3.new(0, 1, 0))

    return {
        head = head.Position,
        neck = neck,
        spine = torso.Position,
        waist = hrp.Position,
        l_shoulder = l_shoulder,
        l_elbow = l_arm.Position,
        l_hand = l_arm.CFrame * Vector3.new(0, -1, 0),
        r_shoulder = r_shoulder,
        r_elbow = r_arm.Position,
        r_hand = r_arm.CFrame * Vector3.new(0, -1, 0),
        l_hip = l_leg.CFrame * Vector3.new(0, 1, 0),
        l_knee = l_leg.Position,
        l_foot = l_leg.CFrame * Vector3.new(0, -1, 0),
        r_hip = r_leg.CFrame * Vector3.new(0, 1, 0),
        r_knee = r_leg.Position,
        r_foot = r_leg.CFrame * Vector3.new(0, -1, 0),
    }
end

local team_cache = {}
local tagTable   = nil
local tags_ready = false
local stateByCb = setmetatable({}, { __mode = "k" })
local lastStateFlush = 0

local function acquireTagTable()
 local RS = game:GetService("ReplicatedStorage")
 local inst = RS:FindFirstChild("client")
        and RS.client:FindFirstChild("namespace")
            and RS.client.namespace:FindFirstChild("ClientPlayerTags")
 if not inst then return false end

    local oldId
    if getthreadidentity then oldId = getthreadidentity() end
    if setthreadidentity then pcall(setthreadidentity, 2) end

    local ok, mod = pcall(require, inst)

    if setthreadidentity and oldId then pcall(setthreadidentity, oldId) end

    if not ok or type(mod) ~= "table" then return false end
 local CPT = mod.ClientPlayerTags
    if type(CPT) ~= "table" or type(CPT.set_for_player) ~= "function" then return false end

 local _, tt = pcall(debug.getupvalue, CPT.set_for_player, 1)
    if type(tt) ~= "table" then return false end
 tagTable = tt
    return true
end

local function extractState(cb)
    for i = 1, 12 do
        local ok, val = pcall(debug.getupvalue, cb, i)
        if ok and type(val) == "table" then
 local okf, fr = pcall(rawget, val, "is_player_friendly")
 local oki, id = pcall(rawget, val, "ingame_id")
 if okf and fr ~= nil and oki and type(id) == "number" then
 return val
            end
        end
    end
    return nil
end

local function getWeaponInfo(st)
    local ew = rawget(st, "equipped_weapon")
 if type(ew) ~= "table" then return nil, nil end
 local build = rawget(ew, "build")
 if type(build) ~= "table" then return nil, nil end
 local wd = rawget(build, "weapon_data")
 if type(wd) ~= "table" then return nil, nil end
 local name
    local base = rawget(wd, "base_instance")
 if typeof(base) == "Instance" then name = base.Name end
 return name, rawget(wd, "category_name")
end

local function refreshTeamCache()
 if not tagTable then return end
    local fresh = {}
    local nowClock = os.clock()
    if nowClock - lastStateFlush > 5 then
        lastStateFlush = nowClock
        table.clear(stateByCb)
    end
    for _userId, cb in pairs(tagTable) do
        if type(cb) == "function" then

 local st = stateByCb[cb]
            if not st or rawget(st, "ingame_id") == nil then
 st = extractState(cb)
                stateByCb[cb] = st
            end
            if st then
                local id = rawget(st, "ingame_id")
 if id then
                    local wname, wcat = getWeaponInfo(st)
                    fresh[id] = {
                        friendly = rawget(st, "is_player_friendly"),
 dead     = rawget(st, "dead"),
 name     = rawget(st, "player_name"),
 hrp      = rawget(st, "humanoid_root_part"),
 char     = rawget(st, "character"),
 weapon   = wname,
                        category = wcat,
                        nvg      = rawget(st, "using_nvg"),
 vel      = rawget(st, "cached_velocity_magnitude"),
 }
                end
            end
        end
    end
    team_cache = fresh
end

task.spawn(function()
    for attempt = 1, 20 do
        if acquireTagTable() then
            tags_ready = true
            DBG.force("[ManulHook] ClientPlayerTags ready")
 return
        end
        task.wait(0.5)
    end
    DBG.force("[ManulHook] ClientPlayerTags unavailable")
end)

local cache = {}

local function newDrawing(cls, props)
 local d
    local cfg = getgenv().RCConfig
    if cfg and cfg.EspEngine == "Drawing" and global_Drawing and typeof(global_Drawing) == "table" and global_Drawing.new then
 local ok, res = pcall(function() return global_Drawing.new(cls) end)
        if ok and res then d = res end
    end
    if not d then
        d = Drawing.new(cls)
    end
    for k, v in pairs(props) do
        if k == "ZIndex" or k == "Font" then
 pcall(function() d[k] = v end)
        else
            d[k] = v
        end
    end
    return d
end

local FONT_MAP = {
    UI = Drawing.Fonts.UI, System = Drawing.Fonts.System,
    Plex = Drawing.Fonts.Plex, Monospace = Drawing.Fonts.Monospace,
}
local function espFontEnum()
    return FONT_MAP[getgenv().RCConfig.EspFont] or Drawing.Fonts.UI
end
local function espFontSize(delta)
    return math.max(6, (getgenv().RCConfig.EspFontSize or 13) + (delta or 0))
end

local function snapV2(x, y)
    return Vector2.new(math.round(x), math.round(y))
end

local function getOrCreate(uid)
    if cache[uid] then return cache[uid] end
    local cfg = getgenv().RCConfig
    local s = {
        Box        = newDrawing("Square", { Filled=false, Thickness=cfg.Thickness, Visible=false }),
 BoxFill    = newDrawing("Square", { Filled=true, Transparency=0.25, Visible=false }),
 Tracer     = newDrawing("Line", { Thickness=cfg.Thickness, Visible=false }),
        Name       = newDrawing("Text", { Size=espFontSize(0), Center=true, Outline=true,
                                            OutlineColor=Color3.new(0,0,0), Font=espFontEnum(), Visible=false }),
        Weapon     = newDrawing("Text", { Size=espFontSize(-1), Center=true, Outline=true,
                                            OutlineColor=Color3.new(0,0,0), Font=espFontEnum(), Visible=false }),
        Dist       = newDrawing("Text", { Size=espFontSize(-2), Center=true, Outline=true,
                                            OutlineColor=Color3.new(0,0,0), Font=espFontEnum(), Visible=false }),
        HeadCircle = newDrawing("Circle", { Filled=false, Thickness=cfg.Thickness, Visible=false }),
 LookLine   = newDrawing("Line", { Thickness=cfg.Thickness, Visible=false }),
        Arrow      = newDrawing("Triangle",{ Filled=true, Transparency=1, Visible=false }),
 Corners    = {},
        Skel       = {},
        Cham       = nil,
    }
    for i = 1, 8 do
        s.Corners[i] = newDrawing("Line", { Thickness=cfg.Thickness, Visible=false })
 end
    for i = 1, SKEL_LINE_COUNT do
        s.Skel[i] = newDrawing("Line", { Thickness=cfg.Thickness, Visible=false })
 end
    cache[uid] = s
    return s
end

local function hideOnscreen(s)
    s.Box.Visible   = false
    s.BoxFill.Visible = false
    s.Tracer.Visible = false
    s.Name.Visible  = false
    s.Weapon.Visible = false
    s.Dist.Visible  = false
    s.HeadCircle.Visible = false
    s.LookLine.Visible = false
    for _, l in ipairs(s.Corners) do l.Visible = false end
    for _, l in ipairs(s.Skel) do l.Visible = false end
end

local function hideAll(s)
    hideOnscreen(s)
    s.Arrow.Visible = false
    if s.Cham then s.Cham.Enabled = false end
end

local function removeCache(uid)
    local s = cache[uid]
    if not s then return end
    s.Box:Remove(); s.BoxFill:Remove(); s.Tracer:Remove(); s.Name:Remove()
    s.Weapon:Remove(); s.Dist:Remove()
    s.HeadCircle:Remove()
    s.LookLine:Remove()
    s.Arrow:Remove()
    for _, l in ipairs(s.Corners) do l:Remove() end
    for _, l in ipairs(s.Skel) do l:Remove() end
    if s.Cham then pcall(function() s.Cham:Destroy() end) end
    cache[uid] = nil
end

local GRENADE_RING_SEGMENTS = 20

local grenadeCache = {}
local GrenadeWarningText = Drawing.new("Text")
GrenadeWarningText.Size = 22
GrenadeWarningText.Center = true
GrenadeWarningText.Outline = true
GrenadeWarningText.Color = Color3.fromRGB(255, 30, 30)
GrenadeWarningText.Visible = false

local GrenadeArrow = Drawing.new("Triangle")
GrenadeArrow.Filled = true
GrenadeArrow.Color = Color3.fromRGB(255, 40, 40)
GrenadeArrow.Transparency = 1
GrenadeArrow.Visible = false

local function getOrCreateGrenade(id)
 if grenadeCache[id] then return grenadeCache[id] end

    local text = Drawing.new("Text")
 text.Size = 13
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Visible = false

    local circle = Drawing.new("Circle")
 circle.NumSides = 16
    circle.Thickness = 1.5
    circle.Filled = false
    circle.Color = Color3.fromRGB(255, 120, 30)
    circle.Visible = false

    local ring = {}
    for i = 1, GRENADE_RING_SEGMENTS do
        local l = Drawing.new("Line")
 l.Thickness = 2
        l.Color = Color3.fromRGB(255, 40, 40)
        l.Visible = false
        ring[i] = l
    end

    local heading = Drawing.new("Line")
 heading.Thickness = 1
    heading.Color = Color3.fromRGB(255, 120, 30)
    heading.Visible = false

    grenadeCache[id] = { Text = text, Circle = circle, Ring = ring, Heading = heading,
        landPos = nil, landValid = false, lastPredict = 0 }
    return grenadeCache[id]
end

local function removeGrenadeCache(id)
    local g = grenadeCache[id]
    if not g then return end
    pcall(function() g.Text:Remove() end)
    pcall(function() g.Circle:Remove() end)
    pcall(function() g.Heading:Remove() end)
    if g.Ring then for _, l in ipairs(g.Ring) do pcall(function() l:Remove() end) end end
    grenadeCache[id] = nil
end

local function _hideAllGrenade(g)
    g.Text.Visible = false
    g.Circle.Visible = false
    if g.Heading then g.Heading.Visible = false end
    if g.Ring then for _, l in ipairs(g.Ring) do l.Visible = false end end
end

local THROWN_LIFETIME     = 8
local EXPLOSION_SHOW_TIME = 3

local thrownGrenades      = {}
local grenadeExplosions   = {}
local grenadeConns        = {}

local GRENADE_OWNER_RANGE = 20
local function resolveGrenadeOwner(pos)
    if (Camera.CFrame.Position - pos).Magnitude < GRENADE_OWNER_RANGE * 0.6 then
        return "self"
 end
    local folder = workspace:FindFirstChild("characters")
 if not folder then return "unknown" end
 local bestD, bestName = GRENADE_OWNER_RANGE, nil
    for _, m in ipairs(folder:GetChildren()) do
        local hrp = m:FindFirstChild("humanoid_root_part")
 if hrp then
            local d = (hrp.Position - pos).Magnitude
            if d < bestD then bestD, bestName = d, m.Name end
        end
    end
    if not bestName then return "unknown" end
 if bestName == "StarterCharacter" or bestName == tostring(LocalId) then return "self" end
 local uid = tonumber(bestName)
    local t = uid and team_cache[uid]
    if t and t.friendly then return "ally" end
 return "enemy"
end

local function isThrownGrenadeBody(c)

 if not c:IsA("BasePart") then return false end
 if c.Name == "receiver" then
 return c.Size.Magnitude < 1.6
    end
    return c.Name:sub(-7) == "_thrown"
end

local function startGrenadeListener()
 task.spawn(function()
        local ignore = workspace:WaitForChild("ignore", 10)
 local effects = ignore and ignore:WaitForChild("effects", 10)
 if effects then
            table.insert(grenadeConns, effects.ChildAdded:Connect(function(c)
                if isThrownGrenadeBody(c) then
                    thrownGrenades[c] = { seen = os.clock(), spawn = c.Position }
                end
            end))
        end
        table.insert(grenadeConns, workspace.ChildAdded:Connect(function(c)
            if c:IsA("Explosion") then
 local pos = c.Position

                local cfg = getgenv().RCConfig
                if cfg and cfg.GrenadeIgnoreAllies ~= false then
                    local now = os.clock()
                    for _, info in pairs(thrownGrenades) do
                        if info.owner == "ally"
                            and info.lastPos
                            and now - info.seen < THROWN_LIFETIME
                            and (info.lastPos - pos).Magnitude < 15 then
                            return
                        end
                    end
                end
                table.insert(grenadeExplosions, { pos = pos, radius = c.BlastRadius, t = os.clock() })
            end
        end))
    end)
end
startGrenadeListener()

local FovCircle = newDrawing("Circle", {
 Color=Color3.new(1,1,1), Thickness=1, Filled=false, Transparency=0.7, Visible=false
})
local SilentAimFovCircle = newDrawing("Circle", {
 Color=Color3.fromRGB(255, 100, 100), Thickness=1, Filled=false, Transparency=0.5, Visible=false
})
local SilentAimTargetLine = newDrawing("Line", {
 Color=Color3.fromRGB(255, 80, 80), Thickness=1, Transparency=0.8, Visible=false
})

local casterModule = nil
local origNetworkHit = nil
local origFire = nil
local weaponParticles = nil
local origEmitWeaponParticles = nil
local tracerConnection = nil
local networkEncodeModule = nil
local origWriteExactPosition = nil
local lastShotOrigin = Vector3.new()

local CrosshairDot = newDrawing("Circle", {
 Filled       = true,
    Thickness    = 1,
    Transparency = 1.0,
    Visible      = false
})

local CrosshairLines = {
    Left   = newDrawing("Line", { Thickness = 1.5, Transparency = 1.0, Visible = false }),
 Right  = newDrawing("Line", { Thickness = 1.5, Transparency = 1.0, Visible = false }),
 Top    = newDrawing("Line", { Thickness = 1.5, Transparency = 1.0, Visible = false }),
 Bottom = newDrawing("Line", { Thickness = 1.5, Transparency = 1.0, Visible = false }),
}

local charsFolderRef, ignoreFolderRef
local LocalIdStr = tostring(LocalId)
local function getCharsFolder()
 if not (charsFolderRef and charsFolderRef.Parent) then
        charsFolderRef = workspace:FindFirstChild("characters")
 end
    return charsFolderRef
end
local function getIgnoreFolder()
    if not (ignoreFolderRef and ignoreFolderRef.Parent) then
        ignoreFolderRef = workspace:FindFirstChild("ignore")
 end
    return ignoreFolderRef
end

local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Exclude
visParams.IgnoreWater = true

local MATERIAL_PEN = {
    Asphalt = 2, Basalt = 0.75, Brick = 2.5, Cardboard = 6, Carpet = 8, CeramicTiles = 1.5, ClayRoofTiles = 2,
    Cobblestone = 2.75, Concrete = 1, CorrodedMetal = 0.15, CrackedLava = 2, DiamondPlate = 0.1, Fabric = 8,
    Foil = 0.3, ForceField = 0, Glacier = 4, Glass = 6, Granite = 0.75, Grass = 7, Ground = 2, Ice = 4,
    LeafyGrass = 7, Leather = 5, Limestone = 1.5, Marble = 1, Metal = 0.15, Mud = 8, Neon = 4, Pavement = 1.75,
    Pebble = 2.75, Plaster = 3, Plastic = 4, Rock = 0.9, RoofShingles = 4, Rubber = 4, Salt = 2, Sand = 2,
    Sandstone = 1.75, Slate = 1.1, SmoothPlastic = 4, Snow = 8, Water = 2.5, Wood = 5, WoodPlanks = 6,
}
local DEFAULT_PEN_ABILITY = 0.6
local penMult = 1
local currentWeaponProperties = nil

local thickParams = RaycastParams.new()
thickParams.FilterType = Enum.RaycastFilterType.Include
local function measureThickness(hitPart, entryPos, unitDir)
    thickParams.FilterDescendantsInstances = { hitPart }
    local far = entryPos + unitDir * 60
    local back = workspace:Raycast(far, -unitDir * 60, thickParams)
    if back then
        return (back.Position - entryPos).Magnitude
    end
    return 1
end

local function isVisible(targetPart, charModel, penetrate)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local dir = destination - origin

    local params = visParams
    local folder = getCharsFolder()
    local myChar = folder and folder:FindFirstChild(LocalIdStr)

    local ignoreList = {Camera}
    if myChar then table.insert(ignoreList, myChar) end
    if charModel then table.insert(ignoreList, charModel) end
    local ign = getIgnoreFolder()
    if ign then
        table.insert(ignoreList, ign)
    end

    params.FilterDescendantsInstances = ignoreList

    local currentOrigin = origin
    local currentDir = dir
    local maxAttempts = penetrate and 10 or 5
    local attempts = 0

    local allowed, spent = 0, 0
    if penetrate then
        local ability = currentWeaponProperties and currentWeaponProperties.bullet_penetration_ability or DEFAULT_PEN_ABILITY
        allowed = ability * penMult * (getgenv().RCConfig.WallbangScale or 1)
    end

    while attempts < maxAttempts do
        local result = workspace:Raycast(currentOrigin, currentDir, params)
        if not result then
            return true
        end

        local hitPart = result.Instance
        local hitName = string.lower(hitPart.Name)

        local isPenetrable = not hitPart.CanCollide
            or hitPart.Transparency > 0.8
            or hitPart.Name == "Glass"
            or hitPart.Material == Enum.Material.Grass
            or string.find(hitName, "leaf")
            or string.find(hitName, "leaves")
            or string.find(hitName, "grass")
            or string.find(hitName, "bush")
            or string.find(hitName, "foliage")
            or string.find(hitName, "tree")
            or string.find(hitName, "trunk")
            or string.find(hitName, "branch")
            or string.find(hitName, "log")

 if isPenetrable then

            table.insert(ignoreList, hitPart)
            params.FilterDescendantsInstances = ignoreList

            currentOrigin = result.Position + currentDir.Unit * 0.05
            currentDir = destination - currentOrigin

            if currentDir.Magnitude < 0.1 then
                return true
            end
            elseif penetrate then

            local unitDir = currentDir.Unit
            local thickness = measureThickness(hitPart, result.Position, unitDir)
            local matPen = MATERIAL_PEN[result.Material.Name] or 1
            if matPen <= 0 then return false end
            spent = spent + thickness / matPen
            if spent > allowed then return false end

            table.insert(ignoreList, hitPart)
            params.FilterDescendantsInstances = ignoreList
            currentOrigin = result.Position + unitDir * 0.05
            currentDir = destination - currentOrigin
            if currentDir.Magnitude < 0.1 then
                return true
            end
            else
            return false
        end
        attempts = attempts + 1
    end

    return false
end

local visMemo = {}
local function isVisibleMemo(part, charModel)
    if not part then return false end
    local cached = visMemo[part]
    if cached ~= nil then return cached end
    local v = isVisible(part, charModel)
    visMemo[part] = v
    return v
end

local function getDropCompensation(origin, targetPos)
    local cfg = getgenv().RCConfig
    if not cfg or not cfg.DropCompEnabled then return Vector3.new() end

    local dist = (targetPos - origin).Magnitude
    local g = workspace.Gravity

    local v0 = 900
    local v_drop = 0.0005
    local isRocket = false

    if currentWeaponProperties then
        v0 = currentWeaponProperties.velocity or 900
        v_drop = currentWeaponProperties.velocity_drop or 0.0005
        if currentWeaponProperties.explosion_on_hit or currentWeaponProperties.suppression_type == "rocket" or currentWeaponProperties.is_physical then
 isRocket = true
        end
    end

    local denominator = v0 - dist * v_drop
    if denominator <= 100 then denominator = 100 end

    local t = dist / denominator
    local dropComp = g * (t ^ 2)

    local maxCap = isRocket and 350 or 50
    if dropComp > maxCap then dropComp = maxCap end
    if dropComp < 0 then dropComp = 0 end

    return Vector3.new(0, dropComp, 0)
end

local function getMyHrp()
    local folder = getCharsFolder()
    local myChar = folder and folder:FindFirstChild(LocalIdStr)
    if myChar then
        local hrp = myChar:FindFirstChild("humanoid_root_part")
 if hrp then return hrp.Position end
    end
    return Camera.CFrame.Position
end

local function predictGrenadeLanding(startPos, startVel)

    if startVel.Magnitude < 8 then return startPos, true end

    local g = workspace.Gravity
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local ignore = { Camera }
    local chars = workspace:FindFirstChild("characters"); if chars then table.insert(ignore, chars) end
 local gren  = workspace:FindFirstChild("grenades"); if gren  then table.insert(ignore, gren)  end
    local ign   = workspace:FindFirstChild("ignore"); if ign   then table.insert(ignore, ign)   end
    params.FilterDescendantsInstances = ignore

    local step = 0.08
    local p, v = startPos, startVel
    for _ = 1, 75 do
        local nextV = v - Vector3.new(0, g * step, 0)
        local nextP = p + v * step + Vector3.new(0, -0.5 * g * step * step, 0)
        local seg = nextP - p
        if seg.Magnitude > 0.01 then
            local hit = workspace:Raycast(p, seg, params)
            if hit then return hit.Position, true end
        end
        p, v = nextP, nextV
    end
    return p, false
end

local function drawGroundRing(ringLines, worldCenter, radius, color, thickness)
    local pts = {}
    for i = 0, GRENADE_RING_SEGMENTS do
        local ang = (i / GRENADE_RING_SEGMENTS) * math.pi * 2
        local wp = worldCenter + Vector3.new(math.cos(ang) * radius, 0, math.sin(ang) * radius)
        local sp, on = Camera:WorldToViewportPoint(wp)
        pts[i] = { pos = Vector2.new(sp.X, sp.Y), on = on and sp.Z > 0 }
    end
    for i = 1, GRENADE_RING_SEGMENTS do
        local a, b = pts[i - 1], pts[i]
        local line = ringLines[i]
        if a.on and b.on then
            line.From = a.pos; line.To = b.pos
            line.Color = color; line.Thickness = thickness
            line.Visible = true
        else
            line.Visible = false
        end
    end
end

local function drawCornerBox(lines, x, y, w, h, color, thick, opacity)
    local len = math.clamp(math.min(w, h) * 0.28, 4, 14)
    local segs = {
        {x, y,       x + len, y      }, {x, y,       x, y + len      },
        {x + w, y,   x + w - len, y  }, {x + w, y,   x + w, y + len  },
        {x, y + h,   x + len, y + h  }, {x, y + h,   x, y + h - len  },
        {x + w, y+h, x+w-len, y + h  }, {x + w, y+h, x + w, y + h-len},
    }
    for i = 1, 8 do
        local d = segs[i]
        local l = lines[i]
        l.From = Vector2.new(d[1], d[2])
        l.To   = Vector2.new(d[3], d[4])
        l.Color = color; l.Thickness = thick; l.Transparency = opacity or 1
        l.Visible = true
    end
end

local function drawEdgeArrow(tri, worldPos, center, color, radius, opacity)
    local rel = Camera.CFrame:PointToObjectSpace(worldPos)
    local dir = Vector2.new(rel.X, -rel.Y)
    if dir.Magnitude < 1 then dir = Vector2.new(0, -1) end
    dir = dir.Unit
    local tip  = center + dir * radius
    local back = center + dir * (radius - 22)
    local perp = Vector2.new(-dir.Y, dir.X)
    tri.PointA = tip
    tri.PointB = back + perp * 11
    tri.PointC = back - perp * 11
    tri.Color = color
    tri.Transparency = opacity or 1
    tri.Visible = true
    return (tip + back) * 0.5, dir
end

local chamHolder = Instance.new("Folder")
chamHolder.Name = "\0_rc"
if syn and syn.protect_gui then
 syn.protect_gui(chamHolder)
elseif protect_gui then
    protect_gui(chamHolder)
end
chamHolder.Parent = getGuiContainer()
if not chamHolder.Parent then chamHolder.Parent = Camera end

local function updateCham(s, charModel, color, cfg)
    if not cfg.ShowChams then
        if s.Cham then s.Cham.Enabled = false end
        return
    end
    if not s.Cham or not s.Cham.Parent then
        if s.Cham then pcall(function() s.Cham:Destroy() end) end
        local h = Instance.new("Highlight")
 h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = chamHolder
        s.Cham = h
    end
    s.Cham.Adornee = charModel
    s.Cham.FillColor = color
    s.Cham.OutlineColor = color
    s.Cham.FillTransparency = cfg.ChamsFillTransparency or 0.55
    s.Cham.OutlineTransparency = 0
    s.Cham.Enabled = true
end

local Radar = {
    Bg     = newDrawing("Square", { Filled=true, Color=Color3.fromRGB(14,14,20),   Transparency=0.45, Visible=false }),
    Border = newDrawing("Square", { Filled=false, Color=Color3.fromRGB(180,180,195), Thickness=1, Transparency=0.85, Visible=false }),
 HLine  = newDrawing("Line", { Color=Color3.fromRGB(80,80,95), Thickness=1, Transparency=0.5, Visible=false }),
    VLine  = newDrawing("Line", { Color=Color3.fromRGB(80,80,95), Thickness=1, Transparency=0.5, Visible=false }),
    Center = newDrawing("Circle", { Filled=true, Radius=3, Color=Color3.fromRGB(0,200,255), Visible=false }),
 Dots   = {},
}
local function radarGetDot(i)
    if Radar.Dots[i] then return Radar.Dots[i] end
    local d = newDrawing("Circle", { Filled=true, NumSides=12, Radius=3, Visible=false })
 Radar.Dots[i] = d
    return d
end
local function radarHideAll()
    Radar.Bg.Visible = false; Radar.Border.Visible = false
    Radar.HLine.Visible = false; Radar.VLine.Visible = false; Radar.Center.Visible = false
    for _, d in ipairs(Radar.Dots) do d.Visible = false end
end

local hudTextTemplate = {
    Size = 13,
    Outline = true,
    OutlineColor = Color3.fromRGB(0, 0, 0),
    Font = Drawing.Fonts.Monospace,
    Color = Color3.fromRGB(255, 255, 255),
    Visible = false,
}
local HudLineWeapon = newDrawing("Text", hudTextTemplate)
local HudLineHP = newDrawing("Text", hudTextTemplate)
local HudLineAmmo = newDrawing("Text", hudTextTemplate)

local cachedStats = nil
local cachedWeapon = nil
local lastGcScanStats = 0
local lastGcScanWeapon = 0

function EnvPack.gcFindTable(opts, pred)
 if type(filtergc) == "function" then
 local ok, list = pcall(filtergc, "table", opts, false)
 if ok and type(list) == "table" then
 for _, v in ipairs(list) do
                if not pred or pred(v) then
                    return v
                end
            end
            return nil
        end
    end
    for _, v in ipairs(getgc(true)) do
        if type(v) == "table" and (not pred or pred(v)) then

 local match = true
            for _, k in ipairs(opts.Keys or {}) do
                if rawget(v, k) == nil then
                    match = false
                    break
                end
            end
            if match then
                for k, val in pairs(opts.KeyValuePairs or {}) do
                    if rawget(v, k) ~= val then
                        match = false
                        break
                    end
                end
            end
            if match then return v end
        end
    end
    return nil
end

local cachedLocalWeaponName = nil
local lastWeaponNameTime = 0

local function getLocalWeaponName()
    local now = tick()
    if cachedLocalWeaponName and (now - lastWeaponNameTime) < 0.5 then
        return cachedLocalWeaponName
    end

    local charsFolder = workspace:FindFirstChild("characters")
 local activeChar = charsFolder and charsFolder:FindFirstChild("StarterCharacter")
 if not activeChar then
        cachedLocalWeaponName = nil
        return nil
    end

    if cachedStats and cachedStats.character == activeChar then
        local wname = getWeaponInfo(cachedStats)
        if wname then
            cachedLocalWeaponName = wname
            lastWeaponNameTime = now
            return wname
        end

        local vm = rawget(cachedStats, "viewmodel")
 if typeof(vm) == "Instance" and vm.Parent ~= nil then
 local weapon = vm.Name:match("_([^_}]+)$")
 if weapon and weapon ~= "" then
 cachedLocalWeaponName = weapon
                lastWeaponNameTime = now
                return weapon
            end
        end
    end

    return cachedLocalWeaponName
end

local function getLocalStats()
    local charsFolder = workspace:FindFirstChild("characters")
 local activeChar = charsFolder and charsFolder:FindFirstChild("StarterCharacter")

 if not activeChar then
        cachedStats = nil
        return nil
    end

    if cachedStats and cachedStats.character == activeChar then
        return cachedStats
    end

    local now = tick()
    if (now - lastGcScanStats) < 4 then
        return nil
    end
    lastGcScanStats = now

    cachedStats = nil
    cachedStats = EnvPack.gcFindTable(
        {
            Keys = { "health" },
            KeyValuePairs = { character = activeChar },
        },
        function(v)
            return rawget(v, "health") ~= nil and rawget(v, "character") == activeChar
        end
    )
    return cachedStats
end

local function getWeaponAmmo()
    local charsFolder = workspace:FindFirstChild("characters")
 local activeChar = charsFolder and charsFolder:FindFirstChild("StarterCharacter")

 if not activeChar then
        cachedWeapon = nil
        return nil
    end

    if cachedWeapon and rawget(cachedWeapon, "is_equipped") == true and type(rawget(cachedWeapon, "ammo")) == "table" then
 local vm = rawget(cachedWeapon, "viewmodel")
 if typeof(vm) == "Instance" and vm.Parent ~= nil then

 local ammo = cachedWeapon.ammo
            local rounds = tonumber(ammo.rounds_in_magazine) or 0
            local chambered = ammo.is_round_chambered and 1 or 0
            local totalLoaded = rounds + chambered

            local maxCap = 30
            local meta = rawget(ammo, "metadata")
 if type(meta) == "table" and rawget(meta, "magazine_capacity") then
 maxCap = tonumber(meta.magazine_capacity) or 30
            end

            local magCount = 0
            local lm = rawget(ammo, "loose_magazines")
 if type(lm) == "table" then
 for _ in pairs(lm) do
                    magCount = magCount + 1
                end
            end

            return totalLoaded, maxCap, magCount
        end
    end

    local now = tick()

    if (now - lastGcScanWeapon) < 3 then

        if cachedWeapon and type(rawget(cachedWeapon, "ammo")) == "table" then
 local ammo = cachedWeapon.ammo
            local rounds = tonumber(ammo.rounds_in_magazine) or 0
            local chambered = ammo.is_round_chambered and 1 or 0
            return rounds + chambered, 30, 0
        end
        return nil
    end
    lastGcScanWeapon = now

    cachedWeapon = nil
    cachedWeapon = EnvPack.gcFindTable(
        {
            KeyValuePairs = { type = "weapon", is_equipped = true },
        },
        function(v)
            if rawget(v, "type") ~= "weapon" or rawget(v, "is_equipped") ~= true then
                return false
            end
            local vm = rawget(v, "viewmodel")
            return typeof(vm) == "Instance" and vm.Parent ~= nil
        end
    )

    if cachedWeapon then
        local ammo = rawget(cachedWeapon, "ammo")
 if type(ammo) == "table" then
 local rounds = tonumber(ammo.rounds_in_magazine) or 0
            local chambered = ammo.is_round_chambered and 1 or 0
            local totalLoaded = rounds + chambered

            local maxCap = 30
            local meta = rawget(ammo, "metadata")
 if type(meta) == "table" and rawget(meta, "magazine_capacity") then
 maxCap = tonumber(meta.magazine_capacity) or 30
            end

            local magCount = 0
            local lm = rawget(ammo, "loose_magazines")
 if type(lm) == "table" then
 for _ in pairs(lm) do
                    magCount = magCount + 1
                end
            end

            return totalLoaded, maxCap, magCount
        end
    end
    return nil
end

local lastHudWpn = ""
local lastHudHP = ""
local lastHudAmmo = ""

local function hideAllHudLines()
 HudLineWeapon.Visible = false
    HudLineHP.Visible = false
    HudLineAmmo.Visible = false
end

local function updateRadarHud(cfg)
    if not cfg.ShowRadarHud then
        hideAllHudLines()
        return
    end

    local stats = getLocalStats()
    local ammoLoaded, maxCap, magCount = getWeaponAmmo()

    if not stats or stats.dead then
        hideAllHudLines()
        return
    end

    local vp = Camera.ViewportSize
    local size = cfg.RadarSize or 180
    local margin = 14
    local ox = vp.X - size - margin
    local oy = margin
    local startY = cfg.RadarEnabled and (oy + size + 6) or oy
    local lineH = 16
    local x = ox + 4

    local wpnStr = "WPN: " .. (getLocalWeaponName() or "--")
 if wpnStr ~= lastHudWpn then
        HudLineWeapon.Text = wpnStr
        lastHudWpn = wpnStr
    end
    HudLineWeapon.Position = snapV2(x, startY)
    HudLineWeapon.Color = Color3.fromRGB(255, 220, 130)
    HudLineWeapon.Visible = true

    local hpVal = math.round(stats.health)
    local maxHp = 100
    local hpStr = string.format("HP: %d/%d", hpVal, maxHp)
 if hpStr ~= lastHudHP then
        HudLineHP.Text = hpStr
        lastHudHP = hpStr
    end
    HudLineHP.Position = snapV2(x, startY + lineH)
    if hpVal > 50 then
        HudLineHP.Color = Color3.fromRGB(255, 255, 255)
    elseif hpVal > 25 then
        HudLineHP.Color = Color3.fromRGB(255, 200, 0)
    else
        HudLineHP.Color = Color3.fromRGB(255, 50, 50)
    end
    HudLineHP.Visible = true

    local ammoStr
    if ammoLoaded then
        ammoStr = string.format("AMMO: %d/%d | MAGS: %d", ammoLoaded, maxCap, magCount)
    else
        ammoStr = "AMMO: --/-- | MAGS: --"
 end
    if ammoStr ~= lastHudAmmo then
        HudLineAmmo.Text = ammoStr
        lastHudAmmo = ammoStr
    end
    HudLineAmmo.Position = snapV2(x, startY + lineH * 2)
    HudLineAmmo.Color = Color3.fromRGB(200, 200, 200)
    HudLineAmmo.Visible = true
end

local function radarRender(cfg)
    if cfg.RadarEnabled then
        local vp = Camera.ViewportSize
        local size = cfg.RadarSize or 180
        local half = size * 0.5
        local margin = 14
        local ox = vp.X - size - margin
        local oy = margin
        local cx, cy = ox + half, oy + half

        Radar.Bg.Size = Vector2.new(size, size);     Radar.Bg.Position = Vector2.new(ox, oy);     Radar.Bg.Visible = true
        Radar.Border.Size = Vector2.new(size, size); Radar.Border.Position = Vector2.new(ox, oy); Radar.Border.Visible = true
        Radar.HLine.From = Vector2.new(ox, cy);      Radar.HLine.To = Vector2.new(ox + size, cy); Radar.HLine.Visible = true
        Radar.VLine.From = Vector2.new(cx, oy);      Radar.VLine.To = Vector2.new(cx, oy + size); Radar.VLine.Visible = true
        Radar.Center.Position = Vector2.new(cx, cy); Radar.Center.Radius = math.max(2, (cfg.RadarDotSize or 3)); Radar.Center.Visible = true

        local myPos = getMyHrp()
        local f = Camera.CFrame.LookVector
        local flatF = Vector3.new(f.X, 0, f.Z)
        if flatF.Magnitude < 1e-3 then flatF = Vector3.new(0, 0, -1) end
        flatF = flatF.Unit
        local rightVec = Vector3.new(-flatF.Z, 0, flatF.X)
        local range = cfg.RadarRange or 150
        local maxR = half - 3

        local charFolder = getCharsFolder()
        local n = 0
        if charFolder then
            for _, charModel in ipairs(charFolder:GetChildren()) do
                local uid = tonumber(charModel.Name)
                if uid and uid ~= LocalId then
                    local tdata = team_cache[uid]
                    local friendly = tdata and tdata.friendly
                    local skip = (tdata and tdata.dead) or (cfg.TeamCheck and friendly)
                    local hrp = not skip and charModel:FindFirstChild("humanoid_root_part")
 if hrp then
                        local rel = hrp.Position - myPos
                        local relFlat = Vector3.new(rel.X, 0, rel.Z)
                        local dx = (relFlat:Dot(rightVec) / range) * half
                        local dy = -(relFlat:Dot(flatF) / range) * half
                        local mag = math.sqrt(dx * dx + dy * dy)
                        if mag > maxR and mag > 0 then dx = dx / mag * maxR; dy = dy / mag * maxR end
                        n = n + 1
                        local dot = radarGetDot(n)
                        dot.Position = Vector2.new(cx + dx, cy + dy)
                        dot.Radius = cfg.RadarDotSize or 3
                        dot.Color = (friendly and cfg.AllyColor) or cfg.EnemyColor
                        dot.Visible = true
                    end
                end
            end
        end
        for i = n + 1, #Radar.Dots do Radar.Dots[i].Visible = false end
                        else
        radarHideAll()
    end

    updateRadarHud(cfg)
end

local ammoBoxes = {}
local ammoDraw  = {}

local function resolveAmmoPart(inst)
    if inst:IsA("BasePart") then return inst end
 if inst.PrimaryPart then return inst.PrimaryPart end
    return inst:FindFirstChildWhichIsA("BasePart", true)
end

local function refreshAmmoBoxes()
 local CS = game:GetService("CollectionService")
 local list, present = {}, {}
    for _, inst in ipairs(CS:GetTagged("interactable")) do
 local t = inst:GetAttribute("interactable_type")
 if type(t) == "string" and string.find(t, "refill") then
 local part = resolveAmmoPart(inst)
            if part then
                local id = inst:GetDebugId()
                list[#list+1] = { inst = inst, part = part, id = id }
                present[id] = true
            end
        end
    end
    ammoBoxes = list

    for id, d in pairs(ammoDraw) do
        if not present[id] then
            pcall(function() d.Box:Remove(); d.Text:Remove() end)
            ammoDraw[id] = nil
        end
    end
end

local function getOrCreateAmmo(id)
    if ammoDraw[id] then return ammoDraw[id] end
    local d = {
        Box  = newDrawing("Square", { Filled=false, Thickness=2, Visible=false }),
 Text = newDrawing("Text", { Size=13, Center=true, Outline=true,
                                      OutlineColor=Color3.new(0,0,0), Font=espFontEnum(), Visible=false }),
    }
    ammoDraw[id] = d
    return d
end

local function ammoRender(cfg)
    if not cfg.ShowAmmoBox then
        for _, d in pairs(ammoDraw) do d.Box.Visible = false; d.Text.Visible = false end
        return
    end
    local myPos = getMyHrp()
    local active = {}
    for _, b in ipairs(ammoBoxes) do
        if b.part and b.part.Parent then
            local pos = b.part.Position
            local sp, on = Camera:WorldToViewportPoint(pos)
            if on and sp.Z > 0 then
                active[b.id] = true
                local d = getOrCreateAmmo(b.id)
                local dist = (pos - myPos).Magnitude
                local r = math.clamp(500 / math.max(dist, 1), 6, 26)
                d.Box.Size      = Vector2.new(r * 2, r * 2)
                d.Box.Position  = snapV2(sp.X - r, sp.Y - r)
                d.Box.Color     = cfg.AmmoBoxColor
                d.Box.Thickness = math.max(cfg.Thickness or 1, 2)
                d.Box.Transparency = cfg.Opacity or 1
                d.Box.Visible   = true
                d.Text.Text     = string.format("AMMO  %d m", math.round(dist))
 d.Text.Size     = espFontSize(-1)
                d.Text.Color    = cfg.AmmoBoxColor
                d.Text.Transparency = cfg.Opacity or 1
                d.Text.Position = snapV2(sp.X, sp.Y + r + 2)
                d.Text.Visible  = true
            end
        end
    end
    for id, d in pairs(ammoDraw) do
        if not active[id] then d.Box.Visible = false; d.Text.Visible = false end
    end
end

local JOINT_TO_PART = {
    head = "head",
 neck = "torso",
 spine = "torso",
 waist = "torso",
 l_shoulder = "left_arm_vis",
 l_elbow = "left_arm_vis",
 l_hand = "left_arm_vis",
 r_shoulder = "right_arm_vis",
 r_elbow = "right_arm_vis",
 r_hand = "right_arm_vis",
 l_hip = "left_leg_vis",
 l_knee = "left_leg_vis",
 l_foot = "left_leg_vis",
 r_hip = "right_leg_vis",
 r_knee = "right_leg_vis",
 r_foot = "right_leg_vis",
}

local function getBestAimJoint(charModel, aimPartName, wallCheck, center, maxFov, penetrate)
 local joints = getJointPositions(charModel)
    if not joints then
        local targetName = (aimPartName == "auto") and "head" or aimPartName
 local p = charModel:FindFirstChild(targetName) or charModel:FindFirstChild("head")
 if p then
            if not wallCheck or isVisible(p, charModel, penetrate) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(p.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist2D <= maxFov then
                        return p, dist2D
                    end
                end
            end
        end
        return nil, nil
    end

    local bestJointPart, bestDist2D = nil, math.huge

    if aimPartName == "auto" then

 for name, pos in pairs(joints) do
            local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
            if onScreen and screenPos.Z > 0 then
                local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if dist2D <= maxFov and dist2D < bestDist2D then
                    local dummy = { Position = pos, Name = JOINT_TO_PART[name] or "head" }
 if not wallCheck or isVisible(dummy, charModel, penetrate) then
                        bestDist2D = dist2D
                        bestJointPart = dummy
                    end
                end
            end
        end
 else
        local name = aimPartName
        local pos = joints[name]
        if not pos then
            local p = charModel:FindFirstChild(name)
            if p then pos = p.Position end
        end
        if pos then
            local dummy = { Position = pos, Name = JOINT_TO_PART[name] or name }
            if not wallCheck or isVisible(dummy, charModel, penetrate) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
                if onScreen and screenPos.Z > 0 then
                    local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist2D <= maxFov then
                        bestDist2D = dist2D
                        bestJointPart = dummy
                    end
                end
            end
        end
    end

    return bestJointPart, bestDist2D
end

local muzzleVmCache, muzzleAttCache = nil, nil
local function getFovCenter(mode)
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    if mode ~= "muzzle" then return center end
 local stats = getLocalStats()
    local vm = stats and rawget(stats, "viewmodel")
 if typeof(vm) ~= "Instance" or vm.Parent == nil then return center end
 if vm ~= muzzleVmCache then
        muzzleVmCache = vm
        local rec = vm:FindFirstChild("receiver")
 muzzleAttCache = rec and rec:FindFirstChild("barrel")
 end
    local att = muzzleAttCache
    if not att or att.Parent == nil then return center end
    local cf = att.WorldCFrame
    local sp = Camera:WorldToViewportPoint(cf.Position + cf.LookVector * 500)
    if sp.Z <= 0 then return center end
    return Vector2.new(sp.X, sp.Y)
end

local function getAimTarget()
    local cfg = getgenv().RCConfig
    local charFolder = getCharsFolder()
    if not charFolder then return nil end

    local center  = getFovCenter(cfg.AimFovCenter)
    local best, bestDist = nil, math.huge
    local myPos = getMyHrp()

    for _, charModel in ipairs(charFolder:GetChildren()) do
        local uid = tonumber(charModel.Name)
        if not uid or uid == LocalId then continue end

        local tdata = team_cache[uid]
        if tdata and tdata.dead then continue end
        if cfg.TeamCheck and tdata and tdata.friendly then continue end

        local hrp = charModel:FindFirstChild("humanoid_root_part")
 if not hrp then continue end
        if (hrp.Position - myPos).Magnitude > (cfg.AimMaxDist or 300) then continue end

        local targetPart, dist2D = getBestAimJoint(charModel, cfg.AimPart or "head", cfg.AimWallCheck, center, math.min(cfg.AimFov, bestDist), cfg.AimWallbang)
 if targetPart and dist2D < bestDist then
            bestDist = dist2D
            best = { charModel=charModel, headPart=targetPart }
        end
    end
    return best
end

local lastSilentAimTime = 0
local cachedSilentAimTarget = nil
local function getSilentAimTarget()
    local now = os.clock()
    if now - lastSilentAimTime < 0.01 then
        return cachedSilentAimTarget
    end
    lastSilentAimTime = now

    local cfg = getgenv().RCConfig
    local charFolder = getCharsFolder()
    if not charFolder then
        cachedSilentAimTarget = nil
        return nil
    end

    local center  = getFovCenter(cfg.SilentAimFovCenter)
    local best, bestDist = nil, math.huge
    local myPos = getMyHrp()

    for _, charModel in ipairs(charFolder:GetChildren()) do
        local uid = tonumber(charModel.Name)
        if not uid or uid == LocalId then continue end

        local tdata = team_cache[uid]
        if tdata and tdata.dead then continue end
        if cfg.TeamCheck and tdata and tdata.friendly then continue end

        local hrp = charModel:FindFirstChild("humanoid_root_part")
 if not hrp then continue end
        local dist = (hrp.Position - myPos).Magnitude
        if dist > (cfg.SilentAimMaxDist or 200) then continue end

        local targetPart, dist2D = getBestAimJoint(charModel, cfg.SilentAimPart or "head", cfg.SilentAimWallCheck, center, math.min(cfg.SilentAimFov, bestDist), cfg.SilentAimWallbang)
 if targetPart and dist2D < bestDist then
            bestDist = dist2D
            best = { charModel=charModel, targetPart=targetPart, uid=uid }
        end
    end
    cachedSilentAimTarget = best
    return best
end

local function findCenterTarget(partName, radiusStuds, maxAngle, maxDist, wallCheck)
    local cfg = getgenv().RCConfig
    local folder = getCharsFolder()
    if not folder then return nil end

    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    local camPos = Camera.CFrame.Position
    local halfTan = math.tan(math.rad(Camera.FieldOfView) * 0.5)
    local best, bestDist = nil, math.huge

    for _, charModel in ipairs(folder:GetChildren()) do
        local uid = tonumber(charModel.Name)
        if not uid or uid == LocalId then continue end

        local tdata = team_cache[uid]
        if tdata and tdata.dead then continue end
        if cfg.TeamCheck and tdata and tdata.friendly then continue end

        local parts = getCharParts(charModel)
        local hrp = parts and parts.hrp or charModel:FindFirstChild("humanoid_root_part")
 if not hrp then continue end
        local dist = (hrp.Position - camPos).Magnitude
        if dist > maxDist or dist < 0.5 then continue end

        local angle = math.min(math.deg(math.atan(radiusStuds / dist)), maxAngle)
        local maxPx = math.tan(math.rad(angle)) / halfTan * (vp.Y * 0.5)
        local targetPart, dist2D = getBestAimJoint(charModel, partName, wallCheck, center, math.min(maxPx, bestDist))
        if targetPart and dist2D < bestDist then
            bestDist = dist2D
            best = { charModel = charModel, targetPart = targetPart, uid = uid }
        end
    end
    return best
end

local lastMicroTime, cachedMicroTarget = 0, nil
local function getMicroAimTarget()
    local now = os.clock()
    if now - lastMicroTime < 0.01 then
        return cachedMicroTarget
    end
    lastMicroTime = now
    local cfg = getgenv().RCConfig
    cachedMicroTarget = findCenterTarget(
        cfg.MicroAimPart or "auto",
        cfg.MicroAimRadius or 3,
        cfg.MicroAimMaxAngle or 3,
        cfg.MicroAimMaxDist or 300,
        cfg.MicroAimWallCheck
    )
    return cachedMicroTarget
end

local function getShotTarget(cfg)
    if cfg.SilentAimEnabled then return getSilentAimTarget() end
    if cfg.MicroAimEnabled then return getMicroAimTarget() end
    return nil
end

local aimActive = false
UIS.InputBegan:Connect(function(inp, gp)
    local k = getgenv().RCConfig.AimKey
    if inp.UserInputType == k or inp.KeyCode == k then aimActive = true end
end)
UIS.InputEnded:Connect(function(inp)
    local k = getgenv().RCConfig.AimKey
    if inp.UserInputType == k or inp.KeyCode == k then aimActive = false end
end)

local refreshAccum = 0
local ammoAccum = 0
local skelScreenCoords, skelScreenOn = {}, {}
local triggerSince = nil
local lastTriggerClick = 0
local noThrowFec = nil
local espConn = RunSvc.RenderStepped:Connect(function(dt)
    local cfg = getgenv().RCConfig
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local myPos = getMyHrp()
    table.clear(visMemo)

    if tags_ready then
        refreshAccum += dt
        if refreshAccum >= 0.2 then
            refreshAccum = 0
            refreshTeamCache()
        end
    end

    if cfg.ShowAmmoBox then
        ammoAccum += dt
        if ammoAccum >= 0.5 then
            ammoAccum = 0
            pcall(refreshAmmoBoxes)
        end
    end

    if cfg.AimbotEnabled and aimActive then
        local t = getAimTarget()
        if t then
            local targetPos = t.headPart.Position

            local compensation = getDropCompensation(Camera.CFrame.Position, targetPos)
            targetPos = targetPos + compensation

            local sp = Camera:WorldToViewportPoint(targetPos)

            local ac = getFovCenter(cfg.AimFovCenter)
            local dx = sp.X - ac.X
            local dy = sp.Y - ac.Y

            local g = 1 / math.max(1, cfg.AimSmooth)
            local algo = cfg.AimAlgo
            if algo == "anticurve" or algo == "dynamic" then
 local fov = math.max(1, cfg.AimFov or 150)
                local r = math.min(1, math.sqrt(dx * dx + dy * dy) / fov)
                local k = cfg.AimCurveStrength or 2
                local shape
                if algo == "anticurve" then

 shape = 1 - r
                else

                    shape = 1 - r * r * (3 - 2 * r)
                end
                g = math.min(1, g * (1 + k * shape))
            end
            if mousemoverel then mousemoverel(dx * g, dy * g) end
        end
    end

    if cfg.TriggerEnabled then

        local inGame = UIS.MouseBehavior == Enum.MouseBehavior.LockCenter and not UIS:GetFocusedTextBox()
        local keyOk = (not cfg.TriggerNeedKey) or aimActive
        local tgt = inGame
            and keyOk
            and findCenterTarget(
                "auto",
                cfg.TriggerRadius or 1.5,
                cfg.TriggerMaxAngle or 2,
                cfg.TriggerMaxDist or 400,
                cfg.TriggerWallCheck
            )
        if tgt then
            local now = os.clock()
            triggerSince = triggerSince or now
            if now - triggerSince >= (cfg.TriggerDelay or 40) / 1000
                and now - lastTriggerClick >= (cfg.TriggerInterval or 90) / 1000 then
                lastTriggerClick = now
                pcall(mouse1click)
            end
            else
            triggerSince = nil
        end
            else
        triggerSince = nil
    end

    if cfg.AimbotEnabled and cfg.ShowAimFov then
        FovCircle.Visible  = true
        FovCircle.Radius   = cfg.AimFov
        FovCircle.Position = getFovCenter(cfg.AimFovCenter)
    else
        FovCircle.Visible = false
    end

    if cfg.SilentAimEnabled and cfg.ShowSilentFov then
        SilentAimFovCircle.Visible  = true
        SilentAimFovCircle.Radius   = cfg.SilentAimFov
        SilentAimFovCircle.Position = getFovCenter(cfg.SilentAimFovCenter)
    else
        SilentAimFovCircle.Visible = false
    end

    if cfg.CrosshairEnabled then
        local cColor = cfg.CrosshairColor or Color3.fromRGB(255, 0, 0)
        local cSize  = cfg.CrosshairSize or 5

        local crossCenter = getFovCenter(cfg.CrosshairCenter)

        if cfg.CrosshairType == "Dot" then
 CrosshairLines.Left.Visible   = false
            CrosshairLines.Right.Visible  = false
            CrosshairLines.Top.Visible    = false
            CrosshairLines.Bottom.Visible = false

            CrosshairDot.Position = crossCenter
            CrosshairDot.Radius   = cSize
            CrosshairDot.Color    = cColor
            CrosshairDot.Visible  = true
        elseif cfg.CrosshairType == "Cross" then
 CrosshairDot.Visible = false

            local gap = 2
            local thickness = cfg.Thickness or 1.5

            CrosshairLines.Left.From      = Vector2.new(crossCenter.X - gap - cSize, crossCenter.Y)
            CrosshairLines.Left.To        = Vector2.new(crossCenter.X - gap, crossCenter.Y)
            CrosshairLines.Left.Color     = cColor
            CrosshairLines.Left.Thickness = thickness
            CrosshairLines.Left.Visible   = true

            CrosshairLines.Right.From     = Vector2.new(crossCenter.X + gap, crossCenter.Y)
            CrosshairLines.Right.To       = Vector2.new(crossCenter.X + gap + cSize, crossCenter.Y)
            CrosshairLines.Right.Color    = cColor
            CrosshairLines.Right.Thickness = thickness
            CrosshairLines.Right.Visible  = true

            CrosshairLines.Top.From       = Vector2.new(crossCenter.X, crossCenter.Y - gap - cSize)
            CrosshairLines.Top.To         = Vector2.new(crossCenter.X, crossCenter.Y - gap)
            CrosshairLines.Top.Color      = cColor
            CrosshairLines.Top.Thickness = thickness
            CrosshairLines.Top.Visible    = true

            CrosshairLines.Bottom.From    = Vector2.new(crossCenter.X, crossCenter.Y + gap)
            CrosshairLines.Bottom.To      = Vector2.new(crossCenter.X, crossCenter.Y + gap + cSize)
            CrosshairLines.Bottom.Color   = cColor
            CrosshairLines.Bottom.Thickness = thickness
            CrosshairLines.Bottom.Visible = true
        else
            CrosshairDot.Visible          = false
            CrosshairLines.Left.Visible   = false
            CrosshairLines.Right.Visible  = false
            CrosshairLines.Top.Visible    = false
            CrosshairLines.Bottom.Visible = false
        end
        else
        CrosshairDot.Visible          = false
        CrosshairLines.Left.Visible   = false
        CrosshairLines.Right.Visible  = false
        CrosshairLines.Top.Visible    = false
        CrosshairLines.Bottom.Visible = false
    end

    local charFolder = getCharsFolder()
    local activeIds  = {}

    if cfg.EspEnabled and charFolder then
        for _, charModel in ipairs(charFolder:GetChildren()) do
            local uid = tonumber(charModel.Name)
            if not uid or uid == LocalId then continue end
            if charModel.Name == "StarterCharacter" then continue end

 local tdata    = team_cache[uid]
            local friendly = tdata and tdata.friendly
            local dead     = tdata and tdata.dead

            if friendly == nil then friendly = false end

            if dead then
                if cache[uid] then hideAll(cache[uid]) end
                continue
            end

            if cfg.TeamCheck and friendly then
                if cache[uid] then hideAll(cache[uid]) end
                continue
            end

            local hrp = charModel:FindFirstChild("humanoid_root_part")
 if not hrp then
                if cache[uid] then hideAll(cache[uid]) end
                continue
            end

            local dist = (hrp.Position - myPos).Magnitude
            if dist > cfg.MaxDist then
                if cache[uid] then hideAll(cache[uid]) end
                continue
            end

            local hitbox = charModel:FindFirstChild("hitbox")
 local hY = hitbox and hitbox.Size.Y or 6.5

            local topS, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, hY*0.5, 0))
            local botS           = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, hY*0.5, 0))

            local baseColor = (friendly and cfg.AllyColor) or cfg.EnemyColor

            if not onScreen or topS.Z <= 0 then
                activeIds[uid] = true
                local s = getOrCreate(uid)
                hideOnscreen(s)
                updateCham(s, charModel, baseColor, cfg)
                if cfg.ShowOffscreenArrow then
                    local arrowCenter, arrowDir = drawEdgeArrow(s.Arrow, hrp.Position, center,
                        baseColor, cfg.OffscreenArrowRadius or 190, cfg.Opacity or 1)

                    if cfg.ShowDist then
                        local tp = arrowCenter - arrowDir * (20 + espFontSize(0))
                        s.Dist.Text     = string.format("%d m", math.round(dist))
 s.Dist.Size     = espFontSize(-1)
                        s.Dist.Color    = baseColor
                        s.Dist.Transparency = cfg.Opacity or 1
                        s.Dist.Position = snapV2(tp.X, tp.Y)
                        s.Dist.Visible  = true
                    end
                    else
                    s.Arrow.Visible = false
                end
                continue
            end

            activeIds[uid] = true
            local s = getOrCreate(uid)
            s.Arrow.Visible = false

            local cparts    = getCharParts(charModel)
            local headPart  = cparts and cparts.head  or charModel:FindFirstChild("head")
 local torsoPart = cparts and cparts.torso or charModel:FindFirstChild("torso")
 local isAimingMe = false
            if cfg.AimWarningEnabled and headPart and hrp then

                local isPlayerVisible = isVisibleMemo(headPart, charModel) or isVisibleMemo(torsoPart, charModel)
                if isPlayerVisible then

                    local enemyLook = headPart.CFrame.LookVector
                    local enemyBodyLook = hrp.CFrame.LookVector
                    local dirToMe = (myPos - hrp.Position).Unit

                    local headDot = enemyLook:Dot(dirToMe)
                    local bodyDot = enemyBodyLook:Dot(dirToMe)

                    if headDot > 0.95 or bodyDot > 0.95 then
                        isAimingMe = true
                    end
                end
            end

            local color = baseColor
            if cfg.VisCheck and (isVisibleMemo(headPart, charModel) or isVisibleMemo(torsoPart, charModel)) then
                color = cfg.VisibleColor
            end

            if isAimingMe then
                color = (math.floor(tick() * 5) % 2 == 0) and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(255, 230, 30)
            end

            updateCham(s, charModel, color, cfg)

            local bH = math.abs(botS.Y - topS.Y)
            local bW = bH * 0.6
            local bX = topS.X - bW * 0.5
            local bY = topS.Y

            if cfg.ShowBox then

                if cfg.BoxFilled then
                    s.BoxFill.Color        = color
                    s.BoxFill.Position     = Vector2.new(bX, bY)
                    s.BoxFill.Size         = Vector2.new(bW, bH)

                    s.BoxFill.Transparency = cfg.BoxFillTransparency or 0.25
                    s.BoxFill.Visible      = true
                else
                    s.BoxFill.Visible = false
                end

                if cfg.BoxStyle == "Corner" then
 s.Box.Visible = false
                    drawCornerBox(s.Corners, bX, bY, bW, bH, color, cfg.Thickness, cfg.Opacity)
                else
                    for _, l in ipairs(s.Corners) do l.Visible = false end
                    s.Box.Color        = color; s.Box.Thickness = cfg.Thickness
                    s.Box.Position     = Vector2.new(bX, bY)
                    s.Box.Size         = Vector2.new(bW, bH)
                    s.Box.Transparency = cfg.Opacity
                    s.Box.Visible      = true
                end
                else
                s.Box.Visible = false
                s.BoxFill.Visible = false
                for _, l in ipairs(s.Corners) do l.Visible = false end
            end

            if cfg.ShowTracer then
                local tracerFrom
                if cfg.TracerOrigin == "Center" then
 tracerFrom = Vector2.new(center.X, center.Y)
                elseif cfg.TracerOrigin == "Top" then
 tracerFrom = Vector2.new(center.X, 0)
                else
                    tracerFrom = Vector2.new(center.X, Camera.ViewportSize.Y)
                end
                s.Tracer.Color   = color; s.Tracer.Thickness = cfg.Thickness
                s.Tracer.From    = tracerFrom
                s.Tracer.To      = Vector2.new(botS.X, botS.Y)
                s.Tracer.Visible = true
                else s.Tracer.Visible = false end

            local fSize = espFontSize(0)
            local lineH = fSize + 2

            if cfg.ShowName then
                local dname = tdata and tdata.name or tostring(uid)
                if isAimingMe then
                    dname = "[AIMS YOU] " .. dname
 end
                if cfg.ShowNVG and tdata and tdata.nvg then
                    dname = dname .. "  [NVG]"
 end
                s.Name.Text     = dname
                s.Name.Size     = fSize
                s.Name.Color    = color; s.Name.Transparency = cfg.Opacity
                s.Name.Position = snapV2(topS.X, bY - lineH - 3)
                s.Name.Visible  = true
                else s.Name.Visible = false end

            if cfg.ShowDist then
                local dtext = string.format("%d m", math.round(dist))
 if cfg.ShowMoving and tdata and tdata.vel and tdata.vel > 4 then
                    dtext = dtext .. "  »"
 end
                s.Dist.Text     = dtext
                s.Dist.Size     = espFontSize(-2)
                s.Dist.Color    = color; s.Dist.Transparency = cfg.Opacity
                s.Dist.Position = snapV2(topS.X, bY + bH + 4)
                s.Dist.Visible  = true
 else s.Dist.Visible = false end

            if cfg.ShowWeapon and tdata and tdata.weapon then
                local wtext = tdata.weapon
                if tdata.category then
                    wtext = wtext .. " (" .. tostring(tdata.category) .. ")"
 end
                s.Weapon.Text     = wtext
                s.Weapon.Size     = espFontSize(-1)
                s.Weapon.Color    = color; s.Weapon.Transparency = cfg.Opacity
                s.Weapon.Position = snapV2(topS.X, bY + bH + 4 + (cfg.ShowDist and lineH or 0))
                s.Weapon.Visible  = true
                else s.Weapon.Visible = false end

            if cfg.ShowSkeleton and headPart then
                local headS, onHead = Camera:WorldToViewportPoint(headPart.Position)
                if onHead and headS.Z > 0 then
                    local radius = math.clamp(250 / dist, 2, 18)
                    s.HeadCircle.Position     = Vector2.new(headS.X, headS.Y)
                    s.HeadCircle.Radius       = radius
                    s.HeadCircle.Color        = color
                    s.HeadCircle.Thickness    = cfg.Thickness
                    s.HeadCircle.Transparency = cfg.Opacity
                    s.HeadCircle.Visible      = true
                else
                    s.HeadCircle.Visible = false
                end
                else
                s.HeadCircle.Visible = false
            end

            if cfg.ShowLookLine and headPart then
                local headS, onHead = Camera:WorldToViewportPoint(headPart.Position)
                if onHead and headS.Z > 0 then
                    local lookDir = headPart.CFrame.LookVector
                    local endPosWorld = headPart.Position + lookDir * 8
                    local endS, onEnd = Camera:WorldToViewportPoint(endPosWorld)

                    if onEnd and endS.Z > 0 then
                        s.LookLine.From      = Vector2.new(headS.X, headS.Y)
                        s.LookLine.To        = Vector2.new(endS.X, endS.Y)
                        s.LookLine.Color     = color
                        s.LookLine.Thickness = cfg.Thickness
                        s.LookLine.Transparency = cfg.Opacity
                        s.LookLine.Visible   = true
                    else
                        s.LookLine.Visible = false
                    end
                    else
                    s.LookLine.Visible = false
                end
                    else
                s.LookLine.Visible = false
            end

            if cfg.ShowSkeleton then
                local joints = getJointPositions(charModel)
                if joints then
                    local screenCoords = skelScreenCoords
                    local screenOn = skelScreenOn
                    for name, pos in pairs(joints) do
                        local sp, on = Camera:WorldToViewportPoint(pos)
                        screenCoords[name] = Vector2.new(sp.X, sp.Y)
                        screenOn[name] = on and sp.Z > 0
                    end

                    for i, conn in ipairs(SKELETON) do
                        local name1, name2 = conn[1], conn[2]
                        local line = s.Skel[i]
                        if screenOn[name1] and screenOn[name2] then
                            line.From = screenCoords[name1]
                            line.To = screenCoords[name2]
                            line.Color = color
                            line.Thickness = cfg.Thickness
                            line.Transparency = cfg.Opacity
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    end
                        else
                    for _, l in ipairs(s.Skel) do l.Visible = false end
                end
                        else
                for _, l in ipairs(s.Skel) do l.Visible = false end
            end
        end
    end

    local silentTarget = nil
    if cfg.SilentAimEnabled then
        silentTarget = getSilentAimTarget()
    end

    if cfg.SilentAimEnabled and cfg.ShowSilentTargetLine and silentTarget then
        local targetPart = silentTarget.targetPart
        if targetPart then
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen and screenPos.Z > 0 then
                SilentAimTargetLine.From    = getFovCenter(cfg.SilentAimFovCenter)
                SilentAimTargetLine.To      = Vector2.new(screenPos.X, screenPos.Y)
                SilentAimTargetLine.Color   = Color3.fromRGB(255, 80, 80)
                SilentAimTargetLine.Thickness = 1
                SilentAimTargetLine.Visible = true
            else
                SilentAimTargetLine.Visible = false
            end
            else
            SilentAimTargetLine.Visible = false
        end
            else
        SilentAimTargetLine.Visible = false
    end

    local activeGrenadeIds = {}
    local closestThreatDist = 99999
    local closestThreatPos  = nil

    if cfg.GrenadeEspEnabled then

        local grenadesFolder = workspace:FindFirstChild("grenades")
 do
            local now = os.clock()
            local warnDist = cfg.GrenadeWarnDist or 35

            local sources = grenadesFolder and grenadesFolder:GetChildren() or {}
            local ignoreAllies = cfg.GrenadeIgnoreAllies ~= false
            for part, info in pairs(thrownGrenades) do
                if now - info.seen > THROWN_LIFETIME then
                    thrownGrenades[part] = nil
                elseif part.Parent ~= nil then
                    local p = part.Position

                    local valid = p.Magnitude < 1e5 and (p - info.spawn).Magnitude > 6
                    if valid then
                        if not info.owner then
                            info.owner = resolveGrenadeOwner(p)
                        end
                        info.lastPos = p
                        if not (ignoreAllies and info.owner == "ally") then
 table.insert(sources, part)
                        end
                    end
                end
            end
            for _, child in ipairs(sources) do

                local proj = child:IsA("BasePart") and child
                    or child:FindFirstChildWhichIsA("BasePart", true)
 if proj then
                    local gid = child:GetDebugId()
                    activeGrenadeIds[gid] = true
                    local gDraw = getOrCreateGrenade(gid)

                    local currentPos = myPos or Camera.CFrame.Position
                    local dist = (proj.Position - currentPos).Magnitude

                    local vel = proj.AssemblyLinearVelocity
                    if proj.Anchored then
                        local lp, lt = gDraw.lastPos, gDraw.lastPosT
                        local raw = Vector3.zero
                        if lp and now > lt then
                            raw = (proj.Position - lp) / (now - lt)
                        end
                        gDraw.vel = (gDraw.vel or Vector3.zero):Lerp(raw, 0.5)
                        gDraw.lastPos, gDraw.lastPosT = proj.Position, now
                        vel = gDraw.vel
                    end

                    if cfg.GrenadeLandingEnabled then
                        if now - gDraw.lastPredict > 0.12 then
                            gDraw.lastPredict = now
                            gDraw.landPos, gDraw.landValid =
                                predictGrenadeLanding(proj.Position, vel)
                        end
                        else
                        gDraw.landValid = false
                    end

                    local threatPos  = (gDraw.landValid and gDraw.landPos) or proj.Position
                    local threatDist = (threatPos - currentPos).Magnitude
                    if threatDist < closestThreatDist then
                        closestThreatDist = threatDist
                        closestThreatPos  = threatPos
                    end

                    local near = threatDist < warnDist
                    local markColor = near and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 150, 30)

                    local screenPos, onScreen = Camera:WorldToViewportPoint(proj.Position)
                    if onScreen and screenPos.Z > 0 then
                        local radius = math.clamp(300 / math.max(dist, 1), 5, 20)
                        gDraw.Circle.Position = Vector2.new(screenPos.X, screenPos.Y)
                        gDraw.Circle.Radius   = radius
                        gDraw.Circle.Color    = markColor
                        gDraw.Circle.Visible  = true
                        gDraw.Text.Text     = string.format("[GRENADE] [%d m]", math.round(dist))
 gDraw.Text.Color    = markColor
                        gDraw.Text.Position = Vector2.new(screenPos.X, screenPos.Y + radius + 4)
                        gDraw.Text.Visible  = true
                    else
                        gDraw.Circle.Visible = false
                        gDraw.Text.Visible   = false
                    end

                    if cfg.GrenadeLandingEnabled and gDraw.landValid then
                        drawGroundRing(gDraw.Ring, gDraw.landPos,
                            cfg.GrenadeBlastRadius or 25, markColor, math.max(cfg.Thickness or 1, 2))
                        local gS, gOn = Camera:WorldToViewportPoint(proj.Position)
                        local lS, lOn = Camera:WorldToViewportPoint(gDraw.landPos)
                        if gOn and lOn and gS.Z > 0 and lS.Z > 0 then
                            gDraw.Heading.From    = Vector2.new(gS.X, gS.Y)
                            gDraw.Heading.To      = Vector2.new(lS.X, lS.Y)
                            gDraw.Heading.Color   = markColor
                            gDraw.Heading.Visible = true
                        else
                            gDraw.Heading.Visible = false
                        end
                        else
                        for _, l in ipairs(gDraw.Ring) do l.Visible = false end
                        gDraw.Heading.Visible = false
                    end
                end
            end
        end
    end

    if cfg.GrenadeEspEnabled and cfg.GrenadeLandingEnabled then
        local now = os.clock()
        for i = #grenadeExplosions, 1, -1 do
            local ex = grenadeExplosions[i]
            local age = now - ex.t
            if age > EXPLOSION_SHOW_TIME then
                table.remove(grenadeExplosions, i)
            else
                local gid = "boom" .. i
 activeGrenadeIds[gid] = true
                local gDraw = getOrCreateGrenade(gid)
                local fade = 1 - age / EXPLOSION_SHOW_TIME
                local col = Color3.fromRGB(255, math.floor(60 + 140 * (1 - fade)), 30)
                drawGroundRing(gDraw.Ring, ex.pos, ex.radius, col, math.max(cfg.Thickness or 1, 2))
                local sp, on = Camera:WorldToViewportPoint(ex.pos)
                if on and sp.Z > 0 then
                    local d = myPos and (ex.pos - myPos).Magnitude or 0
                    gDraw.Text.Text = string.format("[BOOM] r=%d  %d m", math.round(ex.radius), math.round(d))
 gDraw.Text.Color = col
                    gDraw.Text.Transparency = math.clamp(fade + 0.2, 0, 1)
                    gDraw.Text.Position = Vector2.new(sp.X, sp.Y)
                    gDraw.Text.Visible = true
                else
                    gDraw.Text.Visible = false
                end
            end
        end
    end

    for gid in pairs(grenadeCache) do
        if not activeGrenadeIds[gid] then
            removeGrenadeCache(gid)
        end
    end

    if cfg.GrenadeEspEnabled and closestThreatPos and closestThreatDist < (cfg.GrenadeWarnDist or 35) then
        GrenadeWarningText.Text = string.format("!!! GRENADE - %d m !!!", math.round(closestThreatDist))
 GrenadeWarningText.Position = Vector2.new(center.X, center.Y - 120)
        GrenadeWarningText.Color = (math.floor(tick() * 6) % 2 == 0)
            and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(255, 230, 30)
        GrenadeWarningText.Visible = true

        local sp, on = Camera:WorldToViewportPoint(closestThreatPos)
        local dir
        if on and sp.Z > 0 then
            dir = Vector2.new(sp.X - center.X, sp.Y - center.Y)
        else
            local rel = Camera.CFrame:PointToObjectSpace(closestThreatPos)
            dir = Vector2.new(rel.X, -rel.Y)
        end
        if dir.Magnitude < 1 then dir = Vector2.new(0, -1) end
        dir = dir.Unit
        local tip  = center + dir * 100
        local back = center + dir * 72
        local perp = Vector2.new(-dir.Y, dir.X)
        GrenadeArrow.PointA  = tip
        GrenadeArrow.PointB  = back + perp * 13
        GrenadeArrow.PointC  = back - perp * 13
        GrenadeArrow.Color   = GrenadeWarningText.Color
        GrenadeArrow.Visible = true
        else
        GrenadeWarningText.Visible = false
        GrenadeArrow.Visible = false
    end

    for uid in pairs(cache) do
        if not activeIds[uid] then
            if not (charFolder and charFolder:FindFirstChild(tostring(uid))) then
                removeCache(uid)
            else
                hideAll(cache[uid])
            end
        end
    end

    radarRender(cfg)

    ammoRender(cfg)

    if cfg.NoThrowables then

        if flashCC and flashCC.Enabled then flashCC.Enabled = false end
        if flashDesat and flashDesat.Enabled then flashDesat.Enabled = false end
        if flashBlur and flashBlur.Enabled then flashBlur.Enabled = false end
        if expCC and expCC.Enabled then expCC.Enabled = false end
        if expBlur and expBlur.Enabled then expBlur.Enabled = false end
        if supCC and supCC.Enabled then supCC.Enabled = false end
        if supBlur and supBlur.Enabled then supBlur.Enabled = false end

        if not (noThrowFec and noThrowFec.Parent) then
            noThrowFec = LP.PlayerGui:FindFirstChild("FlashEffectContainer", true)
 end
        if noThrowFec and noThrowFec.Visible then
            noThrowFec.Visible = false
        end
    end
end)

local sharedState = nil
local sharedStateConn

local smokeConnection = nil

local function startSmokeListener()
    if smokeConnection then return end
    smokeConnection = workspace.DescendantAdded:Connect(function(v)
        local cfg = getgenv().RCConfig
        if cfg and cfg.NoThrowables and v:IsA("ParticleEmitter") then
 local name = string.lower(v.Name)
            if string.find(name, "smoke") or string.find(name, "gas") then
 v.Enabled = false
                v.Rate = 0
            end
        end
    end)
    pcall(function()
        local cfg = getgenv().RCConfig
        if cfg and cfg.NoThrowables then
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") then
 local name = string.lower(v.Name)
                    if string.find(name, "smoke") or string.find(name, "gas") then
 v.Enabled = false
                        v.Rate = 0
                    end
                end
            end
        end
    end)
end

local function stopSmokeListener()
    if smokeConnection then
        pcall(function() smokeConnection:Disconnect() end)
        smokeConnection = nil
    end
end

local function unloadESP()
    pcall(function() DrawingGui:Destroy() end)
    pcall(function() espConn:Disconnect() end)
    pcall(function() sharedStateConn:Disconnect() end)
    pcall(function() FovCircle:Remove() end)
    pcall(function() SilentAimFovCircle:Remove() end)
    pcall(function() SilentAimTargetLine:Remove() end)
    pcall(function() CrosshairDot:Remove() end)
    for _, line in pairs(CrosshairLines) do
        pcall(function() line:Remove() end)
    end

    pcall(function()
        if casterModule then
            if origFire then casterModule.fire = origFire end
            if origNetworkHit then casterModule.network_hit = origNetworkHit end
        end
    end)
    pcall(function()
        if networkEncodeModule and origWriteExactPosition then
            networkEncodeModule.write_exact_position = origWriteExactPosition
        end
    end)
    pcall(function()
        if weaponParticles and origEmitWeaponParticles then
            weaponParticles.emit_weapon_particles = origEmitWeaponParticles
        end
    end)
    pcall(function()
        if tracerConnection then
            tracerConnection:Disconnect()
        end
    end)

    pcall(function()
        if sharedState then
            if sharedState.plr_recoil then sharedState.plr_recoil:set_client(1) end
            if sharedState.plr_barrel_deviation then sharedState.plr_barrel_deviation:set_client(1) end
            if sharedState.plr_buck_barrel_deviation then sharedState.plr_buck_barrel_deviation:set_client(1) end
            if sharedState.plr_arm_stamina_drain_hold_breath then sharedState.plr_arm_stamina_drain_hold_breath:set_client(3) end
            if sharedState.plr_arm_stamina_drain then sharedState.plr_arm_stamina_drain:set_client(2) end

            if sharedState.plr_lens_flare then sharedState.plr_lens_flare:set_client(true) end
            if sharedState.plr_stamina_shake_multiplier then sharedState.plr_stamina_shake_multiplier:set_client(1) end
        end
    end)
    pcall(function()
        if origLightingSettings then
            Lighting.ClockTime = origLightingSettings.ClockTime
            Lighting.Brightness = origLightingSettings.Brightness
            Lighting.OutdoorAmbient = origLightingSettings.OutdoorAmbient
            Lighting.Ambient = origLightingSettings.Ambient
            Lighting.FogEnd = origLightingSettings.FogEnd
        end
    end)
    pcall(stopSmokeListener)
    pcall(function()
        local fec = LP.PlayerGui:FindFirstChild("FlashEffectContainer", true)
 if fec then fec.Visible = true end
    end)
    pcall(function()
        if old_newindex then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__newindex = old_newindex
            setreadonly(mt, true)
        end
    end)
    for _, c in ipairs(grenadeConns) do pcall(function() c:Disconnect() end) end
    table.clear(grenadeConns); table.clear(thrownGrenades); table.clear(grenadeExplosions)
    pcall(function() GrenadeWarningText:Remove() end)
    pcall(function() GrenadeArrow:Remove() end)
    for gid in pairs(grenadeCache) do removeGrenadeCache(gid) end
    for uid in pairs(cache) do removeCache(uid) end
    pcall(function() chamHolder:Destroy() end)

    pcall(function()
        Radar.Bg:Remove(); Radar.Border:Remove(); Radar.HLine:Remove()
        Radar.VLine:Remove(); Radar.Center:Remove()
        for _, d in ipairs(Radar.Dots) do d:Remove() end

        if HudLineWeapon then HudLineWeapon:Remove() end
        if HudLineHP     then HudLineHP:Remove()     end
        if HudLineAmmo   then HudLineAmmo:Remove()   end
    end)

    pcall(function()
        for id, d in pairs(ammoDraw) do d.Box:Remove(); d.Text:Remove(); ammoDraw[id] = nil end
    end)
end
getgenv()._MANULHOOK.Unload = unloadESP

task.spawn(function()
    local RS = game:GetService("ReplicatedStorage")
 local inst = RS:FindFirstChild("module")
        and RS.module:FindFirstChild("shared_state")

 if not inst then
        DBG.force("[ManulHook] shared_state not found")
        return
    end

    local oldId
    if getthreadidentity then oldId = getthreadidentity() end
    if setthreadidentity then pcall(setthreadidentity, 2) end

    local ok, mod = pcall(require, inst)

    if setthreadidentity and oldId then pcall(setthreadidentity, oldId) end

    if ok and type(mod) == "table" and mod.SHARED_STATE then
 sharedState = mod.SHARED_STATE
        DBG.force("[ManulHook] SHARED_STATE linked")
    else
        DBG.force("[ManulHook] shared_state load failed")
 end
end)

local sharedStateAccum = 0
sharedStateConn = RunSvc.Heartbeat:Connect(function(dt)
    if not sharedState then return end

    sharedStateAccum += dt
    if sharedStateAccum < 0.05 then return end
    sharedStateAccum = 0
    local cfg = getgenv().RCConfig
    if not cfg then return end

    local pm = sharedState.plr_penetration_multiplier
    if pm and type(pm.value) == "number" then penMult = pm.value end

 local recoilVal = cfg.NoRecoilEnabled and 0 or 1
    if sharedState.plr_recoil and sharedState.plr_recoil.value ~= recoilVal then
        pcall(function() sharedState.plr_recoil:set_client(recoilVal) end)
    end

    local spreadVal = cfg.NoSpreadEnabled and 0 or 1
    if sharedState.plr_barrel_deviation and sharedState.plr_barrel_deviation.value ~= spreadVal then
        pcall(function() sharedState.plr_barrel_deviation:set_client(spreadVal) end)
    end
    if sharedState.plr_buck_barrel_deviation and sharedState.plr_buck_barrel_deviation.value ~= spreadVal then
        pcall(function() sharedState.plr_buck_barrel_deviation:set_client(spreadVal) end)
    end

    local armDrainHoldBreathVal = cfg.InfiniteArmStamina and 0 or 3
    local armDrainVal = cfg.InfiniteArmStamina and 0 or 2

    if sharedState.plr_arm_stamina_drain_hold_breath and sharedState.plr_arm_stamina_drain_hold_breath.value ~= armDrainHoldBreathVal then
        pcall(function() sharedState.plr_arm_stamina_drain_hold_breath:set_client(armDrainHoldBreathVal) end)
    end
    if sharedState.plr_arm_stamina_drain and sharedState.plr_arm_stamina_drain.value ~= armDrainVal then
        pcall(function() sharedState.plr_arm_stamina_drain:set_client(armDrainVal) end)
    end

    local lensVal = not cfg.NoLensFlare
    if sharedState.plr_lens_flare and sharedState.plr_lens_flare.value ~= lensVal then
        pcall(function() sharedState.plr_lens_flare:set_client(lensVal) end)
    end

    local shakeVal = cfg.NoStaminaShake and 0 or 1
    if sharedState.plr_stamina_shake_multiplier and sharedState.plr_stamina_shake_multiplier.value ~= shakeVal then
        pcall(function() sharedState.plr_stamina_shake_multiplier:set_client(shakeVal) end)
    end
end)

task.spawn(function()
    if getgenv().DL_SAFE_MODE then
        DBG.force("[ManulHook] SAFE_MODE: skip NetworkEncode hook")
        return
    end
    local RS = game:GetService("ReplicatedStorage")
    local inst = RS:FindFirstChild("module")
        and RS.module:FindFirstChild("namespace")
        and RS.module.namespace:FindFirstChild("NetworkEncode")
    if not inst then
        DBG.force("[ManulHook] NetworkEncode not found")
        return
    end

    local oldId
    if getthreadidentity then
        oldId = getthreadidentity()
    end
    if setthreadidentity then
        pcall(setthreadidentity, 2)
    end

    local ok, mod = pcall(require, inst)

    if setthreadidentity and oldId then
        pcall(setthreadidentity, oldId)
    end

    if ok and type(mod) == "table" then
        local targetModule = mod.write_exact_position and mod or mod.NetworkEncode
        if targetModule and targetModule.write_exact_position then
            networkEncodeModule = targetModule
            origWriteExactPosition = targetModule.write_exact_position

            targetModule.write_exact_position = function(bitBuffer, vec3)
                local cfg = getgenv().RCConfig
                if cfg and (cfg.SilentAimEnabled or cfg.MicroAimEnabled) then
                    local mag = vec3.Magnitude
                    if mag > 10 then
                        lastShotOrigin = vec3
                        if cfg.DebugSilentAim then
                            DBG.log(string.format(
                                "[SA] packet origin=(%.1f, %.1f, %.1f)",
                                vec3.X,
                                vec3.Y,
                                vec3.Z
                            ))
                        end
                    elseif math.abs(mag - 1) < 0.05 then
                        local firing = (os.clock() - (DBG.lastFire or 0)) < 0.3
                            or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        if not firing then
                            if cfg.DebugSilentAim and (DBG.idleUnitLogs or 0) < 5 then
                                DBG.idleUnitLogs = (DBG.idleUnitLogs or 0) + 1
                                DBG.log(
                                    "[SA] skipped non-fire unit vector ("
                                        .. tostring(debug.traceback()):gsub("\n", " | ")
                                        .. ")"
                                )
                            end
                            bitBuffer:write_f32(vec3.X)
                            bitBuffer:write_f32(vec3.Y)
                            bitBuffer:write_f32(vec3.Z)
                            return
                        end

                        local target = getShotTarget(cfg)
                        if target and target.targetPart then
                            local targetPos = target.targetPart.Position
                            local compensation = getDropCompensation(lastShotOrigin, targetPos)
                            targetPos = targetPos + compensation
                            local newDir = (targetPos - lastShotOrigin).Unit
                            if cfg.DebugSilentAim then
                                local ang = math.deg(math.acos(math.clamp(vec3:Dot(newDir), -1, 1)))
                                DBG.log(string.format(
                                    "[SA] dir rewrite target=%s part=%s angle=%.2f dropY=%.2f dist=%.0f",
                                    tostring(target.uid),
                                    tostring(target.targetPart.Name),
                                    ang,
                                    compensation.Y,
                                    (targetPos - lastShotOrigin).Magnitude
                                ))
                            end
                            vec3 = newDir
                        elseif cfg.DebugSilentAim then
                            DBG.log("[SA] no target in FOV/range/wall filter")
                        end
                    elseif cfg.DebugSilentAim then
                        DBG.log(string.format(
                            "[SA] write_exact_position skip mag=%.3f",
                            mag
                        ))
                    end
                end
                bitBuffer:write_f32(vec3.X)
                bitBuffer:write_f32(vec3.Y)
                bitBuffer:write_f32(vec3.Z)
            end
            DBG.force("[ManulHook] hooked NetworkEncode.write_exact_position")
        else
            DBG.force("[ManulHook] write_exact_position not found")
        end
    else
        DBG.force("[ManulHook] NetworkEncode load failed")
    end
end)

task.spawn(function()
    if getgenv().DL_SAFE_MODE then
        DBG.force("[ManulHook] SAFE_MODE: skip caster hook")
        return
    end
    local RS = game:GetService("ReplicatedStorage")
 local inst = RS:FindFirstChild("module")
        and RS.module:FindFirstChild("caster")
        and RS.module.caster:FindFirstChild("caster")
 if not inst then
        DBG.force("[ManulHook] caster not found")
        return
    end

    local oldId
    if getthreadidentity then oldId = getthreadidentity() end
    if setthreadidentity then pcall(setthreadidentity, 2) end

    local ok, mod = pcall(require, inst)

    if setthreadidentity and oldId then pcall(setthreadidentity, oldId) end

    if ok and type(mod) == "table" and mod.fire then
 casterModule = mod
        origFire = mod.fire
        mod.fire = function(p75, p76, p77, p78, ...)
            local cfg = getgenv().RCConfig

            local isMine = p75 == LP
                or p75 == LocalId
                or (typeof(p75) == "Instance"
                    and ((compareinstances and compareinstances(p75, LP))
                        or (p75:IsA("Player") and p75.UserId == LocalId)))
            if isMine then
                DBG.lastFire = os.clock()
                lastShotOrigin = p76
            end
            if cfg and cfg.DebugSilentAim then
                DBG.log(string.format(
                    "[SA] caster.fire shooter=%s(%s) isMine=%s",
                    tostring(p75),
                    typeof(p75),
                    tostring(isMine)
                ))
            end
            if isMine and p78 and p78.properties then
                currentWeaponProperties = p78.properties
            end

            if isMine and cfg and (cfg.SilentAimEnabled or cfg.MicroAimEnabled) then
                local silentTarget = getShotTarget(cfg)
                if silentTarget and silentTarget.targetPart then
                    local targetPos = silentTarget.targetPart.Position

                    local compensation = getDropCompensation(p76, targetPos)
                    targetPos = targetPos + compensation

                    p77 = (targetPos - p76).Unit
                end
            end
            return origFire(p75, p76, p77, p78, ...)
        end

        if mod.network_hit then
            origNetworkHit = mod.network_hit
            mod.network_hit = function(arg1, arg2, arg3)
                local cfg = getgenv().RCConfig
                if cfg and (cfg.SilentAimEnabled or cfg.MicroAimEnabled) and type(arg3) == "table" then
 local silentTarget = getShotTarget(cfg)

                    if silentTarget and tonumber(arg2) == silentTarget.uid then

                        local hitPart = silentTarget.targetPart.Name

                        local newArg3 = {}
                        for k, v in pairs(arg3) do
                            if type(v) == "number" then
 local prev = newArg3[hitPart]
                                newArg3[hitPart] = (prev == nil or v < prev) and v or prev
                            else
                                newArg3[k] = hitPart
                            end
                        end
                        if cfg.DebugSilentAim then
                            local before, after = {}, {}
                            for k, v in pairs(arg3) do before[#before + 1] = tostring(k) .. "=" .. tostring(v) end
 for k, v in pairs(newArg3) do after[#after + 1] = tostring(k) .. "=" .. tostring(v) end
 DBG.log("[SA] network_hit arg3 {" .. table.concat(before, ",") .. "} → {" .. table.concat(after, ",") .. "}")
 end
                        arg3 = newArg3
                        elseif cfg.DebugSilentAim then
                        DBG.log("[SA] network_hit victim not silent target")
 end
                end
                if cfg and cfg.DebugSilentAim then
                    DBG.log(string.format("[SA] network_hit(%s, %s, %s)", typeof(arg1) .. ":" .. tostring(arg1), typeof(arg2) .. ":" .. tostring(arg2), typeof(arg3)))
 end
                return origNetworkHit(arg1, arg2, arg3)
            end
        end
        DBG.force("[ManulHook] hooked caster.fire / network_hit")
                else
        DBG.force("[ManulHook] caster load failed")
 end
end)

task.spawn(function()
    if getgenv().DL_SAFE_MODE then
        DBG.force("[ManulHook] SAFE_MODE: skip emit_weapon_particles")
        return
    end
 local RS = game:GetService("ReplicatedStorage")
 local inst = RS:FindFirstChild("framework")
        and RS.framework:FindFirstChild("shared")
            and RS.framework.shared:FindFirstChild("effect")
                and RS.framework.shared.effect:FindFirstChild("emit_weapon_particles")
 if not inst then
        DBG.force("[ManulHook] emit_weapon_particles not found")
        return
    end

    local oldId
    if getthreadidentity then oldId = getthreadidentity() end
    if setthreadidentity then pcall(setthreadidentity, 2) end

    local ok, mod = pcall(require, inst)

    if setthreadidentity and oldId then pcall(setthreadidentity, oldId) end

    if ok and type(mod) == "table" and mod.emit_weapon_particles then
 weaponParticles = mod
        origEmitWeaponParticles = mod.emit_weapon_particles
        mod.emit_weapon_particles = function(p2, p3)
            local cfg = getgenv().RCConfig
            if cfg and cfg.DisableMuzzleFlash then
                return
            end
            return origEmitWeaponParticles(p2, p3)
        end
        DBG.force("[ManulHook] hooked emit_weapon_particles")
            else
        DBG.force("[ManulHook] emit_weapon_particles load failed")
 end
end)

task.spawn(function()
    local projectiles = workspace:WaitForChild("ignore", 5)
        and workspace.ignore:WaitForChild("projectiles", 5)
 if projectiles then
        tracerConnection = projectiles.ChildAdded:Connect(function(child)
            local cfg = getgenv().RCConfig
            if cfg and cfg.DisableTracers and child:IsA("BasePart") then
 child.Transparency = 1
                task.spawn(function()
                    task.wait()
                    pcall(function() child.Transparency = 1 end)
                end)
            end
        end)
        DBG.force("[ManulHook] projectiles listener on")
            else
        DBG.force("[ManulHook] projectiles folder not found")
 end
end)

local Window = nil
local rebuilding = false

local AIM_PART_ITEMS = {
    { "auto", "Auto (Smart)", "Auto (Smart)" },
 { "head", "Head", "Head" },
 { "neck", "Neck", "Neck" },
 { "torso", "Torso", "Torso" },
 { "l_shoulder", "Left Shoulder", "Left Shoulder" },
 { "r_shoulder", "Right Shoulder", "Right Shoulder" },
 { "l_elbow", "Left Elbow", "Left Elbow" },
 { "r_elbow", "Right Elbow", "Right Elbow" },
 { "l_knee", "Left Knee", "Left Knee" },
 { "r_knee", "Right Knee", "Right Knee" },
}

local FOV_CENTER_ITEMS = {
 { "screen", "Fixed (screen center)", "Fixed (screen center)" },
 { "muzzle", "Follow muzzle", "Follow muzzle" },
}

local ESP_ITEMS = {
 { "ShowBox", "Box", "Box" },
 { "ShowChams", "Chams", "Chams" },
 { "ShowTracer", "Tracer", "Tracer" },
 { "ShowSkeleton", "Skeleton", "Skeleton" },
 { "ShowName", "Name", "Name" },
 { "ShowDist", "Distance", "Distance" },
 { "ShowWeapon", "Weapon", "Weapon" },
 { "ShowLookLine", "Look Line", "Look Line" },
 { "ShowNVG", "NVG Tag", "NVG Tag" },
 { "ShowMoving", "Moving", "Moving" },
}

rebuildGUI = function()
 if rebuilding then return end
    rebuilding = true

    if Window then
        pcall(function() Window:Destroy() end)
        Window = nil
    end

    if not ManulUI then
        rebuilding = false
        return
    end

    local cfg = getgenv().RCConfig
    pcall(function()
        ManulUI:SetLanguage("en")
 end)

    local okWin, win = pcall(function()
        return ManulUI:CreateWindow({
            Title     = "ManulHook",
 Subtitle  = "ESP · Aimbot · Silent Aim",
 Footer    = "ManulHook · v3.1",
 Intro     = false,
            Size      = Vector2.new(660, 460),
            ToggleKey = Enum.KeyCode.RightShift,
        })
    end)
    if not okWin then
        DBG.force("[ManulHook] CreateWindow failed: " .. tostring(win))
 rebuilding = false
        return
    end
    Window = win

    local function toggle(sec, zh, en, key, onChange, descZh, descEn)
        return sec:AddToggle({
            Title = en or zh,
            Description = (descEn or descZh) and (descEn or descZh) or nil,
            Default = cfg[key] and true or false,
            Callback = function(v)
                cfg[key] = v
                if onChange then onChange(v) end
            end,
        })
    end

    local function slider(sec, zh, en, key, min, max, unit, decimals, step)
        return sec:AddSlider({
            Title = en or zh,
            Min = min, Max = max, Default = cfg[key] or min,
            Decimals = decimals or 0,
            Increment = step,
            Unit = unit,
            Callback = function(v) cfg[key] = v end,
        })
    end

    local function choice(sec, zh, en, key, items, onChange)
        local labels, byLabel, current = {}, {}, nil
        for _, it in ipairs(items) do
            local label = it[3] or it[2]
            labels[#labels + 1] = label
            byLabel[label] = it[1]
            if it[1] == cfg[key] then current = label end
        end
        return sec:AddDropdown({
            Title = en or zh,
            Options = labels,
            Default = current or labels[1],
            Callback = function(label)
                local k = byLabel[label]
                if k == nil then return end
                cfg[key] = k
                if onChange then onChange(k) end
            end,
        })
    end

    local function color(sec, zh, en, key)
        return sec:AddColorPicker({
            Title = en or zh,
            Default = cfg[key],
            Callback = function(c) cfg[key] = c end,
        })
    end

    local TabV = Window:AddTab({ Title = "Visual", Subtitle = "ESP & tactical", Icon = "eye" })

 local SecEsp = TabV:AddSection({ Title = "ESP", Caption = "Overview" })
 toggle(SecEsp, " ESP", "Enable ESP", "EspEnabled")

 local espSelected, espDefault = {}, {}
    local espLabels = {}
    for _, it in ipairs(ESP_ITEMS) do
        local label = it[3] or it[2]
        espLabels[#espLabels + 1] = label
        if cfg[it[1]] then espDefault[#espDefault + 1] = label end
    end
    SecEsp:AddChips({
        Title = "Draw",
 Options = espLabels,
        Default = espDefault,
        Multi = true,
        Callback = function(list)
            table.clear(espSelected)
            for _, label in ipairs(list) do espSelected[label] = true end
            for _, it in ipairs(ESP_ITEMS) do
                cfg[it[1]] = espSelected[it[3] or it[2]] == true
            end
        end,
    })

    local SecStyle = TabV:AddSection({ Title = "Style", Caption = "Appearance" })
 choice(SecStyle, "", "Box Style", "BoxStyle", {
 { "Corner", "Corner", "Corner" },
 { "Full", "Full", "Full" },
 })
    toggle(SecStyle, "", "Box Fill", "BoxFilled")
 choice(SecStyle, "", "Tracer Origin", "TracerOrigin", {
 { "Top", "Top Center", "Top Center" },
 { "Center", "Screen Center", "Screen Center" },
 { "Bottom", "Bottom Center", "Bottom Center" },
 })

    local SecFilter = TabV:AddSection({ Title = "Filters", Caption = "Filters & indicators" })
 toggle(SecFilter, " (VisCheck)", "Green When Visible", "VisCheck")
 toggle(SecFilter, "", "Hide Allies", "TeamCheck")
 toggle(SecFilter, "", "Off-screen Arrows", "ShowOffscreenArrow")
 toggle(SecFilter, "", "Aiming Warning", "AimWarningEnabled")

 local SecGren = TabV:AddSection({ Title = "Grenade", Caption = "Throwables" })
 toggle(SecGren, " ESP ", "Grenade ESP & Warning", "GrenadeEspEnabled", function(v)
 if not v then
            pcall(function() GrenadeWarningText.Visible = false end)
            pcall(function() GrenadeArrow.Visible = false end)
            for gid in pairs(grenadeCache) do
                removeGrenadeCache(gid)
            end
        end
    end)
    toggle(SecGren, "", "Ignore Ally Grenades", "GrenadeIgnoreAllies", nil, nil, "Thrower = nearest character at throw time; ally grenades are harmless and not shown, warned or ringed; your own grenades are still shown")
 toggle(SecGren, "", "Landing & Blast Ring", "GrenadeLandingEnabled")
 slider(SecGren, "", "Blast Radius", "GrenadeBlastRadius", 5, 80, "studs")
 slider(SecGren, "", "Warn Distance", "GrenadeWarnDist", 5, 100, "studs")

 local SecRadar = TabV:AddSection({ Title = "Radar", Caption = "2D Radar" })
 toggle(SecRadar, " ()", "Enable Radar", "RadarEnabled", function(v)
 if not v then pcall(radarHideAll) end
    end)
    toggle(SecRadar, " HUD (/)", "Radar HUD (HP / Ammo)", "ShowRadarHud", function(v)
 if not v then hideAllHudLines() end
    end)
    slider(SecRadar, "", "Radar Size", "RadarSize", 100, 320, "px")
 slider(SecRadar, "", "Radar Range", "RadarRange", 50, 500, "studs")
 slider(SecRadar, "", "Dot Size", "RadarDotSize", 2, 8, "px")

 local SecWorld = TabV:AddSection({ Title = "World", Caption = "World objects" })
 toggle(SecWorld, " ESP", "Ammo / Supply Box ESP", "ShowAmmoBox", function(v)
 if v then pcall(refreshAmmoBoxes) end
    end)
    color(SecWorld, "", "Box Color", "AmmoBoxColor")

 local TabA = Window:AddTab({ Title = "Aimbot", Subtitle = "Camera aim", Icon = "crosshair" })

 local SecAim = TabA:AddSection({ Title = "Aimbot", Caption = "Camera aim" })
 toggle(SecAim, "", "Enable Aimbot", "AimbotEnabled", function(v)
 if not v then aimActive = false end
    end)
    SecAim:AddKeybind({
        Title = "Aim Key",
 Default = cfg.AimKey,
        Mode = "Press",
 Callback = function() end,
        ChangedCallback = function(k)
            cfg.AimKey = k or Enum.KeyCode.Unknown
            aimActive = false
        end,
    })
    choice(SecAim, "", "Target Part", "AimPart", AIM_PART_ITEMS)
 slider(SecAim, " (1 = )", "Smoothing (1 = lock)", "AimSmooth", 1, 20)
 choice(SecAim, "", "Aim Algorithm", "AimAlgo", {
 { "linear", "Linear (fixed smoothing)", "Linear (fixed smoothing)" },
 { "anticurve", "Anti-Curve", "Anti-Curve" },
 { "dynamic", "Dynamic (Inverse S-Curve)", "Dynamic (Inverse S-Curve)" },
 })
    slider(SecAim, "", "Curve Strength", "AimCurveStrength", 0.5, 6, "x", 1, 0.5)

 local SecAimRule = TabA:AddSection({ Title = "Range & Rules", Caption = "FOV & rules" })
 toggle(SecAimRule, "", "Show FOV Circle", "ShowAimFov")
 slider(SecAimRule, "", "FOV Radius", "AimFov", 30, 500, "px")
 slider(SecAimRule, "", "Max Distance", "AimMaxDist", 50, 1000, "m")
 choice(SecAimRule, "", "FOV Center", "AimFovCenter", FOV_CENTER_ITEMS)
 toggle(SecAimRule, "", "Wall Check", "AimWallCheck")
 toggle(SecAimRule, "", "Wallbang Check", "AimWallbang", nil, nil, "Targets behind walls still count if the bullet is estimated to penetrate (needs Wall Check on)")
 slider(SecAimRule, "", "Penetration Scale", "WallbangScale", 0.2, 3, "x", 1, 0.1)
        toggle(
            SecAimRule,
            "",
            "Bullet Drop Compensation",
            "DropCompEnabled",
            nil,
            nil,
            "Shared with Silent Aim"
        )

 local SecMicro = TabA:AddSection({ Title = "Micro Aim", Caption = "Small-range silent aim" })
 toggle(SecMicro, "", "Enable Micro Aim", "MicroAimEnabled", nil, nil, "Only corrects shots for enemies near the crosshair; tolerance scales with distance")
 choice(SecMicro, "", "Target Part", "MicroAimPart", AIM_PART_ITEMS)
 slider(SecMicro, "", "Tolerance Radius", "MicroAimRadius", 0.5, 10, "studs", 1, 0.5)
 slider(SecMicro, "", "Max Correction Angle", "MicroAimMaxAngle", 0.5, 6, "°", 1, 0.5)
 slider(SecMicro, "", "Max Distance", "MicroAimMaxDist", 30, 800, "m")
 toggle(SecMicro, "", "Wall Check", "MicroAimWallCheck")

 local SecTrigger = TabA:AddSection({ Title = "Triggerbot", Caption = "Auto fire" })
 toggle(SecTrigger, "", "Enable Triggerbot", "TriggerEnabled", nil, nil, "Auto-clicks when the crosshair is on a visible enemy (only while the mouse is locked in-game)")
 toggle(SecTrigger, "", "Only While Aim Key Held", "TriggerNeedKey")
 slider(SecTrigger, "", "Crosshair Tolerance", "TriggerRadius", 0.5, 5, "studs", 1, 0.5)
 slider(SecTrigger, "", "Max Angle", "TriggerMaxAngle", 0.5, 5, "°", 1, 0.5)
 slider(SecTrigger, "", "Max Distance", "TriggerMaxDist", 30, 800, "m")
 slider(SecTrigger, "", "Reaction Delay", "TriggerDelay", 0, 300, "ms")
 slider(SecTrigger, "", "Click Interval", "TriggerInterval", 30, 500, "ms")
 toggle(SecTrigger, "", "Wall Check", "TriggerWallCheck")

 local TabS = Window:AddTab({ Title = "Silent Aim", Subtitle = "Bullet & hit rewrite", Icon = "target" })

 local SecSilent = TabS:AddSection({ Title = "Silent Aim", Caption = "Hook based" })
 toggle(SecSilent, "", "Enable Silent Aim", "SilentAimEnabled")
 choice(SecSilent, "", "Target Part", "SilentAimPart", AIM_PART_ITEMS)

 local SecSilentRule = TabS:AddSection({ Title = "Range & Rules", Caption = "FOV & rules" })
 toggle(SecSilentRule, "", "Show FOV Circle", "ShowSilentFov")
 slider(SecSilentRule, "", "FOV Radius", "SilentAimFov", 30, 800, "px")
 choice(SecSilentRule, "", "FOV Center", "SilentAimFovCenter", FOV_CENTER_ITEMS)
 toggle(SecSilentRule, "", "Wall Check", "SilentAimWallCheck")
 toggle(SecSilentRule, "", "Wallbang Check", "SilentAimWallbang", nil, nil, "Targets behind walls still count if the bullet is estimated to penetrate (needs Wall Check on)")
 toggle(SecSilentRule, "", "Show Target Line", "ShowSilentTargetLine")
 slider(SecSilentRule, "", "Max Distance", "SilentAimMaxDist", 50, 1000, "m")

 local SecSilentDebug = TabS:AddSection({ Title = "Debug", Caption = "Debug" })

 DBG.console = nil
    local okC, con = pcall(function()
        return SecSilentDebug:AddConsole({
            Title = "Silent Aim Console", Height = 160, ReadOnly = true,
 AutoScroll = true, MaxLines = 300, Placeholder = "-",
 Value = table.concat(DBG.lines, "\n"),
 })
    end)
    if okC then
        DBG.console = con
        pcall(function() con:SetVisible(cfg.DebugSilentAim and true or false) end)
    end
    toggle(SecSilentDebug, "", "Debug Output (console)", "DebugSilentAim",
        function(v)
            if DBG.console then
                pcall(function()
                    DBG.console:SetVisible(v and true or false)
                end)
            end
        end,
        nil,
        "Writes per-shot packet / hit rewrite info to the console below (never to Roblox output)")

 local TabM = Window:AddTab({ Title = "Misc", Subtitle = "Weapon, world & performance", Icon = "sliders-horizontal" })

 local SecCross = TabM:AddSection({ Title = "Crosshair", Caption = "Custom crosshair" })
 toggle(SecCross, "", "Enable Crosshair", "CrosshairEnabled")
 choice(SecCross, "", "Style", "CrosshairType", {
 { "Dot", "Dot", "Dot" },
 { "Cross", "Cross", "Cross" },
 })
    choice(SecCross, "", "Position", "CrosshairCenter", FOV_CENTER_ITEMS)
 slider(SecCross, "", "Size", "CrosshairSize", 2, 30, "px")
 color(SecCross, "", "Color", "CrosshairColor")

 local SecWeapon = TabM:AddSection({ Title = "Weapon", Caption = "Weapon & player" })
 toggle(SecWeapon, "", "No Recoil", "NoRecoilEnabled")
 toggle(SecWeapon, "", "No Spread", "NoSpreadEnabled")
 toggle(SecWeapon, "", "Infinite Scope Stamina", "InfiniteArmStamina")

 local SecWorldMod = TabM:AddSection({ Title = "Environment", Caption = "Environment & view" })
 toggle(SecWorldMod, "", "Force Daylight", "ForceDaylight", function(v)
 pcall(function()
            if v then
                Lighting.ClockTime = 14
                Lighting.Brightness = 2
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                Lighting.Ambient = Color3.fromRGB(128, 128, 128)
                Lighting.ExposureCompensation = 0.25
                Lighting.EnvironmentDiffuseScale = 1
                Lighting.FogEnd = 999999
            elseif origLightingSettings then
                Lighting.ClockTime = origLightingSettings.ClockTime
                Lighting.Brightness = origLightingSettings.Brightness
                Lighting.OutdoorAmbient = origLightingSettings.OutdoorAmbient
                Lighting.Ambient = origLightingSettings.Ambient
                Lighting.ExposureCompensation = origLightingSettings.ExposureCompensation
                Lighting.EnvironmentDiffuseScale = origLightingSettings.EnvironmentDiffuseScale
                Lighting.FogEnd = origLightingSettings.FogEnd
            end
        end)
    end)
    toggle(SecWorldMod, "", "Remove Grenade Effects", "NoThrowables", function(v)
 if v then
            pcall(startSmokeListener)
 else
            pcall(stopSmokeListener)
            pcall(function()
                local fec = LP.PlayerGui:FindFirstChild("FlashEffectContainer", true)
 if fec then fec.Visible = true end
            end)
        end
    end)
    toggle(SecWorldMod, "", "No Lens Flare", "NoLensFlare")
 toggle(SecWorldMod, "", "No Stamina Shake", "NoStaminaShake")

 local SecPerf = TabM:AddSection({ Title = "Performance", Caption = "Performance" })
 toggle(SecPerf, "", "Disable Muzzle Flash", "DisableMuzzleFlash")
 toggle(SecPerf, "", "Hide Bullet Tracers", "DisableTracers")

 local TabSt = Window:AddTab({ Title = "Settings", Subtitle = "Render, colors & config", Icon = "settings" })

 local SecRender = TabSt:AddSection({ Title = "Render", Caption = "Drawing" })
 choice(SecRender, " ()", "Engine (save & re-run)", "EspEngine", {
 { "ScreenGui", "ScreenGui (Emulated)", "ScreenGui (Emulated)" },
 { "Drawing", "Drawing (Native)", "Drawing (Native)" },
 })
    slider(SecRender, "", "Max Distance", "MaxDist", 100, 5000, "m")
 SecRender:AddSlider({
        Title = "Line Thickness",
 Min = 1, Max = 5, Default = cfg.Thickness,
        Unit = "px",
 Callback = function(v)
            cfg.Thickness = v
            for _, s in pairs(cache) do
                s.Box.Thickness = v; s.Tracer.Thickness = v; s.LookLine.Thickness = v
                for _, l in ipairs(s.Skel) do l.Thickness = v end
                for _, l in ipairs(s.Corners) do l.Thickness = v end
            end
        end,
    })
    slider(SecRender, "", "Opacity", "Opacity", 0.1, 1, nil, 1, 0.1)
 slider(SecRender, "", "Chams Transparency", "ChamsFillTransparency", 0, 1, nil, 2, 0.05)
 slider(SecRender, "", "Box Fill Strength", "BoxFillTransparency", 0, 1, nil, 2, 0.05)
 slider(SecRender, "", "Text Size", "EspFontSize", 8, 28, "px")
 choice(SecRender, " ()", "Font (re-run)", "EspFont", {
 { "UI", "UI", "UI" },
 { "System", "System", "System" },
 { "Plex", "Plex", "Plex" },
 { "Monospace", "Monospace", "Monospace" },
 })

    local SecColor = TabSt:AddSection({ Title = "Colors", Caption = "Colors" })
 color(SecColor, "", "Enemy", "EnemyColor")
 color(SecColor, "", "Ally", "AllyColor")
 color(SecColor, "", "Visible", "VisibleColor")

 local SecCfg = TabSt:AddSection({ Title = "Config", Caption = "Save & load" })
 toggle(SecCfg, "", "Auto Load On Start", "AutoLoadConfig")
 SecCfg:AddButton({
        Title = "Save Config",
 Style = "Primary",
 Callback = function()
            saveConfig()
            Window:Notify({ Title = "ManulHook", Content = "Config saved", Duration = 2 })
 end,
    })
    SecCfg:AddButton({
        Title = "Load Config",
 Callback = function()
            loadConfig(false)
        end,
    })
    SecCfg:AddButton({
        Title = "Unload Script",
 Callback = function()
            unloadESP()
            getgenv()._MANULHOOK = nil
            pcall(function() Window:Destroy() end)
            DBG.force("[ManulHook] unloaded")
 end,
    })

    pcall(function()
        EnvPack.lib.Section(EnvPack.en, TabSt)
    end)

    Window:AddThemeTab({ Configs = false })

    rebuilding = false
end

rebuildGUI()

DBG.force("[ManulHook] v3.1 loaded (RightShift toggles UI)")
