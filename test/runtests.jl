const DEFAULT_SUITES = "AcceptTests,UnitTests,PerfTests"

for test in split(get(ENV, "TEST", DEFAULT_SUITES), ",")
    include(joinpath(@__DIR__, "$test.jl"))
end

