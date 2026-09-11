# SSZ-1 compiled beforeRoot / rootCall error classification

Additive lot on `grok/lido-ssz-beforeroot-class-20260911` from current
`origin/main`. No existing Lean, registry, Trust, or import-DAG file is
edited.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `0391c430644b0987bebac105d890ca636e2aef8b` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |
| Verity pin (`lakefile.lean`) | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |

CLAIM: grok owns ssz-beforeroot-class since 2026-09-11

STATUS: ready

## Obligation

Classify errors of the compiled prefix `beforeRoot` (IR 43-100),
`slotSibling` (IR 70-97) and `rootCall` (IR 101-114), and partition
`run` failures by phase. Positive constructor classes (not merely
“not proof/root”). Disjoint from #370 (compiled rollback) and #375
(afterRoot class). EIP-4788 authenticity stays declared.

## Files

| File | Role |
| --- | --- |
| `LidoSRv3/Audit/Source/SszCompiledBeforeRootClass.lean` | Additive theorems |
| `LidoSRv3/Tests/SszCompiledBeforeRootClassMutants.lean` | Named kill-lines |
| `audit/ssz-beforeroot-class/README.md` | This note |

## Theorems

Each theorem cites the compiled function and the Solidity/IR it reflects
(`CLValidatorVerifier.sol` at the pinned core, inspected IR
`audit/ssz-compiled-cl-entry/solidity/inspected-cl-entry-ir.yul`).

| Theorem | Reflects | Statement |
| --- | --- | --- |
| `isBeforeRootClass` | `beforeRoot` IR 43-100 | `.abi` / `.bls` / `.panic11` / `.panic32` / `.invalidSlot` |
| `isSlotSiblingClass` | `slotSibling` IR 70-97 | `.panic11` / `.panic32` / `.invalidSlot` |
| `header_of_nonzero_value` | dispatcher IR 40-55 | `weiValue ≠ 0` ⇒ `.abi .abi` |
| `header_ok_is_nonpayable` | same | header success ⇒ `weiValue = 0` |
| `beforeRoot_of_header_error` | first `beforeRoot` bind | header error is the `beforeRoot` error |
| `slotSibling_short_is_panic11` | `_verifySlot` `length-2` IR 70-97 | `length < 2` ⇒ `.panic11` |
| `slotSibling_mismatch_is_invalidSlot` | sibling compare IR 70-97 | `length ≥ 2` and load ≠ expected ⇒ `.invalidSlot` |
| `slotSibling_error_not_panic32` | model `Nat` subtraction | `.panic32` is unreachable after the length guard |
| `slotSibling_error_is_slot_class` | IR 70-97 walk | every `slotSibling` error is `isSlotSiblingClass` |
| `beforeRoot_error_is_class_or_header` | `beforeRoot` bind walk | class **or** `header (prologue context) = error e` |
| `beforeRoot_error_class_of_header_ok` | IR 56-100 | header success ⇒ `isBeforeRootClass` |
| `rootCall_error_is_allocation` | IR 101-114 overflow | `rootCall` error = `.allocation .panic41` |
| `run_error_phase` | `run` (`SszCompiledClEntry.lean:164-171`) | error is beforeRoot **or** rootCall **or** afterRoot |
| `run_rootCall_failure_is_allocation` | rootCall phase of `run` | that phase is panic 0x41 |
| `run_of_nonzero_value` | nonpayable entry | `weiValue ≠ 0` ⇒ `run` is `.abi .abi` |

## Mutants

| Kill-line | Mutant killed |
| --- | --- |
| `slot_short_kill_line` | A one-word proof tail still checks the sibling |
| `slot_short_not_panic32_kill_line` | A short tail is panic 0x32 |
| `slot_mismatch_kill_line` | A mismatched penultimate word still succeeds |
| `header_value_kill_line` | Nonzero `msg.value` still dispatches |
| `run_value_kills_success` | Nonzero value is a successful `run` |
| `rootCall_error_not_proof_kill_line` | `rootCall` overflow is a proof error |

## Hypotheses (declared, not proved here)

- EIP-4788 authenticity and freshness of the BEACON_ROOTS reply.
- Compilation of the inspected IR against the pinned Solidity source.
- Crypto (SHA-256 injectivity), gas, consensus, deployed locator identity.

## Model / IR fidelity gap

`slotSibling` IR 70-97 has a checked subtraction (panic 0x11) and a
bounds check (panic 0x32). The Lean model uses saturating `Nat`
subtraction: after `length ≥ 2`, `length - 2 < length` always holds, so
`.panic32` is unreachable. This lot states that model fact; it does
**not** prove the Solidity checked-sub cannot panic 0x32. Closing that
gap needs a checked-`Nat` (or `UInt`) transcription of `length-2`.

## Axioms

`#print axioms` of every export is only `propext` / `Classical.choice` /
`Quot.sound`, or a subset. No `sorry`, no `sorryAx`, no extra axiom.
No `keccakMemorySlice := fun _ _ _ => 0` closed by a premise.

## Open / not this lane

- Header `do`/`throw` join-points (`SszCompiledClEntry.header`, IR 40-55)
  still block constructor analysis of later dispatcher guards. The
  second disjunct of `beforeRoot_error_is_class_or_header` is that
  remainder. Honest raccord: explicit `if`/`.error`/`.ok` nest in
  `SszCompiledClEntry.lean:53-63` (same seven guards, same order).
  Outside this exclusive three-file contract; also documented on #370.
- `afterRoot` constructor class is #375, not imported here.
- `run` rollback (no committed storage/events) is #370.

## Recheck

```sh
export PATH="$HOME/.elan/bin:$PATH"
lake build LidoSRv3.Audit.Source.SszCompiledBeforeRootClass
lake build LidoSRv3.Tests.SszCompiledBeforeRootClassMutants
lake env lean LidoSRv3/Audit/Source/SszCompiledBeforeRootClass.lean
lake env lean LidoSRv3/Tests/SszCompiledBeforeRootClassMutants.lean
```
