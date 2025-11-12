local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================================
-- НАСТРОЙКИ
-- ============================================================================

local WEBHOOK_URL = "https://discord.com/api/webhooks/1336904089069551728/o94YBO0NhnuqoFwBQdBGXc1YfgXq1WgEJVJPv85Wnx86nKbzkjSJ3LwoszAvMa2p5Fm1"

local DEBUG_MODE = true

local REEL_SPEED = 0.01
local ENTER_SPEED = 0.001
local ROD_EQUIP_DELAY = 0.3
local CAST_HOLD_TIME = 0.2
local CAST_ANIMATION_DELAY = 0.8
local ITEM_DETECTION_WAIT = 0.3
local RECAST_DELAY = 0.2
local FORCED_CAST_TIMEOUT = 10

local WATER_HEIGHT_OFFSET = 2
local NOCLIP_UPDATE_SPEED = 0.05

local IGNORED_ITEMS = {
    ["Rod"] = true,
    ["Training Rod"] = true,
    ["Plastic Rod"] = true,
    ["Lucky Rod"] = true,
    ["Kings Rod"] = true,
    ["Flimsy Rod"] = true,
    ["Fast Rod"] = true,
    ["Carbon Rod"] = true,
    ["Long Rod"] = true,
    ["Mythical Rod"] = true,
    ["Midas Rod"] = true,
    ["Trident Rod"] = true,
    ["Reinforced Rod"] = true,
    ["Aurora Rod"] = true,
    ["Destiny Rod"] = true,
    ["GPS"] = true,
    ["Fish Radar"] = true,
    ["Advanced Radar"] = true,
    ["Appraisal"] = true,
    ["Sundial Totem"] = true,
    ["Carbon Fiber Rod"] = true,
}

local cache = {
    character = nil,
    humanoid = nil,
    hrp = nil,
    backpack = nil,
    rod = nil,
    eventsFolder = nil,
    reelEvent = nil,
    sellEvent = nil
}

local stats = {
    catches = 0,
    relics = 0,
    reelAttempts = 0,
    forcedCasts = 0,
    successfulCasts = 0,
    failedCasts = 0,
    itemsDetected = 0,
    itemsIgnored = 0,
    webhooksSent = 0,
    webhooksFailed = 0,
    shakeClicks = 0,
    sessionStart = os.time(),
    lastWebhookReport = os.time()
}

local fishCatchCount = {}

local farmingEnabled = false
local loops = {}
local connections = {}
local isProcessing = false
local isCasting = false
local catchCount = 0
local farmStartPosition = nil
local lastItemAddedTime = 0
local lastCastTime = 0

local originalPosition = nil
local teleportStates = {
    roslit = false,
    sell = false,
    vertigo = false,
    depth = false
}

local LOCATIONS = {
    roslit = Vector3.new(-1463.45, 132.62, 696.33),
    sell = Vector3.new(465.56, 150.63, 228.30),
    vertigo = Vector3.new(-113.71, -512.34, 1184.57),
    depthSea = Vector3.new(958.92, -709.73, 1276.81)
}

local noClipEnabled = false
local noClipStartHeight = nil
local waterPlatform = nil
local bodyPosition = nil
local savedNoClipPosition = nil
local cachedBodyParts = {}

local notificationQueue = {}
local currentNotification = nil

local ScreenGui = nil
local FillUpBar = nil
local FillUpLabel = nil

-- ============================================================================
-- БАЗОВЫЕ ФУНКЦИИ
-- ============================================================================

local function debugLog(category, message)
    if DEBUG_MODE then
        local timestamp = os.date("%H:%M:%S")
        print(string.format("[%s] [%s] %s", timestamp, category, message))
    end
end

local httpRequest = (function()
    local funcs = {
        http and http.request,
        http_request,
        request,
        syn and syn.request,
        fluxus and fluxus.request,
    }
    
    for _, func in ipairs(funcs) do
        if func then 
            debugLog("HTTP", "✅ Found HTTP function")
            return func 
        end
    end
    
    debugLog("HTTP", "❌ HTTP not found")
    return nil
end)()

local webhookEnabled = httpRequest ~= nil

local function copyToClipboard(text)
    local success = false
    
    if setclipboard then
        pcall(function()
            setclipboard(text)
            success = true
        end)
    end
    
    if not success and syn and syn.write_clipboard then
        pcall(function()
            syn.write_clipboard(text)
            success = true
        end)
    end
    
    if not success and Clipboard and Clipboard.set then
        pcall(function()
            Clipboard.set(text)
            success = true
        end)
    end
    
    if success then
        debugLog("Clipboard", "✅ Copied to clipboard")
    end
    
    return success
end

-- ============================================================================
-- WEBHOOK
-- ============================================================================

local lastWebhookTime = 0
local WEBHOOK_COOLDOWN = 0.5

