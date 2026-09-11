# SSZ-1 compiled afterRoot error classification

Additive lot on `grok/lido-ssz-afterroot-class-20260911` from current
`origin/main`. No existing Lean, registry, Trust, or import-DAG file is
edited.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `ea8e546cedba3c1bbf306eee1a059cdba19eeaca` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |
| Verity pin (`lakefile.lean`) | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |

CLAIM: grok owns ssz-afterroot-class since 2026-09-11

STATUS: ready

## Obligation

`afterRoot` (IR 116-417) is the unique divergence after the compiled
prefix `beforeRoot` / `rootCall`. This lot classifies its error
constructors (`.reply`, `.abi`, `.gindex`, `.allocation`, `.bls`,
`.proof`) against the Solidity/IR sites they reflect, proves that
slot-panic constructors stay on `_verifySlot`, and kills a named line
per reachable class. EIP-4788 authenticity/freshness remain declared
premises. Compilation, crypto, gas and consensus stay outside.

## Files

| File | Role |
| --- | --- |
| `LidoSRv3/Audit/Source/SszCompiledAfterRootClass.lean` | Additive theorems |
| `LidoSRv3/Tests/SszCompiledAfterRootClassMutants.lean` | Named kill-lines |
| `audit/ssz-afterroot-class/README.md` | This note |

## Theorems

Each theorem cites the compiled function and the Solidity/IR it reflects
(`CLValidatorVerifier.sol` at the pinned core, inspected IR
`audit/ssz-compiled-cl-entry/solidity/inspected-cl-entry-ir.yul`).

| Theorem | Reflects | Statement |
| --- | --- | --- |
| `isAfterRootClass` | `afterRoot` IR 116-417 | Named constructors `.reply` / `.abi` / `.gindex` / `.allocation` / `.bls` / `.proof` |
| `liftConsumer_is_afterRootClass` | `liftConsumer` (`SszCompiledClEntry.lean:45-49`) | Leaf/merkle consumer errors stay in that class; never slot-panic |
| `failed_staticcall_is_rootNotFound` | `decodeRoot` `CLValidatorVerifier.sol:103-107`, IR 146-148 | `success = false` ⇒ `.rootNotFound` |
| `afterRoot_of_failed_staticcall` | `afterRoot` bind of `decodeRoot` | `success = false` cannot return `.ok` |
| `empty_proof_is_invalidProof` | `SSZ.verifyProof` count guard, IR 390-417 | `count = 0` ⇒ `.invalidProof` |
| `afterRoot_error_is_afterRootClass` / `afterRoot_error_class` | full `afterRoot` bind walk (copy → decode → read64 → wrapper → allocate → key tail → pubkey → storeFields → merkle → proof tail → verify) | Every `afterRoot` error is `isAfterRootClass` |
| `afterRoot_never_slot_panic` | contrast with `slotSibling` IR 70-97 | `afterRoot` never raises `.panic11` / `.panic32` / `.invalidSlot` |
| `afterRoot_failed_flag_is_reply` | IR 116-148 | `success = false` ⇒ error is `.reply _`; later binds unreachable |
| `afterRoot_failed_flag_is_rootNotFound_of_copy` | IR 146-148 after IR 116-145 success | Successful `copyReply` + failed flag ⇒ `.reply .rootNotFound` |
| `copyReply_empty_ok` | IR 116-145 size-0 branch | Empty returndata copies without allocation |
| `copyReply_oversized_is_panic41` | IR 116-145 uint64 size guard | `returndatasize > 2^64-1` ⇒ `.panic41` |
| `read64_wide_is_abi` | `read64` at calldata 36, IR 167 | Word ≥ `2^64` ⇒ ABI |
| `pubkey_wrong_length_is_invalid` | key SHA length guard, IR 234+ | `length ≠ 48` ⇒ `.invalidPubkeyLength` |

## Mutants

| Kill-line | Mutant killed |
| --- | --- |
| `reply_rootNotFound_kill_line` | Failed STATICCALL still decodes a root |
| `reply_kills_afterRoot_success` / `afterRoot_ok_requires_success_kill_line` | `afterRoot` succeeds with `success = false` |
| `gindex_out_of_range_kill_line` | Index outside the configured subtree still packs |
| `proof_empty_kill_line` | Empty sibling list still verifies |
| `liftConsumer_proof_not_slot_panic` | Consumer proof error becomes `.panic11` |
| `abi_wide_slot_kill_line` | Wide calldata word still reads as uint64 |
| `copyReply_oversized_kill_line` | Oversized returndata still copies |
| `bls_wrong_pubkey_length_kill_line` | Empty pubkey slice still hashes |

## Hypotheses (declared, not proved here)

- EIP-4788 authenticity and freshness of the BEACON_ROOTS reply.
- Compilation of the inspected IR against the pinned Solidity source.
- Crypto (SHA-256 injectivity), gas, consensus, deployed locator identity.

## Axioms

`#print axioms` of every export is only `propext` / `Classical.choice` /
`Quot.sound`, or a subset. No `sorry`, no `sorryAx`, no extra axiom.
No `keccakMemorySlice := fun _ _ _ => 0` closed by a premise.

## Open / not this lane

- Header `do`/`throw` join-points (`SszCompiledClEntry.header`, IR 40-55)
  still block constructor analysis of later dispatcher guards. The
  honest raccord is an explicit `if`/`.error`/`.ok` nest in
  `SszCompiledClEntry.lean:53-63` (same seven guards, same order). That
  edit is outside this exclusive three-file contract; it remains
  documented on the compiled-rollback lot.
- Allocation panic 0x41 of `allocate` (`SszCompiledMemory.lean:490-497`)
  uses `do`/`throw`. Classification still maps it through
  `Error.allocation` in the `afterRoot` walk; a constructor-level
  `allocate` lemma would need the same ite rewrite.
- No claim that a concrete FFI world reaches every constructor.

## Recheck

```sh
export PATH="$HOME/.elan/bin:$PATH"
lake build LidoSRv3.Audit.Source.SszCompiledAfterRootClass
lake build LidoSRv3.Tests.SszCompiledAfterRootClassMutants
lake env lean LidoSRv3/Audit/Source/SszCompiledAfterRootClass.lean
lake env lean LidoSRv3/Tests/SszCompiledAfterRootClassMutants.lean
```
