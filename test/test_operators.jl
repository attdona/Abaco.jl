using Abaco
using Test

Abaco.loginit()

# My time zone: Saturday, October 30, 2021 3:43:35 PM GMT+02:00 DST
window = 900 
metric_ts = 1635600600
metric_sn = "Civetta"

expected_triggers = 10
actual_triggers = 0

#1
abaco = abaco_init(interval=window, ages=10) do ts, ne, name, value, inputs
    global actual_triggers
    @debug "[identity] age [$ts]: scope: [$ne] $name = $value"
    @test ts == metric_ts
    @test ne == metric_sn
    @test value == 100.0
    actual_triggers += 1
end

formula(abaco, "r = x")
ingest(abaco, metric_ts, metric_sn, "x", 100.0)

#2
oncomplete(abaco) do ts, ne, name, value, inputs
    global actual_triggers
    @debug "[negation] age [$ts]: scope: [$ne] $name = $value"
    @test value == -100
    actual_triggers += 1
end
metric_ts += window
formula(abaco, "r = -x")
ingest(abaco, metric_ts, metric_sn, "x", 100)

#3
oncomplete(abaco) do ts, ne, name, value, inputs
    global actual_triggers
    @debug "[add] age [$ts]: scope: [$ne] $name = $value"
    @test value == 6.2
    actual_triggers += 1
end
metric_ts += window
formula(abaco, "r = x + y")
ingest(abaco, metric_ts, metric_sn, "x", 1.0)
ingest(abaco, metric_ts, metric_sn, "y", 5.2)

#4
oncomplete(abaco) do ts, ne, name, value, inputs
    global actual_triggers
    @debug "[mult] age [$ts]: scope: [$ne] $name = $value"
    @test value == 3.1*2.1
    actual_triggers += 1
end
metric_ts += window
formula(abaco, "r = x * y")
ingest(abaco, metric_ts, metric_sn, "x", 3.1)
ingest(abaco, metric_ts, metric_sn, "y", 2.1)

#5
oncomplete(abaco) do ts, ne, name, value, inputs
    global actual_triggers
    @debug "[log10] age [$ts]: scope: [$ne] $name = $value"
    @test value == 2
    actual_triggers += 1
end
metric_ts += window
formula(abaco, "r = log10(x)")
ingest(abaco, metric_ts, metric_sn, "x", 100.0)

#6
oncomplete(abaco) do ts, ne, name, value, inputs
    global actual_triggers
    @debug "[exp] age [$ts]: scope: [$ne] $name = $value"
    @test value == exp(1)
    actual_triggers += 1
end
metric_ts += window
formula(abaco, "r = exp(x)")
ingest(abaco, metric_ts, metric_sn, "x", 1)

#7
oncomplete(abaco) do ts, ne, name, value, inputs
    global actual_triggers
    @debug "[div] age [$ts]: scope: [$ne] $name = $value"
    @test value == 1
    actual_triggers += 1
end
metric_ts += window
formula(abaco, "r = div(x, y)")
ingest(abaco, metric_ts, metric_sn, "x", 5)
ingest(abaco, metric_ts, metric_sn, "y", 3.1)

#8
oncomplete(abaco) do ts, ne, name, value, inputs
    global actual_triggers
    @debug "[x^(y-1)] age [$ts]: scope: [$ne] $name = $value"
    @test value == 4
    actual_triggers += 1
end
metric_ts += window
formula(abaco, "r = x^(y-1)")
ingest(abaco, metric_ts, metric_sn, "x", 2)
ingest(abaco, metric_ts, metric_sn, "y", 3)

#9
oncomplete(abaco) do ts, ne, name, value, inputs
    global actual_triggers
    @debug "[x^2 + y^3 +3*x^4] age [$ts]: scope: [$ne] $name = $value"
    @test value == 60
    actual_triggers += 1
end
metric_ts += window
formula(abaco, "r = x^2 + x^3 + 3*x^4")
ingest(abaco, metric_ts, metric_sn, "x", 2)
ingest(abaco, metric_ts, metric_sn, "y", 3)

#10
oncomplete(abaco) do ts, ne, name, value, inputs
    global actual_triggers
    @debug "[factorial] age [$ts]: scope: [$ne] $name = $value"
    @test value == factorial(6)
    actual_triggers += 1
end
metric_ts += window
# if a function requires an integer argument try to convert the arg value to Int
formula(abaco, "r = factorial(Int(x+x))")
ingest(abaco, metric_ts, metric_sn, "x", 3)

@test actual_triggers === expected_triggers
