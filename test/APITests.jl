module APITests

using Test
using RelicToolkit

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

@testset "FP: add and sub" begin
    # TODO: add more 
    fp = RelicToolkit.fp_rand()
    @test (fp + fp) - fp == fp
    @test (fp + fp + fp) - fp - fp == fp
    @test fp + (-fp) == FP()
end

@testset "FP: square root" begin
    # TODO: add more 
    fp = RelicToolkit.fp_rand()
    @test √(fp * fp) in (fp, -fp)
end

@testset "FP: exp" begin
    # TODO: add more 
    fp = RelicToolkit.fp_rand()
    @test fp^3 == fp * fp * fp 
end

@testset "FP: mul and inv" begin
    fp = RelicToolkit.fp_rand()
    fp2 = fp * fp
    fp3 = fp2 * fp
    @test fp2 // fp == fp
    @test fp2 ÷ fp == fp
    @test fp3 // fp2 == fp
    @test fp3 ÷ fp2 == fp
    @test 3fp == fp + fp + fp
end

@testset "rand method exists for all structs" begin
    for T in (FP, )
        @test isa(rand(T), T)
    end
end

end