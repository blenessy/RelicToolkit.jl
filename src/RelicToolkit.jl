module RelicToolkit

export BN, FP, FP2, FP6, FP12, EP, EP2

using Libdl

# Load in `deps.jl`, complaining if it does not exist
const DEPS_PATH = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(DEPS_PATH)
    error("RelicToolkit is not installed properly, run Pkg.build(\"RelicToolkit\"), restart Julia and try again")
end
include(DEPS_PATH)

const Limb = Base.GMP.Limb

# abstract away the curve
const LIB = librelic_gmp_pbc_bls381
const PREFIX = "gmp_pbc_bls381_"

const BN_CMP = Symbol(PREFIX, :bn_cmp)
const BN_GET_DIG = Symbol(PREFIX, :bn_get_dig)
const BN_IS_ZERO = Symbol(PREFIX, :bn_is_zero)
const BN_READ_BIN = Symbol(PREFIX, :bn_read_bin)
const BN_READ_RAW = Symbol(PREFIX, :bn_read_raw)
const BN_SET_DIG = Symbol(PREFIX, :bn_set_dig)
const BN_SIZE_BIN = Symbol(PREFIX, :bn_size_bin)
const BN_WRITE_RAW = Symbol(PREFIX, :bn_write_raw)

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
const FP_CMP = Symbol(PREFIX, :fp_cmp)
const FP_EXP_SLIDE = Symbol(PREFIX, :fp_exp_slide)
const FP_HLV_BASIC = Symbol(PREFIX, :fp_hlv_basic)
const FP_INV_LOWER = Symbol(PREFIX, :fp_inv_lower)
const FP_IS_ZERO = Symbol(PREFIX, :fp_is_zero)
const FP_NEG_BASIC = Symbol(PREFIX, :fp_neg_basic)
const FP_MUL_COMBA = Symbol(PREFIX, :fp_mul_comba)
const FP_PRIME_GET = Symbol(PREFIX, :fp_prime_get)
const FP_PRIME_CONV = Symbol(PREFIX, :fp_prime_conv)
const FP_PRIME_CONV_DIG = Symbol(PREFIX, :fp_prime_conv_dig)
const FP_PRIME_BACK = Symbol(PREFIX, :fp_prime_back)
const FP_SQR_COMBA = Symbol(PREFIX, :fp_sqr_comba)
const FP_SUB_BASIC = Symbol(PREFIX, :fp_sub_basic)
const FP_SRT = Symbol(PREFIX, :fp_srt)
const FP_PRIME_GET = Symbol(PREFIX, :fp_prime_get)
const FP_RAND = Symbol(PREFIX, :fp_rand)

const FP2_ADD_INTEG = Symbol(PREFIX, :fp2_add_integ)
const FP2_CMP = Symbol(PREFIX, :fp2_cmp)
const FP2_EXP = Symbol(PREFIX, :fp2_exp)
const FP2_INV = Symbol(PREFIX, :fp2_inv)
const FP2_IS_ZERO = Symbol(PREFIX, :fp2_is_zero)
const FP2_MUL_INTEG = Symbol(PREFIX, :fp2_mul_integ)
const FP2_NEG = Symbol(PREFIX, :fp2_neg)
const FP2_SQR_INTEG = Symbol(PREFIX, :fp2_sqr_integ)
const FP2_SUB_INTEG = Symbol(PREFIX, :fp2_sub_integ)
const FP2_RAND = Symbol(PREFIX, :fp2_rand)

const FP6_ADD = Symbol(PREFIX, :fp6_add)
const FP6_CMP = Symbol(PREFIX, :fp6_cmp)
const FP6_EXP = Symbol(PREFIX, :fp6_exp)
const FP6_INV = Symbol(PREFIX, :fp6_inv)
const FP6_IS_ZERO = Symbol(PREFIX, :fp6_is_zero)
const FP6_MUL_LAZYR = Symbol(PREFIX, :fp6_mul_lazyr)
const FP6_NEG = Symbol(PREFIX, :fp6_neg)
const FP6_SQR_LAZYR = Symbol(PREFIX, :fp6_sqr_lazyr)
const FP6_SUB = Symbol(PREFIX, :fp6_sub)
const FP6_RAND = Symbol(PREFIX, :fp6_rand)

