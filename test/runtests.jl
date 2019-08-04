const TEST = get(ENV, "TEST", "UnitTests")
const CURVE = get(ENV, "CURVE", "BLS381")

@info TEST, CURVE

eval(Meta.parse("using RelicToolkit.$CURVE"))
include(joinpath(@__DIR__, "$TEST.jl"))

