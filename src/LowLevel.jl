export md_hmac, fp_prime_get

# Module initialization function
function __init__()
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

    @info "$(basename(LIB)) loaded successfully!"
end

# the data is always last so this should be safe for both BN and BigInt
unsafe_bnptr(bn::BN) = Ptr{Limb}(pointer_from_objref(bn) + sizeof(bn) - sizeof(bn.dp))

function bn_rand!(a::BN, bits::Int)
    if bits < 1 || bits > typemax(Cint)
        error("invalid bits specified: $bits")
    end
    ccall((:bn_rand, LIB), Cvoid, (Ref{BN}, Cint, Cint), a, 0, bits)
    return a
end
function bn_read_bin!(a::BN, bin::Vector{UInt8})
    ccall((:bn_read_bin, LIB), Cvoid, (Ref{BN}, Ptr{UInt8}, Cint), a, bin, length(bin))
    return a
end

function bn_mod_basic!(c::BN, a::BN, m::BN)
    ccall((:bn_mod_basic, LIB), Cvoid, (Ref{BN}, Ref{BN}, Ref{BN}), c, a, m)
    return c
end

bn_size_bin(a::BN) = Int(ccall((:bn_size_bin, LIB), Cint, (Ref{BN},), a))

function bn_write_bin!(bin::Vector{UInt8}, a::BN)
    ccall((:bn_write_bin, LIB), Cvoid, (Ptr{UInt8}, Cint, Ref{BN}), bin, length(bin), a)
    return bin
end

function ep_add_projc!(c::EP, a::EP, b::EP)
    ccall((:ep_add_projc, LIB), Cvoid, (Ref{EP}, Ref{EP}, Ref{EP}), c, a, b)
    return c
end

function ep_dbl_projc!(c::EP, a::EP)
    ccall((:ep_dbl_projc, LIB), Cvoid, (Ref{EP}, Ref{EP}), c, a)
    return c
end

function ep_curve_get_gen!(g::EP)
    ccall((:ep_curve_get_gen, LIB), Cvoid, (Ref{EP},), g)
    return g
end

function ep_curve_get_ord!(n::BN)
    ccall((:ep_curve_get_ord, LIB), Cvoid, (Ref{BN},), n)
    return n
end

function ep_map!(p::EP, msg::Vector{UInt8})
    ccall((:ep_map, LIB), Cvoid, (Ref{EP}, Ptr{UInt8}, Cint), p, msg, length(msg))
    return p
end

function ep_mul_lwnaf!(c::EP, a::EP, b::BN)
    ccall((:ep_mul_lwnaf, LIB), Cvoid, (Ref{EP}, Ref{EP}, Ref{BN}), c, a, b)
    return c
end

function ep_neg_projc!(c::EP, a::EP)
    ccall((:ep_neg_projc, LIB), Cvoid, (Ref{EP}, Ref{EP}), c, a)
    return c
end

# function ep_norm!(r::EP, p::EP)
#     ccall((:ep_norm, LIB), Cvoid, (Ref{EP}, Ref{EP}), r, p)
#     return r
# end

function ep_read_bin!(a::EP, bin::Vector{UInt8})
    ccall((:ep_read_bin, LIB), Cvoid, (Ref{EP}, Ptr{UInt8}, Cint), a, bin, length(bin))
    return a
end

function ep_rand!(ep::EP)
    ccall((:ep_rand, LIB), Cvoid, (Ref{EP},), ep)
    return ep
end

ep_size_bin(ep::EP, pack::Bool) = Int(ccall((:ep_size_bin, LIB), Cint, (Ref{EP}, Cint), ep, pack ? one(Cint) : zero(Cint)))

function ep_sub_projc!(c::EP, a::EP, b::EP)
    ccall((:ep_sub_projc, LIB), Cvoid, (Ref{EP}, Ref{EP}, Ref{EP}), c, a, b)
    return c
end

