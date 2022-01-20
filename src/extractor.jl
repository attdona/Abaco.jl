


#
#    extractor(formula_def::String)
#
# Extract the formula name and the variables from `formula_def`. 
#
function extractor(formula_def)
    try
        ast = Meta.parse(string(formula_def))
        #dump(ast)
        formula::Formula = Formula(formula_def, ast)
        find_symbol(ast, formula, 0)
        return formula
    catch ex
        throw(WrongFormula(formula_def))
    end
end    

# Look up symbol and return value, or throw.
function find_symbol(s::Symbol, formula::Formula, level)
    push!(formula.inputs, String(s))
end    

function find_symbol(x::Number, formula::Formula, level)
    # do nothing
end    

# To parse an expression, convert the head to a singleton
# domain, so that Julia can dispatch on that domain.
function find_symbol(e::Expr, formula::Formula, exprlevel)

    find_symbol(Val(e.head), e.args, formula, exprlevel+1)
end

# Call the function named in args[1]
function find_symbol(::Val{:call}, args, formula::Formula, level)
    op = args[1]
    if level === 2 && (hasproperty(Statistics, op) || op in [:sum])
        # A progressive has a statistic operator at level 1
        formula.progressive = true
    end

    find_symbol(Val(args[1]), args[2:end], formula, level)
end

function find_symbol(::Val{:.}, args, formula::Formula, level)
    qn = args[2].value
    push!(formula.inputs, "$(args[1]).$qn")
end


# formula definition
function find_symbol(::Val{:(=)}, args, formula::Formula, level)
    # formula name
    formula.output = String(args[1])
    formula.expr = args[2]
    find_symbol(args[2], formula, level)
end

function find_symbol(op::Val, args, formula::Formula, level)
    for arg ∈ args
        find_symbol(arg, formula, level)
    end
end
