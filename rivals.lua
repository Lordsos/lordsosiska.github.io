-- 🔥 sosiskahook - Ultimate Aimbot & ESP
-- Клавиша меню: Insert | Panic Key: Delete

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- 🔧 Настройки
local Config = {
    Aimbot = {
        Enabled = true,
        Mode = "Mouse",
        Smoothness = 0.2,
        FieldOfView = 200,
        TeamCheck = false,
        IgnoreDead = true,
        TargetPart = "Head",
        WallCheck = false,
        MaxDistance = 500,
        Prediction = false,
        PredictionAmount = 0.125,
        ShowFOV = true,
        Killshot = {
            Enabled = true,
            HealthThreshold = 10,
            BodyPart = "HumanoidRootPart"
        },
        DynamicFOV = false,
    },
    CameraAim = {
        Enabled = true,
        Smoothness = 0.3,
    },
    ESP = {
        Enabled = true,
        Box = true,
        Name = true,
        Health = true,
        HealthBar = true, -- НОВОЕ
        Distance = false,
        MaxDistance = 200,
        Skeleton = false,
        WeaponInfo = false,
        GradientHealth = true,
    },
    Chams = { -- НОВОЕ
        Enabled = true,
        FillTransparency = 0.5,
        OutlineTransparency = 0,
        TeamCheck = false,
    },
    Colors = {
        MenuColor = {R = 138, G = 43, B = 226}, -- Фиолетовый
        FOVCircle = {R = 138, G = 43, B = 226},
        ESPBox = {R = 138, G = 43, B = 226},
        ESPName = {R = 255, G = 255, B = 255},
        ESPHealth = {R = 0, G = 255, B = 0},
        ESPDistance = {R = 200, G = 200, B = 100},
        Skeleton = {R = 255, G = 255, B = 255},
        ChamsFill = {R = 138, G = 43, B = 226}, -- НОВОЕ
        ChamsOutline = {R = 255, G = 255, B = 255}, -- НОВОЕ
        Watermark = {R = 138, G = 43, B = 226}, -- НОВОЕ
    },
    Misc = { -- НОВОЕ
        PanicKey = Enum.KeyCode.Delete,
        StreamProof = false,
        Watermark = true,
    },
    MenuKey = Enum.KeyCode.Insert,
}

-- Panic Mode
local PanicMode = false

-- Функция для конвертации Color3
local function Color3ToTable(color)
    return {
        R = math.floor(color.R * 255),
        G = math.floor(color.G * 255),
        B = math.floor(color.B * 255)
    }
end

local function TableToColor3(tbl)
    return Color3.fromRGB(tbl.R or 255, tbl.G or 255, tbl.B or 255)
end

local function getColor(colorName)
    local colorData = Config.Colors[colorName]
    return TableToColor3(colorData)
end

-- 📁 Система сохранения конфига
local CONFIG_FILE = "sosiskahook_config.json"
local CONFIG_VERSION = "2.0"

local fileFunctionsAvailable = false

local function checkFileFunctions()
    local success = pcall(function()
        if writefile and readfile and isfile then
            fileFunctionsAvailable = true
            return true
        end
    end)
    return success and fileFunctionsAvailable
end

checkFileFunctions()

local saveConfigToFile, loadConfigFromFile

