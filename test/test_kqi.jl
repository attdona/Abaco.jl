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

function onresult(ts, sn, name, value, inputs)
    @debug "timestamp [$ts]: sn: [$sn] $name = $value"
    if name === "offset_footprint"
        @test value == x + val1 + val2 + val3
    end
end

function onresult(timestamp, sn, name, value::Abaco.QValue, inputs)
    @debug "kqi timestamp [$ts]: sn: [$sn] $name = $value"
    if name === "footprint_sum"
        if value.actual == 1
            @test sn == "trento"
            @test timestamp == span(ts, interval)
            @test value.value == val1
        elseif value.actual == 2
            @test value.value == val1 + val2
        elseif value.actual == 3
            @test value.value == val1 + val2 + val3
        end
    end
    if name === "footprint_mean"
        if value.actual == 1
            @test sn == "trento"
            @test timestamp == span(ts, interval)
            @test value.value == val1
        elseif value.actual == 2
            @test value.value == (val1 + val2)/2
        elseif value.actual == 3
            @test value.value == (val1 + val2 + val3)/3
        end
    end
end

abaco = abaco_init(onresult, interval=interval)

@debug "starting demo with time span: $interval, values timestamp: $ts"

setup_settings(abaco, "hub", oncomplete=onresult)

add_kqi(abaco, "hub", "footprint_sum", "sum(sensor.footprint)")
add_kqi(abaco, "hub", "footprint_mean", "mean(sensor.footprint)")
add_kqi(abaco, "hub", "footprint_std", "std(sensor.footprint)")
add_kqi(abaco, "hub", "kqi_fake", "x")

add_formula(abaco, "hub", "foobar", "x+y")
add_formula(abaco, "hub", "offset_footprint", "x + footprint_sum")

city = add_element(abaco, "trento", "hub")

add_origin(abaco, city, sn1, "sensor")
add_origin(abaco, city, sn2, "sensor")
add_origin(abaco, city, sn3, "sensor")

current_footprint = get_collected(abaco, city.sn, "sensor.footprint")
@debug "initial carbon footprints: $current_footprint"

add_values(abaco, ts, sn1, Dict("footprint" => val1))
add_values(abaco, ts, sn2, Dict("footprint" => val2))

current_footprint = get_collected(abaco, city.sn, "sensor.footprint", ts)
@debug "current carbon footprint: $current_footprint"

footprint_sum = sum_collected(abaco, city.sn, "sensor.footprint", ts)
@debug "footprint sum: $footprint_sum"
@test footprint_sum.q == 2/3
@test footprint_sum.value == val1 + val2

add_values(abaco, ts, sn3, Dict("footprint" => val3))

footprint_sum = sum_collected(abaco, city.sn, "sensor.footprint", ts)
@debug "footprint sum: $footprint_sum"
@test footprint_sum.q == 1.0
@test footprint_sum.value == val1 + val2 + val3

add_values(abaco, ts, city.sn, Dict(
    "x" => x,
    "y" => 20
))