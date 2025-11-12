local ReplicatedStorage = game:GetService("ReplicatedStorage")
local netFolder = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

_G.AutoFishEnabled = true
_G.AutoSellEnabled = false
_G.ScriptLoaded = true

local isFishing = false
local fishCount = 0
local autoSellLimit = 10 -- <-- можно менять правым кликом по кнопке AUTO SELL

-- Создание GUI (улучшенный дизайн)
local player = Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFishGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 320)
mainFrame.Position = UDim2.new(0.5, -130, 0, 30)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
mainFrame.BorderSizePixel = 0
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.Parent = screenGui

local mainUICorner = Instance.new("UICorner", mainFrame)
mainUICorner.CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(45, 47, 52)
mainStroke.Thickness = 1

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundTransparency = 0
header.Parent = mainFrame

local headerGradient = Instance.new("UIGradient", header)
headerGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 169, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(87, 101, 255))
}
headerGradient.Rotation = 0
header.BackgroundTransparency = 0

local headerCorner = Instance.new("UICorner", header)
headerCorner.CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🎣 AUTO FISH PRO"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 18)
subtitle.Position = UDim2.new(0, 10, 0, 34)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Автоматическая рыбалка • Небольшая настройка"
subtitle.TextColor3 = Color3.fromRGB(220, 220, 220)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

-- Контейнер для кнопок
local container = Instance.new("Frame")
container.Size = UDim2.new(1, -20, 1, -80)
container.Position = UDim2.new(0, 10, 0, 70)
container.BackgroundTransparency = 1
container.Parent = mainFrame

local listLayout = Instance.new("UIListLayout", container)
listLayout.Padding = UDim.new(0, 10)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local function createButton(text, sizeY)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, sizeY or 48)
	btn.BackgroundColor3 = Color3.fromRGB(40, 44, 52)
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(240, 240, 240)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 15
	btn.BorderSizePixel = 0
	btn.Parent = container

	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(60, 64, 72)
	stroke.Thickness = 1
	stroke.Transparency = 0.6

	return btn
end

local toggleButton = createButton("AUTO FISH: ON", 54)
local sellButton = createButton("SELL ALL", 50)
local autoSellButton = createButton("AUTO SELL: OFF (0/10)", 46)
local unloadButton = createButton("🗑️ UNLOAD SCRIPT", 40)

-- Подсказка F7 (стрелка вниз, маленький текст)
local f7hint = Instance.new("TextLabel")
f7hint.Size = UDim2.new(1, 0, 0, 14)
f7hint.Position = UDim2.new(0, 0, 1, -18)
f7hint.BackgroundTransparency = 1
f7hint.Text = "F7 — Быстрая выгрузка (или нажмите кнопку)"
f7hint.TextColor3 = Color3.fromRGB(160, 160, 160)
f7hint.Font = Enum.Font.Gotham
f7hint.TextSize = 11
f7hint.TextXAlignment = Enum.TextXAlignment.Center
f7hint.Parent = mainFrame

-- Цветовые константы
local colors = {
	on = Color3.fromRGB(0, 210, 130),
	off = Color3.fromRGB(220, 60, 70),
	neutral = Color3.fromRGB(40, 44, 52),
	accent = Color3.fromRGB(0, 150, 255),
	gold = Color3.fromRGB(255, 195, 0)
}

-- Вспомогательная функция для плавного изменения цвета при наведении
local function applyHoverEffect(button, hoverColor)
	local original = button.BackgroundColor3
	local hoverInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, hoverInfo, {BackgroundColor3 = hoverColor}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, hoverInfo, {BackgroundColor3 = original}):Play()
	end)
end

applyHoverEffect(toggleButton, Color3.fromRGB(55, 60, 70))
applyHoverEffect(sellButton, Color3.fromRGB(55, 60, 70))
applyHoverEffect(autoSellButton, Color3.fromRGB(55, 60, 70))
applyHoverEffect(unloadButton, Color3.fromRGB(55, 60, 70))

-- Обновление стиля кнопок согласно статусам
local function refreshButtons()
	if _G.AutoFishEnabled then
		toggleButton.BackgroundColor3 = colors.on
		toggleButton.Text = "AUTO FISH: ON"
		toggleButton.TextColor3 = Color3.fromRGB(12, 12, 12)
	else
		toggleButton.BackgroundColor3 = colors.off
		toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		if isFishing then
			toggleButton.Text = "AUTO FISH: STOPPING..."
		else
			toggleButton.Text = "AUTO FISH: OFF"
		end
	end

	if _G.AutoSellEnabled then
		autoSellButton.BackgroundColor3 = colors.accent
		autoSellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		autoSellButton.BackgroundColor3 = colors.neutral
		autoSellButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	end
	autoSellButton.Text = (_G.AutoSellEnabled and "AUTO SELL: ON (" or "AUTO SELL: OFF (") .. tostring(fishCount) .. "/" .. tostring(autoSellLimit) .. ")"
end

-- ФУНКЦИЯ ПОЛНОЙ ВЫГРУЗКИ СКРИПТА (оставлена без изменений логики)
local function unloadScript()
	print("\n🚫 === ВЫГРУЗКА СКРИПТА ===")
	
	_G.AutoFishEnabled = false
	_G.AutoSellEnabled = false
	_G.ScriptLoaded = false
	
	if isFishing then
		print("⏳ Ожидание завершения текущей рыбалки...")
		local timeout = 0
		while isFishing and timeout < 50 do
			wait(0.1)
			timeout = timeout + 1
		end
	end
	
	if screenGui and screenGui.Parent then
		screenGui:Destroy()
		print("✓ GUI удалён")
	end
	
	_G.AutoFishEnabled = nil
	_G.AutoSellEnabled = nil
	_G.ScriptLoaded = nil
	
	print("✓ Скрипт полностью выгружен!")
	print("========================\n")
