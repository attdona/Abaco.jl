
function origins_vals(abaco::Context, sn, ts)
    vals = Dict()

    type = etype(abaco, sn)
    ## cfg = snapsetting(abaco, type)
    index = abaco.interval == -1 ? 1 : mvindex(ts, abaco.interval, abaco.ages)

    if haskey(abaco.origins, sn)
        for origin_elem in abaco.origins[sn]
            ropts = span(ts, abaco.interval)
            snap = origin_elem.snap[index]
            #@debug "origin_elem [$(origin_elem.type).$(origin_elem.sn)]: $snap"
            for (var, val) in snap.vals
                newvar = "$(origin_elem.type).$var"
                if !haskey(vals, newvar)
                    value = LValue(length(abaco.origins[sn]), [])
                    vals[newvar] = value
                end
                #@debug "$sn var $newvar: appending $(val.value) (was $(vals[newvar].value))"
                if (ropts === snap.ts)
                    append!(vals[newvar].value, val.value)
                end
            end
        end
    end
    vals
end

function propagate(abaco::Context, snap, sn, formula_name)
    ts = snap.ts
    (etype, target) = abaco.target[sn]
    var = "$etype.$formula_name"
    @debug "[$sn]: ts:$ts - propagating $var to element [$target]"
    trigger_formulas(abaco, getsnap(abaco, ts, target), target, var)
end

function trigger_formulas(abaco, snap, sn, var::String)
    if haskey(abaco.target, sn)
        propagate(abaco, snap, sn, var)
    end

    poll_formulas(abaco, snap, sn, var)
end

function trigger_formulas(abaco, snap, sn, vars)
    for var in vars
        # propagate input variables to target 
        if haskey(abaco.target, sn)
            propagate(abaco, snap, sn, var)
        end
    end
    poll_formulas(abaco, snap, sn, vars)
end

# 
#     poll_formulas(abaco, snap, sn, vars)
# 
# Check the completion status of all formulas that depends on `vars`.
# 
function poll_formulas(abaco, snap, sn, vars)
    type = etype(abaco, sn)
    cfg = snapsetting(abaco, type)
    formulas = dependents(abaco, type, vars)

    @debug "[$sn] formulas that depends on [$vars]: $formulas"
    for formula_name in formulas
        fstate = snap.outputs[formula_name]

        # pull up the origins variables
        ovals = origins_vals(abaco, sn, snap.ts)
        allvals = merge(snap.vals, ovals)
        result = poll(cfg, fstate, allvals)
        
        @debug "poll($formula_name) = $result"
        if result !== nothing 
            snap_add(snap, sn, formula_name, result)

            # propagate to target 
            if haskey(abaco.target, sn)
                #(etype, target) = abaco.target[sn]
                propagate(abaco, snap, sn, formula_name)
            end

            if cfg.oncomplete !== nothing
                if cfg.handle === nothing
                    cfg.oncomplete(snap.ts,
                                   sn,
                                   formula_name,
                                   result,
                                   allvals)
                else
                    cfg.oncomplete(cfg.handle,
                                   snap.ts,
                                   sn,
                                   formula_name,
                                   result,
                                   allvals)
                end
            end
        end
    end
end

function trigger_formulas(abaco, ::Nothing, sn, var, value)
end

# 
#     poll(abaco, formula_state::FormulaState, vals::Dict)
# 
# Returns the formula value if the formula is computable.
#     
# Returns `NaN` when some input variables are missing because
# the formula cannot run to completion.  
#
function poll(setting::SnapsSetting, formula_state::FormulaState, vals::Dict)
    formula = setting.formula[formula_state.f]
    # Step 1: decide if the formula may be evaluated: all variables are collected
    for v in formula.inputs
        if !(haskey(vals, v) && isready(vals[v]))
            return nothing
        end
    end
    
    # Step 2: evaluate the formula
    if !formula_state.done
        if setting.emitone
            formula_state.done = true
        end
        result = eval(formula, vals)
        return result
    end
    return nothing
end