const FP12_ADD = Symbol(PREFIX, :fp12_add)
const FP12_CMP = Symbol(PREFIX, :fp12_cmp)
const FP12_EXP = Symbol(PREFIX, :fp12_exp)
const FP12_INV = Symbol(PREFIX, :fp12_inv)
const FP12_IS_ZERO = Symbol(PREFIX, :fp12_is_zero)
const FP12_MUL_LAZYR = Symbol(PREFIX, :fp12_mul_lazyr)
const FP12_NEG = Symbol(PREFIX, :fp12_neg)
const FP12_SQR_LAZYR = Symbol(PREFIX, :fp12_sqr_lazyr)
const FP12_SUB = Symbol(PREFIX, :fp12_sub)
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

# const SLimbMax = Base.GMP.SLimbMax
# const ULimbMax = Base.GMP.ULimbMax

#const LIMB_SIZE_BITS_LOG2 = Int(log2(sizeof(Limb))) + 3 

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

const ZERO_BN_DATA = Tuple(zeros(Limb, BN_SIZE))
const ZERO_FP_DATA = Tuple(zeros(Limb, FP_SIZE))
const ZERO_FP2_DATA = (ZERO_FP_DATA, ZERO_FP_DATA)
const ZERO_FP6_DATA = (ZERO_FP2_DATA, ZERO_FP2_DATA, ZERO_FP2_DATA)
const ZERO_FP12_DATA = (ZERO_FP6_DATA, ZERO_FP6_DATA)

mutable struct BN
    alloc::Cint
    used::Cint
    sign::Cint
    dp::NTuple{BN_SIZE,Limb}
    BN(; used=one(Cint), sign=zero(Cint)) = new(BN_SIZE, used, sign, ZERO_BN_DATA)
    function BN(n::Integer)
        negn = signbit(n)
        if negn || sizeof(n) > sizeof(Limb) || !isprimitivetype(typeof(n))
            return BN(BigInt(n))
        end
        bn = BN(sign=negn ? one(Cint) : zero(Cint))
        unsafe_store!(unsafe_bnptr(bn), abs(n))
        return bn
    end
    function BN(n::BigInt)
        bn = BN(used=abs(n.size), sign=signbit(n.size) ? one(Cint) : zero(Cint))
        unsafe_copyto!(unsafe_bnptr(bn), n.d, bn.used)
        return bn
    end
end

mutable struct FP
    data::FPData
    FP() = new(ZERO_FP_DATA)
    function FP(n::Integer) 
        if signbit(n) || sizeof(n) > sizeof(Limb) || !isprimitivetype(typeof(n))
            return FP(BN(n))
        end
        fp = FP()
        ccall((FP_PRIME_CONV_DIG, LIB), Cvoid, (Ref{FP}, Limb), fp, n)
        return fp
    end
    FP(n::BigInt) = FP(BN(n))
end

mutable struct FP2
    data::FP2Data
    FP2() = new(ZERO_FP2_DATA)
    FP2(n::Integer) = new((FP(n).data, ZERO_FP_DATA))
end

mutable struct FP6
    data::FP6Data
    FP6() = new(ZERO_FP6_DATA)
    FP6(n::Integer) = new((FP2(n).data, ZERO_FP2_DATA, ZERO_FP2_DATA))
end

mutable struct FP12
    data::FP12Data
    FP12() = new(ZERO_FP12_DATA)
    FP12(n::Integer) = new((FP6(n).data, ZERO_FP6_DATA))
end

mutable struct EP
    x::FPData
    y::FPData
    z::FPData
    norm::Cint
    EP() = new(ZERO_FP_DATA, ZERO_FP_DATA, ZERO_FP_DATA, zero(Cint))
end

mutable struct EP2
    x::FP2Data
    y::FP2Data
    z::FP2Data
    norm::Cint
    EP2() = new(ZERO_FP2_DATA, ZERO_FP2_DATA, ZERO_FP2_DATA, zero(Cint))
end


# the data is always last so this should be safe for both BN and BigInt
unsafe_bnptr(bn::BN) = Ptr{Limb}(pointer_from_objref(bn) + sizeof(bn) - sizeof(bn.dp))

