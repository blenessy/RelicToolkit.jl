module RelicToolkit

using Libdl

# Load in `deps.jl`, complaining if it does not exist
const DEPS_PATH = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(DEPS_PATH)
    error("RelicToolkit is not installed properly, run Pkg.build(\"RelicToolkit\"), restart Julia and try again")
end
include(DEPS_PATH)

# Module initialization function
function __init__()
    # Always check your dependencies from `deps.jl`
    check_deps()
end

# abstract away the curve
const LIB = librelic_gmp_pbc_bls381
const PREFIX = "gmp_pbc_bls381_"
const BN_READ_BIN = Symbol(PREFIX, :bn_read_bin)
const BN_SIZE_BIN = Symbol(PREFIX, :bn_size_bin)

# TODO: get this from lib
const BN_SIZE = 34

# TODO: get this from lib
const MD_SIZE = 32

mutable struct BN
    alloc::Cint
    user::Cint
    sign::Cint
    dp::NTuple{BN_SIZE,UInt64}
    BN() = new(0, 0, 0, Tuple(zeros(UInt64, BN_SIZE)))
end

function bn_read_bin(a::BN, bin::Vector{UInt8})
    ccall((BN_READ_BIN, LIB), Cvoid, (Ref{BN}, Ptr{UInt8}, Cint), a, bin, length(bin))
    return a
end

function bn_size_bin(a::BN)
    return ccall((BN_SIZE_BIN, LIB), Cint, (Ref{BN},), a)
end

function md_hmac(mac::Vector{UInt8}, in::Vector{UInt8}, key::Vector{UInt8})
    length(mac) == MD_SIZE || error("mac length $(length(mac)) != $MD_SIZE")
    ccall((:md_hmac, LIB), Cvoid, (Ref{UInt8}, Ptr{UInt8}, Cint, Ptr{UInt8}, Cint),
        mac, in, length(in), key, length(key))
    return mac
end

end # module
