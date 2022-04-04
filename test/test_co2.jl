using Abaco
using Test

interval=10
ts = nowts()

sn1 = "tn01"
sn2 = "tn02"
sn3 = "tn03"

count = 0
function onresult(ts, ne, name, value, inputs)
    global count
    count += 1
    @debug "timestamp [$ts]: ne: [$ne] $name = $value"
    if count == 1
        @test value.contribs == 1
        @test value.value == 250
    elseif count == 2
        @test value.contribs == 2
        @test value.value == 950
        @test value.expected == 3
    elseif count == 3
        @test value.contribs == 3
        @test value.value == 1950
    end
end

abaco = abaco_init(onresult, interval=interval)

@debug "starting demo with time span: $interval, values timestamp: $ts"

#setup_settings(abaco, "sensor", oncomplete=onresult)
setup_settings(abaco, "hub", oncomplete=onresult)

## If you have a lot of formulas use a csv file
#using DelimitedFiles
#datadir=joinpath(@__DIR__,"data")
#df = readdlm(joinpath(datadir,"formulas_co2.csv"), ';', header=true)
#add_formulas(abaco, df)

formula(abaco, "total_footprint", "sum(sensor.footprint)", "hub")

city = node(abaco, "trento", "hub")

node(abaco, city, sn1, "sensor")
node(abaco, city, sn2, "sensor")
node(abaco, city, sn3, "sensor")

current_footprint = get_collected(abaco, city.ne, "sensor.footprint")
@debug "initial carbon footprints: $current_footprint"

ingest(abaco, ts, sn1, Dict("footprint" => 250.0))
ingest(abaco, ts, sn2, Dict("footprint" => 700.0))

current_footprint = get_collected(abaco, city.ne, "sensor.footprint", ts)
@debug "current carbon footprint: $current_footprint"

footprint_sum = sum_collected(abaco, city.ne, "sensor.footprint", ts)
@debug "footprint sum: $footprint_sum"
@test footprint_sum.contribs == 2
@test footprint_sum.expected == 3
@test footprint_sum.value == 950

ingest(abaco, ts, sn3, Dict("footprint" => 1000.0))

footprint_sum = sum_collected(abaco, city.ne, "sensor.footprint", ts)
@debug "footprint sum: $footprint_sum"
@test footprint_sum.contribs == 3
@test footprint_sum.value == 1950

@test count == 3