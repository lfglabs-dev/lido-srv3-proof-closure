# TOPUP pointer origin and memory aliasing

Additive lot on `grok/lido-topup-aliasing-20260911`. No existing Lean, registry,
Trust, or import-DAG file is edited. Integration is a later agent’s job.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `e9d6288ae84ba4191a8c705a85220b35cc44e7ca` |
| Work-branch parent (lot a/b) | `b9182478fcc7385a6a2579d615315cf172a1f6cd` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |
| Verity pin (`lakefile.lean`) | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |

CLAIM: grok owns topup-pointer-origin since 2026-09-11

STATUS: proving module_head_in_raw_zone

## Obligation

The Verity memory model used by the existing TOPUP theorems is
`audit.trio.deposit.ModuleCall.finalizeAllocation` plus an immutable returndata
byte list. It is **not** a shared byte-addressable EVM store. A pointer’s origin
is the cursor that produced the allocated half-open interval `[origin, next)`.
Zones alias iff those intervals overlap (`Disjoint` fails).

### (a) Sequential same-execution allocations do not alias

| Theorem | Solidity / IR | Claim |
| --- | --- | --- |
| `allocation_origin` | solc 0.8.25 `finalize_allocation` IR3149–3159 | Successful allocation originates at its input cursor; `next < 2^64` and monotone. |
| `finalize32_next` | same helper, 32-byte STATICCALL copy | Locator/credentials copy: `next = cursor + 32`. |
| `chained_scalar32_disjoint` | `TopUpGateway.sol:185` IR512–538 (`_24 = mload(64)`) | Locator allocation then credentials allocation on the returned next pointer are disjoint. |
| `credentials_zone` | `StakingRouter.sol:1012–1014` `getWithdrawalCredentials`; `:1046–1048` `_getWithdrawalCredentialsWithType`; gateway credentials STATICCALL decode | Successful `decodeCredentials` originates `[cursor, cursor+32)`. |
| `locator_zone` | `TopUpGateway.sol:185` `LOCATOR.stakingRouter()` selector `0xef6c064c`, IR498–511 | Same 32-byte zone before the canonical-160 guard. |
| `module_decode_zones` | `StakingRouter.sol:717–719` `allocateDeposits` returndata; IR1082–1086; IR3323–3353 | Raw-return zone and `uint256[]` zone are sequential (`arr.origin = raw.next`) hence disjoint. |
| `module_head_offset_bounds` | IR3323–3347 signed length-word `slt(add(offset, 0x1f), end)` | On `decodeReturn` success the ABI offset is `< 2^64` and `offset+32 ≤` copied size; the head word does not wrap. Recovered from `raw_bounds` / `signedLt`, not a new `finalizeAllocation` argument. |
| `module_head_in_raw_zone` | `StakingRouter.sol:717–719`; IR3323–3347; head at IR3348–3353 `add(headStart, mload(headStart))` | The head pointer `cursor.val + decode (raw.take 32)` belongs to the same-execution raw zone `[cursor, postRaw)` and not to the array zone `[postRaw, next)`. |

No extra admission, sum, wrap, or successful-stage premise is added. Each
theorem is conditioned only on the existing decoder/`finalizeAllocation`
success already used by `PTopupMemoryCalls` / `PTopupCredentialCalls` /
`PTopupRouterLocatorCall`.

### (b) Independently supplied cursors may alias; existing TOPUP premises do not exclude it

`TopupCredentialCall.run` and `TopupBatchMemory.run` take `credentialCursor`
and `returnBuffer` as separate `Word`s. Existing tests instantiate both at
`128`. Both decoders succeed, and the zones `[128,160)` and `[128,256)` overlap.

| Theorem | Claim |
| --- | --- |
| `same_cursor_successful_decodes_alias` | Same cursor + both decoder successes ⇒ ∃ post-return zone that aliases the credentials zone. |
| `independent_cursor_alias_refutes_global_nonalias` | Kill-line: the universal “successful credential+module decodes ⇒ disjoint zones” statement is false. |
| `free_memory_slot_finalize32` / `free_memory_pointer_slot_admitted` | Cursor `64` (`mstore(64)` / `0x40`) is admitted. The model has no free-memory cell, so that alias is not excluded. |
| `module_head_encodeReturn_at_128` | `encodeReturn [1,9]` @ cursor 128: head `160 ∈ [128,256)` and `160 ∉ [256,352)`. |
| `module_head_in_array_zone_refuted` | Kill-line: “successful decode ⇒ head ∈ array zone” is false. |

This is not a renamed premise and not an always-success stub. It is a
reproducible witness that an unexcluded alias is compatible with the existing
TOPUP decoder-success premises, so those premises do not establish
cross-phase non-aliasing.

## Hypotheses

- Decoder/`finalizeAllocation` success only (already required by the consumed
  TOPUP theorems).
- Interval aliasing is the whole memory model: no `mload`/`mstore` store, no
  returndata-copy overlapping writes, no opcode gas.
- `returnBuffer` origin remains an explicit phase input, as already disclosed
  by `audit/topup-module-memory/README.md` and
  `audit/topup-router-locator-call/README.md`.

## Limits

- Physical guards (`moduleExists`, WC type 2, pause, timing) are not re-proved;
  they do not allocate these memory zones.
- Compiled EVM memory, `returndatacopy` into `mstore(64)`, and gas are outside
  the model. A green build of these files is not bytecode correspondence.
- Locator immutable identity and deployed `LidoLocator` body remain phase
  inputs, as in `PTopupRouterLocatorCall`.

## Checks

```
lake build LidoSRv3.Audit.Source.TopupPointerOrigin
lake build LidoSRv3.Tests.TopupPointerOriginMutants
lake env lean LidoSRv3/Audit/Source/TopupPointerOrigin.lean
lake env lean LidoSRv3/Tests/TopupPointerOriginMutants.lean
```

`#print axioms` of every exported theorem lists only
`propext` / `Classical.choice` / `Quot.sound` (or nothing). Observed:
definitions and `Disjoint` lemmas are axiom-free; allocation/decode
theorems use `propext`/`Quot.sound`; `chained_scalar32_disjoint` also
uses `Classical.choice`. No `sorryAx`.

`lake build LidoSRv3Test` is the package-wide test target; it does not need a
lakefile edit because `LidoSRv3.Tests` is a glob.

## Minimal integration diff (not applied)

If a later agent wants the facade / a guarantee to mention this lot:

```diff
--- a/LidoSRv3/Audit/Guarantees/PTopupMemoryCalls.lean
+++ b/LidoSRv3/Audit/Guarantees/PTopupMemoryCalls.lean
@@
 import LidoSRv3.Audit.Source.TopupBatchMemory
+import LidoSRv3.Audit.Source.TopupPointerOrigin
```

No `guarantees.yaml` / Trust / global import change is required for the
theorems to exist. Do not treat `CHECKED` P-TOPUP-1/2 as closed by this lot.
The remaining parent gaps (beacon-address provenance, wei conversion,
`allocateDeposits` policy, keccak memory-array oracle) are unchanged.
