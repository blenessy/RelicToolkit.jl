export field_add, field_sub, field_neg, field_mul, field_sqr, field_inv, field_exp,
    curve_add, curve_dbl, curve_gen, curve_map, curve_mul, curve_neg, curve_order, curve_sub,
    md_sha256

Base.:(==)(a::BN, b::BN) = iszero(ccall((:bn_cmp, LIB), Cint, (Ref{BN}, Ref{BN}), a, b))
Base.:(>)(a::BN, b::BN) = isone(ccall((:bn_cmp, LIB), Cint, (Ref{BN}, Ref{BN}), a, b))
Base.:(<)(a::BN, b::BN) = b > a
Base.:(<=)(a::BN, b::BN) = !(a > b)
Base.:(>=)(a::BN, b::BN) = !(a < b)

Base.:(*)(a::BN, b) = bn_mul_comba!(BN(), a, BN(b))
Base.:(*)(a::BN, b::BN) = bn_mul_comba!(BN(), b, a)
Base.:(*)(a::Integer, b::BN) = b * a
Base.:(*)(a::BN, b::ULimbMax) = bn_mul_dig!(BN(), a, convert(Limb, b))
function Base.:(*)(a::BN, b::SLimbMax)
    negb = -b
    c = BN()
    if signbit(b)
        bn_mul_dig!(c, a, convert(Limb, negb))
        c.sign = xor(c.sign, 1)
    else # side-channel resistance by balancing the if else branches
        c.sign = xor(c.sign, 1) # side-channel resistance (no logical effect)
        bn_mul_dig!(c, a, convert(Limb, b))
    end
    return c
end

Base.:(+)(a::BN, b) = bn_add!(BN(), a, BN(b))
Base.:(+)(a::BN, b::BN) = bn_add!(BN(), a, b)
Base.:(+)(a::Integer, b::BN) = b + a
Base.:(+)(a::BN, b::ULimbMax) = bn_add_dig!(BN(), a, convert(Limb, b))
function Base.:(+)(a::BN, b::SLimbMax)
    negb = -b
    return signbit(b) ? bn_sub_dig!(BN(), a, convert(Limb, negb)) : bn_add_dig!(BN(), a, convert(Limb, b))
end

Base.:(-)(a::BN) = bn_neg!(BN(), a)
Base.:(-)(a::BN, b) = bn_sub!(BN(), a, BN(b))
Base.:(-)(a::BN, b::BN) = bn_sub!(BN(), a, b)
Base.:(-)(a::Integer, b::BN) = -b + a
Base.:(-)(a::BN, b::ULimbMax) = bn_sub_dig!(BN(), a, convert(Limb, b))
function Base.:(-)(a::BN, b::SLimbMax)
    negb = -b
    return signbit(b) ? bn_add_dig!(BN(), a, convert(Limb, negb)) : bn_sub_dig!(BN(), a, convert(Limb, b))
end

# function Base.invmod(a::BN, m::BN)
#     c, d = BN(), BN()
#     ccall((:bn_gcd_ext_lehme, LIB), Cvoid, (Ref{BN}, Ref{BN}, Ptr{BN}, Ref{BN}, Ref{BN}), c, d, C_NULL, a, m)
#     if !isone(c)
#         val = (BigInt(a), BigInt(m))
#         throw(DomainError(val, "Greatest common divisor is $(val[1])."))
#     end
#     return bn_mod_basic!(c, isone(a.sign) ? bn_sub!(d, m, d) : bn_add!(d, m, d), m)
# end

# TODO: this is slower than the BigInt variant, but faster then bn_gcd_ext_lehme above
Base.invmod(a::BN, m) = BN(invmod(BigInt(a), m))
Base.invmod(a, m::BN) = BN(invmod(a, BigInt(m)))
Base.invmod(a::BN, m::BN) = BN(invmod(BigInt(a), BigInt(m)))

Base.:(==)(a::FP, b::FP) = iszero(ccall((:fp_cmp, LIB), Cint, (Ref{FP}, Ref{FP}), a, b))
Base.:(==)(a::FP2, b::FP2) = iszero(ccall((:fp2_cmp, LIB), Cint, (Ref{FP2}, Ref{FP2}), a, b))
Base.:(==)(a::FP6, b::FP6) = iszero(ccall((:fp6_cmp, LIB), Cint, (Ref{FP6}, Ref{FP6}), a, b))
Base.:(==)(a::FP12, b::FP12) = iszero(ccall((:fp12_cmp, LIB), Cint, (Ref{FP12}, Ref{FP12}), a, b))
Base.:(==)(p::EP, q::EP) = iszero(ccall((:ep_cmp, LIB), Cint, (Ref{EP}, Ref{EP}), p, q))
Base.:(==)(p::EP2, q::EP2) = iszero(ccall((:ep2_cmp, LIB), Cint, (Ref{EP2}, Ref{EP2}), p, q))

