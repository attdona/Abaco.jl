using OrderedCollections

"""
    last_point(abaco, en::String, var::String)::Union{Nothing, Missing, Tuple{Int,Float64}}

Returns the most recent in time value for the `en` node metric `var` as a tuple (time, value).

If the node `en` is unknown returns `nothing` and if there are not values
for metric `var` returns `missing`.
"""
function last_point(abaco, en::String, var::String)::Union{Nothing, Missing, Tuple{Int,Float64}}
    if haskey(abaco.node, en)
        cursor = abaco.node[en].currsnap
        ts = abaco.node[en].snap[cursor].ts
        vals = abaco.node[en].snap[cursor].vals
        if haskey(vals, var)
            return (ts, vals[var].value)
        end
    else
        # unknown en node
        return nothing
    end
    # missing var for en node
    missing
end

"""
    last_value(abaco, en::String, var::String)::Union{Nothing, Missing, Float64}

Returns the most recent in time value for the `en` node metric `var`

If the node `en` is unknown returns `nothing` and if there are not values
for metric `var` returns `missing`.
"""
function last_value(abaco, en::String, var::String)::Union{Nothing, Missing, Float64}
    if haskey(abaco.node, en)
        cursor = abaco.node[en].currsnap
        ts = abaco.node[en].snap[cursor].ts
        vals = abaco.node[en].snap[cursor].vals
        if haskey(vals, var)
            return vals[var].value
        end
    else
        # unknown en node
        return nothing
    end
    # missing var for en node
    missing
end

"""
    get_values(abaco, en::String, var::String)::Dict{Int,Float64}

Returns the ordered by time sequence of `var` values for `en` node.

The returned values dictionary is ordered by descending time, most
recent value first. The number of entries are at most equal to the 
value of ages.
"""
function get_values(abaco, en::String, var::String)::Dict{Int,Float64}
    result = OrderedDict{Int, Float64}()

    if haskey(abaco.node, en)
        cursor = abaco.node[en].currsnap
        for i = 1:abaco.ages
            vals = abaco.node[en].snap[cursor].vals
            ts = abaco.node[en].snap[cursor].ts
            if haskey(vals, var)
                result[ts] = vals[var].value
            end
            cursor = cursor == 1 ? abaco.ages : cursor - 1
        end
    end
    result
end


"""
    ingest!(abaco, payload)

Adds the input variables included in the `payload` dictionary.

The Dict `msg` must contains the keys `ts` and `en` and a numbers
of other keys managed as input variables.

This function modifies the `payload` dictionary: `en` and `ts` keys are popped out.  

```julia
    payload = Dict(
        "ts" => nowts(),
        "en" => "trento.castello",
        "x" => 23.2,
        "y" => 100
    )
    ingest!(abaco, ts, en, payload)
```
"""
function ingest!(abaco, payload)
    ts = pop!(payload, "ts")
    en = pop!(payload, "en")
    ingest(abaco, ts, en, payload)
end

"""
    ingest(abaco, ts, en, values)

Adds the input variables include in the dictionary `values`.

```julia
    # now timestamp 
    ts = nowts()

    # short name of network node
    en = "trento.castello"

    values = Dict(
        "x" => 23.2,
        "y" => 100
    )
    ingest(abaco, ts, en, values)
```
"""
function ingest(abaco, ts, en, values)
    snap = getsnap(abaco, ts, en)
    for (var, val) in values
        snap_add(snap, en, var, val)
    end
    trigger_formulas(abaco, snap, en, keys(values))
end

function ingest(abaco, payload::Dict{String, Any})
    ts = payload["ts"]
    en = payload["en"]
    snap = getsnap(abaco, ts, en)
    vars = [var for var in keys(payload) if !(var in ["en", "ts"])]
    for var in vars
        snap_add(snap, en, var, payload[var])
    end
    trigger_formulas(abaco, snap, en, vars)
end


"""
    ingest(abaco, ts::Int, en::String, var::String, val::Real)

Adds the input variable `var` with value `val`.

* `ts`: timestamp with seconds resolution
* `en`: scope name 
* `var`: variable name
* `val`: variable value

"""
function ingest(abaco, ts::Int, en::String, var::String, val::Real)
    snap = getsnap(abaco, ts, en)
    snap_add(snap, en, var, val)
    trigger_formulas(abaco, snap, en, var)
end

function ingest(abaco, ts::Int, en::String, var::String, val::Vector{<:Real})
    snap = getsnap(abaco, ts, en)
    snap_add(snap, en, var, val)
    trigger_formulas(abaco, snap, en, var)
end

function sum_collected(abaco::Context, en, variable, ts)
    result = get_collected(abaco, en, variable, ts)
    if result === nothing
        return nothing
    else
        return PValue(length(result[1]), result[2], sum(result[1]), result[3])
    end
