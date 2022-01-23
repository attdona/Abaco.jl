using OrderedCollections

function last_point(abaco, sn, var)
    if haskey(abaco.node, sn)
        cursor = abaco.node[sn].currsnap
        ts = abaco.node[sn].snap[cursor].ts
        vals = abaco.node[sn].snap[cursor].vals
        if haskey(vals, var)
            return (ts, vals[var].value)
        end
    else
        # unknown sn node
        return nothing
    end
    # missing var for sn node
    missing
end

function last_value(abaco, sn, var)
    if haskey(abaco.node, sn)
        cursor = abaco.node[sn].currsnap
        ts = abaco.node[sn].snap[cursor].ts
        vals = abaco.node[sn].snap[cursor].vals
        if haskey(vals, var)
            return vals[var].value
        end
    else
        # unknown sn node
        return nothing
    end
    # missing var for sn node
    missing
end

function get_values(abaco, sn, var)
    result = OrderedDict{Int, Float64}()

    if haskey(abaco.node, sn)
        cursor = abaco.node[sn].currsnap
        for i = 1:abaco.ages
            vals = abaco.node[sn].snap[cursor].vals
            ts = abaco.node[sn].snap[cursor].ts
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

The Dict `msg` must contains the keys `ts` and `sn` and a numbers
of other keys managed as input variables.

This function modifies the `payload` dictionary: `sn` and `ts` keys are popped out.  

```julia
    payload = Dict(
        "ts" => nowts(),
        "sn" => "trento.castello",
        "x" => 23.2,
        "y" => 100
    )
    ingest!(abaco, ts, sn, payload)
```
"""
function ingest!(abaco, payload)
    ts = pop!(payload, "ts")
    sn = pop!(payload, "sn")
    ingest(abaco, ts, sn, payload)
end

"""
    ingest(abaco, ts, sn, values)

Adds the input variables include in the dictionary `values`.

```julia
    # now timestamp 
    ts = nowts()

    # short name of network node
    sn = "trento.castello"

    values = Dict(
        "x" => 23.2,
        "y" => 100
    )
    ingest(abaco, ts, sn, values)
```
"""
function ingest(abaco, ts, sn, values)
    snap = getsnap(abaco, ts, sn)
    for (var, val) in values
        snap_add(snap, sn, var, val)
    end
    trigger_formulas(abaco, snap, sn, keys(values))
end

function ingest(abaco, payload::Dict{String, Any})
    ts = payload["ts"]
    sn = payload["sn"]
    snap = getsnap(abaco, ts, sn)
    vars = [var for var in keys(payload) if !(var in ["sn", "ts"])]
    for var in vars
        snap_add(snap, sn, var, payload[var])
    end
    trigger_formulas(abaco, snap, sn, vars)
end


"""
    ingest(abaco, ts::Int, sn::String, var::String, val::Real)

Adds the input variable `var` with value `val`.

* `ts`: timestamp with seconds resolution
* `sn`: scope name 
* `var`: variable name
* `val`: variable value

"""
function ingest(abaco, ts::Int, sn::String, var::String, val::Real)
    snap = getsnap(abaco, ts, sn)
    snap_add(snap, sn, var, val)
    trigger_formulas(abaco, snap, sn, var)
end

function ingest(abaco, ts::Int, sn::String, var::String, val::Vector{<:Real})
    snap = getsnap(abaco, ts, sn)
    snap_add(snap, sn, var, val)
    trigger_formulas(abaco, snap, sn, var)
end

function sum_collected(abaco::Context, sn, variable, ts)
    result = get_collected(abaco, sn, variable, ts)
    if result === nothing
        return nothing
    else
        return PValue(length(result[1]), result[2], sum(result[1]), result[3])
    end
end

function get_collected(abaco::Context, sn, variable, ts)
    result = nothing

    (origin_type, var) = split(variable, ".")

    index = abaco.interval == -1 ? 1 : mvindex(ts, abaco.interval, abaco.ages)

    if haskey(abaco.origins, sn)
        result = LValue(length(abaco.origins[sn]), [])
        for origin_elem in abaco.origins[sn]
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

function sum_collected(abaco, sn, variable)
    ts = nowts()
    sum_collected(abaco, sn, variable, ts)
end

function get_collected(abaco, sn, variable)
    ts = nowts()
    get_collected(abaco, sn, variable, ts)
end

etype(abaco, sn) = haskey(abaco.node, sn) ? abaco.node[sn].tag : DEFAULT_TYPE

snapsetting(abaco, tag) = haskey(abaco.cfg, tag) ? abaco.cfg[tag] : abaco.cfg[DEFAULT_TYPE]

"""
    getsnap(abaco::Context, ts, sn)

Returns the `sn` node snapshot relative to timestamp `ts`.
"""
function getsnap(abaco::Context, ts, sn)
    tag = etype(abaco, sn)
    ## cfg = snapsetting(abaco, tag)

    if !haskey(abaco.node, sn)
        node(abaco, sn, tag)
    end

    if abaco.interval == -1
        snap =  abaco.node[sn].snap[1]
        snap.ts = ts
        return snap
    end

    # get the span
    ropts = span(ts, abaco.interval)
    index = mvindex(ts, abaco.interval, abaco.ages)

    elem = abaco.node[sn]
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
    snap_add(snap::Snap, sn, var::String, val::Real)

Adds the variable value of `sn` node to the `snap` snapshot. 
"""
function snap_add(snap::Snap, sn, var::String, val::Real)
    if !haskey(snap.vals, var)
        # first arrival of variable var
        snap.vals[var] = SValue(val)
    else
        snap.vals[var].value = val
        snap.vals[var].updated = nowts()
    end
end

function snap_add(snap::Snap, sn, var::String, val::PValue)
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

function snap_add(snap::Snap, sn, var::String, val::Vector{<:Real})
    if !haskey(snap.vals, var) || isa(snap.vals[var], SValue)
        # first arrival of variable var
        snap.vals[var] = LValue(sn, val)
    else
        snap.vals[var].value = val
        snap.vals[var].updated = nowts()
    end
end

function snap_add(::Nothing, sn, var::String, values::Any)
    # the target snap is older of any current snap, do nothing
end

function snap_add(::Snap, sn, var::String, value::Any)
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

