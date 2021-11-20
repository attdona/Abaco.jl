using Abaco
using Test

# the standard 15 minutes span 
interval = 900
ages = 4

function onresult(ts, target_sn, target_name, value, inputs)
    @info "age [$ts]: scope: [$target_sn] $target_name = $value"
end

# in this case just needed for log initialization
abaco = abaco_init(onresult, interval=interval, ages=ages)

# My time zone: Saturday, October 30, 2021 6:10:15 PM GMT+02:00 DST
ts = 1635610215


for (t, expected_index) in zip(ts:interval:ts+interval*11, [1,2,3,4,1,2,3,4,1,2,3,4])
    ropts = Abaco.span(t, interval)
    index = Abaco.mvindex(ropts, interval, ages)
    @debug "ropts: $ropts, index: $index"
    @test ropts == t - t%interval
    @test index == expected_index
end
