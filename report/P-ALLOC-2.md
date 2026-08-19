# P-ALLOC-2

Theorems: `PAlloc2.proportional_step_correspondence_and_bounded` (parent), `PAlloc2.selects_least_open_bucket` (child), `PAlloc2.verity_tx_simulates_min_first_distribution`, `Tests.MinFirstDistributionTxMutants.selection_kill_line_refutes_parent` (selection kill-line).
Assumptions: `A-HANDWRITTEN-MINFIRST`, `A-VERITY-SCAFFOLD`. Related (not listed on the YAML row): `A-ALLOC2-TX-BOUNDARY`.

## Intent

Inside a Lido SRv3 staking module, deposits / keys are spread across node-operator “buckets” by `MinFirstAllocationStrategy.allocate` (`lidofinance/core@af095e48`, `contracts/common/lib/MinFirstAllocationStrategy.sol`), after `StakingRouter.getDepositAllocations` has turned share-limit capacities into ETH. The library repeatedly picks a least-filled bucket that still has free space, then gives it a proportional slice of remaining demand (`ceil(remaining / equal-minimum-count)`, capped by the next fill level and by residual capacity). The point is fairness: an operator with more unused room is filled before a fuller one, and ties keep router / array order.

The guarantee is meant to say the selected bucket is a least-filled open bucket, and that a Verity `Contract.run` of the whole allocate loop matches that source loop.

## Modeling

- `A-HANDWRITTEN-MINFIRST`: the `Nat` model is handwritten. The assumption’s own risk line is that Solidity / EVM equivalence is *not* established. The YAML still marks Verity CHECKED.
- `A-VERITY-SCAFFOLD`: non-certified interpreter.
- `A-ALLOC2-TX-BOUNDARY` (amount-slice only): `MinFirstAmountTx` does *not* scan the arrays. Candidate index, `bestCandidatesCount`, and `allocationSizeUpperBound` are source-plane words. The CHECKED parent cites `MinFirstDistributionTx` instead, which does recompute those on lists — but those lists are already decoded `uint256` words, not the Solidity in-memory arrays the library mutates in place.
- Two coexisting models: `Audit.MinFirst` (`Strategy.lean`) increments the winner by **1 validator per iteration**; `MinFirstAllocation.Model.amount` implements the **proportional** `ceilDiv` / next-level / capacity cap of source lines 92–105. The facade’s abstract theorem uses the +1 model; the Verity theorem uses the proportional model.
- `replaceFirst` matches the whole `Row` structurally. Solidity mutates `buckets[bestCandidateIndex]`. Duplicate (allocation, capacity) pairs can make Lean update a different index than source.
- Memory layout is a toy `memoryFor` (`bucketsBase = 0x1000`). Not ABI / Solidity memory.

## Proof

**Abstract `proportional_step_correspondence_and_bounded` (parent).** The registered parent is the pinned-source *proportional* step, not the +1 model. Its first conjunct pins the selection, not merely the two scans to each other: given `RowsCorrespond` and `hSelected : Source.candidate? source = some best`, the Model scan's candidate maps to exactly `some (best.allocation.val, best.capacity.val)` — proved by rewriting `full_candidate_correspondence hRows` with `hSelected`, so the selection hypothesis is load-bearing (wave 4; it was an unused `_hSelected` before). The second conjunct is `source_amount_totality` (a successful checked amount is positive, ≤ the remaining demand, and keeps the candidate within capacity, i.e. never over headroom). Two kill-lines in `MinFirstDistributionTxMutants.lean` refute the parent on its own model: `selection_kill_line_refutes_parent` is the negation of the parent's FULL predicate shape — all six premises (`RowsCorrespond`, `hSelected`, `hOpen`, `hLen`, `hSize`, `hAmount`) retained and the whole conclusion conjunction negated — with a mutant Model-side scan `mutantFirstOpenCandidate?` (first open bucket wins) in place of `Model.candidate?`. The witness discharges every premise on concrete data: on the `RowsCorrespond` pair `[(5, 10), (0, 10)]`, `Source.candidate?` selects the NON-first row `⟨0, 10⟩` (index 1), the row is open, the demand `10` is nonzero, and `Source.checkedAmount` succeeds with `some 5`; yet the mutant scan maps to `some (5, 10)`, falsifying the pinned-selection conjunct. And the aligned `checkedAmountNoCapacityCap` mutant skips the final capacity-headroom clamp and produces an amount that pushes a candidate past its capacity, refuting the headroom conjunct.

