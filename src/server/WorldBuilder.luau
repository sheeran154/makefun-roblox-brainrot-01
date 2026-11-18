-- WorldBuilder: builds the 3D bazaar at runtime (Rojo places the skeleton in
-- default.project.json; this module adds every base, slot, sign, tree and lamp).
-- The world: 8 player bases in a ring around a central conveyor where brainrots
-- spawn and walk, a bazaar plaza, corner towers and a big entrance sign.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local WorldBuilder = {}

local BASE_COLORS = {
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(120, 170, 255),
	Color3.fromRGB(120, 230, 140),
	Color3.fromRGB(255, 210, 90),
	Color3.fromRGB(200, 140, 255),
	Color3.fromRGB(255, 160, 90),
	Color3.fromRGB(90, 220, 220),
	Color3.fromRGB(255, 120, 200),
}

-- Base centres in a ring around the middle, 95 studs out.
local function baseCenter(index)
	local angle = (index - 1) * (math.pi * 2 / BrainrotData.BASE_COUNT)
	return Vector3.new(math.cos(angle) * 95, 0, math.sin(angle) * 95)
end

local function part(parent, name, size, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = true
	p.Parent = parent
	return p
end

local function label(parent, name, text, size, color, face)
	local gui = Instance.new("SurfaceGui")
	gui.Name = name
	gui.Face = face or Enum.NormalId.Top
	gui.AlwaysOnTop = true
	gui.Parent = parent
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Text = text
	tl.TextScaled = true
	tl.Font = Enum.Font.FredokaOne
	tl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	tl.TextStrokeTransparency = 0.4
	tl.Parent = gui
	return tl
end

-- 8 slot pads on a base: two rows of four. Returns the slot world positions.
function WorldBuilder.buildBase(workspace, index)
	local center = baseCenter(index)
	local color = BASE_COLORS[((index - 1) % #BASE_COLORS) + 1]

	local folder = Instance.new("Folder")
	folder.Name = "Base" .. index
	folder.Parent = workspace

	-- The base pad itself is static in default.project.json; here the rim, slots and sign.
	local rim = part(folder, "Rim", Vector3.new(30, 1, 30), center + Vector3.new(0, 1.5, 0), color, Enum.Material.Neon)
	rim.CanCollide = false
	label(rim, "BaseLabel", "BASE " .. index, UDim2.fromScale(1, 1), Color3.fromRGB(255, 255, 255))

	local ownerSign = part(folder, "OwnerSign", Vector3.new(12, 5, 1), center + Vector3.new(0, 6, -14), Color3.fromRGB(40, 40, 50))
	label(ownerSign, "OwnerLabel", "EMPTY BASE", UDim2.fromScale(1, 1), Color3.fromRGB(255, 255, 255), Enum.NormalId.Front)

	local slots = {}
	for row = 1, 2 do
		for col = 1, 4 do
			local slotIndex = (row - 1) * 4 + col
			local x = center.X + (col - 2.5) * 6
			local z = center.Z + (row - 1.5) * 6
			local pad = part(folder, "Slot" .. slotIndex, Vector3.new(5, 0.6, 5), Vector3.new(x, 2.3, z), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
			pad.Transparency = 0.55
			pad.CanCollide = false
			label(pad, "SlotLabel", tostring(slotIndex), UDim2.fromScale(1, 1), color)
			table.insert(slots, Vector3.new(x, 2.6, z))
		end
	end

	return { center = center, color = color, slots = slots, folder = folder, ownerSign = ownerSign }
end

function WorldBuilder.buildConveyor(workspace)
	local folder = Instance.new("Folder")
	folder.Name = "Conveyor"
	folder.Parent = workspace

	-- A raised walkway from the spawn gate to the despawn gate, through the plaza.
	local belt = part(folder, "Belt", Vector3.new(10, 1, 90), Vector3.new(0, 1.5, 0), Color3.fromRGB(60, 60, 75), Enum.Material.Metal)
	label(belt, "BeltLabel", "BRAINROT PARADE", UDim2.fromScale(1, 1), Color3.fromRGB(255, 220, 90))
	for i = 1, 9 do
		local stripe = part(folder, "Stripe" .. i, Vector3.new(10, 0.2, 3), Vector3.new(0, 2.1, -40 + i * 10), Color3.fromRGB(255, 220, 90), Enum.Material.Neon)
		stripe.CanCollide = false
	end

	local spawnGate = part(folder, "SpawnGate", Vector3.new(14, 10, 2), Vector3.new(0, 6, -48), Color3.fromRGB(255, 90, 90), Enum.Material.Neon)
	spawnGate.CanCollide = false
	label(spawnGate, "SpawnLabel", "SPAWN", UDim2.fromScale(1, 1), Color3.fromRGB(255, 255, 255), Enum.NormalId.Front)

	local endGate = part(folder, "DespawnGate", Vector3.new(14, 10, 2), Vector3.new(0, 6, 48), Color3.fromRGB(120, 120, 140))
	endGate.CanCollide = false
	label(endGate, "EndLabel", "GONE!", UDim2.fromScale(1, 1), Color3.fromRGB(255, 255, 255), Enum.NormalId.Front)
end

function WorldBuilder.buildDecor(workspace)
	local folder = Instance.new("Folder")
	folder.Name = "Decor"
	folder.Parent = workspace

	-- Entrance sign over the south edge.
	local postL = part(folder, "SignPostL", Vector3.new(2, 14, 2), Vector3.new(-16, 7, 120), Color3.fromRGB(90, 70, 50), Enum.Material.Wood)
	local postR = part(folder, "SignPostR", Vector3.new(2, 14, 2), Vector3.new(16, 7, 120), Color3.fromRGB(90, 70, 50), Enum.Material.Wood)
	local board = part(folder, "SignBoard", Vector3.new(36, 8, 2), Vector3.new(0, 16, 120), Color3.fromRGB(255, 200, 60))
	label(board, "TitleLabel", "MEME MENAGERIE", UDim2.fromScale(1, 1), Color3.fromRGB(120, 40, 140), Enum.NormalId.Front)
	local sub = part(folder, "SignSub", Vector3.new(30, 3, 1), Vector3.new(0, 10.5, 120), Color3.fromRGB(40, 40, 55))
	label(sub, "SubLabel", "BRAINROT BAZAAR", UDim2.fromScale(1, 1), Color3.fromRGB(255, 255, 255), Enum.NormalId.Front)

	-- Corner towers.
	for _, corner in ipairs({ Vector3.new(-110, 0, -110), Vector3.new(110, 0, -110), Vector3.new(-110, 0, 110), Vector3.new(110, 0, 110) }) do
		local tower = part(folder, "Tower", Vector3.new(10, 30, 10), corner + Vector3.new(0, 15, 0), Color3.fromRGB(150, 110, 200), Enum.Material.Concrete)
		local cap = part(folder, "TowerCap", Vector3.new(12, 2, 12), corner + Vector3.new(0, 31, 0), Color3.fromRGB(255, 220, 90), Enum.Material.Neon)
		cap.CanCollide = false
	end

	-- Trees and lamps scattered between the bases.
	local treeSpots = {
		Vector3.new(-60, 0, -60), Vector3.new(60, 0, -60), Vector3.new(-60, 0, 60), Vector3.new(60, 0, 60),
		Vector3.new(-40, 0, 80), Vector3.new(40, 0, -80), Vector3.new(-80, 0, 40), Vector3.new(80, 0, -40),
	}
	for i, spot in ipairs(treeSpots) do
		local trunk = part(folder, "TreeTrunk" .. i, Vector3.new(2, 8, 2), spot + Vector3.new(0, 4, 0), Color3.fromRGB(120, 85, 50), Enum.Material.Wood)
		local leaves = Instance.new("Part")
		leaves.Name = "TreeTop" .. i
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(10, 10, 10)
		leaves.Position = spot + Vector3.new(0, 12, 0)
		leaves.Color = Color3.fromRGB(70, 190, 90)
		leaves.Material = Enum.Material.SmoothPlastic
		leaves.Anchored = true
		leaves.Parent = folder
	end

	-- Lamps along the conveyor.
	for _, side in ipairs({ -8, 8 }) do
		for _, z in ipairs({ -30, -10, 10, 30 }) do
			local pole = part(folder, "LampPole", Vector3.new(1, 8, 1), Vector3.new(side, 4, z), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
			local bulb = part(folder, "LampBulb", Vector3.new(3, 2, 3), Vector3.new(side, 8.5, z), Color3.fromRGB(255, 240, 160), Enum.Material.Neon)
			bulb.CanCollide = false
		end
	end
end

-- The wave wall: a huge translucent wall the server sweeps across the map.
function WorldBuilder.buildWave(workspace)
	local wave = Instance.new("Part")
	wave.Name = "TsunamiWave"
	wave.Size = Vector3.new(280, 26, 4)
	wave.Position = Vector3.new(0, 13, -200)
	wave.Color = Color3.fromRGB(60, 140, 255)
	wave.Material = Enum.Material.Neon
	wave.Transparency = 0.35
	wave.Anchored = true
	wave.CanCollide = false
	wave.Parent = workspace
	return wave
end

-- Builds one brainrot character as a Model, standing on `position`, facing `facing`.
-- Body + belly + eyes + its signature accessory, tinted by mutation.
function WorldBuilder.buildBrainrotModel(char, mutation, position)
	local mut = BrainrotData.MUTATIONS[mutation] or BrainrotData.MUTATIONS.Normal
	local model = Instance.new("Model")
	model.Name = char.id

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(char.size, char.size, char.size)
	root.Position = position + Vector3.new(0, char.size / 2, 0)
	root.Color = char.body
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true
	root.CanCollide = false
	root.Parent = model

	local belly = Instance.new("Part")
	belly.Name = "Belly"
	belly.Size = Vector3.new(char.size * 0.6, char.size * 0.6, 0.6)
	belly.Position = position + Vector3.new(0, char.size * 0.45, char.size * 0.5)
	belly.Color = char.belly
	belly.Material = Enum.Material.SmoothPlastic
	belly.Anchored = true
	belly.CanCollide = false
	belly.Parent = model

	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye" .. (side < 0 and "L" or "R")
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.7, 0.7, 0.7)
		eye.Position = position + Vector3.new(side * char.size * 0.22, char.size * 0.72, char.size * 0.5)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = model
		local pupil = Instance.new("Part")
		pupil.Name = "Pupil" .. (side < 0 and "L" or "R")
		pupil.Shape = Enum.PartType.Ball
		pupil.Size = Vector3.new(0.35, 0.35, 0.35)
		pupil.Position = position + Vector3.new(side * char.size * 0.22, char.size * 0.72, char.size * 0.5 + 0.3)
		pupil.Color = Color3.fromRGB(20, 20, 20)
		pupil.Anchored = true
		pupil.CanCollide = false
		pupil.Parent = model
	end

	-- Signature accessory, built from parts.
	local acc = Instance.new("Folder")
	acc.Name = "Accessory"
	acc.Parent = model
	local top = position + Vector3.new(0, char.size + 0.4, 0)
	if char.accessory == "TopHat" then
		local brim = Instance.new("Part")
		brim.Name = "HatBrim"
		brim.Size = Vector3.new(char.size * 0.9, 0.3, char.size * 0.9)
		brim.Position = top
		brim.Color = Color3.fromRGB(30, 30, 35)
		brim.Anchored = true
		brim.CanCollide = false
		brim.Parent = acc
		local crown = Instance.new("Part")
		crown.Name = "HatCrown"
		crown.Size = Vector3.new(char.size * 0.55, 1.4, char.size * 0.55)
		crown.Position = top + Vector3.new(0, 0.8, 0)
		crown.Color = Color3.fromRGB(30, 30, 35)
		crown.Anchored = true
		crown.CanCollide = false
		crown.Parent = acc
	elseif char.accessory == "Glasses" then
		for _, side in ipairs({ -1, 1 }) do
			local lens = Instance.new("Part")
			lens.Name = "Lens" .. (side < 0 and "L" or "R")
			lens.Shape = Enum.PartType.Cylinder
			lens.Size = Vector3.new(0.3, 1.1, 1.1)
			lens.CFrame = CFrame.new(position + Vector3.new(side * char.size * 0.22, char.size * 0.72, char.size * 0.5 + 0.2)) * CFrame.Angles(0, 0, math.pi / 2)
			lens.Color = Color3.fromRGB(20, 20, 25)
			lens.Anchored = true
			lens.CanCollide = false
			lens.Parent = acc
		end
	elseif char.accessory == "Mask" then
		local mask = Instance.new("Part")
		mask.Name = "Mask"
		mask.Size = Vector3.new(char.size * 0.8, 0.8, 0.4)
		mask.Position = position + Vector3.new(0, char.size * 0.72, char.size * 0.5 + 0.1)
		mask.Color = Color3.fromRGB(30, 30, 35)
		mask.Anchored = true
		mask.CanCollide = false
		mask.Parent = acc
	elseif char.accessory == "SailorHat" then
		local hat = Instance.new("Part")
		hat.Name = "SailorHat"
		hat.Size = Vector3.new(char.size * 0.9, 0.5, char.size * 0.9)
		hat.Position = top
		hat.Color = Color3.fromRGB(255, 255, 255)
		hat.Anchored = true
		hat.CanCollide = false
		hat.Parent = acc
	elseif char.accessory == "Headphones" then
		for _, side in ipairs({ -1, 1 }) do
			local cup = Instance.new("Part")
			cup.Name = "Cup" .. (side < 0 and "L" or "R")
			cup.Shape = Enum.PartType.Cylinder
			cup.Size = Vector3.new(0.5, 1.2, 1.2)
			cup.CFrame = CFrame.new(position + Vector3.new(side * (char.size * 0.5 + 0.3), char.size * 0.7, 0)) * CFrame.Angles(0, 0, math.pi / 2)
			cup.Color = Color3.fromRGB(255, 60, 120)
			cup.Anchored = true
			cup.CanCollide = false
			cup.Parent = acc
		end
		local band = Instance.new("Part")
		band.Name = "Band"
		band.Size = Vector3.new(char.size + 0.6, 0.4, 0.4)
		band.Position = top + Vector3.new(0, 0.2, 0)
		band.Color = Color3.fromRGB(40, 40, 50)
		band.Anchored = true
		band.CanCollide = false
		band.Parent = acc
	elseif char.accessory == "Cape" then
		local cape = Instance.new("Part")
		cape.Name = "Cape"
		cape.Size = Vector3.new(char.size * 0.9, char.size * 1.1, 0.3)
		cape.Position = position + Vector3.new(0, char.size * 0.45, -char.size * 0.55)
		cape.Color = Color3.fromRGB(160, 20, 40)
		cape.Anchored = true
		cape.CanCollide = false
		cape.Parent = acc
	elseif char.accessory == "CoffeeCup" then
		local cup = Instance.new("Part")
		cup.Name = "CoffeeCup"
		cup.Shape = Enum.PartType.Cylinder
		cup.Size = Vector3.new(1.2, 1, 1)
		cup.CFrame = CFrame.new(position + Vector3.new(char.size * 0.55, char.size * 0.4, char.size * 0.3)) * CFrame.Angles(0, 0, math.pi / 2)
		cup.Color = Color3.fromRGB(255, 255, 255)
		cup.Anchored = true
		cup.CanCollide = false
		cup.Parent = acc
	elseif char.accessory == "Monocle" then
		local mono = Instance.new("Part")
		mono.Name = "Monocle"
		mono.Shape = Enum.PartType.Cylinder
		mono.Size = Vector3.new(0.2, 1.2, 1.2)
		mono.CFrame = CFrame.new(position + Vector3.new(char.size * 0.22, char.size * 0.72, char.size * 0.5 + 0.25)) * CFrame.Angles(0, 0, math.pi / 2)
		mono.Color = Color3.fromRGB(255, 215, 0)
		mono.Material = Enum.Material.Metal
		mono.Anchored = true
		mono.CanCollide = false
		mono.Parent = acc
	elseif char.accessory == "VoidAura" then
		local aura = Instance.new("Part")
		aura.Name = "VoidAura"
		aura.Shape = Enum.PartType.Ball
		aura.Size = Vector3.new(char.size * 1.8, char.size * 1.8, char.size * 1.8)
		aura.Position = position + Vector3.new(0, char.size * 0.55, 0)
		aura.Color = Color3.fromRGB(140, 80, 255)
		aura.Material = Enum.Material.Neon
		aura.Transparency = 0.7
		aura.Anchored = true
		aura.CanCollide = false
		aura.Parent = acc
	elseif char.accessory == "RocketScooter" then
		local deck = Instance.new("Part")
		deck.Name = "ScooterDeck"
		deck.Size = Vector3.new(1, 0.4, char.size * 1.2)
		deck.Position = position + Vector3.new(0, 0.4, 0)
		deck.Color = Color3.fromRGB(220, 60, 60)
		deck.Material = Enum.Material.Metal
		deck.Anchored = true
		deck.CanCollide = false
		deck.Parent = acc
		local flame = Instance.new("Part")
		flame.Name = "RocketFlame"
		flame.Shape = Enum.PartType.Ball
		flame.Size = Vector3.new(1.2, 1.2, 1.2)
		flame.Position = position + Vector3.new(0, 0.6, -char.size * 0.7)
		flame.Color = Color3.fromRGB(255, 160, 40)
		flame.Material = Enum.Material.Neon
		flame.Anchored = true
		flame.CanCollide = false
		flame.Parent = acc
	end

	-- Mutation tint: a glowing ring under the character.
	if mutation ~= "Normal" then
		local ring = Instance.new("Part")
		ring.Name = "MutationRing"
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.4, char.size * 1.4, char.size * 1.4)
		ring.CFrame = CFrame.new(position + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		ring.Color = mut.color
		ring.Material = Enum.Material.Neon
		ring.Anchored = true
		ring.CanCollide = false
		ring.Parent = model
	end

	model.PrimaryPart = root
	return model
end

return WorldBuilder
