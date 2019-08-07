[![Build Status](https://travis-ci.com/blenessy/RelicToolkit.jl.svg?branch=master)](https://travis-ci.com/blenessy/RelicToolkit.jl)
[![codecov](https://codecov.io/gh/blenessy/RelicToolkit.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/blenessy/RelicToolkit.jl)

# Introduction

Julia Wrapper for the [Relic Toolkit](https://github.com/relic-toolkit/relic).

The goal is to facilitate a user-friendly, secure, and performant PBC lib for Julia.

# Key Features

- [x] Supports multiple Curves (BLS381 and BN254)
- [x] Single-line (`using ...`) changes curve
- [x] Supports both 32 and 64 bit machines
- [x] Supports common operative systems (Linux, Mac, Windows)
- [x] State-of-the art performance
- [ ] Production Ready (timing, side-channel resistance)

# Quick Start

So lets implement the simplest possible BLS signature scheme in 10 lines of code!

The symbols (e.g. `pk`, `H(m)`) below were chosen to be consistent with this [excellent blog](https://medium.com/cryptoadvance/bls-signatures-better-than-schnorr-5a7fe30ea716).

```julia
using Pkg
Pkg.add(PackageSpec(url="https://github.com/blenessy/RelicToolkit.jl"))
```

Import the Curve functions you want to use (`BLS381` and `BN254` are currently supported):
```julia
using RelicToolkit.BLS381
```

Lets start by defining the following functions to remain consistent with [Stepan's blog](https://medium.com/cryptoadvance/bls-signatures-better-than-schnorr-5a7fe30ea716):
```julia
# a.k.a. hash to curve function
H(m) = curve_map(EP2, Vector{UInt8}(m))
# a.k.a. pairing function
e(P::EP, Q::EP2) = field_final_exp(curve_miller(P, Q))
```

Create a random private key:
```julia
pk = mod(rand(BN), curve_order(EP))
```

Generate a public key from the private key:
```julia
G = curve_gen(EP)
P = pk * G
```

Generate a public key from the private key:
```julia
P = pk * curve_gen(EP)
```

Sign a hashed message:
```
S = pk * H("foo")
```

Validate the signature:
```
@assert e(P, H("foo")) == e(G, S)
```

# Performance

You can run the performance tests with:

```julia
make CURVE=BLS381 bench
```

Performance is state of the art (on par with C).
You should get something like this on a 4-5 year old 2.2GHz Core i7:

```
...
[PP][field_final_exp]: 947.266 μs (alloc: 1, mem: 624 bytes, gc: 0.000 ns)
[PP][curve_miller]: 1.734 ms (alloc: 1, mem: 624 bytes, gc: 0.000 ns)
...
```

Since the pairing function is defined as `field_final_exp(curve_miller(P, Q))` you can estimate 
its performance by adding these times together.

# Configurations

Cofiguration is done through environment variables.
The number of configuration possibilities should be limited for simplicity.

Key | Default | Description
--- | --- | ---
RELIC_TOOLKIT_CURVE | (all curves are loaded) | Used for limiting, which curve is loaded (saves memory) at startup. Possible values are: `BN254` and `BLS381`.

# Contibutions

Contributions are welcome!
If you are unsure where to chip in, please see the roadmap below.

## Testing

Currect code coverage is 100% and the author would like to keep it that way.

Test | Purpose
--- | ---
`UnitTests` | Make sure the `ccall` are working and do not crash Julia.
`SysTests` | Protect complete features from breaking
`PerfTests` | Fair benchmarks for performance awareness

## Fixes and minor features

Just create a PR (as usual in GitHub) and make sure that the code coverage stays at 100%.

## High-level API changes and new Features

1. Please start by creating an issue and explain your use-case and goal.
2. Create a PR (as usual in GitHub) with the implementation and add a new `SysTest` to protect your use-case.

# Roadmap

## 0.1.0: Provide smooth API for implementing BLS Signatures

- [x] PoC finished (missing Windows)
- [x] Add `.travis.yml` and improve `README.md` so that the community can help
- [x] Add conversion from Integer
- [x] Add syntactic sugar by overloading applicable operators (e.g. +, -, *, //, ^)
- [x] Use BN(undef) and FP(undef) where safe to save some clock cycles
- [x] Remove function name prefix from lib - it just make it harder to switch
- [x] Make it possible to instantiate both libs in one session
- [x] Implement zero and one functions
- [x] Unit tests for EPX
- [x] BLS Schema System Test and example in README.md
- [x] `README.md` chapter about performance
- [x] `README.md` chapter about configuration
- [x] `README.md` chapter to contributors
- [x] Tested on Windows
- [x] Tested 32-bit Linux

## 0.2.0: Facilitate timing and side-channel resistance

- [ ] Fix `TODO`s in code
- [ ] Add `gmp-sec` libs for timing resistance.
- [ ] Use timing resistent `FP`, `EP`, and `PP` configs and functions.
- [ ] Add tests that measure time, CPU, Memory usage consistency over time. 

## 0.x.0: PBC feature complete

- [ ] Julia 1.3.x and multi-thread support
- [ ] Implement all logical operators for BN, FP, and FPX
- [ ] Support all ARCH/OS combos that Julia and the Relic Toolkit has in common
- [ ] Support (signed) integers where BN is supported with FP and EP
- [ ] BN should extend Signed and should be automatically convertible/promotable to BigInt

## 1.0.0: Production Ready

- [ ] Academic/security audits (help needed)
