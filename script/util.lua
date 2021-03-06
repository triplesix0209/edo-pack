-- init
if not aux.UtilityProcedure then aux.UtilityProcedure = {} end
if not Utility then Utility = aux.UtilityProcedure end

-- function
function Utility.RegisterGlobalEffect(c, eff, filter, param1, param2, param3,
                                      param4, param5)
    local g = Duel.GetMatchingGroup(filter, c:GetControler(), LOCATION_ALL, 0,
                                    nil, param1, param2, param3, param4, param5)
    for tc in aux.Next(g) do tc:RegisterEffect(eff:Clone()) end
end

function Utility.CountFreePendulumZones(tp)
    local count = 0
    if Duel.CheckLocation(tp, LOCATION_PZONE, 0) then count = count + 1 end
    if Duel.CheckLocation(tp, LOCATION_PZONE, 1) then count = count + 1 end
    return count
end

function Utility.DeckEditAddCardToDeck(tp, code, condition_code)
    if Duel.IsExistingMatchingCard(Card.IsOriginalCode, tp, LOCATION_ALL, 0, 1,
                                   nil, code) then return end
    if condition_code ~= nil and
        not Duel.IsExistingMatchingCard(Card.IsOriginalCode, tp, LOCATION_ALL,
                                        0, 1, nil, condition_code) then
        return
    end
    
    Duel.SendtoDeck(Duel.CreateToken(tp, code), tp, 2, REASON_RULE)
end

function Utility.DeckEditAddCardToExtraFaceup(tp, code, condition_code)
    if Duel.IsExistingMatchingCard(Card.IsOriginalCode, tp, LOCATION_ALL, 0, 1,
                                   nil, code) then return end
    if condition_code ~= nil and
        not Duel.IsExistingMatchingCard(Card.IsOriginalCode, tp, LOCATION_ALL,
                                        0, 1, nil, condition_code) then
        return
    end
    
    Duel.SendtoExtraP(Duel.CreateToken(tp, code), tp, REASON_RULE)
end

function Utility.PlaceToPZoneWhenDestroyed(c, tg, preop, postop)
    local eff = Effect.CreateEffect(c)
    eff:SetDescription(1160)
    eff:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    eff:SetProperty(EFFECT_FLAG_DELAY)
    eff:SetCode(EVENT_DESTROYED)
    eff:SetCondition(function(e, tp, eg, ep, ev, re, r, rp)
        return e:GetHandler():IsPreviousLocation(LOCATION_MZONE) and
                   e:GetHandler():IsFaceup()
    end)
    eff:SetTarget(function(e, tp, eg, ep, ev, re, r, rp, chk)
        if tg then
            return tg(e, tp, eg, ep, ev, re, r, rp, chk)
        else
            if chk == 0 then
                return Duel.CheckLocation(tp, LOCATION_PZONE, 0) or
                           Duel.CheckLocation(tp, LOCATION_PZONE, 1)
            end
        end
    end)
    eff:SetOperation(function(e, tp, eg, ep, ev, re, r, rp)
        if preop then preop(e, tp, eg, ep, ev, re, r, rp) end

        local c = e:GetHandler()
        if not c:IsRelateToEffect(e) then return end
        if not Duel.CheckLocation(tp, LOCATION_PZONE, 0) and
            not Duel.CheckLocation(tp, LOCATION_PZONE, 1) then
            return false
        end
        Duel.MoveToField(c, tp, tp, LOCATION_PZONE, POS_FACEUP, true)

        if postop then postop(e, tp, eg, ep, ev, re, r, rp) end
    end)
    c:RegisterEffect(eff)
end

function Utility.IsSetCard(c, ...)
    local setcodes = {...}
    for _, setcode in ipairs(setcodes) do
        if c:IsSetCard(setcode) then return true end
    end

    return false
end

function Utility.IsSetCardListed(c, ...)
    if not c.listed_series then return false end

    local setcodes = {...}
    for _, setcode in ipairs(setcodes) do
        for _, seriecode in ipairs(c.listed_series) do
            if setcode == seriecode then return true end
        end
    end

    return false
end

