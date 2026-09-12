# P-ADDRESS-1 / P-ALLOC-2 — lift two model bounds

## CLAIM

- **Guarantees:** `P-ADDRESS-1`, `P-ALLOC-2`
- **fidelity.missing / covered targets:**
  - ADDRESS: `unbounded source-to-Verity correspondence and caller-swap equivariance theorem for the live claimWithdrawalsTo batch; the checked observe receipt is two-item`
  - ALLOC: fuel-bounded `sourceAllocateLoop` conservation (`allocated + remaining = allocationSize`)
- **Branch:** `grok/lido-address-alloc-unbounded-20260912`
- **Base:** `origin/main` @ `1a40db36df3990da9287ac7b03b7e9a1e9bcffe4`
- **Pinned Solidity:** `17005714f151e5502c559932319a3f2f74ac2436`
- **Claimed by:** grok cloud agent, 2026-09-12
- **Status:** closed on this consumer — Spark raccord pending

This lot does **not** claim the Grok #403 singleton-actor exclusion and
does **not** edit the +1 `MinFirst` child or the known proportional/+1
spec gap. Parents, `guarantees.yaml`, and Trust are not edited.

## Targeted gaps

(i) `AddressClaimBatchTx` iterates arbitrary request/hint lists
(`WithdrawalQueue.sol:244-256`), but the checked observe receipt (packed
reads, claimed bits, locked-ETH decrement, ordered `_sendValue` CALLs)
was a two-item witness. This lot proves the receipt for every successful
list by induction: observe is the ordered map of the unit `_claim`
receipt (`WithdrawalQueueBase.sol:460-480`). The two-item parent shape
`[1, 2]` / hints `[1, 1]` / payouts `[30, 40]` is that instance. A
mutant that reorders the CALLs is refused. The concrete physical
`twoClaimState` run stays the known keccak-opaque kernel boundary.

(ii) `PAlloc2.source_allocate_loop_conserves_requested` holds only for
`sourceAllocateLoop` runs that already terminate under caller-supplied
fuel. This lot proves unconditional termination from the decreasing
remaining-capacity sum drawn from
`MinFirstAllocationStrategy.allocate` `:106`
(`buckets[bestCandidateIndex] += allocated`), then conservation with no
fuel premise. Solidity also has a real bound: `while (allocated <
allocationSize)` at `:36-41` with a strictly increasing `uint256`
`allocated` (at most `allocationSize` iterations).

## What is proved

Additive files:

- `LidoSRv3/Audit/Verity/AddressClaimBatchUnbounded.lean`
- `LidoSRv3/Audit/Spec/AllocLoopTermination.lean`
- `LidoSRv3/Tests/AddressClaimBatchUnboundedMutants.lean`
- `LidoSRv3/Tests/AllocLoopTerminationMutants.lean`

| Theorem | Source span | Claim |
|---|---|---|
| `observe_eq_map_unit` | WithdrawalQueue.sol:244-256 / Base.sol:460-480 | successful batch observe = ordered map of unit `_claim` receipts |
| `two_item_parent_instance` | same, parent shape `[1,2]/[1,1]/[30,40]` | two-item parent is that instance; CALL order `(30, 40)` |
| `reordered_calls_refute_two_item` | Base.sol:477 | reversed CALL journal ≠ honest map |
| `sourceAllocateLoop_terminates` | MinFirstAllocationStrategy.sol:30-44, :106 | residue-fuel run is always `some` |
| `source_allocate_conserves_without_fuel` | same | allocated + remaining = request; no fuel premise |
| `fuel_exhaustion_zero_remainder_mutant_refutes_conservation` | mutant fuel=0 leftover 0 | honest conservation is not a renamed fuel |

Axioms of every export (`#print axioms`): `propext` / `Quot.sound` /
`Classical.choice` only (or a subset). No `sorryAx`.

## Verification

- **cwd:** `/workspace`
- **base SHA:** `1a40db36df3990da9287ac7b03b7e9a1e9bcffe4` (`origin/main`)
- **toolchain:** `leanprover/lean4:v4.31.0` (`68218e876d2a38b1985b8590fff244a83c321783`)
- **targets:** `lake build LidoSRv3.Audit.Verity.AddressClaimBatchUnbounded`
  `LidoSRv3.Audit.Spec.AllocLoopTermination`, both mutant modules, and
  `lake build LidoSRv3Test` succeeded. `#print axioms` as above.

## Spark raccord (do not apply in this lot)

In `audit/guarantees.yaml`:

1. Under `P-ADDRESS-1` `fidelity.missing`, replace the two-item observe
   bullet with a `fidelity.covered` note that `observe_eq_map_unit` is
   the inductive receipt and `two_item_parent_instance` is the former
   two-item witness. Caller-swap equivariance of that live batch, keccak
   injectivity, EnumerableSet/events, and adversarial callee semantics
   stay missing.
2. Under `P-ALLOC-2` `fidelity.covered`, replace "fuel-bounded
   sourceAllocateLoop conservation" with residue-measure termination plus
   conservation without a fuel premise. Keep the +1 child separate.

## Honesty (not this entry)

- Live `AddressClaimBatchTx.claimOne` does not journal CALLs; the unit
  receipt records the `_sendValue` frame from the returned payout.
- The concrete physical `twoClaimState` finite run is the known
  kernel-opaque keccak boundary: `decide +kernel` does not reduce
  `mappingSlotLocation`, and `native_decide` needs evmyul FFI. This lot
  does not replace that path with a `mapUint` surrogate.
- `PhysicalClaimSlots` / keccak injectivity and later-write independence
  of claimed bits stay open.
- `sourceAllocateLoop_terminates` needs `rows.length < 2^256` (an EVM
  array bound) and uses `residueFuel = remainingCapacitySum + 1`.
- Arithmetic failure of the copied Lean loop is shown not to arise on
  that measure; generated Yul and bytecode remain out of scope.
