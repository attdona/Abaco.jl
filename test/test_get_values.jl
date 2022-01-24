using Abaco
using OrderedCollections
using Test

function onresult(ts, target_en, target_name, value, inputs)
    @debug "age [$ts]: scope: [$target_en] $target_name = $value"
    @debug "inputs: $inputs"
    
    @test target_en == en
end


# My time zone: Saturday, October 30, 2021 3:43:35 PM GMT+02:00 DST
ts = 1635601415

interval = 5
ages = 5
abaco = abaco_init(onresult, interval=interval, ages=ages)

en = "sansone"

result = get_values(abaco, en, "x")
@debug "init values(r) = $result"
@test result == OrderedDict()

result = last_value(abaco, en, "not_existent")
@debug "last_value(not_existent) = $result"
@test result === nothing

ingest!(abaco, Dict(
                "en" => en,
                "ts" => ts,
                "x" => 100,
            ))

result = last_value(abaco, en, "not_existent")
@debug "last_value(not_existent) = $result"
            
@test result === missing

result = last_value(abaco, en, "x")
@debug "last_value(x) = $result"
            
@test result === 100.0

for i = 0:5:40
    ingest!(abaco, Dict(
        "en" => en,
        "ts" => ts+i,
        "x" => i,
    ))
    last_pt = last_point(abaco, en, "x")
    @debug "last_point(x) = $last_pt"
                
    @test last_pt == (span(ts+i, interval), float(i))
    
end

result = get_values(abaco, en, "x")
@debug "sequence(r) = $result"
@debug "values(r) = $(values(result))"

series = OrderedDict(ts+40-i => float(40-i) for i in 0:5:20)

@test result == series
