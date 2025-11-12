-- 🔥 EVENT ANALYZER - UNIVERSAL EDITION
-- Версия: RemoteFunction / RemoteEvent / Все + Auto / Manual

local MAX_CALLS = 500
local currentEventIndex = 1
local allEvents = {}
local isAnalyzing = false
local isAutoScanning = false

-- 🚫 ФИЛЬТР ОПАСНЫХ СОБЫТИЙ (по ключевым словам)
local BLACKLISTED_KEYWORDS = {
    "kick", "ban", "anticheat", "security", "admin", "moderator",
    "shutdown", "delete", "reset", "clear", "destroy", "remove",
    "teleport", "crash", "exploit", "bypass", "hack", "cheat",
    -- Добавляй свои опасные ключевые слова сюда:
    "dangerous",
}

-- ✅ БЕЛЫЙ СПИСОК (если нужен)
local WHITELISTED_KEYWORDS = {
    -- "safe", "test", "debug",
}

local httpRequest = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)

local CONFIG = {
    WEBHOOK_URL = "https://discord.com/api/webhooks/1336904092597096540/Yz-oWlekMaIKuKDU-aP_YOKwq3CcrG8Wtj92mdaw1VAfQzqXhagThbF3MIMbtAKwoy-2",
    RATE_LIMIT_DELAY = 0.5,
    SAVE_TO_FILE = true,
    SEND_TO_DISCORD = true,
    PRINT_TO_CONSOLE = true,
    SHOW_GUI = true,
    TIMEOUT_SECONDS = 3,
    SKIP_BLACKLISTED = true,
    USE_WHITELIST = false,
    SEND_ALL_AT_END = true, -- Отправлять все ответы одним файлом в конце
}

-- 🎛️ РЕЖИМЫ РАБОТЫ
local MODES = {
    EVENT_TYPE = "ALL", -- "RF", "RE", "ALL"
    SCAN_MODE = "MANUAL", -- "AUTO", "MANUAL"
}

-- 📝 Логирование в файл
local logFile = "event_analyzer_log.txt"
local responseLogFile = "event_responses.json"
local allResponsesData = {} -- Храним все ответы для отправки в конце

local function logToFile(text)
    if not appendfile then return end
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    appendfile(logFile, "[" .. timestamp .. "] " .. text .. "\n")
end

local function saveResponseToFile(eventName, eventType, args, response, executionTime)
    local HttpService = game:GetService("HttpService")
    
    local serializedArgs = {}
    if type(args) == "table" then
        for i, arg in ipairs(args) do
            if typeof(arg) == "Instance" then
                serializedArgs[i] = "[Instance] " .. (arg.Name or "Unknown")
            elseif type(arg) == "table" then
                local success, result = pcall(function()
                    return HttpService:JSONEncode(arg)
                end)
                if success then
                    serializedArgs[i] = result
                else
                    serializedArgs[i] = tostring(arg)
                end
            else
                serializedArgs[i] = tostring(arg)
            end
        end
    else
        serializedArgs = {tostring(args)}
    end

    local serializedResponse
    if typeof(response) == "Instance" then
        serializedResponse = "[Instance] " .. (response.Name or "Unknown")
    elseif type(response) == "table" then
        local success, result = pcall(function()
            return HttpService:JSONEncode(response)
        end)
        if success then
            serializedResponse = result
        else
            serializedResponse = tostring(response)
        end
    else
        serializedResponse = tostring(response)
    end

    local responseData = {
        event = eventName,
        type = eventType,
        timestamp = os.time(),
        args = serializedArgs,
        response = serializedResponse,
        execution_time = executionTime,
        readable_time = os.date("%Y-%m-%d %H:%M:%S")
    }

    -- Сохраняем для отправки в конце
    if CONFIG.SEND_ALL_AT_END then
        table.insert(allResponsesData, responseData)
    end

    -- Сохраняем в JSON файл
    if writefile and CONFIG.SAVE_TO_FILE then
        local currentData = {}
        pcall(function()
            local fileContent = readfile(responseLogFile)
            if fileContent and fileContent ~= "" then
                currentData = HttpService:JSONDecode(fileContent)
            end
        end)
        table.insert(currentData, responseData)
        pcall(function()
            writefile(responseLogFile, HttpService:JSONEncode(currentData))
        end)
    end
end