local function sendWebhook(title, description, color, fields)
    if not webhookEnabled then
        debugLog("Webhook", "⚠️ Disabled - " .. title)
        return false
    end
    
    local timeSinceLastWebhook = tick() - lastWebhookTime
    if timeSinceLastWebhook < WEBHOOK_COOLDOWN then
        task.wait(WEBHOOK_COOLDOWN - timeSinceLastWebhook)
    end
    
    local success = pcall(function()
        local embed = {
            title = title,
            description = description,
            color = color or 3447003,
            fields = fields or {},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
        }

        local data = {
            username = "🎣 Auto Farm",
            avatar_url = "https://i.imgur.com/AfFp7pu.png",
            embeds = {embed}
        }

        local jsonData = HttpService:JSONEncode(data)

        httpRequest({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
    end)
    
    lastWebhookTime = tick()
    
    if success then
        stats.webhooksSent = stats.webhooksSent + 1
        debugLog("Webhook", "✅ Sent: " .. title)
    else
        stats.webhooksFailed = stats.webhooksFailed + 1
        debugLog("Webhook", "❌ Failed: " .. title)
    end
    
    return success
end

local RARITY_COLORS = {
    Rare = 3066993,
    Legendary = 15844367,
    Mythical = 10181046,
    Exotic = 15158332,
    Limited = 16711680,
    Relic = 16711680
}

local function sendRareCatch(fishName, rarity)
    return sendWebhook(
        "🎣 RARE CATCH!",
        "**" .. fishName .. "** (" .. rarity .. ")",
        RARITY_COLORS[rarity] or 3447003,
        {
            {name = "Player", value = LocalPlayer.Name, inline = true},
            {name = "Total Catches", value = tostring(stats.catches), inline = true},
            {name = "Time", value = os.date("%H:%M:%S"), inline = true}
        }
    )
end

local function sendStatsReport()
    local sessionTime = os.time() - stats.sessionStart
    local hours = math.floor(sessionTime / 3600)
    local minutes = math.floor((sessionTime % 3600) / 60)

    local fishArray = {}
    local totalFishTypes = 0
    
    for fishName, count in pairs(fishCatchCount) do
        table.insert(fishArray, {name = fishName, count = count})
        totalFishTypes = totalFishTypes + 1
    end
    
    table.sort(fishArray, function(a, b) return a.count > b.count end)
    
    local fishList = ""
    
    if #fishArray > 0 then
        for i = 1, math.min(25, #fishArray) do
            fishList = fishList .. "• **" .. fishArray[i].name .. "** — " .. fishArray[i].count .. " шт.\n"
        end
    else
        fishList = "Пока ничего не поймано"
    end

    return sendWebhook(
        "📊 СТАТИСТИКА ФАРМА",
        "**Performance Report**",
        2196890,
        {
            {name = "🎣 Catches", value = tostring(stats.catches), inline = true},
            {name = "✅ Casts", value = tostring(stats.successfulCasts), inline = true},
            {name = "🔄 Forced", value = tostring(stats.forcedCasts), inline = true},
            {name = "⏱️ Session", value = string.format("%dч %dм", hours, minutes), inline = true},
            {name = "🐟 Types", value = tostring(totalFishTypes), inline = true},
            {name = "🖱️ Shakes", value = tostring(stats.shakeClicks), inline = true},
            {name = "📋 Fish", value = fishList, inline = false}
        }
    )
end

-- ============================================================================
-- CACHE
-- ============================================================================

local function updateCache()
    cache.character = LocalPlayer.Character
    
    if cache.character then
        cache.humanoid = cache.character:FindFirstChild("Humanoid")
        cache.hrp = cache.character:FindFirstChild("HumanoidRootPart")
    end
    
    cache.backpack = LocalPlayer.Backpack
    
    if not cache.eventsFolder and ReplicatedStorage:FindFirstChild("events") then
        cache.eventsFolder = ReplicatedStorage.events
        cache.reelEvent = cache.eventsFolder:FindFirstChild("reelfinished")
        
        for _, event in pairs(cache.eventsFolder:GetChildren()) do
            if event.Name:lower() == "sellall" then
                cache.sellEvent = event
                break
            end
        end
    end
    
    debugLog("Cache", "Updated - Character: " .. (cache.character and "✅" or "❌"))
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    updateCache()
    
    if noClipEnabled then
        noClipEnabled = false
        task.wait(0.5)
    end
    
    cachedBodyParts = {}
end)

-- ============================================================================
-- NOCLIP
-- ============================================================================

local function cacheBodyParts()
    cachedBodyParts = {}
    if not cache.character then return end
    
    for _, part in pairs(cache.character:GetDescendants()) do
        if part:IsA("BasePart") then
            local isLeg = part.Name == "Left Leg" or part.Name == "Right Leg" or 
                         part.Name == "LeftFoot" or part.Name == "RightFoot" or
                         part.Name == "LeftLowerLeg" or part.Name == "RightLowerLeg"
            
            table.insert(cachedBodyParts, {
                part = part,
                isLeg = isLeg
            })
        end
    end
    
    debugLog("NoClip", "Cached " .. #cachedBodyParts .. " body parts")
end

local function enableNoClip()
    if noClipEnabled then return end
    noClipEnabled = true
    
    updateCache()
    cacheBodyParts()
    
    if cache.hrp then
        noClipStartHeight = cache.hrp.Position.Y
        savedNoClipPosition = cache.hrp.Position
        debugLog("NoClip", "✅ Height LOCKED: " .. noClipStartHeight)
    end
    
    if not waterPlatform then
        waterPlatform = Instance.new("Part")
        waterPlatform.Name = "WaterPlatform"
        waterPlatform.Size = Vector3.new(15, 0.5, 15)
        waterPlatform.Anchored = true
        waterPlatform.Transparency = 1
        waterPlatform.CanCollide = true
        waterPlatform.Material = Enum.Material.SmoothPlastic
        waterPlatform.Parent = workspace
        
        if cache.hrp then
            waterPlatform.CFrame = CFrame.new(
                cache.hrp.Position.X, 
                noClipStartHeight - 3.2,
                cache.hrp.Position.Z
            )
        end
    end
    
    if cache.humanoid then
        cache.humanoid.PlatformStand = false
        cache.humanoid.Sit = false
        cache.humanoid.AutoRotate = true
        
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    end
    
    local lastHeightCheck = 0
    connections.noClipHeartbeat = RunService.Heartbeat:Connect(function(deltaTime)
        if not noClipEnabled then return end
        
        updateCache()
        
        if cache.character and cache.hrp and cache.humanoid then
            for _, data in ipairs(cachedBodyParts) do
                if data.part and data.part.Parent then
                    data.part.CanCollide = data.isLeg
                end
            end
            
            lastHeightCheck = lastHeightCheck + deltaTime
            if lastHeightCheck >= NOCLIP_UPDATE_SPEED then
                local currentPos = cache.hrp.Position
                local heightDiff = math.abs(currentPos.Y - noClipStartHeight)
                
                if heightDiff > 0.1 then
                    local _, yaw, _ = cache.hrp.CFrame:ToEulerAnglesXYZ()
                    cache.hrp.CFrame = CFrame.new(
                        currentPos.X,
                        noClipStartHeight,
                        currentPos.Z
                    ) * CFrame.Angles(0, yaw, 0)
                end
                
                if waterPlatform then
                    waterPlatform.CFrame = CFrame.new(
                        cache.hrp.Position.X, 
                        noClipStartHeight - 3.2,
                        cache.hrp.Position.Z
                    )
                end
                
                lastHeightCheck = 0
            end
            
            cache.humanoid.PlatformStand = false
            cache.humanoid.Sit = false
            
            local state = cache.humanoid:GetState()
            
            if state == Enum.HumanoidStateType.Climbing or
               state == Enum.HumanoidStateType.Swimming or
               state == Enum.HumanoidStateType.Freefall then
                cache.humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            end
        end
    end)
    
    debugLog("NoClip", "✅ NoClip ENABLED")
end

local function disableNoClip()
    if not noClipEnabled then return end
    noClipEnabled = false
    
    debugLog("NoClip", "🔄 Disabling NoClip...")
    
    if connections.noClipHeartbeat then
        connections.noClipHeartbeat:Disconnect()
        connections.noClipHeartbeat = nil
    end
    
    task.wait(0.1)
    
    updateCache()
    
    if cache.humanoid then
        cache.humanoid.PlatformStand = false
        cache.humanoid.Sit = false
        cache.humanoid.AutoRotate = true
        
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
        cache.humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        
        cache.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        task.wait(0.1)
        cache.humanoid:ChangeState(Enum.HumanoidStateType.Landed)
    end
    
    if cache.character then
        for _, part in pairs(cache.character:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                else
                    part.CanCollide = false
                end
            end
        end
    end
    
    if waterPlatform then
        waterPlatform:Destroy()
        waterPlatform = nil
    end
    
    noClipStartHeight = nil
    savedNoClipPosition = nil
    cachedBodyParts = {}
    
    debugLog("NoClip", "✅ NoClip fully DISABLED")
end

-- ============================================================================
-- GUI UPDATE FUNCTIONS
-- ============================================================================

local function showNotification(text, duration)
    if not ScreenGui then
        warn("⚠️ Notification: GUI not ready - " .. text)
        return
    end
    
    local notifFrame = ScreenGui:FindFirstChild("NotificationFrame")
    local notifLabel = notifFrame and notifFrame:FindFirstChild("NotificationLabel")
    
    if not notifFrame or not notifLabel then
        warn("⚠️ Notification UI not found!")
        return
    end
    
    table.insert(notificationQueue, {text = text, duration = duration or 3})
    
    if not currentNotification then
        task.spawn(function()
            while #notificationQueue > 0 do
                local notif = table.remove(notificationQueue, 1)
                currentNotification = notif
                
                notifLabel.Text = notif.text
                notifFrame.Visible = true
                
                task.wait(notif.duration)
                
                notifFrame.Visible = false
                currentNotification = nil
                
                task.wait(0.1)
            end
        end)
    end
end

local function updateFarmButton(state)
    if not ScreenGui then 
        warn("⚠️ ScreenGui not found!")
        return false
    end
    
    local mainFrame = ScreenGui:FindFirstChild("MainFrame")
    if not mainFrame then
        warn("⚠️ MainFrame not found!")
        return false
    end
    
    local btn = mainFrame:FindFirstChild("FarmButton")
    if not btn then 
        warn("⚠️ FarmButton not found in MainFrame!")
        return false
    end
    
    if state then
        btn.Text = "Farm: ON"
        btn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        debugLog("GUI", "✅ Button updated: Farm ON")
    else
        btn.Text = "Farm: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        debugLog("GUI", "❌ Button updated: Farm OFF")
    end
    
    return true
end

local function updateNoClipButton(state)
    if not ScreenGui then return false end
    
    local mainFrame = ScreenGui:FindFirstChild("MainFrame")
    if not mainFrame then return false end
    
    local btn = mainFrame:FindFirstChild("NoClipButton")
    if not btn then return false end
    
    if state then
        btn.Text = "NoClip: ON"
        btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    else
        btn.Text = "NoClip: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
    end
    
    return true
end

-- ============================================================================
-- FILL UP MONITOR
-- ============================================================================

local function updateFillUpDisplay(value)
    if not FillUpBar or not FillUpLabel then 
        return 
    end
    
    local percent = math.clamp(value, 0, 100)
    
    FillUpBar.Size = UDim2.new(percent / 100, 0, 1, 0)
    
    if percent < 50 then
        local ratio = percent / 50
        FillUpBar.BackgroundColor3 = Color3.fromRGB(
            math.floor(46 + (255 - 46) * ratio),
            math.floor(204 - (204 - 193) * ratio),
            113
        )
    else
        local ratio = (percent - 50) / 50
        FillUpBar.BackgroundColor3 = Color3.fromRGB(
            255,
            math.floor(193 - 193 * ratio),
            math.floor(113 - 113 * ratio)
        )
    end
    
    FillUpLabel.Text = string.format("Fill Up: %.0f%%", percent)
end

local function findLureValue()
    local playerFolder = workspace:FindFirstChild(LocalPlayer.Name)
    
    if playerFolder then
        for _, item in pairs(playerFolder:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("rod") then
                local values = item:FindFirstChild("values")
                if values then
                    local lure = values:FindFirstChild("lure")
                    if lure and (lure:IsA("NumberValue") or lure:IsA("IntValue")) then
                        return lure
                    end
                end
            end
        end
    end
    
    return nil
end

local function startFillUpMonitor()
    debugLog("FillUp", "🎯 Starting Fill Up monitor...")
    
    if connections.fillUpMonitor then
        connections.fillUpMonitor:Disconnect()
    end
    
    connections.fillUpMonitor = RunService.Heartbeat:Connect(function()
        if not farmingEnabled then return end
        
        local lureValue = findLureValue()
        
        if lureValue then
            updateFillUpDisplay(lureValue.Value)
        else
            updateFillUpDisplay(0)
        end
    end)
    
    debugLog("FillUp", "✅ Fill Up monitor started!")
end

local function stopFillUpMonitor()
    if connections.fillUpMonitor then
        connections.fillUpMonitor:Disconnect()
        connections.fillUpMonitor = nil
    end
    
    updateFillUpDisplay(0)
    debugLog("FillUp", "⏹️ Fill Up monitor stopped")
end

-- ============================================================================
-- AUTO SHAKE (Focus + Enter)
-- ============================================================================

local function findShakeButton()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local shakeui = playerGui:FindFirstChild("shakeui")
    if not shakeui then return nil end
    
    local safezone = shakeui:FindFirstChild("safezone")
    if not safezone then return nil end
    
    local button = safezone:FindFirstChild("button")
    if button and button.Visible then
        return button
    end
    
    return nil
end

local function startAutoShake()
    if connections.autoShake then
        connections.autoShake:Disconnect()
    end
    
    debugLog("AutoShake", "✅ Auto Shake started (Focus + Enter method)!")
    
    connections.autoShake = RunService.Heartbeat:Connect(function()
        if not farmingEnabled then return end
        
        local button = findShakeButton()
        
        if button then
            local clickables = {}
            
            if button:IsA("GuiButton") or button:IsA("TextButton") or button:IsA("ImageButton") then
                table.insert(clickables, button)
            end
            
            for _, obj in pairs(button:GetDescendants()) do
                if obj:IsA("GuiButton") or obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    table.insert(clickables, obj)
                end
            end
            
            for _, obj in ipairs(clickables) do
                pcall(function()
                    GuiService.SelectedObject = obj
                    task.wait(0.005)
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    task.wait(0.003)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                end)
            end
            
            stats.shakeClicks = stats.shakeClicks + 1
            
            if stats.shakeClicks % 200 == 0 then
                debugLog("AutoShake", string.format("🔄 Shaking... (%d clicks)", stats.shakeClicks))
            end
        end
    end)
end

local function stopAutoShake()
    if connections.autoShake then
        connections.autoShake:Disconnect()
        connections.autoShake = nil
    end
    
    debugLog("AutoShake", "⏹️ Auto Shake stopped")
end

-- ============================================================================
-- CORE FISHING FUNCTIONS
-- ============================================================================

local function isRod(itemName)
    return itemName:lower():find("rod") ~= nil
end

local function isIgnoredItem(itemName)
    local ignored = IGNORED_ITEMS[itemName] == true or isRod(itemName)
    
    if ignored then
        stats.itemsIgnored = stats.itemsIgnored + 1
    end
    
    return ignored
end

local function isEnchantRelic(item)
    if not item then return false end
    local name = item.Name
    return name:find("Enchant") or name:find("Relic") or name == "Enchant Relic"
end

local rarityPatterns = {
    {pattern = "mythic", rarity = "Mythical"},
    {pattern = "legend", rarity = "Legendary"},
    {pattern = "exotic", rarity = "Exotic"},
    {pattern = "rare", rarity = "Rare"},
    {pattern = "uncommon", rarity = "Uncommon"},
    {pattern = "limit", rarity = "Limited"}
}

local function getFishRarity(fishItem)
    if not fishItem then return "Common" end
    
    if isEnchantRelic(fishItem) then
        return "Relic"
    end
    
    local rarityAttr = fishItem:FindFirstChild("Rarity")
    if rarityAttr then
        return rarityAttr.Value
    end

    local nameLower = fishItem.Name:lower()
    
    for _, data in ipairs(rarityPatterns) do
        if nameLower:find(data.pattern) then
            return data.rarity
        end
    end
    
    return "Common"
end

local function pressEnter()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
end

local function findRod()
    if cache.rod and cache.rod.Parent then
        return cache.rod
    end
    
    if not cache.backpack then return nil end
    
    for _, item in pairs(cache.backpack:GetChildren()) do
        if item:IsA("Tool") and isRod(item.Name) then
            cache.rod = item
            return item
        end
    end
    
    if cache.character then
        for _, item in pairs(cache.character:GetChildren()) do
            if item:IsA("Tool") and isRod(item.Name) then
                cache.rod = item
                return item
            end
        end
    end
    
    return nil
end

local function doCast()
    debugLog("Cast", "🎣 Attempting cast...")
    
    if isCasting then
        debugLog("Cast", "❌ Already casting, skipping")
        return false
    end
    
    isCasting = true
    
    local rod = findRod()
    if not rod then 
        stats.failedCasts = stats.failedCasts + 1
        isCasting = false
        return false 
    end

    if rod.Parent == cache.backpack and cache.humanoid then
        cache.humanoid:EquipTool(rod)
        task.wait(ROD_EQUIP_DELAY)
    end

    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(CAST_HOLD_TIME)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    
    task.wait(CAST_ANIMATION_DELAY)
    
    lastCastTime = tick()
    stats.successfulCasts = stats.successfulCasts + 1
    
    isCasting = false
    
    return true
end

local function sellAllItems()
    if not cache.backpack then return false end
    
    local itemCount = 0
    
    for _, item in pairs(cache.backpack:GetChildren()) do
        if item:IsA("Tool") and not isRod(item.Name) then
            itemCount = itemCount + 1
        end
    end

    if itemCount > 0 then
        if cache.sellEvent then
            if cache.sellEvent:IsA("RemoteEvent") then
                cache.sellEvent:FireServer()
            elseif cache.sellEvent:IsA("RemoteFunction") then
                cache.sellEvent:InvokeServer()
            end
        end
        
        showNotification("Sold " .. itemCount .. " items!", 2)
        return true
    else
        showNotification("No items to sell", 2)
    end
    
    return false
end

local function checkAndAutoSell()
    if not cache.backpack then return end
    
    local itemCount = 0
    
    for _, item in pairs(cache.backpack:GetChildren()) do
        if item:IsA("Tool") and not isRod(item.Name) then
            itemCount = itemCount + 1
        end
    end

    if itemCount > 25 and not isProcessing and cache.hrp then
        isProcessing = true
        showNotification("Inventory full, selling...", 2)

        local savedPos = farmStartPosition
        
        cache.hrp.CFrame = CFrame.new(LOCATIONS.sell)
        task.wait(0.8)
        
        sellAllItems()
        task.wait(1.5)
        
        if savedPos then
            cache.hrp.CFrame = savedPos
            farmStartPosition = savedPos
        end

        isProcessing = false
    end
end

local function doReel()
    if cache.reelEvent then
        cache.reelEvent:FireServer(100, false)
        stats.reelAttempts = stats.reelAttempts + 1
    end
end

local function startUltraFastReel()
    local reelTick = 0
    
    connections.reelHeartbeat = RunService.Heartbeat:Connect(function(deltaTime)
        if not farmingEnabled then return end
        
        reelTick = reelTick + deltaTime
        if reelTick >= REEL_SPEED then
            doReel()
            reelTick = 0
        end
    end)
    
    debugLog("Reel", "✅ Ultra Fast Reel started")
end

local function stopUltraFastReel()
    if connections.reelHeartbeat then
        connections.reelHeartbeat:Disconnect()
        connections.reelHeartbeat = nil
    end
    
    debugLog("Reel", "⏹️ Ultra Fast Reel stopped")
end

local function registerCatch(fishItem)
    if not fishItem then 
        return 
    end
    
    local itemName = fishItem.Name
    
    if isIgnoredItem(itemName) then
        return
    end
    
    lastItemAddedTime = tick()
    
    if isEnchantRelic(fishItem) then
        stats.relics = stats.relics + 1
        fishCatchCount[itemName] = (fishCatchCount[itemName] or 0) + 1
        
        showNotification("💎 RELIC! (" .. stats.relics .. ")", 3)
        sendRareCatch(itemName, "Relic")
        return
    end
    
    stats.catches = stats.catches + 1
    fishCatchCount[itemName] = (fishCatchCount[itemName] or 0) + 1
    
    local rarity = getFishRarity(fishItem)
    
    if rarity ~= "Common" and rarity ~= "Uncommon" then
        showNotification("🌟 " .. itemName .. " (" .. rarity .. ")", 3)
        sendRareCatch(itemName, rarity)
    else
        showNotification("🐟 " .. itemName .. " (" .. stats.catches .. ")", 1.5)
    end
end

local function startPositionLock()
    if cache.hrp then
        farmStartPosition = cache.hrp.CFrame
    end
    
    loops.position = task.spawn(function()
        while farmingEnabled do
            task.wait(0.2)
            
            if farmingEnabled and farmStartPosition and cache.hrp then
                local distance = (cache.hrp.Position - farmStartPosition.Position).Magnitude
                
                if distance > 5 then
                    cache.hrp.CFrame = farmStartPosition
                end
            end
        end
    end)
end

local function stopPositionLock()
    if loops.position then
        task.cancel(loops.position)
        loops.position = nil
    end
    farmStartPosition = nil
end

local function startForcedCastMonitor()
    loops.forcedCast = task.spawn(function()
        while farmingEnabled do
            task.wait(1)
            
            if farmingEnabled and not isProcessing and not isCasting then
                local timeSinceLastItem = tick() - lastItemAddedTime
                
                if timeSinceLastItem >= FORCED_CAST_TIMEOUT then
                    stats.forcedCasts = stats.forcedCasts + 1
                    debugLog("ForcedCast", "⚠️ Timeout reached, forcing new cast...")
                    showNotification("🔄 Forced Cast", 1.5)
                    doCast()
                    lastItemAddedTime = tick()
                end
            end
        end
    end)
end

local function stopForcedCastMonitor()
    if loops.forcedCast then
        task.cancel(loops.forcedCast)
        loops.forcedCast = nil
    end
end

local function startFarming()
    debugLog("Farm", "🎣 Starting farm...")
    
    if not ScreenGui then
        warn("❌ GUI not ready! Cannot start farm.")
        return
    end
    
    updateCache()
    
    farmingEnabled = true
    updateFarmButton(true)
    
    showNotification("⚡ AUTO FARM STARTED!", 2)

    lastItemAddedTime = tick()

    startPositionLock()
    startForcedCastMonitor()
    startFillUpMonitor()
    startAutoShake()

    sendWebhook(
        "🟢 FARM STARTED",
        "Auto Farm v12.2 - With Player TP!",
        3066993,
        {
            {name = "Player", value = LocalPlayer.Name, inline = true},
            {name = "Time", value = os.date("%H:%M:%S"), inline = true}
        }
    )

    local enterTick = 0
    connections.enterHeartbeat = RunService.Heartbeat:Connect(function(deltaTime)
        if not farmingEnabled then return end
        
        enterTick = enterTick + deltaTime
        if enterTick >= ENTER_SPEED then
            pressEnter()
            enterTick = 0
        end
    end)

    startUltraFastReel()

    loops.main = task.spawn(function()
        task.wait(0.5)
        
        doCast()

        local trackedItems = {}
        local newItems = {}
        local isProcessingCatch = false

        if cache.backpack then
            for _, item in pairs(cache.backpack:GetChildren()) do
                trackedItems[item] = true
            end
        end

        if cache.backpack then
            connections.itemAdded = cache.backpack.ChildAdded:Connect(function(item)
                if not farmingEnabled then return end
                
                stats.itemsDetected = stats.itemsDetected + 1
                
                if not trackedItems[item] then
                    trackedItems[item] = true
                    
                    if not isIgnoredItem(item.Name) then
                        table.insert(newItems, item)
                        lastItemAddedTime = tick()
                    end
                end
            end)
        end

        task.spawn(function()
            while farmingEnabled do
                task.wait(0.05)
                
                if #newItems > 0 and not isProcessingCatch then
                    local timeSince = tick() - lastItemAddedTime
                    
                    if timeSince >= ITEM_DETECTION_WAIT then
                        isProcessingCatch = true
                        
                        for i, item in ipairs(newItems) do
                            registerCatch(item)
                        end

                        newItems = {}
                        
                        checkAndAutoSell()

                        task.wait(RECAST_DELAY)
                        
                        if not isCasting then
                            doCast()
                        end
                        
                        lastItemAddedTime = tick()
                        isProcessingCatch = false
                    end
                end
            end
        end)

        task.spawn(function()
            while farmingEnabled do
                task.wait(15)
                if not isProcessing then
                    checkAndAutoSell()
                end
            end
        end)

        task.spawn(function()
            while farmingEnabled do
                task.wait(1800)
                sendStatsReport()
            end
        end)
    end)
    
    debugLog("Farm", "✅ Farm started successfully!")
end

local function stopFarming()
    debugLog("Farm", "⏹️ Stopping farm...")
    
    farmingEnabled = false
    updateFarmButton(false)
    
    showNotification("Auto-farm stopped", 2)
    
    stopPositionLock()
    stopUltraFastReel()
    stopForcedCastMonitor()
    stopFillUpMonitor()
    stopAutoShake()
    sendStatsReport()

    for name, loop in pairs(loops) do
        if loop then
            pcall(function() 
                task.cancel(loop)
            end)
        end
    end
    
    for name, conn in pairs(connections) do
        if conn then
            pcall(function() 
                conn:Disconnect()
            end)
        end
    end
    
    loops = {}
    connections = {}
    
    debugLog("Farm", "✅ Farm stopped successfully!")
end

local function teleportTo(location, stateName)
    if not cache.hrp then return end
    
    if not teleportStates[stateName] then
        if not teleportStates.roslit and not teleportStates.sell and not teleportStates.vertigo and not teleportStates.depth then
            originalPosition = cache.hrp.CFrame
        end
        
        cache.hrp.CFrame = CFrame.new(location)
        
        if farmingEnabled then
            farmStartPosition = cache.hrp.CFrame
        end
        
        for key in pairs(teleportStates) do
            teleportStates[key] = false
        end
        teleportStates[stateName] = true
        
        return true
    else
        if originalPosition then
            cache.hrp.CFrame = originalPosition
            
            if farmingEnabled then
                farmStartPosition = cache.hrp.CFrame
            end
        end
        
        teleportStates[stateName] = false
        return false
    end
end

-- ============================================================================
-- PLAYER TELEPORT (НОВОЕ!)
-- ============================================================================

local function findPlayerByName(username)
    username = username:lower()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Name:lower():find(username) or player.DisplayName:lower():find(username) then
                return player
            end
        end
    end
    
    return nil
end

local function teleportToPlayer(username)
    updateCache()
    
    if not cache.hrp then
        showNotification("Character not found!", 2)
        return false
    end
    
    local targetPlayer = findPlayerByName(username)
    
    if not targetPlayer then
        showNotification("Player not found: " .. username, 2)
        return false
    end
    
    if not targetPlayer.Character then
        showNotification(targetPlayer.Name .. " has no character!", 2)
        return false
    end
    
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not targetHRP then
        showNotification("Can't find " .. targetPlayer.Name .. "'s HRP!", 2)
        return false
    end
    
    cache.hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
    
    if farmingEnabled then
        farmStartPosition = cache.hrp.CFrame
    end
    
    showNotification("✅ Teleported to " .. targetPlayer.Name, 2)
    return true
end

local function getNearbyPlayers(maxDistance)
    updateCache()
    
    if not cache.hrp then return {} end
    
    local nearbyPlayers = {}
    local myPos = cache.hrp.Position
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local distance = (hrp.Position - myPos).Magnitude
                if distance <= (maxDistance or 1000) then
                    table.insert(nearbyPlayers, {
                        player = player,
                        distance = distance
                    })
                end
            end
        end
    end
    
    table.sort(nearbyPlayers, function(a, b)
        return a.distance < b.distance
    end)
    
    return nearbyPlayers
end

-- ============================================================================
-- FULL UNLOAD
-- ============================================================================

local function fullUnload()
    print("\n========================================")
    print("🔴 STARTING FULL UNLOAD...")
    print("========================================")
    
    if farmingEnabled then
        print("⏸️ Stopping farm...")
        stopFarming()
        task.wait(0.3)
    end
    
    if noClipEnabled then
        print("🌊 Disabling NoClip...")
        disableNoClip()
        task.wait(0.2)
    end
    
    print("🔌 Disconnecting all connections...")
    local connCount = 0
    for name, conn in pairs(connections) do
        pcall(function()
            if conn and conn.Connected then
                conn:Disconnect()
                connCount = connCount + 1
            end
        end)
    end
    print("📊 Disconnected " .. connCount .. " connections")
    
    print("⏹️ Cancelling all loops...")
    local loopCount = 0
    for name, loop in pairs(loops) do
        pcall(function()
            if loop then
                task.cancel(loop)
                loopCount = loopCount + 1
            end
        end)
    end
    print("📊 Cancelled " .. loopCount .. " loops")
    
    print("🧹 Clearing tables...")
    connections = {}
    loops = {}
    cache = {}
    
    if webhookEnabled then
        print("📤 Sending final webhook...")
        pcall(function()
            sendWebhook(
                "🔴 SCRIPT UNLOADED",
                "Auto Farm v12.2 fully unloaded",
                15158332,
                {
                    {name = "Player", value = LocalPlayer.Name, inline = true},
                    {name = "Total Catches", value = tostring(stats.catches or 0), inline = true}
                }
            )
        end)
        task.wait(0.5)
    end
    
    print("🗑️ Destroying GUI...")
    if ScreenGui then
        pcall(function()
            ScreenGui:Destroy()
        end)
    end
    
    stats = {}
    fishCatchCount = {}
    cachedBodyParts = {}
    
    print("========================================")
    print("✅ FULL UNLOAD COMPLETE!")
    print("========================================\n")
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Script Unloaded",
        Text = "🎣 Auto Farm v12.2 successfully unloaded!",
        Duration = 5
    })
end

-- ============================================================================
-- GUI
-- ============================================================================

local function createButton(props)
    local button = Instance.new("TextButton")
    button.Name = props.name
    button.Parent = props.parent
    button.BackgroundColor3 = props.color
    button.Position = props.position
    button.Size = props.size
    button.Font = Enum.Font.GothamBold
    button.Text = props.text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = props.textSize or 16
    button.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, props.cornerRadius or 10)
    corner.Parent = button
    
    return button
end

local function createTextBox(props)
    local box = Instance.new("TextBox")
    box.Name = props.name
    box.Parent = props.parent
    box.BackgroundColor3 = props.color or Color3.fromRGB(52, 73, 94)
    box.Position = props.position
    box.Size = props.size
    box.Font = Enum.Font.Gotham
    box.PlaceholderText = props.placeholder or ""
    box.Text = props.text or ""
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = props.textSize or 14
    box.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, props.cornerRadius or 8)
    corner.Parent = box
    
    return box
end

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFarmGui"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- УВЕЛИЧИЛИ РАЗМЕР MainFrame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(1, -170, 0.05, 0)
MainFrame.Size = UDim2.new(0, 150, 0, 420) -- БЫЛО 370
MainFrame.BorderSizePixel = 0

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = MainFrame

local FarmButton = createButton({
    name = "FarmButton",
    parent = MainFrame,
    color = Color3.fromRGB(220, 53, 69),
    position = UDim2.new(0, 10, 0, 10),
    size = UDim2.new(1, -20, 0, 50),
    text = "Farm: OFF",
    textSize = 18
})

FarmButton.MouseButton1Click:Connect(function()
    if farmingEnabled then
        stopFarming()
    else
        startFarming()
    end
end)

local NoClipButton = createButton({
    name = "NoClipButton",
    parent = MainFrame,
    color = Color3.fromRGB(192, 57, 43),
    position = UDim2.new(0, 10, 0, 70),
    size = UDim2.new(1, -20, 0, 40),
    text = "NoClip: OFF"
})

NoClipButton.MouseButton1Click:Connect(function()
    if noClipEnabled then
        disableNoClip()
        updateNoClipButton(false)
        showNotification("❌ NoClip OFF", 2)
    else
        enableNoClip()
        updateNoClipButton(true)
        showNotification("✅ NoClip ON!", 2)
    end
end)

local TeleportButton = createButton({
    name = "TeleportButton",
    parent = MainFrame,
    color = Color3.fromRGB(155, 89, 182),
    position = UDim2.new(0, 10, 0, 120),
    size = UDim2.new(1, -20, 0, 40),
    text = "Teleports"
})

local CustomTPButton = createButton({
    name = "CustomTPButton",
    parent = MainFrame,
    color = Color3.fromRGB(142, 68, 173),
    position = UDim2.new(0, 10, 0, 170),
    size = UDim2.new(1, -20, 0, 40),
    text = "Custom TP"
})

-- НОВАЯ КНОПКА!
local PlayerTPButton = createButton({
    name = "PlayerTPButton",
    parent = MainFrame,
    color = Color3.fromRGB(52, 152, 219),
    position = UDim2.new(0, 10, 0, 220),
    size = UDim2.new(1, -20, 0, 40),
    text = "TP to Player"
})

local SellNowButton = createButton({
    name = "SellNowButton",
    parent = MainFrame,
    color = Color3.fromRGB(46, 204, 113),
    position = UDim2.new(0, 10, 0, 270), -- БЫЛО 220
    size = UDim2.new(1, -20, 0, 40),
    text = "Sell All"
})

SellNowButton.MouseButton1Click:Connect(function()
    sellAllItems()
end)

local StatsButton = createButton({
    name = "StatsButton",
    parent = MainFrame,
    color = Color3.fromRGB(26, 188, 156),
    position = UDim2.new(0, 10, 0, 320), -- БЫЛО 270
    size = UDim2.new(1, -20, 0, 40),
    text = "Send Stats"
})

StatsButton.MouseButton1Click:Connect(function()
    sendStatsReport()
    showNotification("Sending stats...", 2)
end)

local UnloadButton = createButton({
    name = "UnloadButton",
    parent = MainFrame,
    color = Color3.fromRGB(231, 76, 60),
    position = UDim2.new(0, 10, 0, 370), -- БЫЛО 320
    size = UDim2.new(1, -20, 0, 40),
    text = "Unload (F7)",
    textSize = 14
})

UnloadButton.MouseButton1Click:Connect(function()
    showNotification("🔴 Unloading script...", 2)
    task.wait(0.5)
    fullUnload()
end)

-- ============================================================================
-- TELEPORT MENUS
-- ============================================================================

local TeleportMenu = Instance.new("Frame")
TeleportMenu.Name = "TeleportMenu"
TeleportMenu.Parent = ScreenGui
TeleportMenu.BackgroundColor3 = Color3.fromRGB(44, 62, 80)
TeleportMenu.Position = UDim2.new(1, -170, 0.58, 0)
TeleportMenu.Size = UDim2.new(0, 150, 0, 180)
TeleportMenu.Visible = false
TeleportMenu.BorderSizePixel = 0

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 10)
menuCorner.Parent = TeleportMenu

