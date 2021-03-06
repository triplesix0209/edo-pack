-- Odd-Eyes Raging Dragon - Overlord
Duel.LoadScript("util.lua")
local s, id = GetID()

s.material_setcode = {0x99, 0x13b}
s.listed_series = {0x99, 0x13b}
s.pendulum_level = 7

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- xyz summon
    Xyz.AddProcedure(c, nil, 7, 2, nil, 0, 99, nil, false, function(g, tp, sc)
        return g:IsExists(function(tc)
            return tc:IsSetCard(0x99, sc, SUMMON_TYPE_XYZ, tp) and
                       tc:IsRace(RACE_DRAGON, sc, SUMMON_TYPE_XYZ, tp) and
                       c:IsType(TYPE_PENDULUM, sc, SUMMON_TYPE_XYZ, tp)
        end, 1, nil) and g:IsExists(function(tc)
            return tc:IsSetCard(0x13b, sc, SUMMON_TYPE_XYZ, tp) and
                       c:IsType(TYPE_XYZ, sc, SUMMON_TYPE_XYZ, tp)
        end, 1, nil)
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
        return (st & SUMMON_TYPE_XYZ) == SUMMON_TYPE_XYZ or
                   (st & SUMMON_TYPE_PENDULUM) == SUMMON_TYPE_PENDULUM
    end)
    c:RegisterEffect(splimit)

    -- halve atk
    local pe1 = Effect.CreateEffect(c)
    pe1:SetDescription(aux.Stringid(id, 0))
    pe1:SetCategory(CATEGORY_ATKCHANGE)
    pe1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    pe1:SetCode(EVENT_BATTLE_CONFIRM)
    pe1:SetRange(LOCATION_PZONE)
    pe1:SetCountLimit(1)
    pe1:SetCondition(s.pe1con)
    pe1:SetOperation(s.pe1op)
    c:RegisterEffect(pe1)

    -- xyz success
    local me1 = Effect.CreateEffect(c)
    me1:SetCategory(CATEGORY_DISABLE)
    me1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    me1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    me1:SetCode(EVENT_SPSUMMON_SUCCESS)
    me1:SetCondition(function(e, tp, eg, ep, ev, re, r, rp)
        return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
    end)
    me1:SetOperation(s.me1op)
    c:RegisterEffect(me1)

    -- destroy
    local me2 = Effect.CreateEffect(c)
    me2:SetDescription(aux.Stringid(id, 2))
    me2:SetCategory(CATEGORY_DESTROY)
    me2:SetType(EFFECT_TYPE_IGNITION)
    me2:SetRange(LOCATION_MZONE)
    me2:SetCountLimit(1)
    me2:SetCost(s.me2cost)
    me2:SetTarget(s.me2tg)
    me2:SetOperation(s.me2op)
    c:RegisterEffect(me2, false, REGISTER_FLAG_DETACH_XMAT)

    -- negate & gain atk
    local me3 = Effect.CreateEffect(c)
    me3:SetDescription(aux.Stringid(id, 3))
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

function s.pe1con(e, tp, eg, ep, ev, re, r, rp)
    local ac = Duel.GetAttacker()
    local bc = Duel.GetAttackTarget()

    if not bc then return false end
    if ac:IsControler(1 - tp) then bc, ac = ac, bc end
    e:SetLabelObject(ac)

    return ac:GetControler() ~= bc:GetControler() and bc:IsFaceup() and
               bc:GetAttack() > 0
end

function s.pe1op(e, tp, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local ac = Duel.GetAttacker()
    local bc = Duel.GetAttackTarget()
    if not bc then return end
    if ac:IsControler(1 - tp) then bc, ac = ac, bc end
    if not ac:IsRelateToBattle() or bc:IsFacedown() or not bc:IsRelateToBattle() then
        return
    end

    local ec1 = Effect.CreateEffect(c)
    ec1:SetType(EFFECT_TYPE_SINGLE)
    ec1:SetCode(EFFECT_SET_ATTACK_FINAL)
    ec1:SetValue(math.ceil(bc:GetAttack() / 2))
    ec1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_DAMAGE_CAL)
    bc:RegisterEffect(ec1)
end

function s.me1op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local ec1 = Effect.CreateEffect(c)
    ec1:SetDescription(aux.Stringid(id, 1))
    ec1:SetType(EFFECT_TYPE_SINGLE)
    ec1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
    ec1:SetCode(EFFECT_EXTRA_ATTACK)
    ec1:SetValue(2)
    ec1:SetReset(RESET_EVENT + RESETS_STANDARD)
    c:RegisterEffect(ec1)
end

function s.me2cost(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    local g = Duel.GetMatchingGroup(aux.TRUE, tp, 0, LOCATION_ONFIELD, nil)
    if chk == 0 then
        return #g > 0 and c:CheckRemoveOverlayCard(tp, 1, REASON_COST)
    end

    local rt = math.min(#g, c:GetOverlayCount())
    c:RemoveOverlayCard(tp, 1, rt, REASON_COST)
    e:SetLabel(Duel.GetOperatedGroup():GetCount())
end

function s.me2tg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chk == 0 then
        return Duel.IsExistingMatchingCard(aux.TRUE, tp, 0, LOCATION_ONFIELD, 1,
                                           nil)
    end

    Duel.SetOperationInfo(0, CATEGORY_DESTROY, nil, 1, 0, 0)
end

function s.me2op(e, tp, eg, ep, ev, re, r, rp)
    local ct = e:GetLabel()
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
    local g = Duel.SelectMatchingCard(tp, aux.TRUE, tp, 0, LOCATION_ONFIELD, 1,
                                      ct, nil)
    if #g > 0 then Duel.Destroy(g, REASON_EFFECT) end
end

function s.me3con(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetCurrentPhase() ~= PHASE_DAMAGE or
               not Duel.IsDamageCalculated()
end

function s.me3tg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chk == 0 then
        return Duel.IsExistingTarget(Card.IsFaceup, tp, 0, LOCATION_MZONE, 1,
                                     nil)
    end

    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_FACEUP)
    Duel.SelectTarget(tp, Card.IsFaceup, tp, 0, LOCATION_MZONE, 1, 1, nil)
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

    if not tc:IsImmuneToEffect(e) then
        Duel.AdjustInstantly(tc)

        local atk = tc:GetAttack()
        local ec3 = Effect.CreateEffect(c)
        ec3:SetType(EFFECT_TYPE_SINGLE)
        ec3:SetCode(EFFECT_SET_ATTACK_FINAL)
        ec3:SetValue(math.ceil(atk / 2))
        ec3:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        tc:RegisterEffect(ec3)

        if c:IsRelateToEffect(e) and c:IsFaceup() then
            local ec4 = Effect.CreateEffect(c)
            ec4:SetType(EFFECT_TYPE_SINGLE)
            ec4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            ec4:SetCode(EFFECT_UPDATE_ATTACK)
            ec4:SetValue(math.ceil(atk / 2))
            ec4:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
            c:RegisterEffect(ec4)
        end
    end
end