Base.:(==)(a::BN, b::BN) = iszero(ccall((BN_CMP, LIB), Cint, (Ref{BN}, Ref{BN}), a, b))
Base.:(==)(a::FP, b::FP) = iszero(ccall((FP_CMP, LIB), Cint, (Ref{FP}, Ref{FP}), a, b))
Base.:(==)(a::FP2, b::FP2) = iszero(ccall((FP2_CMP, LIB), Cint, (Ref{FP2}, Ref{FP2}), a, b))
Base.:(==)(a::FP6, b::FP6) = iszero(ccall((FP6_CMP, LIB), Cint, (Ref{FP6}, Ref{FP6}), a, b))
Base.:(==)(a::FP12, b::FP12) = iszero(ccall((FP12_CMP, LIB), Cint, (Ref{FP12}, Ref{FP12}), a, b))
Base.:(==)(p::EP, q::EP) = iszero(ccall((EP_CMP, LIB), Cint, (Ref{EP}, Ref{EP}), p, q))
Base.:(==)(p::EP2, q::EP2) = iszero(ccall((EP2_CMP, LIB), Cint, (Ref{EP2}, Ref{EP2}), p, q))
# 4 x faster but not sure its side-channel resistant
#Base.:(==)(p::T, q::T) where {T <: Union{EP, EP2}} = !iszero(Int(p.x == q.x) & Int(p.y == q.y) & Int(p.z == q.z) & Int(p.norm == q.norm))
# Base.zero(::Type{BN}) = BN()
# Base.zero(::Type{FPData}) = ZERO_FP_DATA
# Base.zero(::Type{FP2Data}) = ZERO_FP2_DATA
# Base.zero(::Type{FP6Data}) = (zero(FP2Data), zero(FP2Data), zero(FP2Data))
# Base.zero(::Type{FP12Data}) = (zero(FP6Data), zero(FP6Data))
Base.:(+)(a::FP, b::FP) = fp_add_basic(a, b)
Base.:(-)(a::FP, b::FP) = fp_sub_basic(a, b)
Base.:(-)(a::FP) = fp_neg_basic(a)
Base.:(*)(a::FP, b::FP) = fp_mul_comba(a, b)
Base.:(*)(a::FP, b) = fp_mul_comba(a, FP(b))
Base.:(*)(a, b::FP) = fp_mul_comba(FP(a), b)
Base.:(÷)(a::FP, b::FP) = fp_mul_comba(a, fp_inv_lower(b))
Base.:(//)(a::FP, b::FP) = fp_mul_comba(a, fp_inv_lower(b))
Base.:(^)(a::FP, b::BN) = fp_exp_slide(a, b)
Base.:(^)(a::FP, b) = fp_exp_slide(a, BN(b))
Base.sqrt(a::FP) = fp_srt(a)
Base.inv(a::FP) = fp_inv_lower(a)

Base.:(+)(a::FP2, b::FP2) = fp2_add_integ(a, b)
Base.:(-)(a::FP2, b::FP2) = fp2_sub_integ(a, b)
Base.:(-)(a::FP2) = fp2_neg(a)
Base.:(*)(a::FP2, b::FP2) = fp2_mul_integ(a, b)
Base.:(*)(a::FP2, b::Integer) = fp2_mul_integ(a, FP2(b))
Base.:(*)(a::Integer, b::FP2) = fp2_mul_integ(FP2(a), b)
Base.:(÷)(a::FP2, b::FP2) = fp2_mul_integ(a, fp2_inv(b))
Base.:(//)(a::FP2, b::FP2) = fp2_mul_integ(a, fp2_inv(b))
Base.:(^)(a::FP2, b::BN) = fp2_exp(a, b)
Base.:(^)(a::FP2, b::Integer) = fp2_exp(a, BN(b))
Base.inv(a::FP2) = fp2_inv(a)

Base.:(+)(a::FP6, b::FP6) = fp6_add(a, b)
Base.:(-)(a::FP6, b::FP6) = fp6_sub(a, b)
Base.:(-)(a::FP6) = fp6_neg(a)
Base.:(*)(a::FP6, b::FP6) = fp6_mul_lazyr(a, b)
Base.:(*)(a::FP6, b::Integer) = fp6_mul_lazyr(a, FP6(b))
Base.:(*)(a::Integer, b::FP6) = fp6_mul_lazyr(FP6(a), b)
Base.:(÷)(a::FP6, b::FP6) = fp6_mul_lazyr(a, fp6_inv(b))
Base.:(//)(a::FP6, b::FP6) = fp6_mul_lazyr(a, fp6_inv(b))
Base.:(^)(a::FP6, b::BN) = fp6_exp(a, b)
Base.:(^)(a::FP6, b::Integer) = fp6_exp(a, BN(b))
Base.inv(a::FP6) = fp6_inv(a)

Base.:(+)(a::FP12, b::FP12) = fp12_add(a, b)
Base.:(-)(a::FP12, b::FP12) = fp12_sub(a, b)
Base.:(-)(a::FP12) = fp12_neg(a)
Base.:(*)(a::FP12, b::FP12) = fp12_mul_lazyr(a, b)
Base.:(*)(a::FP12, b::Integer) = fp12_mul_lazyr(a, FP12(b))
Base.:(*)(a::Integer, b::FP12) = fp12_mul_lazyr(FP12(a), b)
Base.:(÷)(a::FP12, b::FP12) = fp12_mul_lazyr(a, fp12_inv(b))
Base.:(//)(a::FP12, b::FP12) = fp12_mul_lazyr(a, fp12_inv(b))
Base.:(^)(a::FP12, b::BN) = fp12_exp(a, b)
Base.:(^)(a::FP12, b::Integer) = fp12_exp(a, BN(b))
Base.inv(a::FP12) = fp12_inv(a)

Base.:(+)(a::EP, b::EP) = ep_add_basic(a, b)
Base.rand(::Type{BN}) = BN(fp_rand())
Base.rand(::Type{FP}) = fp_rand()
Base.rand(::Type{FP2}) = fp2_rand()
Base.rand(::Type{FP6}) = fp6_rand()
Base.rand(::Type{FP12}) = fp12_rand()
Base.rand(::Type{EP}) = ep_rand()

Base.iszero(a::BN) = isone(ccall((BN_IS_ZERO, LIB), Cint, (Ref{BN},), a))
Base.iszero(a::FP) = isone(ccall((FP_IS_ZERO, LIB), Cint, (Ref{FP},), a))
Base.iszero(a::FP2) = isone(ccall((FP2_IS_ZERO, LIB), Cint, (Ref{FP2},), a))
Base.iszero(a::FP6) = isone(ccall((FP6_IS_ZERO, LIB), Cint, (Ref{FP6},), a))
Base.iszero(a::FP12) = isone(ccall((FP12_IS_ZERO, LIB), Cint, (Ref{FP12},), a))

function Base.BigInt(bn::BN)
    bigint = Base.GMP.MPZ.realloc2((bn.used * sizeof(Limb)) << 3)
    @assert bigint.alloc >= bn.used
    if isone(bn.sign)
        bigint.size = -bn.used
    else
        bigint.size = iszero(bn) ? 0 : bn.used
    end
    unsafe_copyto!(bigint.d, unsafe_bnptr(bn), bn.used)
    return bigint
end
# NOTE: can be hand optimised but its probably a poor RoI
Base.BigInt(fp::FP) = BigInt(BN(fp))

# Outer constructors to solve bidirectional dependencies.
# TODO: Can this be solved with inner constructors ?
function FP(bn::BN)
    fp = FP()
    ccall((FP_PRIME_CONV, LIB), Cvoid, (Ref{FP}, Ref{BN}), fp, bn)
    return fp
end
function BN(fp::FP)
    bn = BN()
    ccall((FP_PRIME_BACK, LIB), Cvoid, (Ref{BN}, Ref{FP}), bn, fp)
    return bn
end

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
ep_param_embed() = ccall((EP_PARAM_EMBED, LIB), Cint, ())

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

function fp_exp_slide!(c::FP, a::FP, b::BN)
    ccall((FP_EXP_SLIDE, LIB), Cvoid, (Ref{FP}, Ref{FP}, Ref{BN}), c, a, b)
    return c
end
fp_exp_slide(a::FP, b::BN) = fp_exp_slide!(FP(), a, b)

function fp_hlv_basic!(c::FP, a::FP)
    ccall((FP_HLV_BASIC, LIB), Cvoid, (Ref{FP}, Ref{FP}), c, a)
    return c
end
fp_hlv_basic(a::FP) = fp_hlv_basic!(FP(), a)

function fp_inv_lower!(c::FP, a::FP)
    ccall((FP_INV_LOWER, LIB), Cvoid, (Ref{FP}, Ref{FP}), c, a)
    return c
end
fp_inv_lower(a::FP) = fp_inv_lower!(FP(), a)

function fp_mul_comba!(c::FP, a::FP, b::FP)
    ccall((FP_MUL_COMBA, LIB), Cvoid, (Ref{FP}, Ref{FP}, Ref{FP}), c, a, b)
    return c
end
fp_mul_comba(a::FP, b::FP) = fp_mul_comba!(FP(), a, b)

function fp_neg_basic!(c::FP, a::FP)
    ccall((FP_NEG_BASIC, LIB), Cvoid, (Ref{FP}, Ref{FP}), c, a)
    return c
end
fp_neg_basic(a::FP) = fp_neg_basic!(FP(), a)

function fp_prime_get()
    fp = ccall((FP_PRIME_GET, LIB), Ptr{Limb}, ())
    bn = BN(used=FP_SIZE)
    unsafe_copyto!(unsafe_bnptr(bn), fp, bn.used)
    return BigInt(bn)
end

function fp_rand!(fp::FP)
    ccall((FP_RAND, LIB), Cvoid, (Ref{FP},), fp)
    return fp
end
fp_rand() = fp_rand!(FP())


function fp_sqr_comba!(c::FP, a::FP)
    ccall((FP_SQR_COMBA, LIB), Cvoid, (Ref{FP}, Ref{FP}), c, a)
    return c
end
fp_sqr_comba(a::FP) = fp_sqr_comba!(FP(), a)

function fp_srt!(c::FP, a::FP)
    ccall((FP_SRT, LIB), Cvoid, (Ref{FP}, Ref{FP}), c, a)
    return c
end
fp_srt(a::FP) = fp_srt!(FP(), a)

function fp_sub_basic!(c::FP, a::FP, b::FP)
    ccall((FP_SUB_BASIC, LIB), Cvoid, (Ref{FP}, Ref{FP}, Ref{FP}), c, a, b)
    return c
end
fp_sub_basic(a::FP, b::FP) = fp_sub_basic!(FP(), a, b)

function fp2_add_integ!(c::FP2, a::FP2, b::FP2)
    ccall((FP2_ADD_INTEG, LIB), Cvoid, (Ref{FP2}, Ref{FP2}, Ref{FP2}), c, a, b)
    return c
end
fp2_add_integ(a::FP2, b::FP2) = fp2_add_integ!(FP2(), a, b)

function fp2_exp!(c::FP2, a::FP2, b::BN)
    ccall((FP2_EXP, LIB), Cvoid, (Ref{FP2}, Ref{FP2}, Ref{BN}), c, a, b)
    return c
end
fp2_exp(a::FP2, b::BN) = fp2_exp!(FP2(), a, b)

function fp2_inv!(c::FP2, a::FP2)
    ccall((FP2_INV, LIB), Cvoid, (Ref{FP2}, Ref{FP2}), c, a)
    return c
end
fp2_inv(a::FP2) = fp2_inv!(FP2(), a)

function fp2_mul_integ!(c::FP2, a::FP2, b::FP2)
    ccall((FP2_MUL_INTEG, LIB), Cvoid, (Ref{FP2}, Ref{FP2}, Ref{FP2}), c, a, b)
    return c
end
fp2_mul_integ(a::FP2, b::FP2) = fp2_mul_integ!(FP2(), a, b)

function fp2_neg!(c::FP2, a::FP2)
    ccall((FP2_NEG, LIB), Cvoid, (Ref{FP2}, Ref{FP2}), c, a)
    return c
end
fp2_neg(a::FP2) = fp2_neg!(FP2(), a)

function fp2_rand!(a::FP2)
    ccall((FP2_RAND, LIB), Cvoid, (Ref{FP2},), a)
    return a
end
fp2_rand() = fp2_rand!(FP2())

function fp2_sub_integ!(c::FP2, a::FP2, b::FP2)
    ccall((FP2_SUB_INTEG, LIB), Cvoid, (Ref{FP2}, Ref{FP2}, Ref{FP2}), c, a, b)
    return c
end
fp2_sub_integ(a::FP2, b::FP2) = fp2_sub_integ!(FP2(), a, b)

function fp2_sqr_integ!(c::FP2, a::FP2)
    ccall((FP2_SQR_INTEG, LIB), Cvoid, (Ref{FP2}, Ref{FP2}), c, a)
    return c
end
fp2_sqr_integ(a::FP2) = fp2_sqr_integ!(FP2(), a)

function fp6_add!(c::FP6, a::FP6, b::FP6)
    ccall((FP6_ADD, LIB), Cvoid, (Ref{FP6}, Ref{FP6}, Ref{FP6}), c, a, b)
    return c
end
fp6_add(a::FP6, b::FP6) = fp6_add!(FP6(), a, b)

function fp6_exp!(c::FP6, a::FP6, b::BN)
    ccall((FP6_EXP, LIB), Cvoid, (Ref{FP6}, Ref{FP6}, Ref{BN}), c, a, b)
    return c
end
fp6_exp(a::FP6, b::BN) = fp6_exp!(FP6(), a, b)

function fp6_inv!(c::FP6, a::FP6)
    ccall((FP6_INV, LIB), Cvoid, (Ref{FP6}, Ref{FP6}), c, a)
    return c
end
fp6_inv(a::FP6) = fp6_inv!(FP6(), a)

function fp6_mul_lazyr!(c::FP6, a::FP6, b::FP6)
    ccall((FP6_MUL_LAZYR, LIB), Cvoid, (Ref{FP6}, Ref{FP6}, Ref{FP6}), c, a, b)
    return c
end
fp6_mul_lazyr(a::FP6, b::FP6) = fp6_mul_lazyr!(FP6(), a, b)

function fp6_neg!(c::FP6, a::FP6)
    ccall((FP6_NEG, LIB), Cvoid, (Ref{FP6}, Ref{FP6}), c, a)
    return c
end
fp6_neg(a::FP6) = fp6_neg!(FP6(), a)

function fp6_rand!(a::FP6)
    ccall((FP6_RAND, LIB), Cvoid, (Ref{FP6},), a)
    return a
end
fp6_rand() = fp6_rand!(FP6())

function fp6_sub!(c::FP6, a::FP6, b::FP6)
    ccall((FP6_SUB, LIB), Cvoid, (Ref{FP6}, Ref{FP6}, Ref{FP6}), c, a, b)
    return c
end
fp6_sub(a::FP6, b::FP6) = fp6_sub!(FP6(), a, b)

function fp6_sqr!(c::FP6, a::FP6)
    ccall((FP6_SQR, LIB), Cvoid, (Ref{FP6}, Ref{FP6}), c, a)
    return c
end
fp6_sqr(a::FP6) = fp6_sqr!(FP6(), a)

function fp12_add!(c::FP12, a::FP12, b::FP12)
    ccall((FP12_ADD, LIB), Cvoid, (Ref{FP12}, Ref{FP12}, Ref{FP12}), c, a, b)
    return c
end
fp12_add(a::FP12, b::FP12) = fp12_add!(FP12(), a, b)

function fp12_exp!(c::FP12, a::FP12, b::BN)
    ccall((FP12_EXP, LIB), Cvoid, (Ref{FP12}, Ref{FP12}, Ref{BN}), c, a, b)
    return c
end
fp12_exp(a::FP12, b::BN) = fp12_exp!(FP12(), a, b)

function fp12_inv!(c::FP12, a::FP12)
    ccall((FP12_INV, LIB), Cvoid, (Ref{FP12}, Ref{FP12}), c, a)
    return c
end
fp12_inv(a::FP12) = fp12_inv!(FP12(), a)

function fp12_mul_lazyr!(c::FP12, a::FP12, b::FP12)
    ccall((FP12_MUL_LAZYR, LIB), Cvoid, (Ref{FP12}, Ref{FP12}, Ref{FP12}), c, a, b)
    return c
end
fp12_mul_lazyr(a::FP12, b::FP12) = fp12_mul_lazyr!(FP12(), a, b)

function fp12_neg!(c::FP12, a::FP12)
    ccall((FP12_NEG, LIB), Cvoid, (Ref{FP12}, Ref{FP12}), c, a)
    return c
end
fp12_neg(a::FP12) = fp12_neg!(FP12(), a)

function fp12_rand!(a::FP12)
    ccall((FP12_RAND, LIB), Cvoid, (Ref{FP12},), a)
    return a
end
fp12_rand() = fp12_rand!(FP12())

function fp12_sub!(c::FP12, a::FP12, b::FP12)
    ccall((FP12_SUB, LIB), Cvoid, (Ref{FP12}, Ref{FP12}, Ref{FP12}), c, a, b)
    return c
end
fp12_sub(a::FP12, b::FP12) = fp12_sub!(FP12(), a, b)

function fp12_sqr_lazyr!(c::FP12, a::FP12)
    ccall((FP12_SQR_LAZYR, LIB), Cvoid, (Ref{FP12}, Ref{FP12}), c, a)
    return c
end
fp12_sqr_lazyr(a::FP12) = fp12_sqr_lazyr!(FP12(), a)

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
