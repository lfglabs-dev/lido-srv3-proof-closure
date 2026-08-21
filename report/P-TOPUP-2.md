# P-TOPUP-2

> Round 2 (2026-08-21). Voice of the auditor, first person, no em dashes. Lean
> is the authority: every claim below was read off `LidoSRv3/Audit/Guarantees/PTopup2.lean`,
> `LidoSRv3/Audit/Source/Topup2Correspondence.lean`,
> `LidoSRv3/Audit/Verity/Topup2DistributionTx.lean`,
> `LidoSRv3/Audit/Guarantees/PTopup2Verity.lean`,
> `LidoSRv3/Tests/Topup2DistributionTxMutants.lean`, and the verity pin
> `a063bfc`, not off the YAML prose. The four registered P-TOPUP-2 modules build
> clean at `leanprover/lean4:v4.31.0`. The pinned Lido Solidity is not in this
> tree, so where I cite `StakingRouter` line numbers I am carrying them over
> from the round-1 note and did not re-verify them; the three spans I did verify
> are the ones in `audit/source-map.yaml`.
>
> The findings marked "checked" in section B were confirmed by building a
> throwaway probe module, `LidoSRv3/Tests/Topup2AuditProbe.lean`, against the
> same pin. It is committed alongside this note and is explicitly not evidence.

## A. Product note

P-TOPUP-2 is the per-block ceiling on Electra compounding top-ups. The mapped
slice is `TopUpGateway.topUp` (`lidofinance/core@af095e48`, lines 160 to 237),
its per-validator headroom helper `_evaluateTopUpLimit` (396 to 415), and
`CLValidatorVerifier._verifyValidator` (44 to 57). The product question a reader
brings to this row is "can one call top up more gwei than governance allows in a
block", and the answer the row gives is narrower than that question.

The registered abstract theorem is `PTopup2.aggregate_bounded_by_block_cap`. It
says that for every batch and every configuration, with no well-formedness
hypothesis at all,

    (transition b cfg).sum <= cfg.maxTopUpPerBlockGwei

where `transition` is `consumeBudget (transitionBudget b cfg) (candidates b cfg)`,
`transitionBudget` is `min (valueWei / 10^9) (min moduleAllocationLimitGwei maxTopUpPerBlockGwei)`,
and `candidates` is `zipWith min requestedGwei (validators.map evaluated_topup_limit)`.
The proof is an induction over the left-to-right budget walk plus two
projections out of that `min`. The unconditionality is real and I checked it: the
file even carries a witness, `illFormedCapBatch`, whose allocations fail
`well_formed_pre` while the bound still applies.

The registered Verity theorem is `PTopup2.verity_tx_simulates_topup2_spec`. Given
three memory arrays that decode to equal-length `effective`, `pending` and
`requested` lists of at most 32 entries, the observables of `allocate` run
through `Contract.run` equal `sourceView` of the checked-word interpreter
`sourceRun`. On the committed arm those observables are genuine storage rereads:
`observe` calls `state.readArray allocSlot` and `state.readSlot` on the
remaining and used slots, so a write-noop mutant is rejected. That is a real
improvement over the earlier revision, which read the allocation column back out
of the value the transaction had already computed.

Three things in this row are solid and I would not want them lost in the
caveats. First, the checked-word plane is honest about `uint256`:
`evaluateTopUpLimit` uses `safeAdd`, `evaluateTopUpLimit_overflow` proves that an
`effective + pending` overflow is `none`, and an executable vector shows the
transaction reverting on `MAX_UINT256 + 1` where a total `Nat` model would have
produced a number. Second, `revert_restores_snapshot` shows that a failure
injected after the allocation and budget writes returns the exact pre-call
snapshot, so rollback is a proved property of the transaction rather than a
property of the observation function. Third, the vector set pins behaviour a
reviewer can check by hand: a two-validator batch sharing a 10 gwei budget
commits `[6, 4]` and not `[6, 5]`, and a second batch chained onto the first
batch's leftover cap and updated pending balances commits `[0, 0]`.

What the row does not give is the deployed enforcement path, and the registry
says so in its own classification: "do not implement the live topUp + beacon
path". On chain the gateway computes each key's headroom independently, writes
`topUpLimits[i]` in wei, and the router then takes `min(module share, per-block
cap)`, hands the array to the module's `allocateDeposits`, checks each returned
amount against its limit and the sum against the rounded depositable balance,
pulls ether from Lido and forwards it to the beacon deposit contract. The Lean
model is a single greedy left-to-right consumer of one pooled gwei budget. It
never performs the role, pause, block-distance, root-age, credential-type,
pubkey-length or SSZ checks, it never calls a module, and it never moves ether.

So the claim I would sign is this. On a gwei-denominated model of one top-up
batch, an allocator that draws from a budget already cut by the per-block cap
cannot exceed that cap, the pinned headroom formula has a checked-arithmetic
transcription that reverts on overflow rather than wrapping, and an executable
transaction persists and rereads its allocation column and rolls back cleanly on
failure. I would not tell a reader that the deployed gateway respects
`maxTopUpPerBlock`, because nothing in this row models the place where that
ceiling is actually enforced.

## B. Proof audit

**B1. `aggregate_bounded_by_block_cap`: the forall is genuine, the tautology
history is closed, and the residual content is definitional.** The retracted
parent `router_require_post_condition` really is gone. I read the retraction note
at `PTopup2.lean:203-220` and there is no such declaration in the file; the old
statement took `hEachBound` and `hSumBound` as hypotheses and returned
`⟨hEachBound, hSumBound⟩`, which is the textbook shape of a claim no mutant can
touch. The replacement is unconditional in `b` and `cfg` and its proof does work
(`consumeBudget_sum_le` is a real induction), so the "forall versus tautology"
question is settled in the right direction.

The residual weakness is different and I want it stated plainly rather than
argued away. The cap named in the conclusion is a term of the budget named in the
subject. Any function of the form `consumeBudget (min _ (min _ cap)) _` satisfies
this bound, whatever the first two arguments of the `min` mean and whatever
`candidates` computes. The theorem therefore discriminates exactly one class of
regression, namely deleting the cap from `transitionBudget`, and the kill-line
`block_cap_kill_line_refutes_parent` is correctly aimed at that class: it is the
explicit negation of the parent's own predicate shape with `mutantTransition`
substituted, which is the bar P-ALLOC-1 wave 5 and P-CONSOLIDATION-1 set. What
the parent cannot discriminate is any mutation of the headroom computation. A
model that ignored `evaluated_topup_limit` entirely and consumed the raw requests
still satisfies `sum <= cap`, so the registered abstract claim places no
constraint at all on the mapped span 396 to 415, which is the arithmetic the row
is nominally about.

