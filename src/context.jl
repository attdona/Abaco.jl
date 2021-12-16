using OrderedCollections

function last_point(abaco, sn, var)
    if haskey(abaco.element, sn)
        cursor = abaco.element[sn].currsnap
        ts = abaco.element[sn].snap[cursor].ts
        vals = abaco.element[sn].snap[cursor].vals
        if haskey(vals, var)
            return (ts, vals[var].value)
        end
    else
        # unknown sn element
        return nothing
    end
    # missing var for sn element
    missing
end

function last_value(abaco, sn, var)
    if haskey(abaco.element, sn)
        cursor = abaco.element[sn].currsnap
        ts = abaco.element[sn].snap[cursor].ts
        vals = abaco.element[sn].snap[cursor].vals
        if haskey(vals, var)
            return vals[var].value
        end
    else
        # unknown sn element
        return nothing
    end
    # missing var for sn element
    missing
end

function get_values(abaco, sn, var)
    result = OrderedDict{Int, Float64}()

    if haskey(abaco.element, sn)
        cursor = abaco.element[sn].currsnap
        for i = 1:abaco.ages
            vals = abaco.element[sn].snap[cursor].vals
            ts = abaco.element[sn].snap[cursor].ts
            if haskey(vals, var)
                result[ts] = vals[var].value
            end
            cursor = cursor == 1 ? abaco.ages : cursor - 1
        end
    end
    result
end


"""
    add_values!(abaco, payload)

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
    add_values!(abaco, ts, sn, payload)
```
"""
function add_values!(abaco, payload)
    ts = pop!(payload, "ts")
    sn = pop!(payload, "sn")
    add_values(abaco, ts, sn, payload)
end

"""
    add_values(abaco, ts, sn, values)

Adds the input variables include in the dictionary `values`.

```julia
    # now timestamp 
    ts = nowts()

    # short name of network element
    sn = "trento.castello"

    values = Dict(
        "x" => 23.2,
        "y" => 100
    )
    add_values(abaco, ts, sn, values)
```
"""
function add_values(abaco, ts, sn, values)
    snap = getsnap(abaco, ts, sn)
    for (var, val) in values
        snap_add(snap, sn, var, val)
    end
    trigger_formulas(abaco, snap, sn, keys(values))
end

"""
    add_value(abaco, ts::Int, sn::String, var::String, val::Real)

Adds the input variable `var` with value `val`.

* `ts`: timestamp with seconds resolution
* `sn`: scope name 
* `var`: variable name
* `val`: variable value

"""
function add_value(abaco, ts::Int, sn::String, var::String, val::Real)
    snap = getsnap(abaco, ts, sn)
    snap_add(snap, sn, var, val)
    trigger_formulas(abaco, snap, sn, var)
end

function add_value(abaco, ts::Int, sn::String, var::String, val::Vector{<:Real})
    snap = getsnap(abaco, ts, sn)
    snap_add(snap, sn, var, val)
    trigger_formulas(abaco, snap, sn, var)
end

function sum_collected(abaco::Context, sn, variable, ts)
    result = get_collected(abaco, sn, variable, ts)
    if result === nothing
        return nothing
    else
        return PValue(length(result[1])/result[2], sum(result[1]), result[3])
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
            if haskey(snap.vals, var) && origin_type == origin_elem.type
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

etype(abaco, sn) = haskey(abaco.element, sn) ? abaco.element[sn].type : DEFAULT_TYPE

snapsetting(abaco, type) = haskey(abaco.cfg, type) ? abaco.cfg[type] : abaco.cfg[DEFAULT_TYPE]

function getsnap(abaco::Context, ts, sn)
    type = etype(abaco, sn)
    ## cfg = snapsetting(abaco, type)

    if !haskey(abaco.element, sn)
        add_element(abaco, sn, type)
    end

    if abaco.interval == -1
    
        snap =  abaco.element[sn].snap[1]
        snap.ts = ts
        return snap
    end

    # get the span
    ropts = span(ts, abaco.interval)
    index = mvindex(ts, abaco.interval, abaco.ages)

    elem = abaco.element[sn]
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

function snap_add(snap::Snap, sn, var::String, val::Real)
    if !haskey(snap.vals, var)
        # first arrival of variable var
        snap.vals[var] = SValue(val)
    else
        snap.vals[var].value = val
        snap.vals[var].updated = time()
    end
end

function snap_add(snap::Snap, sn, var::String, val::Vector{<:Real})
    if !haskey(snap.vals, var) || isa(snap.vals[var], SValue)
        # first arrival of variable var
        snap.vals[var] = LValue(sn, val)
    else
        snap.vals[var].value = val
        snap.vals[var].updated = time()
    end
end

function snap_add(::Nothing, sn, var::String, values::Any)
    # the target snap is older of any current snap, do nothing