**Child `selects_least_open_bucket`.** The previous parent is demoted to a child of the +1 model. Induction on the bucket list following the recursive definition of `MinFirst.candidate?` (scan from the right; on `allocation ≤ later.allocation` keep the left open bucket). Side lemmas: the candidate is a member, is open, and a `none` result means no open bucket. The `≤` conclusion is exactly the selection rule.

**Amount / SOURCE slice.** `source_amount_correspondence` is a calculation: if checked `uint256` arithmetic succeeds and `source.length < 2^256`, the Nat amount equals the word. `source_pinned_expression_shape` shows the audit’s distributed-`min` form equals the source’s “subtract once after `Math256.min`” form, by case split on the `min` arms, for any open best candidate.

**VERITY `verity_tx_simulates_min_first_distribution`.** `sourceDistribute` and `txDistribute` (`MinFirstDistributionTx.lean:60–92`) are the same recursion; `txDistribute_eq_sourceDistribute` is induction + `simp`. `allocate` decodes two memory arrays, zips them into `Source.Row`s, runs `txDistribute`, writes the new bucket words. `observe` on success reports those words; on revert it reports the caller-supplied preimage, not storage. Rollback is `Contract.run`.

## Issues

## Resolution

**Restated Lean/English.** `selects_least_open_bucket` names `rows`/`selected`/`other` and is the +1 model only. Verity is `allocateToBestCandidate` observe = sourceView.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1 | A | `A-HANDWRITTEN-MINFIRST` kept; Solidity `active` test in `missing`. |
| 2, 4, 13 | A | Two algorithms kept separate (`+1` vs proportional `replaceFirst`). |
| 3 | A | `txDistribute = sourceDistribute` by lockstep. |
| 5 | A | `A-ALLOC2-TX-BOUNDARY` stays on the amount-slice child. |
| 6 | scope | Dummy memory oracle in `missing`. |
| 7 | A | `observe` reads result buckets; persistence not claimed. |
| 8, 9, 10, 11, 14, 17 | A | Honest statements of selection, revert, Nat vs `safeAdd`. |
| 12 | C | Zero `checkedAmount` now returns the prefix (`break`) on SOURCE and TX. |
| 15, 16, 18 | A | Toy-memory / `ofNat` / pad documented in `missing`. |


1. **YAML marks a handwritten model “CHECKED” against an assumption that denies Solidity equivalence.**
   `A-HANDWRITTEN-MINFIRST` is accepted and says the model “lacks established Solidity and EVM equivalence.” The CHECKED Verity status is therefore a classification of a *scaffold of that model*, not of `MinFirstAllocationStrategy.sol`.

   *Scenario.* `MinFirst.Bucket.open` is `active ∧ allocation < capacity`. Solidity `allocateToBestCandidate` (lines 76–78) only tests `buckets[i] < capacities[i]`. Inactive modules are filtered *upstream* by SRLib leaving `capacity = current allocation`. Feed Lean a row `{active := false, allocation := 0, capacity := 10}`: `candidate?` skips it. The same two arrays in the Solidity library would fill it. `RowsCorrespond` papers over the gap only when someone already aligned the flags.

2. **Abstract and Verity theorems are about different algorithms.**
   `selects_least_open_bucket` is `MinFirst.candidate_minimal` on the +1-per-step `Strategy.lean` buckets (`Bucket.open = active ∧ allocation < capacity`). `verity_tx_simulates_min_first_distribution` runs `Source.checkedAmount` (proportional share). Scenario: buckets `[0, 0]`, capacities `[100, 100]`, `allocationSize = 10`.
   - +1 model with fuel 10: ten unit steps, ends `[5, 5]` (or `[6, 4]` depending on tie-break walk).
   - Proportional model: first step sees two minima, `ceil(10/2) = 5`, next-level unbounded, allocates 5 to index 0; second step allocates 5 to index 1; done.
   The two closures can both be “CHECKED” while describing different traces. The parent does not identify them.