The sibling that would constrain it, `aggregate_bounded_by_individual`, exists in
the file and is not registered. `audit/guarantees.yaml` names only
`aggregate_bounded_by_block_cap` in `abstract.theorem`. Worse, the on-chain
`require` is per key, not aggregate, and there is no per-key theorem at all. I
checked how expensive one would be: eighteen lines, no new machinery, reusing the
same induction.

    theorem transition_pointwise_le_limit (b : TopupBatch) (cfg : TopupConfig) (i : Nat) :
        (transition b cfg).getD i 0 <=
          (b.validators.map (fun v => evaluated_topup_limit v cfg)).getD i 0

That builds from `consumeBudget_pointwise_le` and a `zipWith`-`min` projection.
Its absence, not the shape of the aggregate bound, is the largest single gap in
the abstract plane.

Two smaller items in the same file. `aggregate_bounded_by_module_limit` takes
`well_formed_pre` and immediately discards it as `intro _h`, which makes a bound
that is unconditional look conditional on the source guards; either drop the
argument or make it load-bearing. And `candidates` is a `zipWith`, so a batch
whose `requestedGwei` is longer than its validator list silently loses the tail.
Length equality sits in `well_formed_pre` and the registered parent does not use
it, so "for every batch" includes length-mismatched batches whose extra requests
disappear rather than reverting `WrongArrayLength`.

**B2. `consumeBudget` is a policy the chain does not implement.** The definition
is three lines: `allocated := min amount budget`, then recurse on
`budget - allocated` over `Nat`. It is greedy, order-sensitive and saturating.
`sourceConsume` on words is the same walk with `safeSub`, and the source plane's
`execute` is literally `transition` with `execute_matches_pinned_transition`
proved by `rfl`, so there is one algorithm here, not three.

The chain's algorithm is not this one. The gateway publishes independent per-key
limits and the module returns the split. Concretely, two validators each with 20
gwei of headroom under a 20 gwei cap: the router accepts `[20, 0]`, `[0, 20]` and
`[10, 10]` alike, because it checks each entry against its own limit and the sum
against the cap. `transition` produces `[20, 0]` and nothing else, and
`well_formed_batch` then *rejects* `[0, 20]` as ill-formed even though it is an
in-spec on-chain outcome. The row's CHECKED cap is thus a theorem about an
allocator that is one admissible policy among many, and the guard that actually
delivers the product property, the router's own aggregate `require`, is not
modeled on any plane. The retracted tautology was groping toward the right
statement, a predicate over an arbitrary allocations array; the fix is to model
that predicate as an executed guard, not to hand it back as a hypothesis.

**B3. `A-TOPUP-NOWRAP` is now on the row, but it is P-TOPUP-1's assumption wearing
P-TOPUP-2's badge.** The row previously omitted it and now lists it, which closes
round 1 issue 26 as far as bookkeeping goes. Reading
`audit/assumptions.yaml`, though, the assumption's `risk` text names "the
unchecked uint256 accumulation at StakingRouter.sol line 732", which is not in
any P-TOPUP-2 span, and its `validation` clause requires that every consuming
theorem "retain the explicit NoUncheckedWrap premise".
`aggregate_bounded_by_block_cap` has no such premise and cannot have one, since
its whole point is to be unconditional. On this row the assumption is a label
rather than a discharged condition.

The wrap that actually matters here sits in three places on the `Nat` plane:
`evaluated_topup_limit`'s `effectiveBalanceGwei + pendingBalanceGwei`,
`consumeBudget`'s saturating subtraction, and `transitionBudget`'s
`valueWei / GWEI`. I want to be fair about the direction of the divergence,
because it is not the P-TOPUP-1 direction. In the pinned differential harness
`solidity/src/PTopup2Differential.sol`, `effectiveBalance` is a `uint64` and
`pendingBalanceGwei` is a caller-supplied `uint256`, so the only way to overflow
is an operator submitting a pending balance within `2^64` of `2^256`. Live, the
checked add reverts. On the `Nat` plane, `currentTotal` exceeds the target and
`evaluated_topup_limit` returns 0. The `Nat` model under-allocates where the
chain reverts, so this particular gap is conservative, and the checked-word plane
closes it outright via `safeAdd`, `evaluateTopUpLimit_overflow` and the
`MAX_UINT256` vector. A HIGH-severity assumption is the wrong instrument for
that.

The wrap that is not conservative is the one no plane models: the gateway's own
`unchecked` evaluation loop accumulator and the `if (totalLimits > 0)` gate on
`_setLastTopUpData`. Neither `transition` nor `sourceRun` computes `totalLimits`;
`sourceRun`'s `used` is `budget - leftover` via `safeSub`, a different quantity
reached a different way. A wrapped `totalLimits` that skips the last-top-up write
and so permits a second call in the same block is representable on chain and
unrepresentable in Lean.

**B4. The keccak oracle is inert here, and the real oracle gap is elsewhere.**
`Topup2DistributionTx.oracle` sets `mappingSlot := fun _ _ => 0` and
`keccakMemorySlice := fun _ _ _ => 0`, and `audit/guarantees.yaml` lists "keccak
memory-array oracle" under `fidelity.missing`, which reads as though a hash were
being faked inside the proof. It is not. At verity pin `a063bfc`,
`Verity/Core/Model/Denote.lean:627-633` evaluates `.memoryArrayElement` as
`state.world.memory (wordNormalize (dataOffset + 32 * idx))` and never consults
the oracle, so both constant-zero fields are dead for every read this
transaction performs. The `mappingSlot := 0` collapse that has teeth in
P-ADDRESS-1 has none here.

What is actually missing is larger than a hash. `arrayState` supplies
`name_data_offset` and `name_length` as environment bindings, so `hEff`, `hPend`
and `hReq` are assumptions that three disjoint arrays already sit at `0x1000`,
`0x2000` and `0x3000`. There is no ABI decoder and no calldata, so the live
four-array length check is modeled only as `count == 0`. On the storage side,
`Verity/Core.lean:318-322` gives `ContractState` a `storageWords : StorageKey ->
Uint256` map and a separate `storageArray : Nat -> List Uint256`, and
`persistAllocs` writes the latter while remaining and used go to the former. The
disjointness is structural, which is exactly why the proof closes with
`ContractState.storageArray_writeSlot`. So "allocations are persisted and reread"
is true of an idealized array channel that cannot alias anything, not of a
Solidity dynamic array whose data region is derived by keccak and could in
principle meet the ERC-7201 gateway namespace at `0x22e5...2200`.

One latent harness defect is worth recording even though it is currently
unreachable. `memoryFor` tests the effective range first, and the bases are 128
words apart, so at 129 or more entries `0x1000 + 32 * 128` equals `0x2000` and
`pending[0]` silently resolves to `effective[128]`. The new `hMax` bound of 32
puts that out of reach for the registered theorem and for every vector, so it is
a defect in the harness rather than a hole in the claim, but the range test
resolves overlap silently instead of rejecting it.

**B5. The `maxValidatorsPerTopUp` kill-line does not refute the registered
Verity parent.** This is the finding I would act on first. `allocate` now reverts
`MaxValidatorsPerTopUpExceeded` when `count > maxValidatorsPerTopUp`, and
`max_validators_guard_kill_line_refutes_no_check` exhibits a 33-validator batch
that the honest transaction reverts and the guard-free `allocateNoMaxCheck`
commits. Both halves are `rfl`, and as a statement about the two transactions
that is sound.