TeleportButton.MouseButton1Click:Connect(function()
    TeleportMenu.Visible = not TeleportMenu.Visible
    if TeleportMenu.Visible then
        local customMenu = ScreenGui:FindFirstChild("CustomTPMenu")
        if customMenu then customMenu.Visible = false end
        local playerMenu = ScreenGui:FindFirstChild("PlayerTPMenu")
        if playerMenu then playerMenu.Visible = false end
    end
end)

local RoslitButton = createButton({
    name = "RoslitButton",
    parent = TeleportMenu,
    color = Color3.fromRGB(155, 89, 182),
    position = UDim2.new(0.05, 0, 0.05, 0),
    size = UDim2.new(0.9, 0, 0.2, 0),
    text = "Roslit",
    textSize = 14,
    cornerRadius = 8
})

RoslitButton.MouseButton1Click:Connect(function()
    local isTeleported = teleportTo(LOCATIONS.roslit, "roslit")
    RoslitButton.BackgroundColor3 = isTeleported and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(155, 89, 182)
    RoslitButton.Text = isTeleported and "Return" or "Roslit"
    showNotification(isTeleported and "→ Roslit" or "← Returned", 1.5)
end)

local SellButton = createButton({
    name = "SellButton",
    parent = TeleportMenu,
    color = Color3.fromRGB(230, 126, 34),
    position = UDim2.new(0.05, 0, 0.3, 0),
    size = UDim2.new(0.9, 0, 0.2, 0),
    text = "Sell",
    textSize = 14,
    cornerRadius = 8
})

