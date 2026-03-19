-- @ScriptType: LocalScript
-- LocalScript: CustomShiftLock
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local KEYS = "LeftAlt"
local ICON_ID = "rbxassetid://116526467772325"
local player = Players.LocalPlayer

-- Access MouseLockController and set custom key
local mouseLockController = player
	:WaitForChild("PlayerScripts")
	:WaitForChild("PlayerModule")
	:WaitForChild("CameraModule")
	:WaitForChild("MouseLockController")

local obj = mouseLockController:FindFirstChild("BoundKeys")
if obj then
	obj.Value = KEYS
else
	obj = Instance.new("StringValue")
	obj.Name = "BoundKeys"
	obj.Value = KEYS
	obj.Parent = mouseLockController
end

-- Wait until character is loaded, then set the icon
local function setShiftLockIcon()
	StarterGui:SetCore("SetShiftLockIcon", ICON_ID)
end

if player.Character then
	setShiftLockIcon()
else
	player.CharacterAdded:Connect(function()
		-- Delay one frame to ensure the ShiftLock GUI exists
		RunService.RenderStepped:Wait()
		setShiftLockIcon()
	end)
end