It is not a statement about the registered claim.
`verity_tx_simulates_topup2_spec` carries `hMax : requested.length <=
maxValidatorsPerTopUp` as a hypothesis, and under that hypothesis the guard
branch is unreachable, so `allocate` and `allocateNoMaxCheck` are the same
function. Substituting the mutant into the registered statement leaves a
provable statement, and it is provable *from the registered theorem itself*.
Checked:

    theorem allocate_eq_noMaxCheck_of_le ... (h : count <= maxValidatorsPerTopUp) :
        (allocate count ...).run state = (allocateNoMaxCheck count ...).run state

    theorem no_max_check_mutant_survives_registered_verity_parent ...
        (hMax : requested.length <= maxValidatorsPerTopUp) :
        observe (List.replicate requested.length 0) remainingCap
            ((allocateNoMaxCheck requested.length ...).run state) =
          sourceView effective pending requested ...

The second is discharged by rewriting with the first and applying
`verity_tx_simulates_topup2_spec`. So the guard is load-bearing for the
transaction's behaviour on inputs the registered theorem excludes, and inert
inside the registered theorem. The block-cap kill-line on the abstract plane
meets the wave-5 bar; this one does not, and `fidelity.covered` should not list
the two in the same voice.

There is a second, independent problem with this guard.
`Topup2DistributionTx.maxValidatorsPerTopUp` is `def ... : Nat := 32`, a literal.
On chain the bound is `$.maxValidatorsPerTopUp`, a `uint64` at bit offset 0 of
word 0 of the packed ERC-7201 struct, per
`audit/p-topup-2-layout-comparison.json`, and governance can set it.
`TopupPackedStorage` models that word and proves its layout
(`generated_layout_exact`) but runs no guard against it;
`Topup2DistributionTx` runs a guard against the literal and never reads the
word. No theorem connects the two models. "The validator limit is enforced" is
therefore true of the constant 32 and of nothing else, and the round-1 sentence
that 32 "matches maxValidatorsPerTopUp" is a coincidence with whatever the
deployment happens to store.

**B6. The Verity plane is lockstep, and I can now quantify how lockstep.** Round
1 recorded that `txRun` calls the source functions and that the equality is
`rfl`. The current shape is tighter than that description and looser than it
sounds: `allocate` calls `sourceRun`, `sourceView` is *defined* by `sourceRun`,
so the registered equality relates two uses of one function. To measure what it
constrains, I generalized the transaction and the view over an arbitrary run
function and reproved the parent's script:

    theorem verity_tx_simulates_any_run (run : RunFn)
        (hEmpty : forall e p r t m rc ml v, e.length = 0 -> run e p r t m rc ml v = none)
        ... : observe ... ((allocateGen run ...).run state) = sourceViewGen run ...

It goes through unchanged. The only property of the pinned interpreter the
correspondence uses is that an empty batch is `none`. Everything else that
`sourceRun` computes, the headroom formula, the `minTopUp` test, the budget
`min`, the leftover walk, is invisible to the registered Verity claim. I
instantiated this at `mutantRunNoLimit`, which drops the per-validator headroom
and consumes the raw requests, and derived the parent's exact shape for it:

    theorem no_limit_mutant_survives_registered_verity_shape ... :
        observe ... ((allocateGen mutantRunNoLimit requested.length ...).run state) =
          sourceViewGen mutantRunNoLimit effective pending requested ...

That mutant is a real bug, not a bookkeeping change. On `effective = [64]`,
`target = 64`, `requested = [10]`, the pinned interpreter allocates `[0]` and the
mutant allocates `[10]`, topping up a validator that is already at its target
balance. Both were confirmed by `native_decide`. So the Verity CHECKED cell
certifies the plumbing, that is decode, persist, reread, revert-condition
agreement and rollback, and exactly one semantic property of the interpreter it
is paired with.

Two smaller notes on the same theorem. On the reverted arm the equality is
`⟨reverted, replicate n 0, remainingCap, 0⟩` on both sides, since `observe`'s
revert case returns its own `beforeAllocs` and `beforeRemaining` arguments and
the facade passes exactly those two values; the content of that arm is the
agreement of revert conditions, not anything about state. The actual rollback
fact is `revert_restores_snapshot`, which `fidelity.covered` claims and
`guarantees.yaml` does not register. And the block cap does not appear in the
registered Verity theorem at all: `sourceRun`'s budget is
`minWord valueGwei (minWord moduleLimit remainingCap)`, where `remainingCap` is a
caller word with no theorem tying it to any configured value, and the packed
gateway struct does not even contain a per-block cap field, because that value
lives on the router. A cap *is* enforced incidentally, since `sourceRun` returns
`some` only when `safeSub remainingCap used` succeeds, but that is arithmetic
bookkeeping rather than a modeled `require`, and no theorem states it. The two
CHECKED cells on this row are therefore about different objects: one bounds by a
config field, the other never mentions a cap.

**B7. Not live `topUp` plus beacon, and the row is honest about it.** I checked
`fidelity.missing` against the Lean and it is accurate: `_verifyValidator`, the
module credential type, block distance, root age, the live independent per-key
limits and `allocateDeposits`, `withdrawDepositableEther` and
`makeBeaconChainTopUp`, gwei versus wei, 48-byte pubkeys, the array oracle, and
the trusted `pendingBalanceGwei`. The classification's instruction not to
implement the live path is a defensible scope decision and I am not asking for it
to be reversed. Three consequences of it should be more visible than they are.

First, `audit/source-map.yaml` maps `CLValidatorVerifier._verifyValidator` 44 to
57 to this guarantee, and no registered theorem executes or even assumes it. The
source map advertises coverage the theorems do not have, and the span should be
marked mapped-but-not-modeled rather than simply MAPPED.

Second, the seam to P-TOPUP-1 is unproved and very easy to over-read.
`PTopup1.source_topup_conserves_and_rolls_back` takes `inp.topUpLimits` and
`inp.allocations` as free inputs. No theorem states that P-TOPUP-2's `transition`
or `sourceRun` output is that array, or that it satisfies
`allocations[i] <= topUpLimits[i]`. "Gateway limits, then router conservation,
then beacon deposit" is not a chain of theorems, it is two disjoint models joined
by prose. P-CONSOLIDATION-1 already carries an explicit "do not compose with
P-ETH-1" line; this row needs the analogous line for P-TOPUP-1.

Third, `audit/P-TOPUP-2-CORRESPONDENCE.md` is now stale in both directions and
contradicts the tree it documents. It says "the source reverts when
`effectiveBalance + pendingBalanceGwei` overflows uint256. The Nat model does
not. Parent SOURCE and TX stay OPEN", but the checked-word interpreter does
revert on that overflow and the registry has since promoted the row to CHECKED.
It also describes the Verity plane as packed `UIntN` setters plus a synthetic
`recordBudget` transaction, which is `TopupPackedStorage`, not the registered
`Topup2DistributionTx`. Its layout and runtime sections are still sound, and I
agree with their two warnings, that the committed `matches` bit is self-reported
and that matching mainnet runtime at block 25,730,798 is deployment provenance
rather than Solidity-to-Verity correspondence.