SellButton.MouseButton1Click:Connect(function()
    local isTeleported = teleportTo(LOCATIONS.sell, "sell")
    SellButton.BackgroundColor3 = isTeleported and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(230, 126, 34)
    SellButton.Text = isTeleported and "Return" or "Sell"
    
    if isTeleported then
        task.wait(0.8)
        sellAllItems()
    end
    
    showNotification(isTeleported and "→ Sell Point" or "← Returned", 1.5)
end)

local VertigoButton = createButton({
    name = "VertigoButton",
    parent = TeleportMenu,
    color = Color3.fromRGB(26, 188, 156),
    position = UDim2.new(0.05, 0, 0.55, 0),
    size = UDim2.new(0.9, 0, 0.2, 0),
    text = "Vertigo",
    textSize = 14,
    cornerRadius = 8
})

VertigoButton.MouseButton1Click:Connect(function()
    local isTeleported = teleportTo(LOCATIONS.vertigo, "vertigo")
    VertigoButton.BackgroundColor3 = isTeleported and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(26, 188, 156)
    VertigoButton.Text = isTeleported and "Return" or "Vertigo"
    showNotification(isTeleported and "→ Vertigo" or "← Returned", 1.5)
end)

local DepthSeaButton = createButton({
    name = "DepthSeaButton",
    parent = TeleportMenu,
    color = Color3.fromRGB(231, 76, 60),
    position = UDim2.new(0.05, 0, 0.8, 0),
    size = UDim2.new(0.9, 0, 0.2, 0),
    text = "Depth Sea",
    textSize = 14,
    cornerRadius = 8
})