function Utility.HintCard(code) Duel.Hint(HINT_CARD, 0, code) end

function Utility.GainInfinityAtk(root, c)
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetRange(LOCATION_MZONE)
    e1:SetValue(function(e, c)
        local g = Duel.GetMatchingGroup(nil, 0, LOCATION_MZONE, LOCATION_MZONE,
                                        e:GetHandler())

        if #g == 0 then
            return 9999999
        else
            local tg, val = g:GetMaxGroup(Card.GetAttack)
            if val <= 9999999 then
                return 9999999
            else
                return val
            end
        end
    end)
    c:RegisterEffect(e1)

    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e2:SetCode(EVENT_PRE_BATTLE_DAMAGE)
    e2:SetCondition(function(e, tp, eg, ep, ev, re, r, rp)
        return ep ~= tp and e:GetHandler():GetAttack() >= 9999999
    end)
    e2:SetOperation(function(e, tp, eg, ep, ev, re, r, rp)
        Duel.ChangeBattleDamage(ep, Duel.GetLP(ep))
    end)
    c:RegisterEffect(e2)

    aux.GlobalCheck(root, function()
        local e3 = Effect.CreateEffect(c)
        e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
        e3:SetProperty(EFFECT_FLAG_UNCOPYABLE + EFFECT_FLAG_CANNOT_DISABLE +
                           EFFECT_FLAG_IGNORE_IMMUNE)
        e3:SetCode(EVENT_ADJUST)
        e3:SetCondition(function(e, tp, eg, ev, ep, re, r, rp)
            return Duel.IsExistingMatchingCard(AvatarFilter, tp, 0xff, 0xff, 1,
                                               nil)
        end)
        e3:SetOperation(function(e, tp, eg, ev, ep, re, r, rp)
            local g = Duel.GetMatchingGroup(AvatarFilter, tp, 0xff, 0xff, nil)

            g:ForEach(function(c)
                local atktes = {c:GetCardEffect(EFFECT_SET_ATTACK_FINAL)}
                for _, atkte in ipairs(atktes) do
                    if atkte:GetOwner() == c and
                        atkte:IsHasProperty(
                            EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_REPEAT +
                                EFFECT_FLAG_DELAY) then
                        atkte:SetValue(AvatarVal)
                        atkte:SetLabel(9999999)
                    end
                end

                local deftes = {c:GetCardEffect(EFFECT_SET_DEFENSE_FINAL)}
                for _, defte in ipairs(deftes) do
                    if defte:GetOwner() == c and
                        defte:IsHasProperty(
                            EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_REPEAT +
                                EFFECT_FLAG_DELAY) then
                        defte:SetValue(AvatarVal)
                        defte:SetLabel(9999999)
                    end
                end
            end)
        end)
        Duel.RegisterEffect(e3, 0)
    end)
end

function AvatarFilter(c)
    local atktes = {c:GetCardEffect(EFFECT_SET_ATTACK_FINAL)}
    local ae = nil
    local de = nil

    for _, atkte in ipairs(atktes) do
        if atkte:GetOwner() == c and
            atkte:IsHasProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_REPEAT +
                                    EFFECT_FLAG_DELAY) then
            ae = atkte:GetLabel()
        end
    end

    local deftes = {c:GetCardEffect(EFFECT_SET_DEFENSE_FINAL)}
    for _, defte in ipairs(deftes) do
        if defte:GetOwner() == c and
            defte:IsHasProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_REPEAT +
                                    EFFECT_FLAG_DELAY) then
            de = defte:GetLabel()
        end
    end

    return c:IsOriginalCode(21208154) and (ae ~= 9999999 or de ~= 9999999)
end

function AvatarVal(e, c)
    local g = Duel.GetMatchingGroup(function(c)
        return c:IsFaceup() and c:GetCode() ~= 21208154
    end, 0, LOCATION_MZONE, LOCATION_MZONE, nil)

    if #g == 0 then
        return 100
    else
        local tg, val = g:GetMaxGroup(Card.GetAttack)
        if val >= 9999999 then
            return val
        else
            return val + 100
        end
    end
end