local function sendAllResponsesToDiscord()
    if not httpRequest or not CONFIG.WEBHOOK_URL or not CONFIG.SEND_TO_DISCORD or not CONFIG.SEND_ALL_AT_END then return end
    if #allResponsesData == 0 then 
        print("No responses to send")
        return 
    end
    
    print("Sending " .. #allResponsesData .. " responses to Discord")
    
    pcall(function()
        local HttpService = game:GetService("HttpService")
        
        -- Создаем содержимое файла со всеми ответами
        local responseContent = ""
        responseContent = responseContent .. "EVENT ANALYZER - COMPLETE REPORT\n"
        responseContent = responseContent .. string.rep("=", 40) .. "\n"
        responseContent = responseContent .. "Total Events Analyzed: " .. #allResponsesData .. "\n"
        responseContent = responseContent .. "Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
        responseContent = responseContent .. string.rep("=", 40) .. "\n\n"
        
        for i, data in ipairs(allResponsesData) do
            responseContent = responseContent .. "Event " .. i .. "/" .. #allResponsesData .. "\n"
            responseContent = responseContent .. string.rep("-", 20) .. "\n"
            responseContent = responseContent .. "Event: " .. data.event .. "\n"
            responseContent = responseContent .. "Type: " .. data.type .. "\n"
            responseContent = responseContent .. "Execution Time: " .. string.format("%.3fs", data.execution_time) .. "\n"
            responseContent = responseContent .. "Timestamp: " .. data.readable_time .. "\n\n"
            
            responseContent = responseContent .. "Arguments:\n"
            if type(data.args) == "table" then
                for j, arg in ipairs(data.args) do
                    local argStr = tostring(arg)
                    if #argStr > 500 then
                        argStr = argStr:sub(1, 500) .. "..."
                    end
                    responseContent = responseContent .. string.format("  [%d] %s\n", j, argStr)
                end
            else
                responseContent = responseContent .. "  " .. tostring(data.args) .. "\n"
            end
            
            responseContent = responseContent .. "\nResponse:\n"
            local responseStr = tostring(data.response)
            if #responseStr > 1000 then
                responseStr = responseStr:sub(1, 1000) .. "..."
            end
            responseContent = responseContent .. "  " .. responseStr .. "\n\n"
            
            responseContent = responseContent .. string.rep("-", 50) .. "\n\n"
        end
        
        -- Создаем имя файла
        local fileName = "event_report_" .. os.time() .. ".txt"
        
        -- Отправляем через вебхук как файл
        local boundary = "----WebKitFormBoundary" .. tick()
        
        local body = "--" .. boundary .. "\r\n"
        body = body .. "Content-Disposition: form-data; name=\"file\"; filename=\"" .. fileName .. "\"\r\n"
        body = body .. "Content-Type: text/plain\r\n\r\n"
        body = body .. responseContent .. "\r\n"
        body = body .. "--" .. boundary .. "--\r\n"
        
        local success, result = pcall(function()
            return httpRequest({
                Url = CONFIG.WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "multipart/form-data; boundary=" .. boundary
                },
                Body = body
            })
        end)
        
        if success then
            print("Successfully sent report to Discord")
        else
            print("Failed to send report: " .. tostring(result))
        end
        
        -- Очищаем данные после отправки
        allResponsesData = {}
    end)
end

local function sendResponseToDiscord(eventName, eventType, args, response, executionTime)
    if not httpRequest or not CONFIG.WEBHOOK_URL or not CONFIG.SEND_TO_DISCORD then return end
    if CONFIG.SEND_ALL_AT_END then return end -- Если отправка в конце, не отправляем по одному
    
    pcall(function()
        local HttpService = game:GetService("HttpService")
        
        -- Создаем содержимое файла
        local responseContent = ""
        responseContent = responseContent .. "Event Analyzer Response\n"
        responseContent = responseContent .. string.rep("=", 21) .. "\n\n"
        responseContent = responseContent .. "Event: " .. eventName .. "\n"
        responseContent = responseContent .. "Type: " .. eventType .. "\n"
        responseContent = responseContent .. "Execution Time: " .. string.format("%.3fs", executionTime) .. "\n"
        responseContent = responseContent .. "Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n"
        
        responseContent = responseContent .. "Arguments:\n"
        if type(args) == "table" then
            for i, arg in ipairs(args) do
                if typeof(arg) == "Instance" then
                    responseContent = responseContent .. string.format("  [%d] Instance: %s\n", i, arg.Name or "Unknown")
                else
                    local argStr = tostring(arg)
                    if #argStr > 200 then
                        argStr = argStr:sub(1, 200) .. "..."
                    end
                    responseContent = responseContent .. string.format("  [%d] %s\n", i, argStr)
                end
            end
        else
            responseContent = responseContent .. "  " .. tostring(args) .. "\n"
        end
        
        responseContent = responseContent .. "\nResponse:\n"
        if typeof(response) == "Instance" then
            responseContent = responseContent .. "  [Instance] " .. (response.Name or "Unknown") .. "\n"
        elseif type(response) == "table" then
            local success, result = pcall(function()
                return HttpService:JSONEncode(response)
            end)
            if success then
                local resultStr = result
                if #resultStr > 500 then
                    resultStr = resultStr:sub(1, 500) .. "..."
                end
                responseContent = responseContent .. "  JSON: " .. resultStr .. "\n"
            else
                responseContent = responseContent .. "  Table: " .. tostring(response) .. "\n"
            end
        else
            local responseStr = tostring(response)
            if #responseStr > 500 then
                responseStr = responseStr:sub(1, 500) .. "..."
            end
            responseContent = responseContent .. "  " .. responseStr .. "\n"
        end
        
        -- Создаем имя файла
        local fileName = "response_" .. os.time() .. "_" .. math.random(1000, 9999) .. ".txt"
        
        -- Отправляем через вебхук как файл
        local boundary = "----WebKitFormBoundary" .. tick()
        
        local body = "--" .. boundary .. "\r\n"
        body = body .. "Content-Disposition: form-data; name=\"file\"; filename=\"" .. fileName .. "\"\r\n"
        body = body .. "Content-Type: text/plain\r\n\r\n"
        body = body .. responseContent .. "\r\n"
        body = body .. "--" .. boundary .. "--\r\n"
        
        httpRequest({
            Url = CONFIG.WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "multipart/form-data; boundary=" .. boundary
            },
            Body = body
        })
    end)
