module UnitTests

using Test
using RelicToolkit: BN254, BLS381

@testset "all structs have default constructors" begin
    for M in (BN254, BLS381)
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
            @test t^M.BN(3) == t * t * t
        end
    end
end

end