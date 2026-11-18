-- Meme Menagerie — Brainrot Bazaar: client.
-- The HUD over the 3D world: cash + income, the parade shop (buy the brainrots
-- walking the conveyor), wave warnings, rebirth and base-lock buttons, and the
-- notice feed. Everything the player does here is a request: the server validates.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyRemote = remotes:WaitForChild("BuyBrainrot")
local rebirthRemote = remotes:WaitForChild("Rebirth")
local lockRemote = remotes:WaitForChild("LockBase")
local eventRemote = remotes:WaitForChild("GameEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "BazaarGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function moneyText()
	return BrainrotData.formatMoney(player:GetAttribute("Cash") or 0)
end

local function incomeText()
	return BrainrotData.formatMoney(player:GetAttribute("Income") or 0) .. "/s"
end

-- Top bar: cash, income, rebirths.
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 12)
topBar.Size = UDim2.new(0, 460, 0, 54)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
topBar.BackgroundTransparency = 0.15
topBar.BorderSizePixel = 0
topBar.Parent = gui

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "Cash"
cashLabel.Position = UDim2.new(0, 12, 0, 4)
cashLabel.Size = UDim2.new(0.5, -12, 0, 30)
cashLabel.BackgroundTransparency = 1
cashLabel.Text = moneyText()
cashLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
cashLabel.TextSize = 26
cashLabel.Font = Enum.Font.FredokaOne
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Parent = topBar

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "Income"
incomeLabel.Position = UDim2.new(0.5, 0, 0, 8)
incomeLabel.Size = UDim2.new(0.5, -12, 0, 22)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = incomeText()
incomeLabel.TextColor3 = Color3.fromRGB(120, 230, 140)
incomeLabel.TextSize = 18
incomeLabel.Font = Enum.Font.SourceSansBold
incomeLabel.TextXAlignment = Enum.TextXAlignment.Right
incomeLabel.Parent = topBar

local rebirthLabel = Instance.new("TextLabel")
rebirthLabel.Name = "Rebirths"
rebirthLabel.Position = UDim2.new(0, 12, 0, 32)
rebirthLabel.Size = UDim2.new(1, -24, 0, 18)
rebirthLabel.BackgroundTransparency = 1
rebirthLabel.Text = "Rebirths: 0  •  +0% income"
rebirthLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
rebirthLabel.TextSize = 14
rebirthLabel.Font = Enum.Font.SourceSans
rebirthLabel.TextXAlignment = Enum.TextXAlignment.Left
rebirthLabel.Parent = topBar

local function refreshTop()
	cashLabel.Text = moneyText()
	incomeLabel.Text = incomeText()
	local rb = player:GetAttribute("Rebirths") or 0
	rebirthLabel.Text = "Rebirths: " .. rb .. "  •  +" .. math.floor(rb * BrainrotData.REBIRTH_BONUS * 100) .. "% income"
end

player:GetAttributeChangedSignal("Cash"):Connect(refreshTop)
player:GetAttributeChangedSignal("Income"):Connect(refreshTop)
player:GetAttributeChangedSignal("Rebirths"):Connect(refreshTop)
refreshTop()

-- Wave banner across the top of the screen.
local banner = Instance.new("TextLabel")
banner.Name = "WaveBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 76)
banner.Size = UDim2.new(0, 460, 0, 40)
banner.BackgroundColor3 = Color3.fromRGB(40, 90, 200)
banner.BackgroundTransparency = 0.2
banner.Text = ""
banner.TextColor3 = Color3.fromRGB(255, 255, 255)
banner.TextSize = 22
banner.Font = Enum.Font.FredokaOne
banner.Visible = false
banner.Parent = gui

-- Notice feed, bottom-left.
local notice = Instance.new("TextLabel")
notice.Name = "Notice"
notice.AnchorPoint = Vector2.new(0, 1)
notice.Position = UDim2.new(0, 12, 1, -12)
notice.Size = UDim2.new(0, 420, 0, 30)
notice.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
notice.BackgroundTransparency = 0.2
notice.Text = "Welcome to the Brainrot Bazaar!"
notice.TextColor3 = Color3.fromRGB(255, 255, 255)
notice.TextSize = 16
notice.Font = Enum.Font.SourceSansBold
notice.TextXAlignment = Enum.TextXAlignment.Left
notice.Parent = gui

local noticeToken = 0
local function showNotice(text)
	noticeToken += 1
	local myToken = noticeToken
	notice.Text = text
	task.delay(6, function()
		if myToken == noticeToken then
			notice.Text = ""
		end
	end)
end

-- Parade shop: the brainrots currently walking the conveyor.
local shop = Instance.new("Frame")
shop.Name = "ParadeShop"
shop.AnchorPoint = Vector2.new(1, 0)
shop.Position = UDim2.new(1, -12, 0, 12)
shop.Size = UDim2.new(0, 250, 0, 300)
shop.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
shop.BackgroundTransparency = 0.15
shop.BorderSizePixel = 0
shop.Parent = gui

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, 0, 0, 30)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "BRAINROT PARADE"
shopTitle.TextColor3 = Color3.fromRGB(255, 220, 90)
shopTitle.TextSize = 18
shopTitle.Font = Enum.Font.FredokaOne
shopTitle.Parent = shop

local shopList = Instance.new("ScrollingFrame")
shopList.Position = UDim2.new(0, 6, 0, 34)
shopList.Size = UDim2.new(1, -12, 1, -40)
shopList.BackgroundTransparency = 1
shopList.ScrollBarThickness = 4
shopList.CanvasSize = UDim2.new(0, 0, 0, 0)
shopList.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopList.Parent = shop

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = shopList

