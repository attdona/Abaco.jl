using Statistics

#
#     eval_progressive(formula::Formula, map::Dict{String,SValue})
# 
# Compute the progressive defined by `formula`, looking up the values of
# inputs variables in `map`, and returns the result.
# 
# In case of error throws [`Abaco.EvalError`](@ref).
#
function eval_progressive(formula::Formula, map::Dict)
    try
        return progressive_advance(formula.expr, map)
    catch ex
        # for error troubleshooting
        # showerror(stdout, ex, catch_backtrace())
        throw(EvalError(string(formula.expr), ex))
    end
end    

function progressive_advance(s::Symbol, map::Dict)
    var = String(s) 
    if haskey(map, var)
        return map[var].value
    else
        throw(UndefVarError(s))
    end
end    

function progressive_advance(x::Number, map::Dict)
    return x
end    

function progressive_advance(e::Expr, map::Dict)
    return progressive_advance(Val(e.head), e.args, map)
end

function progressive_advance(::Val{:call}, args, map::Dict)
    return progressive_advance(Val(args[1]), args[2:end], map)
end

function progressive_advance(::Val{:ref}, args, map::Dict)
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


function progressive_advance(fsym::Val, args, map::Dict)
    sym = getsymbol(fsym)
    if isdefined(Statistics, sym)
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
        error("Unknow operator $(string(sym))")
    end
end   

