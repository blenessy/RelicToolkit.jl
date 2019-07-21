module RelicToolkit

export BN, FP, FP2, FP6, FP12, EP, EP2

using Libdl

# Load in `deps.jl`, complaining if it does not exist
const DEPS_PATH = joinpath(@__DIR__, "..", "deps", "deps.jl")
isfile(DEPS_PATH) || error("RelicToolkit is not installed properly, run Pkg.build(\"RelicToolkit\"), restart Julia and try again")

include(DEPS_PATH)

const Limb = Base.GMP.Limb

# abstract away the curve
const LIBNAME = get(ENV, "RELICLIB", "librelic_gmp_pbc_bls381") * "." * Libdl.dlext
const LIB = joinpath(dirname(librelic_gmp_pbc_bls381), LIBNAME)
isfile(LIB) || error("Native lib not found: $LIB")

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
    iszero(ccall((:core_init, LIB), Cint, ())) || error("core_init failed")
    iszero(ccall((:ep_param_set_any_pairf, LIB), Cint, ())) || error("ep_param_set_any_pairf failed")

    @info "$LIB loaded successfully!"
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
        ccall((:fp_prime_conv_dig, LIB), Cvoid, (Ref{FP}, Limb), fp, n)
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

Base.:(==)(a::BN, b::BN) = iszero(ccall((:bn_cmp, LIB), Cint, (Ref{BN}, Ref{BN}), a, b))
Base.:(==)(a::FP, b::FP) = iszero(ccall((:fp_cmp, LIB), Cint, (Ref{FP}, Ref{FP}), a, b))
Base.:(==)(a::FP2, b::FP2) = iszero(ccall((:fp2_cmp, LIB), Cint, (Ref{FP2}, Ref{FP2}), a, b))
Base.:(==)(a::FP6, b::FP6) = iszero(ccall((:fp6_cmp, LIB), Cint, (Ref{FP6}, Ref{FP6}), a, b))
Base.:(==)(a::FP12, b::FP12) = iszero(ccall((:fp12_cmp, LIB), Cint, (Ref{FP12}, Ref{FP12}), a, b))
Base.:(==)(p::EP, q::EP) = iszero(ccall((:ep_cmp, LIB), Cint, (Ref{EP}, Ref{EP}), p, q))
Base.:(==)(p::EP2, q::EP2) = iszero(ccall((:ep2_cmp, LIB), Cint, (Ref{EP2}, Ref{EP2}), p, q))
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

Base.iszero(a::BN) = isone(ccall((:bn_is_zero, LIB), Cint, (Ref{BN},), a))
Base.iszero(a::FP) = isone(ccall((:fp_is_zero, LIB), Cint, (Ref{FP},), a))
Base.iszero(a::FP2) = isone(ccall((:fp2_is_zero, LIB), Cint, (Ref{FP2},), a))
Base.iszero(a::FP6) = isone(ccall((:fp6_is_zero, LIB), Cint, (Ref{FP6},), a))
Base.iszero(a::FP12) = isone(ccall((:fp12_is_zero, LIB), Cint, (Ref{FP12},), a))

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
    ccall((:fp_prime_conv, LIB), Cvoid, (Ref{FP}, Ref{BN}), fp, bn)
    return fp
end
function BN(fp::FP)
    bn = BN()
    ccall((:fp_prime_back, LIB), Cvoid, (Ref{BN}, Ref{FP}), bn, fp)
    return bn
end

function bn_read_bin!(a::BN, bin::Vector{UInt8})
    ccall((:bn_read_bin, LIB), Cvoid, (Ref{BN}, Ptr{UInt8}, Cint), a, bin, length(bin))
    return a
end
bn_read_bin(bin::Vector{UInt8}) = bn_read_bin!(BN(), bin::Vector{UInt8})
bn_size_bin(a::BN) = ccall((:bn_size_bin, LIB), Cint, (Ref{BN},), a)

function ep_add_basic!(c::EP, a::EP, b::EP)
    ccall((:ep_add_basic, LIB), Cvoid, (Ref{EP}, Ref{EP}, Ref{EP}), c, a, b)
    return c
end
ep_add_basic(a::EP, b::EP) = ep_add_basic!(EP(), a, b)

