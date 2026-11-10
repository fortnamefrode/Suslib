
--[[
    SUSLIB
    Modern modular Luau UI Library
    Version 1.0.0
]]

local Suslib = {}
Suslib.__index = Suslib

Suslib.Version = "1.0.0"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ThemeModule = require(script.Parent.Services.Theme)

local function create(class, properties, parent)
    local object = Instance.new(class)

    for key, value in pairs(properties or {}) do
        object[key] = value
    end

    object.Parent = parent
    return object
end

local function round(object, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, object)
end

local function outline(object, color)
    return create("UIStroke", {
        Color = color,
        Thickness = 1,
        Transparency = 0.2
    }, object)
end

local function animate(object, properties, duration)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.15,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        properties
    )

    tween:Play()
    return tween
end

local function createText(parent, text, size, color, bold)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextColor3 = color,
        TextSize = size or 13,
        Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 1, 0)
    }, parent)
end

local function createList(parent, padding)
    return create("UIListLayout", {
        Padding = UDim.new(0, padding or 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, parent)
end

local function createButton(parent, text, theme, height)
    local button = create("TextButton", {
        BackgroundColor3 = theme.Surface,
        Size = UDim2.new(1, 0, 0, height or 36),
        Text = tostring(text),
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        BorderSizePixel = 0
    }, parent)

    round(button, 7)

    button.MouseEnter:Connect(function()
        animate(button, {
            BackgroundColor3 = theme.SurfaceHover
        })
    end)

    button.MouseLeave:Connect(function()
        animate(button, {
            BackgroundColor3 = theme.Surface
        })
    end)

    return button
end

function Suslib:CreateWindow(options)
    options = options or {}

    local player = Players.LocalPlayer
    assert(player, "Suslib must be used from a client LocalScript.")

    local theme = ThemeModule.Create(options.Theme)

    if options.Accent then
        theme.Accent = options.Accent
    end

    local playerGui = player:WaitForChild("PlayerGui")

    local gui = create("ScreenGui", {
        Name = "Suslib",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, playerGui)

    local main = create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = options.Size or UDim2.fromOffset(680, 460),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, gui)

    round(main, 12)
    outline(main, theme.Border)

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0
    }, main)

    local title = createText(
        topbar,
        options.Title or "Suslib",
        17,
        theme.Text,
        true
    )

    title.Position = UDim2.fromOffset(18, 0)
    title.Size = UDim2.new(1, -80, 0, 32)

    local subtitle = createText(
        topbar,
        options.Subtitle or "Modern Luau UI Library",
        11,
        theme.Muted,
        false
    )

    subtitle.Position = UDim2.fromOffset(19, 27)
    subtitle.Size = UDim2.new(1, -80, 0, 20)

    local close = create("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(31, 31),
        BackgroundColor3 = theme.Surface,
        Text = "×",
        TextColor3 = theme.Text,
        TextSize = 22,
        Font = Enum.Font.Gotham,
        AutoButtonColor = false
    }, topbar)

    round(close, 7)

    local sidebar = create("ScrollingFrame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(12, 70),
        Size = UDim2.new(0, 150, 1, -82),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, main)

    round(sidebar, 9)

    create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 9),
        PaddingRight = UDim.new(0, 9),
        PaddingBottom = UDim.new(0, 10)
    }, sidebar)

    createList(sidebar, 7)

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(174, 70),
        Size = UDim2.new(1, -186, 1, -82),
        BackgroundTransparency = 1
    }, main)

    local window = {
        Gui = gui,
        Main = main,
        Sidebar = sidebar,
        Content = content,
        Theme = theme,
        Tabs = {},
        Connections = {},
        Destroyed = false
    }

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(window.Connections, connection)
        return connection
    end

    -- Window dragging
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
        if not dragging then
            return
        end

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

    connect(close.MouseButton1Click, function()
        window:Destroy()
    end)

    function window:Notify(message, duration)
        if self.Destroyed then return end

        local notification = create("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -18, 1, 70),
            Size = UDim2.fromOffset(260, 65),
            BackgroundColor3 = theme.Sidebar,
            BorderSizePixel = 0,
            ZIndex = 20
        }, gui)

        round(notification, 9)
        outline(notification, theme.Accent)

        local accentBar = create("Frame", {
            Size = UDim2.new(0, 3, 1, -18),
            Position = UDim2.fromOffset(9, 9),
            BackgroundColor3 = theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 21
        }, notification)

        round(accentBar, 3)

        local messageLabel = createText(
            notification,
            message,
            12,
            theme.Text,
            false
        )

        messageLabel.Position = UDim2.fromOffset(22, 8)
        messageLabel.Size = UDim2.new(1, -32, 1, -16)
        messageLabel.TextWrapped = true
        messageLabel.ZIndex = 21

        animate(notification, {
            Position = UDim2.new(1, -18, 1, -18)
        })

        task.delay(duration or 3, function()
            if notification.Parent then
                animate(notification, {
                    Position = UDim2.new(1, -18, 1, 70)
                }, 0.2)

                task.wait(0.25)
                notification:Destroy()
            end
        end)
    end

    function window:SetAccent(color)
        theme.Accent = color

        for _, tab in ipairs(self.Tabs) do
            if tab.Active then
                tab.Button.BackgroundColor3 = color
            end
        end

        sidebar.ScrollBarImageColor3 = color
    end

    function window:SetVisible(state)
        gui.Enabled = state == true
    end

    function window:Destroy()
        if self.Destroyed then return end

        self.Destroyed = true

        for _, connection in ipairs(self.Connections) do
            connection:Disconnect()
        end

        table.clear(self.Connections)

        if gui then
            gui:Destroy()
        end
    end

    function window:CreateTab(tabName)
        assert(not self.Destroyed, "Cannot create a tab on a destroyed window.")

        local page = create("ScrollingFrame", {
            Name = tostring(tabName),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Accent,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false
        }, content)

        create("UIPadding", {
            PaddingTop = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 9),
            PaddingBottom = UDim.new(0, 10)
        }, page)

        createList(page, 10)

        local tabButton = createButton(
            sidebar,
            tabName,
            theme,
            35
        )

        local tab = {
            Name = tabName,
            Page = page,
            Button = tabButton,
            Active = false,
            Window = self
        }

        function tab:Select()
            for _, other in ipairs(self.Window.Tabs) do
                other.Active = false
                other.Page.Visible = false

                animate(other.Button, {
                    BackgroundColor3 = theme.Surface
                })
            end

            self.Active = true
            self.Page.Visible = true

            animate(self.Button, {
                BackgroundColor3 = theme.Accent
            })
        end

        connect(tabButton.MouseButton1Click, function()
            tab:Select()
        end)

        function tab:CreateSection(sectionName)
            local sectionFrame = create("Frame", {
                Name = tostring(sectionName),
                Size = UDim2.new(1, 0, 0, 50),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Sidebar,
                BorderSizePixel = 0
            }, page)

            round(sectionFrame, 9)
            outline(sectionFrame, theme.Border)

            local sectionTitle = createText(
                sectionFrame,
                sectionName,
                13,
                theme.Accent,
                true
            )

            sectionTitle.Position = UDim2.fromOffset(12, 7)
            sectionTitle.Size = UDim2.new(1, -24, 0, 22)

            local holder = create("Frame", {
                Name = "Controls",
                Position = UDim2.fromOffset(10, 34),
                Size = UDim2.new(1, -20, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1
            }, sectionFrame)

            createList(holder, 7)

            create("UIPadding", {
                PaddingBottom = UDim.new(0, 10)
            }, holder)

            local section = {
                Holder = holder,
                Window = self.Window
            }

            function section:CreateLabel(text)
                local label = createText(
                    holder,
                    text,
                    12,
                    theme.Muted,
                    false
                )

                label.Size = UDim2.new(1, 0, 0, 26)
                return label
            end

            function section:CreateButton(options)
                options = type(options) == "table"
                    and options or {Name = tostring(options)}

                local button = createButton(
                    holder,
                    options.Name or "Button",
                    theme,
                    36
                )

                button.MouseButton1Click:Connect(function()
                    if options.Callback then
                        local ok, err = pcall(options.Callback)

                        if not ok then
                            warn("[Suslib] Button error:", err)
                        end
                    end
                end)

                return button
            end

            function section:CreateToggle(options)
                options = options or {}

                local state = options.Default == true

                local button = createButton(
                    holder,
                    "",
                    theme,
                    36
                )

                button.TextXAlignment = Enum.TextXAlignment.Left

                local name = createText(
                    button,
                    options.Name or "Toggle",
                    12,
                    theme.Text,
                    false
                )

                name.Position = UDim2.fromOffset(11, 0)
                name.Size = UDim2.new(1, -65, 1, 0)

                local switch = create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.fromOffset(34, 18),
                    BackgroundColor3 = state and theme.Accent or theme.Border,
                    BorderSizePixel = 0
                }, button)

                round(switch, 20)

                local dot = create("Frame", {
                    Position = state
                        and UDim2.new(1, -16, 0, 2)
                        or UDim2.fromOffset(2, 2),
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0
                }, switch)

                round(dot, 20)

                local function update()
                    animate(switch, {
                        BackgroundColor3 = state and theme.Accent or theme.Border
                    })

                    animate(dot, {
                        Position = state
                            and UDim2.new(1, -16, 0, 2)
                            or UDim2.fromOffset(2, 2)
                    })

                    if options.Callback then
                        local ok, err = pcall(options.Callback, state)
                        if not ok then
                            warn("[Suslib] Toggle error:", err)
                        end
                    end
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

                return control
            end

            function section:CreateSlider(options)
                options = options or {}

                local minimum = options.Min or 0
                local maximum = options.Max or 100
                local value = math.clamp(
                    options.Default or minimum,
                    minimum,
                    maximum
                )

                local wrap = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 55),
                    BackgroundTransparency = 1
                }, holder)

                local name = createText(
                    wrap,
                    options.Name or "Slider",
                    12,
                    theme.Text,
                    false
                )

                name.Size = UDim2.new(1, -55, 0, 22)

                local valueText = createText(
                    wrap,
                    tostring(value),
                    12,
                    theme.Accent,
                    true
                )

                valueText.TextXAlignment = Enum.TextXAlignment.Right
                valueText.Position = UDim2.new(1, -55, 0, 0)
                valueText.Size = UDim2.fromOffset(55, 22)

                local bar = create("Frame", {
                    Position = UDim2.fromOffset(0, 32),
                    Size = UDim2.new(1, 0, 0, 6),
                    BackgroundColor3 = theme.Border,
                    BorderSizePixel = 0
                }, wrap)

                round(bar, 10)

                local fill = create("Frame", {
                    Size = UDim2.new(
                        (value - minimum) / math.max(maximum - minimum, 1),
                        0, 1, 0
                    ),
                    BackgroundColor3 = theme.Accent,
                    BorderSizePixel = 0
                }, bar)

                round(fill, 10)

                local hitbox = create("TextButton", {
                    Position = UDim2.fromOffset(0, 22),
                    Size = UDim2.new(1, 0, 0, 25),
                    BackgroundTransparency = 1,
                    Text = ""
                }, wrap)

                local function setFromX(x)
                    local width = bar.AbsoluteSize.X
                    if width <= 0 then return end

                    local ratio = math.clamp(
                        (x - bar.AbsolutePosition.X) / width,
                        0, 1
                    )

                    value = math.floor(
                        (minimum + (maximum - minimum) * ratio) + 0.5
                    )

                    valueText.Text = tostring(value)

                    animate(fill, {
                        Size = UDim2.new(ratio, 0, 1, 0)
                    }, 0.08)

                    if options.Callback then
                        options.Callback(value)
                    end
                end

                local sliding = false

                connect(hitbox.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then

                        sliding = true
                        setFromX(input.Position.X)
                    end
                end)

                connect(UserInputService.InputChanged, function(input)
                    if sliding and (
                        input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch
                    ) then
                        setFromX(input.Position.X)
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

                    local ratio = (value - minimum)
                        / math.max(maximum - minimum, 1)

                    valueText.Text = tostring(value)
                    fill.Size = UDim2.new(ratio, 0, 1, 0)

                    if options.Callback then
                        options.Callback(value)
                    end
                end

                return control
            end

            function section:CreateDropdown(options)
                options = options or {}

                local choices = options.Options or {}
                local selected = options.Default or choices[1]
                local opened = false

                local button = createButton(
                    holder,
                    "",
                    theme,
                    36
                )

                local title = createText(
                    button,
                    (options.Name or "Dropdown") .. ": " .. tostring(selected or "None"),
                    12,
                    theme.Text,
                    false
                )

                title.Position = UDim2.fromOffset(11, 0)
                title.Size = UDim2.new(1, -22, 1, 0)

                local list = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = theme.Surface,
                    Visible = false,
                    ClipsDescendants = true
                }, holder)

                round(list, 7)
                createList(list, 3)

                local function rebuild()
                    for _, child in ipairs(list:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end

                    for _, choice in ipairs(choices) do
                        local optionButton = createButton(
                            list,
                            tostring(choice),
                            theme,
                            30
                        )

                        connect(optionButton.MouseButton1Click, function()
                            selected = choice
                            title.Text = (options.Name or "Dropdown")
                                .. ": " .. tostring(selected)

                            opened = false
                            list.Visible = false
                            list.Size = UDim2.new(1, 0, 0, 0)

                            if options.Callback then
                                options.Callback(selected)
                            end
                        end)
                    end
                end

                rebuild()

                connect(button.MouseButton1Click, function()
                    opened = not opened
                    list.Visible = opened

                    local height = opened and (#choices * 33 + 6) or 0

                    animate(list, {
                        Size = UDim2.new(1, 0, 0, height)
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

                    if options.Callback then
                        options.Callback(value)
                    end
                end

                function control:Refresh(newChoices)
                    choices = newChoices or {}
                    selected = choices[1]
                    rebuild()

                    title.Text = (options.Name or "Dropdown")
                        .. ": " .. tostring(selected or "None")
                end

                return control
            end

            function section:CreateTextbox(options)
                options = options or {}

                local wrap = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 60),
                    BackgroundTransparency = 1
                }, holder)

                local name = createText(
                    wrap,
                    options.Name or "Textbox",
                    12,
                    theme.Text,
                    false
                )

                name.Size = UDim2.new(1, 0, 0, 22)

                local box = create("TextBox", {
                    Position = UDim2.fromOffset(0, 25),
                    Size = UDim2.new(1, 0, 0, 32),
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

                round(box, 7)

                create("UIPadding", {
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10)
                }, box)

                connect(box.FocusLost, function(enterPressed)
                    if options.Callback then
                        options.Callback(box.Text, enterPressed)
                    end
                end)

                return box
            end

            return section
        end

        table.insert(self.Window.Tabs, tab)

        if #self.Window.Tabs == 1 then
            tab:Select()
        end

        return tab
    end

    return window
end

return Suslib
