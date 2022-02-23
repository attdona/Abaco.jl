using Abaco
using Test

interval=10
ts = nowts()

sn1 = "tn01"
sn2 = "tn02"
sn3 = "tn03"

val1 = 100
val2 = 101
val3 = 102
x = 10

expected_triggers = 12
actual_triggers = 0

function onresult(ts, ne, name, value, inputs)
    global actual_triggers
    @debug "timestamp [$ts]: ne: [$ne] $name = $value"
    if name === "offset_footprint"
        @test value == x + val1 + val2 + val3
    end
    actual_triggers += 1
end

function onresult(timestamp, ne, name, value::Abaco.PValue, inputs)
    global actual_triggers
    @debug "progressive timestamp [$ts]: ne: [$ne] $name = $value"
    if name === "footprint_sum"
        if value.contribs == 1
            @test ne == "trento"
            @test timestamp == span(ts, interval)
            @test value.value == val1
        elseif value.contribs == 2
            @test value.value == val1 + val2
        elseif value.contribs == 3
            @test value.value == val1 + val2 + val3
        end
    end
    if name === "footprint_mean"
        if value.contribs == 1
            @test ne == "trento"
            @test timestamp == span(ts, interval)
            @test value.value == val1
        elseif value.contribs == 2
            @test value.value == (val1 + val2)/2
        elseif value.contribs == 3
            @test value.value == (val1 + val2 + val3)/3
        end
    end
    actual_triggers += 1
end

abaco = abaco_init(onresult, interval=interval)

@debug "starting demo with time span: $interval, values timestamp: $ts"

setup_settings(abaco, "hub", oncomplete=onresult)

formula(abaco, "footprint_sum", "sum(sensor.footprint)", "hub")
formula(abaco, "footprint_mean", "mean(sensor.footprint)", "hub")
formula(abaco, "footprint_std", "std(sensor.footprint)", "hub")
formula(abaco, "progressive_fake", "x", "hub")
formula(abaco, "foobar", "x+y", "hub")
formula(abaco, "offset_footprint", "x + footprint_sum", "hub")

city = node(abaco, "trento", "hub")

node(abaco, city, sn1, "sensor")
node(abaco, city, sn2, "sensor")
node(abaco, city, sn3, "sensor")

current_footprint = get_collected(abaco, city.ne, "sensor.footprint")
@debug "initial carbon footprints: $current_footprint"

ingest(abaco, ts, sn1, Dict("footprint" => val1))
ingest(abaco, ts, sn2, Dict("footprint" => val2))

current_footprint = get_collected(abaco, city.ne, "sensor.footprint", ts)
@debug "current carbon footprint: $current_footprint"

footprint_sum = sum_collected(abaco, city.ne, "sensor.footprint", ts)
@debug "footprint sum: $footprint_sum"
@test footprint_sum.contribs == 2
@test footprint_sum.expected == 3
@test footprint_sum.value == val1 + val2

ingest(abaco, ts, sn3, Dict("footprint" => val3))

footprint_sum = sum_collected(abaco, city.ne, "sensor.footprint", ts)
@debug "footprint sum: $footprint_sum"
@test footprint_sum.contribs == 3
@test footprint_sum.value == val1 + val2 + val3

ingest(abaco, ts, city.ne, Dict(
    "x" => x,
    "y" => 20
))

@test actual_triggers === expected_triggers