function ep_write_bin!(bin::Vector{UInt8}, a::EP, pack::Bool)
    flags = pack ? one(Cint) : zero(Cint)
    ccall((:ep_write_bin, LIB), Cvoid, (Ptr{UInt8}, Cint, Ref{EP}, Cint), bin, length(bin), a, flags)
    return bin
end

function ep2_add_projc!(c::EP2, a::EP2, b::EP2)
    ccall((:ep2_add_projc, LIB), Cvoid, (Ref{EP2}, Ref{EP2}, Ref{EP2}), c, a, b)
    return c
end

function ep2_dbl_projc!(c::EP2, a::EP2)
    ccall((:ep2_dbl_projc, LIB), Cvoid, (Ref{EP2}, Ref{EP2}), c, a)
    return c
end

function ep2_curve_get_gen!(g::EP2)
    ccall((:ep2_curve_get_gen, LIB), Cvoid, (Ref{EP2},), g)
    return g
end

function ep2_curve_get_ord!(n::BN)
    ccall((:ep2_curve_get_ord, LIB), Cvoid, (Ref{BN},), n)
    return n
end

function ep2_map!(p::EP2, msg::Vector{UInt8})
    ccall((:ep2_map, LIB), Cvoid, (Ref{EP2}, Ptr{UInt8}, Cint), p, msg, length(msg))
    return p
end

function ep2_mul_lwnaf!(c::EP2, a::EP2, b::BN)
    ccall((:ep2_mul_lwnaf, LIB), Cvoid, (Ref{EP2}, Ref{EP2}, Ref{BN}), c, a, b)
    return c
end

function ep2_neg_projc!(c::EP2, a::EP2)
    ccall((:ep2_neg_projc, LIB), Cvoid, (Ref{EP2}, Ref{EP2}), c, a)
    return c
end

# function ep2_norm!(r::EP2, p::EP2)
#     ccall((:ep2_norm, LIB), Cvoid, (Ref{EP2}, Ref{EP2}), r, p)
#     return r
# end

function ep2_rand!(ep::EP2)
    ccall((:ep2_rand, LIB), Cvoid, (Ref{EP2},), ep)
    return ep
end

function ep2_read_bin!(a::EP2, bin::Vector{UInt8})
    ccall((:ep2_read_bin, LIB), Cvoid, (Ref{EP2}, Ptr{UInt8}, Cint), a, bin, length(bin))
    return a
end

ep2_size_bin(ep::EP2, pack::Bool) = Int(ccall((:ep2_size_bin, LIB), Cint, (Ref{EP2}, Cint), ep, pack ? one(Cint) : zero(Cint)))

function ep2_sub_projc!(c::EP2, a::EP2, b::EP2)
    ccall((:ep2_sub_projc, LIB), Cvoid, (Ref{EP2}, Ref{EP2}, Ref{EP2}), c, a, b)
    return c
end

function ep2_write_bin!(bin::Vector{UInt8}, a::EP2, pack::Bool)
    flags = pack ? one(Cint) : zero(Cint)
    ccall((:ep2_write_bin, LIB), Cvoid, (Ptr{UInt8}, Cint, Ref{EP2}, Cint), bin, length(bin), a, flags)
    return bin
end

function fp_add_basic!(c::FP, a::FP, b::FP)
    ccall((:fp_add_basic, LIB), Cvoid, (Ref{FP}, Ref{FP}, Ref{FP}), c, a, b)
    return c
end

function fp_exp_slide!(c::FP, a::FP, b::BN)
    ccall((:fp_exp_slide, LIB), Cvoid, (Ref{FP}, Ref{FP}, Ref{BN}), c, a, b)
    return c
end

function fp_inv_lower!(c::FP, a::FP)
    ccall((:fp_inv_lower, LIB), Cvoid, (Ref{FP}, Ref{FP}), c, a)
    return c
end

function fp_mul_comba!(c::FP, a::FP, b::FP)
    ccall((:fp_mul_comba, LIB), Cvoid, (Ref{FP}, Ref{FP}, Ref{FP}), c, a, b)
    return c
