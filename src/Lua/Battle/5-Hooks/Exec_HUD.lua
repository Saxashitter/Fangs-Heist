local B = CBW_Battle
local CV = B.Console
local CP = B.ControlPoint
local A = B.Arena
local D = B.Diamond
local Bb = B.Battleball
local F = B.CTF
local PR = CBW_PowerCards

//Game HUD
hud.add(function(...)
	if B.GameHudEnabled()
		B.ActionHUD(...)
		B.ShieldStockHUD(...)
		CP.HUD(...)
		D.HUD(...)
		Bb.HUD(...)
		F.HUD(...)
		B.PreRoundHUD(...)
		A.WaitJoinHUD(...)
		A.HUD(...)
		B.PinchHUD(...)
		A.RevengeHUD(...)
		A.GameSetHUD(...)
		B.HitCounterHUD(...)
		B.SpectatorControlHUD(...)
		B.HordeHUD(...)
		PR.ItemHUD(...)
		PR.EventHUD(...)
	end
	B.VersusHUD(...)
	B.DebugHUD(...)
	PR.DebugHUD(...)
end, "game")

//Title HUD
hud.add(B.TitleHUD, "title")