using Abaco
using Test
using SafeTestsets

#DEBUG = get(ENV, "ABACO_DEBUG", "0")
#Abaco.logging(debug = DEBUG=="0" ? [] : [Abaco])


@testset "Abaco.jl" begin
    @testset "unit" begin
        @time @safetestset "get_values" begin include("test_get_values.jl") end
        @time @safetestset "push_value" begin include("test_push_value.jl") end
        @time @safetestset "push_msg" begin include("test_push_msg.jl") end
        @time @safetestset "push_ages" begin include("test_push_ages.jl") end
        @time @safetestset "json" begin include("test_json.jl") end
        @time @safetestset "multiverse" begin include("test_multiverse.jl") end
        @time @safetestset "operators" begin include("test_operators.jl") end
        @time @safetestset "invalid_formula" begin include("test_invalid_formula.jl") end
        @time @safetestset "if" begin include("test_if.jl") end
        @time @safetestset "csv_formulas" begin include("test_csv_formulas.jl") end
        @time @safetestset "co2" begin include("test_co2.jl") end
        @time @safetestset "co2" begin include("test_kqi.jl") end
    end
end
