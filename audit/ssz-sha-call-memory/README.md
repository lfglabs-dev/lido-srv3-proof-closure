# SSZ SHA CALL memory

This bounded slice connects the accepted BLS pubkey scratch operations to the
existing EvmYul `EVM.call`, `Θ` and `Ξ_SHA256` definitions. It uses the actual
opaque `ffi.sha256 input input.size.toUSize`. It neither replaces the interpreter
nor assumes a successful result, a copied buffer, a readback value, or an expected
SHA root. A 32-byte FFI result is an explicit condition: this FFI has no existing
Lean length/correctness theorem.

Source anchor: `lido-core/contracts/common/lib/BLS.sol:538–560` at
`17005714f151e5502c559932319a3f2f74ac2436`. The source executes the length guard,
zeroes memory 32..63, copies the 48-byte key to memory 0, calls precompile 2 on 64 bytes
with a 32-byte output window, checks success AND returndata length 32, then mloads 0.
The accepted scratch theorem supplies the raw input from actual calldata, with
an explicit offset/extent condition. It does not execute the Solidity ABI decoder.

The generic CALL consumer takes the real supplied gas word and the call gasCost
parameter; admission concerns the computed `Ccallgas`, not merely requested gas.
The 64-byte SHA fee is derived as 84. The zero-value gas cap fits UInt256 by the
requested gas word's own bound. Fuel and depth conditions are explicit. These
memory results do not prove gas-charged `EVM.X`, stack decoding, compiled BLS
execution, or the caller's revert ABI. The direct CALL helper itself subtracts
its supplied gasCost without a separate underflow check; no physically reachable
gas execution is claimed from that generic helper alone.

Byte-copy/readback/frame conclusions allow arbitrary old memory and activeWords.
The separate mload conclusion needs initial activeWords < 2^251: the existing
`lookupMemory` compares against `activeWords * 32` as a UInt256. At 2^251 this
product wraps to zero and mload 0 returns zero even for nonzero copied memory.
This is an exposed limitation, not silently excluded from the byte theorem.

No whole-world frame is claimed. In particular, the existing Θ precompile branch
returns an empty createdAccounts set. The receipt must distinguish actual engine
observations from any intended broader EVM semantics.

Targeted validation: 14 public source theorems, 10 kernel-checked regression
examples and nine explicit axiom queries. The queried declarations use only
`propext`, `Classical.choice` and `Quot.sound`; no custom axiom, `sorry`,
`native_decide` or `bv_decide` is introduced. The target build uses cached
unchanged dependencies; it is not a full repository rebuild.

Reproduce from the proof checkout:

```sh
lake build LidoSRv3.Audit.Source.SszShaCallBytes LidoSRv3.Audit.Source.SszShaCallMemory LidoSRv3.Tests.SszShaCallMemoryMutants
python3 audit/ssz-sha-call-memory/check_receipt.py
```

`validation.log` captures the executed targeted command's output. `axioms.log`
contains the nine queries. `dependency-inputs.json` identifies the complete
package Lean source import closure from the final Lake setup and selected core
ByteArray/Array/UInt/platform files; the remaining toolchain is separately
pinned, not represented as a full core source closure. `validated-inputs.sha256`
and `receipt.json` bind the exact sources, inherited local dependencies,
package pins, root-owned Solidity evidence and other receipt artifacts.
`check_receipt.py` checks recorded identities without compiling or running Forge.
Hash-comparison counts are not counts of independent proofs.
Identity-precompile tests exercise real CALL handling of 0/31/32/33-byte replies;
they are not substituted SHA correctness proofs. No fresh actual-Solidity SHA
claim is made unless a separately supplied root-owned receipt is present.

The `blsCall` consumer specializes the generic helper to the source's actual
caller word (`UInt256.ofNat codeOwner.val`), `gas()` request and existing `Ccall`
fee. Its explicit fee-admission condition yields the fee's representation bound.
It derives the positive success flag and returndata-size guard; it does not
execute the failure-branch error encoding, stack dispatch, or EVM.X gas gate.
The generic `call_sha_bytes` input-size condition is derived by the scratch
consumer from the actual calldata extent, not an extra end-result premise.

The root-owned `solidity/` receipt records four tests, including two properties
with 1024 runs each. They distinguish real SHA examples, real identity-precompile
output-copy checks, and explicitly mocked address-2 responses for source guard
fault injection. Successful short address-2 replies are not claimed to be possible
standard-SHA outputs, a deployed defect, or a model of the opaque FFI. The worker
consumes that frozen receipt without rerunning or editing its harness.

The new Lean regressions cover actual identity calls with return lengths 0, 31,
32 and 33, real SHA rejection at 83 gas, CALL fuel 0 and 1, depth 1024, and the
nonzero-memory word-extent wrap witness. They normalize actual ByteArray readers
and writers with proved lemmas before kernel computation; they do not replace
CALL or the callee. The accepted scratch dossier supplies the existing offset,
48-position, dirty-prefix/suffix and short/long-memory regressions. Those prior
cases are dependency evidence, not newly counted tests in this slice.

Open source placement boundaries also include the source length-48 guard/ABI
layout, which is outside the direct helper and expressed here by the input
extent. The earlier scratch `typed_pubkeyBlock` theorem remains usable for a
prefix/key48/suffix layout. This slice does not yet equate opaque FFI words with
the separate typed `ShaReply` or hash-tree semantics, nor close verifier root
lookup, fls/index decoding, calldata proof loads, or address provenance.
