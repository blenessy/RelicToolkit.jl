module RelicToolkit

module Config
    macro enabled(id)
        env = split(get(ENV, "LIBRELIC", id), ",")
        return id in env ? :(true) : :(false) 
    end
end

module BN254
    using ..Config: @enabled
    const ENABLED = @enabled("BN254")
    if ENABLED
        import Libdl
        const LIB = joinpath(dirname(@__FILE__), "..", "deps", "usr", "lib", "librelic_gmp_pbc_bn254.$(Libdl.dlext)")
        include(joinpath(@__DIR__, "Model.jl"))
        include(joinpath(@__DIR__, "LowLevel.jl"))
        include(joinpath(@__DIR__, "HighLevel.jl"))

        export curve_miller, field_final_exp
        curve_miller(a::EP, b::EP2) = pp_map_oatep_k12!(FP12(undef), a, b)
        field_final_exp(a::FP12) = pp_exp_k12!(FP12(undef), a)
    end
end

module BLS381
    using ..Config: @enabled
    const ENABLED = @enabled("BLS381")
    if ENABLED
        import Libdl
        const LIB = joinpath(dirname(@__FILE__), "..", "deps", "usr", "lib", "librelic_gmp_pbc_bls381.$(Libdl.dlext)")
        include(joinpath(@__DIR__, "Model.jl"))
        include(joinpath(@__DIR__, "LowLevel.jl"))
        include(joinpath(@__DIR__, "HighLevel.jl"))

        export curve_miller, field_final_exp
        curve_miller(a::EP, b::EP2) = pp_map_oatep_k12!(FP12(undef), a, b)
        field_final_exp(a::FP12) = pp_exp_k12!(FP12(undef), a)
    end
end

# Load in `deps.jl`, complaining if it does not exist
const DEPS_PATH = joinpath(@__DIR__, "..", "deps", "deps.jl")
isfile(DEPS_PATH) || error("RelicToolkit is not installed properly, run Pkg.build(\"RelicToolkit\"), restart Julia and try again")
include(DEPS_PATH)

# Module initialization function
function __init__()
    # Always check your dependencies from `deps.jl`
    check_deps()
end

end # module
