module RelicToolkit

export BN, FP, FP2, FP6, FP12, EP, EP2

using Libdl

# Load in `deps.jl`, complaining if it does not exist
const DEPS_PATH = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(DEPS_PATH)
    error("RelicToolkit is not installed properly, run Pkg.build(\"RelicToolkit\"), restart Julia and try again")
end
include(DEPS_PATH)

# abstract away the curve
const LIB = librelic_gmp_pbc_bls381
const PREFIX = "gmp_pbc_bls381_"

const BN_READ_BIN = Symbol(PREFIX, :bn_read_bin)
const BN_SIZE_BIN = Symbol(PREFIX, :bn_size_bin)
const CORE_INIT = Symbol(PREFIX, :core_init)
const EP_PARAM_SET_ANY_PAIRF = Symbol(PREFIX, :ep_param_set_any_pairf)
const EP_ADD_BASIC = Symbol(PREFIX, :ep_add_basic)
const EP_ADD_PROJC = Symbol(PREFIX, :ep_add_projc)
const EP_CMP = Symbol(PREFIX, :ep_cmp)
const EP_CURVE_GET_GEN = Symbol(PREFIX, :ep_curve_get_gen)
const EP_NORM = Symbol(PREFIX, :ep_norm)
const EP_PARAM_EMBED = Symbol(PREFIX, :ep_param_embed)
const EP_RAND = Symbol(PREFIX, :ep_rand)
const EP2_CMP = Symbol(PREFIX, :ep2_cmp)
const EP2_RAND = Symbol(PREFIX, :ep2_rand)
const FP_ADD_BASIC = Symbol(PREFIX, :fp_add_basic)
const FP_ADD_INTEG = Symbol(PREFIX, :fp_add_integ)
const FP_PARAM_SET_ANY = Symbol(PREFIX, :fp_param_set_any)
const FP_PRIME_GET = Symbol(PREFIX, :fp_prime_get)
const FP_PRIME_INIT = Symbol(PREFIX, :fp_prime_init)
const FP_RAND = Symbol(PREFIX, :fp_rand)
const FP12_RAND = Symbol(PREFIX, :fp12_rand)
const PP_EXP_K12 = Symbol(PREFIX, :pp_exp_k12)
const PP_MAP_OATEP_K12 = Symbol(PREFIX, :pp_map_oatep_k12)
const PP_MAP_TATEP_K12 = Symbol(PREFIX, :pp_map_tatep_k12)
const PP_MAP_WEILP_K12 = Symbol(PREFIX, :pp_map_weilp_k12)

# Load constants from lib
const MD_LEN = Int(unsafe_load(cglobal((:JL_RLC_MD_LEN, LIB), Csize_t)))
const BN_SIZE = Int(unsafe_load(cglobal((:JL_RLC_BN_SIZE, LIB), Csize_t)))
const BN_ST_SIZE = Int(unsafe_load(cglobal((:JL_BN_ST_SIZE, LIB), Csize_t)))
const LIMB_SIZE = Int(unsafe_load(cglobal((:JL_DIG_T_SIZE, LIB), Csize_t)))
const FP_ST_SIZE = Int(unsafe_load(cglobal((:JL_FP_ST_SIZE, LIB), Csize_t)))
const FP2_ST_SIZE = Int(unsafe_load(cglobal((:JL_FP2_ST_SIZE, LIB), Csize_t)))
const FP3_ST_SIZE = Int(unsafe_load(cglobal((:JL_FP3_ST_SIZE, LIB), Csize_t)))
const G1_ST_SIZE = Int(unsafe_load(cglobal((:JL_G1_ST_SIZE, LIB), Csize_t)))
const G2_ST_SIZE = Int(unsafe_load(cglobal((:JL_G2_ST_SIZE, LIB), Csize_t)))

