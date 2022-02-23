using Abaco
using Test

Abaco.loginit()

# My time zone: Saturday, October 30, 2021 3:43:35 PM GMT+02:00 DST
metric_ts = 1635601415
metric_sn = "Marmolada"

interval = 5
ages = 1

expected_triggers = 1
actual_triggers = 0

values = Dict(
    "x" => 2.0,
    "y" => 4.0
)
    
function onresult(ts, ne, name, value, inputs)
    global actual_triggers
    @info "age [$ts]: scope: [$ne] $name = $value"
    actual_triggers += 1
end
    
abaco = abaco_init(onresult, interval=interval, ages=ages)

# add a formula that is not evaluated because variable t is not feeded
formula(abaco, "r = x + y")

ingest(abaco, metric_ts, metric_sn, values)

# a too old value must be ignored
ingest(abaco, metric_ts-10, metric_sn, values)

@test actual_triggers === expected_triggers
