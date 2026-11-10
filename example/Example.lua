
-- SUSLIB EXAMPLE
-- Run this from a Roblox LocalScript.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Suslib = require(
    ReplicatedStorage:WaitForChild("Suslib")
)

local Window = Suslib:CreateWindow({
    Title = "Suslib",
    Subtitle = "My Custom UI Library",

    Size = UDim2.fromOffset(680, 460),

    Accent = Color3.fromRGB(160, 95, 255)
})

local Main = Window:CreateTab("Main")
local Player = Window:CreateTab("Player")
local Settings = Window:CreateTab("Settings")

-- MAIN
local General = Main:CreateSection("General")

General:CreateLabel("Welcome to Suslib!")

General:CreateButton({
    Name = "Test Notification",

    Callback = function()
        Window:Notify("Suslib is working!", 3)
    end
})

General:CreateToggle({
    Name = "Example Toggle",
    Default = false,

    Callback = function(value)
        print("Toggle:", value)
    end
})

General:CreateDropdown({
    Name = "Select Mode",

    Options = {
        "Normal",
        "Advanced",
        "Experimental"
    },

    Default = "Normal",

    Callback = function(value)
        print("Selected:", value)
    end
})

-- PLAYER
local PlayerSection = Player:CreateSection("Player Settings")

PlayerSection:CreateSlider({
    Name = "WalkSpeed",
    Min = 0,
    Max = 100,
    Default = 16,

    Callback = function(value)
        print("WalkSpeed:", value)
    end
})

PlayerSection:CreateTextbox({
    Name = "Custom Message",
    Placeholder = "Type something...",

    Callback = function(text)
        print("Message:", text)
    end
})

-- SETTINGS
local SettingsSection = Settings:CreateSection("Interface")

SettingsSection:CreateButton({
    Name = "Change Accent",

    Callback = function()
        Window:SetAccent(
            Color3.fromRGB(255, 80, 140)
        )
    end
})

SettingsSection:CreateButton({
    Name = "Show Notification",

    Callback = function()
        Window:Notify("Welcome to your own UI library!", 4)
    end
})

SettingsSection:CreateButton({
    Name = "Destroy UI",

    Callback = function()
        Window:Destroy()
    end
})

print("Suslib loaded successfully! Version:", Suslib.Version)
