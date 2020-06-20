-- Ra the Sun Divine Sphere
Duel.LoadScript("c400000000.lua")
local s, id = GetID()

s.divine_hierarchy = 2
s.listed_names = {CARD_RA, 10000090}

function s.initial_effect(c)
    Transform.AddProcedure(c)
    Divine.AddProcedure(c, RACE_WINGEDBEAST + RACE_PYRO, 'self', false)

    -- transform ra
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetCondition(s.e1con)
    e1:SetOperation(s.e1op)
    Duel.RegisterEffect(e1, nil)

    -- attack limit
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_ATTACK)
    c:RegisterEffect(e2)

    -- battle indes
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetValue(function(e, re, r, rp) return (r & REASON_BATTLE) ~= 0 end)
    c:RegisterEffect(e3)

    -- battle damage avoid
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetValue(1)
    c:RegisterEffect(e4)

    -- de-transform
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 0))
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetProperty(EFFECT_FLAG_BOTH_SIDE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1)
    e5:SetTarget(s.e5tg)
    e5:SetOperation(s.e5op)
    c:RegisterEffect(e5)

    -- transform phoenix
    local e6 = Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e6:SetCode(EVENT_PHASE + PHASE_END)
    e6:SetCondition(s.e6con)
    e6:SetOperation(s.e6op)
    Duel.RegisterEffect(e6, nil)
end

function s.e1filter(c, sc)
    return c:IsCode(CARD_RA) and c:GetOwner() == sc:GetOwner()
end

function s.e1con(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(s.e1filter, 1, nil, e:GetHandler())
end

function s.e1op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = eg:Filter(s.e1filter, nil, c):GetFirst()
    if not tc then return end
    Duel.BreakEffect()

    Transform.Summon(c, tc:GetControler(), tc:GetControler(), tc,
                     tc:GetPosition())
end

function s.e5tg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    local mc = c:GetMaterial():GetFirst()

    if chk == 0 then
        return tp == mc:GetOwner() and
                   (c:IsControler(tp) or
                       Duel.GetLocationCount(tp, LOCATION_MZONE) > 0)
    end
end

function s.e5op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsControler(tp) and Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then
        return
    end

    local tc = Transform.Detransform(c, tp, tp)

    local atk = 0
    local def = 0
    if tc:IsSummonType(SUMMON_TYPE_TRIBUTE) then
        local mg = tc:GetMaterial()
        for mc in aux.Next(mg) do
            if mc:GetBaseAttack() > 0 then
                atk = atk + mc:GetBaseAttack()
            end
            if mc:GetBaseDefense() > 0 then
                def = def + mc:GetBaseDefense()
            end
        end
    end
    if atk < 4000 then atk = 4000 end
    if def < 4000 then def = 4000 end

    local ec1 = Effect.CreateEffect(c)
    ec1:SetType(EFFECT_TYPE_SINGLE)
    ec1:SetProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_IGNORE_IMMUNE)
    ec1:SetCode(EFFECT_SET_BASE_ATTACK)
    ec1:SetRange(LOCATION_MZONE)
    ec1:SetValue(atk)
    ec1:SetReset(RESET_EVENT + RESETS_STANDARD_DISABLE - RESET_TOFIELD)
    tc:RegisterEffect(ec1)
    local ec2 = ec1:Clone()
    ec2:SetCode(EFFECT_SET_BASE_DEFENSE)
    ec2:SetValue(def)
    tc:RegisterEffect(ec2)
end

function s.e6filter(c) return c:IsCode(10000090) and c:IsType(Transform.TYPE) end

function s.e6con(e, tp, eg, ep, ev, re, r, rp)
    tp = e:GetOwner():GetOwner()
    return
        Duel.IsExistingMatchingCard(s.e6filter, tp, LOCATION_MZONE, 0, 1, nil)
end

function s.e6op(e, tp, eg, ep, ev, re, r, rp)
    tp = e:GetOwner():GetOwner()
    local c = e:GetHandler()

    Duel.Hint(HINT_SELECTMSG, tp, Transform.TEXT_TRANSFORM_MATERIAL)
    local tc = Duel.SelectMatchingCard(tp, s.e6filter, tp, LOCATION_MZONE, 0, 1,
                                       1, nil):GetFirst()
    if not tc then return end
    Duel.BreakEffect()

    Transform.Summon(c, tc:GetControler(), tc:GetControler(), tc,
                     POS_FACEUP_DEFENSE)
    c:SetMaterial(tc:GetMaterial())
end