function ep_add_projc!(c::EP, a::EP, b::EP)
    ccall((:ep_add_projc, LIB), Cvoid, (Ref{EP}, Ref{EP}, Ref{EP}), c, a, b)
    return c
end
ep_add_projc(a::EP, b::EP) = ep_add_projc!(EP(), a, b)

function ep_curve_get_gen!(g::EP)
    ccall((:ep_curve_get_gen, LIB), Cvoid, (Ref{EP},), g)
    return g
end
ep_curve_get_gen() = ep_curve_get_gen!(EP())

function ep_norm!(r::EP, p::EP)
    ccall((:ep_norm, LIB), Cvoid, (Ref{EP}, Ref{EP}), r, p)
    return r
end
ep_norm(p::EP) = ep_norm!(EP(), p)
ep_param_embed() = ccall((:ep_param_embed, LIB), Cint, ())

function ep_rand!(ep::EP)
    ccall((:ep_rand, LIB), Cvoid, (Ref{EP},), ep)
    return ep
end
ep_rand() = ep_rand!(EP())

function ep2_rand!(ep::EP2)
    ccall((:ep2_rand, LIB), Cvoid, (Ref{EP2},), ep)
    return ep
end
ep2_rand() = ep2_rand!(EP2())

function fp_add_basic!(c::FP, a::FP, b::FP)
    ccall((:fp_add_basic, LIB), Cvoid, (Ref{FP}, Ref{FP}, Ref{FP}), c, a, b)
    return c
end
fp_add_basic(a::FP, b::FP) = fp_add_basic!(FP(), a, b)

function fp_exp_slide!(c::FP, a::FP, b::BN)
    ccall((:fp_exp_slide, LIB), Cvoid, (Ref{FP}, Ref{FP}, Ref{BN}), c, a, b)
    return c
end
fp_exp_slide(a::FP, b::BN) = fp_exp_slide!(FP(), a, b)

function fp_hlv_basic!(c::FP, a::FP)
    ccall((:fp_hlv_basic, LIB), Cvoid, (Ref{FP}, Ref{FP}), c, a)
    return c
end
fp_hlv_basic(a::FP) = fp_hlv_basic!(FP(), a)

function fp_inv_lower!(c::FP, a::FP)
    ccall((:fp_inv_lower, LIB), Cvoid, (Ref{FP}, Ref{FP}), c, a)
    return c
end
fp_inv_lower(a::FP) = fp_inv_lower!(FP(), a)

function fp_mul_comba!(c::FP, a::FP, b::FP)
    ccall((:fp_mul_comba, LIB), Cvoid, (Ref{FP}, Ref{FP}, Ref{FP}), c, a, b)
    return c
end
fp_mul_comba(a::FP, b::FP) = fp_mul_comba!(FP(), a, b)

function fp_neg_basic!(c::FP, a::FP)
    ccall((:fp_neg_basic, LIB), Cvoid, (Ref{FP}, Ref{FP}), c, a)
    return c
end
fp_neg_basic(a::FP) = fp_neg_basic!(FP(), a)

function fp_prime_get()
    fp = ccall((:fp_prime_get, LIB), Ptr{Limb}, ())
    bn = BN(used=FP_SIZE)
    unsafe_copyto!(unsafe_bnptr(bn), fp, bn.used)
    return BigInt(bn)
end

function fp_rand!(fp::FP)
    ccall((:fp_rand, LIB), Cvoid, (Ref{FP},), fp)
    return fp
end
fp_rand() = fp_rand!(FP())


function fp_sqr_comba!(c::FP, a::FP)
    ccall((:fp_sqr_comba, LIB), Cvoid, (Ref{FP}, Ref{FP}), c, a)
    return c
end
fp_sqr_comba(a::FP) = fp_sqr_comba!(FP(), a)

function fp_srt!(c::FP, a::FP)
    ccall((:fp_srt, LIB), Cvoid, (Ref{FP}, Ref{FP}), c, a)
    return c
end
fp_srt(a::FP) = fp_srt!(FP(), a)

function fp_sub_basic!(c::FP, a::FP, b::FP)
    ccall((:fp_sub_basic, LIB), Cvoid, (Ref{FP}, Ref{FP}, Ref{FP}), c, a, b)
    return c