local function deepCopySettings(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = deepCopySettings(v)
        elseif type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
            copy[k] = v
        end
    end
    return copy
end

saveConfigToFile = function()
    if not fileFunctionsAvailable then 
        print("⚠️ Функции работы с файлами недоступны")
        return 
    end
    
    local success, result = pcall(function()
        local configToSave = {
            version = CONFIG_VERSION,
            settings = {}
        }
        
        for categoryName, categorySettings in pairs(Config) do
            if categoryName ~= "MenuKey" then
                configToSave.settings[categoryName] = deepCopySettings(categorySettings)
            end
        end
        
        local jsonContent = HttpService:JSONEncode(configToSave)
        writefile(CONFIG_FILE, jsonContent)
        print("✅ Конфиг сохранен")
    end)
    
    if not success then
        warn("❌ Ошибка сохранения:", result)
    end
end

local function applyLoadedSettings(savedSettings)
    if not savedSettings then return end
    
    for categoryName, categorySettings in pairs(savedSettings) do
        if Config[categoryName] and type(categorySettings) == "table" then
            for settingName, settingValue in pairs(categorySettings) do
                if Config[categoryName][settingName] ~= nil then
                    local currentType = type(Config[categoryName][settingName])
                    local newType = type(settingValue)
                    
                    if currentType == newType then
                        if currentType == "table" then
                            for subName, subValue in pairs(settingValue) do
                                if Config[categoryName][settingName][subName] ~= nil then
                                    Config[categoryName][settingName][subName] = subValue
                                end
                            end
                        else
                            Config[categoryName][settingName] = settingValue
                        end
                    end
                end
            end
        end
    end
    
    print("✅ Настройки применены")
end

loadConfigFromFile = function()
    if not fileFunctionsAvailable then 
        print("⚠️ Функции работы с файлами недоступны")
        return 
    end
    
    local success, result = pcall(function()
        local fileExists = false
        pcall(function()
            fileExists = isfile(CONFIG_FILE)
        end)
        
        if not fileExists then
            print("ℹ️ Создание нового конфига")
            saveConfigToFile()
            return
        end
        
        local fileContent = readfile(CONFIG_FILE)
        if not fileContent or fileContent == "" then
            print("⚠️ Конфиг пустой")
            saveConfigToFile()
            return
        end
        
        local savedConfig = HttpService:JSONDecode(fileContent)
        
        if not savedConfig.version or savedConfig.version ~= CONFIG_VERSION then
            print("⚠️ Устаревшая версия конфига")
            saveConfigToFile()
            return
        end
        
        if savedConfig.settings then
            applyLoadedSettings(savedConfig.settings)
            print("✅ Конфиг загружен")
        end
    end)
    
    if not success then
        warn("❌ Ошибка загрузки:", result)
        task.wait(0.1)
        saveConfigToFile()
    end
end

if fileFunctionsAvailable then
    loadConfigFromFile()
    print("📁 Файловая система доступна")
else
    print("❌ Файловая система недоступна")
end

-- 🎯 Переменные
local CurrentTarget = nil
local SkeletonCache = {}
local ChamsCache = {} -- НОВОЕ

-- Вспомогательные функции
local function isAlive(character)
    if not character then return false end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function isVisible(targetPart)
    if not Config.Aimbot.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    
    local result = Workspace:Raycast(origin, direction, raycastParams)
    
    return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getBestTarget()
    local closest = nil
    local shortestDist = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.Aimbot.TeamCheck and player.Team == LocalPlayer.Team then continue end

        local char = player.Character
        if not char then continue end
        if Config.Aimbot.IgnoreDead and not isAlive(char) then continue end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local targetHealth = humanoid and humanoid.Health or 100
        
        local targetPartName = Config.Aimbot.TargetPart
        if Config.Aimbot.Killshot.Enabled and targetHealth <= Config.Aimbot.Killshot.HealthThreshold then
            targetPartName = Config.Aimbot.Killshot.BodyPart
        end
        
        local targetPart = char:FindFirstChild(targetPartName)
        if not targetPart then 
            targetPart = char:FindFirstChild("HumanoidRootPart")
            if not targetPart then continue end
        end

        local distance = (targetPart.Position - Camera.CFrame.Position).Magnitude
        if distance > Config.Aimbot.MaxDistance then continue end

        if not isVisible(targetPart) then continue end

        local checkPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end

        local distFromCenter = (Vector2.new(checkPos.X, checkPos.Y) - screenCenter).Magnitude
        
        local effectiveFOV = Config.Aimbot.FieldOfView
        if Config.Aimbot.DynamicFOV then
            effectiveFOV = math.clamp(distance * 0.5, 50, Config.Aimbot.FieldOfView)
        end
        
        if distFromCenter > effectiveFOV then continue end

        if distFromCenter < shortestDist then
            shortestDist = distFromCenter
            closest = targetPart
        end
    end

    return closest
end

-- ✅ FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.ZIndex = 999
FOVCircle.Transparency = 1
FOVCircle.Color = getColor("FOVCircle")

-- 🎨 Watermark
local WatermarkFrame = Instance.new("Frame")
WatermarkFrame.Size = UDim2.new(0, 250, 0, 70)
WatermarkFrame.Position = UDim2.new(1, -260, 0, 10)
WatermarkFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
WatermarkFrame.BorderSizePixel = 0
WatermarkFrame.ZIndex = 10000

local WatermarkCorner = Instance.new("UICorner")
WatermarkCorner.CornerRadius = UDim.new(0, 8)
WatermarkCorner.Parent = WatermarkFrame

local WatermarkTitle = Instance.new("TextLabel")
WatermarkTitle.Size = UDim2.new(1, 0, 0, 25)
WatermarkTitle.BackgroundColor3 = getColor("Watermark")
WatermarkTitle.BorderSizePixel = 0
WatermarkTitle.Text = "✨ sosiskahook"
WatermarkTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
WatermarkTitle.Font = Enum.Font.GothamBold
WatermarkTitle.TextSize = 16
WatermarkTitle.Parent = WatermarkFrame

local WatermarkTitleCorner = Instance.new("UICorner")
WatermarkTitleCorner.CornerRadius = UDim.new(0, 8)
WatermarkTitleCorner.Parent = WatermarkTitle

local WatermarkInfo = Instance.new("TextLabel")
WatermarkInfo.Size = UDim2.new(1, -10, 1, -30)
WatermarkInfo.Position = UDim2.new(0, 5, 0, 28)
WatermarkInfo.BackgroundTransparency = 1
WatermarkInfo.Text = "FPS: 60\nPing: 0ms\nTime: 00:00:00"
WatermarkInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
WatermarkInfo.Font = Enum.Font.Code
WatermarkInfo.TextSize = 12
WatermarkInfo.TextXAlignment = Enum.TextXAlignment.Left
WatermarkInfo.TextYAlignment = Enum.TextYAlignment.Top
WatermarkInfo.Parent = WatermarkFrame

-- Обновление Watermark
task.spawn(function()
    while task.wait(0.5) do
        if not Config.Misc.Watermark or Config.Misc.StreamProof or PanicMode then
            WatermarkFrame.Visible = false
        else
            WatermarkFrame.Visible = true
            local fps = math.floor(1 / RunService.RenderStepped:Wait())
            local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
            local time = os.date("%H:%M:%S")
            WatermarkInfo.Text = string.format("FPS: %d\nPing: %dms\nTime: %s", fps, ping, time)
            WatermarkTitle.BackgroundColor3 = getColor("Watermark")
        end
    end
end)

-- 🎨 GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "sosiskahook"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

WatermarkFrame.Parent = ScreenGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 500, 0, 800)
Main.Position = UDim2.new(0.5, -250, 0.5, -400)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = getColor("MenuColor")
MainStroke.Thickness = 2
MainStroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Title.BorderSizePixel = 0
Title.Text = "✨ sosiskahook - Premium"
Title.TextColor3 = getColor("MenuColor")
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = Title

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 40, 0, 40)
Close.Position = UDim2.new(1, -45, 0, 5)
Close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Close.Text = "✕"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 18
Close.Parent = Title

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = Close