3. **`txDistribute` is not an independent executable.**
   Comment at `MinFirstDistributionTx.lean:76–78` claims the correspondence theorem, “not a shared definition,” is the boundary. The two functions are copies; the theorem is `simp [txDistribute, sourceDistribute, ih]`.

   *Counterexample to independence.* Introduce an off-by-one in `Source.candidate?` (skip index 0). Both sides change; `txDistribute_eq_sourceDistribute` still holds. The CHECKED equality cannot see a shared scan bug.

4. **`replaceFirst` vs index mutation — concrete mismatch.**
   Rows `[(3,10), (3,10)]`, demand 1. `candidate?` walks from the right, both open with allocation 3; `≤` keeps the *left* row as the structural value `(3,10)`. `replaceFirst` updates the **first** structurally-equal row, which happens to be index 0 — lucky here. Solidity always writes `buckets[bestCandidateIndex]`. Duplicate fill levels (the common “many empty operators” case the library’s own comment describes) make the Lean mutation key-ambiguous.

   *Scenario that flips the write.* Three identical open rows `(0, 10)`. After the first proportional chunk the first row is `(k, 10)` and the others remain `(0, 10)`. Next `candidate?` returns a structural `(0, 10)`. `replaceFirst` writes the *first remaining* `(0, 10)` (index 1). If a later refactor returned the rightmost minimum as the same structure, `replaceFirst` would still write index 1, not the rightmost index. Solidity would write the scanned index.

5. **The amount-slice TX can be fed a lying share (A-ALLOC2-TX-BOUNDARY).**
   `MinFirstAmountTx.allocateToBestCandidate share upperBound` does not recompute `bestCandidatesCount` or the next-level bound. Those are arguments.

   *Counterexample.* Rows `[0, 0]`, caps `[100, 100]`, size `5`. Real share is `ceilDiv(5, 2) = 3`. Feeding `share = 5` allocates 5 to the first bucket in one step. `tx_step_matches_source` still holds *of that lie*, because it assumes `sourceShare` / `upperBound` of the real `candidate?` only when the caller passes them. The assumption is not on the YAML row.

6. **Array denotation uses a dummy oracle (`mappingSlot := fun _ _ => 0`).**
   `MinFirstDistributionTx.oracle` (`:31–33`) hashes nothing. `memoryFor` plants words at `0x1000` / `0x2000`. Real ABI `uint256[]` lives at a calldata/memory offset the compiler chooses.

   *Scenario.* A Verity denotation that actually hashed mapping slots would read different words than `memoryFor`. The premises `hBuckets` / `hCapacities` just assume `readArray` already returned the lists. The CHECKED tx is “given these lists in this toy memory, run the Lean loop.”

7. **`observe` reports `result.buckets`, not the written map.**
   `MinFirstDistributionTx.observe` (`:142–146`) takes allocations from the `Result` value built from `afterRows`. Only `allocated` / `remaining` are `readSlot`. `writeBucketsState` is not in the View.

   *Counterexample mutant.* Make `writeBucketsState` a no-op. `verity_tx_simulates_min_first_distribution` still holds. YAML “persists observables through writeMapUint” is not what `observe` checks for the bucket column. Solidity’s observable is the mutated memory array the caller still holds.

8. **`Source.Execute` always admits revert, and `mutate` assumes conservation.**
   `MinFirstAllocation.lean:184–203`: `| revert (i) : Execute i (.reverted i.buckets)` has no premises — every input has a revert execution. `| mutate` takes `hMutation` and `hBounds` as constructor hypotheses (the caller must already know the sum and capacity facts). The CHECKED Verity path uses `sourceDistribute` (a function), but the SOURCE relation in the same module is not that function.

   *Scenario.* `Execute i (.reverted i.buckets)` holds for a well-formed successful allocation. A theorem that only assumes `Execute i result` cannot conclude success. `success_conservation` is inversion of `mutate`’s own hypothesis, not a proof that `replaceFirst` conserves. The CHECKED parent does not use `Execute`, but the SOURCE plane advertised next to it is not deterministic library semantics.

