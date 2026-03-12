-- @ScriptType: ModuleScript
local SlideModule = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RunConfig = require(game.ReplicatedStorage.RunConfig)

local slideActive = false

-- ustawienia slajdu
local slideMultiplier = 0.25  -- ile razy szybciej niż aktualny sprint
local deceleration = 30      -- jak szybko prędkość spada (units/sec^2)

function SlideModule:init()
	local plr = Players.LocalPlayer
	local char = plr.Character or plr.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")

	UIS.InputBegan:Connect(function(input, e)
		if e then return end
		if input.KeyCode == Enum.KeyCode.C then
			if slideActive then return end
			if not RunConfig.Sprinting then return end

			slideActive = true

			local direction = root.CFrame.LookVector
			local currentSpeed = humanoid.WalkSpeed * slideMultiplier

			local conn
			conn = RunService.RenderStepped:Connect(function(delta)
				if currentSpeed <= 0 then
					conn:Disconnect()
					slideActive = false
					return
				end

				-- przesuwanie gracza w kierunku slajdu
				root.CFrame = root.CFrame + direction * currentSpeed * delta

				-- stopniowe zmniejszanie prędkości
				currentSpeed = currentSpeed - deceleration * delta
				if currentSpeed < 0 then currentSpeed = 0 end
			end)
		end
	end)
end

return SlideModule
--kevin