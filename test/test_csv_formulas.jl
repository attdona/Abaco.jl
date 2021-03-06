using Abaco
using DelimitedFiles
using Test

datadir=joinpath(@__DIR__,"data")

expected_triggers = 6
actual_triggers = 0

ts = 1635601415
sn1 = "mi01"
sn2 = "mi02"

values = Dict(
    "x" => 2.0,
    "y" => 4.0,
    "z" => 8.0
    )

df = readdlm(joinpath(datadir,"formulas.csv"), ';', header=true)

function onresult(ts, ne, name, value, inputs)
    global actual_triggers
    @debug "age [$ts]: ne: [$ne] $name = $value"
    actual_triggers += 1
end

abaco = abaco_init(onresult, interval=-1)

setup_settings(abaco, "sensor", oncomplete=onresult)
setup_settings(abaco, "hub", oncomplete=onresult)

add_formulas(abaco, df[1])

city = node(abaco, "milano", "hub")

#sensor = node(abaco, ne, "sensor")
node(abaco, city, sn1, "sensor")
node(abaco, city, sn2, "sensor")

ingest(abaco, ts, sn1, values)
ingest(abaco, ts, sn2, values)

#ingest(abaco, ts, sn1, Dict("x"=>4))

#@info "elements: $(abaco.node)"
#@info "hub: $(abaco.node["milano"])"
#@info "hub settings: $(abaco.cfg["hub"])"
#@info "mi01: $(abaco.node["mi01"])"
#@info "origins: $(abaco.origins)"
#@info "target: $(abaco.target)"

vals = Abaco.origins_vals(abaco, "milano", ts)
@debug "origin_vals: $vals"

@test actual_triggers === expected_triggers