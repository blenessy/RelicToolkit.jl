module PerfTests

using BenchmarkTools
using RelicToolkit: BN254, BLS381

BenchmarkTools.DEFAULT_PARAMETERS.samples = 1000
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 10
BenchmarkTools.DEFAULT_PARAMETERS.evals = 1
BenchmarkTools.DEFAULT_PARAMETERS.gctrial = true
BenchmarkTools.DEFAULT_PARAMETERS.gcsample = false
@show BenchmarkTools.DEFAULT_PARAMETERS

suite = BenchmarkGroup()

suite["RelicToolkit.BN254"] = BenchmarkGroup()


suite["RelicToolkit.BN254.PP"] = BenchmarkGroup()
suite["RelicToolkit.BN254.PP"]["field_final_exp"] = @benchmarkable BN254.field_final_exp($(rand(BN254.FP12)))
suite["RelicToolkit.BN254.PP"]["curve_miller"] = @benchmarkable BN254.curve_miller!($(BN254.FP12()), $(rand(BN254.EP)), $(rand(BN254.EP2)))

suite["RelicToolkit.BLS381"] = BenchmarkGroup()
suite["RelicToolkit.BLS381.BN"] = BenchmarkGroup()
suite["RelicToolkit.BLS381.BN"]["BigInt(::BN)"] = @benchmarkable BigInt($(rand(BLS381.BN)))
suite["RelicToolkit.BLS381.FP"] = BenchmarkGroup()
suite["RelicToolkit.BLS381.FP"]["BigInt(::FP)"] = @benchmarkable BigInt($(rand(BLS381.FP)))
suite["RelicToolkit.BLS381.FP"]["rand(::Type{FP})"] = @benchmarkable rand(BLS381.FP)
suite["RelicToolkit.BLS381.FP"]["FP(::Int)"] = @benchmarkable BLS381.FP(rand(Int))
suite["RelicToolkit.BLS381.MD"] = BenchmarkGroup()
suite["RelicToolkit.BLS381.MD"]["md_hmac"] = @benchmarkable BLS381.md_hmac($(rand(UInt8, BLS381.MD_LEN)), $(rand(UInt8, BLS381.MD_LEN)))
suite["RelicToolkit.BLS381.PP"] = BenchmarkGroup()
suite["RelicToolkit.BLS381.PP"]["field_final_exp"] = @benchmarkable BLS381.field_final_exp($(rand(BLS381.FP12)))
suite["RelicToolkit.BLS381.PP"]["curve_miller"] = @benchmarkable BLS381.curve_miller!($(BLS381.FP12()), $(rand(BLS381.EP)), $(rand(BLS381.EP2)))
suite["RelicToolkit.BLS381.EP"] = BenchmarkGroup()
suite["RelicToolkit.BLS381.EP"]["curve_dbl(::EP)"] = @benchmarkable BLS381.curve_dbl($(rand(BLS381.EP)))
suite["RelicToolkit.BLS381.EP"]["curve_mul_gen(::EP)"] = @benchmarkable BLS381.curve_mul_gen(BLS381.EP, $(rand(BLS381.BN)))
suite["RelicToolkit.BLS381.EP2"] = BenchmarkGroup()
suite["RelicToolkit.BLS381.EP2"]["curve_dbl(::EP2)"] = @benchmarkable BLS381.curve_dbl($(rand(BLS381.EP2)))
suite["RelicToolkit.BLS381.EP2"]["curve_mul_gen(::EP2)"] = @benchmarkable BLS381.curve_mul_gen(BLS381.EP2, $(rand(BLS381.BN)))

for M in (BLS381,)
    for T in (M.FP, M.FP2, M.FP6, M.FP12)
        name = string(T)
        name in suite || (suite[name] = BenchmarkGroup())
        suite[name]["+"] = @benchmarkable $(rand(T)) + $(rand(T))
        suite[name]["-"] = @benchmarkable $(rand(T)) - $(rand(T))
        suite[name]["*"] = @benchmarkable $(rand(T)) * $(rand(T))
        suite[name]["inv"] = @benchmarkable inv($(rand(T)))
        suite[name]["^"] = @benchmarkable $(rand(T)) ^ $(rand(M.BN))
        suite[name]["iszero(::$name)"] = @benchmarkable iszero($(rand(T)))
        suite[name]["isone(::$name)"] = @benchmarkable isone($(rand(T)))
        suite[name]["=="] = @benchmarkable $(rand(T)) == $(rand(T))
    end

    for T in (M.EP, M.EP2)
        name = string(T)
        name in suite || (suite[name] = BenchmarkGroup())
        suite[name]["=="] = @benchmarkable $(rand(T)) == $(rand(T))
        suite[name]["+"] = @benchmarkable $(rand(T)) + $(rand(T))
        suite[name]["-"] = @benchmarkable $(rand(T)) - $(rand(T))
        suite[name]["*"] = @benchmarkable $(rand(T)) * $(rand(M.BN))
        suite[name]["isinf(::$name)"] = @benchmarkable isinf($(rand(T)))
        suite[name]["isvalid(::$name)"] = @benchmarkable isvalid($(rand(T)))
    end
end


function format_trial(suite, group, res)
    a = allocs(res)
    gct = BenchmarkTools.prettytime(gctime(res))
    t = BenchmarkTools.prettytime(time(res))
    m = BenchmarkTools.prettymemory(memory(res))
    return "[$suite][$group]: $t (alloc: $a, mem: $m, gc: $gct)"
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
