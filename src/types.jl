
abstract type Value end

struct PValue <: Value
    contribs::Int # current numbers of contributors
    expected::Int # total number of expected contributors
    value::Float64
    updated::Int64 # time of evaluation
end

mutable struct SValue <: Value
    value::Float64
    updated::Int64 # time of arrival
    SValue(val::Real) = new(val, nowts())
end

mutable struct LValue <: Value
    contribs::Int
    value::Vector{Float64}
    updated::Int64 # greater updated value of the list of values
    LValue(contribs, values) = new(contribs, values, nowts())
    LValue(values::Vector{<:Real}) = new(1, values, nowts())
end

isready(v::SValue) = !isnan(v.value)

isready(v::LValue) = length(v.value) == v.contribs

mutable struct Formula
    output::String
    inputs::Set{String}
    expr::Union{Expr, Symbol}
    progressive::Bool
    Formula(definition, ast) = new(definition, Set(), ast, false)
end

abstract type AbacoError <: Exception end

"""
Wrong formula definition.

[`formula`](@ref) throws `WrongFormula` when a formula is malformed,
for example:

`formula(abaco, "myformula = x + ")`
"""
struct WrongFormula <: AbacoError
    formula::String
end

"""
Formula evaluation failure.

[`ingest`] throws EvalError when a runtime formula evaluation fails,
for example for a wrong numbers of method args:
    
    formula(abaco, "div(x,y,z")
    ingest(abaco, ts, sn, Dict("x"=>10, "y"=>1, "z"=1))

"""
struct EvalError <: AbacoError
    formula::String
    cause::Exception
end

"""
Attempt to get a value with an invalid index.
"""
struct ValueNotFound <: AbacoError
    var::String
    index::Int
end

mutable struct FormulaState
    done::Bool
    f::String
end

"""
Maintains the state of the abaco.

Before adding formulas and values an abaco `MonoContext`
must be initialized by [`abaco_init`](@ref).
"""
mutable struct Snap
    ts::Int64
    vals::Dict{String, SValue} # variable name => value
    outputs::Dict{String, FormulaState} # formula name => state
    Snap(formula) = begin
        outputs = Dict()
        for fname in keys(formula)
            outputs[fname] = FormulaState(false, fname)
        end
        new(0, Dict(), outputs)
    end
end

"""
The settings of snapshots.

Before adding formulas and values the `SnapsSetting`
must be initialized by [`abaco_init`](@ref).
"""
mutable struct SnapsSetting
    handle::Any
    emitone::Bool
    formula::Dict{String, Formula} # formula name => formula
    dependents::Dict{String, Set{String}} # variable => array of formula names where variable is used
    oncomplete::Union{Function, Nothing}
    SnapsSetting(handle,
            emitone,
            oncomplete) = new(handle,
                              emitone,
                              Dict(),
                              Dict(),
                              oncomplete)
end


mutable struct Element
    sn::String
    domain::String
    snap::Dict{Int, Snap}
    currsnap::Int
    Element(sn, domain) = new(sn, domain, Dict(1 => Snap(Dict())), 1)
    Element(sn, domain, ages) = new(sn, domain, Dict(i => Snap(Dict()) for i in 1:ages), 1)
end


"""
The abaco registry. 
"""
mutable struct Context
    interval::Int64
    ages::Int64
    cfg::Dict{String, SnapsSetting}  # domain => snaps setting
    element::Dict{String, Element} # sn => element
    origins::Dict{String, Set{Element}} # sys_2 => [sn_21, sn_22]
    target::Dict{String, Tuple{String, String}} # sn_21 => (sn_21 domain, sys_2)
    oncompletedefault::Union{Function, Nothing}
    Context(interval, ages, oncomplete=nothing) = begin
        new(interval, ages, Dict(), Dict(), Dict(), Dict(), oncomplete)
    end
    Context(interval, ages, settings, oncomplete) = begin
        new(interval, ages, settings, Dict(), Dict(), Dict(), oncomplete)
    end
end


