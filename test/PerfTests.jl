module BLSSignaturesPerf

using BenchmarkTools
using RelicToolkit
using RelicToolkit:
    ep_norm, ep_rand, ep_add_basic!, ep_add_projc!, ep_add_projc,
    ep2_rand,
    fp_add_basic!, fp_add_integ!, fp_rand,
    fp12_rand,
    md_hmac, pp_exp_k12!, pp_map_oatep_k12!, pp_map_tatep_k12!, pp_map_weilp_k12!

BenchmarkTools.DEFAULT_PARAMETERS.samples = 1000
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 10
BenchmarkTools.DEFAULT_PARAMETERS.evals = 1
BenchmarkTools.DEFAULT_PARAMETERS.gctrial = true
BenchmarkTools.DEFAULT_PARAMETERS.gcsample = false
@show BenchmarkTools.DEFAULT_PARAMETERS

eprandp() = ep_add_projc(ep_rand(), EP())
rand256() = zeros(UInt8, 32)

suite = BenchmarkGroup()
suite["RelicToolkit"] = BenchmarkGroup()
suite["RelicToolkit"]["::EP2 == ::EP2"] = @benchmarkable EP2() == EP2()
suite["RelicToolkit"]["ep_add_basic"] = @benchmarkable ep_add_basic!($(EP()), $(ep_rand()), $(ep_rand()))
suite["RelicToolkit"]["ep_add_projc"] = @benchmarkable ep_add_projc!($(EP()), $(eprandp()), $(eprandp()))
suite["RelicToolkit"]["fp_add_basic"] = @benchmarkable fp_add_basic!($(FP()), $(fp_rand()), $(fp_rand()))
suite["RelicToolkit"]["fp_add_integ"] = @benchmarkable fp_add_integ!($(FP()), $(fp_rand()), $(fp_rand()))
suite["RelicToolkit"]["FP12"] = @benchmarkable FP12()
suite["RelicToolkit"]["::FP12 == ::FP12"] = @benchmarkable FP12() == FP12()
suite["RelicToolkit"]["md_hmac"] = @benchmarkable md_hmac($(rand256()), $(rand256()))
suite["RelicToolkit"]["pp_exp_k12"] = @benchmarkable pp_exp_k12!($(FP12()), $(fp12_rand()))
suite["RelicToolkit"]["pp_map_oatep_k12"] = @benchmarkable pp_map_oatep_k12!($(FP12()), $(ep_rand()), $(ep2_rand()))
#suite["RelicToolkit"]["pp_map_tatep_k12"] = @benchmarkable pp_map_tatep_k12($(FP12()), $(eprand()), $(ep2rand()))
#suite["RelicToolkit"]["pp_map_weilp_k12"] = @benchmarkable pp_map_weilp_k12($(FP12()), $(eprand()), $(ep2rand()))


function format_trial(suite, group, res)
    a = allocs(res)
    gct = BenchmarkTools.prettytime(gctime(res))
    t = BenchmarkTools.prettytime(time(res))
    m = BenchmarkTools.prettymemory(memory(res))
    return "[$suite] $group: $t (alloc: $a, mem: $m, gc: $gct)"
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
        msg = format_trial(suiteres.first, groupres.first, groupres.second)
        println(msg)
    end
end

end