using Abaco
using Test

interval=10
ts = nowts()

val1 = 100
val2 = 101
val3 = 102

expected_triggers = 3
actual_triggers = 0

#function onresult(ts, sn, name, value, inputs)
#    global actual_triggers
#    @debug "timestamp [$ts]: sn: [$sn] $name = $value"
#    if name === "offset_footprint"
#        @test value == x + val1 + val2 + val3
#    end
#    actual_triggers += 1
#end

function onresult(timestamp, sn, name, value::Abaco.PValue, inputs)
    global actual_triggers
    @debug "progressive timestamp [$ts]: sn: [$sn] $name = $value"
    if value.contribs == 1
        @test sn == "italy"
        @test timestamp == span(ts, interval)
        @test value.value == val1
    elseif value.contribs == 2
        @test value.value == val1 + val2
    elseif value.contribs == 3
        @test value.value == val1 + val2 + val3
    else
        # never here
        @test 1 == 0
    end
    actual_triggers += 1
end

abaco = abaco_init(onresult, interval=interval)

@debug "starting demo with time span: $interval, values timestamp: $ts"

setup_settings(abaco, "state", oncomplete=onresult)

add_formula(abaco, "state", "total", "sum(region.city.footprint)")


italy = add_element(abaco, "italy", "state")
veneto = add_origin(abaco, italy, "veneto", "region")
trentino = add_origin(abaco, italy, "trentino", "region")
belluno = add_origin(abaco, veneto, "belluno", "city")
padova = add_origin(abaco, veneto, "padova", "city")
rovereto = add_origin(abaco, trentino, "rovereto", "city")
pergine = add_origin(abaco, trentino, "pergine", "city")

#@info "TEST: veneto origins: $(abaco.origins[veneto.sn])"

#current_footprint = get_collected(abaco, italy.sn, "region.city.footprint")
#@debug "initial carbon footprints: $current_footprint"

add_values(abaco, ts, belluno.sn, Dict("footprint" => val1))

add_values(abaco, ts, padova.sn, Dict("footprint" => val2))
add_values(abaco, ts, rovereto.sn, Dict("footprint" => val3))

#current_footprint = get_collected(abaco, italy.sn, "region.city.footprint", ts)
#@debug "current carbon footprint: $current_footprint"

@test actual_triggers === expected_triggers