Base.:(+)(a::FPX, b::FPX) = field_add(a, b)
Base.:(-)(a::FPX, b::FPX) = field_sub(a, b)
Base.:(-)(a::FPX) = field_neg(a)
Base.:(*)(a::FPX, b::FPX) = field_mul(a, b)
Base.:(*)(a::FPX, b::Integer) = field_mul(a, typeof(a)(b))
Base.:(*)(a::Integer, b::FPX) = field_mul(b, typeof(b)(a))
Base.:(÷)(a::FPX, b::FPX) = field_mul(a, field_inv(b))
Base.:(//)(a::FPX, b::FPX) = field_mul(a, field_inv(b))
Base.:(^)(a::FPX, b::BN) = field_exp(a, b)
Base.:(^)(a::FPX, b::Integer) = field_exp(a, BN(b))
Base.inv(a::FPX) = field_inv(a)

Base.:(+)(a::EPX, b::EPX) = curve_add(a, b)
Base.:(-)(a::EPX, b::EPX) = curve_sub(a, b)
Base.:(-)(a::EPX) = curve_neg(a)
Base.:(*)(a::EPX, b::BN) = curve_mul(a, b)
Base.:(*)(a::BN, b::EPX) = curve_mul(b, a)
Base.:(*)(a::EPX, b::Integer) = curve_mul(a, BN(b))
Base.:(*)(a::Integer, b::EPX) = curve_mul(b, BN(a))

Base.rand(::Type{BN}; bits=MD_LEN_BITS) = bn_rand!(BN(), bits)
Base.rand(::Type{FP}) = fp_rand!(FP(undef))
Base.rand(::Type{FP2}) = fp2_rand!(FP2(undef))
Base.rand(::Type{FP6}) = fp6_rand!(FP6(undef))
Base.rand(::Type{FP12}) = fp12_rand!(FP12(undef))
Base.rand(::Type{EP}) = ep_rand!(EP(undef))
Base.rand(::Type{EP2}) = ep2_rand!(EP2(undef))

# optimised iszero methods
Base.iszero(a::BN) = isone(ccall((:bn_is_zero, LIB), Cint, (Ref{BN},), a))
Base.iszero(a::FP) = isone(ccall((:fp_is_zero, LIB), Cint, (Ref{FP},), a))
Base.iszero(a::FP2) = isone(ccall((:fp2_is_zero, LIB), Cint, (Ref{FP2},), a))
Base.iszero(a::FP6) = isone(ccall((:fp6_is_zero, LIB), Cint, (Ref{FP6},), a))
Base.iszero(a::FP12) = isone(ccall((:fp12_is_zero, LIB), Cint, (Ref{FP12},), a))

Base.zero(::Type{BN}) = BN()
Base.zero(::Type{FP}) = FP()
Base.zero(::Type{FP2}) = FP2()
Base.zero(::Type{FP6}) = FP6()
Base.zero(::Type{FP12}) = FP12()
Base.zero(::Type{EP}) = EP()
Base.zero(::Type{EP2}) = EP2()
Base.zero(::BN) = BN()
Base.zero(::FP) = FP()
Base.zero(::FP2) = FP2()
Base.zero(::FP6) = FP6()
Base.zero(::FP12) = FP12()
Base.zero(::EP) = EP()
Base.zero(::EP2) = EP2()

Base.one(::Type{BN}) = BN(1)
Base.one(::Type{FP}) = FP(1)
Base.one(::Type{FP2}) = FP2(1)
Base.one(::Type{FP6}) = FP6(1)
Base.one(::Type{FP12}) = FP12(1)
Base.one(::BN) = BN(1)
Base.one(::FP) = FP(1)
Base.one(::FP2) = FP2(1)
Base.one(::FP6) = FP6(1)
Base.one(::FP12) = FP12(1)

Base.isvalid(a::EP) = isone(ccall((:ep_is_valid, LIB), Cint, (Ref{EP},), a))
Base.isvalid(a::EP2) = isone(ccall((:ep2_is_valid, LIB), Cint, (Ref{EP2},), a))

Base.isinf(a::EP) = isone(ccall((:ep_is_infty, LIB), Cint, (Ref{EP},), a))
Base.isinf(a::EP2) = isone(ccall((:ep_is_infty, LIB), Cint, (Ref{EP2},), a))

Base.string(bn::BN) = string(BigInt(bn))

Base.Vector{UInt8}(a::BN) = bn_write_bin!(Vector{UInt8}(undef, bn_size_bin(a)), a)
Base.Vector{UInt8}(a::EP; pack=true) = ep_write_bin!(Vector{UInt8}(undef, ep_size_bin(a, pack)), a, pack)
Base.Vector{UInt8}(a::EP2; pack=true) = ep2_write_bin!(Vector{UInt8}(undef, ep2_size_bin(a, pack)), a, pack)

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
#Base.BigInt(fp::FP) = BigInt(BN(fp))

# automatic promotion rules
#Base.promote_rule(::Type{BN}, ::Type{Int}) = BN
#Base.promote_rule(::Type{BN}, ::Type{BigInt}) = BigInt

Base.mod(a::BN, m::BN) = bn_mod_basic!(BN(), a, m)
Base.mod(a, m::BN) = bn_mod_basic!(BN(), BN(a), m)
Base.mod(a::BN, m) = bn_mod_basic!(BN(), a, BN(m))

field_add(a::FP, b::FP) = fp_add_basic!(FP(undef), a, b)
field_sub(a::FP, b::FP) = fp_sub_basic!(FP(undef), a, b)
field_neg(a::FP) = fp_neg_basic!(FP(undef), a)
field_mul(a::FP, b::FP) = fp_mul_comba!(FP(undef), a, b)
field_sqr(a::FP) = fp_sqr_comba!(FP(undef), a)
field_inv(a::FP) = fp_inv_lower!(FP(undef), a)
field_exp(a::FP, b::BN) = fp_exp_slide!(FP(undef), a, b)

field_add(a::FP2, b::FP2) = fp2_add_integ!(FP2(undef), a, b)
field_sub(a::FP2, b::FP2) = fp2_sub_integ!(FP2(undef), a, b)
field_neg(a::FP2) = fp2_neg!(FP2(undef), a)
field_mul(a::FP2, b::FP2) = fp2_mul_integ!(FP2(undef), a, b)
field_sqr(a::FP2) = fp2_sqr_integ!(FP2(undef), a)
field_inv(a::FP2) = fp2_inv!(FP2(undef), a)
field_exp(a::FP2, b::BN) = fp2_exp!(FP2(undef), a, b)

field_add(a::FP6, b::FP6) = fp6_add!(FP6(undef), a, b)
field_sub(a::FP6, b::FP6) = fp6_sub!(FP6(undef), a, b)
field_neg(a::FP6) = fp6_neg!(FP6(undef), a)
field_mul(a::FP6, b::FP6) = fp6_mul_lazyr!(FP6(undef), a, b)
field_sqr(a::FP6) = fp6_sqr_lazyr!(FP6(undef), a)
field_inv(a::FP6) = fp6_inv!(FP6(undef), a)
field_exp(a::FP6, b::BN) = fp6_exp!(FP6(undef), a, b)

field_add(a::FP12, b::FP12) = fp12_add!(FP12(undef), a, b)
field_sub(a::FP12, b::FP12) = fp12_sub!(FP12(undef), a, b)
field_neg(a::FP12) = fp12_neg!(FP12(undef), a)
field_mul(a::FP12, b::FP12) = fp12_mul_lazyr!(FP12(undef), a, b)
field_sqr(a::FP12) = fp12_sqr_lazyr!(FP12(undef), a)
field_inv(a::FP12) = fp12_inv!(FP12(undef), a)
field_exp(a::FP12, b::BN) = fp12_exp!(FP12(undef), a, b)

curve_add(a::EP, b::EP) = ep_add_basic!(EP(undef), a, b)
curve_dbl(a::EP) = ep_dbl_basic!(EP(undef), a)
curve_gen(::Type{EP}) = ep_curve_get_gen!(EP(undef))
curve_map(::Type{EP}, msg::Vector{UInt8}) = ep_map!(EP(undef), msg)
curve_mul(a::EP, b::BN) = ep_mul_lwnaf!(EP(undef), a, b)
curve_neg(a::EP) = ep_neg_basic!(EP(undef), a)
curve_order(::Type{EP}) = ep_curve_get_ord!(BN())
curve_sub(a::EP, b::EP) = ep_sub_basic!(EP(undef), a, b)

curve_add(a::EP2, b::EP2) = ep2_add_basic!(EP2(undef), a, b)
curve_dbl(a::EP2) = ep2_dbl_basic!(EP2(undef), a)
curve_gen(::Type{EP2}) = ep2_curve_get_gen!(EP2(undef))
curve_map(::Type{EP2}, msg::Vector{UInt8}) = ep2_map!(EP2(undef), msg)
curve_mul(a::EP2, b::BN) = ep2_mul_lwnaf!(EP2(undef), a, b)
curve_neg(a::EP2) = ep2_neg_basic!(EP2(undef), a)
curve_order(::Type{EP2}) = ep2_curve_get_ord!(BN())
curve_sub(a::EP2, b::EP2) = ep2_sub_basic!(EP2(undef), a, b)

md_sha256(msg::Vector{UInt8}) = md_map_sh256(msg)
