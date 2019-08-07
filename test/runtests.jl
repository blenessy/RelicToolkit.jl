const TEST = get(ENV, "TEST", "UnitTests")
const CURVE = get(ENV, "RELIC_TOOLKIT_CURVE", "BLS381")

@info TEST, CURVE

eval(Meta.parse("using RelicToolkit.$CURVE"))
include(joinpath(@__DIR__, "$TEST.jl"))

