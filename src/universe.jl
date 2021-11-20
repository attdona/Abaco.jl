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
    add_values(abaco, ts, sn, payload)
```
"""
function add_values!(abaco, payload)
    ts = pop!(payload, "ts")
    sn = pop!(payload, "sn")
    add_values!(abaco, ts, sn, payload)
end

"""
    add_values!(abaco, ts, sn, values)

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
function add_values!(abaco, ts, sn, values)
    universe = touniverse(abaco, ts, sn)
    for (var, val) in values
        universe_add(universe, sn, var, val)
        poll_formulas(abaco, universe, sn, var, val)
    end
end

"""
    add_value!(abaco, ts::Int, sn::String, var::String, val::Real)

Adds the input variable `var` with value `val`.

* `ts`: timestamp with seconds resolution
* `sn`: scope name 
* `var`: variable name
* `val`: variable value

"""
function add_value!(abaco, ts::Int, sn::String, var::String, val::Real)
    universe = touniverse(abaco, ts, sn)
    universe_add(universe, sn, var, val)
    poll_formulas(abaco, universe, sn, var, val)
end

function add_value!(abaco, ts::Int, sn::String, var::String, val::Vector{<:Real})
    universe = touniverse(abaco, ts, sn)
    universe_add(universe, sn, var, val)
    poll_formulas(abaco, universe, sn, var, val)
end


function touniverse(abaco::Context, ts, sn)
    # get the span
    ropts = span(ts, abaco.interval)
    index = mvindex(ts, abaco.interval, abaco.ages)

    if !haskey(abaco.scopes, sn)
        abaco.scopes[sn] = Multiverse{abaco.ages}(abaco.formula, abaco.dependents)
    end

    universe = abaco.scopes[sn].universe[index]

    if universe.mark < ropts
        universe.mark  = ropts

        # reset the values of universe
        map!(v->begin 
            v.value = []
            v
        end, values(universe.vals))

        for fstate in values(universe.outputs)
            fstate.done = false
        end
    end

    if ropts < universe.mark
        return nothing
    end

    universe
end    

function universe_add(universe::Universe, sn, var::String, val::Real)
    if !haskey(universe.vals, var)
        # first arrival of variable var
        universe.vals[var] = Value(sn, val)
    else
        universe.vals[var].value = [val]
        universe.vals[var].recv = time()
    end
end

function universe_add(universe::Universe, sn, var::String, val::Vector{<:Real})
    if !haskey(universe.vals, var)
        # first arrival of variable var
        universe.vals[var] = Value(sn, val)
    else
        universe.vals[var].value = val
        universe.vals[var].recv = time()
    end
end

function universe_add(::Nothing, sn, var::String, values::Any)
    # the target universe is older of any current universe, do nothing
end

function universe_add(::Universe, sn, var::String, value::Any)
    # it is not a real value, do nothing
end

# 
#     poll_formulas(abaco, universe, sn, var, value)
# 
# Check the completion status of all formulas that depends on `var`.
# 
function poll_formulas(abaco, universe, sn, var, value)
    if haskey(abaco.dependents, var)
        for formula_name in abaco.dependents[var]
            fstate = universe.outputs[formula_name]
            result = poll(abaco, fstate, universe.vals)
            if result !== nothing
                if abaco.handle === nothing
                    abaco.oncomplete(universe.mark,
                                     sn,
                                     formula_name,
                                     result,
                                     universe.vals)
                else
                    abaco.oncomplete(abaco.handle,
                                     universe.mark,
                                     sn,
                                     formula_name,
                                     result,
                                     universe.vals)
                end
            end
        end
    end
end

function poll_formulas(abaco, ::Nothing, sn, var, value)
end


# 
#     poll(abaco, formula_state::FormulaState, vals::Dict)
# 
# Returns the formula value if the formula is computable.
#     
# Returns `NaN` when some input variables are missing because
# the formula cannot run to completion.  
#
function poll(abaco, formula_state::FormulaState, vals::Dict)
    formula = abaco.formula[formula_state.f]
    # Step 1: decide if the formula may be evaluated: all variables are collected
    for v in formula.inputs
        if !(haskey(vals, v) && !isempty(vals[v].value))
            return nothing
        end
    end
    
    # Step 2: evaluate the formula
    if !formula_state.done
        formula_state.done = true
        result = eval(formula, vals)
        return result
    end
    return nothing
end