Close.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -20, 1, -65)
Content.Position = UDim2.new(0, 10, 0, 57)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 6
Content.ScrollBarImageColor3 = getColor("MenuColor")
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 10)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 15)
end)

local GUIElements = {
    Toggles = {},
    Sliders = {},
    Selectors = {},
    ColorPickers = {}
}

local function Section(text)
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, -10, 0, 30)
    section.BackgroundTransparency = 1
    section.Text = "━━━ " .. text .. " ━━━"
    section.TextColor3 = getColor("MenuColor")
    section.Font = Enum.Font.GothamBold
    section.TextSize = 16
    section.TextXAlignment = Enum.TextXAlignment.Center
    section.Parent = Content
    return section
end

local function Toggle(text, configPath, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = Content

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "  " .. text
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 70, 0, 28)
    button.Position = UDim2.new(1, -75, 0.5, -14)
    button.BackgroundColor3 = default and getColor("MenuColor") or Color3.fromRGB(50, 50, 60)
    button.Text = default and "ON" or "OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    local state = default
    GUIElements.Toggles[configPath] = button
    
    button.MouseButton1Click:Connect(function()
        state = not state
        button.BackgroundColor3 = state and getColor("MenuColor") or Color3.fromRGB(50, 50, 60)
        button.Text = state and "ON" or "OFF"
        callback(state)
        
        if fileFunctionsAvailable then
            task.spawn(saveConfigToFile)
        end
    end)
    
    return button
end

local function Slider(text, configPath, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = Content

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 22)
    label.Position = UDim2.new(0, 5, 0, 3)
    label.BackgroundTransparency = 1
    label.Text = "  " .. text .. ": " .. tostring(math.round(default * 1000) / 1000)
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(1, -20, 0, 22)
    slider.Position = UDim2.new(0, 10, 0, 26)
    slider.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    slider.Text = ""
    slider.Parent = frame

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 6)
    sliderCorner.Parent = slider

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = getColor("MenuColor")
    fill.BorderSizePixel = 0
    fill.Parent = slider

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = fill

    local dragging = false
    GUIElements.Sliders[configPath] = {label = label, fill = fill, min = min, max = max, text = text}

    slider.MouseButton1Down:Connect(function()
        dragging = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging then
                dragging = false
                if fileFunctionsAvailable then
                    task.spawn(saveConfigToFile)
                end
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percentage = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(percentage, 0, 1, 0)
            local value = min + (max - min) * percentage
            value = math.round(value * 1000) / 1000
            label.Text = "  " .. text .. ": " .. tostring(value)
            callback(value)
        end
    end)
    
    return {label = label, fill = fill}
end

local function ButtonSelector(text, configPath, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = Content

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.25, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "  " .. text .. ":"
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local buttons = {}
    local buttonWidth = (1 - 0.28) / #options
    
    for i, option in ipairs(options) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(buttonWidth, -8, 0, 28)
        btn.Position = UDim2.new(0.28 + (i - 1) * buttonWidth, 4, 0.5, -14)
        btn.BackgroundColor3 = (default == option.value) and getColor("MenuColor") or Color3.fromRGB(50, 50, 60)
        btn.Text = option.text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.Parent = frame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            for _, b in pairs(buttons) do
                b.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            end
            btn.BackgroundColor3 = getColor("MenuColor")
            callback(option.value)
            
            if fileFunctionsAvailable then
                task.spawn(saveConfigToFile)
            end
        end)

        table.insert(buttons, btn)
    end
    
    GUIElements.Selectors[configPath] = {buttons = buttons, options = options}
    return buttons
end