end
fp_sub_basic(a::FP, b::FP) = fp_sub_basic!(FP(), a, b)

function fp2_add_integ!(c::FP2, a::FP2, b::FP2)
    ccall((:fp2_add_integ, LIB), Cvoid, (Ref{FP2}, Ref{FP2}, Ref{FP2}), c, a, b)
    return c
end
fp2_add_integ(a::FP2, b::FP2) = fp2_add_integ!(FP2(), a, b)

function fp2_exp!(c::FP2, a::FP2, b::BN)
    ccall((:fp2_exp, LIB), Cvoid, (Ref{FP2}, Ref{FP2}, Ref{BN}), c, a, b)
    return c
end
fp2_exp(a::FP2, b::BN) = fp2_exp!(FP2(), a, b)

function fp2_inv!(c::FP2, a::FP2)
    ccall((:fp2_inv, LIB), Cvoid, (Ref{FP2}, Ref{FP2}), c, a)
    return c
end
fp2_inv(a::FP2) = fp2_inv!(FP2(), a)

function fp2_mul_integ!(c::FP2, a::FP2, b::FP2)
    ccall((:fp2_mul_integ, LIB), Cvoid, (Ref{FP2}, Ref{FP2}, Ref{FP2}), c, a, b)
    return c
end
fp2_mul_integ(a::FP2, b::FP2) = fp2_mul_integ!(FP2(), a, b)

function fp2_neg!(c::FP2, a::FP2)
    ccall((:fp2_neg, LIB), Cvoid, (Ref{FP2}, Ref{FP2}), c, a)
    return c
end
fp2_neg(a::FP2) = fp2_neg!(FP2(), a)

function fp2_rand!(a::FP2)
    ccall((:fp2_rand, LIB), Cvoid, (Ref{FP2},), a)
    return a
end
fp2_rand() = fp2_rand!(FP2())

function fp2_sub_integ!(c::FP2, a::FP2, b::FP2)
    ccall((:fp2_sub_integ, LIB), Cvoid, (Ref{FP2}, Ref{FP2}, Ref{FP2}), c, a, b)
    return c
end
fp2_sub_integ(a::FP2, b::FP2) = fp2_sub_integ!(FP2(), a, b)

function fp2_sqr_integ!(c::FP2, a::FP2)
    ccall((:fp2_sqr_integ, LIB), Cvoid, (Ref{FP2}, Ref{FP2}), c, a)
    return c
end
fp2_sqr_integ(a::FP2) = fp2_sqr_integ!(FP2(), a)

function fp6_add!(c::FP6, a::FP6, b::FP6)
    ccall((:fp6_add, LIB), Cvoid, (Ref{FP6}, Ref{FP6}, Ref{FP6}), c, a, b)
    return c
end
fp6_add(a::FP6, b::FP6) = fp6_add!(FP6(), a, b)

function fp6_exp!(c::FP6, a::FP6, b::BN)
    ccall((:fp6_exp, LIB), Cvoid, (Ref{FP6}, Ref{FP6}, Ref{BN}), c, a, b)
    return c
end
fp6_exp(a::FP6, b::BN) = fp6_exp!(FP6(), a, b)

function fp6_inv!(c::FP6, a::FP6)
    ccall((:fp6_inv, LIB), Cvoid, (Ref{FP6}, Ref{FP6}), c, a)
    return c
end
fp6_inv(a::FP6) = fp6_inv!(FP6(), a)

function fp6_mul_lazyr!(c::FP6, a::FP6, b::FP6)
    ccall((:fp6_mul_lazyr, LIB), Cvoid, (Ref{FP6}, Ref{FP6}, Ref{FP6}), c, a, b)
    return c
end
fp6_mul_lazyr(a::FP6, b::FP6) = fp6_mul_lazyr!(FP6(), a, b)

function fp6_neg!(c::FP6, a::FP6)
    ccall((:fp6_neg, LIB), Cvoid, (Ref{FP6}, Ref{FP6}), c, a)
    return c
end
fp6_neg(a::FP6) = fp6_neg!(FP6(), a)

function fp6_rand!(a::FP6)
    ccall((:fp6_rand, LIB), Cvoid, (Ref{FP6},), a)
    return a
end
fp6_rand() = fp6_rand!(FP6())

