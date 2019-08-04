using Test

@testset "0.1.0: Lib provides high-level APIs for implementing BLS Signatures scheme perfomantly" begin
    # https://medium.com/cryptoadvance/bls-signatures-better-than-schnorr-5a7fe30ea716
    # e(P, H(m)) = e(G, S)
    m = "test"
    pk = mod(rand(BN), curve_order(EP))
    G = curve_gen(EP)
    e(P::EP, Q::EP2) = field_final_exp(curve_miller(P, Q))
    H(m::String) = curve_map(EP2, Vector{UInt8}(m))
    P = pk * G
    S = pk * H(m)
    @test !isinf(G) && isvalid(G) 
    @test !isinf(P) && isvalid(P) 
    @test !isinf(S) && isvalid(S) 
    @test e(P, H(m)) == e(G, S)
    # print something to the log
    @time e(P, H(m)) == e(G, S)
end