local function ColorPicker(text, colorName, defaultColor, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = Content

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "  " .. text
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local colorBox = Instance.new("TextButton")
    colorBox.Size = UDim2.new(0, 70, 0, 28)
    colorBox.Position = UDim2.new(1, -75, 0.5, -14)
    colorBox.BackgroundColor3 = defaultColor
    colorBox.Text = ""
    colorBox.Parent = frame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = colorBox

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(255, 255, 255)
    boxStroke.Thickness = 1
    boxStroke.Parent = colorBox

    local colors = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 127, 0),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(0, 127, 255),
        Color3.fromRGB(138, 43, 226),
        Color3.fromRGB(255, 0, 255),
        Color3.fromRGB(255, 255, 255),
    }
    
    local currentIndex = 1
    GUIElements.ColorPickers[colorName] = colorBox
    
    colorBox.MouseButton1Click:Connect(function()
        currentIndex = currentIndex % #colors + 1
        local newColor = colors[currentIndex]
        colorBox.BackgroundColor3 = newColor
        Config.Colors[colorName] = Color3ToTable(newColor)
        callback(newColor)
        
        if fileFunctionsAvailable then
            task.spawn(saveConfigToFile)
        end
    end)
    
    return colorBox
end

local function updateGUIFromConfig()
    for path, button in pairs(GUIElements.Toggles) do
        local keys = string.split(path, ".")
        local value = Config
        for _, key in ipairs(keys) do
            value = value[key]
        end
        if type(value) == "boolean" then
            button.BackgroundColor3 = value and getColor("MenuColor") or Color3.fromRGB(50, 50, 60)
            button.Text = value and "ON" or "OFF"
        end
    end
    
    for path, data in pairs(GUIElements.Sliders) do
        local keys = string.split(path, ".")
        local value = Config
        for _, key in ipairs(keys) do
            value = value[key]
        end
        if type(value) == "number" then
            local percentage = (value - data.min) / (data.max - data.min)
            data.fill.Size = UDim2.new(percentage, 0, 1, 0)
            data.label.Text = "  " .. data.text .. ": " .. tostring(math.round(value * 1000) / 1000)
        end
    end
    
    for colorName, colorBox in pairs(GUIElements.ColorPickers) do
        local colorData = Config.Colors[colorName]
        if colorData then
            colorBox.BackgroundColor3 = TableToColor3(colorData)
        end
    end
    
    FOVCircle.Color = getColor("FOVCircle")
    Title.TextColor3 = getColor("MenuColor")
    MainStroke.Color = getColor("MenuColor")
    Content.ScrollBarImageColor3 = getColor("MenuColor")
    
    print("🔄 GUI обновлен")
end

local function ProfileManager()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = Content

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.35, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "  Профиль:"
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.28, 0, 0, 30)
    saveBtn.Position = UDim2.new(0.36, 0, 0.5, -15)
    saveBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
    saveBtn.Text = "💾 Сохранить"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 12
    saveBtn.Parent = frame

    local loadBtn = Instance.new("TextButton")
    loadBtn.Size = UDim2.new(0.28, 0, 0, 30)
    loadBtn.Position = UDim2.new(0.68, 0, 0.5, -15)
    loadBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    loadBtn.Text = "📂 Загрузить"
    loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadBtn.Font = Enum.Font.GothamBold
    loadBtn.TextSize = 12
    loadBtn.Parent = frame

    local corner1 = Instance.new("UICorner")
    corner1.CornerRadius = UDim.new(0, 5)
    corner1.Parent = saveBtn

    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 5)
    corner2.Parent = loadBtn

    saveBtn.MouseButton1Click:Connect(function()
        if fileFunctionsAvailable then
            saveConfigToFile()
        else
            print("❌ Файловая система недоступна")
        end
    end)

    loadBtn.MouseButton1Click:Connect(function()
        if fileFunctionsAvailable then
            loadConfigFromFile()
            task.wait(0.1)
            updateGUIFromConfig()
        else
            print("❌ Файловая система недоступна")
        end
    end)
end

-- BUILD MENU
Section("🎯 Режим Аимбота")
ButtonSelector("Режим", "Aimbot.Mode", {
    {text = "Мышь", value = "Mouse"},
    {text = "Камера", value = "Camera"}
}, Config.Aimbot.Mode, function(v) 
    Config.Aimbot.Mode = v 
end)

