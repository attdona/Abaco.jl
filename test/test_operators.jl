using Abaco
using Test

Abaco.loginit()

# My time zone: Saturday, October 30, 2021 3:43:35 PM GMT+02:00 DST
window = 900 
metric_ts = 1635600600
metric_sn = "Civetta"

abaco = abaco_init(width=window) do ts, sn, name, value, inputs 
    @debug "[identity] age [$ts]: scope: [$sn] $name = $value"
    @test ts == metric_ts
    @test sn == metric_sn
    @test value == 100.0
end

add_formula!(abaco, "r = x")
add_value!(abaco, metric_ts, metric_sn, "x", 100.0)

oncomplete(abaco) do ts, sn, name, value, inputs
    @debug "[negation] age [$ts]: scope: [$sn] $name = $value"
    @test value == -100
end
metric_ts += window
add_formula!(abaco, "r = -x")
add_value!(abaco, metric_ts, metric_sn, "x", 100)

oncomplete(abaco) do ts, sn, name, value, inputs
    @debug "[add] age [$ts]: scope: [$sn] $name = $value"
    @test value == 6.2
end
metric_ts += window
add_formula!(abaco, "r = x + y")
add_value!(abaco, metric_ts, metric_sn, "x", 1.0)
add_value!(abaco, metric_ts, metric_sn, "y", 5.2)

oncomplete(abaco) do ts, sn, name, value, inputs
    @debug "[mult] age [$ts]: scope: [$sn] $name = $value"
    @test value == 3.1*2.1
end
metric_ts += window
add_formula!(abaco, "r = x * y")
add_value!(abaco, metric_ts, metric_sn, "x", 3.1)
add_value!(abaco, metric_ts, metric_sn, "y", 2.1)


oncomplete(abaco) do ts, sn, name, value, inputs
    @debug "[log10] age [$ts]: scope: [$sn] $name = $value"
    @test value == 2
end
metric_ts += window
add_formula!(abaco, "r = log10(x)")
add_value!(abaco, metric_ts, metric_sn, "x", 100.0)


oncomplete(abaco) do ts, sn, name, value, inputs
    @debug "[exp] age [$ts]: scope: [$sn] $name = $value"
    @test value == exp(1)
end
metric_ts += window
add_formula!(abaco, "r = exp(x)")
add_value!(abaco, metric_ts, metric_sn, "x", 1)

oncomplete(abaco) do ts, sn, name, value, inputs
    @debug "[div] age [$ts]: scope: [$sn] $name = $value"
    @test value == 1
end
metric_ts += window
add_formula!(abaco, "r = div(x, y)")
add_value!(abaco, metric_ts, metric_sn, "x", 5)
add_value!(abaco, metric_ts, metric_sn, "y", 3.1)

oncomplete(abaco) do ts, sn, name, value, inputs
    @debug "[x^(y-1)] age [$ts]: scope: [$sn] $name = $value"
    @test value == 4
end
metric_ts += window
add_formula!(abaco, "r = x^(y-1)")
add_value!(abaco, metric_ts, metric_sn, "x", 2)
add_value!(abaco, metric_ts, metric_sn, "y", 3)

oncomplete(abaco) do ts, sn, name, value, inputs
    @debug "[x^2 + y^3 +3*x^4] age [$ts]: scope: [$sn] $name = $value"
    @test value == 60
end
metric_ts += window
add_formula!(abaco, "r = x^2 + x^3 + 3*x^4")
add_value!(abaco, metric_ts, metric_sn, "x", 2)
add_value!(abaco, metric_ts, metric_sn, "y", 3)

oncomplete(abaco) do ts, sn, name, value, inputs
    @debug "[factorial] age [$ts]: scope: [$sn] $name = $value"
    @test value == factorial(6)
end
metric_ts += window
add_formula!(abaco, "r = factorial(x+x)")
add_value!(abaco, metric_ts, metric_sn, "x", 3)