**Ranked recommendations.** Ordered by how much claim integrity each buys per
unit of change.

1. Fix the `maxValidatorsPerTopUp` kill-line so it bears on the registered claim.
   The cheapest form is to fold the guard into the parent as a conjunct,
   `(maxValidatorsPerTopUp < count -> allocate ... = .revert "MaxValidatorsPerTopUpExceeded" state)`,
   which is the same move P-TOPUP-1 made in its wave 2. Until then, stop listing
   it in `fidelity.covered` next to the block-cap kill-line, which is correctly
   targeted.
2. Register a per-key bound. `transition_pointwise_le_limit` above is eighteen
   lines and is the only statement on this row that would constrain the mapped
   `_evaluateTopUpLimit` span. Consider registering it and
   `aggregate_bounded_by_individual` as conjuncts of the parent, so that a
   headroom-blind mutant is refuted rather than tolerated.
3. Give the Verity plane a cap statement, or stop reading the Verity cell as
   cap evidence. Bind `remainingCap` to a modeled configuration word and prove
   `used <= remainingCap`, and say in the row summary that the per-block cap on
   this plane is a caller argument.
4. Split `A-TOPUP-NOWRAP`. P-TOPUP-2 needs its own assumption naming
   `evaluated_topup_limit`, `consumeBudget` and `valueWei / GWEI`, stating that
   the divergence is conservative for the headroom gap, and listing the
   gateway's `unchecked` `totalLimits` accumulator and the
   `if (totalLimits > 0)` gate as unmodeled on both planes. Reusing
   P-TOPUP-1's router-line-732 text here is misleading in both directions.
5. Refresh `audit/P-TOPUP-2-CORRESPONDENCE.md`. Its Checked and Open sections
   describe a superseded Verity plane and an overflow gap the word plane now
   closes.
6. Read `maxValidatorsPerTopUp` from the packed slot, or state on the row that
   the guard is against the literal 32 and that a governance change to that
   `uint64` is unrepresented.
7. Add the explicit non-composition line for P-TOPUP-1, and either model the
   router's per-key and aggregate `require` over an arbitrary allocations array
   or say in the summary that `consumeBudget` is a policy the chain does not
   implement.
8. Reword the `fidelity.missing` entry "keccak memory-array oracle". The oracle
   is inert for every read this transaction performs; the honest entries are the
   harness-supplied array bindings, the absent ABI length check, and the
   idealized `storageArray` channel.
9. Housekeeping: drop the unused `well_formed_pre` argument from
   `aggregate_bounded_by_module_limit`, and either reject length-mismatched
   batches in `candidates` or note that the `zipWith` truncates. Harden
   `memoryFor`'s overlapping bases, which are currently masked by `hMax`.

## Auditor note (round 1)

P-TOPUP-2 proves that the total top-up allocated from the leftover budget never exceeds maxTopUpPerBlockGwei:

transition.sum <= maxTopUpPerBlockGwei

This bound holds without assuming well_formed. The cap is enforced by the transition itself, not borrowed from a global state invariant.

On the Verity side, allocate persists the accepted allocation. It reverts when the batch contains more than 32 validators, matching maxValidatorsPerTopUp.

The kill-lines test both controls. Removing the block cap permits an aggregate above the per-block limit. Removing the validator-count guard permits a batch of 33 validators.

The governing theorem is aggregate_bounded_by_block_cap.

## Proof issues and recommendations

The abstract theorem quantifies over every batch and configuration. The Verity model is narrower: the validator limit is the constant 32, not a universally quantified configuration value.

The proof does not cover _verifyValidator, withdrawal credentials type 0x02, or the live allocateDeposits integration.


Theorems: `PTopup2.aggregate_bounded_by_block_cap` (parent), `PTopup2.verity_tx_simulates_topup2_spec`.
Assumptions: `A-SOURCE-SHAPED`, `A-TOPUP-NOWRAP`, `A-VERITY-SCAFFOLD`.

## Intent

Electra compounding validators can be topped up through `TopUpGateway.topUp` (`TopUpGateway.sol` 160–237) after SSZ-witnessed CL state, type-0x02 credentials, activation, sort-order, root-age, and `TOP_UP_ROLE` checks. Each validator’s allowed top-up is `_evaluateTopUpLimit` (396–415): 0 if slashed/exiting or already at target, else the gap if it is at least `minTopUp`. The batch is then cut by `msg.value / 1 gwei`, the module’s remaining share, and `maxTopUpPerBlock`. The intended guarantee: the gwei actually allocated in one call cannot exceed the per-block cap (and, separately, the module limit).

## Modeling

- `A-SOURCE-SHAPED`. `PTopup2.Validator` is a record of Nats/Bools. No SSZ witness, no EIP-4788 beacon root, no pubkey bytes, no `CLValidatorVerifier`.
- `A-VERITY-SCAFFOLD`: `Contract.run` is a non-certified Verity 4.31 interpreter.
- `evaluated_topup_limit` is unbounded `Nat` addition. Solidity `effective + pending` is checked `uint256` and reverts on overflow. The file says so (`PTopup2.lean:31–34`). `audit/P-TOPUP-2-CORRESPONDENCE.md` still records “Parent SOURCE and TX stay OPEN” for that reason — the YAML now says CHECKED anyway.
- `well_formed_batch` *includes* `b.allocations = transition b cfg` as a conjunct, plus: wc = 0x02, activated, not slashed/exiting, strictly increasing indices, unique pubkeys, length caps, root age, gwei-aligned value. Those extra conjuncts are **not used** by `aggregate_bounded_by_block_cap` except the transition equality.
- Verity `Topup2DistributionTx` reads three memory arrays (effective, pending, requested) and a numeric budget. It does not model `onlyRole`, pause, root age, or witnesses.
- `txRun` calls `sourceCandidates` and `sourceConsume` (`Topup2DistributionTx.lean:74–78`). `txRun_eq_sourceRun` is `rfl`.

## Proof

**Abstract `aggregate_bounded_by_block_cap` (parent).** Unconditional in `b`/`cfg`: `(transition b cfg).sum ≤ cfg.maxTopUpPerBlockGwei`. From `consumeBudget_sum_le`: induction over the left-to-right leftover-budget walk shows the sum is ≤ the budget it was given, then `transitionBudget`'s `min _ (min _ blockCap) ≤ blockCap` closes it. The same skeleton gives `aggregate_bounded_by_module_limit` and `aggregate_bounded_by_individual`. The theorem's content is in the induction, not in a restated hypothesis, so it is non-vacuous: it constrains the actual output of `consumeBudget`/`candidates`, not an arbitrary `alloc` handed in by the caller.

