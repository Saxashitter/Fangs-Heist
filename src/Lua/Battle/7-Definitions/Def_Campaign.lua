/*
	CBW_Battle.Campaign is a table which stores match info for all campaign stages.
	Displayed campaign length is determined by amount of numbered entries in the table, therefore all campaign stages be in a numbered sequence.
	If BattleCampaign is not set or is out of table bounds, or the specified entry is otherwise missing,
	the stage progress HUD will not appear on the VS screen, and the opponent will be selected at random.
	Extra stages (e.g. for side game modes like Multi Man Melee) can be defined by using a string instead of a number as the table index. This will not affect displayed campaign length.
	Mapheaders should set BattleCampaign = #, where # is the index of the table entry.
	
	----
	hudbonus - Must be a graphic name. If specified, displays the specified graphic in the center of the HUD instead of character VS elements.
	hudname - VS text to display. Will be generated automatically if unspecified.
	hudicon - Skin name for HUD progress bar. Allows special arguments. If unspecified, references stage fighters data.
			If the string is preceded by a "~", a graphic name can be specified instead of skin name.
			If "?", this displays a question mark graphic (~QUESTION)
			If "!" or bonus is specified, this displays an exclamation mark graphic (~EXCLAIM)
			If "#", this displays the Battle icon graphic (~BATTLE16)
			If there was an error parsing the hudicon, it will display a warning graphic (~ERROR16)
	hudiconcolor - Determines color to use for hudicon. If unspecified, gets default from hudicon skin, then fighter data.
	hudiconcolormap - Determines colormap translation method to use for hudicon. If unspecified, references fighter data.
	intromusic - BGM to play on the VS intro screen. Defaults to _VS
	teamsize - Specifies how many enemy players should be on the field at a time.
	fighters - Table storing all bots to spawn and their respective settings.
		skin - Specify skin name or number. Also accepts special arguments.
			?: sets random. Attempts to choose skins not already chosen for the current match. 
				Note: If duplicates are not desired, but some bot characters are deterministic, then it is recommended that the deterministic characters be listed first in the fighters table, so that other fighters do not choose the same character first.
			=: character will be equal to Player 1 skin (single player only; random otherwise)
		ally - boolean
		color - defaults to skin's prefcolor
		flags - battlespflags to use for the player object. Defaults to 0
*/

/*
	NOTE: This lump only contains fallback stage definitions. See battle_campaign.pk3 for all other campaign definitions.
*/


--local B = CBW_Battle
--local C = B.Campaign
--local Nf = NavFunc

--Default
--C["default"] = {
--	fighters = {
--		{skin = "?"}
	}
}
--C["bonus"] = {
--	hudicon = "~BLUSP16",
--	hudbonus = "~BLUSP128",
--	hudname = "Get blue spheres !!",
--	fighters = {}
}


--Error Check
-- C["badentry"] = {
-- 	hudicon = {},
-- 	hudiconcolor = true,
-- 	hudiconcolormap = false,
-- 	teamsize = "not a number",
-- 	fighters = "not a table"
-- }
-- C["badentry2"] = {
-- 	bonus = {},
-- 	fighters = {
-- 		skin = "fang"
-- 	}
-- }

--Bonus game
-- C[6] = {
-- 	hudicon = "~TARGET16",
-- 	hudbonus = "~TARGT128",
-- 	hudname = "Break the targets !!",
-- 	hudicon = "~BLUSP16",
-- 	hudbonus = "~BLUSP128",
-- 	hudname = "Get blue spheres !!"
-- 	hudicon = "~STPST16",
-- 	hudbonus = "~STPST128",
-- 	hudname = "Reach the starposts !!"
-- 	hudicon = "~RACE16",
-- 	hudbonus = "~RACE128",
-- 	hudname = "Race to the finish !!"
-- }