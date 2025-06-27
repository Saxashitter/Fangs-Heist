local B = CBW_Battle
local Bb = B.Battleball

addHook("MobjThinker",Bb.Thinker,MT_BATTLEBALL)

-- addHook("MobjFuse",function(mo)
-- 	mo.flags = $|MF_SPECIAL
-- 	return true
-- end,MT_BATTLEBALL)