end

function get_collected(abaco::Context, en, variable, ts)
    result = nothing

    (origin_type, var) = split(variable, ".")

    index = abaco.interval == -1 ? 1 : mvindex(ts, abaco.interval, abaco.ages)

    if haskey(abaco.origins, en)
        result = LValue(length(abaco.origins[en]), [])
        for origin_elem in abaco.origins[en]
            snap = origin_elem.snap[index]
            if haskey(snap.vals, var) && origin_type == origin_elem.tag
                ropts = span(ts, abaco.interval)
                # @debug "[get_collected] interval: $(abaco.interval) - snap ts ts: $(snap.ts), ts: $ts, ropts: $ropts"
                if (ropts === snap.ts)
                    append!(result.value, snap.vals[var].value)
                    # updated is the last updated timestamp of origins
                    if result.updated < snap.vals[var].updated
                        result.updated = snap.vals[var].updated
                    end
                end
            end
        end
    end
    if result === nothing
        return nothing
    else
        return (result.value, result.contribs, result.updated)
    end
end

function sum_collected(abaco, en, variable)
    ts = nowts()
    sum_collected(abaco, en, variable, ts)
end

function get_collected(abaco, en, variable)
    ts = nowts()
    get_collected(abaco, en, variable, ts)
end

etype(abaco, en) = haskey(abaco.node, en) ? abaco.node[en].tag : DEFAULT_TYPE

snapsetting(abaco, tag) = haskey(abaco.cfg, tag) ? abaco.cfg[tag] : abaco.cfg[DEFAULT_TYPE]

"""
    getsnap(abaco::Context, ts, en)

Returns the `en` node snapshot relative to timestamp `ts`.
"""
function getsnap(abaco::Context, ts, en)
    tag = etype(abaco, en)
    ## cfg = snapsetting(abaco, tag)

    if !haskey(abaco.node, en)
        node(abaco, en, tag)
    end

    if abaco.interval == -1
        snap =  abaco.node[en].snap[1]
        snap.ts = ts
        return snap
    end

    # get the span
    ropts = span(ts, abaco.interval)
    index = mvindex(ts, abaco.interval, abaco.ages)

    elem = abaco.node[en]
    snap = elem.snap[index]

    if snap.ts < ropts

        last_ts = elem.snap[elem.currsnap].ts
        if last_ts < ropts
            elem.currsnap = index
        end
        snap.ts  = ropts

        # reset the values of snap
        map!(v->begin 
            isa(v, SValue) ? v.value=NaN : v.value = []
            v
        end, values(snap.vals))

        for fstate in values(snap.outputs)
            fstate.done = false
        end
    end

    if ropts < snap.ts
        return nothing
    end

    snap
end    

"""
    snap_add(snap::Snap, en, var::String, val::Real)

Adds the variable value of `en` node to the `snap` snapshot. 
"""
function snap_add(snap::Snap, en, var::String, val::Real)
    if !haskey(snap.vals, var)
        # first arrival of variable var
        snap.vals[var] = SValue(val)
    else
        snap.vals[var].value = val
        snap.vals[var].updated = nowts()
    end
end

function snap_add(snap::Snap, en, var::String, val::PValue)
    if val.contribs === val.expected
        # Add only completed qvalues to the snapshot
        if !haskey(snap.vals, var)
            # first arrival of variable var
            snap.vals[var] = SValue(val.value)
        else
            snap.vals[var].value = val.value
            snap.vals[var].updated = nowts()
        end
    end
end

function snap_add(snap::Snap, en, var::String, val::Vector{<:Real})
    if !haskey(snap.vals, var) || isa(snap.vals[var], SValue)
        # first arrival of variable var
        snap.vals[var] = LValue(en, val)
    else
        snap.vals[var].value = val
        snap.vals[var].updated = nowts()
    end
end

function snap_add(::Nothing, en, var::String, values::Any)
    # the target snap is older of any current snap, do nothing
end

function snap_add(::Snap, en, var::String, value::Any)
    # it is not a real value, do nothing
end


function setup_settings(abaco::Context,
                        tag;
                        handle=missing,
                        oncomplete=missing,
                        emitone=missing)
    if !haskey(abaco.cfg, tag)
        abaco.cfg[tag] = SnapsSetting(handle === missing ? nothing : handle,
                                       emitone === missing ? false : emitone,
                                       oncomplete === missing ? nothing : oncomplete)
    else
        if handle !== missing
            abaco.cfg[tag].handle = handle
        end
        if oncomplete !== missing
            abaco.cfg[tag].oncomplete = oncomplete
        end
        if emitone !== missing
            abaco.cfg[tag].emitone = emitone
        end
    end
end

