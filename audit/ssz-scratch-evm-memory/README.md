# SSZ calldata scratch block on EvmYul memory

The new consumer proves the actual primitive memory block used by `BLS12_381.pubkeyRoot`: clearing bytes32–63, then copying48 bytes from the real calldata offset. For any initial EvmYul shared state, arbitrary dirty memory, and an in-bounds48-byte calldata slice, the final memory is exactly that slice, sixteen zeros, and the old memory tail beginning at64. The real `ByteArray.readWithPadding 0 64` consequently returns the independent SSZ input. Every zero-extended byte observation at or above64 is preserved. Short initial arrays grow to64; longer arrays retain their old size.

The `typed_pubkeyBlock` consumer derives the existing typed `SszValidatorLeaf.pubkeyBlock` from raw calldata laid out as prefix++pubkey++suffix, where the pubkey has48 bytes and the actual UInt256 offset denotes the prefix size. Neither the resulting copy nor its readback, padding, or encoded key is supplied as a premise. Prefix/suffix contents and the initial memory are arbitrary.

## Exact source and reused semantics

- [Pinned BLS.sol:538–548](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/common/lib/BLS.sol#L538) contains the width guard, `mstore(0x20, 0)`, then `calldatacopy(0, pubkey.offset, 48)`. The new `scratch` calls the existing `MachineState.mstore` and `SharedState.calldatacopy` in precisely this order. It does not substitute DenoteMemory or introduce an interpreter.
- EvmYul pin `f7e4ee0dc8f8d5265ce822a937ab5be771f182e9`, consumed through Verity pin `e977aaad6e1a9e92e0132d41b3d33a14135a4d46`: `EvmYul/MachineStateOps.lean` (`writeWord`, `mstore`), `SharedStateOps.lean` (`calldatacopy`), `Wheels.lean` (`UInt256.toByteArray`, `ByteArray.write`, `readWithoutPadding`, `readWithPadding`), and `FFI/ffi.lean` (the Lean body of zero-byte allocation).
- Lean4.31 core `ByteArray.copySlice_eq_append`, array extraction and padding lemmas are reused. `SszScratchByteArray` proves local write/clear/copy/read/frame lemmas by unfolding these existing semantics. Padding-size conversion is proved for both supported32/64-bit platforms, with no platform-specific axiom. The zero word codec is reduced in the kernel.
- `SszValidatorLeaf.pubkeyBlock` remains unchanged. The new module does not replace the accepted leaf/fold/entry/placement consumers. Its result is the missing memory-to-typed-input connection for this particular pre-SHA block.

## Theorems and independent specification

`SszScratchByteArray.lean` contains eleven public helper theorems plus one private USize lemma. `write_fit` gives a general in-bounds copy normal form with destination address at most64 and arbitrary destination bytes/length. `scratch_shape` derives the complete final array from the two writes. `read_prefix` and `frame_byte` establish observable readback/frame properties rather than assuming them.

`SszScratchEvmMemory.lean` contains seven theorems: `rawBlock_size`, `memory_exact`, `read_exact`, `frame`, `memory_size`, `context_preserved`, and `typed_pubkeyBlock`. The specification `rawBlock` directly extracts48 bytes from the original execution-environment calldata and appends a mathematical16-zero array. `memory_exact` also fixes the entire remaining old tail. The semantic world/environment and pre-existing returndata/return buffers are preserved by these primitives; this is separate from charging gas or executing the next call.

## Validation

The final targeted command is recorded in `receipt.json` and `validation.log`:

```sh
lake build LidoSRv3.Audit.Source.SszScratchByteArray LidoSRv3.Audit.Source.SszScratchEvmMemory LidoSRv3.Tests.SszScratchEvmMemoryMutants
```

It passed1097 jobs with25 regression examples, one fixture lemma, and eight axiom queries. The queried declarations depend only on `propext`, `Classical.choice`, and `Quot.sound`; no new axiom, `sorry`, `admit`, `native_decide`, or `bv_decide` is used. Existing Conform.Wheels/EvmYul.Pretty deprecation warnings were replayed; the new files have no warnings. `axioms.log` contains the eight lines extracted from this actual build, not a separate claimed run.

The Lean examples include dirty memory sizes0,1,31,32,47,48,63,64,65,256; offsets0,7,257; every one of48 key positions; every one of16 padding positions; frames at64,96 and beyond allocation; and the typed consumer. Seven negative examples kill six mutation classes: omitted zero store, reverse order, copy32, copy64, wrong offset (both±1), and destination32. They run the real primitive variants and use kernel reduction after proven byte-array normalization.

The separate root-authored [Solidity receipt](solidity/receipt.json) records four passing tests on the unmodified pinned BLS helper and a separately duplicated exact two-operation block: two1024-case fuzz properties, all48 one-hot key positions, and six mutations. Raw ABI calls dirty all16 ABI padding bytes after the key, vary dynamic prefix/suffix lengths and offsets, and dirty scratch memory. The real helper's root equals SHA256(key++zero16); words64/96 are observed unchanged. The duplicated block exposes the64 bytes before SHA. These finite execution checks complement, and are distinct from, the universal EvmYul primitive theorem. The worker verified the frozen receipt/source/harness/log hashes; it did not rerun or modify root's Solidity files.

`dependency-inputs.json` records the package source closure exposed by the final Lake setup, its hashes and module paths, plus selected Lean core byte-array/USize implementation files. The toolchain/version and dependency pins remain explicit. `validated-inputs.sha256` covers new Lean inputs, the complete local Lido import closure, relevant semantic source files, pinned Solidity, frozen Solidity dossier, and package/build configuration. `source-check.json` records a byte comparison with the source pin and operation-order checks. These checks identify the source consumed by the proof; they are not a compiler-refinement proof. Independent exact-candidate review is required after commit and is not claimed by the author receipt.

## Boundaries retained

1. The block starts after Solidity's length48 guard. `hfit` requires offset+48 within actual calldata; the typed consumer derives it from the stated layout. Solidity ABI decoding, malformed calldata, out-of-bounds source zero extension, and the entire function preamble are not proved here. No zero-memory or canonical zero-ABI-padding assumption is needed.
2. These are the existing EvmYul memory primitives, not a theorem about public opcode dispatch, compiler output, gas-charged `EVM.X`, stack safety, host allocation resources, or deployed runtime. Logical arrays may be arbitrary; `memory_size` describes their byte length, not gas.
3. The SHA `staticcall`, input transfer to the precompile, success/failure, returndata length, actual output-buffer copying and final `mload` are subsequent obligations. The proof derives only the input memory block and its typed interpretation. In particular, it does not silently turn the typed `ShaReply.output` into a derived EVM call result. BLS checks both the call flag and exact32-byte return; SSZ.verifyProof's flag-only behavior remains distinct.
4. SSZ's separate memory `mcopy` helper, proof-sibling `calldataload`/loop scratch, packed generalized-index decoding/fls, root lookup, SHA assumptions and deployment/configuration/consensus provenance are unchanged. This lot does not close all raw-memory or whole-validator-entry obligations.