DepthSeaButton.MouseButton1Click:Connect(function()
    local isTeleported = teleportTo(LOCATIONS.depthSea, "depth")
    DepthSeaButton.BackgroundColor3 = isTeleported and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
    DepthSeaButton.Text = isTeleported and "Return" or "Depth Sea"
    showNotification(isTeleported and "→ Depth Sea" or "← Returned", 1.5)
end)

local CustomTPMenu = Instance.new("Frame")
CustomTPMenu.Name = "CustomTPMenu"
CustomTPMenu.Parent = ScreenGui
CustomTPMenu.BackgroundColor3 = Color3.fromRGB(44, 62, 80)
CustomTPMenu.Position = UDim2.new(1, -340, 0.58, 0)
CustomTPMenu.Size = UDim2.new(0, 150, 0, 220)
CustomTPMenu.Visible = false
CustomTPMenu.BorderSizePixel = 0

local customCorner = Instance.new("UICorner")
customCorner.CornerRadius = UDim.new(0, 10)
customCorner.Parent = CustomTPMenu

CustomTPButton.MouseButton1Click:Connect(function()
    CustomTPMenu.Visible = not CustomTPMenu.Visible
    if CustomTPMenu.Visible then
        TeleportMenu.Visible = false
        local playerMenu = ScreenGui:FindFirstChild("PlayerTPMenu")
        if playerMenu then playerMenu.Visible = false end
    end
end)

