using Test

@testset "model constructors" begin
        @test isa(BN(typemax(Int128)), BN)
        @test isa(BN(typemin(Int128)), BN)
        @test isa(FP(typemax(Int128)), FP)
        @test isa(FP(typemin(Int128)), FP)
        for T in (BN, FP, FP2, FP6, FP12)
            @test isa(T(typemax(Int)), T)
            @test isa(T(typemax(UInt)), T)
        end
        for T in (FP2, FP6, FP12)
            @test_throws InexactError T(typemin(Int))
        end
        for T in (BN, FP, FP2, FP6, FP12, EP, EP2)
            @test isa(T(), T)
            @test isa(T(undef), T) 
        end
end

@testset "serialisation works with some struct" begin
    bn = rand(BN)
    @test BN(Vector{UInt8}(bn)) == bn
    for T in (EP, EP2)
        ep = rand(T)
        @test T(Vector{UInt8}(ep, pack=true)) == ep
        @test T(Vector{UInt8}(ep, pack=false)) == ep
    end
end

@testset "== and != works for all structs" begin
    for T in (BN, FP, FP2, FP6, FP12)
        @test zero(T) == zero(T)
        @test zero(T) != rand(T)
    end
    for T in (EP, EP2)
        @test curve_gen(T) == curve_gen(T)
        @test curve_gen(T) != T()
    end
end

@testset "all logical operators work for BN" begin
    @test BN(1) <= BN(1)
    @test BN(-1) <= BN(1)
    @test BN(-1) < BN(1)
    @test BN(1) > BN(-1)
    @test BN(1) >= BN(-1)
    @test BN(1) >= BN(1)
end


@testset "BN mul" begin
    @test BN(1) * BN(1) == BN(1)
    @test BN(1) * BN(0) == BN(0)
    @test BN(2) * BN(3) == BN(6)
    @test BN(-2) * BN(3) == BN(-6)
    @test 0x3 * BN(2) == BN(6)
    @test Int8(-3) * BN(2) == BN(-6)
    @test Int8(3) * BN(2) == BN(6)
    @test BN(2) * Int128(-3) == BN(-6)
end

@testset "BN add" begin
    @test BN(0) + BN(0) == BN(0)
    @test BN(1) + BN(0) == BN(1)
    @test BN(2) + BN(3) == BN(5)
    @test BN(-2) + BN(3) == BN(1)
    @test BN(3) - 0x2 == BN(1)
    @test Int8(-3) + BN(2) == BN(-1)
    @test BN(2) + Int128(-3) == BN(-1)
end

@testset "BN sub" begin
    @test BN(0) - BN(0) == BN(0)
    @test BN(1) - BN(0) == BN(1)
    @test BN(3) - BN(2) == BN(1)
    @test BN(-2) - BN(3) == BN(-5)
    @test BN(2) - 3 == BN(-1)
    @test 0x3 - BN(2) == BN(1)
    @test Int8(-3) - BN(-2) == BN(-1)
    @test BN(2) - Int128(-3) == BN(5)
end

@testset "BN invmod" begin
    @test_throws DomainError invmod(BN(2), BN(0))
    @test_throws DomainError invmod(BN(5), BN(5))
    @test_throws DomainError invmod(BN(-5), BN(5))
    for i in (-11, -9, -8, -7, -6, -4, -3, -2, -1, 1, 2, 3, 4, 6, 7, 8, 9, 11)
        @test invmod(BN(i), BN(5)) == BN(invmod(i, 5))
        @test invmod(BN(i), BN(-5)) == BN(invmod(i, -5))
        @test invmod(BN(i), 5) == BN(invmod(i, 5))
        @test invmod(i, BN(5)) == BN(invmod(i, 5))
    end
end

@testset "string method works for BN and FP" begin
    @test string(BN(123)) == "123"
    @test string(BN(-123)) == "-123"
end

@testset "rand works for all structs" begin
    for T in (BN, FP, FP2, FP6, FP12, EP, EP2)
        @test !iszero(rand(T))
    end
end