*Kill-line (`block_cap_kill_line_refutes_parent`, `Topup2DistributionTxMutants.lean`).* `mutantTransition` runs the identical `consumeBudget` walk against a mutant budget that drops the `maxTopUpPerBlockGwei` term from `transitionBudget`'s `min` — the Lean analogue of a router that dropped its block-cap `require`. Two validators each independently eligible for 20 gwei (`evaluated_topup_limit = target(32) - effective(12) = 20`), each requesting 10 gwei, both clear the uncapped 100-gwei mutant budget in full: the walk commits `[10, 10]`, summing to 20 against `maxTopUpPerBlockGwei = 10`. `¬ ∀ b cfg, (mutantTransition b cfg).sum ≤ cfg.maxTopUpPerBlockGwei` is proved from this witness, and the file also shows the *real* `aggregate_bounded_by_block_cap` still holds on that same `b`/`cfg` pair — the cap term in `transitionBudget` is exactly what the mutant is missing.

**Retracted `router_require_post_condition` (Wave 1 review).** A prior revision registered a different parent: unconstrained `alloc`/`limits`, hypotheses `hEachBound : ∀ i, alloc[i] ≤ limits[i]` and `hSumBound : alloc.sum ≤ min share cfg.maxTopUpPerBlockGwei`, conclusion `⟨hEachBound, hSumBound⟩`. The conclusion is syntactically identical to the hypotheses — a pure tautology, true for any `alloc`/`limits`/`share` including ones no execution of `transition` could produce — and does not mention `transition`, `consumeBudget`, or `evaluated_topup_limit` at all. Its "kill-line mutant" fed concrete numbers into that same restated conclusion directly, never through the theorem, so it refuted a general `Nat` fact rather than the registered parent. It has been removed rather than restated (see `PTopup2.lean` for the retraction note), and `aggregate_bounded_by_block_cap` is registered again, now with the mutant-budget kill-line above closing the gap that made it vulnerable to being swapped out in the first place.

**VERITY `verity_tx_simulates_topup2_spec`.** Decode three arrays of equal length, run `txRun` (= `sourceRun` by `rfl`), write allocations and remaining/used slots, compare `observe` to `sourceView`. Rollback via `Contract.run` and `failAfterWrites`. Unaffected by the parent swap above: it was never `router_require_post_condition`'s Verity plane.

## Issues

## Resolution

**2026-08-20 Wave2 — Verity allocation persistence and block-cap binding:** Enforced `count ≤ maxValidatorsPerTopUp (32)` in `Topup2DistributionTx.allocate` as checked revert `MaxValidatorsPerTopUpExceeded` before decoding; updated `verity_tx_simulates_pinned_source` and `verity_tx_simulates_topup2_spec` to require `requested.length ≤ maxValidatorsPerTopUp` and proved equivalence via `Nat.not_lt.mpr`; added mutant `allocateNoMaxCheck` without guard and kill-line `max_validators_guard_kill_line_refutes_no_check` showing honest reverts a 33-validator batch (effective 32, pending 0, requested 1, target 64, remainingCap 100) while mutant commits `[1;33]` with remaining 67 / used 33; `observe` still rereads `state.readArray allocSlot`/`readSlot` persistence, now load-bearing for the new guard. YAML `fidelity.covered` now names the new observable; `fidelity.missing` stays honest.

**Wave 2 (2026-08-18 fix): retracted a tautological parent.** The Wave 1 revision that registered `router_require_post_condition` conjoined the per-validator and aggregate-sum hypotheses and handed them straight back as the conclusion, so the "parent" held for any `alloc`/`limits` and its kill-line mutant never actually applied the theorem — it checked a `Nat` fact about hand-picked numbers instead. `router_require_post_condition` is removed. `aggregate_bounded_by_block_cap` — unconditional in `b`/`cfg`, proved by induction over `consumeBudget` — is the registered parent again, and its non-vacuity now has an explicit witness: `block_cap_kill_line_refutes_parent` shows a mutant that drops `maxTopUpPerBlockGwei` from `transitionBudget`'s `min` lets the identical leftover-budget walk exceed the cap, using the same two-validator numbers the retracted kill-line used, now driven through the real `consumeBudget`/`candidates` functions.

**Restated Lean/English.** `aggregate_bounded_by_block_cap` no longer takes unused `well_formed_pre`. An ill-formed batch still has `transition.sum ≤ cap`.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1 | B | `well_formed_pre` split; registered cap is about `transition`. |
| 2, 8 | A | Lockstep / leftover-walk plane named honestly. |
| 3, 9, 13, 14, 7, 15, 24 | scope | Executed SSZ/role/distance/slash/activation/`maxValidators` in `missing`. |
| 4, 20, 26 | A | `A-TOPUP-NOWRAP` now on the row. |
| 5, 6, 12 | A | Two planes; `observe` reads result allocations. |
| 10, 11, 16–19, 21–23, 25, 27–31 | scope | WC, budget name, leftover vs independent limits, units, beacon pull, packed model in `missing`. |


1. **The headline bound assumes the result it proves.**
   `well_formed_batch` requires `b.allocations = transition b cfg`, and `transition` is `consumeBudget` of a budget that is already `min(…, maxTopUpPerBlockGwei)`. Then `sum allocations ≤ blockCap` is `consumeBudget_sum_le`. Any list already defined to be the leftover-budget walk is bounded by that budget.

   *Counterexample to reading this as a property of TopUpGateway.* Construct `b` with `allocations = [10^18]`, `maxTopUpPerBlockGwei = 1`. `well_formed_batch` is false (transition would have allocated 1), so the theorem does not apply. The *deployed* gateway (`TopUpGateway.sol:226–232`) writes **independent** `topUpLimits[i] = _evaluateTopUpLimit(...) * 1 gwei` and sums them; it never walks a leftover budget. A bug that skipped the later router `sum ≤ cap` check would produce exactly that `b`. The CHECKED theorem cannot see the bug because such an output is excluded by the hypothesis, not refuted by the code.

2. **`txRun` is not independent of `sourceRun`.**
   The comment (`Topup2DistributionTx.lean:67–68`) says the correspondence theorem is the boundary. The definition calls `sourceCandidates` / `sourceConsume` and the equality is `rfl`.

   *Counterexample to independence.* Change `gap < minTopUp` to `gap ≤ minTopUp` inside `sourceEvaluateLimit` (or the helper `sourceCandidates` calls). Both `txRun` and `sourceRun` change; `txRun_eq_sourceRun` remains `rfl`. The CHECKED equality cannot see a shared off-by-one on the min-top-up test.

3. **SSZ / activation / 0x02 / role / root-age are hypotheses, not executed guards.**
   `well_formed_batch` *assumes* wc = 0x02, activated, not slashed/exiting, sorted unique indices, fresh beacon root. `TopUpGateway.topUp` *enforces* those or reverts. Scenario: a caller without `TOP_UP_ROLE` or with a failed Merkle proof. Live gateway reverts. The Nat model never sees the caller; a well-formed batch can still be written down and the cap theorem applies to it. The Verity tx likewise has no role check — it will allocate if the arrays decode.