Section("⚙️ Настройки Аимбота")
Toggle("Включить", "Aimbot.Enabled", Config.Aimbot.Enabled, function(v) Config.Aimbot.Enabled = v end)
Slider("Плавность", "Aimbot.Smoothness", 0.05, 1, Config.Aimbot.Smoothness, function(v) Config.Aimbot.Smoothness = v end)
Slider("FOV", "Aimbot.FieldOfView", 50, 500, Config.Aimbot.FieldOfView, function(v) 
    Config.Aimbot.FieldOfView = v 
    FOVCircle.Radius = v
end)
Toggle("Показать FOV", "Aimbot.ShowFOV", Config.Aimbot.ShowFOV, function(v) Config.Aimbot.ShowFOV = v end)
Toggle("Проверка команды", "Aimbot.TeamCheck", Config.Aimbot.TeamCheck, function(v) Config.Aimbot.TeamCheck = v end)
Toggle("Игнорировать мертвых", "Aimbot.IgnoreDead", Config.Aimbot.IgnoreDead, function(v) Config.Aimbot.IgnoreDead = v end)
Toggle("Проверка стен", "Aimbot.WallCheck", Config.Aimbot.WallCheck, function(v) Config.Aimbot.WallCheck = v end)
Toggle("Предсказание", "Aimbot.Prediction", Config.Aimbot.Prediction, function(v) Config.Aimbot.Prediction = v end)
Slider("Сила предсказания", "Aimbot.PredictionAmount", 0.05, 0.5, Config.Aimbot.PredictionAmount, function(v) Config.Aimbot.PredictionAmount = v end)
Slider("Макс. дистанция", "Aimbot.MaxDistance", 100, 1000, Config.Aimbot.MaxDistance, function(v) Config.Aimbot.MaxDistance = v end)
ButtonSelector("Часть тела", "Aimbot.TargetPart", {
    {text = "Голова", value = "Head"},
    {text = "Тело", value = "HumanoidRootPart"}
}, Config.Aimbot.TargetPart, function(v) Config.Aimbot.TargetPart = v end)
Toggle("Динамический FOV", "Aimbot.DynamicFOV", Config.Aimbot.DynamicFOV, function(v) Config.Aimbot.DynamicFOV = v end)

Section("💀 Система Добивания")
Toggle("Killshot", "Aimbot.Killshot.Enabled", Config.Aimbot.Killshot.Enabled, function(v) Config.Aimbot.Killshot.Enabled = v end)
Slider("Порог HP", "Aimbot.Killshot.HealthThreshold", 1, 50, Config.Aimbot.Killshot.HealthThreshold, function(v) Config.Aimbot.Killshot.HealthThreshold = v end)
ButtonSelector("Часть тела", "Aimbot.Killshot.BodyPart", {
    {text = "Голова", value = "Head"},
    {text = "Тело", value = "HumanoidRootPart"}
}, Config.Aimbot.Killshot.BodyPart, function(v) Config.Aimbot.Killshot.BodyPart = v end)

Section("📷 Камера")
Slider("Плавность камеры", "CameraAim.Smoothness", 0.1, 1, Config.CameraAim.Smoothness, function(v) Config.CameraAim.Smoothness = v end)

Section("👁️ ESP")
Toggle("Включить", "ESP.Enabled", Config.ESP.Enabled, function(v) Config.ESP.Enabled = v end)
Toggle("Рамка", "ESP.Box", Config.ESP.Box, function(v) Config.ESP.Box = v end)
Toggle("Имя", "ESP.Name", Config.ESP.Name, function(v) Config.ESP.Name = v end)
Toggle("Здоровье", "ESP.Health", Config.ESP.Health, function(v) Config.ESP.Health = v end)
Toggle("Полоса здоровья", "ESP.HealthBar", Config.ESP.HealthBar, function(v) Config.ESP.HealthBar = v end)
Toggle("Дистанция", "ESP.Distance", Config.ESP.Distance, function(v) Config.ESP.Distance = v end)
Toggle("Скелет", "ESP.Skeleton", Config.ESP.Skeleton, function(v) Config.ESP.Skeleton = v end)
Toggle("Оружие", "ESP.WeaponInfo", Config.ESP.WeaponInfo, function(v) Config.ESP.WeaponInfo = v end)
Toggle("Градиент HP", "ESP.GradientHealth", Config.ESP.GradientHealth, function(v) Config.ESP.GradientHealth = v end)
Slider("Макс. дистанция", "ESP.MaxDistance", 50, 500, Config.ESP.MaxDistance, function(v) Config.ESP.MaxDistance = v end)

Section("✨ Chams (Подсветка)")
Toggle("Включить Chams", "Chams.Enabled", Config.Chams.Enabled, function(v) Config.Chams.Enabled = v end)
Slider("Прозрачность заливки", "Chams.FillTransparency", 0, 1, Config.Chams.FillTransparency, function(v) Config.Chams.FillTransparency = v end)
Slider("Прозрачность обводки", "Chams.OutlineTransparency", 0, 1, Config.Chams.OutlineTransparency, function(v) Config.Chams.OutlineTransparency = v end)
Toggle("Проверка команды", "Chams.TeamCheck", Config.Chams.TeamCheck, function(v) Config.Chams.TeamCheck = v end)

