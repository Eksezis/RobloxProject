-- @ScriptType: ModuleScript
local DashModule = {}

local Resources = game.ReplicatedStorage.Resources
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local dashCD = false
local dashTime = 3
local dashDuration = 0.3

function DashModule:init()
	local plr = game.Players.LocalPlayer
	local char = plr.Character or plr.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")

	UIS.InputBegan:Connect(function(i,e)
		if e then return end
		if i.KeyCode == Enum.KeyCode.Q and dashCD == false then

			dashCD = true
			task.delay(dashTime,function()
				dashCD = false
			end)

			local BodyVel = Instance.new("BodyVelocity")
			BodyVel.Parent = hrp
			BodyVel.MaxForce = Vector3.new(1e5,0,1e5)

			local dashDir = "Forward"

			if UIS:IsKeyDown(Enum.KeyCode.S) then
				dashDir = "Back"
			elseif UIS:IsKeyDown(Enum.KeyCode.D) then
				dashDir = "Right"
			elseif UIS:IsKeyDown(Enum.KeyCode.A) then
				dashDir = "Left"
			end

			local start = tick()

			local conn
			conn = RunService.RenderStepped:Connect(function()
				if tick() - start >= dashDuration then
					conn:Disconnect()
					BodyVel:Destroy()
					return
				end

				if dashDir == "Forward" then
					BodyVel.Velocity = hrp.CFrame.LookVector * 60
				elseif dashDir == "Back" then
					BodyVel.Velocity = -hrp.CFrame.LookVector * 60
				elseif dashDir == "Right" then
					BodyVel.Velocity = hrp.CFrame.RightVector * 60
				elseif dashDir == "Left" then
					BodyVel.Velocity = -hrp.CFrame.RightVector * 60
				end
			end)

		end
	end)
end

return DashModule