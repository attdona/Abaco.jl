using OrderedCollections

"""
    last_point(abaco, ne::String, var::String)::Union{Nothing, Missing, Tuple{Int,Float64}}

Returns the most recent in time value for the `ne` node metric `var` as a tuple (time, value).

If the node `ne` is unknown returns `nothing` and if there are not values
for metric `var` returns `missing`.
"""
function last_point(abaco, ne::String, var::String)::Union{Nothing, Missing, Tuple{Int,Float64}}
    if haskey(abaco.node, ne)
        cursor = abaco.node[ne].currsnap
        ts = abaco.node[ne].snap[cursor].ts
        vals = abaco.node[ne].snap[cursor].vals
        if haskey(vals, var)
            return (ts, vals[var].value)
        end
    else
        # unknown ne node
        return nothing
    end
    # missing var for ne node
    missing
end

"""
    last_value(abaco, ne::String, var::String)::Union{Nothing, Missing, Float64}

Returns the most recent in time value for the `ne` node metric `var`

If the node `ne` is unknown returns `nothing` and if there are not values
for metric `var` returns `missing`.
"""
function last_value(abaco, ne::String, var::String)::Union{Nothing, Missing, Float64}
    if haskey(abaco.node, ne)
        cursor = abaco.node[ne].currsnap
        ts = abaco.node[ne].snap[cursor].ts
        vals = abaco.node[ne].snap[cursor].vals
        if haskey(vals, var)
            return vals[var].value
        end
    else
        # unknown ne node
        return nothing
    end
    # missing var for ne node
    missing
end

"""
    get_values(abaco, ne::String, var::String)::Dict{Int,Float64}

Returns the ordered by time sequence of `var` values for `ne` node.

The returned values dictionary is ordered by descending time, most
recent value first. The number of entries are at most equal to the 
value of ages.
"""
function get_values(abaco, ne::String, var::String)::Dict{Int,Float64}
    result = OrderedDict{Int, Float64}()

    if haskey(abaco.node, ne)
        cursor = abaco.node[ne].currsnap
        for i = 1:abaco.ages
            vals = abaco.node[ne].snap[cursor].vals
            ts = abaco.node[ne].snap[cursor].ts
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

The Dict `msg` must contains the keys `ts` and `ne` and a numbers
of other keys managed as input variables.

This function modifies the `payload` dictionary: `ne` and `ts` keys are popped out.  

```julia
    payload = Dict(
        "ts" => nowts(),
        "ne" => "trento.castello",
        "x" => 23.2,
        "y" => 100
    )
    ingest!(abaco, ts, ne, payload)
```
"""
function ingest!(abaco, payload)
    ts = pop!(payload, "ts")
    ne = pop!(payload, "ne")
    ingest(abaco, ts, ne, payload)
end

"""
    ingest(abaco, ts, ne, values)

Adds the input variables include in the dictionary `values`.

```julia
    # now timestamp 
    ts = nowts()

    # short name of network node
    ne = "trento.castello"

    values = Dict(
        "x" => 23.2,
        "y" => 100
    )
    ingest(abaco, ts, ne, values)
```
"""
function ingest(abaco, ts, ne, values)
    snap = getsnap(abaco, ts, ne)
    if snap !== nothing
        for (var, val) in values
            snap_add(snap, ne, var, val)
        end
        trigger_formulas(abaco, snap, ne, keys(values))
    end
end

function ingest(abaco, payload::Dict{String, Any})
    ts = payload["ts"]
    ne = payload["ne"]
    snap = getsnap(abaco, ts, ne)
    vars = [var for var in keys(payload) if !(var in ["ne", "ts"])]
    if snap !== nothing
        for var in vars
            snap_add(snap, ne, var, payload[var])
        end
        trigger_formulas(abaco, snap, ne, vars)
    end
end


"""
    ingest(abaco, ts::Int, ne::String, var::String, val::Real)

Adds the input variable `var` with value `val`.

* `ts`: timestamp with seconds resolution
* `ne`: scope name 
* `var`: variable name
* `val`: variable value

"""
function ingest(abaco, ts::Int, ne::String, var::String, val::Real)
    snap = getsnap(abaco, ts, ne)
    snap_add(snap, ne, var, val)
    trigger_formulas(abaco, snap, ne, var)
end

function ingest(abaco, ts::Int, ne::String, var::String, val::Vector{<:Real})
    snap = getsnap(abaco, ts, ne)
    snap_add(snap, ne, var, val)
    trigger_formulas(abaco, snap, ne, var)
end

function sum_collected(abaco::Context, ne, variable, ts)
    result = get_collected(abaco, ne, variable, ts)
    if result === nothing
        return nothing
    else
        return PValue(length(result[1]), result[2], sum(result[1]), result[3])
    end
end

function get_collected(abaco::Context, ne, variable, ts)
    result = nothing

    (origin_type, var) = split(variable, ".")

    index = abaco.interval == -1 ? 1 : mvindex(ts, abaco.interval, abaco.ages)

    if haskey(abaco.origins, ne)
        result = LValue(length(abaco.origins[ne]), [])
        for origin_elem in abaco.origins[ne]
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

function sum_collected(abaco, ne, variable)
    ts = nowts()
    sum_collected(abaco, ne, variable, ts)
end

function get_collected(abaco, ne, variable)
    ts = nowts()
    get_collected(abaco, ne, variable, ts)
end

etype(abaco, ne) = haskey(abaco.node, ne) ? abaco.node[ne].tag : DEFAULT_TYPE

snapsetting(abaco, tag) = haskey(abaco.cfg, tag) ? abaco.cfg[tag] : abaco.cfg[DEFAULT_TYPE]

"""
    getsnap(abaco::Context, ts, ne)

Returns the `ne` node snapshot relative to timestamp `ts`.
"""
function getsnap(abaco::Context, ts, ne)
    tag = etype(abaco, ne)
    ## cfg = snapsetting(abaco, tag)

    if !haskey(abaco.node, ne)
        node(abaco, ne, tag)
    end

    if abaco.interval == -1
        snap =  abaco.node[ne].snap[1]
        snap.ts = ts
        return snap
    end

    # get the span
    ropts = span(ts, abaco.interval)
    index = mvindex(ts, abaco.interval, abaco.ages)

    elem = abaco.node[ne]
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
    snap_add(snap::Snap, ne, var::String, val::Real)

Adds the variable value of `ne` node to the `snap` snapshot. 
"""
function snap_add(snap::Snap, ne, var::String, val::Real)
    if !haskey(snap.vals, var)
        # first arrival of variable var
        snap.vals[var] = SValue(val)
    else
        snap.vals[var].value = val
        snap.vals[var].updated = nowts()
    end
end

function snap_add(snap::Snap, ne, var::String, val::PValue)
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

function snap_add(snap::Snap, ne, var::String, val::Vector{<:Real})
    if !haskey(snap.vals, var) || isa(snap.vals[var], SValue)
        # first arrival of variable var
        snap.vals[var] = LValue(ne, val)
    else
        snap.vals[var].value = val
        snap.vals[var].updated = nowts()
    end
end

function snap_add(::Nothing, ne, var::String, values::Any)
    # the target snap is older of any current snap, do nothing
end

function snap_add(::Snap, ne, var::String, value::Any)
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