end

function fp_neg_basic!(c::FP, a::FP)
    ccall((:fp_neg_basic, LIB), Cvoid, (Ref{FP}, Ref{FP}), c, a)
    return c
end

function fp_prime_get()
    fp = ccall((:fp_prime_get, LIB), Ptr{Limb}, ())
    bn = BN(used=FP_SIZE)
    unsafe_copyto!(unsafe_bnptr(bn), fp, bn.used)
    return bn
end

function fp_rand!(fp::FP)
    ccall((:fp_rand, LIB), Cvoid, (Ref{FP},), fp)
    return fp
end

function fp_sqr_comba!(c::FP, a::FP)
    ccall((:fp_sqr_comba, LIB), Cvoid, (Ref{FP}, Ref{FP}), c, a)
    return c
end

function fp_sub_basic!(c::FP, a::FP, b::FP)
    ccall((:fp_sub_basic, LIB), Cvoid, (Ref{FP}, Ref{FP}, Ref{FP}), c, a, b)
    return c
end

function fp_zero(c::FP) 
    ccall((:fp_zero, LIB), Cvoid, (Ref{FP},), c)
    return c
end

function fp2_add_integ!(c::FP2, a::FP2, b::FP2)
    ccall((:fp2_add_integ, LIB), Cvoid, (Ref{FP2}, Ref{FP2}, Ref{FP2}), c, a, b)
    return c
end

function fp2_exp!(c::FP2, a::FP2, b::BN)
    ccall((:fp2_exp, LIB), Cvoid, (Ref{FP2}, Ref{FP2}, Ref{BN}), c, a, b)
    return c
end

function fp2_inv!(c::FP2, a::FP2)
    ccall((:fp2_inv, LIB), Cvoid, (Ref{FP2}, Ref{FP2}), c, a)
    return c
end

function fp2_mul_integ!(c::FP2, a::FP2, b::FP2)
    ccall((:fp2_mul_integ, LIB), Cvoid, (Ref{FP2}, Ref{FP2}, Ref{FP2}), c, a, b)
    return c
end

function fp2_neg!(c::FP2, a::FP2)
    ccall((:fp2_neg, LIB), Cvoid, (Ref{FP2}, Ref{FP2}), c, a)
    return c
end

function fp2_rand!(a::FP2)
    ccall((:fp2_rand, LIB), Cvoid, (Ref{FP2},), a)
    return a
end

function fp2_sub_integ!(c::FP2, a::FP2, b::FP2)
    ccall((:fp2_sub_integ, LIB), Cvoid, (Ref{FP2}, Ref{FP2}, Ref{FP2}), c, a, b)
    return c
end

function fp2_sqr_integ!(c::FP2, a::FP2)
    ccall((:fp2_sqr_integ, LIB), Cvoid, (Ref{FP2}, Ref{FP2}), c, a)
    return c
end

function fp2_zero(c::FP2) 
    ccall((:fp2_zero, LIB), Cvoid, (Ref{FP2},), c)
    return c
end

function fp6_add!(c::FP6, a::FP6, b::FP6)
    ccall((:fp6_add, LIB), Cvoid, (Ref{FP6}, Ref{FP6}, Ref{FP6}), c, a, b)
    return c
end

function fp6_exp!(c::FP6, a::FP6, b::BN)
    ccall((:fp6_exp, LIB), Cvoid, (Ref{FP6}, Ref{FP6}, Ref{BN}), c, a, b)
    return c
end

function fp6_inv!(c::FP6, a::FP6)
    ccall((:fp6_inv, LIB), Cvoid, (Ref{FP6}, Ref{FP6}), c, a)
    return c
end

function fp6_mul_lazyr!(c::FP6, a::FP6, b::FP6)
    ccall((:fp6_mul_lazyr, LIB), Cvoid, (Ref{FP6}, Ref{FP6}, Ref{FP6}), c, a, b)
    return c
