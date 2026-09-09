# One actual SSZ calldata iteration

This supplement connects a nonempty iteration of pinned `SSZ.sol:179–249` to the
existing generic `SszProofFold.sourceFold`, instantiated with `EvmYul.UInt256`
and the **same concrete, opaque FFI-backed pair function**. It does not close
SSZ-1 or replace the registered verifier, leaf, entry or canonical-state programs.

## What the theorem derives

`sourceStep_success` starts from an independent raw calldata layout: arbitrary
prefix bytes, a list of fixed 32-byte big-endian sibling words, and arbitrary
suffix bytes. A list decomposition selects the current sibling. From total
calldata size below `2^256`, the proof derives the actual cursor's word fit,
in-range 32-byte extent, shifted length/end arithmetic, next offset and loop
continuation. It does not receive a loaded sibling or a no-wrap conclusion.

The executed operations use the existing EvmYul primitives:

1. Compute scratch from the **current** index, then shift the parent index and
   reject zero parent. `sourceStep_extra` proves this rejection for index 0/1.
2. Perform the first actual `mstore`, then actual `State.calldataload` from the
   resulting state's calldata, then the second `mstore` at the XOR-selected half.
3. Execute the existing `EVM.call → Theta → Xi_SHA256 → ffi.sha256` path with
   actual code-owner, `gasAvailable`, and `Ccall` operands, reusing PR278.
4. Check the returned flag **only**, then execute actual `mload(0)`, advance the
   word cursor by 32 and compare it with the computed end word.

The outcome's word digest and parent agree with one step of the existing typed
fold using `ffiPair`. The next cursor equals the mathematical byte offset plus
32, and the continuation flag is true exactly when a sibling remains. The
separate `decodeIndex` facts prove `GIndex.sol`'s shift by eight and its derived
uint248 width. This decoder can initialize the iteration; the main theorem takes
the current decoded index, as subsequent iterations do.

`SszWordBytes` relates the pinned engine's **actual** minimal-word encoder plus
FFI leading-zero padding to an independent fixed-count base-256 digit definition.
It proves 32-byte size and both actual calldata/memory decoder roundtrips for all
words. A local alias of the encoder's recursive body is definitionally equal to
the public engine encoder; no generated private name or replacement interpreter
is used. `ByteArray.toList`'s actual loop is also related to `data.toList`.

`calldata_read_fit` unfolds the real `readBytes`, including its copySlice and
large-offset list branches and USize padding. Both write-order lemmas allow dirty,
short or long initial memory and preserve its complete tail from byte 64. The
byte and input-read results do not require an activeWords bound. They are not
assumptions about a zero-initialized scratch buffer.

## Exact admission and remaining obligations

- The raw prefix/list/suffix layout and total size `< 2^256` are explicit ABI and
  representation conditions. No compiler ABI decoder, calldata-head extraction,
  malformed-input equivalence or deployed reachability of these conditions is
  proved. The selected list decomposition is a semantic input, not a decoded
  Solidity array supplied by a proven caller.
- Success requires current index > 1, depth < 1024, at least 84 gas actually
  forwarded by the existing cap, and sufficient gas to pay the calculated CALL
  fee. CALL receives `fuel+2`, leaving recursion fuel for Theta. The bound on the
  fee's word conversion is derived. Preparation and CALL use direct primitives;
  full opcode/stack/X dispatch, charging for the preceding operations and a
  resource theorem for the entire proof are still open.
- The actual opaque FFI result is explicitly required to contain 32 bytes.
  The program itself has **no return-size guard**, matching this SSZ loop rather
  than BLS. No SHA-256 correctness, universal FFI length, collision resistance or
  refinement of the existing leaf/entry `standardSha` adapter is established.
  `ffiPair` decodes the real FFI bytes into a word; it does not assert a supplied
  successful digest or final-root match.
- Actual `mload` needs initial `activeWords < 2^251`, due to the engine's wrapped
  UInt256 extent product. This is a representation condition, not a newly proved
  reachable-state invariant. PR278 retains the universal wrap witness at the
  excluded boundary. Full byte copying remains unrestricted by that condition.
- `StepError` is an error-tag projection. Extra-item selector writes, revert-byte
  ABI, root comparison, empty-proof entry rejection and missing-item final checks
  are not executed by this one-iteration program. Foundry checks those original
  source errors only as finite supporting evidence. No unchanged error-path
  memory, gas or complete EVM rollback is claimed.
- The entire proof loop is not yet composed through one state/gas history. The
  generic typed fold is reused at one step, not proved equivalent to the complete
  registered wrapper or canonical membership consumer. Root authentication,
  EIP-4788 timestamp anchoring, fork/credential provenance and compiler/runtime
  correspondence remain open. Theta's precompile path resets createdAccounts;
  there is no full-world frame claim.

## Validation

`fresh-validation.json` binds before/after hashes to fresh direct Lean checks of
both complete source files and the targeted test build. Direct checks write only
temporary outputs and reuse imported caches. The test module contains 34 kernel
examples and one fixture lemma, including all 256 one-hot bit positions, all 256
metadata bytes, endian/padding mutations, wrong cursors, both scratch orders,
dirty/short memory, shifted-parity mutations, end/stride/boundary cases, source
extra-item priority, the actual cold-account gas cap and source depth rejection.

Kernel examples use the proved encoder/read/write normal forms where the abstract
platform-sized FFI padding would prevent direct reduction. They do not silently
switch to native_decide or replace an engine function. The 256-bit example still
checks an independent fixed-position octet specification. Ten principal axiom
queries are recorded; no custom/native checker axiom is permitted. PR278's
unchanged real SHA gas-83, fuel-0/1, short identity-output and mload-wrap regressions
remain separately recorded under `audit/ssz-sha-call-memory/`; they are not counted
as new tests or claimed to have been freshly rerun here.

The separate Solidity dossier executes the unmodified pinned verifier with real
SHA and real compiler-produced calldata offsets. It contains four tests, one
1,024-run fuzz property, and 256 coupled bit/metadata cases. The finite reference
uses four explicit positions in a two-level tree. See its README for the precise
mock-free scope, observed memory word, and mutation limitations.

The receipt checker only compares recorded files, package pins and source
identities; it does not execute Lean or Forge. Dependency hashes cover the actual
Lake setup's package-source import closure and selected Lean core source files,
not every source file or binary in the full toolchain. Independent review of the
exact candidate is required before integration.
