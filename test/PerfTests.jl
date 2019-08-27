using BenchmarkTools

BenchmarkTools.DEFAULT_PARAMETERS.samples = 1000
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 10
BenchmarkTools.DEFAULT_PARAMETERS.evals = 1
BenchmarkTools.DEFAULT_PARAMETERS.gctrial = true
BenchmarkTools.DEFAULT_PARAMETERS.gcsample = false
@show BenchmarkTools.DEFAULT_PARAMETERS

suite = BenchmarkGroup()

suite["BN"] = BenchmarkGroup()
suite["BN"]["BigInt(::BN)"] = @benchmarkable BigInt($(rand(BN)))

suite["BN"]["invmod(::BN, ::BN)"] = @benchmarkable invmod($(rand(BN)), $(curve_order(EP)))
suite["BN"]["invmod(::BigInt, ::BigInt)"] = @benchmarkable invmod($(BigInt(rand(BN))), $(BigInt(curve_order(EP))))
suite["BN"]["mod(::BN, ::BN)"] = @benchmarkable mod($(rand(BN)), $(curve_order(EP)))
suite["BN"]["mod(::BigInt, ::BigInt)"] = @benchmarkable mod($(BigInt(rand(BN))), $(BigInt(curve_order(EP))))
suite["BN"]["::BN * ::BN"] = @benchmarkable $(rand(BN)) * $(rand(BN))
suite["BN"]["::BigInt * ::BigInt"] = @benchmarkable $(BigInt(rand(BN))) * $(BigInt(rand(BN)))

suite["FP"] = BenchmarkGroup()
suite["FP"]["rand(::Type{FP})"] = @benchmarkable rand(FP)
suite["FP"]["FP(::Int)"] = @benchmarkable FP(rand(Int))
suite["MD"] = BenchmarkGroup()
suite["MD"]["md_hmac"] = @benchmarkable md_hmac($(rand(UInt8, MD_LEN)), $(rand(UInt8, MD_LEN)))
suite["PP"] = BenchmarkGroup()
suite["PP"]["field_final_exp"] = @benchmarkable field_final_exp($(rand(FP12)))
suite["PP"]["curve_miller"] = @benchmarkable curve_miller($(rand(EP)), $(rand(EP2)))
suite["EP"] = BenchmarkGroup()
suite["EP"]["curve_dbl(::EP)"] = @benchmarkable curve_dbl($(rand(EP)))
suite["EP2"] = BenchmarkGroup()
suite["EP2"]["curve_dbl(::EP2)"] = @benchmarkable curve_dbl($(rand(EP2)))

for T in (FP, FP2, FP6, FP12)
    name = string(T)
    name in suite || (suite[name] = BenchmarkGroup())
    suite[name]["+"] = @benchmarkable $(rand(T)) + $(rand(T))
    suite[name]["-"] = @benchmarkable $(rand(T)) - $(rand(T))
    suite[name]["*"] = @benchmarkable $(rand(T)) * $(rand(T))
    suite[name]["inv"] = @benchmarkable inv($(rand(T)))
    suite[name]["^"] = @benchmarkable $(rand(T)) ^ $(rand(BN))
    suite[name]["iszero(::$name)"] = @benchmarkable iszero($(rand(T)))
    suite[name]["isone(::$name)"] = @benchmarkable isone($(rand(T)))
    suite[name]["=="] = @benchmarkable $(rand(T)) == $(rand(T))
end

for T in (EP, EP2)
    name = string(T)
    name in suite || (suite[name] = BenchmarkGroup())
    suite[name]["=="] = @benchmarkable $(rand(T)) == $(rand(T))
    suite[name]["+"] = @benchmarkable $(rand(T)) + $(rand(T))
    suite[name]["-"] = @benchmarkable $(rand(T)) - $(rand(T))
    suite[name]["*"] = @benchmarkable $(rand(T)) * $(rand(BN))
    suite[name]["isinf(::$name)"] = @benchmarkable isinf($(rand(T)))
    suite[name]["isvalid(::$name)"] = @benchmarkable isvalid($(rand(T)))
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