local shopRows = {}

local function removeShopRow(id)
	local row = shopRows[id]
	if row then
		row:Destroy()
		shopRows[id] = nil
	end
end

local function addShopRow(data)
	removeShopRow(data.id)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 52)
	row.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	row.BorderSizePixel = 0
	row.Parent = shopList

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.new(0, 8, 0, 4)
	nameLabel.Size = UDim2.new(1, -16, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = data.name .. "  (" .. data.mutation .. ")"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 15
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Position = UDim2.new(0, 8, 0, 26)
	rateLabel.Size = UDim2.new(0.6, -8, 0, 20)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = BrainrotData.formatMoney(data.rate) .. "/s"
	rateLabel.TextColor3 = Color3.fromRGB(120, 230, 140)
	rateLabel.TextSize = 14
	rateLabel.Font = Enum.Font.SourceSans
	rateLabel.TextXAlignment = Enum.TextXAlignment.Left
	rateLabel.Parent = row

	local buyButton = Instance.new("TextButton")
	buyButton.Position = UDim2.new(0.62, 0, 0, 26)
	buyButton.Size = UDim2.new(0.38, -8, 0, 22)
	buyButton.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
	buyButton.Text = "Buy " .. BrainrotData.formatMoney(data.cost)
	buyButton.TextColor3 = Color3.fromRGB(40, 40, 50)
	buyButton.TextSize = 14
	buyButton.Font = Enum.Font.SourceSansBold
	buyButton.Parent = row
	buyButton.MouseButton1Click:Connect(function()
		buyRemote:FireServer(data.id)
	end)

	shopRows[data.id] = row
	-- Parade walkers leave on their own; drop the row after ~15 seconds.
	task.delay(15, function()
		removeShopRow(data.id)
	end)
end

-- Bottom-right buttons: rebirth + lock base.
local buttonRow = Instance.new("Frame")
buttonRow.Name = "Buttons"
buttonRow.AnchorPoint = Vector2.new(1, 1)
buttonRow.Position = UDim2.new(1, -12, 1, -12)
buttonRow.Size = UDim2.new(0, 250, 0, 46)
buttonRow.BackgroundTransparency = 1
buttonRow.Parent = gui

local rebirthButton = Instance.new("TextButton")
rebirthButton.Position = UDim2.new(0, 0, 0, 0)
rebirthButton.Size = UDim2.new(0.5, -4, 1, 0)
rebirthButton.BackgroundColor3 = Color3.fromRGB(170, 90, 255)
rebirthButton.Text = "REBIRTH"
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.TextSize = 16
rebirthButton.Font = Enum.Font.FredokaOne
rebirthButton.Parent = buttonRow
rebirthButton.MouseButton1Click:Connect(function()
	rebirthRemote:FireServer()
end)

local lockButton = Instance.new("TextButton")
lockButton.Position = UDim2.new(0.5, 4, 0, 0)
lockButton.Size = UDim2.new(0.5, -4, 1, 0)
lockButton.BackgroundColor3 = Color3.fromRGB(90, 140, 255)
lockButton.Text = "LOCK BASE"
lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockButton.TextSize = 16
lockButton.Font = Enum.Font.FredokaOne
lockButton.Parent = buttonRow
lockButton.MouseButton1Click:Connect(function()
	lockRemote:FireServer()
end)

-- Help line, bottom-centre.
local help = Instance.new("TextLabel")
help.Name = "Help"
help.AnchorPoint = Vector2.new(0.5, 1)
help.Position = UDim2.new(0.5, 0, 1, -12)
help.Size = UDim2.new(0, 460, 0, 22)
help.BackgroundTransparency = 1
help.Text = "Buy brainrots from the parade • Steal from rivals • Slap thieves • Run home when the wave comes!"
help.TextColor3 = Color3.fromRGB(220, 220, 240)
help.TextSize = 13
help.Font = Enum.Font.SourceSans
help.Parent = gui

-- Server events.
eventRemote.OnClientEvent:Connect(function(kind, data)
	if kind == "spawned" then
		addShopRow(data)
	elseif kind == "bought" then
		removeShopRow(data.id)
		if data.player ~= player.Name then
			showNotice(data.player .. " bought " .. data.name .. " (" .. data.mutation .. ")")
		end
	elseif kind == "notice" then
		showNotice(data.text)
	elseif kind == "stolen" then
		showNotice(data.thief .. " stole " .. data.victim .. "'s " .. data.name .. "!")
	elseif kind == "slapped" then
		showNotice(data.slapper .. " slapped " .. data.thief .. " — the " .. data.name .. " is safe!")
	elseif kind == "stealKept" then
		showNotice(data.thief .. " got away with the " .. data.name .. "!")
	elseif kind == "rebirthed" then
		showNotice(data.player .. " reached Rebirth " .. data.rebirths .. "!")
	elseif kind == "waveWarning" then
		banner.Visible = true
		banner.Text = "TSUNAMI IN " .. data.seconds .. "s — GET TO YOUR BASE!"
		task.spawn(function()
			for i = data.seconds, 1, -1 do
				task.wait(1)
				if banner.Visible then
					banner.Text = "TSUNAMI IN " .. i .. "s — GET TO YOUR BASE!"
				end
			end
		end)
	elseif kind == "waveIncoming" then
		banner.Text = "TSUNAMI! RUN HOME!"
	elseif kind == "waveOver" then
		banner.Visible = false
	end
end)

-- The Slap Glove's swing is hooked on the server (BrainrotService): the
-- server checks range and cooldowns, so the client needs no extra wiring here.
