module BLSSignaturesPerf

using BenchmarkTools
using RelicToolkit
using RelicToolkit: fp_sqr_comba!, md_hmac, pp_exp_k12!, pp_map_oatep_k12!, pp_map_tatep_k12!, pp_map_weilp_k12!,
    ep_mul_gen!, ep2_mul_gen!

BenchmarkTools.DEFAULT_PARAMETERS.samples = 1000
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 10
BenchmarkTools.DEFAULT_PARAMETERS.evals = 1
BenchmarkTools.DEFAULT_PARAMETERS.gctrial = true
BenchmarkTools.DEFAULT_PARAMETERS.gcsample = false
@show BenchmarkTools.DEFAULT_PARAMETERS

rand256() = zeros(UInt8, 32)
fpsqrrand() = fp_sqr_comba!(FP(), rand(FP))

suite = BenchmarkGroup()
suite["RelicToolkit"] = BenchmarkGroup()

suite["RelicToolkit"]["BN"] = BenchmarkGroup()
suite["RelicToolkit"]["BN"]["BigInt(::BN)"] = @benchmarkable BigInt($(rand(BN)))

suite["RelicToolkit"]["FP"] = BenchmarkGroup()
suite["RelicToolkit"]["FP"]["BigInt(::FP)"] = @benchmarkable BigInt($(rand(FP)))
suite["RelicToolkit"]["FP"]["FP(::UInt)"] = @benchmarkable FP($(rand(UInt)))
suite["RelicToolkit"]["FP"]["+"] = @benchmarkable $(rand(FP)) + $(rand(FP))
suite["RelicToolkit"]["FP"]["-"] = @benchmarkable $(rand(FP)) - $(rand(FP))
suite["RelicToolkit"]["FP"]["*"] = @benchmarkable $(rand(FP)) * $(rand(FP))
suite["RelicToolkit"]["FP"]["^"] = @benchmarkable $(rand(FP)) ^ $(rand(BN))
suite["RelicToolkit"]["FP"]["inv"] = @benchmarkable inv($(rand(FP)))
suite["RelicToolkit"]["FP"]["sqrt"] = @benchmarkable sqrt($(fpsqrrand()))

suite["RelicToolkit"]["FP2"] = BenchmarkGroup()
suite["RelicToolkit"]["FP2"]["+"] = @benchmarkable $(rand(FP2)) + $(rand(FP2))
suite["RelicToolkit"]["FP2"]["-"] = @benchmarkable $(rand(FP2)) - $(rand(FP2))
suite["RelicToolkit"]["FP2"]["*"] = @benchmarkable $(rand(FP2)) * $(rand(FP2))
suite["RelicToolkit"]["FP2"]["^"] = @benchmarkable $(rand(FP2)) ^ $(rand(BN))
suite["RelicToolkit"]["FP2"]["inv"] = @benchmarkable inv($(rand(FP2)))

suite["RelicToolkit"]["FP6"] = BenchmarkGroup()
suite["RelicToolkit"]["FP6"]["+"] = @benchmarkable $(rand(FP6)) + $(rand(FP6))
suite["RelicToolkit"]["FP6"]["-"] = @benchmarkable $(rand(FP6)) - $(rand(FP6))
suite["RelicToolkit"]["FP6"]["*"] = @benchmarkable $(rand(FP6)) * $(rand(FP6))
suite["RelicToolkit"]["FP6"]["^"] = @benchmarkable $(rand(FP6)) ^ $(rand(BN))
suite["RelicToolkit"]["FP6"]["inv"] = @benchmarkable inv($(rand(FP6)))

suite["RelicToolkit"]["FP12"] = BenchmarkGroup()
suite["RelicToolkit"]["FP12"]["FP12()"] = @benchmarkable FP12()
suite["RelicToolkit"]["FP12"]["+"] = @benchmarkable $(rand(FP12)) + $(rand(FP12))
suite["RelicToolkit"]["FP12"]["-"] = @benchmarkable $(rand(FP12)) - $(rand(FP12))
suite["RelicToolkit"]["FP12"]["*"] = @benchmarkable $(rand(FP12)) * $(rand(FP12))
suite["RelicToolkit"]["FP12"]["^"] = @benchmarkable $(rand(FP12)) ^ $(rand(BN))
suite["RelicToolkit"]["FP12"]["inv"] = @benchmarkable inv($(rand(FP12)))
suite["RelicToolkit"]["FP12"]["=="] = @benchmarkable $(FP12()) == $(FP12())

