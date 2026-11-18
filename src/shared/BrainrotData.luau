-- BrainrotData: every character, rarity, mutation and price in Meme Menagerie.
-- Pure data + helpers: no Roblox services are touched here, so this module can be
-- required by the server, the client, and any offline test.
-- All characters, names and art direction are original creations for this game.

local BrainrotData = {}

BrainrotData.RARITIES = {
	Common = { order = 1, color = Color3.fromRGB(180, 180, 180), label = "Common" },
	Rare = { order = 2, color = Color3.fromRGB(80, 170, 255), label = "Rare" },
	Epic = { order = 3, color = Color3.fromRGB(170, 90, 255), label = "Epic" },
	Legendary = { order = 4, color = Color3.fromRGB(255, 190, 40), label = "Legendary" },
	Mythic = { order = 5, color = Color3.fromRGB(255, 70, 120), label = "Mythic" },
	Secret = { order = 6, color = Color3.fromRGB(40, 230, 200), label = "Secret" },
}

-- Mutation roll chances (server rolls once per spawn) and income multipliers.
BrainrotData.MUTATIONS = {
	Normal = { chance = 0.86, multiplier = 1, color = Color3.fromRGB(255, 255, 255), label = "Normal" },
	Golden = { chance = 0.10, multiplier = 2, color = Color3.fromRGB(255, 215, 0), label = "Golden" },
	Diamond = { chance = 0.03, multiplier = 5, color = Color3.fromRGB(120, 220, 255), label = "Diamond" },
	Rainbow = { chance = 0.01, multiplier = 10, color = Color3.fromRGB(255, 120, 220), label = "Rainbow" },
}

-- Every character: an absurd meme-born creature with its own look.
-- body: main colour, belly: second colour, size: studs tall, accessory: what it wears.
-- rate: base dollars per second. cost: what a player pays to take it home.
BrainrotData.CHARACTERS = {
	{
		id = "quacksalot",
		name = "Sir Quacksalot",
		rarity = "Common",
		rate = 5,
		cost = 100,
		weight = 30,
		body = Color3.fromRGB(255, 220, 90),
		belly = Color3.fromRGB(255, 245, 200),
		size = 3,
		accessory = "TopHat",
		blurb = "A duck in a top hat who quacks in cursive.",
	},
	{
		id = "pickle",
		name = "Professor Pickle",
		rarity = "Common",
		rate = 8,
		cost = 250,
		weight = 26,
		body = Color3.fromRGB(90, 180, 80),
		belly = Color3.fromRGB(160, 220, 120),
		size = 3,
		accessory = "Glasses",
		blurb = "Holds a PhD in brine. Grades your base harshly.",
	},
	{
		id = "bandit",
		name = "Banana Bandit",
		rarity = "Rare",
		rate = 20,
		cost = 750,
		weight = 18,
		body = Color3.fromRGB(255, 225, 60),
		belly = Color3.fromRGB(255, 240, 150),
		size = 3,
		accessory = "Mask",
		blurb = "Steals potassium. Leaves a thank-you note.",
	},
	{
		id = "noodle",
		name = "Captain Noodle",
		rarity = "Rare",
		rate = 35,
		cost = 1500,
		weight = 12,
		body = Color3.fromRGB(240, 200, 120),
		belly = Color3.fromRGB(255, 235, 190),
		size = 4,
		accessory = "SailorHat",
		blurb = "Sailed the seven soups. Never al dente, always on time.",
	},
	{
		id = "toaster",
		name = "DJ Toaster",
		rarity = "Epic",
		rate = 70,
		cost = 4000,
		weight = 7,
		body = Color3.fromRGB(200, 200, 210),
		belly = Color3.fromRGB(90, 90, 110),
		size = 3,
		accessory = "Headphones",
		blurb = "Drops the bread. Drops the beat. Same thing.",
	},
	{
		id = "spaghetti",
		name = "Count Spaghetti",
		rarity = "Epic",
		rate = 120,
		cost = 8000,
		weight = 4,
		body = Color3.fromRGB(245, 210, 140),
		belly = Color3.fromRGB(255, 240, 200),
		size = 4,
		accessory = "Cape",
		blurb = "Bleh bleh bleh. Counts your meatballs at night.",
	},
	{
		id = "llama",
		name = "Lord Llama Latte",
		rarity = "Legendary",
		rate = 250,
		cost = 20000,
		weight = 2,
		body = Color3.fromRGB(235, 220, 200),
		belly = Color3.fromRGB(255, 250, 235),
		size = 4,
		accessory = "CoffeeCup",
		blurb = "Foams his own lattes. Judges your foam.",
	},
	{
		id = "frog",
		name = "Sir Reginald Frog",
		rarity = "Legendary",
		rate = 450,
		cost = 40000,
		weight = 1,
		body = Color3.fromRGB(80, 200, 110),
		belly = Color3.fromRGB(200, 240, 170),
		size = 3,
		accessory = "Monocle",
		blurb = "A frog of culture. Ribbits in iambic pentameter.",
	},
	{
		id = "hamster",
		name = "The Void Hamster",
		rarity = "Mythic",
		rate = 900,
		cost = 100000,
		weight = 0.7,
		body = Color3.fromRGB(60, 50, 90),
		belly = Color3.fromRGB(150, 100, 220),
		size = 3,
		accessory = "VoidAura",
		blurb = "Stares into the void. The void stares back, then pays rent.",
	},
	{
		id = "grandma",
		name = "Grandma Turbo",
		rarity = "Secret",
		rate = 2500,
		cost = 300000,
		weight = 0.3,
		body = Color3.fromRGB(190, 150, 220),
		belly = Color3.fromRGB(240, 230, 250),
		size = 4,
		accessory = "RocketScooter",
		blurb = "Bakes cookies at Mach 2. Never lost a race. Never will.",
	},
}