function fp6_sub!(c::FP6, a::FP6, b::FP6)
    ccall((:fp6_sub, LIB), Cvoid, (Ref{FP6}, Ref{FP6}, Ref{FP6}), c, a, b)
    return c
end
fp6_sub(a::FP6, b::FP6) = fp6_sub!(FP6(), a, b)

function fp6_sqr!(c::FP6, a::FP6)
    ccall((:fp6_sqr, LIB), Cvoid, (Ref{FP6}, Ref{FP6}), c, a)
    return c
end
fp6_sqr(a::FP6) = fp6_sqr!(FP6(), a)

function fp12_add!(c::FP12, a::FP12, b::FP12)
    ccall((:fp12_add, LIB), Cvoid, (Ref{FP12}, Ref{FP12}, Ref{FP12}), c, a, b)
    return c
end
fp12_add(a::FP12, b::FP12) = fp12_add!(FP12(), a, b)

function fp12_exp!(c::FP12, a::FP12, b::BN)
    ccall((:fp12_exp, LIB), Cvoid, (Ref{FP12}, Ref{FP12}, Ref{BN}), c, a, b)
    return c
end
fp12_exp(a::FP12, b::BN) = fp12_exp!(FP12(), a, b)

function fp12_inv!(c::FP12, a::FP12)
    ccall((:fp12_inv, LIB), Cvoid, (Ref{FP12}, Ref{FP12}), c, a)
    return c
end
fp12_inv(a::FP12) = fp12_inv!(FP12(), a)

function fp12_mul_lazyr!(c::FP12, a::FP12, b::FP12)
    ccall((:fp12_mul_lazyr, LIB), Cvoid, (Ref{FP12}, Ref{FP12}, Ref{FP12}), c, a, b)
    return c
end
fp12_mul_lazyr(a::FP12, b::FP12) = fp12_mul_lazyr!(FP12(), a, b)

function fp12_neg!(c::FP12, a::FP12)
    ccall((:fp12_neg, LIB), Cvoid, (Ref{FP12}, Ref{FP12}), c, a)
    return c
end
fp12_neg(a::FP12) = fp12_neg!(FP12(), a)

function fp12_rand!(a::FP12)
    ccall((:fp12_rand, LIB), Cvoid, (Ref{FP12},), a)
    return a
end
fp12_rand() = fp12_rand!(FP12())

function fp12_sub!(c::FP12, a::FP12, b::FP12)
    ccall((:fp12_sub, LIB), Cvoid, (Ref{FP12}, Ref{FP12}, Ref{FP12}), c, a, b)
    return c
end
fp12_sub(a::FP12, b::FP12) = fp12_sub!(FP12(), a, b)

function fp12_sqr_lazyr!(c::FP12, a::FP12)
    ccall((:fp12_sqr_lazyr, LIB), Cvoid, (Ref{FP12}, Ref{FP12}), c, a)
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
    ccall((:pp_exp_k12, LIB), Cvoid, (Ref{FP12}, Ref{FP12}), c, a)
    return c
end
pp_exp_k12(a::FP12) = pp_exp_k12!(FP12(), a)

function pp_map_oatep_k12!(r::FP12, p::EP, q::EP2)
    ccall((:pp_map_oatep_k12, LIB), Cvoid, (Ref{FP12}, Ref{EP}, Ref{EP2}), r, p, q)
    return r
end
pp_map_oatep_k12(p::EP, q::EP2) = pp_map_oatep_k12!(FP12(), p, q)

function pp_map_tatep_k12!(r::FP12, p::EP, q::EP2)
    ccall((:pp_map_tatep_k12, LIB), Cvoid, (Ref{FP12}, Ref{EP}, Ref{EP2}), r, p, q)
    return r
end
pp_map_tatep_k12(p::EP, q::EP2) = pp_map_tatep_k12!(FP12(), p, q)

function pp_map_weilp_k12!(r::FP12, p::EP, q::EP2)
    ccall((:pp_map_weilp_k12, LIB), Cvoid, (Ref{FP12}, Ref{EP}, Ref{EP2}), r, p, q)
    return r
end
pp_map_weilp_k12(p::EP, q::EP2) = pp_map_weilp_k12!(FP12(), p, q)

end # module