local TPTitle = Instance.new("TextLabel")
TPTitle.Parent = CustomTPMenu
TPTitle.BackgroundTransparency = 1
TPTitle.Position = UDim2.new(0, 0, 0, 5)
TPTitle.Size = UDim2.new(1, 0, 0, 25)
TPTitle.Font = Enum.Font.GothamBold
TPTitle.Text = "Custom Teleport"
TPTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TPTitle.TextSize = 14

local XBox = createTextBox({
    name = "XBox",
    parent = CustomTPMenu,
    position = UDim2.new(0.1, 0, 0, 35),
    size = UDim2.new(0.8, 0, 0, 30),
    placeholder = "X coordinate",
    textSize = 12
})

local YBox = createTextBox({
    name = "YBox",
    parent = CustomTPMenu,
    position = UDim2.new(0.1, 0, 0, 75),
    size = UDim2.new(0.8, 0, 0, 30),
    placeholder = "Y coordinate",
    textSize = 12
})

local ZBox = createTextBox({
    name = "ZBox",
    parent = CustomTPMenu,
    position = UDim2.new(0.1, 0, 0, 115),
    size = UDim2.new(0.8, 0, 0, 30),
    placeholder = "Z coordinate",
    textSize = 12
})

local GetPosButton = createButton({
    name = "GetPosButton",
    parent = CustomTPMenu,
    color = Color3.fromRGB(52, 152, 219),
    position = UDim2.new(0.55, 0, 0, 155),
    size = UDim2.new(0.35, 0, 0, 25),
    text = "Get Pos",
    textSize = 11,
    cornerRadius = 6
})

