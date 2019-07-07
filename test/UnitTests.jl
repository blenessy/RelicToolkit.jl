module UnitTests

using Test
using RelicToolkit

@testset "BN" begin
    using RelicToolkit: BN
    @test sizeof(BN) == 288
    bn = RelicToolkit.bn_read_bin(BN(), UInt8[1, 2, 3])
    @test bn.dp[1] ==  0x0000000000010203
    @test RelicToolkit.bn_size_bin(bn) == 3
end

@testset "md_hmac" begin
    @test RelicToolkit.md_hmac(zeros(UInt8, 32), UInt8[1, 2, 3], UInt8[1, 2, 3]) == UInt8[0xba, 0xe3, 0xa2, 0x36, 0x7e, 0xe3, 0xf2, 0x75, 0x4b, 0xdd, 0x3b, 0x39, 0x81, 0x13, 0xb5, 0xcd, 0x45, 0x47, 0xab, 0xee, 0xb5, 0xae, 0x3e, 0x65, 0x1e, 0x5b, 0x37, 0xc3, 0xf2, 0x50, 0x22, 0x68]
    @test_throws ErrorException RelicToolkit.md_hmac(zeros(UInt8, 2), UInt8[1, 2, 3], UInt8[1, 2, 3])
end

end