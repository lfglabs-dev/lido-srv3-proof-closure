# SSZ endian increment — 9 September 2026

Scope: `SSZ.toLittleEndian(uint256)` and `SSZ.toLittleEndian(bool)` at pinned
[lidofinance/core 17005714](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/common/lib/SSZ.sol#L251-L270).
The validator uses these helpers for effective balance, slashed and four epochs
at [lines 113–118](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/common/lib/SSZ.sol#L113-L118);
header integer fields use them at lines 23–24.

The source model preserves all eight masks, all shifts and all five stages as
256-bit operations. The independent specification concatenates individual
input octets in increasing significance order. It does not copy the mask/shift
algorithm. Four theorems prove, for arbitrary inputs:

- `source_uint256_eq_octets`: all 32 serialized octets match that specification;
- `source_uint64_chunk`: zero-extended uint64 values yield eight little-endian
  bytes followed by 24 zero bytes;
- `source_bool_chunk`: boolean encoding is byte 0 or 1 followed by 31 zero bytes;
- `source_uint256_injective`: serialization preserves every input bit.

The accepted candidate contains no `bv_decide`, `native_decide`, custom axiom,
`sorry` or admitted premise. The arithmetic proofs enumerate the 256 possible
*bit positions*, keeping the entire input word universally quantified. They
use kernel-checked `interval_cases` and bit-vector simplification. An earlier
unaccepted experiment used bv_decide; its generated native checker axioms were
detected and the experiment was replaced before integration.

Build command executed successfully with Lean 4.31.0 and repository Lake env:

```
lake env lean -o /tmp/lido-ssz-endian-20260909/LidoSRv3/Audit/Source/SszLittleEndianCorrespondence.olean LidoSRv3/Audit/Source/SszLittleEndianCorrespondence.lean
```

The output log `lean-source.log` is empty (exit 0, no warnings). Final tests and
axiom inspection are recorded separately in `receipt.json` when complete.

The independent finite source-expression check in `differential.py` parses the
pinned Solidity masks/shifts, checks their equality to Lean, compares 2308
uint256 values with Python byte serialization, and detects seven mutations:
omit each of five swap stages, truncate input to uint64, put the boolean byte
at the wrong end. This script is not an EVM test. The integrator separately ran
actual pinned Solidity tests in `solidity/test/SszLittleEndian.t.sol`.

Residual boundary: this is a helper-arithmetic result. Source transcription
still depends on exact-source review. It does not connect the helpers to a
Solidity/Verity/EVM execution theorem, prove byte-addressed memory, validate
validator field selection or offsets, establish wrapper generalized indices,
or discharge SHA-256/precompile and deployment provenance. Canonical SSZ-1
SOURCE/TX closure must not be inferred from this increment.