@testset "mod(::BN, ::BN)" begin
    @test isone(mod(BN(8), BN(7)))
    @test mod(BN(8), BigInt(fp_prime_get())) == BN(8)
    @test mod(8, BN(15)) == BN(8)
end

@testset "zero and iszero" begin
    for T in (BN, FP, FP2, FP6, FP12)
        @test iszero(zero(T))
        @test iszero(zero(rand(T)))
    end
end

@testset "one and isone" begin
    for T in (BN, FP, FP2, FP6, FP12)
        @test isone(one(T))
        @test isone(one(rand(T)))
    end
end

@testset "point isvalid and isinf methods are defined" begin
    for T in (EP, EP2)
        @test isinf(zero(T))
        @test isinf(zero(rand(T)))
        @test isvalid(zero(T))
        @test isvalid(curve_gen(T))
    end
end

@testset "field additions, subtraction, and negation works" begin
    for T in (FP, FP2, FP6, FP12)
        a = rand(T)
        @test a + zero(T) == a
        @test a - zero(T) == a
        @test a + a != a
        @test a + a - a == a
        @test iszero(a - a)
        @test iszero(-a + a)
    end
end

@testset "field multiplication, inversion and exponentiation works" begin
    for T in (FP, FP2, FP6, FP12)
        t = rand(T)
        @test iszero(0 * t)
        @test t * 1 == t
        @test 2t == t + t
        @test isone(t * inv(t))
        @test isone(t // t)
        @test isone(t ÷ t)
        @test t^2 == t * t
        @test t^2 == field_sqr(t)
        @test t^BN(3) == t * t * t
    end
end

@testset "field_final_exp" begin
    for T in (FP12,)
        t = rand(T)
        @test !iszero(t)
        @test field_final_exp(t) != t
    end
end

@testset "basic curve operations work" begin
    for T in (EP, EP2)
        a = rand(T)
        @test !isinf(a) && isvalid(a)
        @test a + a == curve_dbl(a)
        @test a + a == 2a
        @test a + a == BN(2) * a == a * BN(2)
        @test -a == a * -1
        @test 2a - a == a 

    end
end

@testset "curve operations output affline points" begin
    for T in (EP, EP2)
        a = rand(T)
        @test isone(a.norm)
        @test isone((a + a).norm)
        @test isone(curve_dbl(a).norm)
        @test isone((2a).norm)
        @test isone((-a).norm)
        @test isone((a * -1).norm)
        @test isone((2a - a).norm)
    end
end


@testset "curve_map" begin
    for T in (EP, EP2)
        point = curve_map(T, Vector{UInt8}("test"))
        @test !isinf(point) && isvalid(point)
    end
end

@testset "curve_order" begin
    @test curve_order(EP) == curve_order(EP2)
end

@testset "curve_miller" begin
    p, q = rand(EP), rand(EP2)
    @test curve_miller(p, q) == curve_miller(q, p)
    @test !iszero(curve_miller(p, q))
end

@testset "md_sha256" begin
    @test md_sha256(Vector{UInt8}("test")) == UInt8[
        0x9f, 0x86, 0xd0, 0x81, 0x88, 0x4c, 0x7d, 0x65,
        0x9a, 0x2f, 0xea, 0xa0, 0xc5, 0x5a, 0xd0, 0x15,
        0xa3, 0xbf, 0x4f, 0x1b, 0x2b, 0x0b, 0x82, 0x2c,
        0xd1, 0x5d, 0x6c, 0x15, 0xb0, 0xf0, 0x0a, 0x08
    ]
end

@testset "md_hmac" begin
    @test md_hmac(Vector{UInt8}("foo"), Vector{UInt8}("bar")) == UInt8[
        0x14, 0x79, 0x33, 0x21, 0x8a, 0xaa, 0xbc, 0x0b,
        0x8b, 0x10, 0xa2, 0xb3, 0xa5, 0xc3, 0x46, 0x84,
        0xc8, 0xd9, 0x43, 0x41, 0xbc, 0xf1, 0x0a, 0x47,
        0x36, 0xdc, 0x72, 0x70, 0xf7, 0x74, 0x18, 0x51
    ]
end
