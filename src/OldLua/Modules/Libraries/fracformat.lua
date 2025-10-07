return function (fu)
    local sign = ""
    if fu < 0 then
        sign = "-"
        fu = -fu
    end
    local whole = FixedRound(fu)/FU
    if whole <= 99 then
        return sign .. tostring(whole) .. "FU"
    elseif whole <= 999 then
        return sign .. string.format("%.2f", fu/1000) .. "kFU"
    elseif whole <= 9999 then
        return sign .. string.format("%.1f", fu/1000) .. "kFU"
    else
        return sign .. string.format("%.0f", fu/1000) .. "kFU"
    end
end