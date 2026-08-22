# Pack N1 — ALLOC to executed amounts

One node, one PR. This is a finish, not a leftover naming pack.
ALLOC ↛ LinksSource is already proved
(`Spec.AllocationCorrespondence.spec_amounts_do_not_imply_linkssource`);
this pack does not re-document it. ALLOC is not merged into DEPOSIT. No
declarations were added to `PDeposit1.lean` or `PTopup1.lean`. No pin is
invented that discharges `A-DEPOSIT-32-ETHER`.

## Design (this attempt: bridge, positive equality)

A composition parent is provided whose named conclusion is the equality

    executed deposit wei = Spec.Allocation.amount * depositSize

where `depositSize` is the existing configuration field
(`SourceDepositConfig.depositSize` / `Inputs.depositSize`), not a claimed
32-ether deployment fact.

The bridge `Spec.AllocExecCorrespondence.ExecutesAllocation` replaces the
`firstAmount` / `secondAmount` conjuncts of `PDeposit1.LinksSource`: it
carries, per batch leg, (a) allocation amount = batch key count and (b)
batch wei = allocation amount * `Inputs.depositSize` — the unit multiply
that validator counts alone do not provide. Under that bridge plus the
already-proved key-count partition, both wei conjuncts — and hence all of
`LinksSource` — are proved, not assumed. The registered conclusion is the
equality, not "ALLOC ↛ LinksSource".

## Parent (universal, every binder used)

`LidoSRv3.Audit.Guarantees.PAllocExec1.allocated_amount_times_deposit_size`
(unregistered until the integrator writes the supplemental YAML row).

For all source deposit configs `cfg`, call inputs `inp`, executable
transaction inputs, and Spec allocations `(first, second)` with
`ExecutesAllocation`, `inputs.depositSize.val = cfg.depositSize`, the
key-count partition
`inputs.first.keys.val + inputs.second.keys.val = actualDepositsCount`,
and the no-wrap bound, the conclusion is:

- `inputs.first.amount.val = first.amount.value * cfg.depositSize`
  and the same for the second leg;
- `(totalAmount inputs).val
     = (first.amount.value + second.amount.value) * cfg.depositSize`;
- `pushedValue cfg inp
     = (first.amount.value + second.amount.value) * cfg.depositSize`
  (through `loopPushed_eq` and the partition — not definitional);
- `PDeposit1.LinksSource cfg inp inputs` (the bridge consequence);
- on every committed run of the pinned source model, the wei pulled from
  Lido and pushed to the beacon deposit contract both equal
  `(first.amount.value + second.amount.value) * cfg.depositSize`
  (through the line 996 assert gate, `committed_deposits_spec`).

Non-vacuity: `canonical_allocation_composition_witness` discharges every
premise at once on the canonical five-key deployment, where the source
model commits `5` keys / `160` wei and `160 = (2 + 3) * 32`.

## Kill-line

`LidoSRv3.Tests.PackN1AllocExecMutants.raw_count_as_wei_kill_line`: one
model mutant (`mutantAllocationWei`) drops the `* depositSize`, reading the
raw validator count as wei (written `* 1` to make the dropped factor
explicit). The kill-line is parent-shaped — it negates the exact
universally quantified equality with every premise retained. Witness: the
canonical deployment, where the honest equality holds (`160 = 5 * 32`) and
the mutant fails (`160 ≠ 5`); `honest_equality_holds_where_mutant_fails`
records both at the witness. The existing 2-key / 65-wei skew
(`skewed_wei_falsifies_bridge`) shows the bridge's wei half is falsifiable:
keys `2`/`3` with wei `65`/`95` satisfy the key-count half but refute the
unit multiply (`65 ≠ 2 * 32`), so the bridge cannot be weakened back to
validator counts alone.

## Frozen interfaces

Only `Spec.Allocation` is mentioned across guarantees. Amount is validator
counts. Wei is `amount * depositSize`.

## Files

- `LidoSRv3/Audit/Spec/AllocExecCorrespondence.lean` — `allocationWei`,
  `ExecutesAllocation`, `allocationWei_add` (new).
- `LidoSRv3/Audit/Guarantees/PAllocExec1.lean` — the parent, canonical
  bridge witness, non-vacuity witness (new).
- `LidoSRv3/Tests/PackN1AllocExecMutants.lean` — kill-line, witness
  vectors (new).
- `audit/PACK-N1-ALLOC-EXEC-BRIEF.md` — this brief.

Untouched: `LidoSRv3.lean`, `Trust.lean`, `audit/validation-receipt.txt`,
`audit/guarantees.yaml`, `audit/assumptions.yaml`, `Registry.lean`,
`AllGuarantees.lean`, `PDeposit1.lean`, `PTopup1.lean`.

## Quality

`lake build` of the new modules passes on toolchain
`leanprover/lean4:v4.31.0`. No `sorry` / `admit` / `native_decide` on the
parent. Branch `cursor/n1-alloc-exec-fable-f120` from `origin/main` at
`93711f7`. Commit, push, stop. Integrator registers the supplemental ID and
Trust prints.
