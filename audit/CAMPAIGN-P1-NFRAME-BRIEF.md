# Campaign product 1 — n-frame deposit

One node, one PR. Product claim (first line), not the leftover two-batch
honesty restatement. Real fork: lift `DepositParentTx` to `List Batch`,
or keep two-batch and make conjunct (d) the named n=2 case. Isolated
Best-of-2/3 uses this same brief.

Do not reopen `P-ALLOC-EXEC-1` except to discharge a named OPEN it
already lists (the n-frame lift is listed as missing there). Prefer
discharging that OPEN by generalizing `routerDepositInputs`, or leave
`P-ALLOC-EXEC-1` as the two-batch lemma and put the n-frame parent on
`P-DEPOSIT-1`. Keep `A-DEPOSIT-32-ETHER` named until an artifact
identity. Do not invent a 32-ether pin.

## What the parent must say

Universal over a finite `List Batch` (or, if keeping two-batch, a
parent-shaped statement that conjunct (d) *is* the n=2 case).

If lifting:

`Inputs.batches : List Batch` replaces `first` / `second`.

∀ cfg, inp, inputs, entry, with `LinksSource` (generalized) and
`Preconditions` (every batch healthy, pairwise distinct module ids,
fold-stable no-wrap):

1. **Inductive journal.** `execute` is
   `batches.mapM (processBatch inputs)` then one `pullFromLido` of the
   folded total then `batches.mapM (pushBatch inputs)`. The observed
   journal is
   `batches.map (moduleEntry inputs) ++ [pullEntry inputs] ++
    batches.map (pushEntry inputs)`.
2. **Fold-stable no-wrap.** The folded beacon wei equals
   `batches.foldl (· + ·.amount) 0` and stays `< 2^256` under the
   no-wrap premise. A wrapping fold does not commit a value-moving
   journal.
3. **Arity-n.** Exactly `batches.length` module probes and exactly
   `batches.length` `depositToBeacon` legs, independent of per-batch
   key counts. The n=2 specialization recovers today’s conjunct (d).
4. **Router.** `routerDepositInputs` generalizes to
   `List Spec.Allocation` and yields `LinksSource`, *or* conjunct (d)
   of the registered `P-DEPOSIT-1` parent is proved as the n=2 case
   of this parent.

If keeping two-batch: the registered YAML theorem must be a ∀ parent
whose named conclusion is “conjunct (d) is the n=2 case of an n-frame
journal,” with a parent-shaped kill-line. That is an honest stop, not
a leftover restatement of two-batch honesty.

## Kill-line

Parent-shaped, premises retained, non-vacuous witness.

- Lift: a fixed-arity-2 mutant `executeTwoOnly` (or a fold that drops
  the tail) on a 3-batch witness fails the inductive journal / arity-n
  conjunct.
- Keep two-batch: a mutant that claims the executable journal is
  n-frame (or hides conjunct (d)) fails the named n=2 conclusion.

No `sorry` / `admit` / `native_decide` on the parent.

## Non-goals

- Do not discharge `A-DEPOSIT-32-ETHER` without an in-repo artifact
  identity.
- Do not merge ALLOC into DEPOSIT. ALLOC ↛ `LinksSource` without the
  unit multiply stays.
- Do not reopen `P-ALLOC-EXEC-1` to restate `router_produces_executes_allocation`.
- Do not edit `PAccount1.lean`. Do not add VaultHub constructors.

## Files

Own: `DepositParentTx.lean` (or a new `DepositNFrameTx.lean` that the
YAML theorem cites), `PDeposit1.lean` only if the registered Verity
theorem changes, `AllocExecCorrespondence.lean` only if
`routerDepositInputs` generalizes, new Spec correspondence, new
mutants, this brief, `guarantees.yaml` / `AllGuarantees` / `Registry` /
`LidoSRv3.lean` / `Makefile` / `check_public_claim_surfaces.py` as
required by a declaration or YAML change.

`P-DEPOSIT-1` is a public-claim surface. If you add or rename a
declaration on `PDeposit1.lean`, update
`scripts/check_public_claim_surfaces.py` in the same PR.

## Build

    lake build LidoSRv3.Audit.Guarantees.PDeposit1
    lake build LidoSRv3.Audit.Verity.DepositParentTx
    lake build LidoSRv3.Tests.DepositParentTxMutants
    # plus any new n-frame module / mutants
    python3 scripts/check_public_claim_surfaces.py
    python3 scripts/audit_metadata.py check

## Quality gate

YAML theorem is the new parent or the named n=2 discharge. Kill-line
builds and is parent-shaped. `lake build` of the listed targets. Verity
quantifier matches or is disclosed like today’s conjunct (d). English
claim does not hide a two-batch gap behind an n-frame title.