Section("🎨 Цвета")
ColorPicker("Цвет меню", "MenuColor", getColor("MenuColor"), function(v) 
    Title.TextColor3 = v
    MainStroke.Color = v
    Content.ScrollBarImageColor3 = v
    WatermarkTitle.BackgroundColor3 = v
end)
ColorPicker("FOV круг", "FOVCircle", getColor("FOVCircle"), function(v) 
    FOVCircle.Color = v
end)
ColorPicker("ESP рамка", "ESPBox", getColor("ESPBox"), function(v) end)
ColorPicker("ESP имя", "ESPName", getColor("ESPName"), function(v) end)
ColorPicker("ESP здоровье", "ESPHealth", getColor("ESPHealth"), function(v) end)
ColorPicker("ESP дистанция", "ESPDistance", getColor("ESPDistance"), function(v) end)
ColorPicker("Скелет", "Skeleton", getColor("Skeleton"), function(v) end)
ColorPicker("Chams заливка", "ChamsFill", getColor("ChamsFill"), function(v) end)
ColorPicker("Chams обводка", "ChamsOutline", getColor("ChamsOutline"), function(v) end)
ColorPicker("Watermark", "Watermark", getColor("Watermark"), function(v) 
    WatermarkTitle.BackgroundColor3 = v
end)

Section("🔧 Разное")
Toggle("Stream Proof", "Misc.StreamProof", Config.Misc.StreamProof, function(v) Config.Misc.StreamProof = v end)
Toggle("Watermark", "Misc.Watermark", Config.Misc.Watermark, function(v) Config.Misc.Watermark = v end)

Section("💾 Профили")
ProfileManager()

task.wait(0.5)
updateGUIFromConfig()

-- Dragging
local dragging, dragInput, dragStart, startPos

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