4. **Nat vs checked addition (documented, still CHECKED).**
   *Scenario.* Validator with `effectiveBalanceGwei = 2^256 − 1`, `pendingBalanceGwei = 1`. Solidity reverts in `_evaluateTopUpLimit`. `evaluated_topup_limit` computes `currentTotal = 2^256`, then `≥ target` or a wrap-free Nat gap. The abstract cap theorem still holds of the Nat numbers. `audit/P-TOPUP-2-CORRESPONDENCE.md` called this a reason to keep SOURCE/TX OPEN. Promoting the row to CHECKED does not remove the mismatch.

5. **No theorem that the Verity allocations satisfy `well_formed_batch`.**
   Different types (`Word` lists vs `TopupBatch`). `verity_tx_simulates_topup2_spec` never mentions `maxTopUpPerBlockGwei`.

   *Scenario.* Call `allocate` with `remainingCap = moduleLimit = valueGwei = 10^18`. It commits `used` up to that budget. A configured on-chain `maxTopUpPerBlock` of 1 gwei is not an input unless the harness happens to pass it. CHECKED Verity does not imply the abstract cap.

6. **`observe` on revert reports caller-supplied `beforeAllocs`, not storage.**
   *Scenario.* `failAfterWrites = true` after `writeAllocs`. `Contract.run` restores the snapshot (monad). `observe` on revert returns the `beforeAllocs` argument (`List.replicate n 0` in the facade), not a storage read. A mutant that skipped `Contract.run` and left dirty maps would still present a clean View if someone only looked at `observe`.

7. **Slash / exit is dropped on the executed plane.**
   Abstract `evaluated_topup_limit` returns 0 if `v.exiting || v.slashed`. Source/Verity `sourceEvaluateLimit` (`Topup2Correspondence.lean:67–72`) is only `effective + pending` vs target / minTopUp — no slash flag. The comment says this is “after activation/exit/slash filters,” i.e. those filters are assumed, not executed.

   *Counterexample.* One slashed validator, `effective = pending = 0`, `target = 32e9`, `minTopUp = 1`, `requested = remainingCap = moduleLimit = valueGwei = 32e9`. Solidity `_evaluateTopUpLimit` (`TopUpGateway.sol:403–404`) returns 0. `sourceRun` / `allocate` commit allocation `32e9`. `well_formed_batch` hides this by *requiring* `slashed = false`, so the abstract theorem never sees the case; Verity never sees the flag.

8. **The registered Verity theorem is not `Topup2Tx`’s call-program plane.**
   `Verity/Topup2Tx.lean` is an adversary-quantified `CallProgram` / `CallsIn` model that actually talks about wei on call sites (`tx_aggregate_bounded_by_block_cap`). YAML points at `PTopup2.verity_tx_simulates_topup2_spec` → `Topup2DistributionTx`, the array/`consumeBudget` script. The module header of `Topup2Tx` even records a *retracted* `tx_revert_has_failed_call` that was discharged by fabricating an unconstrained `CallObservation`.

   *Scenario.* A reader follows the CHECKED Verity name expecting “every adversary’s paid CALL sum ≤ block cap.” That lemma is not the registered theorem. The registered one never mentions an adversary or a CALL value.

9. **Mapped `_verifyValidator` (CLValidatorVerifier 44–57) is not executed.**
   `audit/source-map.yaml` lists that span for P-TOPUP-2. Neither `evaluated_topup_limit` nor `sourceEvaluateLimit` nor `allocate` calls it. Witnesses are trusted fields / absent.

   *Scenario.* A top-up with a forged Merkle proof. Live `TopUpGateway.topUp` reverts in `_verifyValidator`. Lean `verity_tx_simulates_topup2_spec` still allocates if the three numeric arrays decode. The mapped verifier span is not a premise of the CHECKED theorem.

10. **Type-0x02 is a per-validator field in Lean and a per-module field on chain.**
   `well_formed_batch` requires `v.wc = 0x02` for each `Validator`. Live `TopUpGateway.topUp` reads **one** `stakingRouter.getStakingModuleWithdrawalCredentials(moduleId)` and `_requireWithdrawalCredentials02`. `sourceEvaluateLimit` / `allocate` have no WC field at all.

   *Scenario.* Module WC is 0x01. Live top-up reverts `WrongWithdrawalCredentials`. Lean `allocate` on effective/pending/requested still commits. The abstract `wc = 0x02` conjunct is unused by `aggregate_bounded_by_block_cap` anyway.

11. **`valueWei` is the wrong resource; the gateway is not payable.**
   `TopUpGateway.topUp` is `onlyRole` / `whenResumed` and pulls from `LIDO.getDepositableEther()` after the **module** runs `allocateDeposits`. Lean treats `valueWei / GWEI` as a left-to-right `consumeBudget`.

   *Scenario.* Attacker sends `msg.value` to the gateway (it is non-payable → revert) or a module `allocateDeposits` returns a permutation that is *not* left-to-right greedy. Live `StakingRouter.topUp` (lines 696–718) takes `min(moduleShare, maxTopUpPerBlockWei)`, rounds to gwei, then calls `IStakingModuleV2(moduleAddress).allocateDeposits(...)`. The module, not the gateway, picks per-key amounts. The router only checks `allocations[i] ≤ limits[i]` and `sum ≤ smDepositableEthAmountRounded`. The CHECKED `consumeBudget` walk is not that algorithm; CSM queue-cursor advancement on a zero budget is unmodeled.

12. **`observe` on success reports `result.allocations`, not the allocation map.**
   `Topup2DistributionTx.observe` (`:140–145`) copies `result.allocations` from the value `allocate` built after `txRun`. Only remaining/used are `readSlot`.

   *Counterexample mutant.* Make `writeAllocs` a no-op. `verity_tx_simulates_topup2_spec` still holds. YAML “persists allocations through writeMapUint” is not an observed fact for the allocation column.

13. **`_requireBlockDistancePassed` is unmodeled.**
   Live `topUp` (`:179`) reverts `MinBlockDistanceNotMet` if not enough blocks since `_setLastTopUpData`. `well_formed_batch` has no block-distance field. `allocate` has no last-top-up timestamp.

   *Scenario.* Two `topUp` calls in the same block with `minBlockDistance ≥ 1`. Live second call reverts. Lean `allocate` twice (or two-batch mutant) commits both. The CHECKED tx does not implement the frequency guard.

14. **`RootPrecedesLastTopUp` is not in `well_formed_batch`.**
   Live `_verifyRootAge` (`:385–386`) reverts if `childBlockTimestamp <= lastTopUpTimestamp`. Abstract `well_formed_batch` only has `beaconRootTimestamp ≤ currentTimestamp` and `current − beacon ≤ maxRootAge`. No last-top-up timestamp.

   *Scenario.* Beacon root is fresh vs `maxRootAge` but older than the last top-up. Live `topUp` reverts `RootPrecedesLastTopUp`. A `well_formed_batch` can still be written and `aggregate_bounded_by_block_cap` applies. The CHECKED cap theorem does not know about last-top-up ordering.

