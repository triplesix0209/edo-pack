-- Neo-Space Multiverse
local s, id = GetID()
Duel.LoadScript("util.lua")

s.listed_names = {CARD_NEOS}
s.listed_series = {0x8, 0x3008, 0x1f}

function s.global_effect(c, tp)
    -- Elemental HERO Neos
    local eg1 = Effect.CreateEffect(c)
    eg1:SetType(EFFECT_TYPE_SINGLE)
    eg1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    eg1:SetCode(EFFECT_ADD_CODE)
    eg1:SetValue(CARD_NEOS)
    Utility.RegisterGlobalEffect(c, eg1, Card.IsCode, 14124483)
end

function s.initial_effect(c)
    -- activate
    local act = Effect.CreateEffect(c)
    act:SetType(EFFECT_TYPE_ACTIVATE)
    act:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(act)

    -- indes & immune
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1:SetRange(LOCATION_FZONE)
    e1:SetValue(1)
    c:RegisterEffect(e1)
    local e1b = e1:Clone()
    e1b:SetCode(EFFECT_IMMUNE_EFFECT)
    e1b:SetValue(function(e, te) return te:GetHandler():IsType(TYPE_MONSTER) end)
    c:RegisterEffect(e1b)

    -- cannot disable summon
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_IGNORE_RANGE + EFFECT_FLAG_SET_AVAILABLE)
    e2:SetCode(EFFECT_CANNOT_DISABLE_SPSUMMON)
    e2:SetRange(LOCATION_FZONE)
    e2:SetTargetRange(1, 0)
    e2:SetTarget(function(e, c)
        return c:IsType(TYPE_FUSION) and aux.IsMaterialListCode(c, CARD_NEOS)
    end)
    c:RegisterEffect(e2)

    -- may not return
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(42015635)
    e3:SetRange(LOCATION_FZONE)
    e3:SetTargetRange(LOCATION_MZONE, LOCATION_MZONE)
    c:RegisterEffect(e3)

    -- summon with 1 tribute
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 0))
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_SUMMON_PROC)
    e4:SetRange(LOCATION_SZONE)
    e4:SetTargetRange(LOCATION_HAND, 0)
    e4:SetCondition(s.e4con)
    e4:SetTarget(aux.FieldSummonProcTg(s.e4tg, s.e4tgsum))
    e4:SetOperation(s.e4op)
    e4:SetValue(SUMMON_TYPE_TRIBUTE)
    c:RegisterEffect(e4)
    local e4b = e4:Clone()
    e4b:SetCode(EFFECT_SET_PROC)
    c:RegisterEffect(e4b)

    -- extra summon
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 1))
    e5:SetType(EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
    e5:SetRange(LOCATION_FZONE)
    e5:SetTargetRange(LOCATION_HAND, 0)
    e5:SetValue(0x1)
    e5:SetTarget(aux.TargetBoolFunction(Card.IsSetCard, 0x8))
    c:RegisterEffect(e5)

    -- special summon neo-spacian
    local e6 = Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id, 2))
    e6:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e6:SetType(EFFECT_TYPE_QUICK_O)
    e6:SetCode(EVENT_FREE_CHAIN)
    e6:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e6:SetRange(LOCATION_FZONE)
    e6:SetCountLimit(1)
    e6:SetTarget(s.e6tg)
    e6:SetOperation(s.e6op)
    c:RegisterEffect(e6)
end

function s.e4filter(c, tp) return c:IsControler(tp) or c:IsFaceup() end

function s.e4con(e, c, minc)
    if c == nil then return true end
    local tp = c:GetControler()
    local mg = Duel.GetMatchingGroup(s.e4filter, tp, LOCATION_MZONE,
                                     LOCATION_MZONE, nil, tp)
    return minc <= 1 and Duel.CheckTribute(c, 1, 1, mg)
end

function s.e4tg(e, c) return c:IsLevelAbove(7) end

function s.e4tgsum(e, tp, eg, ep, ev, re, r, rp, chk, c)
    local mg = Duel.GetMatchingGroup(s.e4filter, tp, LOCATION_MZONE,
                                     LOCATION_MZONE, nil, tp)
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then
        mg = mg:Filter(Card.IsControler, nil, tp)
    end

    local sg = Duel.SelectTribute(tp, c, 1, 1, mg, nil, nil, true)
    if sg then
        sg:KeepAlive()
        e:SetLabelObject(sg)
        return true
    end
    return false
end

function s.e4op(e, tp, eg, ep, ev, re, r, rp, c)
    local sg = e:GetLabelObject()
    if not sg then return end

    c:SetMaterial(sg)
    Duel.Release(sg, REASON_SUMMON + REASON_MATERIAL)
    sg:DeleteGroup()
end

function s.e6filter1(c, e, tp)
    return c:IsFaceup() and c:IsLevel(4) and c:IsSetCard(0x3008) and
               c:IsAbleToGrave() and
               Duel.IsExistingMatchingCard(s.e6filter2, tp, LOCATION_HAND +
                                               LOCATION_DECK + LOCATION_GRAVE,
                                           0, 1, nil, e, tp, c:GetAttribute())
end

function s.e6filter2(c, e, tp, attr)
    return c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP) and
               c:IsSetCard(0x1f) and c:IsAttribute(attr)
end

function s.e6tg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chk == 0 then
        return Duel.IsExistingTarget(s.e6filter1, tp, LOCATION_MZONE, 0, 1, nil,
                                     e, tp)
    end

    local g = Duel.SelectTarget(tp, s.e6filter1, tp, LOCATION_MZONE, 0, 1, 1,
                                nil, e, tp)

    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, g, #g, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, 0,
                          LOCATION_HAND + LOCATION_DECK + LOCATION_GRAVE)
end

function s.e6op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end

    local tc = Duel.GetFirstTarget()
    if not tc or tc:IsFacedown() or not tc:IsRelateToEffect(e) then return end

    local attr = tc:GetAttribute()
    if Duel.SendtoGrave(tc, REASON_EFFECT) > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local g = Duel.SelectMatchingCard(tp, s.e6filter2, tp, LOCATION_HAND +
                                              LOCATION_DECK + LOCATION_GRAVE, 0,
                                          1, 1, nil, e, tp, attr)
        if #g > 0 then
            Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
        end
    end
end
