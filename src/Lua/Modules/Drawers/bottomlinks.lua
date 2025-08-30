/*
Discord Link code has Evolved to an Bottom Links
(bad pun lmao.)
*/
local module = {}
local FH = FangsHeist
local linknum = 1
local linktics = 0

function module.init()
	linknum = 1
	linktics = 0
end

FH.Links = {} --Made a Table to add Things in Tab Scores
FH.AddLink = function(txtanchor,url,color)
	table.insert(FH.Links,{text=txtanchor,linkurl=url,linkcol=color})
end

function module.draw(v)
	if not (#FH.Links) then return end

	linktics = $+1

	local time = FixedAngle(ease.linear(min(FixedDiv(linktics%250,250),FU),0,180)*FU)
	local sine = sin(time)
	local tic = min(FixedDiv(abs(sine),FU/10),FU)
	local trans = ease.linear(tic,10,0)
	local y = ease.outquad(tic,210*FU,191*FU)

	if linktics%250 == 0 then
		if linknum >= (#FH.Links) then
			linknum = 1
			linktics = 0
		else
			linknum = $+1
		end
	end

	local d = FH.Links[linknum]

	if trans != 10 then
		local tex = string.format("%s: %s",d.text,d.linkurl)
		local stringscale = ease.linear(max(0,min(FixedDiv(tex:len(),50),FU)),tofixed("1.042"),tofixed("0.832"))
		FH.DrawString(v,160*FU,y,stringscale,tex,"FHTXT","center",V_SNAPTOBOTTOM|trans*V_10TRANS,v.getStringColormap(d.linkcol))
	end
end
FH.BottomLinkHUD = module.draw
return module,"scores"