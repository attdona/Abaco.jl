using Abaco
using DelimitedFiles

datadir=joinpath(@__DIR__,"data")

ts = 1635601415
sn1 = "mi01"
sn2 = "mi02"

values = Dict(
    "x" => 2.0,
    "y" => 4.0,
    "z" => 8.0
    )

df = readdlm(joinpath(datadir,"formulas.csv"), ';', header=true)

function onresult(ts, sn, name, value, inputs)
    @debug "age [$ts]: sn: [$sn] $name = $value"
end

abaco = abaco_init(onresult, interval=-1)

setup_settings(abaco, "sensor", oncomplete=onresult)
setup_settings(abaco, "hub", oncomplete=onresult)

add_formulas(abaco, df[1])

city = add_element(abaco, "milano", "hub")

#sensor = add_element(abaco, sn, "sensor")
add_origin(abaco, city, sn1, "sensor")
add_origin(abaco, city, sn2, "sensor")

add_values(abaco, ts, sn1, values)
add_values(abaco, ts, sn2, values)

#add_values(abaco, ts, sn1, Dict("x"=>4))

#@info "elements: $(abaco.element)"
#@info "hub: $(abaco.element["milano"])"
#@info "hub settings: $(abaco.cfg["hub"])"
#@info "mi01: $(abaco.element["mi01"])"
#@info "origins: $(abaco.origins)"
#@info "target: $(abaco.target)"

vals = Abaco.origins_vals(abaco, "milano", ts)
@debug "origin_vals: $vals"