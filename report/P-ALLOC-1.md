# P-ALLOC-1

> Auditor proof note (2026-08-21). I treat
> `LidoSRv3/Audit/Guarantees/PAlloc1.lean` and
> `LidoSRv3/Audit/Verity/AllocationTx.lean` as authoritative. I use
> `audit/guarantees.yaml` and the existing report to audit claim presentation.
> I have not rewritten the owner product note below.

## Auditor proof audit

**1. The registered parent has been split from the `min` tautology correctly.**
`PAlloc1.checked_execute` says exactly this: if `CheckedBounds` holds, the
checked source-shaped executor returns rows and the rows' capacity column,
coerced to `Nat`, equals `MathView.capacities`. Its proof is a direct
application of `source_capacities_match_canonical`.

`active_capacity_bounded` is a different theorem. For an active module,
`MathView.capacity` is defined to be
`min targetValidators availableCapacity`, so the two inequalities are
`Nat.min_le_left` and `Nat.min_le_right`. The Lean comments, registry, and
current report now label that theorem as an unregistered, MathView-definitional
child. I agree with this repair. Reintroducing it as a parent conjunct would
add no executable obligation and would recreate the earlier half-tautological
claim.

The remaining parent does have falsifiable content. It constrains the output of
the checked-word `execute`, not just `MathView`. Its limit is provenance:
`SolidityAllocCapacity.execute` is an API alias of
`AllocCapacity.execute`, not a separately extracted Solidity interpreter.
The meaningful comparison is one checked-word loop against separately written
unbounded `Nat` formulas.

**2. `CheckedBounds` is complete for the modeled arithmetic and unproved for
reachable router states.** The structure requires a nonzero `maxEBType1`, no
underflow in each active-count subtraction, no overflow in the accumulated
validator total, no overflow in each active module's available-capacity
arithmetic, and no overflow in each active module's share-limit
multiplication. Those hypotheses line up with the `safeSub`, `safeAdd`,
`safeMul`, and `safeDiv` failure points used by the modeled loops.

No theorem in the reviewed facade proves `CheckedBounds` from a reachable
StakingRouter configuration. It also contains no module-count, unique-id,
unique-address, packed-field-width, or share-limit policy invariant. Thus
CHECKED means "the modeled executor succeeds and refines `MathView` under this
caller-supplied arithmetic envelope." It does not mean every live router state
is inside that envelope.

The abstract and executable registered theorems are not composed through this
premise. `verity_tx_simulates_allocation` has no `CheckedBounds`; it agrees with
`sourceView` on both success and arithmetic revert. There is no facade theorem
that starts from a bound module list recovered from storage, converts it to the
abstract module list, applies `checked_execute`, and concludes a storage-read
capacity column.

**3. There is no live summary CALL in the allocation transaction.**
`sourceBindOne` reads depositable, deposited, exited, and stake words from four
model-local maps keyed by the already-bound module address. `allocate` then
runs `sourceExecute` on those planted words. A stale word or a dishonest module
summary is therefore part of the input state, not an execution that the theorem
can detect.

`mappedSummaryTransaction` does not close that gap. It is a separate Phase-3
proposition. On a long successful return it proves that
`executeObservedSummary` succeeds while the prewritten depositable slot remains
the prewritten value. It does not decode the return bytes into a `BoundModule`,
and `verity_tx_simulates_allocation` never consumes it.

The conjunction
`source_capacities_and_mapped_summary_transaction` is correspondingly
non-compositional. Its `moduleAddress` is free and is not tied to an element of
`modules`; no return word from the call side flows into `execute`. I read it as
two facts reported together, not as SOURCE-to-transaction summary
correspondence.

**4. The module count is a harness dimension.** The lower-level transaction
takes `count : Nat` and binds `List.range count`. The facade chooses
`modules.length`, but the caller still chooses an arbitrary module list and
supplies

    sourceBindAll state modules.length = modules

as `hBind`. There is no `SRStorage.getModulesCount()` read, no
`MAX_STAKING_MODULES_COUNT = 32` guard, and no theorem connecting the list
length to a reachable registry. A state seeded with 33 rows can satisfy the
premise just as a state seeded with two rows can.

`hBind` is useful because it states exactly which rows the storage harness will
recover. It is not evidence that those rows are the router's live module set.
The registry's `fidelity.missing` entry on `count` is accurate and should remain
prominent.

**5. The Verity theorem is lockstep storage plumbing.** `sourceExecute` calls
`AllocCapacity.firstLoop` and `AllocCapacity.secondLoop` directly.
`allocate` calls `sourceBindAll` and then that same `sourceExecute`.
`sourceView` also calls `sourceExecute`. After rewriting by `hBind`, the proof
case-splits on one shared interpreter.

That design usefully removes a duplicated handwritten loop, but it also fixes
the theorem's interpretation. `verity_tx_simulates_allocation` does not compare
two independent implementations of the capacity arithmetic. A shared defect in
the loop appears on both sides. The theorem checks binding, commit/revert
branching, persistence, observation, and rollback around that loop.

**6. Observe-from-storage is a real repaired obligation.** On success,
`observe` ignores the returned `Result` payload. It reads the allocation,
capacity, and bound-address arrays from the post-state and reads the total from
`totalSlot`. `persistRows_read` proves that the three writes are what those
reads recover, and the write-noop mutant is rejected. I consider the old
result-echo issue closed.

This remains an idealized storage channel. `writeArray` and `readArray` operate
on the Verity scaffold's array abstraction at literal local slots 40, 41, and
42. The theorem does not derive Solidity dynamic-array locations, packed
router storage, or keccak separation. The positive claim should stay
"persisted arrays are reread in this scaffold," not "the deployed storage
layout is observed."

On revert, `observe` constructs a reverted view rather than inspecting the
rollback state. The separate `revert_restores_snapshot` theorem carries the
real atomicity obligation and proves that even the injected failure after
writes returns the original state.

