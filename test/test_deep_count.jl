using Abaco
using Test

interval=10

function onresult(ts, ne, name, value, inputs)
    @debug "timestamp [$ts]: ne: [$ne] $name = $value"
end

function onresult(timestamp, ne, name, value::Abaco.PValue, inputs)
    @debug "progressive timestamp [$ts]: ne: [$ne] $name = $value"
end

abaco = abaco_init(onresult, interval=interval)

@debug "starting demo with time span: $interval, values timestamp: $ts"

setup_settings(abaco, "state", oncomplete=onresult)

formula(abaco, "total", "sum(region.city.footprint)", "state")


italy = node(abaco, "italy", "state")
veneto = node(abaco, italy, "veneto", "region")
trentino = node(abaco, italy, "trentino", "region")

node(abaco, veneto, "belluno", "city")
node(abaco, veneto, "padova", "city")
node(abaco, trentino, "rovereto", "city")
node(abaco, trentino, "pergine", "city")
node(abaco, trentino, "mori", "city")
node(abaco, trentino, "bondone", "mountain")

nodes = split("region.city.footprint", ".")[1:end-1]
count = Abaco.deep_count(abaco, italy.ne, nodes)
@test count == 5 