end

local function printResponseToConsole(eventName, eventType, args, response, executionTime)
    if not CONFIG.PRINT_TO_CONSOLE then return end
    
    print("\n" .. string.rep("=", 50))
    print("🔍 " .. eventType .. " RESPONSE ANALYSIS")
    print(string.rep("=", 50))
    print("🎯 Event:", eventName)
    print("⏱️ Execution Time:", string.format("%.3fs", executionTime))
    
    print("\n📥 Arguments:")
    if type(args) == "table" then
        for i, arg in ipairs(args) do
            if typeof(arg) == "Instance" then
                print(string.format("  [%d] Instance: %s", i, arg.Name or "Unknown"))
            else
                print(string.format("  [%d] %s", i, tostring(arg)))
            end
        end
    else
        print("  ", tostring(args))
    end
    
    print("\n📤 Response:")
    if typeof(response) == "Instance" then
        print("  [Instance]", response.Name or "Unknown")
    elseif type(response) == "table" then
        local success, result = pcall(function()
            return game:GetService("HttpService"):JSONEncode(response)
        end)
        if success then
            print("  JSON:", result)
        else
            print("  Table:", tostring(response))
        end
    else
        print("  ", tostring(response))
    end
    print(string.rep("=", 50))
end

-- 🔍 ФИЛЬТРЫ ПО КЛЮЧЕВЫМ СЛОВАМ
local function isEventBlacklisted(eventName)
    if not CONFIG.SKIP_BLACKLISTED then return false end
    
    local nameLower = eventName:lower()
    for _, keyword in ipairs(BLACKLISTED_KEYWORDS) do
        if nameLower:find(keyword:lower()) then
            return true
        end
    end
    return false
end

local function isEventWhitelisted(eventName)
    if not CONFIG.USE_WHITELIST or #WHITELISTED_KEYWORDS == 0 then return true end
    
    local nameLower = eventName:lower()
    for _, keyword in ipairs(WHITELISTED_KEYWORDS) do
        if nameLower:find(keyword:lower()) then
            return true
        end
    end
    return false
end

-- 🎨 GUI СОЗДАНИЕ
local ScreenGui, MainFrame, LogFrame, LogList, StatsText, CurrentEventText
local EventTypeButtons = {}
local ScanModeButtons = {}