Title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Открытие меню и Panic Key
UserInputService.InputEnded:Connect(function(input, processed)
    if input.KeyCode == Config.MenuKey and not processed then
        if not PanicMode then
            Main.Visible = not Main.Visible
        end
    end
    
    -- PANIC KEY
    if input.KeyCode == Config.Misc.PanicKey then
        PanicMode = not PanicMode
        if PanicMode then
            -- Отключаем все
            Config.Aimbot.Enabled = false
            Config.ESP.Enabled = false
            Config.Chams.Enabled = false
            Config.Aimbot.ShowFOV = false
            Main.Visible = false
            print("🚨 PANIC MODE: ВСЕ ОТКЛЮЧЕНО")
        else
            -- Включаем обратно
            Config.Aimbot.Enabled = true
            Config.ESP.Enabled = true
            Config.Chams.Enabled = true
            Config.Aimbot.ShowFOV = true
            print("✅ PANIC MODE: ОТКЛЮЧЕН")
        end
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CHAMS SYSTEM
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function createChams(player)
    if ChamsCache[player] then return end
    
    local character = player.Character
    if not character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "sosiskahook_Chams"
    highlight.FillColor = getColor("ChamsFill")
    highlight.OutlineColor = getColor("ChamsOutline")
    highlight.FillTransparency = Config.Chams.FillTransparency
    highlight.OutlineTransparency = Config.Chams.OutlineTransparency
    highlight.Adornee = character
    highlight.Parent = character
    
    ChamsCache[player] = highlight
end

local function removeChams(player)
    if ChamsCache[player] then
        pcall(function()
            ChamsCache[player]:Destroy()
        end)
        ChamsCache[player] = nil
    end
end

local function updateChams()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.Chams.TeamCheck and player.Team == LocalPlayer.Team then
            removeChams(player)
            continue
        end
        
        local char = player.Character
        if not char or not isAlive(char) then
            removeChams(player)
            continue
        end
        
        if Config.Chams.Enabled and not PanicMode and not Config.Misc.StreamProof then
            if not ChamsCache[player] or not ChamsCache[player].Parent then
                createChams(player)
            else
                -- Обновляем цвета и прозрачность
                ChamsCache[player].FillColor = getColor("ChamsFill")
                ChamsCache[player].OutlineColor = getColor("ChamsOutline")
                ChamsCache[player].FillTransparency = Config.Chams.FillTransparency
                ChamsCache[player].OutlineTransparency = Config.Chams.OutlineTransparency
            end
        else
            removeChams(player)
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    removeChams(player)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- AIMBOT LOGIC
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RunService.RenderStepped:Connect(function()
    -- Update Chams
    updateChams()
    
    -- FOV Circle
    if Config.Aimbot.ShowFOV and not PanicMode and not Config.Misc.StreamProof then
        FOVCircle.Visible = true
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = Config.Aimbot.FieldOfView
        FOVCircle.Color = getColor("FOVCircle")
    else
        FOVCircle.Visible = false
    end

    if not Config.Aimbot.Enabled or PanicMode then return end

    if Config.Aimbot.Mode == "Camera" and Config.CameraAim.Enabled then
        local target = getBestTarget()
        if target then
            local targetPos = target.Position
            
            if Config.Aimbot.Prediction then
                local success, velocity = pcall(function()
                    return target.AssemblyVelocity or target.Velocity or Vector3.new(0, 0, 0)
                end)
                if success and velocity then
                    targetPos = targetPos + (velocity * Config.Aimbot.PredictionAmount)
                end
            end
            
            local currentCF = Camera.CFrame
            local targetCF = CFrame.new(Camera.CFrame.Position, targetPos)
            Camera.CFrame = currentCF:Lerp(targetCF, Config.CameraAim.Smoothness)
            return
        end
    end

    if Config.Aimbot.Mode == "Mouse" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getBestTarget()
        if target then
            local finalPosition = target.Position
            
            if Config.Aimbot.Prediction then
                local success, velocity = pcall(function()
                    return target.AssemblyVelocity or target.Velocity or Vector3.new(0, 0, 0)
                end)
                
                if success and velocity then
                    finalPosition = finalPosition + (velocity * Config.Aimbot.PredictionAmount)
                end
            end
            
            local screenPos = Camera:WorldToViewportPoint(finalPosition)
            local targetVec = Vector2.new(screenPos.X, screenPos.Y)
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            
            local smoothFactor = 1 - math.clamp(Config.Aimbot.Smoothness, 0.01, 1)
            local delta = (targetVec - screenCenter) * smoothFactor
            
            mousemoverel(delta.X, delta.Y)
        end
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ESP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ESPObjects = {}

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            pcall(function() obj:Remove() end)
        end
        ESPObjects[player] = nil
    end
    
    if SkeletonCache[player] then
        SkeletonCache[player] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if not Config.ESP.Enabled or PanicMode or Config.Misc.StreamProof then
        for _, objs in pairs(ESPObjects) do
            for _, obj in pairs(objs) do
                if obj then obj.Visible = false end
            end
        end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        if not ESPObjects[player] then 
            ESPObjects[player] = {} 
        end
        
        if not SkeletonCache[player] then
            SkeletonCache[player] = {}
        end
        
        local esp = ESPObjects[player]
        local skeletonCache = SkeletonCache[player]

        local char = player.Character
        
        if not char or not isAlive(char) then
            for _, obj in pairs(esp) do
                if obj then obj.Visible = false end
            end
            for _, line in pairs(skeletonCache) do
                if line then line.Visible = false end
            end
            continue
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        
        if not hrp or not head then
            for _, obj in pairs(esp) do
                if obj then obj.Visible = false end
            end
            for _, line in pairs(skeletonCache) do
                if line then line.Visible = false end
            end
            continue
        end

        local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
        if dist > Config.ESP.MaxDistance then
            for _, obj in pairs(esp) do
                if obj then obj.Visible = false end
            end
            for _, line in pairs(skeletonCache) do
                if line then line.Visible = false end
            end
            continue
        end

        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            for _, obj in pairs(esp) do
                if obj then obj.Visible = false end
            end
            for _, line in pairs(skeletonCache) do
                if line then line.Visible = false end
            end
            continue
        end

        local topPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local bottomPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local height = math.abs(bottomPos.Y - topPos.Y)
        local width = height * 0.5

        if Config.ESP.Box then
            if not esp.Box then
                esp.Box = Drawing.new("Square")
                esp.Box.Thickness = 2
                esp.Box.Filled = false
            end
            esp.Box.Visible = true
            esp.Box.Size = Vector2.new(width, height)
            esp.Box.Position = Vector2.new(pos.X - width/2, topPos.Y)
            esp.Box.Color = getColor("ESPBox")
        elseif esp.Box then
            esp.Box.Visible = false
        end

        -- HEALTH BAR
        if Config.ESP.HealthBar and humanoid then
            if not esp.HealthBarBG then
                esp.HealthBarBG = Drawing.new("Square")
                esp.HealthBarBG.Thickness = 1
                esp.HealthBarBG.Filled = true
                esp.HealthBarBG.Color = Color3.fromRGB(20, 20, 20)
            end
            
            if not esp.HealthBarFill then
                esp.HealthBarFill = Drawing.new("Square")
                esp.HealthBarFill.Thickness = 0
                esp.HealthBarFill.Filled = true
            end
            
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            local barHeight = height * healthPercent
            
            -- Background
            esp.HealthBarBG.Visible = true
            esp.HealthBarBG.Size = Vector2.new(4, height)
            esp.HealthBarBG.Position = Vector2.new(pos.X - width/2 - 8, topPos.Y)
            
            -- Fill
            esp.HealthBarFill.Visible = true
            esp.HealthBarFill.Size = Vector2.new(4, barHeight)
            esp.HealthBarFill.Position = Vector2.new(pos.X - width/2 - 8, topPos.Y + (height - barHeight))
            
            -- Gradient color
            if Config.ESP.GradientHealth then
                esp.HealthBarFill.Color = Color3.new(1 - healthPercent, healthPercent, 0)
            else
                esp.HealthBarFill.Color = getColor("ESPHealth")
            end
        elseif esp.HealthBarBG then
            esp.HealthBarBG.Visible = false
            esp.HealthBarFill.Visible = false
        end

        if Config.ESP.Name then
            if not esp.Name then
                esp.Name = Drawing.new("Text")
                esp.Name.Center = true
                esp.Name.Outline = true
                esp.Name.Size = 15
                esp.Name.Font = 2
            end
            esp.Name.Visible = true
            esp.Name.Text = player.Name
            esp.Name.Position = Vector2.new(pos.X, topPos.Y - 18)
            esp.Name.Color = getColor("ESPName")
        elseif esp.Name then
            esp.Name.Visible = false
        end

        if Config.ESP.Health and humanoid then
            if not esp.Health then
                esp.Health = Drawing.new("Text")
                esp.Health.Center = true
                esp.Health.Outline = true
                esp.Health.Size = 14
                esp.Health.Font = 2
            end
            esp.Health.Visible = true
            esp.Health.Text = "HP: " .. math.floor(humanoid.Health)
            
            if Config.ESP.GradientHealth then
                local healthPercent = humanoid.Health / humanoid.MaxHealth
                esp.Health.Color = Color3.new(1 - healthPercent, healthPercent, 0)
            else
                esp.Health.Color = getColor("ESPHealth")
            end
            
            esp.Health.Position = Vector2.new(pos.X, bottomPos.Y + 5)
        elseif esp.Health then
            esp.Health.Visible = false
        end

        if Config.ESP.Distance then
            if not esp.Distance then
                esp.Distance = Drawing.new("Text")
                esp.Distance.Center = true
                esp.Distance.Outline = true
                esp.Distance.Size = 13
                esp.Distance.Font = 2
            end
            esp.Distance.Visible = true
            esp.Distance.Text = math.floor(dist) .. "m"
            esp.Distance.Position = Vector2.new(pos.X, bottomPos.Y + 22)
            esp.Distance.Color = getColor("ESPDistance")
        elseif esp.Distance then
            esp.Distance.Visible = false
        end
        
        if Config.ESP.Skeleton then
            local bones = {
                {"Head", "UpperTorso"},
                {"UpperTorso", "LowerTorso"},
                {"UpperTorso", "RightUpperArm"},
                {"RightUpperArm", "RightLowerArm"},
                {"RightLowerArm", "RightHand"},
                {"UpperTorso", "LeftUpperArm"},
                {"LeftUpperArm", "LeftLowerArm"},
                {"LeftLowerArm", "LeftHand"},
                {"LowerTorso", "RightUpperLeg"},
                {"RightUpperLeg", "RightLowerLeg"},
                {"RightLowerLeg", "RightFoot"},
                {"LowerTorso", "LeftUpperLeg"},
                {"LeftUpperLeg", "LeftLowerLeg"},
                {"LeftLowerLeg", "LeftFoot"}
            }
            
            for i, bone in pairs(bones) do
                local part1 = char:FindFirstChild(bone[1])
                local part2 = char:FindFirstChild(bone[2])
                if part1 and part2 then
                    local pos1, visible1 = Camera:WorldToViewportPoint(part1.Position)
                    local pos2, visible2 = Camera:WorldToViewportPoint(part2.Position)
                    if visible1 and visible2 then
                        if not skeletonCache[i] then
                            skeletonCache[i] = Drawing.new("Line")
                            skeletonCache[i].Thickness = 1
                        end
                        skeletonCache[i].Visible = true
                        skeletonCache[i].From = Vector2.new(pos1.X, pos1.Y)
                        skeletonCache[i].To = Vector2.new(pos2.X, pos2.Y)
                        skeletonCache[i].Color = getColor("Skeleton")
                    elseif skeletonCache[i] then
                        skeletonCache[i].Visible = false
                    end
                end
            end
        else
            for _, line in pairs(skeletonCache) do
                if line then line.Visible = false end
            end
        end
        
        if Config.ESP.WeaponInfo then
            local weapon = char:FindFirstChildOfClass("Tool")
            if weapon then
                if not esp.Weapon then
                    esp.Weapon = Drawing.new("Text")
                    esp.Weapon.Center = true
                    esp.Weapon.Outline = true
                    esp.Weapon.Size = 12
                    esp.Weapon.Font = 2
                end
                esp.Weapon.Visible = true
                esp.Weapon.Text = weapon.Name
                esp.Weapon.Position = Vector2.new(pos.X, topPos.Y - 35)
                esp.Weapon.Color = getColor("ESPName")
            elseif esp.Weapon then
                esp.Weapon.Visible = false
            end
        end
    end

    for player, objs in pairs(ESPObjects) do
        if not Players:FindFirstChild(player.Name) then
            for _, obj in pairs(objs) do
                pcall(function() obj:Remove() end)
            end
            ESPObjects[player] = nil
            
            if SkeletonCache[player] then
                for _, line in pairs(SkeletonCache[player]) do
                    if line then pcall(function() line:Remove() end) end
                end
                SkeletonCache[player] = nil
            end
        end
    end
end)

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✨ sosiskahook - Premium Edition")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
if fileFunctionsAvailable then
    print("📁 Конфиг:", CONFIG_FILE)
else
    print("❌ Файловая система недоступна")
end
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("⌨️ Insert - меню")
print("🚨 Delete - PANIC KEY (все выкл)")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🎯 Аимбот: Mouse & Camera")
print("👁️ ESP: Box, Name, HP, HP Bar, Distance")
print("✨ Chams: Подсветка игроков")
print("🦴 Skeleton ESP, Weapon Info")
print("💀 Killshot System")
print("📺 Stream Proof Mode")
print("🎨 Watermark справа сверху")
print("💾 Автосохранение настроек")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")