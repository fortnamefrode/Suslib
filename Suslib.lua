
--[[
    SUSLIB V3.0
    Advanced Standalone Luau UI Framework

    Features:
      - Rounded animated interface
      - Theme manager
      - Configuration export/import
      - Menu builder API
      - ESP visual preview
      - Notifications
      - Buttons, toggles, sliders, dropdowns
      - Textboxes, keybinds, color pickers
      - Window dragging and minimization

    UI-only framework.
]]

local Suslib = {}
Suslib.__index = Suslib

Suslib.Name = "Suslib"
Suslib.Version = "3.0.0"

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
assert(Player, "Suslib must run on the client")

--==================================================
-- DEFAULT THEMES
--==================================================

local Themes = {
    Purple = {
        Background = Color3.fromRGB(13, 14, 21),
        Sidebar = Color3.fromRGB(18, 19, 29),
        Surface = Color3.fromRGB(26, 27, 39),
        Element = Color3.fromRGB(31, 33, 47),
        Hover = Color3.fromRGB(42, 43, 59),
        Border = Color3.fromRGB(53, 54, 73),
        Accent = Color3.fromRGB(155, 105, 255),
        Text = Color3.fromRGB(245, 245, 252),
        Muted = Color3.fromRGB(145, 148, 166),
        Success = Color3.fromRGB(91, 220, 150),
        Danger = Color3.fromRGB(255, 100, 115)
    },

    Midnight = {
        Background = Color3.fromRGB(9, 11, 17),
        Sidebar = Color3.fromRGB(14, 17, 25),
        Surface = Color3.fromRGB(22, 26, 37),
        Element = Color3.fromRGB(28, 33, 46),
        Hover = Color3.fromRGB(39, 45, 60),
        Border = Color3.fromRGB(47, 55, 73),
        Accent = Color3.fromRGB(100, 130, 255),
        Text = Color3.fromRGB(240, 243, 255),
        Muted = Color3.fromRGB(140, 150, 174),
        Success = Color3.fromRGB(91, 220, 150),
        Danger = Color3.fromRGB(255, 100, 115)
    },

    Ocean = {
        Background = Color3.fromRGB(10, 18, 24),
        Sidebar = Color3.fromRGB(14, 27, 35),
        Surface = Color3.fromRGB(21, 39, 48),
        Element = Color3.fromRGB(27, 49, 60),
        Hover = Color3.fromRGB(36, 66, 77),
        Border = Color3.fromRGB(43, 75, 87),
        Accent = Color3.fromRGB(45, 190, 220),
        Text = Color3.fromRGB(235, 249, 252),
        Muted = Color3.fromRGB(135, 171, 180),
        Success = Color3.fromRGB(91, 220, 150),
        Danger = Color3.fromRGB(255, 100, 115)
    },

    Crimson = {
        Background = Color3.fromRGB(19, 12, 15),
        Sidebar = Color3.fromRGB(27, 16, 21),
        Surface = Color3.fromRGB(40, 24, 30),
        Element = Color3.fromRGB(49, 29, 36),
        Hover = Color3.fromRGB(64, 37, 45),
        Border = Color3.fromRGB(77, 43, 52),
        Accent = Color3.fromRGB(245, 82, 110),
        Text = Color3.fromRGB(255, 242, 245),
        Muted = Color3.fromRGB(177, 139, 149),
        Success = Color3.fromRGB(91, 220, 150),
        Danger = Color3.fromRGB(255, 100, 115)
    },

    Emerald = {
        Background = Color3.fromRGB(11, 18, 15),
        Sidebar = Color3.fromRGB(15, 25, 20),
        Surface = Color3.fromRGB(23, 38, 29),
        Element = Color3.fromRGB(29, 48, 36),
        Hover = Color3.fromRGB(39, 64, 48),
        Border = Color3.fromRGB(45, 75, 55),
        Accent = Color3.fromRGB(72, 210, 130),
        Text = Color3.fromRGB(240, 250, 243),
        Muted = Color3.fromRGB(139, 171, 148),
        Success = Color3.fromRGB(91, 220, 150),
        Danger = Color3.fromRGB(255, 100, 115)
    }
}

--==================================================
-- UTILITIES
--==================================================

local function copyTable(source)
    local result = {}

    for key, value in pairs(source) do
        if type(value) == "table" then
            result[key] = copyTable(value)
        else
            result[key] = value
        end
    end

    return result
end

local function create(class, properties, parent)
    local object = Instance.new(class)

    for key, value in pairs(properties or {}) do
        object[key] = value
    end

    object.Parent = parent
    return object
end

local function round(object, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 12)
    }, object)
end

local function outline(object, color, transparency)
    return create("UIStroke", {
        Color = color,
        Thickness = 1,
        Transparency = transparency or 0.3
    }, object)
end

local function tween(object, properties, duration)
    if not object or not object.Parent then
        return
    end

    local animation = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.2,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        properties
    )

    animation:Play()
    return animation
end

local function label(parent, value, size, color, bold)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(value or ""),
        TextSize = size or 13,
        TextColor3 = color,
        Font = bold and Enum.Font.GothamBold
            or Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, parent)
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return
    end

    local success, result = pcall(callback, ...)

    if not success then
        warn("[Suslib] Callback error:", result)
    end
end

