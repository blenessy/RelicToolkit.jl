module UnitTests

using Test
using RelicToolkit: BN254, BLS381

@testset "model constructors" begin
    for M in (BN254, BLS381)
        @test isa(M.BN(typemax(Int128)), M.BN)
        @test isa(M.BN(typemin(Int128)), M.BN)
        @test isa(M.FP(typemax(Int128)), M.FP)
        @test isa(M.FP(typemin(Int128)), M.FP)
        for T in (M.BN, M.FP, M.FP2, M.FP6, M.FP12)
            @test isa(T(typemax(Int)), T)
            @test isa(T(typemax(M.Limb)), T)
        end
        for T in (M.FP2, M.FP6, M.FP12)
            @test_throws InexactError T(typemin(Int))
        end
        for T in (M.BN, M.FP, M.FP2, M.FP6, M.FP12, M.EP, M.EP2)
            @test isa(T(), T)
            @test isa(T(undef), T) 
        end
    end
end

@testset "serialisation works with some struct" begin
    for M in (BN254, BLS381)
        bn = rand(M.BN)
        @test M.BN(Vector{UInt8}(bn)) == bn
        for T in (M.EP, M.EP2)
            ep = rand(T)
            @test T(Vector{UInt8}(ep, pack=true)) == ep
            @test T(Vector{UInt8}(ep, pack=false)) == ep
        end
    end
end

@testset "== and != works for all structs" begin
    for M in (BN254, BLS381)
        for T in (M.BN, M.FP, M.FP2, M.FP6, M.FP12)
            @test zero(T) == zero(T)
            @test zero(T) != rand(T)
        end
        for T in (M.EP, M.EP2)
            @test M.curve_gen(T) == M.curve_gen(T)
            @test M.curve_gen(T) != T()
        end
    end
end

@testset "all logical operators work for BN" begin
    for BN in (BN254.BN, BLS381.BN)
        @test BN(1) <= BN(1)
        @test BN(-1) <= BN(1)
        @test BN(-1) < BN(1)
        @test BN(1) > BN(-1)
        @test BN(1) >= BN(-1)
        @test BN(1) >= BN(1)
    end
end

@testset "string method works for BN and FP" begin
    for M in (BN254, BLS381)
        @test string(M.BN(123)) == "123"
        @test string(M.BN(-123)) == "-123"
    end
end

@testset "rand works for all structs" begin
    for M in (BN254, BLS381)
        for T in (M.BN, M.FP, M.FP2, M.FP6, M.FP12, M.EP, M.EP2)
            @test !iszero(rand(T))
        end
    end
end

@testset "mod(::BN, ::BN)" begin
    for M in (BN254, BLS381)
        @test isone(mod(M.BN(8), M.BN(7)))
        @test mod(M.BN(8), M.fp_prime_get()) == M.BN(8)
    end
end

@testset "zero and iszero" begin
    for M in (BN254, BLS381)
        for T in (M.BN, M.FP, M.FP2, M.FP6, M.FP12)
            @test iszero(zero(T))
            @test iszero(zero(rand(T)))
        end
    end
end

@testset "one and isone" begin
    for M in (BN254, BLS381)
        for T in (M.BN, M.FP, M.FP2, M.FP6, M.FP12)
            @test isone(one(T))
            @test isone(one(rand(T)))
        end
    end
end

@testset "point isvalid and isinf methods are defined" begin
    for M in (BN254, BLS381)
        for T in (M.EP, M.EP2)
            @test isinf(zero(T))
            @test isinf(zero(rand(T)))
            @test isvalid(zero(T))
            @test isvalid(M.curve_gen(T))
        end
    end
end

@testset "field additions, subtraction, and negation works" begin
    for M in (BN254, BLS381)
        for T in (M.FP, M.FP2, M.FP6, M.FP12)
            a = rand(T)
            @test a + zero(T) == a
            @test a - zero(T) == a
            @test a + a != a
            @test a + a - a == a
            @test iszero(a - a)
            @test iszero(-a + a)
        end
    end
end

@testset "field multiplication, inversion and exponentiation works" begin
    for M in (BN254, BLS381)
        for T in (M.FP, M.FP2, M.FP6, M.FP12)
            t = rand(T)
            @test iszero(0 * t)
            @test t * 1 == t
            @test 2t == t + t
            @test isone(t * inv(t))
            @test isone(t // t)
            @test isone(t ÷ t)
            @test t^2 == t * t
            @test t^2 == M.field_sqr(t)
            @test t^M.BN(3) == t * t * t
        end
    end
end

@testset "field_final_exp" begin
    for M in (BN254, BLS381)
        for T in (M.FP12,)
            t = rand(T)
            @test !iszero(t)
            @test M.field_final_exp(t) != t
        end
    end
end

@testset "basic curve operations work" begin
    for M in (BN254, BLS381)
        for T in (M.EP, M.EP2)
            a = rand(T)
            @test !isinf(a) && isvalid(a)
            @test a + a == M.curve_dbl(a)
            @test a + a == 2a
            @test a + a == M.BN(2) * a == a * M.BN(2)
            @test -a == a * -1
            @test 2a - a == a 
        end
    end
end

@testset "curve_map" begin
    for M in (BN254, BLS381)
        for T in (M.EP, M.EP2)
            point = M.curve_map(T, Vector{UInt8}("test"))
            @test !isinf(point) && isvalid(point)
        end
    end
end

@testset "curve_miller" begin
    for M in (BN254, BLS381)
        p, q = rand(M.EP), rand(M.EP2)
        @test !iszero(M.curve_miller(M.FP12, p, q))
    end
end

@testset "md_sha256" begin
    for M in (BN254, BLS381)
        @test M.md_sha256(Vector{UInt8}("test")) == UInt8[
            0x9f, 0x86, 0xd0, 0x81, 0x88, 0x4c, 0x7d, 0x65,
            0x9a, 0x2f, 0xea, 0xa0, 0xc5, 0x5a, 0xd0, 0x15,
            0xa3, 0xbf, 0x4f, 0x1b, 0x2b, 0x0b, 0x82, 0x2c,
            0xd1, 0x5d, 0x6c, 0x15, 0xb0, 0xf0, 0x0a, 0x08
        ]
    end
end

@testset "md_hmac" begin
    for M in (BN254, BLS381)
        @test M.md_hmac(Vector{UInt8}("foo"), Vector{UInt8}("bar")) == UInt8[
            0x14, 0x79, 0x33, 0x21, 0x8a, 0xaa, 0xbc, 0x0b,
            0x8b, 0x10, 0xa2, 0xb3, 0xa5, 0xc3, 0x46, 0x84,
            0xc8, 0xd9, 0x43, 0x41, 0xbc, 0xf1, 0x0a, 0x47,
            0x36, 0xdc, 0x72, 0x70, 0xf7, 0x74, 0x18, 0x51
        ]
    end
end

end