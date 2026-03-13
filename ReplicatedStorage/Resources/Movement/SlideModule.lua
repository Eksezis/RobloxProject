-- @ScriptType: ModuleScript
local SlideModule = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RunConfig = require(game.ReplicatedStorage.RunConfig)

local slideActive = false
local cooldownActive = false

-- ustawienia slajdu
local slideMultiplier = .8  -- ile razy szybciej niż aktualny sprint
local deceleration = 50      -- jak szybko prędkość spada (units/sec^2)

-- ustawienia slowdown
local slowDownMultiplier = 0.5   --  wolniej po slajdzie
local slowDownDuration = 2.0     -- jak długo trwa slowdown (sekundy)
local cooldownTime = 5          -- cooldown w sekundach

function SlideModule:init()
	
	local plr = Players.LocalPlayer
	local char = plr.Character or plr.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")
	local originalHipHeight = humanoid.HipHeight
	
	UIS.InputBegan:Connect(function(input, e)
		if e then return end
		if input.KeyCode == Enum.KeyCode.C then
			if slideActive then return end
			if cooldownActive then return end
			if RunConfig.Crouching then return end
			if not RunConfig.Sprinting then return end

			slideActive = true
			RunConfig.Sliding = true
			-- zmniejsz hitbox żeby zmieścić się w niskich miejscach
			humanoid.HipHeight = originalHipHeight * 0.25
			cooldownActive = true

			-- zapisz oryginalną prędkość
			local originalWalkSpeed = humanoid.WalkSpeed

			local direction = root.CFrame.LookVector
			local currentSpeed = humanoid.WalkSpeed * slideMultiplier

			local conn
			conn = RunService.RenderStepped:Connect(function(delta)
				if currentSpeed <= 0 then
					conn:Disconnect()
					slideActive = false
					RunConfig.Sliding = false
					-- przywróć hitbox
					humanoid.HipHeight = originalHipHeight

					-- zastosuj slowdown po zakończeniu slajdu
					humanoid.WalkSpeed = originalWalkSpeed * slowDownMultiplier

					-- przywróć normalną prędkość po czasie
					task.delay(slowDownDuration, function()
						if humanoid and humanoid.Parent then
							humanoid.WalkSpeed = originalWalkSpeed
						end
					end)

					-- cooldown
					task.delay(cooldownTime, function()
						cooldownActive = false
					end)
					return
				end

				-- stopniowe zmniejszanie prędkości
				currentSpeed = currentSpeed - deceleration * delta
				if currentSpeed < 0 then currentSpeed = 0 end
			end)
		end
	end)
end

return SlideModule
--kevin