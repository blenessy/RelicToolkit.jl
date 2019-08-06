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
        const LIB = "librelic_gmp_pbc_bn254"

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
        const LIB = "librelic_gmp_pbc_bls381"

        include(joinpath(@__DIR__, "Model.jl"))
        include(joinpath(@__DIR__, "LowLevel.jl"))
        include(joinpath(@__DIR__, "HighLevel.jl"))

        export curve_miller, field_final_exp
        curve_miller(a::EP, b::EP2) = pp_map_oatep_k12!(FP12(undef), a, b)
        field_final_exp(a::FP12) = pp_exp_k12!(FP12(undef), a)
    end
end

end # module
