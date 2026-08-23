# Campaign product 4 — keccak / unbounded claim batch

One node, one PR. Product claim (first line). Fuel-bounded payout and
recipient rename are already done on `P-ADDRESS-BATCH-1`. Reopen that
ID only to discharge a named OPEN it already lists (keccak physical
slot maps; unbounded live-loop correspondence).

Do not weaken `PAddress1.universal_address_writer_equivariance`.

## What the parent must say

Either:

**A. Inhabit physical slots.** ∀ request id / hint / recipient on the
live `executeClaimWithdrawalsTo` path, the keyed `mapUint` channels at
`queuePosition` / `queuePosition+1` and `checkpointsPosition` /
`checkpointsPosition+1` are the keccak mapping slots
`keccak256(abi.encode(key, POSITION))` and the next word, not merely
the unstructured-storage constants plus a channel offset. The parent
names the keccak derivation and a correspondence to those physical
slots.

Or:

**B. Keep keccak OPEN** as a named hyp / `fidelity.missing` line, and
do not claim machine-storage refinement.

AND, independently, unbounded rename only with a kill-line:

**C. Unbounded rename.** ∀ request/hint lists (no fuel bound),
`ρ · executeClaimWithdrawalsTo = execute · ρ` on journal dests, with
a parent-shaped kill-line. Fuel-bounded rename stays a lemma.

If C cannot be proved without fuel, keep unbounded OPEN. Do not
restate the fuel-bounded rename as the new parent.

Default product is A and/or C. B alone is an honest stop only if A
cannot inhabit slots; it is not a leftover restatement of “keccak
stays OPEN” unless the YAML theorem is a real hyp discharge.

## Kill-line

- A: mutant that reads `queuePosition` as a raw key (no keccak) or
  that aliases `POSITION+1` to a different map fails the physical-slot
  conjunct.
- C: fixed-dest mutant on an arbitrary-length well-formed batch (not
  a 2/3-item numeral) fails the unbounded rename.
- B-only: do not invent a kill-line that restates the fuel-bounded
  parent.

## Non-goals

- Do not weaken the four-projection `P-ADDRESS-1` parent.
- Do not treat numeral 2/3-item receipts as unbounded.
- Node 7 (pause/bunker) is not required.

## Files

Own: `AddressClaimBatchTx.lean` / new keccak-slot module,
`AddressClaimFuelCorrespondence.lean` or a new unbounded module,
`PAddressBatch1.lean` only for the discharged OPEN, mutants, this
brief, YAML missing/next_gate.

## Build

    lake build LidoSRv3.Audit.Guarantees.PAddressBatch1
    lake build LidoSRv3.Tests.PackN4AddressBatchMutants
    # plus new keccak / unbounded modules

## Quality gate

YAML theorem is the physical-slot parent, the unbounded-rename
parent, or a named keccak-OPEN hyp discharge. Kill-line builds for
any ∀ that is not an OPEN. `lake build`.
