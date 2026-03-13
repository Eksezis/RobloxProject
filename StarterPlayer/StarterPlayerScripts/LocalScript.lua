-- @ScriptType: LocalScript
local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")

player.DevEnableMouseLock = true

-- force shift lock
UIS.MouseBehavior = Enum.MouseBehavior.LockCenter