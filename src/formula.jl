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
        throw(EvalError(string(formula.expr)))
    end
end    

function advance(s::Symbol, map::Dict{String,Value})
    var = String(s) 
    if haskey(map, var)
        return map[var].value
    else
        throw(UndefVarError(s))
    end
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

getsymbol(::Val{x}) where x = x

function advance(fsym::Val, args, map::Dict{String,Value})
    sym = getsymbol(fsym)
    return eval(sym)([advance(arg, map) for arg in args]...)
end   