local function makeList(parent, gap)
    return create("UIListLayout", {
        Padding = UDim.new(0, gap or 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, parent)
end

--==================================================
-- WINDOW CREATION
--==================================================

function Suslib:CreateWindow(options)
    options = options or {}

    local theme = copyTable(Themes[options.Theme or "Purple"] or Themes.Purple)

    if options.Accent then
        theme.Accent = options.Accent
    end

    local settings = {
        Animations = true,
        Scale = 1,
        ToggleKey = Enum.KeyCode.RightShift
    }

    local connections = {}
    local tabs = {}
    local pages = {}
    local controls = {}
    local destroyed = false
    local selectedTab = nil

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    -- GUI

    local gui = create("ScreenGui", {
        Name = "Suslib_V3",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, Player:WaitForChild("PlayerGui"))

    local main = create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(780, 540),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, gui)

    round(main, 18)
    local mainStroke = outline(main, theme.Accent, 0.25)

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 72),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0
    }, main)

    local title = label(
        topbar,
        options.Title or "SUSLIB",
        20,
        theme.Text,
        true
    )
    title.Position = UDim2.fromOffset(22, 10)
    title.Size = UDim2.new(1, -150, 0, 28)

    local subtitle = label(
        topbar,
        options.Subtitle or "Advanced interface framework",
        11,
        theme.Muted
    )
    subtitle.Position = UDim2.fromOffset(23, 39)
    subtitle.Size = UDim2.new(1, -150, 0, 19)

    local version = label(topbar, "V3.0", 10, theme.Accent, true)
    version.TextXAlignment = Enum.TextXAlignment.Right
    version.Position = UDim2.new(1, -125, 0, 25)
    version.Size = UDim2.fromOffset(45, 20)

    local function makeTopButton(name, symbol, position)
        local button = create("TextButton", {
            Name = name,
            Position = position,
            Size = UDim2.fromOffset(34, 34),
            BackgroundColor3 = theme.Surface,
            Text = symbol,
            TextColor3 = theme.Text,
            TextSize = 19,
            Font = Enum.Font.Gotham,
            BorderSizePixel = 0,
            AutoButtonColor = false
        }, topbar)

        round(button, 10)

        connect(button.MouseEnter, function()
            tween(button, {
                BackgroundColor3 = theme.Hover
            })
        end)

        connect(button.MouseLeave, function()
            tween(button, {
                BackgroundColor3 = theme.Surface
            })
        end)

        return button
    end

    local minimizeButton = makeTopButton(
        "Minimize",
        "−",
        UDim2.new(1, -88, 0, 19)
    )

    local closeButton = makeTopButton(
        "Close",
        "×",
        UDim2.new(1, -46, 0, 19)
    )

    -- Sidebar

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(13, 84),
        Size = UDim2.new(0, 164, 1, -97),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0
    }, main)

    round(sidebar, 14)

    local sidebarPadding = create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    }, sidebar)

    local tabHolder = create("ScrollingFrame", {
        Name = "TabHolder",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new()
    }, sidebar)

    makeList(tabHolder, 7)

    -- Content

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(190, 84),
        Size = UDim2.new(1, -203, 1, -97),
        BackgroundTransparency = 1
    }, main)

    -- Window API

    local window = {
        Gui = gui,
        Main = main,
        Theme = theme,
        Settings = settings,
        Tabs = tabs,
        Controls = controls,
        Destroyed = false
    }

    --==================================================
    -- NOTIFICATIONS
    --==================================================

    local notificationHolder = create("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(290, 300),
        BackgroundTransparency = 1
    }, gui)

    local notificationLayout = makeList(notificationHolder, 9)
    notificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

    function window:Notify(message, duration, notificationType)
        if destroyed then return end

        local accent = theme.Accent

        if notificationType == "Success" then
            accent = theme.Success
        elseif notificationType == "Error" then
            accent = theme.Danger
        end

        local frame = create("Frame", {
            Size = UDim2.new(1, 0, 0, 67),
            BackgroundColor3 = theme.Sidebar,
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        }, notificationHolder)

        round(frame, 13)
        local border = outline(frame, accent, 0.2)

        local bar = create("Frame", {
            Position = UDim2.fromOffset(10, 12),
            Size = UDim2.new(0, 3, 1, -24),
            BackgroundColor3 = accent,
            BorderSizePixel = 0
        }, frame)

        round(bar, 4)

        local messageLabel = label(
            frame,
            tostring(message),
            12,
            theme.Text,
            false
        )

        messageLabel.Position = UDim2.fromOffset(23, 8)
        messageLabel.Size = UDim2.new(1, -34, 1, -16)
        messageLabel.TextWrapped = true

        tween(frame, {
            BackgroundTransparency = 0
        }, 0.2)

        task.delay(duration or 3, function()
            if frame.Parent then
                tween(frame, {
                    BackgroundTransparency = 1
                }, 0.2)

                tween(border, {
                    Transparency = 1
                }, 0.2)

                task.wait(0.25)

                if frame.Parent then
                    frame:Destroy()
                end
            end
        end)
    end

    --==================================================
    -- THEME MANAGER
    --==================================================

    local function applyTheme(newTheme)
        for key, value in pairs(newTheme) do
            theme[key] = value
        end

        tween(main, {BackgroundColor3 = theme.Background})
        tween(topbar, {BackgroundColor3 = theme.Sidebar})
        tween(sidebar, {BackgroundColor3 = theme.Sidebar})
        tween(mainStroke, {Color = theme.Accent})

        tabHolder.ScrollBarImageColor3 = theme.Accent

        for _, data in pairs(tabs) do
            tween(data.Button, {
                BackgroundColor3 = data.Name == selectedTab
                    and theme.Accent or theme.Surface
            })

            tween(data.Page, {
                BackgroundColor3 = theme.Background
            })

            data.RefreshTheme()
        end

        window:Notify("Theme updated!", 2, "Success")
    end

    function window:SetTheme(themeName)
        local selected = Themes[themeName]

        if not selected then
            return false
        end

        applyTheme(copyTable(selected))
        self.CurrentTheme = themeName

        return true
    end

    function window:GetThemes()
        local result = {}

        for name in pairs(Themes) do
            table.insert(result, name)
        end

        table.sort(result)

        return result
    end

    function window:CreateCustomTheme(name, custom)
        assert(type(name) == "string", "Theme name must be a string")
        assert(type(custom) == "table", "Theme must be a table")

        local newTheme = copyTable(theme)

        for key, value in pairs(custom) do
            if newTheme[key] ~= nil then
                newTheme[key] = value
            end
        end

        Themes[name] = newTheme

        return true
    end

    function window:SetAccent(color)
        if typeof(color) ~= "Color3" then
            return
        end

        theme.Accent = color
        applyTheme(theme)
    end

    --==================================================
    -- CONFIG MANAGER
    --==================================================

    local configData = {}

    function window:RegisterConfigValue(name, getter, setter)
        assert(type(name) == "string", "Config name must be a string")

        configData[name] = {
            Get = getter,
            Set = setter
        }
    end

    function window:ExportConfig()
        local output = {
            Version = Suslib.Version,
            Theme = self.CurrentTheme or "Purple",
            Values = {}
        }

        for name, data in pairs(configData) do
            if type(data.Get) == "function" then
                local success, value = pcall(data.Get)

                if success then
                    local valueType = typeof(value)

                    if valueType == "Color3" then
                        output.Values[name] = {
                            Type = "Color3",
                            R = value.R,
                            G = value.G,
                            B = value.B
                        }
                    elseif valueType == "EnumItem" then
                        output.Values[name] = {
                            Type = "Enum",
                            Value = value.Name
                        }
                    elseif type(value) == "string"
                        or type(value) == "number"
                        or type(value) == "boolean" then
                        output.Values[name] = value
                    end
                end
            end
        end

        return HttpService:JSONEncode(output)
    end

    function window:ImportConfig(json)
        local success, data = pcall(function()
            return HttpService:JSONDecode(json)
        end)

        if not success or type(data) ~= "table" then
            return false, "Invalid configuration"
        end

        if data.Theme and Themes[data.Theme] then
            self:SetTheme(data.Theme)
        end

        for name, value in pairs(data.Values or {}) do
            local registration = configData[name]

            if registration and type(registration.Set) == "function" then
                if type(value) == "table" and value.Type == "Color3" then
                    value = Color3.new(value.R, value.G, value.B)
                end

                pcall(registration.Set, value)
            end
        end

        self:Notify("Configuration imported!", 3, "Success")
        return true
    end

    --==================================================
    -- WINDOW CONTROLS
    --==================================================

    function window:SetVisible(state)
        gui.Enabled = state == true
    end

    function window:Destroy()
        if destroyed then return end

        destroyed = true
        self.Destroyed = true

        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end

        table.clear(connections)

        gui:Destroy()
    end

    local minimized = false

    connect(minimizeButton.MouseButton1Click, function()
        minimized = not minimized

        sidebar.Visible = not minimized
        content.Visible = not minimized

        tween(main, {
            Size = minimized
                and UDim2.fromOffset(440, 72)
                or UDim2.fromOffset(780, 540)
        }, 0.25)

        minimizeButton.Text = minimized and "+" or "−"
    end)

    connect(closeButton.MouseButton1Click, function()
        window:Destroy()
    end)

    --==================================================
    -- WINDOW DRAGGING
    --==================================================

    local dragging = false
    local dragStart
    local startPosition

    connect(topbar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if not dragging then return end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            local delta = input.Position - dragStart

            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    --==================================================
    -- TAB BUILDER
    --==================================================

    function window:CreateTab(tabName)
        assert(not destroyed, "Window has been destroyed")

        local page = create("ScrollingFrame", {
            Name = tostring(tabName),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Accent,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
            Visible = false
        }, content)

        create("UIPadding", {
            PaddingTop = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 9),
            PaddingBottom = UDim.new(0, 12)
        }, page)

        makeList(page, 11)

        local button = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = theme.Surface,
            Text = "  " .. tostring(tabName),
            TextColor3 = theme.Muted,
            TextSize = 12,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            BorderSizePixel = 0
        }, tabHolder)

        round(button, 10)

        local indicator = create("Frame", {
            Position = UDim2.fromOffset(0, 9),
            Size = UDim2.new(0, 3, 1, -18),
            BackgroundColor3 = theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        }, button)

        round(indicator, 5)

        local tab = {
            Name = tabName,
            Page = page,
            Button = button,
            Active = false
        }

        local function select()
            selectedTab = tabName

            for name, other in pairs(tabs) do
                local active = name == tabName

                other.Active = active
                other.Page.Visible = active

                tween(other.Button, {
                    BackgroundColor3 = active
                        and theme.Accent or theme.Surface,
                    TextColor3 = active
                        and Color3.new(1, 1, 1) or theme.Muted
                }, 0.2)

                tween(other.Indicator, {
                    BackgroundTransparency = active and 0 or 1
                }, 0.2)
            end
        end

        connect(button.MouseButton1Click, select)

        function tab:Select()
            select()
        end

        -- Theme refresh for tab and its controls.
        tab.RefreshTheme = function()
            button.TextColor3 = tab.Active
                and Color3.new(1, 1, 1) or theme.Muted
            page.ScrollBarImageColor3 = theme.Accent
        end

        --==================================================
        -- SECTION BUILDER
        --==================================================

        function tab:CreateSection(sectionName)
            local sectionFrame = create("Frame", {
                Name = tostring(sectionName),
                Size = UDim2.new(1, 0, 0, 50),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Sidebar,
                BorderSizePixel = 0
            }, page)

            round(sectionFrame, 14)
            outline(sectionFrame, theme.Border, 0.45)

            local heading = label(
                sectionFrame,
                sectionName,
                13,
                theme.Accent,
                true
            )

            heading.Position = UDim2.fromOffset(14, 8)
            heading.Size = UDim2.new(1, -28, 0, 23)

            local holder = create("Frame", {
                Name = "Controls",
                Position = UDim2.fromOffset(12, 38),
                Size = UDim2.new(1, -24, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1
            }, sectionFrame)

            makeList(holder, 8)

            create("UIPadding", {
                PaddingBottom = UDim.new(0, 12)
            }, holder)

            local section = {
                Holder = holder,
                Frame = sectionFrame,
                Name = sectionName
            }

            -- Label

            function section:CreateLabel(value)
                local item = label(
                    holder,
                    value,
                    12,
                    theme.Muted,
                    false
                )

                item.Size = UDim2.new(1, 0, 0, 27)

                return item
            end

            -- Button

            function section:CreateButton(options)
                options = type(options) == "table"
                    and options or {Name = tostring(options)}

                local button = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 39),
                    BackgroundColor3 = theme.Surface,
                    Text = options.Name or "Button",
                    TextColor3 = theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    BorderSizePixel = 0,
                    AutoButtonColor = false
                }, holder)

                round(button, 10)

                connect(button.MouseEnter, function()
                    tween(button, {
                        BackgroundColor3 = theme.Hover
                    }, 0.15)
                end)

                connect(button.MouseLeave, function()
                    tween(button, {
                        BackgroundColor3 = theme.Surface
                    }, 0.15)
                end)

                connect(button.MouseButton1Click, function()
                    tween(button, {
                        BackgroundColor3 = theme.Accent
                    }, 0.1)

                    task.delay(0.13, function()
                        if button.Parent then
                            tween(button, {
                                BackgroundColor3 = theme.Surface
                            }, 0.2)
                        end
                    end)

                    safeCallback(options.Callback)
                end)

                return button
            end

            -- Toggle

            function section:CreateToggle(options)
                options = options or {}

                local state = options.Default == true

                local button = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundColor3 = theme.Surface,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false
                }, holder)

                round(button, 10)

                local name = label(
                    button,
                    options.Name or "Toggle",
                    12,
                    theme.Text
                )

                name.Position = UDim2.fromOffset(12, 0)
                name.Size = UDim2.new(1, -70, 1, 0)

                local switch = create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -11, 0.5, 0),
                    Size = UDim2.fromOffset(36, 19),
                    BackgroundColor3 = state
                        and theme.Accent or theme.Border,
                    BorderSizePixel = 0
                }, button)

                round(switch, 20)

                local dot = create("Frame", {
                    Position = state
                        and UDim2.new(1, -17, 0, 2)
                        or UDim2.fromOffset(2, 2),
                    Size = UDim2.fromOffset(15, 15),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0
                }, switch)

                round(dot, 20)

                local function update()
                    tween(switch, {
                        BackgroundColor3 = state
                            and theme.Accent or theme.Border
                    })

                    tween(dot, {
                        Position = state
                            and UDim2.new(1, -17, 0, 2)
                            or UDim2.fromOffset(2, 2)
                    })

                    safeCallback(options.Callback, state)
                end

                connect(button.MouseButton1Click, function()
                    state = not state
                    update()
                end)

                local control = {}

                function control:Get()
                    return state
                end

                function control:Set(value)
                    state = value == true
                    update()
                end

                window:RegisterConfigValue(
                    options.Config or options.Name or "Toggle",
                    function() return state end,
                    function(value) control:Set(value) end
                )

                table.insert(controls, control)

                return control
            end

            -- Slider

            function section:CreateSlider(options)
                options = options or {}

                local minimum = options.Min or 0
                local maximum = options.Max or 100

                assert(maximum > minimum, "Slider Max must exceed Min")

                local value = math.clamp(
                    options.Default or minimum,
                    minimum,
                    maximum
                )

                local wrap = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 61),
                    BackgroundTransparency = 1
                }, holder)

                local name = label(
                    wrap,
                    options.Name or "Slider",
                    12,
                    theme.Text
                )

                name.Size = UDim2.new(1, -60, 0, 23)

                local valueText = label(
                    wrap,
                    tostring(value),
                    12,
                    theme.Accent,
                    true
                )

                valueText.TextXAlignment = Enum.TextXAlignment.Right
                valueText.Position = UDim2.new(1, -55, 0, 0)
                valueText.Size = UDim2.fromOffset(55, 23)

                local bar = create("Frame", {
                    Position = UDim2.fromOffset(0, 36),
                    Size = UDim2.new(1, 0, 0, 6),
                    BackgroundColor3 = theme.Border,
                    BorderSizePixel = 0
                }, wrap)

                round(bar, 10)

                local ratio = (value - minimum) / (maximum - minimum)

                local fill = create("Frame", {
                    Size = UDim2.new(ratio, 0, 1, 0),
                    BackgroundColor3 = theme.Accent,
                    BorderSizePixel = 0
                }, bar)

                round(fill, 10)

                local hitbox = create("TextButton", {
                    Position = UDim2.fromOffset(0, 25),
                    Size = UDim2.new(1, 0, 0, 27),
                    BackgroundTransparency = 1,
                    Text = ""
                }, wrap)

                local sliding = false

                local function updateX(x)
                    local width = bar.AbsoluteSize.X

                    if width <= 0 then return end

                    local r = math.clamp(
                        (x - bar.AbsolutePosition.X) / width,
                        0,
                        1
                    )

                    value = math.floor(
                        minimum + (maximum - minimum) * r + 0.5
                    )

                    valueText.Text = tostring(value)

                    tween(fill, {
                        Size = UDim2.new(r, 0, 1, 0)
                    }, 0.08)

                    safeCallback(options.Callback, value)
                end

                connect(hitbox.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then

                        sliding = true
                        updateX(input.Position.X)
                    end
                end)

                connect(UserInputService.InputChanged, function(input)
                    if sliding and (
                        input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch
                    ) then
                        updateX(input.Position.X)
                    end
                end)

                connect(UserInputService.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)

                local control = {}

                function control:Get()
                    return value
                end

                function control:Set(newValue)
                    value = math.clamp(newValue, minimum, maximum)

                    local r = (value - minimum) / (maximum - minimum)

                    valueText.Text = tostring(value)
                    fill.Size = UDim2.new(r, 0, 1, 0)

                    safeCallback(options.Callback, value)
                end

                window:RegisterConfigValue(
                    options.Config or options.Name or "Slider",
                    function() return value end,
                    function(newValue) control:Set(newValue) end
                )

                table.insert(controls, control)

                return control
            end

            -- Dropdown

            function section:CreateDropdown(options)
                options = options or {}

                local choices = options.Options or {}
                local selected = options.Default or choices[1]
                local opened = false

                local button = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundColor3 = theme.Surface,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false
                }, holder)

                round(button, 10)

                local title = label(
                    button,
                    (options.Name or "Dropdown") .. ": "
                        .. tostring(selected or "None"),
                    12,
                    theme.Text
                )

                title.Position = UDim2.fromOffset(12, 0)
                title.Size = UDim2.new(1, -45, 1, 0)

                local arrow = label(button, "⌄", 17, theme.Muted, true)
                arrow.TextXAlignment = Enum.TextXAlignment.Right
                arrow.Position = UDim2.new(1, -32, 0, 0)
                arrow.Size = UDim2.fromOffset(20, 40)

                local listFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = theme.Element,
                    ClipsDescendants = true,
                    Visible = false,
                    BorderSizePixel = 0
                }, holder)

                round(listFrame, 10)

                local layout = makeList(listFrame, 4)

                local optionConnections = {}

                local function rebuild()
                    for _, connection in ipairs(optionConnections) do
                        connection:Disconnect()
                    end

                    table.clear(optionConnections)

                    for _, child in ipairs(listFrame:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end

                    for _, choice in ipairs(choices) do
                        local option = create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 31),
                            BackgroundColor3 = theme.Surface,
                            Text = tostring(choice),
                            TextColor3 = theme.Text,
                            TextSize = 12,
                            Font = Enum.Font.GothamMedium,
                            BorderSizePixel = 0,
                            AutoButtonColor = false
                        }, listFrame)

                        round(option, 7)

                        table.insert(
                            optionConnections,
                            option.MouseButton1Click:Connect(function()
                                selected = choice

                                title.Text = (options.Name or "Dropdown")
                                    .. ": " .. tostring(choice)

                                opened = false
                                listFrame.Visible = false
                                listFrame.Size = UDim2.new(1, 0, 0, 0)

                                tween(arrow, {Rotation = 0})

                                safeCallback(options.Callback, selected)
                            end)
                        )
                    end
                end

                rebuild()

                connect(button.MouseButton1Click, function()
                    opened = not opened
                    listFrame.Visible = opened

                    local height = opened
                        and (#choices * 35 + 5) or 0

                    tween(listFrame, {
                        Size = UDim2.new(1, 0, 0, height)
                    })

                    tween(arrow, {
                        Rotation = opened and 180 or 0
                    })
                end)

                local control = {}

                function control:Get()
                    return selected
                end

                function control:Set(value)
                    selected = value

                    title.Text = (options.Name or "Dropdown")
                        .. ": " .. tostring(value)

                    safeCallback(options.Callback, value)
                end

                function control:Refresh(newChoices)
                    choices = newChoices or {}
                    selected = choices[1]

                    rebuild()

                    title.Text = (options.Name or "Dropdown")
                        .. ": " .. tostring(selected or "None")
                end

                window:RegisterConfigValue(
                    options.Config or options.Name or "Dropdown",
                    function() return selected end,
                    function(value) control:Set(value) end
                )

                table.insert(controls, control)

                return control
            end

            -- Textbox

            function section:CreateTextbox(options)
                options = options or {}

                local wrap = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 64),
                    BackgroundTransparency = 1
                }, holder)

                local name = label(
                    wrap,
                    options.Name or "Textbox",
                    12,
                    theme.Text
                )

                name.Size = UDim2.new(1, 0, 0, 22)

                local box = create("TextBox", {
                    Position = UDim2.fromOffset(0, 27),
                    Size = UDim2.new(1, 0, 0, 35),
                    BackgroundColor3 = theme.Surface,
                    TextColor3 = theme.Text,
                    PlaceholderColor3 = theme.Muted,
                    PlaceholderText = options.Placeholder or "Enter text...",
                    Text = options.Default or "",
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    ClearTextOnFocus = false,
                    BorderSizePixel = 0
                }, wrap)

                round(box, 9)

                create("UIPadding", {
                    PaddingLeft = UDim.new(0, 11),
                    PaddingRight = UDim.new(0, 11)
                }, box)

                connect(box.Focused, function()
                    tween(box, {
                        BackgroundColor3 = theme.Hover
                    })
                end)

                connect(box.FocusLost, function(enterPressed)
                    tween(box, {
                        BackgroundColor3 = theme.Surface
                    })

                    safeCallback(options.Callback, box.Text, enterPressed)
                end)

                return box
            end

            -- Keybind

            function section:CreateKeybind(options)
                options = options or {}

                local key = options.Default or Enum.KeyCode.K
                local listening = false

                local button = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 39),
                    BackgroundColor3 = theme.Surface,
                    Text = (options.Name or "Keybind")
                        .. "  [" .. key.Name .. "]",
                    TextColor3 = theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    BorderSizePixel = 0,
                    AutoButtonColor = false
                }, holder)

                round(button, 10)

                connect(button.MouseButton1Click, function()
                    listening = true
                    button.Text = (options.Name or "Keybind")
                        .. "  [PRESS KEY]"

                    tween(button, {
                        BackgroundColor3 = theme.Accent
                    })
                end)

                connect(UserInputService.InputBegan, function(input, processed)
                    if processed then return end

                    if listening
                        and input.UserInputType == Enum.UserInputType.Keyboard then

                        if input.KeyCode == Enum.KeyCode.Escape then
                            listening = false
                        else
                            key = input.KeyCode
                            listening = false
                        end

                        button.Text = (options.Name or "Keybind")
                            .. "  [" .. key.Name .. "]"

                        tween(button, {
                            BackgroundColor3 = theme.Surface
                        })

                    elseif not listening and input.KeyCode == key then
                        safeCallback(options.Callback)
                    end
                end)

                local control = {}

                function control:Get()
                    return key
                end

                function control:Set(newKey)
                    key = newKey

                    button.Text = (options.Name or "Keybind")
                        .. "  [" .. key.Name .. "]"
                end

                return control
            end

            -- Color picker

            function section:CreateColorpicker(options)
                options = options or {}

                local current = options.Default or theme.Accent

                local button = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundColor3 = theme.Surface,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false
                }, holder)

                round(button, 10)

                local name = label(
                    button,
                    options.Name or "Color picker",
                    12,
                    theme.Text
                )

                name.Position = UDim2.fromOffset(12, 0)
                name.Size = UDim2.new(1, -60, 1, 0)

                local preview = create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -11, 0.5, 0),
                    Size = UDim2.fromOffset(28, 21),
                    BackgroundColor3 = current,
                    BorderSizePixel = 0
                }, button)

                round(preview, 6)

                local palette = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = theme.Element,
                    ClipsDescendants = true,
                    Visible = false,
                    BorderSizePixel = 0
                }, holder)

                round(palette, 10)

                local colors = {
                    Color3.fromRGB(155, 105, 255),
                    Color3.fromRGB(80, 150, 255),
                    Color3.fromRGB(45, 205, 220),
                    Color3.fromRGB(75, 220, 135),
                    Color3.fromRGB(255, 190, 80),
                    Color3.fromRGB(255, 95, 125),
                    Color3.fromRGB(255, 255, 255),
                    Color3.fromRGB(40, 42, 55)
                }

                local grid = create("Frame", {
                    Position = UDim2.fromOffset(10, 9),
                    Size = UDim2.new(1, -20, 1, -18),
                    BackgroundTransparency = 1
                }, palette)

                create("UIGridLayout", {
                    CellSize = UDim2.fromOffset(30, 25),
                    CellPadding = UDim2.fromOffset(7, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                }, grid)

                local opened = false

                for _, color in ipairs(colors) do
                    local swatch = create("TextButton", {
                        BackgroundColor3 = color,
                        Text = "",
                        BorderSizePixel = 0
                    }, grid)

                    round(swatch, 7)

                    connect(swatch.MouseButton1Click, function()
                        current = color
                        preview.BackgroundColor3 = color
                        safeCallback(options.Callback, color)
                    end)
                end

                connect(button.MouseButton1Click, function()
                    opened = not opened
                    palette.Visible = opened

                    tween(palette, {
                        Size = UDim2.new(1, 0, 0, opened and 85 or 0)
                    })
                end)

                local control = {}

                function control:Get()
                    return current
                end

                function control:Set(color)
                    current = color
                    preview.BackgroundColor3 = color
                    safeCallback(options.Callback, color)
                end

                return control
            end

            -- Return section

            return section
        end

        tabs[tabName] = tab
        table.insert(pages, page)

        if not selectedTab then
            select()
        end

        return tab
    end

    --==================================================
    -- BUILT-IN ESP VISUAL PREVIEW
    --==================================================

    function window:CreateESPPreview(parent, options)
        options = options or {}

        local preview = create("Frame", {
            Name = "ESPPreview",
            Size = UDim2.new(1, 0, 0, options.Height or 270),
            BackgroundColor3 = theme.Background,
            BorderSizePixel = 0,
            ClipsDescendants = true
        }, parent)

        round(preview, 14)
        outline(preview, theme.Border, 0.2)

        local header = label(
            preview,
            "VISUAL PREVIEW",
            10,
            theme.Muted,
            true
        )

        header.Position = UDim2.fromOffset(13, 7)
        header.Size = UDim2.new(1, -26, 0, 20)

        local scene = create("Frame", {
            Position = UDim2.fromOffset(10, 34),
            Size = UDim2.new(1, -20, 1, -44),
            BackgroundColor3 = Color3.fromRGB(20, 24, 33),
            BorderSizePixel = 0,
            ClipsDescendants = true
        }, preview)

        round(scene, 10)

        local backgroundText = label(
            scene,
            "SUSLIB  /  ESP SIMULATION",
            9,
            Color3.fromRGB(90, 100, 120),
            true
        )

        backgroundText.Position = UDim2.fromOffset(12, 8)
        backgroundText.Size = UDim2.new(1, -24, 0, 16)

        local mockObjects = {}

        local function createMock(x, y, name, distance, color)
            local box = create("Frame", {
                Position = UDim2.new(x, 0, y, 0),
                Size = UDim2.fromOffset(68, 115),
                BackgroundTransparency = 1,
                BorderSizePixel = 0
            }, scene)

            local boxStroke = outline(box, color, 0)
            boxStroke.Thickness = 1.5

            local nameLabel = label(
                scene,
                name,
                10,
                Color3.new(1, 1, 1),
                true
            )

            nameLabel.Position = UDim2.new(x, -12, y, -20)
            nameLabel.Size = UDim2.fromOffset(100, 17)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Center

            local distanceLabel = label(
                scene,
                distance,
                9,
                Color3.fromRGB(205, 210, 220)
            )

            distanceLabel.Position = UDim2.new(x, -12, y, 116)
            distanceLabel.Size = UDim2.fromOffset(100, 15)
            distanceLabel.TextXAlignment = Enum.TextXAlignment.Center

            local healthBackground = create("Frame", {
                Position = UDim2.new(x, -7, y, 0),
                Size = UDim2.fromOffset(4, 115),
                BackgroundColor3 = Color3.fromRGB(50, 55, 65),
                BorderSizePixel = 0
            }, scene)

            local health = create("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0.8, 0),
                BackgroundColor3 = Color3.fromRGB(80, 220, 130),
                BorderSizePixel = 0
            }, healthBackground)

            mockObjects[name] = {
                Box = box,
                Stroke = boxStroke,
                Name = nameLabel,
                Distance = distanceLabel,
                Health = healthBackground
            }
        end

        createMock(0.16, 0.28, "Player_01", "12m", theme.Accent)
        createMock(0.46, 0.20, "Player_02", "25m", Color3.fromRGB(80, 190, 255))
        createMock(0.76, 0.34, "Player_03", "48m", Color3.fromRGB(255, 190, 80))

        local previewApi = {}

        function previewApi:SetVisible(state)
            scene.Visible = state == true
        end

        function previewApi:SetAccent(color)
            for _, object in pairs(mockObjects) do
                object.Stroke.Color = color
            end
        end

        function previewApi:SetNames(state)
            for _, object in pairs(mockObjects) do
                object.Name.Visible = state == true
            end
        end

        function previewApi:SetBoxes(state)
            for _, object in pairs(mockObjects) do
                object.Box.Visible = state == true
            end
        end

        function previewApi:SetDistances(state)
            for _, object in pairs(mockObjects) do
                object.Distance.Visible = state == true
            end
        end

        function previewApi:SetHealth(state)
            for _, object in pairs(mockObjects) do
                object.Health.Visible = state == true
            end
        end

        return previewApi
    end

    --==================================================
    -- BUILT-IN TABS
    --==================================================

    local homeTab = window:CreateTab("Home")
    local visualTab = window:CreateTab("Visuals")
    local themeTab = window:CreateTab("Themes")
    local settingsTab = window:CreateTab("Settings")
    local configTab = window:CreateTab("Configs")

    -- HOME

    local homeSection = homeTab:CreateSection("Welcome to Suslib")

    homeSection:CreateLabel(
        "A customizable Luau interface framework."
    )

    homeSection:CreateLabel(
        "Version 3.0.0  |  Standalone UI"
    )

    homeSection:CreateButton({
        Name = "Test Notification",
        Callback = function()
            window:Notify(
                "Suslib is working correctly!",
                3,
                "Success"
            )
        end
    })

    local quickSection = homeTab:CreateSection("Quick Controls")

    quickSection:CreateDropdown({
        Name = "Quick Page Selector",
        Options = {"Home", "Visuals", "Themes", "Settings", "Configs"},
        Callback = function(value)
            local selected = tabs[value]

            if selected then
                selected:Select()
            end
        end
    })

    quickSection:CreateButton({
        Name = "Reset Window Position",
        Callback = function()
            tween(main, {
                Position = UDim2.fromScale(0.5, 0.5)
            }, 0.35)
        end
    })

    -- VISUALS

    local previewSection = visualTab:CreateSection("ESP Preview")

    local preview = window:CreateESPPreview(
        previewSection.Holder,
        {Height = 270}
    )

    local espSection = visualTab:CreateSection("Preview Options")

    espSection:CreateToggle({
        Name = "Show Boxes",
        Default = true,
        Callback = function(value)
            preview:SetBoxes(value)
        end
    })

    espSection:CreateToggle({
        Name = "Show Names",
        Default = true,
        Callback = function(value)
            preview:SetNames(value)
        end
    })

    espSection:CreateToggle({
        Name = "Show Distances",
        Default = true,
        Callback = function(value)
            preview:SetDistances(value)
        end
    })

    espSection:CreateToggle({
        Name = "Show Health Bars",
        Default = true,
        Callback = function(value)
            preview:SetHealth(value)
        end
    })

    espSection:CreateDropdown({
        Name = "Preview Style",
        Options = {"Classic", "Corner", "Filled", "Minimal"},
        Default = "Classic",
        Callback = function(value)
            window:Notify("Preview style: " .. value, 2)
        end
    })

    -- THEMES

    local themeSection = themeTab:CreateSection("Theme Manager")

    themeSection:CreateDropdown({
        Name = "Select Theme",
        Options = {"Purple", "Midnight", "Ocean", "Crimson", "Emerald"},
        Default = "Purple",
        Callback = function(value)
            window:SetTheme(value)
        end
    })

    themeSection:CreateButton({
        Name = "Reset Theme",
        Callback = function()
            window:SetTheme("Purple")
        end
    })

    themeSection:CreateColorpicker({
        Name = "Preview Accent Color",
        Default = theme.Accent,
        Callback = function(color)
            window:SetAccent(color)
            preview:SetAccent(color)
        end
    })

    -- SETTINGS

    local interfaceSection = settingsTab:CreateSection("Interface Settings")

    interfaceSection:CreateToggle({
        Name = "Interface Animations",
        Default = true,
        Callback = function(value)
            settings.Animations = value
        end
    })

    interfaceSection:CreateKeybind({
        Name = "Toggle Interface Key",
        Default = Enum.KeyCode.RightShift,
        Callback = function()
            gui.Enabled = not gui.Enabled
        end
    })

    interfaceSection:CreateButton({
        Name = "Reset Interface",
        Callback = function()
            window:SetTheme("Purple")

            tween(main, {
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(780, 540)
            }, 0.3)

            window:Notify("Interface reset!", 2, "Success")
        end
    })

    -- CONFIGS

    local configSection = configTab:CreateSection("Configuration Manager")

    local configOutput

    configSection:CreateButton({
        Name = "Export Configuration",
        Callback = function()
            configOutput.Text = window:ExportConfig()
            window:Notify("Configuration generated!", 3, "Success")
        end
    })

    configSection:CreateButton({
        Name = "Import Configuration",
        Callback = function()
            local success, message = window:ImportConfig(configOutput.Text)

            if not success then
                window:Notify(message, 3, "Error")
            end
        end
    })

    configSection:CreateButton({
        Name = "Clear Configuration Box",
        Callback = function()
            configOutput.Text = ""
        end
    })

    configOutput = configSection:CreateTextbox({
        Name = "Configuration JSON",
        Placeholder = "Paste exported configuration here..."
    })

    configOutput.Text = ""

    configSection:CreateLabel(
        "Configurations are exported as JSON text."
    )

    --==================================================
    -- GLOBAL INPUT
    --==================================================

    connect(UserInputService.InputBegan, function(input, processed)
        if processed then return end

        if input.KeyCode == settings.ToggleKey then
            gui.Enabled = not gui.Enabled
        end
    end)

    --==================================================
    -- OPEN ANIMATION
    --==================================================

    main.Size = UDim2.fromOffset(0, 0)

    tween(main, {
        Size = UDim2.fromOffset(780, 540)
    }, 0.45)

    window:Notify("Welcome to Suslib V3.0!", 4, "Success")

    print("[Suslib] V3.0 loaded successfully.")

    return window
end

--==================================================
-- PUBLIC API
--==================================================

function Suslib:GetThemes()
    local result = {}

    for name in pairs(Themes) do
        table.insert(result, name)
    end

    table.sort(result)

    return result
end

function Suslib:CreateTheme(name, custom)
    assert(type(name) == "string", "Theme name must be a string")
    assert(type(custom) == "table", "Theme must be a table")

    local base = copyTable(Themes.Purple)

    for key, value in pairs(custom) do
        if base[key] ~= nil then
            base[key] = value
        end
    end

    Themes[name] = base

    return base
end

return Suslib
