#
#     eval(formula::Formula, map::Dict{String,Value})
# 
# Compute the `formula`, looking up the values of
# inputs variables in `map`, and returns the result.
# 
# In case of error throws [`Abaco.EvalError`](@ref).
#
function eval(formula::Formula, map::Dict{String,Value})
    try
        return advance(formula.expr, map)
    catch ex
        # internal error inspection
        # showerror(stdout, ex, catch_backtrace())
        throw(EvalError(string(formula.expr), ex))
    end
end    

function advance(s::Symbol, map::Dict{String,Value})
    var = String(s) 
    if haskey(map, var)
        return map[var].value[1]
    else
        throw(UndefVarError(s))
    end
end    

function advance(::Val{:.}, map::Dict{String,Value})
    qn = args[2].value
    varname = "$(args[1]).$qn"
    return map[var].value
end

function advance(x::Number, map::Dict{String,Value})
    return x
end    

function advance(e::Expr, map::Dict{String,Value})
    return advance(Val(e.head), e.args, map)
end

function advance(::Val{:call}, args, map::Dict{String,Value})
    return advance(Val(args[1]), args[2:end], map)
end

function advance(::Val{:sum}, args, map::Dict{String,Value})
    node = args[1]
    if isa(node, Symbol)
        var = String(args[1])
    else
        # a dotted variable name like entity.counter
        var = "$(node.args[1]).$(node.args[2].value)"
    end
    if haskey(map, var)
        return sum(map[var].value)
    else
        throw(UndefVarError(s))
    end
end

function advance(::Val{:ref}, args, map::Dict{String,Value})
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

function advance(fsym::Val, args, map::Dict{String,Value})
    sym = getsymbol(fsym)
    return eval(sym)([advance(arg, map) for arg in args]...)
end   

