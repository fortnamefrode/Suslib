local Theme = {}

Theme.Default = {
    Background = Color3.fromRGB(15, 15, 21),
    Sidebar = Color3.fromRGB(20, 20, 28),
    Surface = Color3.fromRGB(29, 29, 40),
    SurfaceHover = Color3.fromRGB(40, 39, 53),
    Accent = Color3.fromRGB(160, 95, 255),
    Text = Color3.fromRGB(245, 243, 255),
    Muted = Color3.fromRGB(155, 151, 172),
    Border = Color3.fromRGB(54, 51, 69),
    Success = Color3.fromRGB(100, 220, 150),
    Danger = Color3.fromRGB(240, 90, 100)
}

function Theme.Create(custom)
    local result = {}

    for key, value in pairs(Theme.Default) do
        result[key] = value
    end

    for key, value in pairs(custom or {}) do
        if result[key] ~= nil then
            result[key] = value
        end
    end

    return result
end

return Theme
