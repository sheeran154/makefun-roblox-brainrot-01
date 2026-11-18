-- BrainrotService: the whole server game loop for Meme Menagerie.
-- Owns player money, bases, the conveyor parade, buying, stealing, rebirths
-- and the tsunami wave. Every RemoteEvent is validated here: the client can
-- ask, but the server decides (price, ownership, free slot, cooldowns).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local BrainrotService = {}

-- Remotes are created by init.server.luau before start() runs.
local remotes
local buyRemote
local stealRemote
local slapRemote
local rebirthRemote
local lockRemote
local eventRemote

local workspace = game:GetService("Workspace")

local START_MONEY = 500
local WALK_SPEED = 6 -- studs per second along the conveyor
local CONVEYOR_START_Z = -44
local CONVEYOR_END_Z = 44
local SLAP_RANGE = 12
local SLAP_COOLDOWN = 3

local bases = {} -- [baseIndex] = { owner = Player|nil, slots = { [slot] = brainrot|nil }, lockUntil, lockCooldownUntil, info }
local players = {} -- [Player] = { cash, rebirths, baseIndex, carrying = brainrot|nil, lastSlap }
local walkers = {} -- brainrots currently parading on the conveyor
local nextWalkerId = 1
local waveActive = false

local function baseOf(player)
	local state = players[player]
	if not state or not state.baseIndex then
		return nil
	end
	return bases[state.baseIndex]
end

local function incomePerSecond(player)
	local state = players[player]
	if not state then
		return 0
	end
	local total = 0
	local base = baseOf(player)
	if base then
		for _, br in pairs(base.slots) do
			if br then
				total += br.rate
			end
		end
	end
	return total * BrainrotData.rebirthMultiplier(state.rebirths)
end

local function setCash(player, amount)
	local state = players[player]
	if not state then
		return
	end
	state.cash = math.max(0, math.floor(amount))
	player:SetAttribute("Cash", state.cash)
	player:SetAttribute("Income", incomePerSecond(player))
	player:SetAttribute("Rebirths", state.rebirths)
end

local function freeSlot(base)
	for i = 1, BrainrotData.MAX_SLOTS do
		if base.slots[i] == nil then
			return i
		end
	end
	return nil
end