if CONFIG.SHOW_GUI then
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "EventAnalyzer"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 550, 0, 550)
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -275)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MainFrame

    -- Заголовок
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "🔍 EVENT ANALYZER"
    TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 25, 0, 25)
    CloseButton.Position = UDim2.new(1, -30, 0, 5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    CloseButton.Text = "✕"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 14
    CloseButton.Parent = TitleBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseButton

    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- Переключатели типов событий
    local EventTypeFrame = Instance.new("Frame")
    EventTypeFrame.Size = UDim2.new(1, -20, 0, 60)
    EventTypeFrame.Position = UDim2.new(0, 10, 0, 45)
    EventTypeFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    EventTypeFrame.BorderSizePixel = 0
    EventTypeFrame.Parent = MainFrame

    local EventTypeCorner = Instance.new("UICorner")
    EventTypeCorner.CornerRadius = UDim.new(0, 8)
    EventTypeCorner.Parent = EventTypeFrame

    local EventTypeLabel = Instance.new("TextLabel")
    EventTypeLabel.Size = UDim2.new(1, -10, 0, 20)
    EventTypeLabel.Position = UDim2.new(0, 5, 0, 5)
    EventTypeLabel.BackgroundTransparency = 1
    EventTypeLabel.Text = "🎯 Event Type:"
    EventTypeLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
    EventTypeLabel.Font = Enum.Font.GothamBold
    EventTypeLabel.TextSize = 14
    EventTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
    EventTypeLabel.Parent = EventTypeFrame

    local function createEventTypeButton(text, mode, position)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.3, -5, 0, 25)
        btn.Position = position
        btn.BackgroundColor3 = MODES.EVENT_TYPE == mode and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(60, 60, 80)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.Parent = EventTypeFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            MODES.EVENT_TYPE = mode
            for _, b in pairs(EventTypeButtons) do
                b.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            end
            btn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            if #allEvents > 0 then
                startScan() -- Пересканируем с новым режимом
            end
        end)
        
        EventTypeButtons[mode] = btn
        return btn
    end

    createEventTypeButton("RemoteFunction", "RF", UDim2.new(0, 5, 0, 30))
    createEventTypeButton("RemoteEvent", "RE", UDim2.new(0.333, 5, 0, 30))
    createEventTypeButton("All Events", "ALL", UDim2.new(0.666, 5, 0, 30))

    -- Переключатели режимов сканирования
    local ScanModeFrame = Instance.new("Frame")
    ScanModeFrame.Size = UDim2.new(1, -20, 0, 60)
    ScanModeFrame.Position = UDim2.new(0, 10, 0, 115)
    ScanModeFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    ScanModeFrame.BorderSizePixel = 0
    ScanModeFrame.Parent = MainFrame

    local ScanModeCorner = Instance.new("UICorner")
    ScanModeCorner.CornerRadius = UDim.new(0, 8)
    ScanModeCorner.Parent = ScanModeFrame

    local ScanModeLabel = Instance.new("TextLabel")
    ScanModeLabel.Size = UDim2.new(1, -10, 0, 20)
    ScanModeLabel.Position = UDim2.new(0, 5, 0, 5)
    ScanModeLabel.BackgroundTransparency = 1
    ScanModeLabel.Text = "🔄 Scan Mode:"
    ScanModeLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
    ScanModeLabel.Font = Enum.Font.GothamBold
    ScanModeLabel.TextSize = 14
    ScanModeLabel.TextXAlignment = Enum.TextXAlignment.Left
    ScanModeLabel.Parent = ScanModeFrame

    local function createScanModeButton(text, mode, position)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.45, -5, 0, 25)
        btn.Position = position
        btn.BackgroundColor3 = MODES.SCAN_MODE == mode and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(60, 60, 80)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.Parent = ScanModeFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            MODES.SCAN_MODE = mode
            for _, b in pairs(ScanModeButtons) do
                b.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            end
            btn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        end)
        
        ScanModeButtons[mode] = btn
        return btn
    end

    createScanModeButton("Manual Scan", "MANUAL", UDim2.new(0, 5, 0, 30))
    createScanModeButton("Auto Scan", "AUTO", UDim2.new(0.55, 5, 0, 30))

    -- Информация о текущем событии
    local CurrentEventFrame = Instance.new("Frame")
    CurrentEventFrame.Size = UDim2.new(1, -20, 0, 60)
    CurrentEventFrame.Position = UDim2.new(0, 10, 0, 185)
    CurrentEventFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    CurrentEventFrame.BorderSizePixel = 0
    CurrentEventFrame.Parent = MainFrame

    local CurrentEventCorner = Instance.new("UICorner")
    CurrentEventCorner.CornerRadius = UDim.new(0, 8)
    CurrentEventCorner.Parent = CurrentEventFrame

    CurrentEventText = Instance.new("TextLabel")
    CurrentEventText.Size = UDim2.new(1, -20, 1, -20)
    CurrentEventText.Position = UDim2.new(0, 10, 0, 10)
    CurrentEventText.BackgroundTransparency = 1
    CurrentEventText.Text = "Ожидание начала анализа..."
    CurrentEventText.TextColor3 = Color3.fromRGB(200, 255, 200)
    CurrentEventText.Font = Enum.Font.Code
    CurrentEventText.TextSize = 12
    CurrentEventText.TextXAlignment = Enum.TextXAlignment.Left
    CurrentEventText.TextYAlignment = Enum.TextYAlignment.Top
    CurrentEventText.Parent = CurrentEventFrame

    -- Статистика
    local StatsFrame = Instance.new("Frame")
    StatsFrame.Size = UDim2.new(1, -20, 0, 100)
    StatsFrame.Position = UDim2.new(0, 10, 0, 255)
    StatsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    StatsFrame.BorderSizePixel = 0
    StatsFrame.Parent = MainFrame

    local StatsCorner = Instance.new("UICorner")
    StatsCorner.CornerRadius = UDim.new(0, 8)
    StatsCorner.Parent = StatsFrame

    StatsText = Instance.new("TextLabel")
    StatsText.Size = UDim2.new(1, -20, 1, -20)
    StatsText.Position = UDim2.new(0, 10, 0, 10)
    StatsText.BackgroundTransparency = 1
    StatsText.Text = "Starting analysis..."
    StatsText.TextColor3 = Color3.fromRGB(200, 200, 255)
    StatsText.Font = Enum.Font.Code
    StatsText.TextSize = 12
    StatsText.TextXAlignment = Enum.TextXAlignment.Left
    StatsText.TextYAlignment = Enum.TextYAlignment.Top
    StatsText.Parent = StatsFrame

    -- Лог (ScrollingFrame)
    LogFrame = Instance.new("ScrollingFrame")
    LogFrame.Size = UDim2.new(1, -20, 0, 160)
    LogFrame.Position = UDim2.new(0, 10, 0, 365)
    LogFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    LogFrame.BorderSizePixel = 0
    LogFrame.ScrollBarThickness = 6
    LogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogFrame.Parent = MainFrame

    local LogCorner = Instance.new("UICorner")
    LogCorner.CornerRadius = UDim.new(0, 8)
    LogCorner.Parent = LogFrame

    LogList = Instance.new("UIListLayout")
    LogList.Padding = UDim.new(0, 2)
    LogList.Parent = LogFrame

    -- Кнопки действий
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Size = UDim2.new(1, -20, 0, 35)
    ButtonFrame.Position = UDim2.new(0, 10, 0, 535)
    ButtonFrame.BackgroundTransparency = 1
    ButtonFrame.Parent = MainFrame

    local function createButton(text, position, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.3, 0, 1, 0)
        btn.Position = position
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.Parent = ButtonFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local StartButton = createButton("▶️ Start", UDim2.new(0, 0, 0, 0), Color3.fromRGB(50, 150, 50), function() end)
    local NextButton = createButton("⏭️ Next", UDim2.new(0.35, 0, 0, 0), Color3.fromRGB(50, 120, 200), function() end)
    local StopButton = createButton("⏹️ Stop", UDim2.new(0.7, 0, 0, 0), Color3.fromRGB(200, 50, 50), function() end)

    -- Draggable
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    ScreenGui.Parent = game:GetService("CoreGui")
end

