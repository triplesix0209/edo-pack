-- Odd-Eyes Magician
Duel.LoadScript("util.lua")
local s, id = GetID()

function s.initial_effect(c)
    -- pendulum
    Pendulum.AddProcedure(c)
end
