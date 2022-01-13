


#
#    extractor(formula_def::String)
#
# Extract the formula name and the variables from `formula_def`. 
#
function extractor(formula_def)
    try
        ast = Meta.parse(string(formula_def))
        formula::Formula = Formula(formula_def, ast)
        find_symbol(ast, formula)
        return formula
    catch ex
        throw(WrongFormula(formula_def))
    end
end    

# Look up symbol and return value, or throw.
function find_symbol(s::Symbol, formula::Formula)
    push!(formula.inputs, String(s))
end    

function find_symbol(x::Number, formula::Formula)
    # do nothing
end    

# To parse an expression, convert the head to a singleton
# domain, so that Julia can dispatch on that domain.
function find_symbol(e::Expr, formula::Formula)
    find_symbol(Val(e.head), e.args, formula)
end

# Call the function named in args[1]
function find_symbol(::Val{:call}, args, formula::Formula)
    find_symbol(Val(args[1]), args[2:end], formula)
end

function find_symbol(::Val{:.}, args, formula::Formula)
    qn = args[2].value
    push!(formula.inputs, "$(args[1]).$qn")
end


# formula definition
function find_symbol(::Val{:(=)}, args, formula::Formula)
    # formula name
    formula.output = String(args[1])
    formula.expr = args[2]
    find_symbol(args[2], formula)
end

function find_symbol(::Val, args, formula::Formula)
    for arg ∈ args
        find_symbol(arg, formula)
    end
end
