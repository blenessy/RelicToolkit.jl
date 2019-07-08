module UnitTests

using Test
using RelicToolkit
using RelicToolkit:
    bn_read_bin, bn_size_bin,
    fp_prime_get, fp_rand, fp_add_basic, fp_add_integ,
    fp12_rand,
    ep_rand, ep_add_basic, ep_add_projc, ep_norm, ep_curve_get_gen, ep_param_embed,
    ep2_rand,
    md_hmac, pp_exp_k12, pp_map_oatep_k12, pp_map_tatep_k12, pp_map_weilp_k12

@testset "BN" begin
    @test sizeof(BN) == 288
    bn = bn_read_bin(UInt8[1, 2, 3])
    @test bn.dp[1] ==  0x0000000000010203
    @test bn_size_bin(bn) == 3
end

@testset "ep_add_*" begin
    a, b = ep_rand(),  ep_rand()
    @test ep_add_basic(a, b) == ep_norm(ep_add_projc(a, b))
end

@testset "ep_curve_get_gen" begin
    ep = ep_curve_get_gen()
    @test !isempty(x for x in ep.x if !iszero(x))
    @test ep.norm == 1
end

@testset "ep_param_embed" begin
    @test !iszero(ep_param_embed())
end

@testset "ep_rand" begin
    @test ep_rand() != EP()
end

@testset "ep2_rand" begin
    @test ep2_rand() != EP2()
end

@testset "fp_add_*" begin
    a, b = fp_rand(), fp_rand()
    @test fp_add_basic(a, b) == fp_add_integ(a, b)
end

@testset "fp_prime_get" begin
    @test !isempty(x for x in fp_prime_get().data if !iszero(x))
end

@testset "fp_rand" begin
    @test fp_rand() != FP()
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