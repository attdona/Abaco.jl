using Abaco
using Test

Abaco.loginit()

# My time zone: Saturday, October 30, 2021 3:43:35 PM GMT+02:00 DST
window = 900 
metric_ts = 1635600600
metric_sn = "Civetta"

expected_triggers = 0
actual_triggers = 0

abaco = abaco_init(interval=window) do ts, sn, name, value, inputs 
    global actual_triggers
    @info "[identity] age [$ts]: scope: [$sn] $name = $value"
    @test ts == metric_ts
    @test sn == metric_sn
    @test value == 100.0
    actual_triggers += 1
end

invalid_formula = "r = rm(\"foo.txt\")"
@test_throws Abaco.WrongFormula(invalid_formula) add_formula(abaco, invalid_formula)

@test actual_triggers === expected_triggers

