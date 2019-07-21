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
using RelicToolkit
RelicToolkit.md_hmac(UInt8[1, 2, 3], UInt8[1, 2, 3])
```

# 0.1.0

- [ ] PoC finished (missing Windows)
- [ ] Implement the necessary wrappers for the BLS12 381 signature scheme.
- [ ] Fix `TODO`s in code
- [ ] Add `.travis.yml` and improve `README.md` so that the community can help
- [x] Add conversion from Integer
- [x] Add syntactic sugar by overloading applicable operators (e.g. +, -, *, //, ^)
- [x] Use BN(undef) and FP(undef) where safe to save some clock cycles
- [x] remove function name prefix from lib - it just make it harder to switch
- [ ] implement all logical operators for BN, FP, and FPX
- [x] make it possible to instantiate both libs in one session
- [x] implement zero and one functions
- [ ] Unit tests for EPX
- [ ] BLS Schema System Test and example in README.md

# Long Term Goal

- [ ] Implement wrappers for all Relic Toolkit APIs
- [ ] Support all ARCH/OS combos that Julia and the Relic Toolkit has in common
- [ ] Support (signed) integers where BN is supported with FP and EP
- [ ] BN should extend Signed and should be automatically convertible/promotable to BigInt
