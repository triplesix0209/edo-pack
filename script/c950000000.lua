-- Supreme Gate
Duel.LoadScript("util.lua")
local s, id = GetID()

s.listed_names = {950000001, 13331639}
s.listed_series = {0x10f8, 0x20f8, 0xf2, 0x46}

function s.initial_effect(c)
    -- activate
    local act = Effect.CreateEffect(c)
    act:SetType(EFFECT_TYPE_ACTIVATE)
    act:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(act)

    -- predraw
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EVENT_PREDRAW)
    e1:SetRange(LOCATION_FZONE)
    e1:SetCountLimit(1)
    e1:SetCondition(s.e1con)
    e1:SetTarget(s.e1tg)
    e1:SetOperation(s.e1op)
    c:RegisterEffect(e1)

    -- pendulum zone protect
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
    e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e2:SetRange(LOCATION_FZONE)
    e2:SetTargetRange(LOCATION_PZONE, 0)
    e2:SetValue(aux.tgoval)
    c:RegisterEffect(e2)

    -- destroy & search
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 0))
    e3:SetCategory(CATEGORY_DESTROY + CATEGORY_TOHAND + CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetRange(LOCATION_FZONE)
    e3:SetCountLimit(1, id)
    e3:SetTarget(s.e3tg)
    e3:SetOperation(s.e3op)
    c:RegisterEffect(e3)

    -- fusion: special summon
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 1))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_SPSUMMON_SUCCESS)
    e4:SetRange(LOCATION_FZONE)
    e4:SetLabel(TYPE_FUSION)
    e4:SetCondition(s.effcon)
    e4:SetTarget(s.e4tg)
    e4:SetOperation(s.e4op)
    c:RegisterEffect(e4)

    -- synchro: add fusion spell
    local e5 = e4:Clone()
    e5:SetDescription(aux.Stringid(id, 2))
    e5:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e5:SetLabel(TYPE_SYNCHRO)
    e5:SetTarget(s.e5tg)
    e5:SetOperation(s.e5op)
    c:RegisterEffect(e5)

    -- xyz: add to hand or special summon
    local e6 = e4:Clone()
    e6:SetDescription(aux.Stringid(id, 3))
    e6:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOHAND + CATEGORY_SEARCH)
    e6:SetLabel(TYPE_XYZ)
    e6:SetTarget(s.e6tg)
    e6:SetOperation(s.e6op)
    c:RegisterEffect(e6)

    -- material check
    local eff = Effect.CreateEffect(c)
    eff:SetType(EFFECT_TYPE_FIELD)
    eff:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_SET_AVAILABLE +
                        EFFECT_FLAG_IGNORE_RANGE)
    eff:SetCode(EFFECT_MATERIAL_CHECK)
    eff:SetRange(LOCATION_FZONE)
    eff:SetValue(s.effcheck)
    c:RegisterEffect(eff)
end

function s.e1filter(c) return c:IsCode(950000001) and c:IsAbleToHand() end

function s.e1con(e, tp, eg, ep, ev, re, r, rp) return Duel.IsTurnPlayer(tp) end

function s.e1tg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.IsExistingMatchingCard(s.e1filter, tp,
                                           LOCATION_DECK + LOCATION_GRAVE, 0, 1,
                                           nil)
    end

    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp,
                          LOCATION_DECK + LOCATION_GRAVE)
end

function s.e1op(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(s.e1filter, tp,
                                    LOCATION_DECK + LOCATION_GRAVE, 0, nil)
    if #g > 1 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
        g = g:Select(tp, 1, 1, nil)
    end
    if #g > 0 then
        Utility.HintCard(id)
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end

function s.e3filter(c)
    if c:IsCode(id) or not c:IsAbleToHand() then return false end
    return (Utility.IsSetCard(c, 0x10f8, 0x20f8) and c:IsType(TYPE_MONSTER)) or
               (c:IsSetCard(0xf2) and c:IsType(TYPE_SPELL + TYPE_TRAP)) or
               aux.IsCodeListed(c, 13331639)
end

function s.e3tg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    local c = e:GetHandler()
    if chk == 0 then
        return Duel.IsExistingTarget(Card.IsFaceup, tp, LOCATION_ONFIELD, 0, 1,
                                     c) and
                   Duel.IsExistingMatchingCard(s.e3filter, tp, LOCATION_DECK +
                                                   LOCATION_GRAVE +
                                                   LOCATION_EXTRA, 0, 1, nil)
    end

    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectTarget(tp, Card.IsFaceup, tp, LOCATION_ONFIELD, 0, 1,
                                1, c)

    Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp,
                          LOCATION_DECK + LOCATION_GRAVE + LOCATION_EXTRA)
end

function s.e3op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end

    local tc = Duel.GetFirstTarget()
    if not tc:IsRelateToEffect(e) or Duel.Destroy(tc, REASON_EFFECT) == 0 then
        return
    end

    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.e3filter), tp,
                                      LOCATION_DECK + LOCATION_GRAVE +
                                          LOCATION_EXTRA, 0, 1, 1, tc)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end