15. **Activation is not on the executed plane.**
   Live `_verifyValidatorWasActivated` (`TopUpGateway.sol:390–393`) reverts if `activationEpoch > current epoch`. `evaluated_topup_limit` does not look at `activated`. `sourceEvaluateLimit` has no epoch. `well_formed_batch` requires `activated = true` and then ignores it in the cap proof.

   *Scenario.* Validator with `activationEpoch = FAR_FUTURE`, `effective = pending = 0`, `target = 32e9`, request 32e9. Live `topUp` reverts `ValidatorIsNotActivated`. Lean `allocate` commits 32e9. Same shape as the slash hole: the abstract hypothesis excludes the case; Verity never sees the flag.

16. **Same dummy memory oracle as P-ALLOC-2.**
   `Topup2DistributionTx.oracle` is `mappingSlot := fun _ _ => 0`. Arrays are planted at `0x1000` / `0x2000` / `0x3000`.

   *Scenario.* Premises `hEff` / `hPend` / `hReq` assume `readArray` already returned the three lists. A different memory layout (real ABI) would not satisfy those premises, so the CHECKED equality does not apply to a compiled `topUp` call.

17. **`consumeBudget` is saturating `Nat` subtraction, not a checked leftover walk.**
    `consumeBudget` (`PTopup2.lean:60–64`) does `min amount budget` then `budget - allocated`. `Nat.sub` saturates. Combined with issue 4 (Nat vs checked add on the gap), a `requestedGwei` entry larger than `2^256` is a legal `Nat` and is silently clamped.

    *Scenario.* `requestedGwei = [2^256]`, `budget = 32e9`. `consumeBudget` allocates `32e9` and continues. Solidity `_evaluateTopUpLimit` / `+=` on `uint256` would revert on the overflowed effective+pending that produced such a request, or the ABI would have wrapped the word already. The CHECKED leftover walk is not a `uint256[]` consumption.

18. **Per-key limits are independent on chain and a leftover walk in Lean.**
    Extends issue 1 to the executed plane. Live `TopUpGateway.sol:226–232` sets `topUpLimits[i] = _evaluateTopUpLimit(...) * 1 gwei` independently, then the router checks each `allocations[i] ≤ limits[i]` and `sum ≤ cap`. `transition` / `txRun` walk leftover budget left-to-right, so key `i+1` is cut because key `i` took the cap.

    *Counterexample.* Two validators, each independently eligible for 20 gwei, `maxTopUpPerBlockGwei = 20`. Live limits `[20, 20]`; module `allocateDeposits` may return `[20, 0]` or `[10, 10]` (module policy); router accepts either if `sum ≤ 20`. Lean `consumeBudget` forces `[20, 0]`. A module that returned `[0, 20]` is in-spec on chain and is not `transition`. `well_formed_batch` then *rejects* that in-spec output (issue 1). The CHECKED cap theorem is a property of a different allocator.

19. **`pendingBalanceGwei` is unauthenticated calldata; Lean treats it as a trusted word.**
    Live `_evaluateTopUpLimit(vw, _topUps.pendingBalanceGwei[i])` (`TopUpGateway.sol:226, 396–415`) takes pending from the `TopUpData` array. The SSZ witness supplies `effectiveBalance`; pending is **not** a CL field and is not `_verifyValidator`’d. `sourceEvaluateLimit` / `allocate` take a `pending` word with the same status as `effective`.

    *Scenario.* Operator submits `pendingBalanceGwei[i] = 0` for a validator that already has 16 ETH in-flight deposits. Live limit is `target − effective` (too large). `allocateDeposits` may send another 16 ETH and overshoot the target once pending lands. Lean `sourceRun` with the same lie commits the same inflated gap. The CHECKED limit is “gap vs the numbers you handed me,” not “gap vs CL + known pending.” Inflating pending shrinks the limit (self-DoS); deflating it is the over-allocation.

20. **Live `totalLimits +=` sits in `unchecked`; Lean uses `safeAdd` / `Nat`.**
    `TopUpGateway.sol:203–228` wraps the evaluation loop in `unchecked`, including `totalLimits += topUpLimits[i]`. `sourceConsume` / `sourceRun` use `safeSub` / `safeAdd` (`Topup2Correspondence.lean:75–108`). Abstract `consumeBudget` is unbounded `Nat`.

    *Counterexample.* Contrived limits whose wei sum exceeds `2^256 − 1`. Live `totalLimits` wraps (then `if (totalLimits > 0)` may be false and `_setLastTopUpData` is skipped, while `stakingRouter.topUp` still received the unwrapped per-key array). Lean `sourceRun` returns `none` on `safeAdd` overflow, or `Nat` addition stays exact. Practical batches cannot hit this (32 × 2048 ETH ≪ `2^256`); the CHECKED correspondence is still not the `unchecked` loop. The later router `sum ≤ cap` is not in `sourceRun` at all (issue 11).

21. **Lean allocations are gwei; live `topUpLimits` are wei.**
    Live line 226: `topUpLimits[i] = _evaluateTopUpLimit(...) * 1 gwei`. `sourceRun` / `allocate` stay in gwei (`valueGwei`, `target`, `minTopUp`, result `used`). The router then consumes wei.

    *Scenario.* One validator, gap 32e9 gwei (32 ETH). Lean `allocate` commits `used = 32e9`. Live writes `32e9 * 1e9 = 32e18` wei into `stakingRouter.topUp`. Comparing the CHECKED `used` word to the on-chain `topUpLimits[i]` is a `10^9`× disagreement. Feeding Lean’s number into the router as wei would top up 32 gwei, not 32 ETH. The CHECKED Verity column is not the array the router sees.

22. **`well_formed_batch` does not require 48-byte pubkeys.**
    Live `topUp` (`:208–210`) reverts `WrongPubkeyLength` unless `vw.pubkey.length == PUBKEY_LENGTH` (48). Abstract `Validator.pubkey` is an unconstrained `ByteArray`. `well_formed_batch` asks wc/activated/slash/exit, sorted unique indices, and `pubkeys.Nodup` — not length 48. `sourceEvaluateLimit` / `allocate` have no pubkey field.

    *Scenario.* Validator with `pubkey = #[]` (or 96 bytes), otherwise well-formed, gap 32e9. Live reverts. Lean `allocate` on the numeric arrays commits 32e9. `aggregate_bounded_by_block_cap` still applies to a `well_formed_batch` with empty pubkeys. The CHECKED cap theorem is silent on the length guard the gateway actually runs first.