9. **Selection theorem does not mention capacities of *other* buckets except via `open`.**
   `selected.allocation ≤ other.allocation` for every other *open* bucket.

   *Scenario.* Closed bucket `{allocation := 0, capacity := 0}` and open `{allocation := 5, capacity := 10}`. The theorem says nothing about the closed one (correct for selection) and nothing about the *amount* given to the open one (that is the other model). The CHECKED parent presents both as one closure.

10. **`observe` on revert reports the caller-supplied preimage, not a decode of leftover memory.**
    `MinFirstDistributionTx.observe` on `.revert` returns the `before` lists the harness passed in, not `readArray` of the rolled-back state.

    *Scenario.* `failAfterWrites = true` after `writeBucketsState`. `Contract.run` restores the snapshot (monad). `observe` still needs the caller to hand it the original buckets; a different preimage would make the View lie about what storage held. The CHECKED revert conjunct is “the function returned `.reverted` and we echoed our own input,” not “memory equals the pre-call arrays.”

11. **Abstract `Model.amount` is unbounded `Nat`; the CHECKED Verity loop uses `safeAdd` and is a different overflow story.**
    `MinFirstAllocation.Model.amount` (`:55–60`) is `Nat` `ceilDiv` / `+`. `selects_least_open_bucket` never mentions overflow. `sourceDistribute` / `txDistribute` (`MinFirstDistributionTx.lean:68–72`) do `safeAdd best.allocation amount` and treat `none` as `MIN_FIRST_ARITHMETIC`.

    *Scenario.* Best bucket allocation `2^256 − 1`, `amount = 1`, still `allocation < capacity` (capacity also max). Abstract +1 / Nat proportional step produces `2^256`. Verity `safeAdd` reverts the whole `allocate`. Solidity 0.8 `buckets[i] += allocated` also reverts. The two CHECKED theorems disagree with each other on this input: the selection theorem still names that bucket as least-open; the Verity theorem does not commit. Issue 2’s “two algorithms” includes overflow, not just the +1 vs proportional split.

12. **A zero `checkedAmount` aborts the Verity tx; Solidity `allocate` returns the prefix.**
    Lean `sourceDistribute` (`:69`): `if amount = 0 then none`. Solidity `allocate` (`MinFirstAllocationStrategy.sol:36–40`): `if (allocatedToBestCandidate == 0) break;` then `return (allocated, buckets)` — success with whatever was already added.

    *Scenario.* A candidate exists and `checkedAmount` returns `0` (e.g. a shared transcription of `ceilDiv` / `min` that collapsed). Live library stops and returns the partial fill. Lean `allocate` reverts `MIN_FIRST_ARITHMETIC` and `observe` reports the caller-supplied preimage (issue 10). The CHECKED correspondence is not the library’s “zero means done” loop. With the current `checkedAmount`, that zero may be a dead arm; the control-flow mismatch is still in the executed program.

13. **The +1 model updates by `moduleId`; Verity `replaceFirst` is structural.**
    `MinFirst.incrementSelected` (`Strategy.lean:33–36`) increments the bucket whose `moduleId` equals the selected one. `Source.replaceFirst` (`MinFirstAllocation.lean:158–162`) writes the first row with equal `(allocation, capacity)` words. `selects_least_open_bucket` is about the +1 model; `verity_tx_simulates_min_first_distribution` uses `replaceFirst`.

    *Counterexample.* Rows `(id=1, alloc=0, cap=10)` and `(id=2, alloc=0, cap=10)`. Candidate walk from the right keeps the left on `≤`, so both models want id 1. After a first proportional chunk, suppose a later step’s `candidate?` returns a structural `(0, 10)` that is *meant* to be id 2 (right-hand scan in Solidity). `replaceFirst` still writes the first remaining `(0, 10)` (id 1 if it was reset, or id 2 if id 1 was raised). The +1 model would increment `moduleId` of the selected bucket and cannot hit the wrong id. The two CHECKED theorems can name different winners on the same duplicate-fill list (issue 4 plus a different key). Solidity writes `buckets[bestCandidateIndex]`.

