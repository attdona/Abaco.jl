using Abaco
using Test

Abaco.loginit()

# My time zone: Saturday, October 30, 2021 3:43:35 PM GMT+02:00 DST
metric_ts = 1635601415
metric_sn = "Pelmo"

interval = 5
ages = 4

values = Dict(
    "x" => 2.0,
    "y" => 4.0,
    "z" => 8.0
    )

expected_triggers = 2
actual_triggers = 0

function onresult(ts, sn, name, value, inputs)
    global actual_triggers
    @debug "age [$ts]: scope: [$sn] $name = $value"
    @test sn == metric_sn
    @test value == 14.0
    actual_triggers += 1
end
    
abaco = abaco_init(onresult, interval=interval, ages=ages)

# add a formula that is not evaluated because variable t is not feeded
formula(abaco, "r = (x + y) / exp(t)")

# this gets evaluated (2 + 4 + 8 = 14)
formula(abaco, "w = x + y + z")

ingest(abaco, metric_ts, metric_sn, values)
ingest(abaco, metric_ts+interval*ages, metric_sn, values)

@test actual_triggers === expected_triggers