BrainrotData.MAX_SLOTS = 8
BrainrotData.BASE_COUNT = 8
BrainrotData.SPAWN_INTERVAL = 8 -- seconds between spawns on the conveyor
BrainrotData.MAX_WALKERS = 6 -- brainrots wandering the bazaar at once
BrainrotData.WAVE_INTERVAL = 180 -- seconds between tsunami waves
BrainrotData.WAVE_WARNING = 15 -- seconds of warning before a wave
BrainrotData.REBIRTH_BASE_COST = 50000 -- x (rebirths + 1)
BrainrotData.REBIRTH_BONUS = 0.25 -- +25% income per rebirth, forever
BrainrotData.STEAL_LOCK_SECONDS = 60
BrainrotData.STEAL_LOCK_COOLDOWN = 120

function BrainrotData.getCharacter(id)
	for _, char in ipairs(BrainrotData.CHARACTERS) do
		if char.id == id then
			return char
		end
	end
	return nil
end

function BrainrotData.totalWeight()
	local total = 0
	for _, char in ipairs(BrainrotData.CHARACTERS) do
		total += char.weight
	end
	return total
end

-- Weighted random pick, so commons show up often and secrets almost never do.
function BrainrotData.rollCharacter()
	local roll = math.random() * BrainrotData.totalWeight()
	local acc = 0
	for _, char in ipairs(BrainrotData.CHARACTERS) do
		acc += char.weight
		if roll <= acc then
			return char
		end
	end
	return BrainrotData.CHARACTERS[1]
end

function BrainrotData.rollMutation()
	local roll = math.random()
	local acc = 0
	for name, mut in pairs(BrainrotData.MUTATIONS) do
		acc += mut.chance
		if roll <= acc then
			return name
		end
	end
	return "Normal"
end

function BrainrotData.rateFor(char, mutation)
	local mut = BrainrotData.MUTATIONS[mutation] or BrainrotData.MUTATIONS.Normal
	return char.rate * mut.multiplier
end

function BrainrotData.rebirthCost(rebirths)
	return BrainrotData.REBIRTH_BASE_COST * (rebirths + 1)
end

function BrainrotData.rebirthMultiplier(rebirths)
	return 1 + rebirths * BrainrotData.REBIRTH_BONUS
end

function BrainrotData.formatMoney(amount)
	amount = math.floor(amount + 0.5)
	if amount >= 1000000 then
		return string.format("$%.2fM", amount / 1000000)
	elseif amount >= 10000 then
		return string.format("$%.1fK", amount / 1000)
	else
		local s = tostring(amount)
		local out = ""
		while #s > 3 do
			out = "," .. string.sub(s, -3) .. out
			s = string.sub(s, 1, -4)
		end
		return "$" .. s .. out
	end
end

return BrainrotData
