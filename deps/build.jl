using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
const products = [
    LibraryProduct(prefix, "librelic_gmp_pbc_bls381", :librelic_gmp_pbc_bls381),
]

# Download binaries from hosted location
const version = "0.4.0-614-g0109b037-2"
const bin_prefix = "https://github.com/blenessy/RelicToolkitBuilder/releases/download/$version"

# Listing of files generated by BinaryBuilder:
const download_info = Dict(
    Linux(:i686, :glibc) => ("$bin_prefix/RelicToolkit.v$version.i686-linux-gnu.tar.gz", "3de6fbe558d999ce1c065e89180e15f5ec56119bd5621cc995a9697ba07f4a8d"),
    MacOS(:x86_64) => ("$bin_prefix/RelicToolkit.v$version.x86_64-apple-darwin14.tar.gz", "3196440583affaffd9b1aa113ed652a8f35bd4b481e00968b508890a534a17f9"),
    Linux(:x86_64, :glibc) => ("$bin_prefix/RelicToolkit.v$version.x86_64-linux-gnu.tar.gz", "e6902d60d0a743467fbf253212b25560aa514dd2a39bd6a43e4172be20000a3b"),
    # broken
    #Windows(:i686) => ("$bin_prefix/RelicToolkit.v$version.i686-w64-mingw32.tar.gz", "36b2978b1527e2b9575237ab5ad393a74ea34c9561bc4c56720e203eb0cde94e"),
    #Windows(:x86_64) => ("$bin_prefix/RelicToolkit.v$version.x86_64-w64-mingw32.tar.gz", "62c1e36eaa44dd09258931e90e8e10d0804b9e4f892f0cc19474221d66df6687"),
)

# First, check to see if we're all satisfied
if any(!satisfied(p; verbose=verbose) for p in products)
    try
        # Download and install binaries
        url, tarball_hash = choose_download(download_info)
        install(url, tarball_hash; prefix=prefix, force=true, verbose=true)
    catch e
        if typeof(e) <: ArgumentError
            error("Your platform $(Sys.MACHINE) is not supported by this package!")
        else
            rethrow(e)
        end
    end
    # Finally, write out a deps.jl file
    write_deps_file(joinpath(@__DIR__, "deps.jl"), products)
end