**7. `capacity_target_kill_line_refutes_parent` targets the repaired parent,
with one presentational overstatement.** The mutant still computes
`availableCapacity?` so it preserves that failure condition, but writes
`capacity := target` instead of `wordMin target available`. At the two-module
witness, `CheckedBounds` holds, the mutant commits raw targets `[24, 24]`, and
`MathView.capacities` is `[11, 11]`. This is the right mutation and the right
observable for `checked_execute`; it would not be meaningful against the
unregistered `Nat.min` child.

The theorem is a concrete witness bundle:

    CheckedBounds /\ mutant commits /\ Option.map capacities != some MathView

That is logically sufficient to refute the mutant-substituted parent because
the executor is deterministic. It is not literally the "explicit negation of
the parent's predicate shape" claimed by the YAML and comments. A literal
parent-shaped statement would negate the universal implication, or at least
negate the existential row-and-equality conclusion at the witness. This is a
small statement-discipline issue, not a defect in the counterexample.

The parent observes only the capacity column. `router_order_preserved` is a
separate child, and the parent does not compare current allocations,
target-validator diagnostics, active counts, addresses, or the persisted total.
The current kill-line is therefore strong evidence for the clamp in the
capacity column, but not for every returned field.

**Ranked recommendations.**

1. Preserve the Wave-2 split. Keep `checked_execute` as the registered parent
   and keep `active_capacity_bounded` explicitly unregistered. Do not re-fold
   the definitional `min` inequalities into the claim.
2. State the conditional perimeter at every CHECKED presentation point, and
   add a theorem from a modeled reachable-router invariant to `CheckedBounds`
   before making a live non-revert claim. If that invariant is not modeled,
   continue to list reachable `CheckedBounds` as missing.
3. Make summary data flow real before calling the Phase-3 conjunction a
   transaction correspondence. Decode successful callback returndata into the
   bound module fields, link the called address to the current module, and feed
   those fields into the loops. Otherwise keep the live summary CALL explicitly
   missing.
4. Read the module count from modeled router storage and enforce the live upper
   bound, or rename `allocate count` as a bounded harness and keep arbitrary
   `count` out of protocol-facing prose.
5. Add one composed theorem that starts with storage binding plus
   `CheckedBounds` on `modules.map toSourceModule` and ends with the
   observe-from-storage capacity column equaling `MathView.capacities`. This
   would connect the two current CHECKED cells without pretending the shared
   loop is independent.
6. Restate `capacity_target_kill_line_refutes_parent` as the literal negation of
   the mutant-substituted parent shape. Add targeted mutants for wrong target
   arithmetic and wrong available headroom, since the present mutant exercises
   only omission of the final `wordMin`.
7. Keep the storage-reread and rollback theorems. Describe the array channel as
   scaffold storage until concrete layout and aliasing are proved, and keep
   rollback separate from the reverted observation.

## Second pass, same day: machine-checked proof audit

> Second reviewer (2026-08-21). Proof audit only. The owner product note below
> is untouched, and so is the note above. Written against
> `LidoSRv3/Audit/Guarantees/PAlloc1.lean`,
> `LidoSRv3/Audit/Verity/AllocationTx.lean`,
> `LidoSRv3/Audit/Model/AllocCapacity.lean`,
> `LidoSRv3/Audit/Source/AllocCapacityCorrespondence.lean`,
> `LidoSRv3/Tests/AllocationTxMutants.lean` and `audit/guarantees.yaml`. First
> person, no em dashes. Lean is the authority. The three modules named in the
> row's reproduction command build clean at `leanprover/lean4:v4.31.0`. The
> pinned Lido Solidity is not in this tree, so every `SRLib` line number below is
> carried from the existing report and not re-verified.
>
> I arrived after the first-pass audit above and my job here is to put numbers on
> its prose where I can. Everything marked "checked" was confirmed by building a
> throwaway probe, `LidoSRv3/Tests/Alloc1AuditProbe.lean`, at the same pin. It is
> committed alongside this note and is explicitly not evidence: no facade imports
> it, `Trust.lean` does not print it, and `audit/guarantees.yaml` does not name
> it.

**C1. I agree the Wave 2 split was the right repair, and the registered parent
does have teeth.** `PAlloc1.checked_execute` forwards to
`source_capacities_match_canonical`, which forwards to
`SolidityAllocCapacity.source_execute_refines_audit_model`, which forwards to
`AllocCapacity.execute_refines_math`. Four public names, one theorem, and since
`SolidityAllocCapacity.execute` is `def execute := AllocCapacity.execute` there
are two artifacts under those four names, not three: the checked-word loop and
the `Nat` formulas in `MathView`. That pair is a real obligation. The `Nat`
formulas are written separately, the induction has to line up `safeSub`,
`safeAdd`, `safeMul` and `safeDiv` with their unbounded counterparts, and the
kill-line lands.

What the pair cannot see is a coordinated edit. The only lemma tying the clamp to
the model is `wordMin_coe`, and the same file already proves `wordMax_coe`
(`AllocCapacity.lean:223-232, 346-353`), so substituting `wordMax` in
`secondLoop` and `max` in `MathView.capacity` is supported by the existing lemma
set and the refinement would still go through. I did not build that pair, so I
mark this as read and not checked, but the shape of the proof makes it clear:
`checked_execute` is a transcription-agreement theorem between two artifacts in
this repository, and correctness against `SRLib.sol:493-559` rests on
`A-SOURCE-SHAPED`, whose subject is not in the tree. That is the honest reading
of the CHECKED cell and I would put it in the row summary.