end

-- Обработчик клавиши F7 (настройка: срабатывает по клавиатуре)
local inputConnection
inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.F7 then
		print("🔑 F7 нажата! Начинаем выгрузку...")
		task.spawn(function()
			unloadScript()
			if inputConnection then
				inputConnection:Disconnect()
				inputConnection = nil
			end
		end)
	end
end)

-- Кнопка выгрузки
unloadButton.MouseButton1Click:Connect(function()
	task.spawn(function()
		unloadScript()
		if inputConnection then
			inputConnection:Disconnect()
			inputConnection = nil
		end
	end)
end)

-- Переключение AUTO FISH
toggleButton.MouseButton1Click:Connect(function()
	if not _G.ScriptLoaded then return end
	
	_G.AutoFishEnabled = not _G.AutoFishEnabled
	refreshButtons()
end)

-- SELL ALL
local function sellAll()
	local success, error = pcall(function()
		netFolder["RF/SellAllItems"]:InvokeServer()
	end)
	
	if success then
		fishCount = 0
		refreshButtons()
		return true
	else
		warn("Ошибка продажи: " .. tostring(error))
		return false
	end
end

sellButton.MouseButton1Click:Connect(function()
	if not _G.ScriptLoaded then return end
	
	if sellAll() then
		sellButton.Text = "SOLD! ✓"
		sellButton.BackgroundColor3 = colors.on
		sellButton.TextColor3 = Color3.fromRGB(12,12,12)
		wait(1)
		if _G.ScriptLoaded then
			refreshButtons()
		end
	else
		sellButton.Text = "ERROR!"
		sellButton.BackgroundColor3 = colors.off
		wait(1)
		if _G.ScriptLoaded then
			refreshButtons()
		end
	end
end)

-- AUTO SELL (левая кнопка — вкл/выкл)
autoSellButton.MouseButton1Click:Connect(function()
	if not _G.ScriptLoaded then return end
	
	_G.AutoSellEnabled = not _G.AutoSellEnabled
	refreshButtons()
end)

-- AUTO SELL: правый клик для изменения лимита
autoSellButton.MouseButton2Click:Connect(function()
	if not _G.ScriptLoaded then return end
	
	-- Создаём TextBox поверх кнопки
	local tb = Instance.new("TextBox")
	tb.Size = autoSellButton.Size
	tb.Position = autoSellButton.Position
	tb.AnchorPoint = autoSellButton.AnchorPoint
	tb.BackgroundColor3 = colors.gold
	tb.TextColor3 = Color3.fromRGB(12,12,12)
	tb.Font = Enum.Font.Gotham
	tb.TextSize = 16
	tb.Text = tostring(autoSellLimit)
	tb.ClearTextOnFocus = false
	tb.Parent = container
	tb:CaptureFocus()
	
	-- Стили
	local corner = Instance.new("UICorner", tb)
	corner.CornerRadius = UDim.new(0, 8)
	
	local function finishEditing()
		local val = tonumber(tb.Text)
		if val and val >= 1 then
			autoSellLimit = math.clamp(math.floor(val), 1, 999)
		end
		tb:Destroy()
		refreshButtons()
	end
	
	tb.FocusLost:Connect(function(enterPressed)
		finishEditing()
	end)
end)

-- Функция рыбалки (логика оставлена)
local function autoFish()
	if not _G.ScriptLoaded then return end
	
	isFishing = true
	
	-- Заряжаем удочку
	local timestamp1 = tick()
	netFolder["RF/ChargeFishingRod"]:InvokeServer(timestamp1)
	wait(0.5)
	
	if not _G.ScriptLoaded then 
		isFishing = false
		refreshButtons()
		return 
	end
	
	-- Начинаем мини-игру
	local timestamp2 = tick()
	netFolder["RF/RequestFishingMinigameStarted"]:InvokeServer(
		-1.233184814453125,
		0.9976736023169583,
		timestamp2
	)
	
	-- Ждём 3 секунды (можешь поменять это число)
	wait(2.5)
	
	-- Вызов завершения
	if _G.ScriptLoaded then
		netFolder["RE/FishingCompleted"]:FireServer()
	end
	
	wait(0.5)
	
	-- Увеличиваем счетчик
	fishCount = fishCount + 1
	refreshButtons()
	
	-- Автопродажа по лимиту
	if _G.AutoSellEnabled and fishCount >= autoSellLimit and _G.ScriptLoaded then
		print("💰 Автопродажа! Поймано рыб:", fishCount)
		sellAll()
	end
	
	isFishing = false
	
	if not _G.AutoFishEnabled and _G.ScriptLoaded then
		refreshButtons()
	end
end

-- Основной цикл
task.spawn(function()
	refreshButtons()
	while _G.ScriptLoaded do
		if _G.AutoFishEnabled then
			local success, error = pcall(function()
				autoFish()
			end)
			
			if not success then
				warn("Ошибка рыбалки: " .. tostring(error))
				isFishing = false
				refreshButtons()
			end
			wait(1)
		else
			wait(0.5)
		end
	end
	print("🛑 Основной цикл остановлен")
end)

-- СДЕЛАТЬ GUI ПЕРЕТАСКИВАЕМЫМ (header перетаскивает mainFrame)
do
	local dragging = false
	local dragInput, dragStart, startPos

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging and dragStart and startPos then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end