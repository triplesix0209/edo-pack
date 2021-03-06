-- Odd-Eyes Venom Dragon - Overlord
Duel.LoadScript("util.lua")
local s, id = GetID()

s.material_setcode = {0x99, 0x1050, 0x50}
s.listed_series = {0x99, 0x1050, 0x50}
s.counter_list = {0x1149}

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- fusion summon
    Fusion.AddProcMix(c, false, false, function(c, sc, sumtype, tp)
        return c:IsSetCard(0x99, sc, sumtype, tp) and
                   c:IsRace(RACE_DRAGON, sc, sumtype, tp) and
                   c:IsType(TYPE_PENDULUM, sc, sumtype, tp) and c:IsOnField()
    end, function(c, sc, sumtype, tp)
        return c:IsSetCard(0x1050, sc, sumtype, tp) and
                   c:IsType(TYPE_FUSION, sc, sumtype, tp) and c:IsOnField()
    end)

    -- pendulum
    Pendulum.AddProcedure(c, false)
    Utility.PlaceToPZoneWhenDestroyed(c)

    -- special summon limit
    local splimit = Effect.CreateEffect(c)
    splimit:SetType(EFFECT_TYPE_SINGLE)
    splimit:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    splimit:SetCode(EFFECT_SPSUMMON_CONDITION)
    splimit:SetValue(function(e, se, sp, st)
        return (st & SUMMON_TYPE_FUSION) == SUMMON_TYPE_FUSION or
                   (st & SUMMON_TYPE_PENDULUM) == SUMMON_TYPE_PENDULUM
    end)
    c:RegisterEffect(splimit)

    -- atk down
    local eatkdown = Effect.CreateEffect(c)
    eatkdown:SetType(EFFECT_TYPE_FIELD)
    eatkdown:SetCode(EFFECT_UPDATE_ATTACK)
    eatkdown:SetRange(LOCATION_PZONE + LOCATION_MZONE)
    eatkdown:SetTargetRange(LOCATION_MZONE, LOCATION_MZONE)
    eatkdown:SetTarget(function(e, c)
        return not (c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_DRAGON))
    end)
    eatkdown:SetValue(function(e, c)
        return -200 * Duel.GetCounter(0, 1, 1, 0x1149)
    end)
    c:RegisterEffect(eatkdown)

    -- place counter (pendulum)
    local pe1 = Effect.CreateEffect(c)
    pe1:SetDescription(aux.Stringid(id, 0))
    pe1:SetCategory(CATEGORY_COUNTER)
    pe1:SetType(EFFECT_TYPE_TRIGGER_F + EFFECT_TYPE_FIELD)
    pe1:SetCode(EVENT_PHASE + PHASE_STANDBY)
    pe1:SetCountLimit(1)
    pe1:SetRange(LOCATION_PZONE)
    pe1:SetOperation(s.pe1op)
    c:RegisterEffect(pe1)

    -- atk up
    local pe2 = Effect.CreateEffect(c)
    pe2:SetDescription(aux.Stringid(id, 1))
    pe2:SetCategory(CATEGORY_ATKCHANGE)
    pe2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    pe2:SetCode(EVENT_BATTLE_CONFIRM)
    pe2:SetRange(LOCATION_PZONE)
    pe2:SetCountLimit(1)
    pe2:SetCondition(s.pe2con)
    pe2:SetOperation(s.pe2op)
    c:RegisterEffect(pe2)

    -- fusion success
    local me1 = Effect.CreateEffect(c)
    me1:SetCategory(CATEGORY_ATKCHANGE)
    me1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
    me1:SetProperty(EFFECT_FLAG_DELAY)
    me1:SetCode(EVENT_SPSUMMON_SUCCESS)
    me1:SetCondition(function(e, tp, eg, ep, ev, re, r, rp)
        return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
    end)
    me1:SetOperation(s.me1op)
    c:RegisterEffect(me1)

    -- place counter (monster)
    local me2 = Effect.CreateEffect(c)
    me2:SetType(EFFECT_TYPE_CONTINUOUS + EFFECT_TYPE_FIELD)
    me2:SetCode(EVENT_TO_GRAVE)
    me2:SetRange(LOCATION_MZONE)
    me2:SetOperation(s.me2op)
    c:RegisterEffect(me2)

    -- negate & copy effect and atk
    local me3 = Effect.CreateEffect(c)
    me3:SetDescription(aux.Stringid(id, 2))
    me3:SetCategory(CATEGORY_ATKCHANGE + CATEGORY_DISABLE)
    me3:SetType(EFFECT_TYPE_QUICK_O)
    me3:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DAMAGE_STEP)
    me3:SetCode(EVENT_FREE_CHAIN)
    me3:SetRange(LOCATION_MZONE)
    me3:SetHintTiming(TIMING_DAMAGE_STEP,
                      TIMING_DAMAGE_STEP + TIMINGS_CHECK_MONSTER)
    me3:SetCountLimit(1)
    me3:SetCondition(s.me3con)
    me3:SetTarget(s.me3tg)
    me3:SetOperation(s.me3op)
    c:RegisterEffect(me3)