GetPosButton.MouseButton1Click:Connect(function()
    updateCache()
    if cache.hrp then
        local pos = cache.hrp.Position
        XBox.Text = string.format("%.2f", pos.X)
        YBox.Text = string.format("%.2f", pos.Y)
        ZBox.Text = string.format("%.2f", pos.Z)
        showNotification("Position saved!", 1.5)
    else
        showNotification("Character not found!", 2)
    end
end)

local CopyPosButton = createButton({
    name = "CopyPosButton",
    parent = CustomTPMenu,
    color = Color3.fromRGB(155, 89, 182),
    position = UDim2.new(0.1, 0, 0, 155),
    size = UDim2.new(0.35, 0, 0, 25),
    text = "Copy",
    textSize = 11,
    cornerRadius = 6
})

CopyPosButton.MouseButton1Click:Connect(function()
    updateCache()
    if cache.hrp then
        local pos = cache.hrp.Position
        local posText = string.format("Vector3.new(%.2f, %.2f, %.2f)", pos.X, pos.Y, pos.Z)
        
        if copyToClipboard(posText) then
            showNotification("📋 Position copied!", 1.5)
            CopyPosButton.Text = "✅"
            CopyPosButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            task.wait(1)
            CopyPosButton.Text = "Copy"
            CopyPosButton.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
        else
            showNotification("❌ Clipboard error!", 2)
        end
    else
        showNotification("Character not found!", 2)
    end
end)

local TPGoButton = createButton({
    name = "TPGoButton",
    parent = CustomTPMenu,
    color = Color3.fromRGB(46, 204, 113),
    position = UDim2.new(0.1, 0, 0, 188),
    size = UDim2.new(0.8, 0, 0, 25),
    text = "Teleport!",
    textSize = 11,
    cornerRadius = 6
})

TPGoButton.MouseButton1Click:Connect(function()
    local x = tonumber(XBox.Text)
    local y = tonumber(YBox.Text)
    local z = tonumber(ZBox.Text)
    
    if x and y and z then
        updateCache()
        if cache.hrp then
            local targetPos = Vector3.new(x, y, z)
            cache.hrp.CFrame = CFrame.new(targetPos)
            
            if farmingEnabled then
                farmStartPosition = cache.hrp.CFrame
            end
            
            if noClipEnabled then
                noClipStartHeight = y
            end
            
            showNotification("Teleported!", 1.5)
        else
            showNotification("Character not found!", 2)
        end
    else
        showNotification("Invalid coordinates!", 2)
    end
end)

-- ============================================================================
-- PLAYER TP MENU (НОВОЕ!)
-- ============================================================================

local PlayerTPMenu = Instance.new("Frame")
PlayerTPMenu.Name = "PlayerTPMenu"
PlayerTPMenu.Parent = ScreenGui
PlayerTPMenu.BackgroundColor3 = Color3.fromRGB(44, 62, 80)
PlayerTPMenu.Position = UDim2.new(1, -340, 0.25, 0)
PlayerTPMenu.Size = UDim2.new(0, 150, 0, 150)
PlayerTPMenu.Visible = false
PlayerTPMenu.BorderSizePixel = 0