const FP_SIZE = Int(FP_ST_SIZE // LIMB_SIZE)

const Limb = Base.GMP.Limb

# Module initialization function
function __init__()
    # Always check your dependencies from `deps.jl`
    check_deps()
    # make sure the native lib was configure correctly
    @assert sizeof(Limb) == LIMB_SIZE
    @assert MD_LEN == 32  # SHA256
    @assert BN_SIZE >= 32  # 256-bits
    @assert BN_ST_SIZE == sizeof(BN)
    @assert FP_ST_SIZE == sizeof(FP)
    @assert FP2_ST_SIZE == sizeof(FP2)
    #@assert FP3_ST_SIZE == sizeof(FP3)
    @assert G1_ST_SIZE == sizeof(EP)
    @assert G2_ST_SIZE == sizeof(EP2)
    iszero(ccall((CORE_INIT, LIB), Cint, ())) || error("core_init failed")
    #ccall((FP_PRIME_INIT, LIB), Cint, ())
    iszero(ccall((EP_PARAM_SET_ANY_PAIRF, LIB), Cint, ())) || error("ep_param_set_any_pairf failed")

    @info "$(basename(librelic_gmp_pbc_bls381)) loaded successfully!"
end

const FPData = NTuple{FP_SIZE,Limb}
const FP2Data = NTuple{2,FPData}
const FP6Data = NTuple{3,FP2Data}
const FP12Data = NTuple{2,FP6Data}

mutable struct BN
    alloc::Cint
    user::Cint
    sign::Cint
    dp::NTuple{BN_SIZE,Limb}
    BN() = new(zero(Cint), zero(Cint), zero(Cint), ntuple(_ -> zero(Limb), BN_SIZE))
end

mutable struct FP
    data::FPData
    FP() = new(zero(FPData))
end

mutable struct FP2
    data::FP2Data
    FP2() = new(zero(FP2Data))
end

mutable struct FP6
    data::FP6Data
    FP6() = new(zero(FP6Data))
end

mutable struct FP12
    data::FP12Data
    FP12() = new(zero(FP12Data))
end

mutable struct EP
    x::FPData
    y::FPData
    z::FPData
    norm::Cint
    EP() = new(zero(FPData), zero(FPData), zero(FPData), zero(Cint))
end

mutable struct EP2
    x::FP2Data
    y::FP2Data
    z::FP2Data
    norm::Cint
    EP2() = new(zero(FP2Data), zero(FP2Data), zero(FP2Data), zero(Cint))
end

# TODO: use fp_cmp for improved security
Base.:(==)(a::T, b::T) where {T <: Union{FP,FP2,FP6,FP12}} = a.data == b.data
Base.:(==)(p::EP, q::EP) = iszero(ccall((EP_CMP, LIB), Cint, (Ref{EP}, Ref{EP}), p, q))
Base.:(==)(p::EP2, q::EP2) = iszero(ccall((EP2_CMP, LIB), Cint, (Ref{EP2}, Ref{EP2}), p, q))
# 4 x faster but not sure its side-channel resistant
#Base.:(==)(p::T, q::T) where {T <: Union{EP, EP2}} = !iszero(Int(p.x == q.x) & Int(p.y == q.y) & Int(p.z == q.z) & Int(p.norm == q.norm))
Base.zero(::Type{FPData}) = ntuple(_ -> zero(Limb), FP_SIZE)
Base.zero(::Type{FP2Data}) = (zero(FPData), zero(FPData))
Base.zero(::Type{FP6Data}) = (zero(FP2Data), zero(FP2Data), zero(FP2Data))
Base.zero(::Type{FP12Data}) = (zero(FP6Data), zero(FP6Data))
function Base.:(+)(a::EP, b::EP, rest::EP...)
    sum = ep_add_basic(a, b) 
    for x in rest
        ep_add_basic!(sum, sum, x) 
    end
    return sum
end
Base.rand(::Type{FP}) = fp_rand()

function bn_read_bin!(a::BN, bin::Vector{UInt8})
    ccall((BN_READ_BIN, LIB), Cvoid, (Ref{BN}, Ptr{UInt8}, Cint), a, bin, length(bin))
    return a
end
bn_read_bin(bin::Vector{UInt8}) = bn_read_bin!(BN(), bin::Vector{UInt8})

bn_size_bin(a::BN) = ccall((BN_SIZE_BIN, LIB), Cint, (Ref{BN},), a)

function ep_add_basic!(c::EP, a::EP, b::EP)
    ccall((EP_ADD_BASIC, LIB), Cvoid, (Ref{EP}, Ref{EP}, Ref{EP}), c, a, b)
    return c
end
ep_add_basic(a::EP, b::EP) = ep_add_basic!(EP(), a, b)

function ep_add_projc!(c::EP, a::EP, b::EP)
    ccall((EP_ADD_PROJC, LIB), Cvoid, (Ref{EP}, Ref{EP}, Ref{EP}), c, a, b)
    return c
end
ep_add_projc(a::EP, b::EP) = ep_add_projc!(EP(), a, b)

function ep_curve_get_gen!(g::EP)
    ccall((EP_CURVE_GET_GEN, LIB), Cvoid, (Ref{EP},), g)
    return g
end
ep_curve_get_gen() = ep_curve_get_gen!(EP())

function ep_norm!(r::EP, p::EP)
    ccall((EP_NORM, LIB), Cvoid, (Ref{EP}, Ref{EP}), r, p)
    return r
end
ep_norm(p::EP) = ep_norm!(EP(), p)

function ep_param_embed()
    return ccall((EP_PARAM_EMBED, LIB), Cint, ())
end

function ep_rand!(ep::EP)
    ccall((EP_RAND, LIB), Cvoid, (Ref{EP},), ep)
    return ep
end
ep_rand() = ep_rand!(EP())

function ep2_rand!(ep::EP2)
    ccall((EP2_RAND, LIB), Cvoid, (Ref{EP2},), ep)
    return ep
end
ep2_rand() = ep2_rand!(EP2())

function fp_add_basic!(c::FP, a::FP, b::FP)
    ccall((FP_ADD_BASIC, LIB), Cvoid, (Ref{FP}, Ref{FP}, Ref{FP}), c, a, b)
    return c
end
fp_add_basic(a::FP, b::FP) = fp_add_basic!(FP(), a, b)

function fp_add_integ!(c::FP, a::FP, b::FP)
    ccall((FP_ADD_INTEG, LIB), Cvoid, (Ref{FP}, Ref{FP}, Ref{FP}), c, a, b)
    return c
end
fp_add_integ(a::FP, b::FP) = fp_add_integ!(FP(), a, b)

function fp_prime_get()
    return unsafe_load(ccall((FP_PRIME_GET, LIB), Ptr{FP}, ()))
end

function fp_rand!(fp::FP)
    ccall((FP_RAND, LIB), Cvoid, (Ref{FP},), fp)
    return fp
end
fp_rand() = fp_rand!(FP())

function fp12_rand!(a::FP12)
    ccall((FP12_RAND, LIB), Cvoid, (Ref{FP12},), a)
    return a
end
fp12_rand() = fp12_rand!(FP12())

function md_hmac(in::Vector{UInt8}, key::Vector{UInt8})
    mac = zeros(UInt8, MD_LEN)
    ccall((:md_hmac, LIB), Cvoid, (Ref{UInt8}, Ptr{UInt8}, Cint, Ptr{UInt8}, Cint),
        mac, in, length(in), key, length(key))
    return mac
end

function pp_exp_k12!(c::FP12, a::FP12)
    ccall((PP_EXP_K12, LIB), Cvoid, (Ref{FP12}, Ref{FP12}), c, a)
    return c
end
pp_exp_k12(a::FP12) = pp_exp_k12!(FP12(), a)

function pp_map_oatep_k12!(r::FP12, p::EP, q::EP2)
    ccall((PP_MAP_OATEP_K12, LIB), Cvoid, (Ref{FP12}, Ref{EP}, Ref{EP2}), r, p, q)
    return r
end
pp_map_oatep_k12(p::EP, q::EP2) = pp_map_oatep_k12!(FP12(), p, q)

function pp_map_tatep_k12!(r::FP12, p::EP, q::EP2)
    ccall((PP_MAP_TATEP_K12, LIB), Cvoid, (Ref{FP12}, Ref{EP}, Ref{EP2}), r, p, q)
    return r
end
pp_map_tatep_k12(p::EP, q::EP2) = pp_map_tatep_k12!(FP12(), p, q)

function pp_map_weilp_k12!(r::FP12, p::EP, q::EP2)
    ccall((PP_MAP_WEILP_K12, LIB), Cvoid, (Ref{FP12}, Ref{EP}, Ref{EP2}), r, p, q)
    return r
end
pp_map_weilp_k12(p::EP, q::EP2) = pp_map_weilp_k12!(FP12(), p, q)

end # module
