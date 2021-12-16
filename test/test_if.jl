using Abaco
using Test

Abaco.loginit()

# My time zone: Saturday, October 30, 2021 3:43:35 PM GMT+02:00 DST
window = 900 
ts = 1635600600
sn = "Civetta"

abaco = abaco_init(interval=window) do ts, sn, name, value, inputs 
    @info "[identity] age [$ts]: scope: [$sn] $name = $value"
    @test value == 100.0
end

formula = "r = x == 0 ? y : 2"
add_formula(abaco, formula)

add_value(abaco, ts, sn, "x", 0)

@test_throws Abaco.EvalError add_value(abaco, ts, sn, "y", 100)