local function tagModel(model, br)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Tag"
	billboard.Size = UDim2.fromOffset(140, 64)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = model
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = br.char.name
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Parent = billboard
	local rateLabel = Instance.new("TextLabel")
	rateLabel.Position = UDim2.new(0, 0, 0.5, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.5, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = BrainrotData.formatMoney(br.rate) .. "/s  •  " .. br.mutation
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.SourceSansBold
	rateLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
	rateLabel.TextStrokeTransparency = 0.3
	rateLabel.Parent = billboard
end

local function promptOn(model, text, actionText)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = text
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	return prompt
end

local function placeOnSlot(base, br, slotIndex)
	local slotPos = base.info.slots[slotIndex]
	br.model:PivotTo(CFrame.new(slotPos))
	br.slot = slotIndex
	br.state = "owned"
	base.slots[slotIndex] = br
	local tag = br.model:FindFirstChild("Tag")
	if tag then
		tag:FindFirstChildOfClass("TextLabel").Text = br.char.name
	end
	local prompt = br.model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt:Destroy()
	end
	-- Anyone but the owner can try to steal it: walk up and hold the prompt.
	local stealPrompt = Instance.new("ProximityPrompt")
	stealPrompt.ActionText = "Steal"
	stealPrompt.ObjectText = br.char.name
	stealPrompt.HoldDuration = 0.6
	stealPrompt.MaxActivationDistance = 14
	stealPrompt.RequiresLineOfSight = false
	stealPrompt.Parent = br.model.PrimaryPart
	stealPrompt.Triggered:Connect(function(player)
		BrainrotService.steal(player, br)
	end)
end

local function removeBrainrot(br)
	if br.model then
		br.model:Destroy()
	end
	if br.ownerBase and br.slot then
		local base = bases[br.ownerBase]
		if base and base.slots[br.slot] == br then
			base.slots[br.slot] = nil
		end
	end
	for i, w in ipairs(walkers) do
		if w == br then
			table.remove(walkers, i)
			break
		end
	end
end

-- Spawn one brainrot at the gate and let it parade down the conveyor.
local function spawnWalker()
	if #walkers >= BrainrotData.MAX_WALKERS then
		return
	end
	local char = BrainrotData.rollCharacter()
	local mutation = BrainrotData.rollMutation()
	local rate = BrainrotData.rateFor(char, mutation)
	local id = nextWalkerId
	nextWalkerId += 1
	local model = WorldBuilder.buildBrainrotModel(char, mutation, Vector3.new(0, 2, CONVEYOR_START_Z))
	model.Parent = workspace
	local br = {
		id = id,
		char = char,
		mutation = mutation,
		rate = rate,
		model = model,
		state = "walking",
		owner = nil,
		ownerBase = nil,
		slot = nil,
		z = CONVEYOR_START_Z,
	}
	tagModel(model, br)
	local buyPrompt = promptOn(model, char.name .. " — " .. BrainrotData.formatMoney(char.cost), "Buy " .. BrainrotData.formatMoney(char.cost))
	buyPrompt.Triggered:Connect(function(player)
		BrainrotService.buy(player, br)
	end)
	table.insert(walkers, br)
	eventRemote:FireAllClients("spawned", { id = id, name = char.name, mutation = mutation, rate = rate, cost = char.cost })
end

function BrainrotService.buy(player, br)
	local state = players[player]
	if not state or br.state ~= "walking" then
		return
	end
	local base = baseOf(player)
	if not base then
		return
	end
	local slot = freeSlot(base)
	if not slot then
		eventRemote:FireClient(player, "notice", { text = "Your base is full! Rebirth or wait." })
		return
	end
	if state.cash < br.char.cost then
		eventRemote:FireClient(player, "notice", { text = "Not enough cash for " .. br.char.name .. " (" .. BrainrotData.formatMoney(br.char.cost) .. ")" })
		return
	end
	setCash(player, state.cash - br.char.cost)
	for i, w in ipairs(walkers) do
		if w == br then
			table.remove(walkers, i)
			break
		end
	end
	br.owner = player
	br.ownerBase = state.baseIndex
	placeOnSlot(base, br, slot)
	setCash(player, state.cash) -- refresh income attribute
	eventRemote:FireAllClients("bought", { id = br.id, player = player.Name, name = br.char.name, mutation = br.mutation })
	eventRemote:FireClient(player, "notice", { text = "You bought " .. br.char.name .. " (" .. br.mutation .. ") — " .. BrainrotData.formatMoney(br.rate) .. "/s!" })
end

-- Steal: pick up someone else's brainrot and carry it home. The owner can slap
-- it out of your hands; if you reach your own base with it, it is yours.
function BrainrotService.steal(player, br)
	local state = players[player]
	if not state or state.carrying then
		return
	end
	if br.state ~= "owned" or br.owner == player then
		return
	end
	local victimBase = bases[br.ownerBase]
	if not victimBase then
		return
	end
	if victimBase.lockUntil and os.clock() < victimBase.lockUntil then
		eventRemote:FireClient(player, "notice", { text = "That base is locked!" })
		return
	end
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then
		return
	end
	local root = br.model.PrimaryPart
	if not root then
		return
	end
	if (char.HumanoidRootPart.Position - root.Position).Magnitude > 16 then
		return
	end
	victimBase.slots[br.slot] = nil
	br.slot = nil
	br.state = "carried"
	br.carrier = player
	state.carrying = br
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = char.HumanoidRootPart
	weld.Part1 = root
	weld.Parent = root
	br.model:PivotTo(CFrame.new(char.HumanoidRootPart.Position + Vector3.new(0, 3.5, 0)))
	eventRemote:FireAllClients("stolen", { thief = player.Name, victim = br.owner.Name, name = br.char.name })
	if br.owner then
		eventRemote:FireClient(br.owner, "notice", { text = player.Name .. " is stealing your " .. br.char.name .. "! Slap them!" })
	end
end

local function dropCarried(player, br, returnHome)
	local state = players[player]
	if state and state.carrying == br then
		state.carrying = nil
	end
	local weld = br.model.PrimaryPart:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	br.carrier = nil
	if returnHome and br.owner and br.ownerBase then
		local base = bases[br.ownerBase]
		local slot = freeSlot(base)
		if slot then
			br.state = "owned"
			placeOnSlot(base, br, slot)
			return
		end
	end
	-- No home to return to: it wanders off and despawns.
	br.state = "walking"
	br.owner = nil
	br.ownerBase = nil
	br.z = CONVEYOR_END_Z - 10
	table.insert(walkers, br)
end

function BrainrotService.slap(player)
	local state = players[player]
	if not state then
		return
	end
	if state.lastSlap and os.clock() - state.lastSlap < SLAP_COOLDOWN then
		return
	end
	state.lastSlap = os.clock()
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then
		return
	end
	local myPos = char.HumanoidRootPart.Position
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local otherState = players[other]
			if otherState and otherState.carrying then
				local otherChar = other.Character
				if otherChar and otherChar:FindFirstChild("HumanoidRootPart") then
					if (otherChar.HumanoidRootPart.Position - myPos).Magnitude <= SLAP_RANGE then
						local br = otherState.carrying
						dropCarried(other, br, true)
						eventRemote:FireAllClients("slapped", { slapper = player.Name, thief = other.Name, name = br.char.name })
						eventRemote:FireClient(other, "notice", { text = player.Name .. " slapped the " .. br.char.name .. " out of your hands!" })
						return
					end
				end
			end
		end
	end
end

function BrainrotService.rebirth(player)
	local state = players[player]
	if not state then
		return
	end
	local cost = BrainrotData.rebirthCost(state.rebirths)
	if state.cash < cost then
		eventRemote:FireClient(player, "notice", { text = "Rebirth costs " .. BrainrotData.formatMoney(cost) .. " — you have " .. BrainrotData.formatMoney(state.cash) })
		return
	end
	local base = baseOf(player)
	if base then
		for i = 1, BrainrotData.MAX_SLOTS do
			local br = base.slots[i]
			if br then
				removeBrainrot(br)
			end
		end
	end
	if state.carrying then
		local br = state.carrying
		state.carrying = nil
		removeBrainrot(br)
	end
	state.rebirths += 1
	setCash(player, 0)
	eventRemote:FireAllClients("rebirthed", { player = player.Name, rebirths = state.rebirths })
	eventRemote:FireClient(player, "notice", { text = "REBIRTH " .. state.rebirths .. "! Permanent +" .. math.floor(BrainrotData.REBIRTH_BONUS * 100) .. "% income forever." })
end

function BrainrotService.lockBase(player)
	local state = players[player]
	if not state then
		return
	end
	local base = baseOf(player)
	if not base then
		return
	end
	if base.lockCooldownUntil and os.clock() < base.lockCooldownUntil then
		local left = math.ceil(base.lockCooldownUntil - os.clock())
		eventRemote:FireClient(player, "notice", { text = "Base lock recharging: " .. left .. "s" })
		return
	end
	base.lockUntil = os.clock() + BrainrotData.STEAL_LOCK_SECONDS
	base.lockCooldownUntil = os.clock() + BrainrotData.STEAL_LOCK_COOLDOWN
	eventRemote:FireClient(player, "notice", { text = "Base locked for " .. BrainrotData.STEAL_LOCK_SECONDS .. "s — nobody can steal from you!" })
end

-- The tsunami: warn, then sweep a wave wall across the map. Players caught
-- outside their own base are flung and lose 10% of their cash.
local function runWave(wavePart)
	if waveActive then
		return
	end
	waveActive = true
	eventRemote:FireAllClients("waveWarning", { seconds = BrainrotData.WAVE_WARNING })
	task.wait(BrainrotData.WAVE_WARNING)
	eventRemote:FireAllClients("waveIncoming", {})
	wavePart.Position = Vector3.new(0, 13, -200)
	for z = -200, 200, 4 do
		wavePart.Position = Vector3.new(0, 13, z)
		-- Anyone touching the wall who is not standing on their own base gets hit.
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			if hrp and humanoid and humanoid.Health > 0 then
				if math.abs(hrp.Position.Z - z) < 6 then
					local state = players[player]
					local safe = false
					if state and state.baseIndex then
						local c = bases[state.baseIndex].info.center
						if (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(c.X, 0, c.Z)).Magnitude < 22 then
							safe = true
						end
					end
					if not safe then
						local dir = (hrp.Position - Vector3.new(0, hrp.Position.Y, z))
						if dir.Magnitude < 1 then
							dir = Vector3.new(0, 1, 1)
						end
						hrp.AssemblyLinearVelocity = dir.Unit * 70 + Vector3.new(0, 40, 0)
						if state then
							setCash(player, state.cash * 0.9)
						end
						eventRemote:FireClient(player, "notice", { text = "The tsunami caught you! -10% cash. Get to your base next time!" })
					end
				end
			end
		end
		task.wait(0.08)
	end
	wavePart.Position = Vector3.new(0, 13, -200)
	waveActive = false
	eventRemote:FireAllClients("waveOver", {})
end

local function claimBase(player)
	for i, base in ipairs(bases) do
		if base.owner == nil then
			base.owner = player
			players[player].baseIndex = i
			local sign = base.info.ownerSign:FindFirstChild("OwnerLabel")
			if sign then
				sign:FindFirstChildOfClass("TextLabel").Text = string.upper(player.Name) .. "'S BASE"
			end
			local rimLabel = base.info.folder:FindFirstChild("Rim")
			if rimLabel then
				rimLabel:FindFirstChild("BaseLabel"):FindFirstChildOfClass("TextLabel").Text = string.upper(player.Name)
			end
			return i
		end
	end
	return nil
end

local function onPlayerAdded(player)
	players[player] = { cash = START_MONEY, rebirths = 0, baseIndex = nil, carrying = nil, lastSlap = nil }
	player:SetAttribute("Cash", START_MONEY)
	player:SetAttribute("Income", 0)
	player:SetAttribute("Rebirths", 0)
	local baseIndex = claimBase(player)
	if baseIndex then
		eventRemote:FireClient(player, "notice", { text = "Welcome to Meme Menagerie! Base " .. baseIndex .. " is yours. Buy brainrots from the parade!" })
	else
		eventRemote:FireClient(player, "notice", { text = "Welcome! All bases are taken — spectate or wait for a free base." })
	end
	player.CharacterAdded:Connect(function(char)
		task.wait(1)
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and players[player] and players[player].baseIndex then
			local c = bases[players[player].baseIndex].info.center
			hrp.CFrame = CFrame.new(c + Vector3.new(0, 5, 0))
		end
		-- The Slap Glove every player spawns with: swinging it near a thief
		-- knocks the stolen brainrot out of their hands.
		local tool = char:WaitForChild("Slap Glove", 10)
		if tool then
			tool.Activated:Connect(function()
				BrainrotService.slap(player)
			end)
		end
	end)
end

local function onPlayerRemoving(player)
	local state = players[player]
	if state then
		if state.carrying then
			dropCarried(player, state.carrying, true)
		end
		local base = baseOf(player)
		if base then
			for i = 1, BrainrotData.MAX_SLOTS do
				local br = base.slots[i]
				if br then
					removeBrainrot(br)
				end
			end
			base.owner = nil
			local sign = base.info.ownerSign:FindFirstChild("OwnerLabel")
			if sign then
				sign:FindFirstChildOfClass("TextLabel").Text = "EMPTY BASE"
			end
		end
	end
	players[player] = nil
end

function BrainrotService.start()
	-- Remotes (created by init.server.luau before start runs).
	remotes = ReplicatedStorage:WaitForChild("Remotes")
	buyRemote = remotes:WaitForChild("BuyBrainrot")
	stealRemote = remotes:WaitForChild("StealBrainrot")
	slapRemote = remotes:WaitForChild("Slap")
	rebirthRemote = remotes:WaitForChild("Rebirth")
	lockRemote = remotes:WaitForChild("LockBase")
	eventRemote = remotes:WaitForChild("GameEvent")

	-- Build the world.
	for i = 1, BrainrotData.BASE_COUNT do
		local info = WorldBuilder.buildBase(workspace, i)
		bases[i] = { owner = nil, slots = {}, lockUntil = nil, lockCooldownUntil = nil, info = info }
	end
	WorldBuilder.buildConveyor(workspace)
	WorldBuilder.buildDecor(workspace)
	local wavePart = WorldBuilder.buildWave(workspace)

	-- The Slap tool every player spawns with.
	local slapTool = Instance.new("Tool")
	slapTool.Name = "Slap Glove"
	slapTool.RequiresHandle = true
	slapTool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 2)
	handle.Color = Color3.fromRGB(255, 120, 160)
	handle.Parent = slapTool
	slapTool.Parent = game:GetService("StarterPack")

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	buyRemote.OnServerEvent:Connect(function(player, walkerId)
		for _, br in ipairs(walkers) do
			if br.id == walkerId then
				BrainrotService.buy(player, br)
				return
			end
		end
	end)
	stealRemote.OnServerEvent:Connect(function(player, ownerName, charId)
		for _, base in ipairs(bases) do
			for _, br in pairs(base.slots) do
				if br and br.char.id == charId and br.owner and br.owner.Name == ownerName then
					BrainrotService.steal(player, br)
					return
				end
			end
		end
	end)
	slapRemote.OnServerEvent:Connect(function(player)
		BrainrotService.slap(player)
	end)
	rebirthRemote.OnServerEvent:Connect(function(player)
		BrainrotService.rebirth(player)
	end)
	lockRemote.OnServerEvent:Connect(function(player)
		BrainrotService.lockBase(player)
	end)

	-- Slap tool activation is hooked in onPlayerAdded's CharacterAdded handler.

	-- Income tick: every second, everyone earns.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local state = players[player]
				if state then
					setCash(player, state.cash + incomePerSecond(player))
				end
			end
		end
	end)

	-- Spawner: a new brainrot joins the parade every few seconds.
	task.spawn(function()
		while true do
			task.wait(BrainrotData.SPAWN_INTERVAL)
			spawnWalker()
		end
	end)

	-- Walkers parade down the conveyor; reaching the end, they leave.
	task.spawn(function()
		while true do
			task.wait(0.15)
			for i = #walkers, 1, -1 do
				local br = walkers[i]
				if br.state == "walking" then
					br.z += WALK_SPEED * 0.15
					br.model:PivotTo(CFrame.new(0, 2, br.z))
					if br.z >= CONVEYOR_END_Z then
						removeBrainrot(br)
					end
				end
			end
			-- Carried brainrots follow their thief.
			for _, player in ipairs(Players:GetPlayers()) do
				local state = players[player]
				if state and state.carrying then
					local char = player.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if hrp then
						state.carrying.model:PivotTo(CFrame.new(hrp.Position + Vector3.new(0, 3.5, 0)))
						-- Reached your own base with the loot? It is yours now.
						local base = baseOf(player)
						if base then
							local c = base.info.center
							if (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(c.X, 0, c.Z)).Magnitude < 20 then
								local br = state.carrying
								local slot = freeSlot(base)
								if slot then
									state.carrying = nil
									local weld = br.model.PrimaryPart:FindFirstChild("CarryWeld")
									if weld then
										weld:Destroy()
									end
									br.carrier = nil
									br.owner = player
									br.ownerBase = state.baseIndex
									placeOnSlot(base, br, slot)
									setCash(player, state.cash)
									eventRemote:FireAllClients("stealKept", { thief = player.Name, name = br.char.name })
									eventRemote:FireClient(player, "notice", { text = "You got away with the " .. br.char.name .. "! It now earns for you." })
								end
							end
						end
					else
						dropCarried(player, state.carrying, true)
					end
				end
			end
		end
	end)

	-- The tsunami, on a timer, forever.
	task.spawn(function()
		while true do
			task.wait(BrainrotData.WAVE_INTERVAL)
			runWave(wavePart)
		end
	end)
end

return BrainrotService
