module Abaco

using Dates

include("logger.jl")
include("types.jl")
include("extractor.jl")
include("formula.jl")
include("universe.jl")
include("time.jl")

export abaco_init, add_formula!,
       add_scope!, add_value!, add_values!,
       oncomplete, nowts, Value

DEBUG = get(ENV, "ABACO_DEBUG", "0")
logging(debug = DEBUG=="0" ? [] : [Abaco])


"""
    abaco_init(onresult; handle=nothing, interval::Int=900, ages::Int=4)::Context

Initialize the abaco context:

* `onresult`: function callback that gets called each time a formula value is computed.

* `handle`: user defined object. 
            If handle is defined it is the first argument of `onresult`, default to `nothing`.

* `interval`: the span interval in seconds, default to 900 seconds (15 minutes).

* `ages`: the number of active rops managed by the abaco, default to 4.

Example 1: defining `onresult` callback that uses of an handle object.

```
# the handle object is a socket
sock = connect(3001)

function onresult(handle, ts, sn, formula_name, value, inputs)
    # build a pkt message from ts, sn, ...
    pkt = ...
    write(sock, pkt)
end
```

Example 2: defining `onresult` callback that doesn't use an handle object.

```julia
abaco = abaco_init(onresult, handle=sock)

function onresult(ts, sn, formula_name, value, inputs)
    @info "[\$ts][\$sn] function \$fname=\$value"
end

abaco = abaco_init(onresult)
```

 
"""
function abaco_init(onresult; handle=nothing, interval::Int=900, ages::Int=4)::Context
    Context(handle, interval, ages, onresult)
end

function oncomplete(onresult, abaco::Context)
    abaco.oncomplete = onresult
end

function loginit()
    DEBUG = get(ENV, "ABACO_DEBUG", "0")
    Abaco.logging(debug = DEBUG=="0" ? [] : [Abaco, Main])
end

end
