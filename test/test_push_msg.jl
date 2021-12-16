using Abaco
using Test

x = 2.0
y = 8.0
z = 2.0
t = 10.0

r = (x + y) / exp(z)
w = (x + y) / z
sum = x + y + z + t

function onresult(ts, target_sn, target_name, value, inputs)
    @debug "age [$ts]: scope: [$target_sn] $target_name = $value"
    @debug "inputs: $inputs"
    
    @test target_sn == sn
    if target_name === "r"
        @test value == r
    end
    if target_name === "sum"
        @test value == sum
    end
    if target_name === "w"
        @test value == w
    end
end

# My time zone: Saturday, October 30, 2021 3:43:35 PM GMT+02:00 DST
ts = 1635601415

interval = 5
ages = 4
abaco = abaco_init(onresult, interval=interval, ages=ages)

sn = "Mulaz"

# add a formula
add_formula(abaco, "r = (x + y) / exp(z)")
add_formula(abaco, "w = (x + y) / z")
add_formula(abaco, "sum = x + y + z + t")

add_values!(abaco, Dict(
                "sn" => sn,
                "ts" => ts,
                "x" => x,
            ))

add_values!(abaco, Dict(
                "sn" => sn,
                "ts" => ts+2,
                "y" => y,
                "z" => z
            ))

add_values!(abaco, Dict(
                "sn" => sn,
                "ts" => ts+2,
                "t" => t,
            ))

add_values!(abaco, Dict(
                "sn" => sn,
                "ts" => ts+2,
                "w" => nothing,
            ))

@debug "[$sn]: $(abaco.element[sn])"

result = get_values(abaco, sn, "r")
@debug "get_values(r) = $result"