module APITests

using Test
using RelicToolkit
#using RelicToolkit: ep_dbl_basic, ep2_dbl_basic


@testset "all structs have default constructors" begin
    for T in (BN, FP, FP2, FP6, FP12, EP, EP2)
        @test isa(T(), T)
    end
end

@testset "the == operator works for all structs" begin
    # TODO: add BN
    for T in (FP, FP2, FP6, FP12, EP, EP2)
        @test T() == T()
    end
end

@testset "Basic FP and FPX arithmetic" begin
    for T in (FP, FP2, FP6, FP12)
        a = rand(T)
        @test !iszero(a)
    
        # add, sub, neg
        @test (a + a) - a == a
        @test (a + a + a) - a - a == a
        @test -a == a - a - a
    
        # mul, inv, exp
        b = a * a
        c = b * a
        @test b // a == a
        @test b ÷ a == a
        @test c // b == a
        @test c ÷ b == a
        @test 3a == a + a + a
        @test a^3 == c
    end
end

@testset "FP: square root" begin
    a = rand(FP)
    b = a * a
    @test √b in (a, -a)
    @test sqrt(b) in (a, -a)
end


@testset "Basic EP and EP2 arithmetic" begin
    for T in (EP, EP2)
        a = rand(T)
        @test !isinf(a)
        @test isvalid(a)

        # add, sub, neg
        @test (a + a) - a == a
        @test (a + a + a) - a - a == a
        @test -a == a - a - a

        # mul, inv, exp
        @test a + a == 2 * a
        @test a + a + a == a * 3
    end
end

end