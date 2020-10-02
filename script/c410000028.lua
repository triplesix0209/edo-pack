-- The Palladium Oracles
Duel.LoadScript("util.lua")
local s, id = GetID()

s.listed_names = {
    71703785, CARD_DARK_MAGICIAN, 42006475, CARD_DARK_MAGICIAN_GIRL
}

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- link summon
    Link.AddProcedure(c, s.lnkfilter, 2, 2, s.lnkcheck)

    -- code
    local code1 = Effect.CreateEffect(c)
    code1:SetType(EFFECT_TYPE_SINGLE)
    code1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    code1:SetCode(EFFECT_ADD_CODE)
    code1:SetValue(CARD_DARK_MAGICIAN_GIRL)
    c:RegisterEffect(code1)
    local code2 = code1:Clone()
    code2:SetValue(CARD_DARK_MAGICIAN)
    c:RegisterEffect(code2)

    -- attribute
    local attribute = Effect.CreateEffect(c)
    attribute:SetType(EFFECT_TYPE_SINGLE)
    attribute:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    attribute:SetCode(EFFECT_ADD_ATTRIBUTE)
    attribute:SetValue(ATTRIBUTE_DARK)
    c:RegisterEffect(attribute)

    -- indes
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(LOCATION_MZONE, 0)
    e1:SetTarget(function(e, c)
        return c == e:GetHandler() or
                   (c:IsLevelAbove(6) and c:IsRace(RACE_SPELLCASTER))
    end)
    e1:SetValue(1)
    c:RegisterEffect(e1)

    -- atk up
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetCode(EFFECT_SET_ATTACK_FINAL)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.e2con)
    e2:SetValue(s.e2val)
    c:RegisterEffect(e2)

    -- draw
    local e3reg = Effect.CreateEffect(c)
    e3reg:SetType(EFFECT_TYPE_CONTINUOUS + EFFECT_TYPE_FIELD)
    e3reg:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e3reg:SetCode(EVENT_CHAINING)
    e3reg:SetRange(LOCATION_MZONE)
    e3reg:SetOperation(aux.chainreg)
    c:RegisterEffect(e3reg)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 0))
    e3:SetCategory(CATEGORY_DRAW)
    e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_CHAIN_SOLVING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(s.e3con)
    e3:SetTarget(s.e3tg)
    e3:SetOperation(s.e3op)
    c:RegisterEffect(e3)

    -- special summon
    local e4 = Effect.CreateEffect(c)
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_DESTROYED)
    e4:SetTarget(s.e4tg)
    e4:SetOperation(s.e4op)
    c:RegisterEffect(e4)
end

function s.lnkfilter(c)
    return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_SPELLCASTER)
end

function s.lnkcheck(g, sc, sumtype, tp)
    return g:IsExists(Card.IsSummonCode, 1, nil, sc, sumtype, tp, 71703785,
                      CARD_DARK_MAGICIAN, 42006475, CARD_DARK_MAGICIAN_GIRL)
end

function s.e2con(e)
    local ph = Duel.GetCurrentPhase()
    local bc = e:GetHandler():GetBattleTarget()
    return (ph == PHASE_DAMAGE or ph == PHASE_DAMAGE_CAL) and bc and
               bc:IsAttribute(ATTRIBUTE_DARK)
end

function s.e2val(e, c) return e:GetHandler():GetAttack() * 2 end

function s.e3con(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    return re:IsActiveType(TYPE_SPELL + TYPE_TRAP) and c:GetFlagEffect(1) > 0
end

function s.e3tg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsPlayerCanDraw(tp, 1) end

    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(1)
    Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
end

function s.e3op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER,
                                   CHAININFO_TARGET_PARAM)
    if Duel.Draw(p, d, REASON_EFFECT) == 0 then return end

    local tc = Duel.GetOperatedGroup():GetFirst()
    local b1 = tc:IsType(TYPE_MONSTER) and
                   Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and
                   tc:IsCanBeSpecialSummoned(e, tp, tp, false, false)
    local b2 = tc:IsType(TYPE_SPELL + TYPE_TRAP) and tc:IsSSetable()

    if b1 and Duel.SelectYesNo(tp, 5) then
        Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP)
    elseif b2 and Duel.SelectYesNo(tp, 1153) then
        Duel.SSet(tp, tc, tp, false)

        local ec1 = Effect.CreateEffect(c)
        ec1:SetType(EFFECT_TYPE_SINGLE)
        if tc:IsType(TYPE_QUICKPLAY) then
            ec1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
        elseif tc:IsType(TYPE_TRAP) then
            ec1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
        end
        ec1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
        ec1:SetReset(RESET_EVENT + RESETS_STANDARD)
        tc:RegisterEffect(ec1)
    end
end

function s.e4filter(c, e, tp, code1, code2)
    return c:IsCode(code1, code2) and
               c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.e4tg(e, tp, eg, ep, ev, re, r, rp, chk)
    local loc = LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE
    if chk == 0 then
        return not Duel.IsPlayerAffectedByEffect(tp, CARD_BLUEEYES_SPIRIT) and
                   Duel.GetLocationCount(tp, LOCATION_MZONE) > 1 and
                   Duel.IsExistingMatchingCard(s.e4filter, tp, loc, 0, 1, nil,
                                               e, tp, 71703785,
                                               CARD_DARK_MAGICIAN) and
                   Duel.IsExistingMatchingCard(s.e4filter, tp, loc, 0, 1, nil,
                                               e, tp, 42006475,
                                               CARD_DARK_MAGICIAN_GIRL)
    end

    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 2, tp, loc)
end

function s.e4op(e, tp, eg, ep, ev, re, r, rp)
    local loc = LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE
    if Duel.IsPlayerAffectedByEffect(tp, CARD_BLUEEYES_SPIRIT) or
        Duel.GetLocationCount(tp, LOCATION_MZONE) < 2 then return end

    local g1 = Duel.GetMatchingGroup(aux.NecroValleyFilter(s.e4filter), tp, loc,
                                     0, nil, e, tp, 71703785, CARD_DARK_MAGICIAN)
    local g2 = Duel.GetMatchingGroup(aux.NecroValleyFilter(s.e4filter), tp, loc,
                                     0, nil, e, tp, 42006475,
                                     CARD_DARK_MAGICIAN_GIRL)

    if #g1 > 0 and #g2 > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local sg1 = g1:Select(tp, 1, 1, nil)
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local sg2 = g2:Select(tp, 1, 1, nil)
        sg1:Merge(sg2)
        Duel.SpecialSummon(sg1, 0, tp, tp, true, false, POS_FACEUP)
    end
end
