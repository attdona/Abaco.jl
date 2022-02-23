using Abaco
using BenchmarkTools
using Test

Abaco.loginit()

# My time zone: Saturday, October 30, 2021 3:43:35 PM GMT+02:00 DST
mo = "Cristallo"

interval = 1
ages = 4

function onresult(ts, ne, name, value, inputs)
    @info "age [$ts]: scope: [$ne] $name = $value"
    @test 1 == 0 # onresult should not be invoked
end
    
abaco = abaco_init(onresult, interval=interval, ages=ages)

formula(abaco, "myformula = (x + y)")

for ts in 0:6
    ingest(abaco, ts, mo, "x", ts)
end

# too old, formula must not be evaluated
ingest(abaco, 1, mo, "y", 4)