local playerTPCorner = Instance.new("UICorner")
playerTPCorner.CornerRadius = UDim.new(0, 10)
playerTPCorner.Parent = PlayerTPMenu

PlayerTPButton.MouseButton1Click:Connect(function()
    PlayerTPMenu.Visible = not PlayerTPMenu.Visible
    if PlayerTPMenu.Visible then
        TeleportMenu.Visible = false
        CustomTPMenu.Visible = false
    end
end)

local PlayerTPTitle = Instance.new("TextLabel")
PlayerTPTitle.Parent = PlayerTPMenu
PlayerTPTitle.BackgroundTransparency = 1
PlayerTPTitle.Position = UDim2.new(0, 0, 0, 5)
PlayerTPTitle.Size = UDim2.new(1, 0, 0, 25)
PlayerTPTitle.Font = Enum.Font.GothamBold
PlayerTPTitle.Text = "TP to Player"
PlayerTPTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerTPTitle.TextSize = 14

local UsernameBox = createTextBox({
    name = "UsernameBox",
    parent = PlayerTPMenu,
    position = UDim2.new(0.1, 0, 0, 35),
    size = UDim2.new(0.8, 0, 0, 35),
    placeholder = "Username",
    textSize = 13
})

local TPToPlayerButton = createButton({
    name = "TPToPlayerButton",
    parent = PlayerTPMenu,
    color = Color3.fromRGB(46, 204, 113),
    position = UDim2.new(0.1, 0, 0, 80),
    size = UDim2.new(0.8, 0, 0, 30),
    text = "Teleport!",
    textSize = 12,
    cornerRadius = 8
})

TPToPlayerButton.MouseButton1Click:Connect(function()
    local username = UsernameBox.Text
    
    if username and username ~= "" then
        teleportToPlayer(username)
    else
        showNotification("Enter username!", 2)
    end
end)

local NearbyPlayersButton = createButton({
    name = "NearbyPlayersButton",
    parent = PlayerTPMenu,
    color = Color3.fromRGB(52, 152, 219),
    position = UDim2.new(0.1, 0, 0, 118),
    size = UDim2.new(0.8, 0, 0, 27),
    text = "Nearby",
    textSize = 11,
    cornerRadius = 8
})

NearbyPlayersButton.MouseButton1Click:Connect(function()
    local nearby = getNearbyPlayers(500)
    
    if #nearby > 0 then
        local playerList = "Nearby players:\n"
        for i = 1, math.min(5, #nearby) do
            playerList = playerList .. string.format("%d. %s (%.0fm)\n", 
                i, 
                nearby[i].player.Name, 
                nearby[i].distance
            )
        end
        
        showNotification(playerList, 5)
        print(playerList)
    else
        showNotification("No players nearby!", 2)
    end
end)

-- ============================================================================
-- NOTIFICATION & FILL UP (остается прежним)
-- ============================================================================

local NotificationFrame = Instance.new("Frame")
NotificationFrame.Name = "NotificationFrame"
NotificationFrame.Parent = ScreenGui
NotificationFrame.BackgroundColor3 = Color3.fromRGB(41, 128, 185)
NotificationFrame.Position = UDim2.new(0.5, -150, 0.9, 0)
NotificationFrame.Size = UDim2.new(0, 300, 0, 50)
NotificationFrame.Visible = false
NotificationFrame.BorderSizePixel = 0

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 10)
notifCorner.Parent = NotificationFrame

local NotificationLabel = Instance.new("TextLabel")
NotificationLabel.Name = "NotificationLabel"
NotificationLabel.Parent = NotificationFrame
NotificationLabel.BackgroundTransparency = 1
NotificationLabel.Size = UDim2.new(1, 0, 1, 0)
NotificationLabel.Font = Enum.Font.GothamBold
NotificationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
NotificationLabel.TextSize = 16
NotificationLabel.Text = ""

local FillUpFrame = Instance.new("Frame")
FillUpFrame.Name = "FillUpFrame"
FillUpFrame.Parent = ScreenGui
FillUpFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
FillUpFrame.Position = UDim2.new(0.5, -150, 0.82, 0)
FillUpFrame.Size = UDim2.new(0, 300, 0, 50)
FillUpFrame.BorderSizePixel = 0

local fillUpFrameCorner = Instance.new("UICorner")
fillUpFrameCorner.CornerRadius = UDim.new(0, 10)
fillUpFrameCorner.Parent = FillUpFrame

local FillUpBG = Instance.new("Frame")
FillUpBG.Name = "FillUpBG"
FillUpBG.Parent = FillUpFrame
FillUpBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
FillUpBG.Position = UDim2.new(0.05, 0, 0.5, 0)
FillUpBG.Size = UDim2.new(0.9, 0, 0.3, 0)
FillUpBG.AnchorPoint = Vector2.new(0, 0.5)
FillUpBG.BorderSizePixel = 0

local fillUpBGCorner = Instance.new("UICorner")
fillUpBGCorner.CornerRadius = UDim.new(0, 5)
fillUpBGCorner.Parent = FillUpBG

FillUpBar = Instance.new("Frame")
FillUpBar.Name = "FillUpBar"
FillUpBar.Parent = FillUpBG
FillUpBar.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
FillUpBar.Size = UDim2.new(0, 0, 1, 0)
FillUpBar.BorderSizePixel = 0

local fillUpBarCorner = Instance.new("UICorner")
fillUpBarCorner.CornerRadius = UDim.new(0, 5)
fillUpBarCorner.Parent = FillUpBar

FillUpLabel = Instance.new("TextLabel")
FillUpLabel.Name = "FillUpLabel"
FillUpLabel.Parent = FillUpFrame
FillUpLabel.BackgroundTransparency = 1
FillUpLabel.Position = UDim2.new(0, 0, 0, 5)
FillUpLabel.Size = UDim2.new(1, 0, 0, 20)
FillUpLabel.Font = Enum.Font.GothamBold
FillUpLabel.Text = "Fill Up: 0%"
FillUpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FillUpLabel.TextSize = 14

connections.f7Unload = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F7 then
        showNotification("🔴 Unloading script...", 2)
        task.wait(0.5)
        fullUnload()
    end
end)

-- ============================================================================
-- INIT
-- ============================================================================

updateCache()

print("========================================")
print("🎣 AUTO FARM v12.2 - WITH PLAYER TP!")
print("========================================")
print("✅ Fill Up indicator")
print("✅ Auto Shake (Focus + Enter)")
print("✅ TP to Player (NEW!)")
print("✅ All features working")
print("========================================")

showNotification("🎣 v12.2! TP to Player added!", 4)

sendWebhook(
    "🎣 AUTO FARM LOADED",
    "v12.2 - Player TP Edition!",
    3066993,
    {
        {name = "Player", value = LocalPlayer.Name, inline = true},
        {name = "Version", value = "v12.2", inline = true},
        {name = "New Feature", value = "TP to Player", inline = true}
    }
)