using Abaco
using JSON3
using Test

en = "Ambrusogn"
ts = nowts()
x = 2
y = 2
z = 3
very_long_variable = 5

expected_triggers = 1
actual_triggers = 0

function onresult(ts, en, name, value, inputs)
    global actual_triggers
    @debug "age [$ts]: scope: [$en] $name = $value"
    @test value == (x + y * very_long_variable)/z
    actual_triggers += 1
end

abaco = abaco_init(onresult)

# add a formula
f = formula(abaco, "(x + y * very_long_variable)/z")

# The values may be received one at time or in a batch
# The only mandatory fields are en and ts
# ts relate values coming in different messages: the partecipants in a formula 
# evaluation step have values marked with the same ts and the same en. 
# mnemonics:
# *en -> scope name
# *ts -> timestamp

msg = Dict(
    "en" => "element_under_test",
    "ts" => ts,
    "x" => 2,
    "y" => 2,
    "z" => 3,
    "very_long_variable" => 5
)

json_str = JSON3.write(msg)
@debug "json msg: $json_str" 

pkt = JSON3.read(json_str, Dict{String, Any})

ingest!(abaco, pkt)

@test actual_triggers === expected_triggers