**C2. The registered parent does not constrain the allocation column, and I can
show a mutant that exploits it. Checked.** The first pass notes in passing that
the parent observes only the capacity column. That gap is larger than it looks,
because `Row.currentAllocation` is a returned column, not a diagnostic: the
function is `_getModulesAllocationAndCapacity`, the legacy model notes in
`archive/legacy-p1-p15/README.md` describe it as building one current-allocation
row per router module, and the allocation column is the bucket fill `MinFirst`
starts from downstream. So I mutated exactly that column and left every capacity
computation alone:

    theorem zero_allocation_column_mutant_survives_registered_parent
        (cfg) (modules) (deposits) (isTopUp) (hBounds : CheckedBounds …) :
        ∃ rows, executeZeroAlloc cfg modules deposits isTopUp = some rows ∧
          rows.map (fun row => (row.capacity : Nat)) =
            MathView.capacities cfg modules deposits isTopUp

    theorem zero_allocation_column_is_observably_wrong :
        (execute … ).map (fun rows => rows.map Row.currentAllocation)
            = some [10, 10] ∧
          (executeZeroAlloc … ).map (fun rows => rows.map Row.currentAllocation)
            = some [0, 0]

`executeZeroAlloc` is `secondLoop` with `currentAllocation := 0` in both arms and
`capacity := wordMin target available` untouched, so the capacity column is
literally unchanged (`secondLoopZeroAlloc_eq` proves the mutant is the honest
executor post-composed with a row rewrite) and the mutant-substituted parent is
derivable from the parent itself. The Verity cell does not catch it either,
because `sourceView` is built from the same interpreter the transaction runs, so
the wrong column appears on both sides of the equality.

The fix is close to free, which is why I rank it first. `firstLoop_refines`
already proves `entries.map (·.1) = modules.map (MathView.allocationEntry cfg)`
(`AllocCapacity.lean:313-316`), and `secondLoop` copies `entry.1` straight into
`currentAllocation`, so extending `secondLoop_refines`'s conclusion with the
allocation column is bookkeeping over an induction that already carries the
needed equation.

**C3. The registered Verity theorem holds for an arbitrary interpreter. Checked.**
The first pass calls the Verity plane lockstep storage plumbing. I can state
exactly how lockstep. I generalized `allocate` and `sourceView` over an arbitrary
function of the interpreter's type and reproved the registered theorem's script
unchanged, with no hypothesis on that function at all:

    abbrev ExecFn := Config → List BoundModule → Word → Bool → Option (List Row × Word)

    theorem verity_tx_simulates_any_exec (exec : ExecFn) (cfg) (modules)
        (deposits) (isTopUp) (state)
        (hBind : sourceBindAll state modules.length = modules) :
        observe modules ((allocateGen exec modules.length cfg deposits isTopUp).run state)
          = sourceViewGen exec cfg modules deposits isTopUp

This is a stronger version of the same finding recorded for P-TOPUP-2, where the
analogous generalization at least needed the interpreter to return `none` on an
empty batch. Here nothing is needed. So the registered Verity cell certifies the
bind identity, the commit and revert branching, the persist and reread channel,
and the revert-arm agreement, and exactly zero properties of the allocation
arithmetic.

The immediate consequence is that the row's one kill-line bears on one of its two
CHECKED cells. Instantiating the generalization at the kill-line's own mutant:

    theorem capacity_target_mutant_survives_registered_verity_shape … :
        observe modules ((allocateGen execCapTarget …).run state)
          = sourceViewGen execCapTarget cfg modules deposits isTopUp

    theorem capacity_target_mutant_is_observably_wrong :
        (sourceViewGen execCapTarget cfg killModules 10 false).capacities = [24, 24] ∧
          (sourceView cfg killModules 10 false).capacities = [11, 11]

The `capacity := target` mutant that refutes `checked_execute` satisfies
`verity_tx_simulates_allocation`'s exact shape while committing unclamped
capacities. `fidelity.covered` currently reads as though the kill-line covered the
row; it covers the abstract cell.

**C4. `hBind` is not a restriction on the state. Checked.** The first pass says a
state seeded with 33 rows can satisfy the premise as easily as one seeded with
two. It is stronger than that: *every* state satisfies it, for every count.

    theorem bind_premise_is_total (state : ContractState) (count : Nat) :
        sourceBindAll state (sourceBindAll state count).length =
          sourceBindAll state count

Take `modules := sourceBindAll state count` and the premise is discharged by
`List.length_map` on `List.range`. So `hBind` names the module list rather than
constraining the world, and the registered Verity theorem is total over states
and over counts: 33 rows on a two-module seed, unseeded phantom rows reading as
`moduleId = 0`, addresses colliding, all in scope. That is the sharp form of
report issues 13, 15 and 19, and `fidelity.missing` already carries the count
gap, which I would keep and reword as "the bind premise is satisfiable for every
state and count; it identifies the row list rather than restricting it".

I also checked the other direction, that the harness round-trips, because a
premise that is trivially satisfiable is not automatically satisfied by the
vectors: `bind_round_trip` confirms `sourceBindAll (stateFor modules) 2 = modules`
on the mutant file's own two-module seed, so the seed/bind pair in
`AllocationTxMutants.lean` is coherent with `isActive = (status == 0)` and
`isType2 = (wcType == 2)` after the PR #105 repair.

**C5. Observe-from-storage is a real repair, and the channel it reads is
structurally unaliasable.** I agree with the first pass that the old result-echo
issue is closed: `observe`'s success arm reads `state.readArray` on slots 40, 41
and 42 plus `state.readSlot totalSlot` (`AllocationTx.lean:132-137`), and
`persistRows_read` is what closes the proof.

I would put the caveat in structural terms rather than calling it idealized.
`ContractState` (`Verity/Core.lean:318-322`) has two separate storage fields, a
`storageWords : StorageKey → Uint256` map and a `storageArray : Nat → List
Uint256`. `persistRows` writes the second, the total write and every summary read
go to the first, and the proof's last step is
`ContractState.storageArray_writeSlot`, which is `rfl` because the two fields are
different record components. So "the allocation and capacity columns are
persisted and reread" is a true statement about a channel that cannot alias
anything, including the map slots the same transaction reads. That is also why
the packed-`ModuleStateConfig` gap (report issue 7) is not representable: the map
bases 30 through 39 are distinct `StorageKey.mapUint` constructors, so no write
can clobber a neighbour.