23. **A packed ERC-7201 gateway model exists and is not the CHECKED theorem.**
    `Verity/TopupPackedStorage.lean` binds `GATEWAY_STORAGE_POSITION = 0x22e5…2200` and packed `Uint64`/`Uint32`/`Uint16` fields (`maxValidatorsPerTopUp`, `lastTopUpTimestamp`, `minBlockDistance`, `targetBalanceGwei`, …). Its header says it starts *after* the source guards and does not close SOURCE/TX. YAML CHECKED points at `verity_tx_simulates_topup2_spec` → `Topup2DistributionTx` (toy memory arrays, no packed slot).

    *Scenario.* Change `minBlockDistance` in the packed contract; `verity_tx_simulates_topup2_spec` is unchanged (no such field). The frequency guard (issue 13) lives in the unused packed model as a *slot*, still not as a check. CHECKED “Verity of topUp” is the leftover-budget script, not the ERC-7201 layout the gateway actually stores.

24. **`maxValidatorsPerTopUp` is not a Verity guard.**
    Live `topUp` (`:174–176`) reverts `MaxValidatorsPerTopUpExceeded` when `validatorsCount > $.maxValidatorsPerTopUp`. Lean `allocate` reverts only on `count == 0`. `maxValidatorsPerCall` exists on `well_formed_batch` and is unused by `aggregate_bounded_by_block_cap`; `allocate` does not take the field.

    *Scenario.* `maxValidatorsPerTopUp = 2`, three eligible keys, each gap 1 gwei, budget 3. Live reverts. Lean `allocate 3 …` commits `[1, 1, 1]`. The executed CHECKED tx allocates a batch the gateway rejects before `_evaluateTopUpLimit`.

25. **Same 128-word memory alias as P-ALLOC-2.**
    `Topup2DistributionTx.memoryFor` plants effective at `0x1000`, pending at `0x2000`, requested at `0x3000`. Length `≥ 129` makes `0x1000 + 32·128 = 0x2000`: pending[0] reads as effective[128].

    *Counterexample.* 129 validators, `effective[128] = 99`, `pending[0] = 0`. `readArray "pending"` returns a list whose head is `99`. `hPend` fails, or a raw `allocate` evaluates the wrong gap. Live `uint256[]` pending is a separate calldata array. Combined with issue 16 (dummy oracle), the CHECKED decoder is a layout that is false above 128 keys (`maxValidatorsPerTopUp` is typically much smaller — issue 24 — but the decoder does not know that).

26. **`A-TOPUP-NOWRAP` is HIGH and not on this row.**
    `audit/assumptions.yaml` accepts `A-TOPUP-NOWRAP`: unbounded `Nat` matches Solidity only when the sum stays below `2^256`. It is listed on P-TOPUP-1, not on P-TOPUP-2 (`guarantees.yaml` assumptions are only `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`). Issue 4 is exactly that wrap: `evaluated_topup_limit` / `consumeBudget` are `Nat`; live `_evaluateTopUpLimit` / `* 1 gwei` / `totalLimits +=` (unchecked) are words.

    *Scenario.* `effective + pending` overflows `uint256`. Live reverts. Lean Nat gap is well-defined and `aggregate_bounded_by_block_cap` holds. The campaign already named this risk HIGH and asked every consuming theorem to keep an explicit NoUncheckedWrap premise. The CHECKED P-TOPUP-2 theorems do not. Promoting the row to CHECKED dropped the assumption rather than discharging it.

27. **Gwei alignment is only an abstract `well_formed` conjunct.**
    Abstract `well_formed_batch` requires `valueWei % GWEI = 0`. Live `topUp` is not payable and has no `valueWei`; it writes wei via `* 1 gwei` (issue 11, 21). `allocate` / `sourceRun` take `valueGwei` already divided; there is no `% 10^9` check.

    *Scenario.* Harness passes `valueGwei = 32e18` thinking it is wei. Lean treats it as 32e18 gwei (~32 million ETH) and allocates up to that budget. Combined with issue 21, the CHECKED Verity column has no alignment guard the abstract theorem pretends to have, and the live function never saw a `valueWei` field at all.

28. **One `count` is used for all three arrays; short memory reads as 0.**
    Live `topUp` (`:163–171`) reverts `WrongArrayLength` unless four arrays plus witnesses all have the same nonzero length. Lean `allocate count` (`Topup2DistributionTx.lean:112–117`) reads `count` words from each of three bases. `memoryFor` returns 0 outside the planted range. A short `requested` list is padded with zeros, not rejected.

    *Scenario.* `count = 3`, planted `requested = [10, 10]` (two words). `readArray "requested"` returns `[10, 10, 0]`. `txRun` treats the third validator as requesting 0 and may still allocate the first two. Live would have reverted before evaluation. Combined with issue 25 (128-word alias), the CHECKED decoder can invent trailing zeros instead of `WrongArrayLength`.

29. **Router `amount += allocations[i]` is `unchecked`; Lean `safeSub`s leftover.**
    Live `StakingRouter.topUp` (`:722–734`) sums module-returned wei in `unchecked`, then requires each `allocations[i] % 1 gwei == 0` and `allocations[i] ≤ _topUpLimits[i]`. `sourceConsume` uses `safeSub` on gwei words and has no wei-alignment test on the output.

    *Counterexample.* Module returns `[1]` wei (not gwei-aligned). Live reverts `AmountNotAlignedToGwei`. Lean `allocate` never sees the module return; it *is* the leftover walk (issue 18). A 1-wei allocation is unrepresentable as a Lean gwei word that came from `consumeBudget`. Combined with issue 20 (gateway `totalLimits +=` also unchecked), both live sums that the CHECKED row claims to simulate are wrapping loops, and the executed Lean tx is a different algorithm in a different unit.

30. **`withdrawDepositableEther` + `makeBeaconChainTopUp` are not in `allocate`.**
    After the module returns, live router (`:741–755`) pulls ETH from Lido (`withdrawDepositableEther(amount, 0)` — P-RESERVE-1’s spend) and `BeaconChainDepositor.makeBeaconChainTopUp`, then `assert`s the router’s ETH is unchanged. Lean `allocate` writes a gwei map and remaining/used slots.

    *Scenario.* Module returns 32e18 wei. Live pulls 32 ETH from the Lido buffer and deposits it to the beacon deposit contract with 0x02 WC. Lean `verity_tx_simulates_topup2_spec` commits `used = 32e9` (gwei) and never moves ETH. A bug that pulled and then failed to deposit (assert would fire) cannot appear. The CHECKED “top-up” is not a deposit.

31. **Live `_setLastTopUpData` runs only when `totalLimits > 0`.**
    `TopUpGateway.sol:234–236`: `if (totalLimits > 0) _setLastTopUpData()`. A all-zero-limit batch does not move the last-top-up timestamp, so a second call in the same block is allowed. Lean `allocate` has no last-top-up field (issue 13). `well_formed_batch` has no such conjunct.

    *Scenario.* Three validators all already at target (limits 0). Live `topUp` succeeds, does not write last-top-up, and a second `topUp` in the same block is allowed. A later non-zero batch in that block also succeeds. If Lean modeled block distance as “any previous allocate,” it would wrongly reject the second call. The CHECKED tx cannot represent either policy: it has no timestamp at all.