suite["RelicToolkit"]["EP"] = BenchmarkGroup()
suite["RelicToolkit"]["EP"]["=="] = @benchmarkable $(EP()) == $(EP())
suite["RelicToolkit"]["EP"]["+"] = @benchmarkable $(rand(EP)) + $(rand(EP))
suite["RelicToolkit"]["EP"]["*"] = @benchmarkable $(rand(EP)) * $(rand(BN))
suite["RelicToolkit"]["EP"]["-"] = @benchmarkable $(rand(EP)) - $(rand(EP))
suite["RelicToolkit"]["EP"]["isvalid"] = @benchmarkable isvalid($(rand(EP)))
suite["RelicToolkit"]["EP"]["isinf"] = @benchmarkable isinf($(rand(EP)))
suite["RelicToolkit"]["EP"]["ep_mul_gen"] = @benchmarkable ep_mul_gen!($(EP()), $(rand(BN)))

suite["RelicToolkit"]["EP2"] = BenchmarkGroup()
suite["RelicToolkit"]["EP2"]["=="] = @benchmarkable $(EP2()) == $(EP2())
suite["RelicToolkit"]["EP2"]["+"] = @benchmarkable $(rand(EP2)) + $(rand(EP2))
suite["RelicToolkit"]["EP2"]["*"] = @benchmarkable $(rand(EP2)) * $(rand(BN))
suite["RelicToolkit"]["EP2"]["-"] = @benchmarkable $(rand(EP2)) - $(rand(EP2))
suite["RelicToolkit"]["EP2"]["isvalid"] = @benchmarkable isvalid($(rand(EP2)))
suite["RelicToolkit"]["EP2"]["isinf"] = @benchmarkable isinf($(rand(EP2)))
suite["RelicToolkit"]["EP2"]["ep2_mul_gen"] = @benchmarkable ep2_mul_gen!($(EP2()), $(rand(BN)))

suite["RelicToolkit"]["MD"] = BenchmarkGroup()
suite["RelicToolkit"]["MD"]["md_hmac"] = @benchmarkable md_hmac($(rand256()), $(rand256()))

suite["RelicToolkit"]["PP"] = BenchmarkGroup()
suite["RelicToolkit"]["PP"]["pp_exp_k12"] = @benchmarkable pp_exp_k12!($(FP12()), $(rand(FP12)))
suite["RelicToolkit"]["PP"]["pp_map_oatep_k12"] = @benchmarkable pp_map_oatep_k12!($(FP12()), $(rand(EP)), $(rand(EP2)))
#suite["RelicToolkit"]["PP"]["pp_map_tatep_k12"] = @benchmarkable pp_map_tatep_k12($(FP12()), $(rand(EP)), $(rand(EP2)))
#suite["RelicToolkit"]["PP"]["pp_map_weilp_k12"] = @benchmarkable pp_map_weilp_k12($(FP12()), $(rand(EP)), $(rand(EP2)))


function format_trial(suite, group, subgroup, res)
    a = allocs(res)
    gct = BenchmarkTools.prettytime(gctime(res))
    t = BenchmarkTools.prettytime(time(res))
    m = BenchmarkTools.prettymemory(memory(res))
    return "[$suite][$group] $subgroup: $t (alloc: $a, mem: $m, gc: $gct)"
end

# If a cache of tuned parameters already exists, use it, otherwise, tune and cache
# the benchmark parameters. Reusing cached parameters is faster and more reliable
# than re-tuning `suite` every time the file is included.
paramspath = joinpath(@__DIR__, "params.json")
if isfile(paramspath)
    loadparams!(suite, BenchmarkTools.load(paramspath)[1], :evals);
else
    println("First run - tuning params (please be patient) ...")
    tune!(suite)
    BenchmarkTools.save(paramspath, params(suite));
end

# print the results
results = run(suite, verbose = true)
for suiteres in results
    for groupres in suiteres.second
        for subgroupres in groupres.second
            msg = format_trial(suiteres.first, groupres.first, subgroupres.first, subgroupres.second)
            println(msg)
        end
    end
end

end