Two smaller items. On the reverted arm both sides are
`⟨reverted, [], [], modules.map moduleAddress, 0⟩`, where the address list on the
`observe` side is the caller-supplied `before` argument and on the `sourceView`
side is the same list from `hBind`, so that arm carries revert-condition
agreement and nothing about state. And `PAlloc1.verity_tx_revert_restores_snapshot`
is proved but not registered: `audit/guarantees.yaml` names two theorems for this
row and lists "Contract.run rollback after intermediate writes" under
`fidelity.covered`, so the atomicity obligation is claimed in the YAML prose and
carried by a theorem the YAML does not name.

**C6. The kill-line is well aimed and its statement shape is one step short.** I
agree with the first pass on both halves. `capacity_target_kill_line_refutes_parent`
discharges `CheckedBounds` at the witness with `decide`, shows the mutant
commits, and shows its capacity column differs from `MathView.capacities`, which
is the right mutation and the right observable. Since the executor is a function,
that conjunction does refute the mutant-substituted parent, but the reader has to
take that step: `P-DEREF-1`, `P-ALLOC-2`, `P-TOPUP-2` and `P-ADDRESS-1` all state
their kill-lines as `¬ ∀ …` over the registered shape, and the YAML claims this
one is "the explicit negation of the parent's predicate shape". I would restate it
in that form for uniformity, and add C3's observation to the row so the two
CHECKED cells are not described as sharing one kill-line.

**C7. `CheckedBounds` is phrased in the vocabulary of the model it is comparing
against.** Beyond the first pass's point that no theorem derives `CheckedBounds`
from a reachable router state, the five fields are stated over `MathView` terms:
`total_addition` bounds `(deposits : Nat) + (modules.map (MathView.allocationEntry
cfg)).sum`, and `available_arithmetic` and `target_multiplication` quantify over
`MathView.activeCount`, `MathView.allocationEntry` and
`MathView.totalValidators` (`AllocCapacity.lean:165-178`). So discharging the
premise for a concrete state requires computing the `Nat` model first, which is
fine as a proof device and awkward as a deployment-facing side condition. A
reader who wants to know whether a live router is inside the envelope has no
predicate over storage words to evaluate.

One dead branch worth noting in the same place. `MathView.allocationEntry` guards
`maxEBType1 = 0` and returns `0` (`:132-137`), while
`CheckedBounds.maxEBType1_nonzero` excludes that case, so the guard is
unreachable in every theorem that uses the bounds. It is the `Nat` plane's
stand-in for a Solidity revert, and it never fires under the hypothesis that
makes the correspondence hold.

**C8. No live summary CALL, and the Phase-3 conjunct is not on the registered
path.** I confirm the first pass. `sourceBindOne` reads depositable, deposited,
exited and stake from map bases 36 to 39 keyed by the bound `moduleAddress`
(`AllocationTx.lean:78-81`), and the module docstring says so. What I would add is
where this leaves the source map: `audit/source-map.yaml` maps
`SRLib._getStakingModuleSummary` 372-379,
`IStakingModule.getStakingModuleSummary` 71-81 and
`IStakingModuleV2.getTotalModuleStake` 28-29 to P-ALLOC-1, and no registered
theorem executes or even assumes any of them. `fidelity.missing` is honest about
the calls, so the mismatch is in the map's `MAPPED` status rather than in the
YAML, and the same mapped-but-not-modeled marking recommended for P-TOPUP-2's
`_verifyValidator` span applies here.

### Ranked recommendations (second pass)

Ordered by claim integrity bought per unit of change. Where the first pass and I
agree I say so instead of restating.

1. Register the allocation column (C2). Extend the parent's conclusion with
   `rows.map (fun r => (r.currentAllocation : Nat)) = modules.map
   (MathView.allocationEntry cfg)`. The equation is already produced by
   `firstLoop_refines`, and without it a router that returns a zeroed allocation
   array to `MinFirst` is CHECKED.
2. Give the Verity cell one semantic conjunct, or stop reading it as evidence for
   the arithmetic (C3). The cheapest form composes what already exists: under
   `CheckedBounds` on `modules.map toSourceModule`, the observed capacity column
   equals `MathView.capacities`. That is the composed theorem the first pass asks
   for in its recommendation 5, and it has the side effect of making the existing
   kill-line bite on both cells.
3. Say in the row summary that `checked_execute` is transcription agreement
   between `AllocCapacity.execute` and `MathView`, that
   `SolidityAllocCapacity.execute` is an alias rather than a third plane, and
   that a coordinated edit to both is invisible (C1).
4. Reword the `hBind` entry in `fidelity.missing` to say the premise is
   satisfiable for every state and count (C4), and either read the count from
   modeled router storage or keep `allocate count` described as a harness, which
   is the first pass's recommendation 4.
