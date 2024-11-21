local copy = FangsHeist.require "Modules/Libraries/copy"
local VWarp = FangsHeist.require "Modules/Libraries/vwarp"

-- Fang's Heist TaLKing Fang
freeslot("sfx_fhtlkf")

local patches = {}
local get_patch = function(v, patch)
	if not patches[patch] then
		patches[patch] = v.cachePatch(patch) or v.cachePatch("MISSING")
	end

	return patches[patch]
end

local BOXSIZE = 150
local SLIDEAMT = 15

local function isInvisChar(char)
    local byte = string.byte(char, 1, 1)
    if not byte then
        return false
    end
    if byte >= 0x80 and byte <= 0x8F then
        return true
    end
    return false
end

local snap = V_SNAPTOBOTTOM|V_SNAPTORIGHT
local DIALOGUE;
DIALOGUE = {
    tick = function ()
        if leveltime == 10 then
            DIALOGUE.startDialogue({
                icon = "FH_DIALOGUE_FANG_DEFAULT",
                text = "hey yo! i want you to\ngimme some stuff,\nalright?"
            })
        end

        if leveltime <= 1 then return end

        local ds = DIALOGUE.state
        if not ds then return end

        ds.textprogbeat = $ + 1
        if ds.textprogress >= #(ds.text) then
            if ds.textprogbeat > (ds.next and TICRATE*2 or TICRATE*3) then
                if ds.next then
                    DIALOGUE.startDialogue(ds.next)
                else
                    if ds.slide <= SLIDEAMT then
                        ds.slide = $ + 2
                    else
                        DIALOGUE.state = nil
                    end
                end
            end
        elseif ds.slide < SLIDEAMT/2
            while isInvisChar(string.sub(ds.text, ds.textprogress+1, ds.textprogress+1)) do
                ds.textprogress = $ + 1
            end
            local thisChar = string.sub(ds.text, ds.textprogress, ds.textprogress)
            local nextCharBeat = 2
            if thisChar == "!" or thisChar == "." or thisChar == "?" then
                nextCharBeat = 11
            end
            if thisChar == "," then
                nextCharBeat = 6
            end
            if ds.textprogbeat >= nextCharBeat then
                ds.textprogbeat = 0
                ds.textprogress = $ + 1
                S_StartSound(nil, sfx_fhtlkf)
            end
        end
        ds.slide = max(0, $-1)
    end,
    state = nil,
    startDialogue = function (prompt)
        DIALOGUE.state = {
            icon = prompt.icon or "FH_DIALOGUE_FANG_DEFAULT",
            text = prompt.text or "hi\nmom\nlol",
            next = prompt.next,
            textprogress = 0,
            textprogbeat = 0,
            slide = SLIDEAMT
        }
    end,
    drawhud = function (truev)
        local ds = DIALOGUE.state
        if not ds then return end
        --[[@type videolib]]
        local v = VWarp(truev, {
            xoffset = (DIALOGUE.state.slide*DIALOGUE.state.slide)*FU,
            yoffset = -8*FU
        })
		local diag_box = get_patch(truev, "FH_DIALOGUE_BOX_BG")
		local diag_outline = get_patch(truev, "FH_DIALOGUE_BOX_OUTLINE")

        v.draw(320-BOXSIZE, 200, diag_box, V_50TRANS|snap)
        v.draw(320-BOXSIZE, 200, diag_outline, snap)

        local talking = (ds.textprogress <= #(ds.text)) and (ds.textprogbeat <= 0)
        local avatar = get_patch(truev, ds.icon+(talking and "2" or "1"))

        v.draw(319, 199, avatar)
        v.drawString(
            320-BOXSIZE+6, 200-40+4,
            string.sub(ds.text, 1, ds.textprogress),
            V_SNAPTOBOTTOM|V_ALLOWLOWERCASE|snap,
            "thin"
        )
    end
}

return DIALOGUE