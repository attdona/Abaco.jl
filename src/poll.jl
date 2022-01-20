
function all_values(abaco, ts, sn, snap)
    ovals = origins_vals(abaco, sn, ts)
    merge(snap.vals, ovals)
end

function deep_count(abaco, sn, domains)
    #@debug "deep_count: $sn, domains: $domains"
    count = 0
    # TODO: filter on domain value
    if length(domains) === 1
        return length(filter(el->el.domain == domains[1], abaco.origins[sn]))
    else
        for node in abaco.origins[sn]
            count += deep_count(abaco, node.sn, domains[2:end])
        end
    end
    count
end

function origins_vals(abaco::Context, sn, ts)
    vals = Dict()
    index = abaco.interval == -1 ? 1 : mvindex(ts, abaco.interval, abaco.ages)

    if haskey(abaco.origins, sn)
        for origin_elem in abaco.origins[sn]
            ropts = span(ts, abaco.interval)
            snap = origin_elem.snap[index]
            # @debug "$ropts --> origin_elem [$(origin_elem.domain).$(origin_elem.sn)]: $snap"
            
            for (var, val) in all_values(abaco, ts, origin_elem.sn, snap)
                newvar = "$(origin_elem.domain).$var"
                #@debug "[$sn] getting var $newvar"
                if !haskey(vals, newvar)
                    nodes = split(newvar, ".")[1:end-1]
                    value = LValue(deep_count(abaco, sn, nodes), [])
                    vals[newvar] = value
                end
                #@debug "$sn var $newvar: appending $(val.value) (was $(vals[newvar].value))"
                # if interval == -1 considers all values collected at different times
                if (abaco.interval == -1 || ropts === snap.ts)
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
    #@debug "[$sn]: ts:$ts - propagating $var to element [$target]"
    trigger_formulas(abaco, getsnap(abaco, ts, target), target, var)
end

function trigger_formulas(abaco, snap, sn, var::String)
    poll_formulas(abaco, snap, sn, var)

    if haskey(abaco.target, sn)
        propagate(abaco, snap, sn, var)
    end
end

function trigger_formulas(abaco, snap, sn, vars)
    poll_formulas(abaco, snap, sn, vars)

    for var in vars
        # propagate input variables to target 
        if haskey(abaco.target, sn)
            propagate(abaco, snap, sn, var)
        end
    end
end

update_inputs(abaco, snap, sn, formula_name, result::Real) = snap_add(snap, sn, formula_name, result)

function update_inputs(abaco, snap, sn, formula_name, result::PValue)
    snap_add(snap, sn, formula_name, result)
    trigger_formulas(abaco, snap, sn, formula_name)
end

# 
#     poll_formulas(abaco, snap, sn, vars)
# 
# Check the completion status of all formulas that depends on `vars`.
# 
function poll_formulas(abaco, snap, sn, vars)
    domain = etype(abaco, sn)
    cfg = snapsetting(abaco, domain)
    formulas = dependents(abaco, domain, vars)

    @debug "[$sn] formulas that depends on [$vars]: $formulas"
    for formula_name in formulas
        fstate = snap.outputs[formula_name]

        # pull up the origins variables
        ovals = origins_vals(abaco, sn, snap.ts)
        allvals = merge(snap.vals, ovals)
        result = poll(cfg, fstate, allvals)
        
        #@debug "[$sn] allvals: $allvals"
        @debug "[$sn] poll($formula_name) = $result"
        if result !== nothing

            #snap_add(snap, sn, formula_name, result)
            update_inputs(abaco, snap, sn, formula_name, result)

            # propagate to target 
            if haskey(abaco.target, sn)
                #@info "propagate $sn --> $formula_name"
                #propagate(abaco, snap, sn, formula_name)
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