5. Restate the kill-line as `¬ ∀ …` over the registered shape, and add mutants
   for the target and headroom arithmetic rather than only the final clamp (C6,
   agreed with the first pass's recommendation 6).
6. Register `verity_tx_revert_restores_snapshot` or drop the rollback line from
   `fidelity.covered` (C5).
7. Describe the persistence channel structurally: `storageArray` is a separate
   record field from `storageWords`, which is why reread and non-aliasing are
   free here and why packed router storage is unrepresentable (C5).
8. Mark the three summary-call spans in `audit/source-map.yaml` as
   mapped-but-not-modeled (C8), and note that `CheckedBounds` is stated in
   `MathView` terms with one branch that its own nonzero hypothesis makes dead
   (C7).

## Owner product note and prior audit history

Theorems: `PAlloc1.checked_execute` (registered parent), `PAlloc1.active_capacity_bounded` (unregistered MathView-definitional child), `PAlloc1.verity_tx_simulates_allocation`.
Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

Lido SRv3’s `StakingRouter` decides how many new deposits (or top-ups) each staking module may receive. The live function is `SRLib._getModulesAllocationAndCapacity` (`lidofinance/core@af095e48`, lines 493–559), exposed as `StakingRouter.getDepositAllocations`. For every module it (1) reads `moduleId → moduleAddress` and calls the module’s `getStakingModuleSummary`, (2) computes a current allocation (active-validator count, or `ceil(stake / maxEBType1)` for type-2 / compounding modules), (3) sums those into a new network-wide validator total, then (4) sets each *active* module’s capacity to `min(share-limit target, available headroom)`.

The registered guarantee (`checked_execute`) is an execute↔MathView capacity-column correspondence: under the named checked-arithmetic bounds (`CheckedBounds`), the source-shaped executor succeeds and its capacity column equals the independent `MathView` model’s, row for row. The earlier headline — an active module cannot be given more capacity than its stake-share target *or* its available depositable/top-up headroom, the router’s anti-concentration / anti-over-allocation bound — is now the unregistered child `active_capacity_bounded`, a `Nat.min` tautology on the `MathView.capacity` definition (issue 1), not the registered claim.

## Modeling

- `A-SOURCE-SHAPED`: the Lean `Module` record is not extracted from the pinned Solidity AST; depositable / exited / stake words are trusted fields already sitting in model-local maps.
- `A-VERITY-SCAFFOLD`: `Contract.run` is a non-certified Verity 4.31 interpreter, not compiled bytecode.
- No live `getStakingModuleSummary()` / `getTotalModuleStake()` CALL. `AllocationTx.sourceBindOne` reads summary words from storage keyed by the already-bound `moduleAddress`. A module that lies, or a stale cache, is outside the model.
- Slot numbers (`moduleIdSlot = 30`, …) are a local projection, not `ROUTER_STORAGE_POSITION` / keccak map slots.
- `AllocCapacityPhase3.mappedSummaryTransaction` stubs the summary CALL: a successful adversary returning enough bytes leaves the *pre-placed* depositable slot unchanged; return data is not decoded.
- `MathView` uses unbounded `Nat`. Solidity 0.8 checked `+`/`*` revert; `CheckedBounds` is an extra hypothesis only on the SOURCE refinement, not on the headline bound.
- Inactive modules keep their current allocation as capacity (matching source line 541 / the `else` of line 542). The bound theorem requires `isActive = true`.

## Proof

**Abstract `checked_execute` (registered parent, Wave 2).** Restates `source_capacities_match_canonical` below under the parent's public name: under `CheckedBounds`, the source-shaped executor succeeds and its capacity column equals `MathView.capacities`. No `min`-tautology conjunct. The named kill-line `LidoSRv3.Tests.AllocationTxMutants.capacity_target_kill_line_refutes_parent` (`capacity := target`, skipping `wordMin`) is the explicit negation of the parent's predicate shape with the mutant executor substituted: `CheckedBounds` is discharged at the witness, the mutant commits a capacity column `[24, 24]` that disagrees with `MathView.capacities`' `[11, 11]`, so the kill-line is checked against the parent's entire statement, not half of it.

**Unregistered child `active_capacity_bounded`.** Unfold `MathView.capacity`. For an active module that definition *is* `min(targetValidators, availableCapacity)`. The two conjuncts are `Nat.min_le_left` and `Nat.min_le_right`. No induction, no source loop, no share-limit algebra — this is a fact about the `min` operator applied to whatever two `Nat`s `MathView` computed, true regardless of whether those `Nat`s are the router's actual target/headroom. Wave 1 folded this into the registered parent as `checked_execute_and_active_capacity_bounded`; Wave 2 demoted it back out (issue 1) because a definitional tautology in a registered parent cannot be targeted by any kill-line mutant.

**SOURCE `source_capacities_match_canonical`.** Under `CheckedBounds` (nonzero `maxEBType1`, no underflow on exited-count, no `uint256` overflow on the sums/products), a pair of inductions on `firstLoop` / `secondLoop` show each `safe*` word equals the corresponding `Nat` operation, so the checked interpreter’s capacity column equals `MathView.capacities`. Router order is a structural list-map identity (`secondLoop_router_order`).

**VERITY `verity_tx_simulates_allocation`.** Assume `sourceBindAll state n = modules`. The transaction rebinds with the same `sourceBindAll` and runs the same two loops: `sourceExecute` calls `AllocCapacity.firstLoop` / `secondLoop` directly (`AllocationTx.lean:87–91`); the former tx-side copies (`txBindOne`, `txFirstLoop`, …) no longer exist — see the historical notes on issues 2 and 12. The transaction writes capacity/allocation arrays (`persistRows`), and `observe` reads those arrays back. Equality with `sourceView` is therefore the bind identity plus the already-checked SOURCE interpreter. Revert-rollback is `Contract.run` restoring the snapshot, including an injected `failAfterWrites` hook.

## Issues

## Resolution

**Restated Lean/English.** `active_capacity_bounded` is `MathView.capacity = min`, not a live router clamp. Verity names `hBind` and reads persisted arrays.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

**Wave 2 (2026-08-19): registered-parent repair for issue 1.** The 2026-08-18
`A+D` close kept `active_capacity_bounded`'s `Nat.min` tautology conjoined
into the registered parent (`checked_execute_and_active_capacity_bounded`)
and pointed at the unrelated `P-ALLOC-1.eugene-bound` sibling instead of
touching the parent statement itself, so the tautological conjunct was still
part of every CHECKED claim about P-ALLOC-1 and still could not be killed by
any mutant. This wave splits the Wave 1 parent: the registered parent is now
`checked_execute` (`source_capacities_match_canonical`'s statement, renamed
to the public parent name), and `active_capacity_bounded` is kept only as an
explicit, unregistered, separately labeled MathView-definitional fact. The
existing kill-line mutant in `AllocationTxMutants.lean` (`capacity := target`)
is unchanged in substance and is now checked against the parent's entire
(purely executable) statement instead of half of a conjunction. Issue 1 is
reclassified `B` below.

**Wave 5 (2026-08-19): kill-line naming.** The parent kill-line was an
anonymous `example`; it is now the named theorem
`LidoSRv3.Tests.AllocationTxMutants.capacity_target_kill_line_refutes_parent`,
strengthened to the explicit negation of the registered parent's predicate
shape with `executeMutant` substituted: `CheckedBounds` discharged at the
witness, the mutant commits, and `Option.map` of its capacity column differs
from `MathView.capacities`. No other theorem statement changed.

| # | Close | Note |
| --- | --- | --- |
| 1 | B (Wave 2) | Registered parent is now `checked_execute` (no `min` conjunct); `active_capacity_bounded` is an explicit unregistered child. `P-ALLOC-1.eugene-bound` remains an unrelated sibling. |
| 2, 12, 16 | A | SOURCE/TX are lockstep copies. |
| 3, 4 | scope | Live summary CALL/returndata listed in `missing`. |
| 5, 14, 17 | A | Unbounded-Nat min; `CheckedBounds` is a separate sibling. |
| 6 | C | Fixed in PR #105: `observe` reads the persisted `writeArray` columns (`AllocationTx.lean:132–136`); the write-noop mutant `allocateNoWrite` is rejected. |
| 7 | scope | Packed `ModuleStateConfig` in `missing`. |
| 8, 9 | C | Active is status `== 0`; type-2 is WC `== 2`; seed writes 0/1 and 2/1. |
| 10 | A | Named `_getModulesAllocationAndCapacity` only. |
| 11 | scope | Unique `moduleAddress` in `missing`. |
| 13, 15, 19 | A | `count` is a harness argument; `hBind` already required. |


1. **The headline abstract bound is a tautology of `min`.**
   `MathView.capacity` for `isActive = true` is defined as `min(target, available)`. `active_capacity_bounded` restates `min a b ≤ a ∧ min a b ≤ b`. It would hold for any two Nats, including a model that computed the wrong target or the wrong headroom. It does not prove that the *router* clamps capacity; it proves that the *definition* that already is a clamp is a clamp.

   *Counterexample to the intended guarantee, not to the Lean statement.* Take `targetValidators = 10^9` (share limit 10000, huge `totalValidators`) and `availableCapacity = 10^9` (a module that advertised `depositableCount = 10^9`). The theorem holds (`min` of those is still `≤` both). On the deployed router the same inputs produce a capacity of `10^9` validators. The “bound” did not constrain anything the share-limit or depositable-count already failed to constrain.

2. **Verity bind is definitional, not a correspondence.** **Historical as stated** (the tx-side copy is gone): when written, `txBindOne` and `sourceBindOne` were the same function (`AllocationTx.lean:73–86` vs `104–116`; `txBindOne_eq_sourceBindOne` was `rfl`). The duplicate has since been removed — `allocate` rebinds through `sourceBindAll` and `sourceExecute` calls the `AllocCapacity` loops directly (`AllocationTx.lean:107–120`, `87–91`) — which makes the same point without a second copy: the bind the theorem quantifies over is the shared `sourceBindAll` assumed by `hBind`, not an independent artifact.

   *Counterexample to “two independent artifacts” (historical).* Edit only a comment in `txBindOne`. The equality still held by `rfl`. The only way to break `verity_tx_simulates_allocation` via binding was to hand-edit one copy and leave the other. A solc that emitted the wrong key would not be one of those copies.

3. **No module callback, so a lying / stale summary is in-model.**
   Deployed `SRLib` lines 516–517 call `getIStakingModule()` then `getStakingModuleSummary`; line 529 is a **second** CALL `getIStakingModuleV2().getTotalModuleStake()` for type-2 modules. The Verity tx never performs those CALLs. Scenario: module address `0xM` is stored; the summary map at `0xM` still holds yesterday’s `depositableCount = 100` while the live module now reports `0`. `verity_tx_simulates_allocation` commits capacity 100. The deployed view function would read `0`. The guarantee as a claim about `getDepositAllocations` is false under any desynchronised summary.

4. **Phase-3 “mapped summary” does not parse return data.**
   `mappedSummaryTransaction` (PAlloc1.lean:14–54) is not used by `verity_tx_simulates_allocation`. Its `CallsIn` adversary always returns `success (replicate summaryReturnBytes 0)` and a no-op `stateTransition`. On a long-enough success, `executeObservedSummary` leaves `lastCapacitySlot` equal to the *pre-written* `depositable`. The 4-byte selector `0x9abddf09` is the real `getStakingModuleSummary()` selector; that is the honest fragment.

   *Scenario.* Module returns 96 bytes of `0xff` (a huge depositable). Lean still commits with the old slot. The Phase-3 conjunct is “the stub CALL happened,” not “capacity came from returndata.”

5. **`CheckedBounds` is not proved of any reachable router state.**
   If `maxEBType1 = 0`, Lean `Nat` division in `MathView.availableCapacity` is `0`; Solidity `activeCount * maxEBType2 / maxEBType1` reverts. The abstract bound still “holds” (capacity 0 ≤ 0). The SOURCE refinement simply does not apply. No theorem says a configured SRv3 router satisfies `CheckedBounds`.

   *Scenario.* Misconfigured `maxEBType1 = 0` on a type-2 top-up. Live `getDepositAllocations` reverts. `active_capacity_bounded` reports capacity 0 and succeeds. CHECKED does not mean “the router cannot be in the reverting configuration.”

6. **`observe` read the returned `Result`, not the written maps.** **Resolved** (observe-from-storage repair, PR #105): `AllocationTx.observe` on success now reads the persisted arrays — `state.readArray allocationSlot`, `state.readArray capacitySlot`, `state.readArray boundAddressSlot` — plus `state.readSlot totalSlot` (`AllocationTx.lean:132–136`), and the write-noop mutant `allocateNoWrite` in `AllocationTxMutants.lean` is rejected precisely because `observe` reads the storage arrays. Historical statement: `observe` took `result.allocations`, `result.capacities`, `result.moduleAddresses` from the value `allocate` constructed *before* looking at the writes; only `totalValidators` was `state.readSlot totalSlot`.

   *Counterexample mutant (now rejected).* Make the row persistence a no-op (or write `0` for every capacity) while keeping the `Result` triple built from `rows`. Before the fix, `verity_tx_simulates_allocation` still held; after the fix, the mutant disagrees with `observe`.

7. **Share-limit / status / WC-type live in one packed Solidity slot; Lean uses separate maps.**
   `ModuleStateConfig` (`SRTypes.sol:118–136`) packs `moduleAddress`, `uint16 stakeShareLimit`, `status`, `uint8 withdrawalCredentialsType` in a single slot. `AllocationTx` reads `shareLimitSlot = 32`, `statusSlot = 33`, `wcTypeSlot = 34` as independent words. `stakeShareLimit` is `uint16`; Lean allows any `Uint256`.

   *Scenario.* A wide `SSTORE` that updates status also clobbers the packed share limit on chain. Lean `statusSlot` write (if anyone modeled one) would not touch `shareLimitSlot`. Conversely, Lean can have `shareLimit = 10001` (not a `uint16` field); target becomes `10001 * total / 10000`. The CHECKED bind/loop never sees packing.

8. **`status != 0` was the opposite of `StakingModuleStatus.Active`.** **Resolved** (bind/seed repair, PR #105): `sourceBindOne` now sets `isActive := statusSlot == 0` (`AllocationTx.lean:75`) and `seedOne` writes `0` for active / `1` for inactive (`:187`), matching the Solidity enum (`SRTypes.sol:40–43`: `Active = 0`, `DepositsPaused = 1`, `Stopped = 2`) and the `cache[i].status == Active` clamp (`SRLib.sol:542`). Historical statement: the bind set `isActive := statusSlot != 0` and `seedOne` wrote `1` for active and `0` for inactive, so the Lean harness was self-consistent and inverted vs storage.

   *Counterexample (pre-fix).* Real slot: module A `status = 0` (Active), `depositable = 100`; module B `status = 1` (DepositsPaused), `depositable = 100`. Live `getDepositAllocations` gives A `min(target, alloc+100)` and B its current allocation (no new deposits). The pre-fix Lean bind read A as inactive and B as active: A kept current allocation, B got the share-limit clamp and new depositable, so `verity_tx_simulates_allocation` on a state copied from mainnet storage computed the wrong capacities.

9. **`wcType != 0` treated type-0x01 modules as type 2.** **Resolved** (bind/seed repair, PR #105): `sourceBindOne` now sets `isType2 := wcTypeSlot == 2` (`AllocationTx.lean:76`) and `seedOne` writes `2` for type 2 / `1` otherwise (`:188`), matching the stored `withdrawalCredentialsType` values `0x01` / `0x02` (`WithdrawalCredentials.sol:13–14, 47–48`). Historical statement: the bind set `isType2 := wcTypeSlot != 0`, so type `0x01` (curated / DVT) modules took the type-2 branch — `ceil(stake / maxEBType1)` instead of active-validator count, and the top-up `active * maxEBType2 / maxEBType1` capacity — and `seedOne` hid it by writing `1` only for type 2 and `0` for type 1.

   *Scenario (pre-fix).* Curated module, `wcType = 1`, `deposited = 100`, `stake = 0`. Live allocation is `100` (active count). The pre-fix Lean bind saw `isType2 = true`, `ceil(0 / 32) = 0`; capacities and share-limit totals were computed from the wrong column.

10. **`getDepositAllocations` (the user-facing function) is not this guarantee.**
   After capacities, `SRLib._getDepositAllocations` converts to ETH and runs `MinFirstAllocationStrategy.allocate` (lines 404–421). P-ALLOC-1 stops at the capacity column.

   *Scenario.* Two modules, allocations 0, capacities 10, `depositsToAllocate = 1`. Capacities are fine; MinFirst then mis-splits the single deposit. P-ALLOC-1 still CHECKED. That bug is supposed to be P-ALLOC-2, which is a different model (see that report).

11. **Summary words are keyed by `moduleAddress`, so colliding addresses share depositable.**
    `sourceBindOne` / `txBindOne` (`AllocationTx.lean:82–85, 113–116`) read `summaryDepositableSlot[moduleAddress]` (and deposited / exited / stake). Two module ids that resolve to the same address (legal under P-DEREF-1 `Reachable` — see that report issue 7) bind the same summary.

    *Scenario.* Modules 1 and 2 both have address `0xA`. Map at `0xA` holds `depositable = 10`. Lean gives *each* module available 10, total headroom 20. Live `_addModule` reverts `StakingModuleAddressExists` on the second add, so this state does not arise; if a migration produced it, each CALL to `0xA.getStakingModuleSummary` would still return one summary, but the router would count that summary twice in the first loop. The CHECKED bind cannot tell “two modules” from “one module registered twice.”

12. **`txFirstLoop` / `txAllocationEntry?` are a second handwritten copy of `AllocCapacity`.** **Historical** (those symbols no longer exist): the tx-side loop copies have been deleted and `sourceExecute` now calls `AllocCapacity.firstLoop` / `secondLoop` directly (`AllocationTx.lean:87–91`), so there is literally one interpreter; the lines this issue cited (`AllocationTx.lean:124–138`) now hold `Status` / `View` / `observe`. As written: bind equality was already `rfl` (issue 2), and the loops re-implemented `txActiveCount?`, `txCeilDiv?`, type-2 `ceil(stake / maxEBType1)` vs active count — the same arithmetic `AllocCapacity.firstLoop` already ran under `sourceExecute`.

    *Counterexample to independence (historical).* Invert `isType2` in both `AllocCapacity.allocationEntry?` and `txAllocationEntry?`. `verity_tx_simulates_allocation` still held (both sides took the stake-ceil branch for curated modules). Combined with issue 9 (`wcType != 0` already treats 0x01 as type 2), a shared type-dispatch bug was invisible to the CHECKED equality.

13. **`allocate` takes `count` as an argument, not `getModulesCount()`.**
    Live `_getModulesAllocationAndCapacity` (`SRLib.sol:496`) sets `modulesCount = SRStorage.getModulesCount()` and walks `getModuleIdAt(i)`. Lean `allocate count` (`AllocationTx.lean:107–120`) does `sourceBindAll snapshot count` = `(List.range count).map (sourceBindOne snapshot)` (`AllocationTx.lean:83–84`). There is no modules-count slot.

    *Scenario.* Router has 3 modules. Harness calls `allocate 2`. Lean binds indices 0 and 1, computes a `totalValidators` that omits module 2, and clamps the first two capacities against that smaller total. Live view includes all three and a larger share-limit total. `verity_tx_simulates_allocation` holds of the 2-row fiction. The CHECKED tx is “run the loops on the first `count` map rows,” not “the router’s live module list.”

14. **`MathView.activeCount` saturates; Solidity 0.8 reverts.**
    `AllocCapacity.lean:129–130`: `(deposited : Nat) - max(summaryExited, accountingExited)`. `Nat.sub` is 0 when exited > deposited. Live `SRLib.sol:521–522` is checked `depositedValidatorsCount - Math.max(...)`. `CheckedBounds.active_subtraction` excludes this case from the SOURCE refinement only.

    *Counterexample.* `depositedCount = 10`, `summaryExitedCount = 20`, module active, `isType2 = false`. Live `getDepositAllocations` reverts. `MathView.activeCount = 0`, `capacity = min(target, 0+depositable)`. `active_capacity_bounded` holds. The CHECKED abstract bound is true of a configuration the router cannot return. Same shape as issue 5 (`maxEBType1 = 0`).

15. **`count` can exceed `MAX_STAKING_MODULES_COUNT = 32`.**
    Extends issue 13. Live `_addModule` reverts when `getModulesCount() >= 32` (`SRUtils.sol:18`, SRLib 183–231). Lean `allocate 33` is a legal tx: `List.range 33` binds 33 map rows (many default-zero). Share-limit `totalValidators` includes those zeros.

    *Scenario.* Harness calls `allocate 33` on a two-module seed. Lean walks 33 indices; ids 2..32 read as 0, share-limit total is computed over 33 rows. Live view has 2 modules. `verity_tx_simulates_allocation` holds of the 33-row fiction. The CHECKED tx is not capped by the router’s module limit.

16. **SOURCE `execute` is an alias of `AllocCapacity.execute`, not a second interpreter.**
    `AllocCapacityCorrespondence.lean:31–33`: `def execute := AllocCapacity.execute`. The file header still talks about “independent” source semantics. `source_capacities_match_canonical` compares that alias to `MathView` under `CheckedBounds`. Combined with issue 2 / 12 (`txBind` / `txFirstLoop` copies), the three “planes” are one loop plus a `Nat` `List.map`.

    *Counterexample to independence.* Change `availableCapacity?`’s type-2 formula. SOURCE `execute` changes with it (`:=`). MathView is a separate `Nat` formula, so the refinement can fail — that pair has teeth. The SOURCE *name* is not a third artifact. A reader of CHECKED “MODEL→SOURCE→TX” is looking at `MathView` vs `execute` vs a handwritten copy of `execute`. YAML’s three-layer story oversells the SOURCE export.

17. **`MathView.targetValidators` is unbounded `Nat` `shareLimit * total / 10000`.**
    Live `SRLib.sol:552` is checked `(shareLimit * totalValidators) / TOTAL_BASIS_POINTS`. `CheckedBounds.target_multiplication` excludes overflow from the SOURCE refinement. `active_capacity_bounded` uses `MathView` with no such bound.

    *Counterexample.* `shareLimit = 10000`, `totalValidators` (including `depositsToAllocate`) = `2^256`. Live `*` reverts. MathView target is `2^256`; `capacity = min(2^256, available)` still satisfies `≤ target` and `≤ available`. The CHECKED abstract bound holds of a reverting share-limit multiplication. Same shape as issues 5 and 14.

18. **The Eugene “amount ≤ capacity headroom” lemma is not this row.**
    `PAlloc1EugeneBound.checked_amount_le_bond` says MinFirst `checkedAmount` is `≤ capacity − allocation`. That is a P-ALLOC-1 × P-ALLOC-2 composition the CHECKED parent does not state. `active_capacity_bounded` is `min` tautology (issue 1); `verity_tx_simulates_allocation` stops before MinFirst (issue 10).

    *Scenario.* Capacities are fine; MinFirst then over-fills a bucket (issue 11 of P-ALLOC-2). P-ALLOC-1 stays CHECKED. The Eugene lemma would have constrained that fill and is not the registered theorem. The YAML row once headlined an “anti-concentration / anti-over-allocation bound” (the phrase has since been removed from the row); that headline was the `min` of two Nats, not `checked_amount_le_bond`.

19. **`verity_tx_simulates_allocation` assumes the bind already produced `modules`.**
    The theorem takes `hBind : sourceBindAll state modules.length = modules`. Unset map rows read as `moduleId = 0`, `moduleAddress = 0`, `status = 0` (inactive under the inverted test, issue 8), `depositable = 0`. `allocate 33` on a two-module seed (issue 15) binds 31 phantom id-0 rows.

    *Scenario.* Two real modules at indices 0,1. `allocate 5` without seeding 2..4. Bind is `[m0, m1, zero, zero, zero]`. Share-limit `totalValidators` includes three extra current-allocation 0s. Live `getModulesCount() = 2`. `hBind` holds of that 5-row fiction. The CHECKED equality is “given a list that is already the bind of `state`, re-run the loops.” It does not prove the bind is the router’s module list.
