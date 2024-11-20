local copy = FangsHeist.require "Modules/Libraries/copy"

-- Fang's Heist TaLKing Fang
freeslot("sfx_fhtlkf")

local BOXSIZE = 200

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

local DIALOUGE;
DIALOUGE = {
    tick = function ()
        if leveltime == 350 then
            DIALOUGE.startDialouge({
                icon = "FH_DIALOUGE_FANG_DEFAULT",
                text = "hey yo! i want you to\ngimme some stuff,\nalright?"
            })
        end
        if leveltime <= 1 then return end
        if not DIALOUGE.state then return end
        local ds = DIALOUGE.state
        ds.textprogbeat = $ + 1
        if ds.textprogress >= #(ds.text) then
            if ds.textprogbeat > (ds.next and TICRATE*2 or TICRATE*3) then
                if ds.next then
                    DIALOUGE.startDialouge(ds.next)
                else
                    DIALOUGE.state = nil
                end
            end
        else
            while isInvisChar(string.sub(ds.text, ds.textprogress+1, ds.textprogress+1)) do
                ds.textprogress = $ + 1
            end
            local thisChar = string.sub(ds.text, ds.textprogress, ds.textprogress)
            local nextCharBeat = 1
            if thisChar == "!" or thisChar == "." or thisChar == "?" then
                nextCharBeat = 11
            end
            if thisChar == "," then
                nextCharBeat = 6
            end
            if ds.textprogbeat >= nextCharBeat then
                ds.textprogbeat = 0
                ds.textprogress = $ + 1
                ds.voice = true
                S_StartSound(nil, sfx_fhtlkf)
            end
        end
    end,
    state = nil,
    startDialouge = function (prompt)
        DIALOUGE.state = {
            icon = prompt.icon or "FH_DIALOUGE_FANG_DEFAULT",
            text = prompt.text or "hi\nmom\nlol",
            next = prompt.next,
            textprogress = 1,
            textprogbeat = 0,
            slide = 15,
            voice = false
        }
    end,
    --[[@param v videolib]]
    drawhud = function (v)
        if not DIALOUGE.state then return end
        local ds = DIALOUGE.state
        v.draw(320-BOXSIZE, 200, v.cachePatch("FH_DIALOUGE_BOX_BG"), V_50TRANS)
        v.draw(320-BOXSIZE, 200, v.cachePatch("FH_DIALOUGE_BOX_OUTLINE"))
        local talking = (ds.textprogress <= #(ds.text)) and (ds.textprogbeat <= 0)
        local avatar = v.cachePatch(ds.icon + (talking and "2" or "1"))
        v.draw(319, 199, avatar)
        v.drawString(
            320-BOXSIZE+6, 200-40+4,
            string.sub(ds.text, 1, ds.textprogress),
            V_SNAPTOBOTTOM|V_ALLOWLOWERCASE,
            "thin"
        )
    end
}

-- test
hud.add(DIALOUGE.drawhud)
addHook("ThinkFrame", DIALOUGE.tick)

return DIALOUGE