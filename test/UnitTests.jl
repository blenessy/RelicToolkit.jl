module UnitTests

using Test
using RelicToolkit
using RelicToolkit:
    bn_read_bin, bn_size_bin, 
    fp_prime_get, fp_rand, fp_add_basic, fp_sub_basic, fp_neg_basic, fp_prime_get,
    fp_mul_comba, fp_inv_lower, fp_hlv_basic, fp_sqr_comba, fp_exp_slide, fp_srt,
    fp12_rand,
    ep_rand, ep_add_basic, ep_add_projc, ep_norm, ep_curve_get_gen,
    ep2_rand,
    md_hmac, pp_exp_k12, pp_map_oatep_k12, pp_map_tatep_k12, pp_map_weilp_k12

@testset "BN" begin
    @test sizeof(BN) == 288
    bn = bn_read_bin(UInt8[1, 2, 3])
    @test bn.dp[1] ==  0x0000000000010203
    @test bn_size_bin(bn) == 3

    # Signed
    @test BN(3).dp[1] == 3
    @test iszero(BN(3).sign)
    @test BN(-1).dp[1] == 1
    @test isone(BN(-1).sign)
    
    # Unsigned
    @test BN(0x3).dp[1] == 3
    @test iszero(BN(0x3).sign)

    # Int128
    @test BN(typemax(Int128)) == BN(BigInt(typemax(Int128)))
    @test BN(typemin(Int128)) == BN(BigInt(typemin(Int128)))

    # BigInt
    @test BN(BigInt(3)).dp[1] == 3
    @test iszero(BN(BigInt(3)).sign)
    @test BN(BigInt(-1)).dp[1] == 1
    @test isone(BN(BigInt(-1)).sign)
end

@testset "FP" begin
    # normal integers
    @test FP(0) == FP(BN(0))
    @test FP(1) == FP(BN(1))
    @test FP(-1) == fp_neg_basic(FP(1))

    @test FP(Int128(0)) == FP(0)
    @test FP(Int128(1)) == FP(1)
    @test FP(Int128(-1)) == fp_neg_basic(FP(1))

    @test FP(big"0") == FP(0)
    @test FP(big"1") == FP(1)
    @test FP(big"-1") == fp_neg_basic(FP(1))
end

@testset "BigInt" begin
    @test BigInt(BN(0)) == 0
    @test BigInt(BN(typemax(Int128))) == typemax(Int128)
    @test BigInt(BN(typemin(Int128))) == typemin(Int128)

    @test BigInt(FP(0)) == 0
    @test BigInt(FP(typemax(Int128))) == typemax(Int128)
end

@testset "fp_prime_get" begin
    @test RelicToolkit.fp_prime_get() != 0
end

# @testset "bn_read_bigint" begin
#     @test bn_read_bigint(zero(BigInt)) == BN(0)
#     @test bn_read_bigint(big"1") == BN(1)    @test BN(-1).dp[1] == 1
#     @test bn_read_bigint(big"2") == BN(2)
#     @test bn_read_bigint(big"-1") == BN(-1)
# end

# @testset "bn_write_bigint" begin
#     one = bn_read_bigint(big"1")

#     @test bn_read_bigint(zero(BigInt)) == BN()
#     @test one.dp[1] == 1 && one.sign == 0 && one.used == 1
#     two = bn_read_bigint(big"2")
#     @test two.dp[1] == 2 && two.sign == 0 && two.used == 1
#     neg1 = bn_read_bigint(big"-1")
#     @test neg1.dp[1] == 1 && neg1.sign == 1 && neg1.used == 1
# end

@testset "ep_add_*" begin
    a, b = ep_rand(),  ep_rand()
    @test ep_add_basic(a, b) == ep_norm(ep_add_projc(a, b))
end

@testset "ep_curve_get_gen" begin
    ep = ep_curve_get_gen()
    @test !isempty(x for x in ep.x if !iszero(x))
    @test ep.norm == 1
end

@testset "ep_rand" begin
    @test ep_rand() != EP()
end

@testset "ep2_rand" begin
    @test ep2_rand() != EP2()
end

@testset "fp_add_basic and fp_sub_basic" begin
    a, b = fp_rand(), fp_rand()
    @test fp_sub_basic(fp_add_basic(a, b), a) == b
end

# @testset "fp_prime_get" begin
#     @test fp_prime_get() == (0xb9feffffffffaaab, 0x1eabfffeb153ffff, 0x6730d2a0f6b0f624, 0x64774b84f38512bf, 0x4b1ba7b6434bacd7, 0x1a0111ea397fe69a)
# end

@testset "fp_exp_slide" begin
    a = fp_rand()
    @test fp_exp_slide(a, BN(1)) == a
    @test fp_exp_slide(a, BN(3)) == fp_mul_comba(a, fp_sqr_comba(a))
    @test fp_exp_slide(a, BN(-1)) == fp_inv_lower(a)
end

@testset "fp_hlv_basic" begin
    a = fp_rand()
    @test fp_hlv_basic(fp_add_basic(a, a)) == a
end

@testset "fp_mul_comba and fp_inv_lower" begin
    a = fp_rand()
    a2 = fp_mul_comba(a, a)
    a3 = fp_mul_comba(a2, a)
    @test fp_mul_comba(a3, fp_inv_lower(a)) == a2
    @test fp_mul_comba(a3, fp_inv_lower(a2)) == a
end

@testset "fp_neg_basic" begin
    a = fp_rand()
    @test fp_sub_basic(FP(), a) == fp_neg_basic(a)
end

@testset "fp_rand" begin
    @test fp_rand() != FP()
end

@testset "fp_sqr_basic" begin
    a = fp_rand()
    @test fp_sqr_comba(a) == fp_mul_comba(a, a)
end

@testset "fp_srt" begin
    a = fp_rand()
    @test fp_srt(fp_mul_comba(a, a)) in (a, fp_neg_basic(a))
end

@testset "fp12_rand" begin
    @test fp12_rand() != FP12()
end

@testset "md_hmac" begin
    @test md_hmac(UInt8[1, 2, 3], UInt8[1, 2, 3]) == UInt8[0xba, 0xe3, 0xa2, 0x36, 0x7e, 0xe3, 0xf2, 0x75, 0x4b, 0xdd, 0x3b, 0x39, 0x81, 0x13, 0xb5, 0xcd, 0x45, 0x47, 0xab, 0xee, 0xb5, 0xae, 0x3e, 0x65, 0x1e, 0x5b, 0x37, 0xc3, 0xf2, 0x50, 0x22, 0x68]
end

@testset "pp_exp_k12" begin
    @test pp_exp_k12(fp12_rand()) != FP12() 
end

@testset "pp_map_oatep_k12" begin
    @test pp_map_oatep_k12(ep_rand(), ep2_rand()) != FP12()
end

@testset "pp_map_tatep_k12" begin
    @test pp_map_tatep_k12(ep_rand(), ep2_rand()) != FP12()
end

@testset "pp_map_weilp_k12" begin
    @test pp_map_weilp_k12(ep_rand(), ep2_rand()) != FP12()
end

end