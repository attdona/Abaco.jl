using Abaco
using JSON3
using BenchmarkTools

function nop(s, sn, name, value, inputs)
end

function onresult(ts, sn, name, value, inputs)
    @info "age [$ts]: scope: [$sn] $name = $value"
end

interval = 5
ages = 4
abaco = Abaco.init(nop, interval, ages)
add_formula!(abaco, "y = x1 + x2")


function main(sns)
    for ts in 0:5:80
        for i in 1:100
            add_value!(abaco, ts, sns[i].first, :x1, sns[i].second)
            add_value!(abaco, ts, sns[i].first, :x2, sns[i].second)
        end
    end
end

sns = Dict(i => "SN$i" => float(i) for i in 1:100)

main(sns)
add_value!(abaco, 85, "SN", "x1", 1.0)
abaco.oncomplete = onresult

# expect (0 allocations: 0 bytes)
@btime add_value!(abaco, 85, "SN", "x2", 1.0)