end

function snap_add(::Snap, sn, var::String, value::Any)
    # it is not a real value, do nothing
end


function setup_settings(abaco::Context,
                        type;
                        handle=missing,
                        oncomplete=missing,
                        emitone=missing)
    if !haskey(abaco.cfg, type)
        abaco.cfg[type] = SnapsSetting(handle === missing ? nothing : handle,
                                       emitone === missing ? false : emitone,
                                       oncomplete === missing ? nothing : oncomplete)
    else
        if handle !== missing
            abaco.cfg[type].handle = handle
        end
        if oncomplete !== missing
            abaco.cfg[type].oncomplete = oncomplete
        end
        if emitone !== missing
            abaco.cfg[type].emitone = emitone
        end
    end
end


function add_element(abaco::Context, sn, type)
    # if type is unknow then fallback to the default settings
    ##settings = get(abaco.cfg, type, abaco.cfg[DEFAULT_TYPE])
    if abaco.interval == -1
        el = Element(sn, type)
    else
        el = Element(sn, type, abaco.ages)
    end

    if haskey(abaco.cfg, type)
            for formula in values(abaco.cfg[type].formula)
                for snap in values(el.snap)
                    snap.outputs[formula.output] = FormulaState(false, formula.output)
                end
            end
    end

    abaco.element[sn] = el
    el
end

function add_origin(abaco::Context, target, sn, type)
    elem = add_element(abaco, sn, type)

    if haskey(abaco.origins, target.sn)
        push!(abaco.origins[target.sn], elem)
    else
        abaco.origins[target.sn] = Set([elem])
    end
    abaco.target[sn] = (type, target.sn)
end

"""

"""
function add_formulas(abaco, df)
    for (type, name, expression) in eachrow(df[1])
        if !haskey(abaco.cfg, type)
            abaco.cfg[type] = SnapsSetting(nothing, -1, 1, false, nothing)
        end
        setting = abaco.cfg[type]
        formula = add_formula(setting, name, expression)
        #@info "set $(row.type)::$(formula.output) formula"
        
        # create a formula state for each element with type==row.type
        for el in values(abaco.element)
            #@info "$(el.sn): $(el.type) == $(row.type)"
            if el.type == row.type
                for snap in values(el.snap)
                    snap.outputs[formula.output] = FormulaState(false, formula.output)
                end
            end
        end
    end
end

function add_formula(abaco::Context, formula_def)
    setting = abaco.cfg[DEFAULT_TYPE]
    add_formula(setting, formula_def)
end


function add_formula(abaco::Context, type, name, expression)
    if !haskey(abaco.cfg, type)
        abaco.cfg[type] = SnapsSetting(nothing, -1, 1, false, nothing)
    end
    setting = abaco.cfg[type]
    formula = add_formula(setting, name, expression)
    #@info "set $(row.type)::$(formula.output) formula"
    
    # create a formula state for each element with type==row.type
    for el in values(abaco.element)
        #@info "$(el.sn): $(el.type) == $(row.type)"
        if el.type == row.type
            for snap in values(el.snap)
                snap.outputs[formula.output] = FormulaState(false, formula.output)
            end
        end
    end
end

"""
    add_formula(setting::SnapsSetting, name, expression)

Add the formula `name` defined by `expression`:
a mathematical expression like `x + y*w`.
"""
add_formula(setting::SnapsSetting, name, expression) = add_formula(setting::SnapsSetting, "$name=$expression")


"""
    add_formula(setting::SnapsSetting, formula_def::String)

Add a formula, with `formula_def` formatted as `"formula_name = expression"`,
where expression is a mathematical expression, like `x + y*w`.
"""
function add_formula(setting::SnapsSetting, formula_def)
    formula = extractor(formula_def)
    setting.formula[formula.output] = formula
    # update the dependents
    for invar in formula.inputs
        if haskey(setting.dependents, invar)
            push!(setting.dependents[invar], formula.output)
        else
            setting.dependents[invar] = Set([formula.output])
        end
    end

    formula
end

"""
    dependents(abaco::Context, type::String, var::String)

Returns the list of expressions that depends on `var`.
"""
function dependents(abaco::Context, type::String, var::String)
    result = String[]
    if haskey(abaco.cfg, type)
        deps = abaco.cfg[type].dependents
        if haskey(deps, var)
            append!(result, deps[var])
        end
    end

    # TODO: merge glob dependents

    result
end

function dependents(abaco::Context, type::String, vars::Base.KeySet)
    result = String[]
    if haskey(abaco.cfg, type)
        deps = abaco.cfg[type].dependents
        append!(result, union([haskey(deps, var) ? deps[var] : [] for var in vars]...))
    end

    # TODO: merge glob dependents

    result
end