end

function s.pe1op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end

    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_MZONE, nil)
    for tc in aux.Next(g) do tc:AddCounter(0x1149, 1) end
end

function s.pe2con(e, tp, eg, ep, ev, re, r, rp)
    local ac = Duel.GetAttacker()
    local bc = Duel.GetAttackTarget()

    if not bc then return false end
    if ac:IsControler(1 - tp) then bc, ac = ac, bc end
    e:SetLabelObject(ac)

    return ac:GetControler() ~= bc:GetControler() and ac:IsFaceup() and
               bc:IsFaceup() and Duel.GetCounter(0, 1, 1, 0x1149) > 0
end

function s.pe2op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end

    local ac = e:GetLabelObject()
    if not ac:IsRelateToBattle() or ac:IsFacedown() or not ac:IsControler(tp) then
        return
    end

    local ec1 = Effect.CreateEffect(c)
    ec1:SetType(EFFECT_TYPE_SINGLE)
    ec1:SetCode(EFFECT_UPDATE_ATTACK)
    ec1:SetValue(500 * Duel.GetCounter(0, 1, 1, 0x1149))
    ec1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_DAMAGE_CAL)
    ac:RegisterEffect(ec1)
end

function s.me1op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) or c:IsFacedown() then return end

    local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_MZONE, nil)
    local atk = 0
    for tc in aux.Next(g) do
        if tc:GetAttack() > 0 then atk = atk + tc:GetAttack() end
    end

    local ec1 = Effect.CreateEffect(c)
    ec1:SetType(EFFECT_TYPE_SINGLE)
    ec1:SetCode(EFFECT_UPDATE_ATTACK)
    ec1:SetValue(atk)
    ec1:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE)
    c:RegisterEffect(ec1)
end

function s.me2op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local ct = eg:FilterCount(Card.IsPreviousLocation, nil, LOCATION_ONFIELD)
    if ct > 0 then c:AddCounter(0x1149, ct) end
end

function s.me3filter(c) return c:IsFaceup() and c:IsType(TYPE_MONSTER) end

function s.me3con(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() ~= PHASE_DAMAGE or
               not Duel.IsDamageCalculated()
end

function s.me3tg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chk == 0 then
        return Duel.IsExistingTarget(s.me3filter, tp, 0,
                                     LOCATION_MZONE + LOCATION_GRAVE, 1, nil)
    end

    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_FACEUP)
    Duel.SelectTarget(tp, s.me3filter, tp, 0, LOCATION_MZONE + LOCATION_GRAVE,
                      1, 1, nil)
end

function s.me3op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()

    if not tc or tc:IsFacedown() or not tc:IsRelateToEffect(e) then return end

    Duel.NegateRelatedChain(tc, RESET_TURN_SET)
    local ec1 = Effect.CreateEffect(c)
    ec1:SetType(EFFECT_TYPE_SINGLE)
    ec1:SetCode(EFFECT_DISABLE)
    ec1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
    tc:RegisterEffect(ec1)
    local ec2 = Effect.CreateEffect(c)
    ec2:SetType(EFFECT_TYPE_SINGLE)
    ec2:SetCode(EFFECT_DISABLE_EFFECT)
    ec2:SetValue(RESET_TURN_SET)
    ec2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
    tc:RegisterEffect(ec2)

    if c:IsRelateToEffect(e) and c:IsFaceup() then
        if not tc:IsType(TYPE_TRAPMONSTER) then
            c:CopyEffect(tc:GetOriginalCodeRule(),
                         RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END,
                         1)
        end

        local atk = tc:GetBaseAttack()
        if atk < 0 then atk = 0 end
        local ec3 = Effect.CreateEffect(c)
        ec3:SetType(EFFECT_TYPE_SINGLE)
        ec3:SetCode(EFFECT_UPDATE_ATTACK)
        ec3:SetValue(atk)
        ec3:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        c:RegisterEffect(ec3)
    end
end