14. **Lean never mutates the decoded memory array; a second `allocate` re-reads the original words.**
    Solidity `allocate` writes `buckets[best] += allocated` in place (`MinFirstAllocationStrategy.sol:106`) and the `while` loop sees the new fills. Lean decodes toy memory at `0x1000`, then `writeBucketsState` into `bucketsSlot = 20`. Memory is unchanged. A second `allocate` on the same `ContractState` re-reads `[0, 0]`.

    *Counterexample.* `buckets = [0, 0]`, `capacities = [100, 100]`, size `5`. First call: both sides `[3, 2]`. Second call on the same arrays: Solidity continues from `[3, 2]` → `[6, 4]`. Lean still sees memory `[0, 0]` → `[3, 2]` again. Tests hide this by rebuilding `stateFor` from the first result. The CHECKED theorem is one-shot; sequential min-first — the real `while` observable — is not the Verity state.

15. **Toy memory aliases at 128 words.**
    `memoryFor` plants buckets at `0x1000` and capacities at `0x2000` (`MinFirstDistributionTx.lean:46–53`). For length `≥ 129`, `0x1000 + 32·128 = 0x2000`. The first `if` wins, so `capacities[0]` reads as `buckets[128]`.

    *Counterexample.* 129 buckets, last bucket `99`, first capacity `50`. `readArray "capacities"` returns a list whose head is `99`. Premises `hCapacities` of the CHECKED theorem become unsatisfiable, or a raw `allocate 129 129` distributes against the wrong caps. Real ABI `uint256[]` pairs do not alias this way. The CHECKED decoder is false for any batch the library could actually see above 128.

16. **`countBest` is `Nat`; `ofNat count` wraps; the parent has no `length < 2^256` hypothesis.**
    `checkedAmount` (`MinFirstAllocation.lean:167–169`) does `ceilDiv allocationSize (Uint256.ofNat count)` when `1 < count`. Amount-slice lemmas require `source.length < 2^256`. `verity_tx_simulates_min_first_distribution` does not.

    *Counterexample.* `count = 2^256` equal open rows (legal `Nat`). `ofNat (2^256) = 0`. `ceilDiv(size, 0)` is not Solidity `ceilDiv(size, bestCandidatesCount)` (which would have panicked on `+= 1` long before). The CHECKED loop uses a wrapping encoding the amount correspondence already knew was unsafe, then drops the only premise that rules it out.

17. **`MinFirstCorrespondence.candidate?` is a third copy of the same walk; `RowsCorrespond` erases `active`.**
    `MinFirstCorrespondence.lean:33–40` is the same right-fold as `MinFirst.candidate?` and `Source.candidate?`. `RowsCorrespond` (`:45–46`) requires `hasFreeSpace b = b.open`, i.e. `allocation < capacity` iff `active ∧ allocation < capacity`. So every corresponding row with free space must have `active = true`.

    *Scenario.* Inactive row `{active := false, allocation := 0, capacity := 10}` (issue 1). `RowsCorrespond` is false, so `candidate?_eq_minFirst_candidate?` does not apply. The SOURCE selection lemma only talks about rows that already agree with the +1 model’s `open` flag. Combined with issue 3 (`txDistribute` copy), there are three identical walks and a correspondence that assumes away the `active` discrepancy. The CHECKED selection theorem is `MinFirst.candidate_minimal` on the +1 model, not this third copy.

18. **Decode length is `bucketCount`; short planted memory pads with 0.**
    `allocate` (`MinFirstDistributionTx.lean:116–122`) reads `bucketCount` / `capacityCount` words. `memoryFor` returns 0 outside the planted range (issue 15 aliases at 129). Live `uint256[]` length is the ABI length.

    *Scenario.* `bucketCount = capacityCount = 3`, planted buckets `[0, 0]`, capacities `[10, 10]`. `readArray` returns buckets `[0, 0, 0]` and capacities `[10, 10, 0]`. Third row is closed (`0 < 0` is false). Lean distributes over two open rows plus a dummy. Live a length-2 pair cannot grow a third bucket. Combined with issue 14 (memory never updated), the CHECKED decoder can invent a zero-capacity bucket instead of `ARRAY_LENGTH_MISMATCH`.