end

function fp6_neg!(c::FP6, a::FP6)
    ccall((:fp6_neg, LIB), Cvoid, (Ref{FP6}, Ref{FP6}), c, a)
    return c
end

function fp6_rand!(a::FP6)
    ccall((:fp6_rand, LIB), Cvoid, (Ref{FP6},), a)
    return a
end

function fp6_sub!(c::FP6, a::FP6, b::FP6)
    ccall((:fp6_sub, LIB), Cvoid, (Ref{FP6}, Ref{FP6}, Ref{FP6}), c, a, b)
    return c
end

function fp6_sqr_lazyr!(c::FP6, a::FP6)
    ccall((:fp6_sqr_lazyr, LIB), Cvoid, (Ref{FP6}, Ref{FP6}), c, a)
    return c
end

function fp6_zero(c::FP6) 
    ccall((:fp6_zero, LIB), Cvoid, (Ref{FP6},), c)
    return c
end

function fp12_add!(c::FP12, a::FP12, b::FP12)
    ccall((:fp12_add, LIB), Cvoid, (Ref{FP12}, Ref{FP12}, Ref{FP12}), c, a, b)
    return c
end

function fp12_exp!(c::FP12, a::FP12, b::BN)
    ccall((:fp12_exp, LIB), Cvoid, (Ref{FP12}, Ref{FP12}, Ref{BN}), c, a, b)
    return c
end

function fp12_inv!(c::FP12, a::FP12)
    ccall((:fp12_inv, LIB), Cvoid, (Ref{FP12}, Ref{FP12}), c, a)
    return c
end

function fp12_mul_lazyr!(c::FP12, a::FP12, b::FP12)
    ccall((:fp12_mul_lazyr, LIB), Cvoid, (Ref{FP12}, Ref{FP12}, Ref{FP12}), c, a, b)
    return c
end

function fp12_neg!(c::FP12, a::FP12)
    ccall((:fp12_neg, LIB), Cvoid, (Ref{FP12}, Ref{FP12}), c, a)
    return c
end

function fp12_rand!(a::FP12)
    ccall((:fp12_rand, LIB), Cvoid, (Ref{FP12},), a)
    return a
end

function fp12_sub!(c::FP12, a::FP12, b::FP12)
    ccall((:fp12_sub, LIB), Cvoid, (Ref{FP12}, Ref{FP12}, Ref{FP12}), c, a, b)
    return c
end

function fp12_sqr_lazyr!(c::FP12, a::FP12)
    ccall((:fp12_sqr_lazyr, LIB), Cvoid, (Ref{FP12}, Ref{FP12}), c, a)
    return c
end

function fp12_zero(c::FP12) 
    ccall((:fp12_zero, LIB), Cvoid, (Ref{FP12},), c)
    return c
end

function md_hmac(in::Vector{UInt8}, key::Vector{UInt8})
    mac = Vector{UInt8}(undef, MD_LEN)
    ccall((:md_hmac, LIB), Cvoid, (Ref{UInt8}, Ptr{UInt8}, Cint, Ptr{UInt8}, Cint),
        mac, in, length(in), key, length(key))
    return mac
end

function md_map_sh256(msg::Vector{UInt8})
    hash = Vector{UInt8}(undef, 32)
    ccall((:md_map_sh256, LIB), Cvoid, (Ref{UInt8}, Ptr{UInt8}, Cint), hash, msg, length(msg))
    return hash
end

function pp_exp_k12!(c::FP12, a::FP12)
    ccall((:pp_exp_k12, LIB), Cvoid, (Ref{FP12}, Ref{FP12}), c, a)
    return c
end

function pp_map_oatep_k12!(r::FP12, p::EP, q::EP2)
    ccall((:pp_map_oatep_k12, LIB), Cvoid, (Ref{FP12}, Ref{EP}, Ref{EP2}), r, p, q)
    return r
end
