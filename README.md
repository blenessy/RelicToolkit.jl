# Introduction

Julia Wrapper for the [Relic Toolkit](https://github.com/relic-toolkit/relic).

# Quick Start

You can test this with on x86/amd64 Windows, Mac, and Linux:

```julia
using Pkg
Pkg.add(PackageSpec(url="https://github.com/blenessy/RelicToolkit.jl"))
```

Not much wrapped yet, but this should work:
```julia
using RelicToolkit: md_hmac
md_hmac(zeros(UInt8, 32), UInt8[1, 2, 3], UInt8[1, 2, 3])
```

# Short Term Goal

- [ ] PoC finished
- [ ] Implement the necessary wrappers for the BLS12 381 signature scheme.
- [ ] Fix `TODO`s in code
- [ ] Add `.travis.yml` and improve `README.md` so that the community can help

# Long Term Goal

- [ ] Implement wrappers for all Relic Toolkit APIs
- [ ] Support all ARCH/OS combos that Julia and the Relic Toolkit has in common
