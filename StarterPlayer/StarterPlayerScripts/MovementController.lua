-- @ScriptType: LocalScript
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local DashModule = require(game.ReplicatedStorage.Resources.Movement.DashModule)
local SprintModule = require(game.ReplicatedStorage.Resources.Movement.SprintModule)

local plr = Players.LocalPlayer

local function onCharacterAdded(char)
	local humanoid = char:WaitForChild("Humanoid")

	UIS.InputBegan:Connect(function(i,e)
		if e then return end

		if i.KeyCode == Enum.KeyCode.Q then
			DashModule:Dash(char)
		end

		if i.KeyCode == Enum.KeyCode.LeftShift then
			SprintModule:StartSprint(humanoid)
		end
	end)

	UIS.InputEnded:Connect(function(i,e)
		if e then return end

		if i.KeyCode == Enum.KeyCode.LeftShift then
			SprintModule:StopSprint(humanoid)
		end
	end)
end

-- Handle current character
if plr.Character then
	onCharacterAdded(plr.Character)
end

-- Handle future characters
plr.CharacterAdded:Connect(onCharacterAdded)