-- 📊 ДАННЫЕ
local results = {
    total = 0,
    completed = 0,
    errors = 0,
    timeouts = 0,
    responses = {},
    suspicious = {},
    blacklisted = 0,
    rf_count = 0,
    re_count = 0,
    processed = 0, -- Добавлен счетчик обработанных событий
}

-- 📁 ПОДОЗРИТЕЛЬНЫЕ СОБЫТИЯ
local SUSPICIOUS_PATTERNS = {
    "give", "add", "set", "money", "cash", "coin", "item", "weapon", 
    "admin", "moderator", "kick", "ban", "anticheat", "cheat", 
    "exploit", "bypass", "unlock", "free", "unlimited"
}

local function isSuspicious(name)
    local nameLower = name:lower()
    for _, pattern in ipairs(SUSPICIOUS_PATTERNS) do
        if nameLower:find(pattern) then
            return true
        end
    end
    return false
end

-- 📝 Лог в GUI
local function addLog(text, color)
    if not CONFIG.SHOW_GUI or not LogFrame then return end
    
    local log = Instance.new("TextLabel")
    log.Size = UDim2.new(1, -10, 0, 14)
    log.BackgroundTransparency = 1
    log.Text = text
    log.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    log.Font = Enum.Font.Code
    log.TextSize = 10
    log.TextXAlignment = Enum.TextXAlignment.Left
    log.Parent = LogFrame
    
    LogFrame.CanvasSize = UDim2.new(0, 0, 0, LogList.AbsoluteContentSize.Y)
    LogFrame.CanvasPosition = Vector2.new(0, LogList.AbsoluteContentSize.Y)
    
    if #LogFrame:GetChildren() > 50 then
        LogFrame:GetChildren()[1]:Destroy()
    end
end

