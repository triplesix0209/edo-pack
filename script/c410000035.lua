-- Palladium Knight of Atlantis
Duel.LoadScript("util.lua")
local s, id = GetID()

function s.initial_effect(c)
    -- race
    local race = Effect.CreateEffect(c)
    race:SetType(EFFECT_TYPE_SINGLE)
    race:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    race:SetCode(EFFECT_ADD_RACE)
    race:SetValue(RACE_DRAGON)
    c:RegisterEffect(race)

    -- special summon self
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
    e1:SetCode(EVENT_DESTROYED)
    e1:SetRange(LOCATION_HAND + LOCATION_GRAVE)
    e1:SetCountLimit(1, id + 1 * 1000000)
    e1:SetCondition(s.e1con)
    e1:SetTarget(s.e1tg)
    e1:SetOperation(s.e1op)
    c:RegisterEffect(e1)

    -- special summon monster
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetHintTiming(0, TIMING_END_PHASE)
    e2:SetCountLimit(1, id + 2 * 1000000)
    e2:SetCondition(s.e2con)
    e2:SetCost(s.e2cost)
    e2:SetTarget(s.e2tg)
    e2:SetOperation(s.e2op)
    c:RegisterEffect(e2)
end

function s.e1filter(c)
    if c:IsCode(id) then return false end
    return c:IsRace(RACE_DRAGON + RACE_WARRIOR) and
               c:IsReason(REASON_EFFECT + REASON_BATTLE) and
               c:IsPreviousPosition(POS_FACEUP) and
               c:IsPreviousLocation(LOCATION_MZONE) and
               (c:GetPreviousRaceOnField() == RACE_DRAGON or
                   c:GetPreviousRaceOnField() == RACE_WARRIOR)
end

function s.e1con(e, tp, eg, ep, ev, re, r, rp)
    return eg:FilterCount(s.e1filter, nil) > 0;
end

function s.e1tg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and
                   c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
    end

    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.e1op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end

    Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP_DEFENSE)
end

function s.e2filter(c, e, tp, mc)
    if c:IsLocation(LOCATION_EXTRA) and
        (c:IsFacedown() or Duel.GetLocationCountFromEx(tp, tp, mc, c) == 0) then
        return false
    end

    return c:IsLevel(7, 8) and c:IsRace(RACE_DRAGON + RACE_WARRIOR) and
               c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.e2con(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetFieldGroupCount(tp, 0, LOCATION_MZONE) > 0
end

function s.e2cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsReleasable() end
    Duel.Release(e:GetHandler(), REASON_COST)
end

function s.e2tg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    local loc = LOCATION_EXTRA
    local ft = Duel.GetLocationCount(tp, LOCATION_MZONE)
    if c:GetSequence() < 5 then ft = ft + 1 end
    if ft > 0 then loc = loc + LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE end

    if chk == 0 then
        return Duel.IsExistingMatchingCard(s.e2filter, tp, loc, 0, 1, nil, e,
                                           tp, c)
    end

    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, loc)
end

function s.e2op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local loc = LOCATION_EXTRA
    if Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
        loc = loc + LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE
    end

    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.e2filter, tp, loc, 0, 1, 1, nil, e,
                                      tp, c)
    if #g > 0 then Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP) end
end
