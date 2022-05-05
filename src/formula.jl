using Statistics
import Base.+, Base.-, Base.*, Base./

+(x::PValue, y::PValue) = PValue(x.contribs+y.contribs,
                                 x.expected+y.expected,
                                 x.value+y.value,
                                 max(x.updated,y.updated))

-(x::PValue, y::PValue) = PValue(x.contribs+y.contribs,
                                 x.expected+y.expected,
                                 x.value-y.value,
                                 max(x.updated,y.updated))



*(x::PValue, y::PValue) = PValue(x.contribs+y.contribs,
                                 x.expected+y.expected,
                                 x.value*y.value,
                                 max(x.updated,y.updated))


/(x::PValue, y::PValue) = PValue(x.contribs+y.contribs,
                                 x.expected+y.expected,
                                 x.value/y.value,
                                 max(x.updated,y.updated))


"""

"""
function add_formulas(abaco, df)
    for (tag, name, expression) in eachrow(df)
        if !haskey(abaco.cfg, tag)
            abaco.cfg[tag] = SnapsSetting(nothing, false, nothing)
        end
        setting = abaco.cfg[tag]
        f = formula(setting, name, expression)
        
        # create a formula state for each node with el.tag==tag
        for el in values(abaco.node)
            if el.tag == tag
                for snap in values(el.snap)
                    snap.outputs[f.output] = FormulaState(false, f.output)
                end
            end
        end
    end
end

function formula(abaco::Context, formula_def)
    setting = abaco.cfg[DEFAULT_TYPE]
    formula(setting, formula_def)
end


function formula(abaco::Context, name, expression, tag)
    if !haskey(abaco.cfg, tag)
        abaco.cfg[tag] = SnapsSetting(nothing, false, abaco.oncompletedefault)
    end
    setting = abaco.cfg[tag]
    f = formula(setting, name, expression)

    # create a formula state for each node with tag==row.tag
    for el in values(abaco.node)
        if el.tag == tag
            for snap in values(el.snap)
                snap.outputs[f.output] = FormulaState(false, f.output)
            end
        end
    end
    f
end

formula(abaco, name, expression) = formula(abaco, name, expression, "")

"""
    formula(setting::SnapsSetting, name, expression)

Add the formula `name` defined by `expression`:
a mathematical expression like `x + y*w`.
"""
formula(setting::SnapsSetting, name, expression) = formula(setting::SnapsSetting, "$name=$expression")


"""
    formula(setting::SnapsSetting, formula_def::String)

Add a formula, with `formula_def` formatted as `"formula_name = expression"`,
where expression is a mathematical expression, like `x + y*w`.
"""
function formula(setting::SnapsSetting, formula_def)
    formula = extractor(formula_def)
    setting.formula[formula.output] = formula
    setup_formula(setting, formula)
end

function setup_formula(setting::SnapsSetting, formula::Formula)
    setting.formula[formula.output] = formula

    # delete already present dependents, otherwise formula redefinition 
    # could not work as expected
    for dependent in values(setting.dependents)
        delete!(dependent, formula.output)
    end

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


function delete_formula(abaco::Context, name::String, tag::String)
    if !haskey(abaco.cfg, tag)
        abaco.cfg[tag] = SnapsSetting(nothing, false, nothing)
    end
    setting = abaco.cfg[tag]
    formula = setting.formula[name]

    for invar in formula.inputs
        delete!(setting.dependents[invar], name)
    end
    delete!(setting.formula, name)
end


"""
    dependents(abaco::Context, tag::String, var::String)

Returns the list of expressions that depends on `var`.
"""
function dependents(abaco::Context, tag::String, var::String)
    result = String[]
    if haskey(abaco.cfg, tag)
        deps = abaco.cfg[tag].dependents
        if haskey(deps, var)
            append!(result, deps[var])
        end
    end

    # TODO: merge glob dependents

    result
end

function dependents(abaco::Context, tag::String, vars)
    result = String[]
    if haskey(abaco.cfg, tag)
        deps = abaco.cfg[tag].dependents
        append!(result, union([haskey(deps, var) ? deps[var] : [] for var in vars]...))
    end

    # TODO?: merge glob dependents

    result
end

#
#     eval(formula::Formula, map::Dict{String,SValue})
# 
# Compute the `formula`, looking up the values of
# inputs variables in `map`, and returns the result.
# 
# In case of error throws [`Abaco.EvalError`](@ref).
#
function eval(formula::Formula, map::Dict)
    try
        return advance(formula.expr, map)
    catch ex
        # internal error inspection
        # showerror(stdout, ex, catch_backtrace())
        throw(EvalError(string(formula.expr), ex))
    end
end    

function advance(s::Symbol, map::Dict)
    var = String(s) 
    if haskey(map, var)
        return map[var].value
    else
        throw(UndefVarError(s))
    end
end    

function advance(x::Number, map::Dict)
    return x
end    

function advance(e::Expr, map::Dict)
    return advance(Val(e.head), e.args, map)
end

function advance(::Val{:call}, args, map::Dict)
    return advance(Val(args[1]), args[2:end], map)
end

function advance(::Val{:ref}, args, map::Dict)
    var = String(args[1])
    idx = args[2]
    if haskey(map, var)
        if idx <= length(map[var].value)
            return map[var].value[idx]
        else
            throw(ValueNotFound(var, idx))
        end
    else
        throw(UndefVarError(var))
    end
end


getsymbol(::Val{x}) where x = x

function advance(fsym::Val, args, map::Dict)
    sym = getsymbol(fsym)
    if hasproperty(Statistics, sym) || sym === :sum
        var = string(args[1])
        if haskey(map, var)
            return PValue(length(map[var].value),
                          map[var].contribs,
                          eval(sym)(map[var].value),
                          nowts())
        else
            throw(UndefVarError(var))
        end
    else
        return eval(sym)([advance(arg, map) for arg in args]...)
    end
end   

