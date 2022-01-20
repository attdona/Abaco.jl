using Abaco
using Test

interval=10

function onresult(ts, sn, name, value, inputs)
    @debug "timestamp [$ts]: sn: [$sn] $name = $value"
end

function onresult(timestamp, sn, name, value::Abaco.PValue, inputs)
    @debug "progressive timestamp [$ts]: sn: [$sn] $name = $value"
end

abaco = abaco_init(onresult, interval=interval)

@debug "starting demo with time span: $interval, values timestamp: $ts"

setup_settings(abaco, "state", oncomplete=onresult)

add_formula(abaco, "state", "total", "sum(region.city.footprint)")


italy = add_element(abaco, "italy", "state")
veneto = add_origin(abaco, italy, "veneto", "region")
trentino = add_origin(abaco, italy, "trentino", "region")

add_origin(abaco, veneto, "belluno", "city")
add_origin(abaco, veneto, "padova", "city")
add_origin(abaco, trentino, "rovereto", "city")
add_origin(abaco, trentino, "pergine", "city")
add_origin(abaco, trentino, "mori", "city")
add_origin(abaco, trentino, "bondone", "mountain")

nodes = split("region.city.footprint", ".")[1:end-1]
count = Abaco.deep_count(abaco, italy.sn, nodes)
@test count == 5 


