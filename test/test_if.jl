using Abaco
using Test

Abaco.loginit()

# My time zone: Saturday, October 30, 2021 3:43:35 PM GMT+02:00 DST
window = 900 
ts = 1635600600
ne = "Civetta"

abaco = abaco_init(interval=window) do ts, ne, name, value, inputs 
    @info "[identity] age [$ts]: scope: [$ne] $name = $value"
    @test value == 100.0
end

formula(abaco, "r = x == 0 ? y : 2")

ingest(abaco, ts, ne, "x", 0)

@test_throws Abaco.EvalError ingest(abaco, ts, ne, "y", 100)