## Wave 4 changes (2026-08-19): P-ALLOC-2 decorative-hypothesis / sibling kill-line remediation

**Defect (P-ALLOC-2).** The registered parent
`proportional_step_correspondence_and_bounded` declared
`_hSelected : Source.candidate? source = some best` but never used it: the
proof was `⟨full_candidate_correspondence hRows, source_amount_totality hOpen hLen hSize hAmount⟩`,
so the premise was decorative and the conclusion's first conjunct only
related the two scans to *each other*, never to the selected row.
Compounding this, the "selection kill-line" in
`Tests/MinFirstDistributionTxMutants.lean` proved
`firstOpenCandidate? rows ≠ Source.candidate? rows` — a disagreement between
two Source-side scans with no `Model`, no `RowsCorrespond`, and no negation
of the parent's correspondence equality — so it refuted a sibling predicate,
not the parent. Only the `checkedAmountNoCapacityCap` headroom kill-line
actually refuted a parent conjunct, and the YAML/report text overclaimed
that the kill-lines "witness both conjuncts".

**Fix: pinned the first conjunct to the selected row (load-bearing
`hSelected`).** The parent's first conjunct is now
`Option.map (fun b => (b.allocation, b.capacity)) (Model.candidate? model) =
  some (best.allocation.val, best.capacity.val)`,
proved by rewriting `full_candidate_correspondence hRows` with
`hSelected : Source.candidate? source = some best`. The hypothesis is
therefore load-bearing: dropping or vacating it breaks the proof. The
amount conjuncts (`0 < w.val ∧ w.val ≤ allocationSize.val ∧
best.allocation.val + w.val ≤ best.capacity.val`) are unchanged, as are the
theorem name, the remaining hypotheses, and every other declaration in the
file.

**New kill-line: `selection_kill_line_refutes_parent`.** A mutant Model-side
candidate scan `mutantFirstOpenCandidate?` (first open bucket wins, mirroring
the old Source-side `firstOpenCandidate?` it replaces) is refuted on the
parent's own model. The theorem is the negation of the parent's FULL
predicate shape — `¬ ∀ {model source best allocationSize w}, RowsCorrespond →
hSelected → hOpen → hLen → hSize → hAmount → (C1' ∧ C2 ∧ C3 ∧ C4)` with
`mutantFirstOpenCandidate?` in place of `Model.candidate?` in C1' — not
merely a projection: the witness instantiates all five binders and discharges
all six premises on concrete data (the `RowsCorrespond` pair
`[(5, 10), (0, 10)]`; `Source.candidate?` selects the NON-first row
`⟨w 0, w 10⟩`, index 1, the strictly least allocation; the row is open;
`2 < 2^256`; demand `w 10` nonzero; `Source.checkedAmount` succeeds with
`some (w 5)`), then contradicts the pinned-selection conjunct, which the
mutant maps to `some (5, 10)`. The old Source-side disagreement
example is removed (subsumed); the aligned
`checkedAmountNoCapacityCap` headroom kill-line is unchanged.

**Metadata/report realignment.** `audit/guarantees.yaml`'s `P-ALLOC-2` row:
`summary`, `fidelity.covered`, and `reproduction.expected` now describe the
threaded-`hSelected` parent and name `selection_kill_line_refutes_parent`;
`fidelity.missing`, `classification`, `assumptions`, and both registered
theorem names are unchanged. `scripts/audit_metadata.py`'s
`EXPECTED_CANONICAL_DETAIL_SHA256["P-ALLOC-2"]` is recomputed to match
(`e896bd71…24cf6f760`), and `audit/REPRODUCE.md` is regenerated
(`STATUS.md`/`ROADMAP.md` are byte-identical). No `sorry`/`admit`, no new
axioms (`#print axioms` still reports only `[propext, Quot.sound]`).
