using Statistics

#
#     eval_kqi(formula::Formula, map::Dict{String,SValue})
# 
# Compute the kqi defined by `formula`, looking up the values of
# inputs variables in `map`, and returns the result.
# 
# In case of error throws [`Abaco.EvalError`](@ref).
#
function eval_kqi(formula::Formula, map::Dict)
    try
        return kqi_advance(formula.expr, map)
    catch ex
        # for error troubleshooting
        # showerror(stdout, ex, catch_backtrace())
        throw(EvalError(string(formula.expr), ex))
    end
end    

function kqi_advance(s::Symbol, map::Dict)
    var = String(s) 
    if haskey(map, var)
        return map[var].value
    else
        throw(UndefVarError(s))
    end
end    

function kqi_advance(x::Number, map::Dict)
    return x
end    

function kqi_advance(e::Expr, map::Dict)
    return kqi_advance(Val(e.head), e.args, map)
end

function kqi_advance(::Val{:call}, args, map::Dict)
    return kqi_advance(Val(args[1]), args[2:end], map)
end

function kqi_advance(::Val{:ref}, args, map::Dict)
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


function kqi_advance(fsym::Val, args, map::Dict)
    sym = getsymbol(fsym)
    if isdefined(Statistics, sym)
        var = string(args[1])
        if haskey(map, var)
            return QValue(length(map[var].value),
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

