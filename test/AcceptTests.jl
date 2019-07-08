module AcceptTests

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

@testset "the != operator is works for all structs" begin
    # TODO: add more 
    @test FP() != RelicToolkit.fp_rand()
end

@testset "the + operator works for all structs" begin
    # TODO: add more 
    ep = RelicToolkit.ep_rand()
    @test ep + EP() == ep
    @test ep + EP() + ep != ep
    @test ep + EP() + ep == ep + ep + EP()
end

@testset "rand method exists for all structs" begin
    # TODO: add more 
    for T in (FP, )
        @test isa(rand(T), T)
    end
end

end