-- 🔄 Обновление GUI с защитой от ошибок
local function updateGUI()
    pcall(function()
        if not CONFIG.SHOW_GUI then return end
        
        if StatsText then
            StatsText.Text = string.format(
                "📊 Stats:\n" ..
                "  Total: %d | Processed: %d | Analyzed: %d\n" ..  -- Исправлен порядок
                "  RF: %d | RE: %d | Errors: %d\n" ..
                "  Timeouts: %d | Suspicious: %d | Blacklisted: %d\n" ..
                "  Current: %d/%d | Mode: %s",
                results.total, results.processed, results.completed,
                results.rf_count, results.re_count, results.errors,
                results.timeouts, #results.suspicious, results.blacklisted,
                math.min(currentEventIndex, #allEvents), #allEvents, MODES.SCAN_MODE
            )
        end
        
        if CurrentEventText and currentEventIndex <= #allEvents and allEvents[currentEventIndex] then
            local event = allEvents[currentEventIndex]
            if event and event.name then
                CurrentEventText.Text = string.format(
                    "Current [%d/%d]:\n%s (%s)",
                    currentEventIndex, #allEvents,
                    event.name:match("[^%.]+$") or event.name,
                    event.type or "Unknown"
                )
            else
                CurrentEventText.Text = "Invalid event data"
            end
        elseif CurrentEventText then
            CurrentEventText.Text = "No more events"
        end
    end)
end

-- 🎯 Анализ RemoteFunction с улучшенной обработкой ошибок
local function analyzeRemoteFunction(event)
    if not event or not event.instance or isAnalyzing then return end
    
    isAnalyzing = true
    local inst = event.instance
    local name = event.name or "Unknown"
    
    -- Проверяем, что инстанс еще существует
    if not inst or not inst.Parent then
        addLog(string.format("🚫 RF skipped (destroyed): %s", name:match("[^%.]+$") or name), Color3.fromRGB(255, 100, 100))
        logToFile(string.format("🚫 RF skipped (destroyed): %s", name))
        isAnalyzing = false
        results.processed = results.processed + 1  -- Увеличиваем счетчик обработанных
        updateGUI()
        return
    end
    
    addLog(string.format("🔍 RF: %s", name:match("[^%.]+$") or name), Color3.fromRGB(100, 255, 100))
    logToFile(string.format("🔍 RF: %s", name))
    
    task.spawn(function()
        local startTime = tick()
        local completed = false
        local response, args
        local executionTime = 0
        
        local testArgs = {
            {}, {""}, {"test"}, {0}, {1}, {true}, {false}, {{}},
        }
        
        local bestResponse, bestArgs, bestTime = nil, {}, math.huge
        local hadSuccess = false
        
        for _, argSet in ipairs(testArgs) do
            if not completed and not isAutoScanning then break end -- Проверка остановки
            
            task.spawn(function()
                local callStartTime = tick()
                local ok, res = pcall(function() return inst:InvokeServer(unpack(argSet)) end)
                local callTime = tick() - callStartTime
                
                if ok and not isAutoScanning then -- Проверка остановки
                    completed = true
                    response = res
                    args = argSet
                    executionTime = callTime
                    hadSuccess = true
                    
                    if callTime < bestTime then
                        bestResponse = res
                        bestArgs = argSet
                        bestTime = callTime
                    end
                end
            end)
            
            task.wait(0.1)
        end
        
        local start = tick()
        while not completed and (tick() - start) < CONFIG.TIMEOUT_SECONDS and not isAutoScanning do
            task.wait(0.05)
        end
        
        if isAutoScanning then
            -- Анализ был остановлен
            isAnalyzing = false
            results.processed = results.processed + 1
            updateGUI()
            return
        end
        
        if not completed then
            results.timeouts = results.timeouts + 1
            results.completed = results.completed + 1
            results.processed = results.processed + 1
            addLog("  ⏳ Timeout", Color3.fromRGB(255, 150, 50))
            logToFile(string.format("⏳ [RF Timeout] %s", name))
        elseif hadSuccess then
            response = bestResponse
            args = bestArgs
            executionTime = bestTime
            
            results.completed = results.completed + 1
            results.processed = results.processed + 1
            
            local responseStr = typeof(response) == "table" and "Table" or tostring(response):sub(1, 50)
            addLog(string.format("  ✅ (%.3fs): %s", executionTime, responseStr), Color3.fromRGB(100, 255, 100))
            logToFile(string.format("✅ [RF Response] %s -> %s (%.3fs)", name, responseStr, executionTime))
            
            saveResponseToFile(name, "RF", args, response, executionTime)
            sendResponseToDiscord(name, "RF", args, response, executionTime)
            printResponseToConsole(name, "RF", args, response, executionTime)
            
            table.insert(results.responses, {
                name = name,
                type = "RF",
                args = args,
                response = response,
                time = executionTime,
                timestamp = tick()
            })
            
            if isSuspicious(name) then
                table.insert(results.suspicious, {
                    name = name,
                    type = "RF",
                    response = response,
                    time = executionTime
                })
                addLog(string.format("  ⚠️ Suspicious RF: %s", name:match("[^%.]+$") or name), Color3.fromRGB(255, 200, 50))
                logToFile(string.format("⚠️ [Suspicious RF] %s", name))
            end
        else
            results.errors = results.errors + 1
            results.completed = results.completed + 1
            results.processed = results.processed + 1
            addLog("  ❌ All attempts failed", Color3.fromRGB(255, 100, 100))
            logToFile(string.format("❌ [RF Failed] %s", name))
        end
        
        isAnalyzing = false
        updateGUI()
        
        -- Автоматический переход в авто режиме
        if MODES.SCAN_MODE == "AUTO" and currentEventIndex < #allEvents and isAutoScanning then
            task.wait(CONFIG.RATE_LIMIT_DELAY)
            if isAutoScanning then
                processNextEvent()
            end
        end
    end)
end

-- 🔥 Анализ RemoteEvent с улучшенной обработкой ошибок
local function analyzeRemoteEvent(event)
    if not event or not event.instance or isAnalyzing then return end
    
    isAnalyzing = true
    local inst = event.instance
    local name = event.name or "Unknown"
    
    -- Проверяем, что инстанс еще существует
    if not inst or not inst.Parent then
        addLog(string.format("🚫 RE skipped (destroyed): %s", name:match("[^%.]+$") or name), Color3.fromRGB(255, 100, 100))
        logToFile(string.format("🚫 RE skipped (destroyed): %s", name))
        isAnalyzing = false
        results.processed = results.processed + 1  -- Увеличиваем счетчик обработанных
        updateGUI()
        return
    end
    
    addLog(string.format("🔥 RE: %s", name:match("[^%.]+$") or name), Color3.fromRGB(255, 150, 100))
    logToFile(string.format("🔥 RE: %s", name))
    
    task.spawn(function()
        local startTime = tick()
        local ok, err = pcall(function() 
            if isAutoScanning and inst and inst.Parent then -- Проверка остановки и существования
                inst:FireServer() 
            end
        end)
        local executionTime = tick() - startTime

        if not isAutoScanning then
            -- Анализ был остановлен
            isAnalyzing = false
            results.processed = results.processed + 1
            updateGUI()
            return
        end

        results.completed = results.completed + 1
        results.processed = results.processed + 1
        updateGUI()

        if not ok then
            results.errors = results.errors + 1
            addLog(string.format("  ❌ Error: %s", tostring(err):sub(1, 30)), Color3.fromRGB(255, 100, 100))
            logToFile(string.format("❌ [RE Error] %s: %s", name, tostring(err)))
        else
            addLog(string.format("  ✅ Sent (%.3fs)", executionTime), Color3.fromRGB(100, 255, 100))
            logToFile(string.format("✅ [RE Sent] %s (%.3fs)", name, executionTime))
            
            saveResponseToFile(name, "RE", {}, "Fired (no response)", executionTime)
            sendResponseToDiscord(name, "RE", {}, "Fired (no response)", executionTime)
            
            if isSuspicious(name) then
                table.insert(results.suspicious, {
                    name = name,
                    type = "RE",
                    time = executionTime
                })
                addLog(string.format("  ⚠️ Suspicious RE: %s", name:match("[^%.]+$") or name), Color3.fromRGB(255, 200, 50))
                logToFile(string.format("⚠️ [Suspicious RE] %s", name))
            end
        end

        isAnalyzing = false
        updateGUI()
        
        if MODES.SCAN_MODE == "AUTO" and currentEventIndex < #allEvents and isAutoScanning then
            task.wait(CONFIG.RATE_LIMIT_DELAY)
            if isAutoScanning then
                processNextEvent()
            end
        end
    end)
end

-- 🎮 Обработка следующего события с улучшенной обработкой ошибок
local function processNextEvent()
    if currentEventIndex > #allEvents or not isAutoScanning then
        if currentEventIndex > #allEvents then
            addLog("🏁 All analyzed!", Color3.fromRGB(100, 255, 100))
            logToFile("🏁 All events analyzed!")
            updateGUI()
        end
        return
    end
    
    -- Защита от выхода за пределы массива
    while currentEventIndex <= #allEvents and isAutoScanning do
        if currentEventIndex > #allEvents then break end
        
        local event = allEvents[currentEventIndex]
        if not event then
            results.processed = results.processed + 1
            currentEventIndex = currentEventIndex + 1
            updateGUI()
            continue
        end
        
        local eventName = event.name and event.name:match("[^%.]+$") or "Unknown"
        
        if isEventBlacklisted(event.name or "") then
            addLog(string.format("🚫 Skipped: %s", eventName), Color3.fromRGB(255, 100, 100))
            logToFile(string.format("🚫 Skipped blacklisted: %s", event.name or "Unknown"))
            results.blacklisted = results.blacklisted + 1
            results.processed = results.processed + 1
            currentEventIndex = currentEventIndex + 1
            updateGUI()
        elseif not isEventWhitelisted(event.name or "") then
            addLog(string.format("📋 Skipped: %s", eventName), Color3.fromRGB(255, 150, 50))
            logToFile(string.format("📋 Skipped non-whitelisted: %s", event.name or "Unknown"))
            results.processed = results.processed + 1
            currentEventIndex = currentEventIndex + 1
            updateGUI()
        else
            if event.type == "RF" then
                analyzeRemoteFunction(event)
            elseif event.type == "RE" then
                analyzeRemoteEvent(event)
            else
                -- Пропускаем неизвестные типы событий
                results.processed = results.processed + 1
                currentEventIndex = currentEventIndex + 1
                updateGUI()
                continue
            end
            -- currentEventIndex будет увеличен в самих функциях анализа
            return
        end
    end
    
    if isAutoScanning and currentEventIndex > #allEvents then
        addLog("🏁 All events processed!", Color3.fromRGB(100, 255, 100))
        logToFile("🏁 All events processed!")
        isAutoScanning = false
        updateGUI()
        
        -- Отправляем все ответы одним файлом в конце
        if CONFIG.SEND_ALL_AT_END and CONFIG.SEND_TO_DISCORD and #allResponsesData > 0 then
            task.spawn(function()
                task.wait(2) -- Небольшая задержка перед отправкой
                sendAllResponsesToDiscord()
                addLog("📤 Complete report sent to Discord", Color3.fromRGB(100, 200, 255))
                logToFile("📤 Complete report sent to Discord")
                updateGUI()
            end)
        end
    end
end

-- ⚡ Автоматический анализ
local function autoAnalyze()
    if isAutoScanning then return end
    
    isAutoScanning = true
    addLog("⚡ Starting auto-analysis...", Color3.fromRGB(255, 200, 50))
    logToFile("⚡ Starting auto-analysis...")
    updateGUI()
    
    while currentEventIndex <= #allEvents and isAutoScanning do
        processNextEvent()
        if MODES.SCAN_MODE == "AUTO" and isAutoScanning then
            task.wait(CONFIG.RATE_LIMIT_DELAY)
        else
            break
        end
    end
    
    if not isAutoScanning then
        addLog("⏹️ Auto-analysis stopped", Color3.fromRGB(255, 150, 50))
        logToFile("⏹️ Auto-analysis stopped")
        updateGUI()
    end
end

-- 🚀 Сканирование событий
local function startScan()
    addLog("🔍 Starting Event Analyzer...", Color3.fromRGB(100, 200, 255))
    logToFile("🔍 Starting Event Analyzer...")
    
    allEvents = {}
    results = {
        total = 0, completed = 0, errors = 0, timeouts = 0,
        responses = {}, suspicious = {}, blacklisted = 0,
        rf_count = 0, re_count = 0, processed = 0  -- Сброс счетчика
    }
    currentEventIndex = 1
    isAutoScanning = false
    isAnalyzing = false
    allResponsesData = {} -- Очищаем данные для нового сканирования
    
    local descendants = game:GetDescendants()
    
    for _, inst in ipairs(descendants) do
        if results.total >= MAX_CALLS then break end
        
        local shouldInclude = false
        local eventType = nil
        
        -- Проверяем существование инстанса
        if not inst or not inst.Parent then continue end
        
        if MODES.EVENT_TYPE == "RF" and inst:IsA("RemoteFunction") then
            shouldInclude = true
            eventType = "RF"
        elseif MODES.EVENT_TYPE == "RE" and inst:IsA("RemoteEvent") then
            shouldInclude = true
            eventType = "RE"
        elseif MODES.EVENT_TYPE == "ALL" and (inst:IsA("RemoteFunction") or inst:IsA("RemoteEvent")) then
            shouldInclude = true
            eventType = inst:IsA("RemoteFunction") and "RF" or "RE"
        end
        
        if shouldInclude then
            results.total = results.total + 1
            if eventType == "RF" then
                results.rf_count = results.rf_count + 1
            else
                results.re_count = results.re_count + 1
            end
            
            local fullName = inst:GetFullName()
            
            table.insert(allEvents, {
                instance = inst,
                name = fullName,
                type = eventType,
                id = results.total
            })
            
            if isSuspicious(fullName) then
                table.insert(results.suspicious, {name = fullName, type = eventType})
            end
        end
    end
    
    addLog(string.format("📊 Found %d events (%d RF, %d RE)", #allEvents, results.rf_count, results.re_count), Color3.fromRGB(100, 255, 100))
    logToFile(string.format("📊 Found %d events (%d RF, %d RE)", #allEvents, results.rf_count, results.re_count))
    updateGUI()
    
    -- Автозапуск если в авто режиме
    if MODES.SCAN_MODE == "AUTO" and #allEvents > 0 then
        task.spawn(autoAnalyze)
    end
end

-- 🛑 Остановка анализа
local function stopAnalysis()
    isAutoScanning = false
    isAnalyzing = false
    addLog("⏹️ Analysis stopped", Color3.fromRGB(255, 150, 50))
    logToFile("⏹️ Analysis stopped")
    updateGUI()
    
    -- Отправляем все накопленные ответы при остановке
    if CONFIG.SEND_ALL_AT_END and CONFIG.SEND_TO_DISCORD and #allResponsesData > 0 then
        task.spawn(function()
            task.wait(1)
            sendAllResponsesToDiscord()
            addLog("📤 Partial report sent to Discord", Color3.fromRGB(100, 200, 255))
            logToFile("📤 Partial report sent to Discord")
            updateGUI()
        end)
    end
end

-- Подключение кнопок
if CONFIG.SHOW_GUI then
    local StartButton, NextButton, StopButton
    
    for _, child in ipairs(MainFrame:GetDescendants()) do
        if child:IsA("TextButton") and child.Text == "▶️ Start" then
            StartButton = child
        elseif child:IsA("TextButton") and child.Text == "⏭️ Next" then
            NextButton = child
        elseif child:IsA("TextButton") and child.Text == "⏹️ Stop" then
            StopButton = child
        end
    end
    
    if StartButton then
        StartButton.MouseButton1Click:Connect(function()
            startScan()
        end)
    end
    
    if NextButton then
        NextButton.MouseButton1Click:Connect(function()
            if #allEvents == 0 then
                addLog("⚠️ Start first", Color3.fromRGB(255, 200, 50))
                updateGUI()
                return
            end
            if MODES.SCAN_MODE == "AUTO" then
                if not isAutoScanning then
                    task.spawn(autoAnalyze)
                end
            else
                processNextEvent()
            end
        end)
    end
    
    if StopButton then
        StopButton.MouseButton1Click:Connect(stopAnalysis)
    end
end

-- Автозапуск если GUI выключен
if not CONFIG.SHOW_GUI then
    task.spawn(function()
        task.wait(1)
        startScan()
        if MODES.SCAN_MODE == "AUTO" then
            autoAnalyze()
        end
    end)
end

-- Инициализация
updateGUI()

print("🔥 Event Analyzer Loaded!")
print("📊 Found writefile:", writefile and "YES" or "NO")
print("📊 Mode: " .. MODES.EVENT_TYPE .. " / " .. MODES.SCAN_MODE)
print("📊 Send all at end: " .. (CONFIG.SEND_ALL_AT_END and "YES" or "NO"))

-- Показываем фильтры
print("\n🚫 Blacklisted Keywords (" .. #BLACKLISTED_KEYWORDS .. "):")
for i, keyword in ipairs(BLACKLISTED_KEYWORDS) do
    print("  " .. i .. ". " .. keyword)
end