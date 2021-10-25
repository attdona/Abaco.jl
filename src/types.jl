
mutable struct Value
    dn::String # managed object distinguished name
    value::Number
    recv::Float64 # time of arrival
    Value(dn, val) = new(dn, val, time())
end

mutable struct Formula
    output::String
    inputs::Set{String}
    expr::Union{Expr, Symbol}
    Formula(definition, ast) = new(definition, Set(), ast)
end

abstract type AbacoError <: Exception end

"""
Wrong formula definition.

[`add_formula!`](@ref) throws `WrongFormula` when a formula is malformed,
for example:

`add_formula!(abaco, "myformula = x + ")`
"""
struct WrongFormula <: AbacoError
    formula::String
end

"""
Formula evaluation failure.

[`add_value!`] throws EvalError when a runtime formula evaluation fails,
for example for a wrong numbers of method args:
    
    add_formula!(abaco, "div(x,y,z")
    add_value!(abaco, ts, sn, Dict("x"=>10, "y"=>1, "z"=1))

"""
struct EvalError <: AbacoError
    formula::String
end

mutable struct FormulaState
    done::Bool
    f::String
end

mutable struct Universe
    mark::Int64
    vals::Dict{String, Value} # variable name => (dn => value)
    outputs::Dict{String, FormulaState} # formula name => state
    Universe(formula) = begin
        outputs = Dict()
        for fname in keys(formula)
            outputs[fname] = FormulaState(false, fname)
        end
        new(0, Dict(), outputs)
    end
end

mutable struct Multiverse{N}
    ages::Int
    universe::Dict{Int, Universe}
    Multiverse{N}(formula, dependents) where {N}= new(N, Dict(i => Universe(formula) for i in 1:N))
end

"""
Maintains the state of the abaco.

Before adding formulas and values an abaco `Context`
must be initialized by [`abaco_init`](@ref).
"""
mutable struct Context
    handle::Any
    width::Int64
    ages::Int64
    formula::Dict{String, Formula} # formula name => formula
    dependents::Dict{String, Vector{String}} # independent variable => array of formula names where used
    scopes::Dict{String, Multiverse} # sn => multiverse
    oncomplete::Function
    Context(handle, width, ages, oncomplete) = new(handle,
                                                   width,
                                                   ages,
                                                   Dict(),
                                                   Dict(),
                                                   Dict(),
                                                   oncomplete)
end