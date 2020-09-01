-- Palladium Knight - King
local s, id = GetID()

s.listed_names = {25652259, 24094653}

function s.initial_effect(c)
    -- code
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_ADD_CODE)
    e1:SetValue(64788463)
    c:RegisterEffect(e1)

    -- special summon
    local e2 = Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_HAND)
    e2:SetCountLimit(1, id)
    e2:SetCondition(s.e2con)
    e2:SetTarget(s.e2tg)
    e2:SetOperation(s.e2op)
    c:RegisterEffect(e2)

    -- search
    local e3 = Effect.CreateEffect(c)
    e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_SUMMON_SUCCESS)
    e3:SetTarget(s.e3tg)
    e3:SetOperation(s.e3op)
    c:RegisterEffect(e3)
    local e3b = e3:Clone()
    e3b:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
    c:RegisterEffect(e3b)
    local e3c = e3:Clone()
    e3c:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3c)
end

function s.e2filter1(c) return c:IsFaceup() and c:IsCode(25652259) end

function s.e2filter2(c, e, tp)
    return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_WARRIOR) and
               c:IsCanBeSpecialSummoned(e, 0, tp, false, false) and
               not c:IsCode(id)
end

function s.e2con(e, tp, eg, ep, ev, re, r, rp)
    return Duel.IsExistingMatchingCard(s.e2filter1, tp, LOCATION_MZONE, 0, 1,
                                       nil)
end

function s.e2tg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and
                   c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
    end

    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 0, tp,
                          LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE)
end

function s.e2op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    if Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) == 0 then
        return
    end
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end

    local g = Duel.GetMatchingGroup(s.e2filter2, tp, LOCATION_HAND +
                                        LOCATION_DECK + LOCATION_GRAVE, 0, nil,
                                    e, tp)
    if #g > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 0)) then
        Duel.BreakEffect()
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local sg = g:Select(tp, 1, 1, nil)
        if #sg > 0 then
            Duel.SpecialSummon(sg, 0, tp, tp, false, false, POS_FACEUP)
        end
    end
end

function s.e3filter(c) return c:IsCode(24094653) and c:IsAbleToHand() end

function s.e3tg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.IsExistingMatchingCard(s.e3filter, tp, LOCATION_DECK, 0, 1,
                                           nil)
    end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.e3op(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstMatchingCard(s.e3filter, tp, LOCATION_DECK, 0, nil)
    if not tc then return end

    Duel.SendtoHand(tc, nil, REASON_EFFECT)
    Duel.ConfirmCards(1 - tp, tc)
end
