
function all_values(abaco, ts, ne, snap)
    ovals = origins_vals(abaco, ne, ts)
    merge(snap.vals, ovals)
end

function deep_count(abaco, ne, domains)
    #@debug "deep_count: $ne, domains: $domains"
    count = 0
    # TODO: filter on tag value
    if length(domains) === 1
        return length(filter(el->el.tag == domains[1], abaco.origins[ne]))
    else
        for node in abaco.origins[ne]
            count += deep_count(abaco, node.ne, domains[2:end])
        end
    end
    count
end

function origins_vals(abaco::Context, ne, ts)
    vals = Dict()
    index = abaco.interval == -1 ? 1 : mvindex(ts, abaco.interval, abaco.ages)

    if haskey(abaco.origins, ne)
        for origin_elem in abaco.origins[ne]
            ropts = span(ts, abaco.interval)
            snap = origin_elem.snap[index]
            # @debug "$ropts --> origin_elem [$(origin_elem.tag).$(origin_elem.ne)]: $snap"
            
            for (var, val) in all_values(abaco, ts, origin_elem.ne, snap)
                newvar = "$(origin_elem.tag).$var"
                #@debug "[$ne] getting var $newvar"
                if !haskey(vals, newvar)
                    nodes = split(newvar, ".")[1:end-1]
                    value = LValue(deep_count(abaco, ne, nodes), [])
                    vals[newvar] = value
                end
                #@debug "$ne var $newvar: appending $(val.value) (was $(vals[newvar].value))"
                # if interval == -1 considers all values collected at different times
                if (abaco.interval == -1 || ropts === snap.ts)
                    append!(vals[newvar].value, val.value)
                end
            end
        end
    end
    vals
end

function propagate(abaco::Context, snap, ne, formula_name)
    ts = snap.ts
    (etype, target) = abaco.target[ne]
    var = "$etype.$formula_name"
    #@debug "[$ne]: ts:$ts - propagating $var to node [$target]"
    trigger_formulas(abaco, getsnap(abaco, ts, target), target, var)
end

function trigger_formulas(abaco, snap, ne, var::String)
    poll_formulas(abaco, snap, ne, var)

    if haskey(abaco.target, ne)
        propagate(abaco, snap, ne, var)
    end
end

function trigger_formulas(abaco, snap, ne, vars)
    poll_formulas(abaco, snap, ne, vars)

    for var in vars
        # propagate input variables to target 
        if haskey(abaco.target, ne)
            propagate(abaco, snap, ne, var)
        end
    end
end

update_inputs(abaco, snap, ne, formula_name, result::Real) = snap_add(snap, ne, formula_name, result)

function update_inputs(abaco, snap, ne, formula_name, result::PValue)
    snap_add(snap, ne, formula_name, result)
    trigger_formulas(abaco, snap, ne, formula_name)
end

# 
#     poll_formulas(abaco, snap, ne, vars)
# 
# Check the completion status of all formulas that depends on `vars`.
# 
function poll_formulas(abaco, snap, ne, vars)
    if snap === nothing
        return
    end
    tag = etype(abaco, ne)
    cfg = snapsetting(abaco, tag)
    formulas = dependents(abaco, tag, vars)

    @debug "[$ne] formulas that depends on [$vars]: $formulas"
    for formula_name in formulas
        fstate = get(snap.outputs, formula_name, FormulaState(false, formula_name))

        # pull up the origins variables
        ovals = origins_vals(abaco, ne, snap.ts)
        allvals = merge(snap.vals, ovals)
        result = poll(cfg, fstate, allvals)
        
        #@debug "[$ne] allvals: $allvals"
        @debug "[$ne] poll($formula_name) = $result"
        if result !== nothing

            #snap_add(snap, ne, formula_name, result)
            update_inputs(abaco, snap, ne, formula_name, result)

            # propagate to target 
            if haskey(abaco.target, ne)
                #@info "propagate $ne --> $formula_name"
                #propagate(abaco, snap, ne, formula_name)
            end

            if cfg.oncomplete !== nothing
                if cfg.handle === nothing
                    cfg.oncomplete(snap.ts,
                                   ne,
                                   formula_name,
                                   result,
                                   allvals)
                else
                    cfg.oncomplete(cfg.handle,
                                   snap.ts,
                                   ne,
                                   formula_name,
                                   result,
                                   allvals)
                end
            end
        end
    end
end

function trigger_formulas(abaco, ::Nothing, ne, var, value)
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
    if formula.progressive
        poll_progressive(setting, formula, formula_state, vals)
    else
        poll_simple(setting, formula, formula_state, vals)
    end
end


function poll_simple(setting::SnapsSetting, formula::Formula, formula_state::FormulaState, vals::Dict)
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

function poll_progressive(setting::SnapsSetting, formula::Formula, formula_state::FormulaState, vals::Dict)
    # Step 1: decide if the formula may be evaluated: all variables are collected
    for v in formula.inputs
        if !(haskey(vals, v))
            return nothing
        end
    end
    
    # Step 2: evaluate the formula
    eval_progressive(formula, vals)
end
