module Abaco

using Dates

const DEFAULT_TYPE = ""

include("logger.jl")
include("types.jl")
include("context.jl")
include("extractor.jl")
include("formula.jl")
include("kqi.jl")
include("poll.jl")
include("time.jl")

export abaco_init, add_formula, add_formulas, add_kqi, add_element,
       add_origin, add_value, add_values, add_values!,
       last_value, last_point, get_values, get_collected, sum_collected,
       setup_settings, oncomplete, nowts,
       Context, Element, dependents, etype, span



"""
    abaco_init(onresult; handle=nothing, interval::Int=900, ages::Int=4, emitone=true)::Context

Initialize the abaco context:

* `onresult`: function callback that gets called each time a formula value is computed.

* `handle`: user defined object. 
            If handle is defined it is the first argument of `onresult`, default to `nothing`.

* `interval`: the span interval in seconds, default to 900 seconds (15 minutes).
              If interval is equal to -1 there is just one infinite time span.

* `ages`: the number of active rops managed by the abaco. Default to 4.
          If `interval` is equal to -1 `ages`  is not applicable because it loses meaning.

* `emitone`: if `true` emits for each time span at most 1 formula value, 
             otherwise emits a new result at every new inputs. Defaut to `true`

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
function abaco_init(onresult;
                    handle=nothing,
                    interval::Int=-1,
                    ages::Int=1,
                    emitone::Bool=true)::Context
                    DEBUG = get(ENV, "ABACO_DEBUG", "0")
    logging(debug = DEBUG=="0" ? [] : [@__MODULE__, Main])
    @debug "resetting abaco ..."
    cfg = SnapsSetting(handle, emitone, onresult)
    Context(interval, ages, Dict(DEFAULT_TYPE=>cfg))
end


function oncomplete(onresult, abaco::Context)
    abaco.cfg[DEFAULT_TYPE].oncomplete = onresult
end

function abaco_multi()
end

function loginit()
    DEBUG = get(ENV, "ABACO_DEBUG", "0")
    Abaco.logging(debug = DEBUG=="0" ? [] : [Abaco, Main])
end

end
