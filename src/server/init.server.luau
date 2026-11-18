-- Meme Menagerie — Brainrot Bazaar: server bootstrap.
-- Creates the RemoteEvents the game uses, then starts the BrainrotService,
-- which builds the world and runs the whole game loop.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local eventNames = { "BuyBrainrot", "StealBrainrot", "Slap", "Rebirth", "LockBase", "GameEvent" }
for _, name in ipairs(eventNames) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end

local BrainrotService = require(script.Parent:WaitForChild("BrainrotService"))
BrainrotService.start()

print("[Meme Menagerie] Brainrot Bazaar is open for business!")