function s.effcheck(e, c)
    local g = c:GetMaterial()
    if c:IsType(TYPE_FUSION + TYPE_SYNCHRO + TYPE_XYZ) and
        g:IsExists(Card.IsType, 1, nil, TYPE_PENDULUM) then
        c:RegisterFlagEffect(id,
                             RESET_EVENT + 0x4fe0000 + RESET_PHASE + PHASE_END,
                             0, 1)
    end
end

function s.efffilter(c, e, tp)
    return
        c:GetFlagEffect(id) ~= 0 and c:IsFaceup() and c:IsType(e:GetLabel()) and
            c:IsSummonPlayer(tp)
end

function s.effcon(e, tp, eg, ep, ev, re, r, rp)
    return #eg == 1 and s.efffilter(eg:GetFirst(), e, tp)
end

function s.e4filter(c, e, tp, sc)
    return c:HasLevel() and c:GetOriginalLevel() == sc:GetOriginalLevel() and
               c:IsCanBeSpecialSummoned(e, 0, tp, false, false,
                                        POS_FACEUP_DEFENSE)
end

function s.e4tg(e, tp, eg, ep, ev, re, r, rp, chk)
    local loc = LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE
    if chk == 0 then
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and
                   Duel.IsExistingMatchingCard(s.e4filter, tp, loc, 0, 1, nil,
                                               e, tp, eg:GetFirst()) and
                   Duel.GetFlagEffect(tp, id + 1 * 1000000) == 0
    end

    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, loc)
end

function s.e4op(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetFlagEffect(tp, id + 1 * 1000000) ~= 0 then return end
    Duel.RegisterFlagEffect(tp, id + 1 * 1000000, RESET_PHASE + PHASE_END, 0, 1)

    local c = e:GetHandler()
    local sc = eg:GetFirst()
    if not c:IsRelateToEffect(e) then return end
    if sc:IsFacedown() or Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then
        return
    end

    local loc = LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE
    local tc = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.e4filter),
                                       tp, loc, 0, 1, 1, nil, e, tp, sc):GetFirst()
    if tc and Duel.SpecialSummonStep(tc, 0, tp, tp, false, false, POS_FACEUP) then
        local ec1 = Effect.CreateEffect(c)
        ec1:SetDescription(3206)
        ec1:SetType(EFFECT_TYPE_SINGLE)
        ec1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
        ec1:SetCode(EFFECT_CANNOT_ATTACK)
        ec1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(ec1)
        local ec1b = ec1:Clone()
        ec1b:SetDescription(3302)
        ec1b:SetCode(EFFECT_CANNOT_TRIGGER)
        tc:RegisterEffect(ec1b)
    end
    Duel.SpecialSummonComplete()
end

function s.e5filter(c)
    return c:IsSetCard(0x46) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function s.e5tg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.IsExistingMatchingCard(s.e5filter, tp,
                                           LOCATION_DECK + LOCATION_GRAVE, 0, 1,
                                           nil) and
                   Duel.GetFlagEffect(tp, id + 2 * 1000000) == 0
    end

    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp,
                          LOCATION_DECK + LOCATION_GRAVE)
end

function s.e5op(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetFlagEffect(tp, id + 2 * 1000000) ~= 0 then return end
    Duel.RegisterFlagEffect(tp, id + 2 * 1000000, RESET_PHASE + PHASE_END, 0, 1)

    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end

    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.e5filter), tp,
                                      LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1,
                                      nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end

function s.e6filter(c, e, tp, sc)
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    return c:IsLevelBelow(sc:GetRank()) and c:IsType(TYPE_TUNER) and
               (c:IsAbleToHand() or
                   (ft > 0 and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)))
end

function s.e6tg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.IsExistingMatchingCard(s.e6filter, tp,
                                           LOCATION_DECK + LOCATION_GRAVE, 0, 1,
                                           nil, e, tp, eg:GetFirst()) and
                   Duel.GetFlagEffect(tp, id + 3 * 1000000) == 0
    end

    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp,
                          LOCATION_DECK + LOCATION_GRAVE)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp,
                          LOCATION_DECK + LOCATION_GRAVE)
end

function s.e6op(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetFlagEffect(tp, id + 3 * 1000000) ~= 0 then return end
    Duel.RegisterFlagEffect(tp, id + 3 * 1000000, RESET_PHASE + PHASE_END, 0, 1)

    local c = e:GetHandler()
    local sc = eg:GetFirst()
    if not c:IsRelateToEffect(e) then return end
    if sc:IsFacedown() then return end

    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SELECT)
    local g = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.e6filter), tp,
                                      LOCATION_DECK + LOCATION_GRAVE, 0, 1, 1,
                                      nil, e, tp, eg:GetFirst())
    if #g == 0 then return end

    aux.ToHandOrElse(g:GetFirst(), tp, function(tc)
        return tc:IsCanBeSpecialSummoned(e, 0, tp, false, false) and
                   Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
    end, function(tc)
        Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP_DEFENSE)
    end, 2)
end
