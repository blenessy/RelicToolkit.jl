export BN, FP, FP2, FP6, FP12, FPX, EP, EP2, EPX, MD_LEN, FP_ST_SIZE

# Load constants from lib
const MD_LEN = Int(unsafe_load(cglobal((:JL_RLC_MD_LEN, LIB), Csize_t)))
const MD_LEN_BITS = MD_LEN * 8
const BN_SIZE = Int(unsafe_load(cglobal((:JL_RLC_BN_SIZE, LIB), Csize_t)))
const BN_ST_SIZE = Int(unsafe_load(cglobal((:JL_BN_ST_SIZE, LIB), Csize_t)))
const LIMB_SIZE = Int(unsafe_load(cglobal((:JL_DIG_T_SIZE, LIB), Csize_t)))
const FP_ST_SIZE = Int(unsafe_load(cglobal((:JL_FP_ST_SIZE, LIB), Csize_t)))
const FP2_ST_SIZE = Int(unsafe_load(cglobal((:JL_FP2_ST_SIZE, LIB), Csize_t)))
const FP3_ST_SIZE = Int(unsafe_load(cglobal((:JL_FP3_ST_SIZE, LIB), Csize_t)))
const G1_ST_SIZE = Int(unsafe_load(cglobal((:JL_G1_ST_SIZE, LIB), Csize_t)))
const G2_ST_SIZE = Int(unsafe_load(cglobal((:JL_G2_ST_SIZE, LIB), Csize_t)))

const FP_SIZE = Int(FP_ST_SIZE // LIMB_SIZE)

# Type aliases 
const Limb = Base.GMP.Limb
const SLimbMax = Base.GMP.SLimbMax
const ULimbMax = Base.GMP.ULimbMax
const FPData = NTuple{FP_SIZE,Limb}
const FP2Data = NTuple{2,FPData}
const FP6Data = NTuple{3,FP2Data}
const FP12Data = NTuple{2,FP6Data}

# Common data used by initializers
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
    BN(; used=one(Cint), sign=zero(Cint), data=ZERO_BN_DATA) = new(BN_SIZE, used, sign, data)
    BN(::UndefInitializer) = new()
    BN(n::Integer) = BN(BigInt(n))
    BN(n::Int) = signbit(n) ? BN(BigInt(n)) : BN(Limb(n)) 
    function BN(n::Limb)
        bn = BN(sign=zero(Cint), used=one(Cint))
        unsafe_store!(unsafe_bnptr(bn), n)
        return bn
    end
    function BN(n::BigInt)
        bn = BN(used=abs(n.size), sign=signbit(n.size) ? one(Cint) : zero(Cint))
        unsafe_copyto!(unsafe_bnptr(bn), n.d, bn.used)
        return bn
    end
    BN(bin::Vector{UInt8}) = bn_read_bin!(BN(), bin)
end

abstract type FPX end
mutable struct FP <: FPX
    data::FPData
    FP() = fp_zero(new())
    FP(::UndefInitializer) = new()
    FP(n::Integer) = FP(BN(n))
    FP(n::Int) = signbit(n) ? FP(BN(n)) : FP(Limb(n))
    function FP(n::Limb) 
        fp = new()
        ccall((:fp_set_dig, LIB), Cvoid, (Ref{FP}, Limb), fp, n)
        return fp
    end
    function FP(bn::BN)
        fp = new()
        ccall((:fp_prime_conv, LIB), Cvoid, (Ref{FP}, Ref{BN}), fp, bn)
        return fp
    end
end

# Outer constructors to solve bidirectional dependencies.
# function BN(fp::FP)
#     bn = BN()
#     ccall((:fp_prime_back, LIB), Cvoid, (Ref{BN}, Ref{FP}), bn, fp)
#     return bn
# end

mutable struct FP2 <: FPX
    data::FP2Data
    FP2() = fp2_zero(new())
    FP2(::UndefInitializer) = new()
    FP2(n::Int) = FP2(Limb(n))
    function FP2(n::Limb) 
        fp = new()
        ccall((:fp2_set_dig, LIB), Cvoid, (Ref{FP2}, Limb), fp, n)
        return fp
    end
end

mutable struct FP6 <: FPX
    data::FP6Data
    FP6() = fp6_zero(new())
    FP6(::UndefInitializer) = new()
    FP6(n::Int) = FP6(Limb(n))
    function FP6(n::Limb) 
        fp = new()
        ccall((:fp6_set_dig, LIB), Cvoid, (Ref{FP6}, Limb), fp, n)
        return fp
    end
end

mutable struct FP12 <: FPX
    data::FP12Data
    FP12() = fp12_zero(new())
    FP12(::UndefInitializer) = new()
    FP12(n::Int) = FP12(Limb(n))
    function FP12(n::Limb) 
        fp = new()
        ccall((:fp12_set_dig, LIB), Cvoid, (Ref{FP12}, Limb), fp, n)
        return fp
    end
end

abstract type EPX end

mutable struct EP <: EPX
    x::FPData
    y::FPData
    z::FPData
    norm::Cint
    EP() = new(ZERO_FP_DATA, ZERO_FP_DATA, ZERO_FP_DATA, zero(Cint))
    EP(::UndefInitializer) = new()
    EP(bin::Vector{UInt8}) = ep_read_bin!(EP(), bin)
end

mutable struct EP2 <: EPX
    x::FP2Data
    y::FP2Data
    z::FP2Data
    norm::Cint
    EP2() = new(ZERO_FP2_DATA, ZERO_FP2_DATA, ZERO_FP2_DATA, zero(Cint))
    EP2(::UndefInitializer) = new()
    EP2(bin::Vector{UInt8}) = ep2_read_bin!(EP2(), bin)
end
