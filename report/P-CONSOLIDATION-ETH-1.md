# P-CONSOLIDATION-ETH-1

> Round 2 (2026-08-21). Product note plus proof audit, arbitrated from GPT 5.6 Pro and Opus 5. Fable 5 was unavailable (data-retention gate). Kimi K3 was not an allowed Task model. No em dashes. Lean is authority.


> Renamed from `P-ETH-1`: this row is the consolidation fee/refund ETH plane, not a general SRv3 ETH guarantee. Orthogonal to `P-CONSOLIDATION-1` (vault request atomicity).
A consolidation execution takes ETH in at one door and must let it out through exactly two: the EIP-7251 consolidation-request predeploy, owed a per-request fee, and the caller's refund recipient, owed the remainder. The route is `ConsolidationBus.executeConsolidation` forwarding `msg.value` to `ConsolidationGateway.addConsolidationRequests`, which pays $n \times \mathrm{fee}$ and refunds the rest.

P-CONSOLIDATION-ETH-1 verifies this on `gatewayExecute`, whose destinations are classified against a two-address `ApprovedSet`:

- $\mathrm{msgValue} = 0$ reverts `ZeroArgument`
- $n \times \mathrm{fee} \ge 2^{256}$ reverts overflow
- $n \times \mathrm{fee} > \mathrm{msgValue}$ reverts `InsufficientValue`
- otherwise every journaled move is `parentApproved` and $\mathrm{totalAmount} = \mathrm{msgValue}$

The registered abstract theorem is `eth_flow_parent_at_canonical`, a real $\forall (\mathrm{msgValue}, n, \mathrm{fee})$ whose `canonicalApprovedSet` fixes the fee destination to the EIP-7251 `0x7251` literal. Equality of a deployed configured target with that model literal remains `A-CANONICAL-REQUEST-ADDRESS`. The registered Verity theorem is `verity_tx_success_and_revert_partition`, which conjoins `verity_tx_universal_success_shape` on the success arm with `UniversalRevertPartition` on all four modeled non-success arms; both sides now match the abstract plane's quantifier strength under explicit non-revert and fuel premises. Former P-CONSOLIDATION-ETH-1a (vault→Lido/WQ returns) remains retired, and no composition into P-CONSOLIDATION-1 is claimed.

## Proof limitations and recommendations

The two planes now share quantifier strength on both sides of the gateway guard. Abstract is $\forall (\mathrm{msgValue}, n, \mathrm{fee})$ over all `gatewayExecute` outcomes (three revert clauses plus the approved-and-conserving success clause). Verity is $\forall (\mathrm{msgValue}, \mathrm{batchSize}, \mathrm{feePerRequest})$ over the success branch under those non-revert conditions plus the model's fuel bound, and (Wave 6) $\forall$ over each of the four modeled non-success branches under the negated guard conditions. Each premise is load-bearing: a premise-necessity kill-line refutes each premise-dropped projection on the honest wiring. The registered parent is therefore not a naked $\forall$ and must not be quoted as one. `fuelBudget = 32` still bounds dispatched frames and `Expr.mul` still wraps mod $2^{256}$, which is why those two premises sit in the statement.

Residual gap, recorded in YAML `fidelity.missing`: the universal revert arms cover the *modeled* non-success shapes only, so a reverting refund/Lido sink or a rejecting request predeploy is still carried by numeral witnesses, and the fuel arm quantifies over the model's own `fuelBudget = 32` frame count under `A-ABSTRACT-TX` rather than any deployed gas fact. There is no `Audit/Source` file. Rollback is `finalWorld` returning the entry world on any non-success. The ensemble is still not the live `executeConsolidation` ABI (groups, not `(amount, batchSize)`). Children `eth_flow_confined` and `consolidation_fee_path_confined` are weaker and unused by the parent proof. Wiring mutants do not retarget `requestTarget` / `refundTarget`.

CHECKED does not mean a naked Verity $\forall$, pinned-Solidity correspondence, bytecode, or complete SRv3 ETH-site coverage.

Ranked next work: keep the universal success parent, the universal revert partition, and the premise kill-lines; register the Verity canonical-address fact only with a real proof; discharge deployed-target provenance from artifacts; compose with P-CONSOLIDATION-1 only after the ABI bridge.

Theorems: `PConsolidationEth1.eth_flow_parent_at_canonical`, `PConsolidationEth1.verity_tx_success_and_revert_partition` (registered parents); `PConsolidationEth1.verity_tx_universal_success_shape`, `PConsolidationEth1.verity_tx_universal_revert_partition`, `PConsolidationEth1.verity_tx_universal_zero_remainder_boundary` (its universal components); `PConsolidationEth1.eth_flow_parent` (generic helper); `PConsolidationEth1.verity_tx_composes_value_flow_and_rollback` (auxiliary regression evidence).
Kill-lines (Tests): `misrouted_journal_kill_line_refutes_parent`, `zero_value_success_kill_line_refutes_parent` (abstract parent, Wave 4); `dropped_refund_leg_kill_line_refutes_universal_parent`, `misrouted_vault_kill_line_refutes_universal_parent`, `corrupted_refund_kill_line_refutes_universal_parent`, `single_request_kill_line_refutes_universal_parent` (universal Verity parent, Wave 5 wiring mutants); `zero_value_kill_line_refutes_dropped_positivity`, `underfunded_kill_line_refutes_dropped_funding`, `fuel_exhaustion_kill_line_refutes_dropped_fuel_premise` (Wave 5 premise-necessity); `underfunded_batch_is_not_a_repartition`, `large_funded_batch_exhausts_fuel_budget` (Wave 2 executable premise witnesses).
Assumptions: `A-ABSTRACT-TX`, `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-CANONICAL-REQUEST-ADDRESS`.

## Wave 6 changes (2026-08-22)

**The Verity revert arms are lifted from numeral witnesses to `∀`.** Wave 5
left an explicit quantifier gap: the abstract parent's three revert clauses
were universally quantified, while the Verity plane carried one numeral
rollback witness per shape. That gap is now closed in
`Audit/Verity/PConsolidationEth1CompositionTxUniversalRevert.lean` and wired
into the registry as `UniversalRevertPartition`, discharged by
`verity_tx_universal_revert_partition` and conjoined into the registered
`verity_tx_success_and_revert_partition`:

- `run_zero_value_reverts`: for all word-sized `(batchSize, feePerRequest)`,
  `msgValue = 0` gives
  `observe = ⟨.calleeReverted gatewayAddr, 2, ⟨0,0,0,0,0,0,0⟩⟩` (the
  `ZeroArgument` guard).
- `run_overflow_reverts`: for all nonzero-valued word-sized inputs with
  `0 < batchSize` and `2^256 ≤ batchSize * feePerRequest`, the post-`mul`
  wrap check fires `Panic(0x11)` and the sender's whole `msgValue` is
  restored.
- `run_underfunded_reverts`: for all nonzero-valued word-sized inputs with a
  non-wrapping product and `msgValue < batchSize * feePerRequest`, the
  `InsufficientValue` guard reverts with the entry balance sheet restored.
- `run_exhausts_fuel`: for all funded, non-wrapping, word-sized inputs with
  `29 ≤ batchSize` that need more than `fuelBudget` frames, the dispatcher
  reports `⟨.exhausted, fuelBudget, ⟨msgValue,0,0,0,0,0,0⟩⟩`.

Every arm is read through `observe`, hence through `finalWorld`, so each arm
asserts transaction-entry rollback of the whole balance sheet and not merely a
control tag. The three gateway arms are proved by executing the compiled
gateway body symbolically to the failing `require`; the fuel arm reuses the
success parent's `request_phase` induction, run for exactly `fuelBudget - 3`
request hops.

**The partition is total on word-sized inputs.** The registered success arm
carries the conservative premise `batchSize + 4 ≤ fuelBudget`, which excludes
the zero-remainder corner `batchSize + 3 = fuelBudget`. That corner is closed
by `verity_tx_universal_zero_remainder_boundary`
(`run_success_at_zero_remainder_boundary`), so for word-sized inputs:
`batchSize ≤ 28` commits, `batchSize = 29` commits iff the remainder is zero
and otherwise exhausts, `batchSize ≥ 30` exhausts, `msgValue = 0` reverts, a
wrapped product reverts, and an underfunded batch reverts. No word-sized
input is left unclassified between the modeled arms.

**Nothing was weakened.** The four numeral conjuncts of
`verity_tx_success_and_revert_partition` are retained verbatim alongside the
new universal conjunct; they are now instances of it — `(0,2,0)` of the zero
arm, `(10,2,2^255)` of the overflow arm, `(10,4,3)` of the underfunded arm,
`(30,29,1)` of the fuel arm — and remain as regression facts. The registered
theorem name is unchanged, so `scripts/audit_metadata.py`'s canonical claim
tuple is unchanged; only the pinned detail digest moves.

**Residual honesty.** The universal arms characterize the *modeled*
non-success shapes. A reverting refund or Lido sink is still not modeled, and
the rejecting-predeploy rollback stays a numeral witness in
`verity_tx_composes_value_flow_and_rollback`. `run_success_at_zero_remainder_boundary`
needed an explicit `batchSize * feePerRequest ≤ msgValue` premise added during
this wave: without it the zero-remainder statement is false, because
`msgValue - batchSize * feePerRequest = 0` is also satisfied by underfunded
inputs, which revert at the `InsufficientValue` guard. The fuel arm quantifies
over `fuelBudget = 32`, a frame count of the abstract dispatcher under
`A-ABSTRACT-TX`; it carries no deployed gas-metering meaning.

## Wave 5 changes (2026-08-21)

**Model repair disclosed first:** the compiled gateway body `gatewayFn` in
`PConsolidationEth1CompositionTx.lean` gains the `ZeroArgument` guard
(`require 0 < msg.value`) this wave, matching the pinned source gateway's
`ZeroArgument("msg.value")` revert and the abstract plane's Wave 1 guard
(report issue 13). The guard only affects `msgValue = 0` runs, which lie
outside the registered parent's premises, so it neither weakens nor
strengthens the registered success claim; it is what makes the positivity
premise load-bearing (the premise-necessity kill-line below reverts at that
guard), and it removes the pre-Wave-5 phantom zero-value success from the
model rather than merely excluding it by premise.

**The Verity plane is lifted to matching `∀` strength on the success arm.**
The registered Verity parent is now
`LidoSRv3.Audit.Guarantees.PConsolidationEth1.verity_tx_universal_success_shape`: for all
`(msgValue, batchSize, feePerRequest)` satisfying

- `0 < msgValue` (the Gateway's `ZeroArgument` guard),
- `msgValue`, `batchSize`, `feePerRequest`, and the product
  `batchSize * feePerRequest` all below `2^256` (word-sized, no wrap —
  issues 12/14),
- `batchSize * feePerRequest ≤ msgValue` (funded — the `InsufficientValue`
  guard), and
- `batchSize + 4 ≤ fuelBudget` (the dispatch fuel bound — issue 9),

the honest wiring commits with
`observe = ⟨.success, batchSize + 3 + (refund leg ? 1 : 0), ⟨0,0,0,0,0, n*fee, msgValue − n*fee⟩⟩`:
the whole product fee lands at the consolidation-request predeploy, the
remainder lands at the refund recipient, and no protocol contract on the
route retains ETH. The proof is frame-by-frame chaining through the
recursive dispatcher: per-hop frame lemmas for the Bus, Gateway, Vault,
per-request, and refund legs, plus a `requestPhaseWorld` induction over the
symbolic `batchSize`-driven request loop
(`Audit/Verity/PConsolidationEth1CompositionTxUniversal.lean`). The premises are exactly
the abstract parent's non-revert conditions plus the fuel bound, so the two
planes now state the same success-arm quantification.

**Kill-lines on that same universal parent.** `Tests.PConsolidationEth1CompositionTxMutants`
factors the registered parent's exact statement over the wiring as
`universalSuccessShapePredicate` and proves
`universal_parent_is_predicate_at_honest` (the registered parent is that
predicate at the honest wiring). Then:

- Four wiring mutants refute the same predicate at `(10, 2, 3)`, a witness
  that satisfies every premise
  (`witness_10_2_3_satisfies_universal_premises`):
  `dropped_refund_leg_kill_line_refutes_universal_parent`,
  `misrouted_vault_kill_line_refutes_universal_parent`,
  `corrupted_refund_kill_line_refutes_universal_parent`,
  `single_request_kill_line_refutes_universal_parent`.
- Three premise-necessity kill-lines refute the premise-dropped projections
  on the honest wiring, showing each premise is load-bearing rather than
  incidental: `zero_value_kill_line_refutes_dropped_positivity` (witness
  `(0, 2, 0)`, the `ZeroArgument` guard reverts),
  `underfunded_kill_line_refutes_dropped_funding` (witness `(10, 4, 3)`,
  the `InsufficientValue` guard reverts),
  `fuel_exhaustion_kill_line_refutes_dropped_fuel_premise` (witness
  `(30, 29, 1)`, the dispatcher reports `.exhausted`).

The Wave 2 scope kill-lines (`underfunded_batch_is_not_a_repartition`,
`large_funded_batch_exhausts_fuel_budget`) remain as the executable forms of
the funding and fuel premise witnesses. The previous finite Verity parent
`verity_tx_composes_value_flow_and_rollback` is retained as auxiliary
regression evidence — its success numerals are instances of the universal
parent — but it is no longer the registered Verity theorem in
`audit/guarantees.yaml`.

**Residual honesty (as of Wave 5).** The universal parent characterizes the
success branch only. There is no `∀` revert-shape theorem on the Verity plane
(the premise-necessity kill-lines witness non-success runs, negatively); this
is the new `fidelity.missing` entry replacing the old quantifier-strength gap.
*Closed in Wave 6 below.* The ensemble remains the audit-authored ABI
(issue 17), so composition into P-CONSOLIDATION-1 is still gated on
`FunctionSpec` becoming `ConsolidationGateway.addConsolidationRequests`.

## Wave 4 changes (2026-08-19)

**Parent kill-lines that actually refute the registered parent.** The Wave 1
"kill-lines" refuted nothing: `rejects_unapproved_journal_entry` quantified
over a hand-built one-move list that `eth_flow_parent` never mentions (the
parent quantifies over `gatewayExecute`'s output, not over arbitrary lists),
and `rejects_zero_msg_value` *confirmed* the honest model's zero guard —
exactly what the parent's first clause already requires. Both are retained
under honest names: `confirms_lateral_journal_entry_is_not_parent_approved`
and `confirms_zero_msg_value_reverts`.

`Tests.PConsolidationEth1CompositionTxMutants` now factors the parent's per-outcome
predicate out as `parentOutcomePredicate` and proves it is exactly the
registered parent's conclusion
(`parentOutcomePredicate_is_eth_flow_parent_conclusion`: on the honest model
the predicate holds for every input, by `eth_flow_parent` itself). Two
mutants of `gatewayExecute` then refute that predicate on their own success
outputs:

- `gatewayExecuteMisrouted` keeps every guard and the fee/refund split but
  journals the per-request fee legs to `rogueFeeSink = 999`, an address
  outside the `ApprovedSet`, so `classifyJournal` maps them to `.other 999`.
  `misrouted_journal_kill_line_refutes_parent` proves the funded run
  `(10, 2, 3)` succeeds with moves on which the parent's exact success
  conjunct is false: conservation still holds (`3 + 3 + 4 = 10`), but
  `∀ m, m ∈ moves → parentApproved m.destination` does not. This is issue
  1's scenario made executable.
- `gatewayExecuteUnguarded` drops the `ZeroArgument`/`InsufficientValue`
  value guards, so the zero-value call `(0, 2, 3)` *succeeds*, paying
  `2 * 3 = 6` wei of fees from the gateway's own balance.
  `zero_value_success_kill_line_refutes_parent` proves the parent's success
  conjunct at `msgValue = 0` false: every destination is approved, but
  `totalAmount moves = 6 ≠ 0`. This is the parent-killing form of the old
  zero-value check.

No registered Lean statement changed; the report and composition doc also
drop the stale `EthPath`/`pathTrace`/`pathFunded` narrative (those
definitions were removed by the Wave 1 rewrite) in favour of the current
`gatewayExecute`/`ApprovedSet` parent.

## Wave 2 changes (2026-08-19)

**Scope narrowing, not generalization.** `eth_flow_parent` (abstract plane)
was already `∀ (msgValue n fee : Nat)` as of Wave 1. `verity_tx_composes_value_flow_and_rollback`
(Verity plane) remains a finite conjunction over five concrete
`(msgValue, batchSize, feePerRequest)` tuples. A genuine `∀`-generalization
of the Verity plane was evaluated and rejected as infeasible without
`sorry`: it would require new induction infrastructure for the recursive
`MultiContract.callFunction` dispatch (`PConsolidationEth1CompositionTx.step`) over an
arbitrary `batchSize`-driven `forEach`, and even then two model properties
make an unconditional universal statement *false*, not merely hard to
prove:
- `fuelBudget = 32` (issue 9) caps the number of dispatched frames, so any
  candidate `∀` statement needs a batch-size side condition the current
  statement has none of;
- `Expr.mul` wraps mod `2^256` in the compiled bodies (issue 12), so
  "funded" as the model computes it and "funded" in checked-Solidity
  arithmetic diverge for large inputs.

Instead this wave (a) documents the finite-witness scope honestly in the
Lean docstrings, `audit/P-CONSOLIDATION-ETH-1-COMPOSITION.md`, and `audit/guarantees.yaml`
(explicit `fidelity.missing` entry), and (b) adds two named, executable
kill-line theorems to `PConsolidationEth1CompositionTxMutants.lean` that refute reading
the registered Verity parent as `∀`:
- `underfunded_batch_is_not_a_repartition` — `(10, 4, 3)` reverts instead of
  repartitioning the total (restates issue 2's counterexample as a named,
  citable theorem instead of an anonymous `example`).
- `large_funded_batch_exhausts_fuel_budget` — `(30, 29, 1)` is funded and
  passes every guard the compiled bodies check, yet needs 33 dispatched
  frames against `fuelBudget = 32` and so hits `TxControl.exhausted`, a
  control value none of the five registered witnesses ever produce. This is
  issue 9 made executable, and a strictly new failure mode: it refutes even
  the narrower over-generalization "every batch whose own Gateway/Vault
  guards pass succeeds."

No Lean statement changed; only the docstrings, this report, the
composition doc, and the metadata gained the explicit scope and the two new
kill-line theorems.

## Wave 1 changes (2026-08-19)

**Strengthened `eth_flow_parent`:**
- Derives destinations from call-journal addresses classified against an `ApprovedSet` (consolidation contract, refund recipient).
- Quantifies `∀ (msgValue n fee : Nat)` — universally over all funded triples.
- `msg.value = 0` reverts with `GatewayRevert.zeroArgument`.
- `n * fee ≥ 2^256` reverts with `GatewayRevert.overflowPanic`.
- `n * fee > msgValue` reverts with `GatewayRevert.insufficientValue`.
- Success branch: every move is `parentApproved` (no `.other`) and `totalAmount = msgValue`.
- VaultHub / `StakingVault.withdraw` explicitly named out of scope on the theorem.

**Model confirmations (renamed in Wave 4 — they confirm the model, they are not parent kill-lines):**
- `confirms_lateral_journal_entry_is_not_parent_approved` (was `rejects_unapproved_journal_entry`): classifying address 999 (not in ApprovedSet) produces `.other 999`; the parent’s `parentApproved` predicate rejects it. This quantifies over a hand-built list the parent never mentions, so it is a classifier sanity check, not a kill-line.
- `confirms_zero_msg_value_reverts` (was `rejects_zero_msg_value`): `gatewayExecute` with `msgValue = 0` returns `.reverted .zeroArgument`, not success — exactly what the parent's first clause already requires of the honest model.

**Non-composition:** This ensemble is NOT composed into P-CONSOLIDATION-1 until the `FunctionSpec` is actually `ConsolidationGateway.addConsolidationRequests`.

## Intent

SRv3 moves ETH along a small set of protocol paths: `ConsolidationBus` forwards `msg.value` to `ConsolidationGateway`; the gateway pays `requestsCount × fee` into `WithdrawalVault` and refunds the rest; the vault pays the EIP-7251 `CONSOLIDATION_REQUEST` predeploy (and, separately, EIP-7002 `WITHDRAWAL_REQUEST`); `WithdrawalVault.withdrawWithdrawals` sends finalized EL rewards / withdrawals to Lido. The intended guarantee is that those paths never leak wei to a lateral address and that what goes out equals what came in.

## Modeling

- `A-ABSTRACT-TX`: success/revert are not EVM traces.
- `A-SOURCE-SHAPED`: Bus / Gateway / Vault in `PConsolidationEth1CompositionTx` are audit-authored `FunctionSpec`s (`executeConsolidation`, `triggerConsolidation`, `addConsolidationRequests`) — names and bodies are not the pinned Solidity functions.
- `A-VERITY-SCAFFOLD`.
- **Declared-amount convention** (PConsolidationEth1CompositionTx header): every `LinkedExternal.value` is `0`. The body puts the amount in calldata word 0; the dispatcher copies it into `CallSite.value`; the callee `require`s `msg.value == amount`. Real Solidity pays via `call{value: x}`. The model cannot express a body that both transfers and forwards the same wei (it would double-debit).
- The abstract parent models one Gateway execution as `gatewayExecute approved msgValue n fee`: a guard chain (`ZeroArgument` at `msgValue = 0`, `Panic(0x11)` overflow at `n * fee ≥ 2^256`, `InsufficientValue` at `n * fee > msgValue`), then success emits `List.replicate n` fee moves of `fee` wei classified to the approved consolidation contract plus one refund move of `msgValue − n * fee` classified to the approved refund recipient (elided when the refund is zero).
- Destinations are derived from journaled call addresses classified against a two-address `ApprovedSet` (`classifyJournal`); an address outside the set becomes `EthDestination.other`, which `parentApproved` rejects — lateral leakage is *representable* and excluded by the parent, not unrepresentable. The Wave 4 misroute mutant exercises exactly that representability.
- Owner-controlled `StakingVault.withdraw`, `Lido.submit`, WithdrawalQueue claims, EL-rewards sweep, and module deposits have no `gatewayExecute` leg; VaultHub / `StakingVault.withdraw` are named out of scope on the theorem.
- Composition covers Bus→Gateway→Vault→request plus refund. The EIP-7002 and withdrawals-to-Lido legs run on neither parent (issue 15; `audit/P-CONSOLIDATION-ETH-1-COMPOSITION.md` says so).

## Proof

**Abstract `eth_flow_parent`.** `split_ifs` on the three `gatewayExecute` guards; each revert branch discharges its own clause (`msgValue = 0`, `n * fee ≥ 2^256`, `n * fee > msgValue`). On the success branch, membership in `List.replicate` forces a fee move, whose destination is `classifyJournal approved approved.consolidationContract = .consolidationContract`; the optional refund singleton is `.refundRecipient` under the hypothesis that the two approved addresses differ. Neither is `.other`, so `parentApproved` holds. Conservation: `totalAmount (List.replicate n {fee, …}) = n * fee` by `totalAmount_replicate` (induction on `n`), then `n * fee + (msgValue − n * fee) = msgValue` by `omega`; the zero-refund case uses `totalAmount [] = 0` and `n * fee = msgValue`.

No relation to a contract is used. The proof is arithmetic + “the list `gatewayExecute` built contains only the tags it put in it.”

**VERITY `verity_tx_universal_success_shape` (registered parent since Wave 5).** A `∀` statement over `(msgValue, batchSize, feePerRequest)` under the positivity, word-size, no-wrap, funding, and fuel premises. The proof (`Audit/Verity/PConsolidationEth1CompositionTxUniversal.run_success_shape`) chains per-hop frame lemmas through the recursive dispatcher: each hop's `callFunction`/`step` execution is reduced once (`bus_frame`, `gateway_frame`, `vault_frame`, `request_frame`, `refund_frame`), the symbolic `batchSize`-driven request loop is handled by induction over the recursive `requestPhaseWorld` definition, and the final balance sheet is computed by `Uint256`/`Nat` arithmetic lemmas under the no-wrap premises. Dispatch itself is a fueled DFS that executes each `FunctionSpec` and prepends journaled child frames.

**VERITY `UniversalRevertPartition` / `verity_tx_universal_revert_partition` (registered conjunct since Wave 6).** Four `∀` statements over `(msgValue, batchSize, feePerRequest)`, one per modeled non-success shape, each concluding an exact `observe` value — control tag, hop count, and the fully restored transaction-entry balance sheet. The three gateway arms (`Audit/Verity/PConsolidationEth1CompositionTxUniversalRevert.run_zero_value_reverts`, `run_overflow_reverts`, `run_underfunded_reverts`) execute the compiled gateway body symbolically to the failing `require` and lift the resulting `.revert` frame through `gateway_frame_reverts` / `hop_gateway_revert` to `observe`; `wrapped_div_ofNat_val_ne` supplies the post-`mul` wrap check's `(a*b)/a ≠ b` fact at `Uint256` rather than `Nat`. The fuel arm (`run_exhausts_fuel`) reuses the success parent's `request_phase` induction for exactly `fuelBudget - 3` request hops and then reads `.exhausted` off the fuel-zero branch of `step`. Because every arm goes through `observe`, and `finalWorld` returns the transaction-entry world on any non-success, each arm asserts rollback and not merely a control tag.

**VERITY `verity_tx_universal_zero_remainder_boundary` (registered conjunct since Wave 6).** The `batchSize + 3 ≤ fuelBudget` zero-remainder corner excluded by the success parent's conservative `batchSize + 4 ≤ fuelBudget` premise. It carries an explicit `batchSize * feePerRequest ≤ msgValue` funding premise: `msgValue − batchSize * feePerRequest = 0` alone does not imply funding (underfunded inputs satisfy it too and revert at `InsufficientValue`), so without that premise the statement is false.

**VERITY `verity_tx_composes_value_flow_and_rollback` (auxiliary evidence).** A finite conjunction of concrete runs of `PConsolidationEth1CompositionTx.run honest 10 2 3`, `10 1 3`, `6 2 3`, a `requestAccepts := false` run, an underfunded `10 4 3` run, plus `escrowed = msgValue` on three of those and a `replay` equality on the first (`denoteTransaction` of the discovered `List CompiledCall` matches `observe`’s balance sheet — the only non-arithmetic content, still one numeral). Proof is `decide` / kernel reduction (`audit/P-CONSOLIDATION-ETH-1-COMPOSITION.md`). Its three success numerals are instances of the universal parent.

## Issues

## Resolution

**Restated Lean/English.** Abstract is the `∀ (msgValue n fee : Nat)` match on `gatewayExecute` outcomes: three revert clauses plus an approved-and-conserving success clause. Verity is the matching `∀ (msgValue batchSize feePerRequest : Nat)` success-shape theorem under the abstract parent's non-revert conditions plus the fuel bound (Wave 5); each premise carries a premise-necessity kill-line. Underfunded `(10,4,3)` remains a counterexample to a universal split and is now the funding-premise witness.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1 | C | Wave 1 journal classification makes lateral destinations representable; Wave 4 `misrouted_journal_kill_line_refutes_parent` refutes the parent's success conjunct on a misrouted-journal mutant of `gatewayExecute`. |
| 7, 8 | A | `finalWorld` / 7-account escrow named honestly. |
| 2 | C | Wave 5 registers `verity_tx_universal_success_shape`: the Verity plane is `∀` on the success arm under funded + no-wrap + fuel premises. Wave 6 adds `UniversalRevertPartition` to the registered theorem, so the non-success arms are `∀` too; the Wave 2 kill-lines remain as executable premise witnesses. |
| 3, 5, 10, 15, 17 | scope | Extra ETH sites, hops, ABI in `missing`. |
| 4, 6, 11, 18, 19, 20 | A | Declared-amount, two planes, sinks, fee slot, replay. |
| 9 | C | `fuelBudget` is now an explicit premise (`batchSize + 4 ≤ fuelBudget`) of the registered universal Verity parent; `fuel_exhaustion_kill_line_refutes_dropped_fuel_premise` shows it is load-bearing. |
| 12, 14 | C | Post-`mul` wrap-check reverts when `(a*b)/a ≠ b`; the no-wrap condition (`n * fee < 2^256`) is now an explicit premise of the universal Verity parent. |
| 13 | C | `gatewayExecute` reverts `ZeroArgument` at `msgValue = 0` and the parent's first clause pins it; Wave 4 `zero_value_success_kill_line_refutes_parent` shows the guard is load-bearing on the abstract plane, and Wave 5 `zero_value_kill_line_refutes_dropped_positivity` shows the `0 < msgValue` premise is load-bearing on the Verity plane. |
| 16 | A | 160-bit wrap documented. |


1. **“No lateral destination” was unfalsifiable on the abstract type — closed in Waves 1 and 4.**
   The pre-Wave-1 parent built its move lists by hand, so no constructor argument could place wei on `.other` and the first conjunct could not fail. Wave 1 re-derived destinations from journaled call addresses via `classifyJournal` against an `ApprovedSet`, making lateral destinations representable: `parentApproved (.other _) = False`, and any journaled address outside the set classifies to `.other`. Wave 4 then made the conjunct genuinely load-bearing: `Tests.PConsolidationEth1CompositionTxMutants.misrouted_journal_kill_line_refutes_parent` runs the funded success case `(10, 2, 3)` through `gatewayExecuteMisrouted` — the same guard chain and split as `gatewayExecute`, but with the fee legs journaled to the operator-supplied `rogueFeeSink = 999`, classified `.other 999` — and proves the registered parent's exact success conjunct is false on that mutant's output. The hand-built-list theorem survives only as `confirms_lateral_journal_entry_is_not_parent_approved`, a classifier sanity check.

   *Scenario the guarantee now catches.* A patched `ConsolidationGateway` fee or refund leg that sends wei to `tx.origin` or to an operator-supplied address off the `ApprovedSet` produces an `.other` move and violates the parent's first success conjunct — proved executable on the mutant, not just asserted in prose.

2. **The Verity parent is a unit-test bundle, not a theorem about all batches.**
   *Resolved in Wave 5, extended in Wave 6.* The registered Verity parent is now the universal `verity_tx_universal_success_shape`, which quantifies over all `(msgValue, batchSize, feePerRequest)` satisfying the funded / no-wrap / fuel-fit / positivity premises; the five numeral tuples are retained only as auxiliary regression evidence in `verity_tx_composes_value_flow_and_rollback`. Wave 6 removes the last unit-test residue from the registered theorem by conjoining `UniversalRevertPartition`, so the four modeled non-success shapes are `∀`-quantified as well and their numeral witnesses become instances. The historical note below describes the pre-Wave-5 state.

   The old named theorem mentioned only the tuples `(msgValue, batchSize, fee) ∈ {(10,2,3),(10,1,3),(6,2,3),(10,2,3 false),(10,4,3)}`. It did not quantify over `msgValue`, `feePerRequest`, or `batchSize`.

   *Counterexample to the claimed generality (pre-Wave-5).* `run honest 100 10 7` (fee 70, refund 30) was not a conjunct. Nothing in the old Lean statement failed if that run mis-routed the refund. Under the Wave 5 parent, `(100, 10, 7)` satisfies every premise (`70 ≤ 100`, `10 + 4 ≤ 32`), so the success shape *is* now a theorem about that run; the four wiring kill-lines refute the same universal predicate on the mutants (`drop` refund, `misroute` vault to Lido, `refundWholeValue`, single request) at the premise-satisfying witness `(10, 2, 3)`.

3. **Inventory is incomplete versus deployed ETH-bearing sites.**
   Pinned SRv3 also moves ETH through `VaultHub.withdraw` / `Dashboard.withdraw` (protocol-controlled, **any** `_recipient`), `StakingVault.withdraw`, `StakingVault.triggerValidatorWithdrawals` (EIP-7002 + excess refund to a caller-chosen address), `TriggerableWithdrawalsGateway`, `WithdrawalQueueBase._sendValue` (payout to the *claimant*), `Lido.submit`, and beacon `deposit{value:}`.

   *Scenario.* Owner with `WITHDRAW_ROLE` calls `Dashboard.withdraw(attacker, 100 ether)`. ETH leaves the stVault to `attacker`. No `gatewayExecute` leg models this; the theorem names VaultHub / `StakingVault.withdraw` out of scope explicitly. Separately, `TriggerableWithdrawalsGateway.triggerFullWithdrawals` (`:165–190`) — the contract the Lean gateway is *named* after — pays EIP-7002 fees and refunds; it has no `gatewayExecute` leg either. CHECKED covers the modeled gateway execution, not every ETH-bearing path of SRv3.

4. **Declared-amount convention is not the deployed calling convention.**
   Every `LinkedExternal.value` is `0`; the amount rides in calldata word 0; the dispatcher copies it into `CallSite.value`. Source never takes `amount` as calldata word 0.

   *Scenario.* A real body does `vault.call{value: fee}(...)` *and* the frame also debited `CallSite.value`. The model would double-charge, so the harness zeroed link value. That is a harness invariant, not a Lido invariant. `A-ABSTRACT-TX` plus this convention means the composition is a different protocol.

5. **FunctionSpecs are not the pinned functions.**
   The compilation model is named `TriggerableWithdrawalsGateway` (`PConsolidationEth1CompositionTx.lean:131–154`) — a **different** deployed contract than `ConsolidationGateway`. Gateway is named `triggerConsolidation` with params `(amount, batchSize)`. Deployed `ConsolidationGateway.addConsolidationRequests` takes `ConsolidationWitnessGroup[]`, checks SSZ, consumes quota, expands groups, then calls the vault. Deployed `ConsolidationBus.executeConsolidation` (`:383–406`) hashes the pending batch, waits `_executionDelay`, deletes it, and forwards `{value: msg.value}` with **`msg.sender` as refund recipient**. The model refunds hardcoded `refundAddr = 6` (`senderAddr = 7`), has no batch hash / delay / delete.

   *Scenario.* A witness/quota bug sends an extra fee CALL, or the executor (`msg.sender`) is refunded instead of a supplied `refundRecipient`. The ensemble cannot represent batch-not-found / delay-not-passed / hash mismatch; the CHECKED split still holds of `(10, 2, 3)`.

6. **Abstract and Verity planes are not refined to each other.**
   No lemma relates `gatewayExecute`'s move list to `observe (run honest 10 2 3)`. Parent Verity never runs an EIP-7002 or `withdrawWithdrawals` leg, and the abstract parent has no legs for them beyond the `ApprovedSet`'s two addresses.

   *Scenario.* Change the fee-leg destination in `gatewayExecute` to `.other 0` and leave the Verity ensemble alone. `eth_flow_parent` fails; `verity_tx_composes_value_flow_and_rollback` still holds. The two CHECKED marks are independent. (The Wave 4 `gatewayExecuteMisrouted` mutant is essentially this change, executed against the abstract parent only.)

7. **Rollback / conservation-on-revert are `finalWorld` by definition.**
   `finalWorld` returns `entryWorld` on any non-`.success` (`PConsolidationEth1CompositionTx.lean:343–347`). `observe` reads `finalWorld`. So the reject-request balance sheet `⟨10,0,0,0,0,0,0⟩` follows from `initial 10 _` plus the wrapper, even if the dispatcher never undid anything.

   *Scenario.* Delete the dispatcher’s restore and keep `finalWorld` as written. The registered revert conjuncts still hold. The mutant `observeWithoutRollback` only shows `lastWorld` was dirtied; it does not prove EVM CALL-revert semantics (`A-ABSTRACT-TX`).

8. **`escrowed` / `BalanceView` only see the seven seeded accounts.**
   `initial` creates sender, bus, gateway, vault, lido, request, refund. `escrowed` is the sum of those `selfBalance`s. `lidoAddr` is a sink the honest program never calls, so `lido = 0` on every success run.

   *Scenario.* Add an eighth address that a mutant gateway pays. That address is not in `BalanceView`. `escrowed` still equals `msgValue` because the missing wei is not in the sum. The CHECKED conservation conjunct cannot see an off-sheet leak.

9. **`fuelBudget = 32` silently changes the theorem’s meaning for large batches.**
   `PConsolidationEth1CompositionTx.fuelBudget` is 32 frames. A 40-request batch hits `TxControl.exhausted` and `finalWorld` restores the entry world.

   *Scenario.* `run honest 40 40 1` (fee 40, exact). Source vault loops 40 CALLs. Lean stops at 32 hops and reports `exhausted`, which `observe` treats like a revert (entry balances). The pre-Wave-5 registered theorem never mentions this. CHECKED “atomic compiled multicall” is a 32-frame cap.

   *Executable (Wave 2).* `PConsolidationEth1CompositionTxMutants.large_funded_batch_exhausts_fuel_budget` proves `(run honest 30 29 1).control = .exhausted` — a funded (`29 * 1 ≤ 30`), guard-passing batch that still cannot reach the registered parent's success shape. This is a kill-line against generalizing the registered Verity parent to `∀` funded batches, not just against this report's prose.

   *Resolved as a premise (Wave 5).* The registered universal parent carries the explicit fuel premise `batchSize + 4 ≤ fuelBudget`, and `fuel_exhaustion_kill_line_refutes_dropped_fuel_premise` refutes the fuel-dropped projection on the honest wiring at `(30, 29, 1)` — the premise is load-bearing, and no naked `∀` claim is registered.

10. **The abstract parent omits the Bus→Gateway and Gateway→Vault hops.**
   The inventory comment lists those CALLs. `gatewayExecute`'s success list is only `List.replicate n` fee moves plus the optional refund move. Intermediate forwards of `msg.value` / `totalFee` are not `EthMove`s. Conservation is `n*fee + refund = msg.value`, which counts the same wei once at the terminal, not at each hop.

   *Scenario.* Gateway keeps `msg.value` and also pays the vault from its own pocket. Terminal fees + refund still sum to `msg.value`. `eth_flow_parent` holds. The protocol’s intermediate balance sheet is not in the theorem.

11. **The refund sink always accepts.**
   `sinkFn "RefundRecipient" true` (`PConsolidationEth1CompositionTx.lean:227–228`) cannot revert. Live `_refundFee` (`ConsolidationGateway.sol:302–304`) reverts `FeeRefundFailed` if `recipient.call{value: refund}` fails. `preservesEthBalance` then reverts the whole gateway tx.

   *Scenario.* `refundRecipient` is a contract whose fallback reverts. Live `addConsolidationRequests` reverts and rolls back the vault fee CALL. Lean `run honest 10 2 3` still commits `⟨0,0,0,0,0,6,4⟩`. The CHECKED success numeral is not the deployed refund.

12. **Gateway/vault `.mul` wraps; Solidity 0.8 reverts.**
   `evalExpr` on `.mul` is `(lhs * rhs).val` — wrapping `Uint256` (`Verity/Core/Model/Denote.lean:724–727`). The ensemble computes `fee = batchSize * feePerRequest` that way (`PConsolidationEth1CompositionTx.lean:140, 172`). Live `requestsCount * fee` (`ConsolidationGateway.sol:212`) is checked `uint256` and panics on overflow.

   *Counterexample.* `batchSize = 2^128`, `feePerRequest = 2^128`, `msgValue = 1`. Live `totalFee` overflows and the tx reverts. Lean `mul` wraps to `0`. `require(0 ≤ 1)` passes. The run can succeed with fee 0 (no request value, full refund). The CHECKED numerals never hit this; the ensemble is not 0.8 multiplication.

13. **Zero-value runs were a phantom success on the Verity plane — model corrected in Wave 5.**
    On the abstract plane this was already closed: `gatewayExecute` reverts `ZeroArgument` at `msgValue = 0` and the parent's first clause pins the behaviour. Wave 4 shows the clause is load-bearing — `gatewayExecuteUnguarded` drops the value guards, `(0, 2, 3)` succeeds paying 6 wei of fees, and `zero_value_success_kill_line_refutes_parent` refutes the parent's success conjunct on that mutant. On the Verity plane, Wave 5 fixes the model itself: the compiled gateway body `gatewayFn` now opens with the `ZeroArgument` guard (`require 0 < msg.value`), matching the source gateway's `ZeroArgument("msg.value")` revert, so `run honest 0 0 3` reverts at the gateway (`calleeReverted`, 2 hops) instead of reporting a phantom success. The registered universal parent carries the explicit positivity premise `0 < msgValue`, and `zero_value_kill_line_refutes_dropped_positivity` refutes the positivity-dropped projection on the honest wiring at `(0, 2, 0)` — the premise is load-bearing precisely because the corrected model reverts there.

    *Pre-Wave-5 scenario (now closed).* Before the guard was added, `run honest 0 0 3` gave fee `0`, vault `FeeMismatch` `0 == 0`, `forEach 0`, success with no request hops, while the source gateway reverts `ZeroArgument("msg.value")` / empty groups. The guard addition removes that divergence rather than papering over it with a premise alone. Lean `Nat` `requestsCount * fee` also cannot overflow; Solidity 0.8 reverts.

14. **Abstract fee arithmetic is unbounded `Nat` multiply; Verity `.mul` wraps; no refinement.**
    `composed_eth_conservation` is `fee + (msgValue - fee) = msgValue` under `fee ≤ msgValue` — true of any two Nats — and the abstract parent's overflow clause (`n * fee ≥ 2^256` reverts `Panic(0x11)`) is a model-side guard inside `gatewayExecute`, not a lemma about the Verity ensemble. The Verity ensemble multiplies with wrapping `Expr.mul` (issue 12). There is no lemma relating `gatewayExecute`'s move list to `observe (run …)`.

    *Counterexample.* `n = 2^128`, `fee = 2^128`. Abstract parent: `n * fee = 2^256 ≥ 2^256`, so the model reverts overflow for any `msgValue`. Verity wrap product is `0` and can succeed with a full refund (issue 12). Both CHECKED theorems hold of their own plane; the overflow guard is not the child's multiplication.

15. **EIP-7002 / withdrawals-to-Lido legs run on neither parent.**
    `gatewayExecute` emits only consolidation-fee and refund legs; `EthDestination.withdrawalRequestContract` and `.lido` exist as tags but no `gatewayExecute` branch produces them, and `verity_tx_composes_value_flow_and_rollback` only executes the consolidation ensemble (`run honest …`). Former P-CONSOLIDATION-ETH-1a's `withdrawToLido` (retired/unregistered) and former P-CONSOLIDATION-ETH-1b's `sendWithdrawalFee` (now parent fee-leg evidence) are different modules, different numerals — not sibling guarantees.

    *Scenario.* A mutant sending the fee leg to `.lido` — an approved tag, but the wrong contract — passes the abstract parent's `parentApproved` check: within the `classifyJournal` model an approved tag can only arise from a journaled address that matches the `ApprovedSet`, so tag-vs-contract confusion is a configuration error the parent cannot see. The Wave 4 misroute mutant covers the complementary case (off-set address → `.other` → caught). The registered Verity parent is unchanged by either.

16. **Dispatcher `callee` is `Address.ofNat` of the journaled target — 160-bit wrap.**
    `PConsolidationEth1CompositionTx.childPending` (`:262–271`) sets `callee := Core.Address.ofNat entry.target` and `value := entry.calldata.headD 0`. Two targets that differ by `2^160` collapse to the same registry key. The honest wiring only uses addresses 1–7, so the numerals hide this.

    *Counterexample.* A mutant gateway journals `target = 1 + 2^160` (would be a lateral address on chain). `wordToAddress` / `Address.ofNat` maps it to account 1 (`busAddr`). Dispatch re-enters the bus instead of an unknown target. `unknownTarget` is never taken. The CHECKED ensemble cannot represent a 160-bit-truncated retarget; `nodeAt` is a 6-address `if` chain.

17. **Bus `FunctionSpec` is `(amount, batchSize)` plus `require(msg.value == amount)`; live `executeConsolidation` takes groups only.**
    `busFn` (`PConsolidationEth1CompositionTx.lean:115–123`) is `executeConsolidation(amount, batchSize)` with `declaredValueCheck`. Live `ConsolidationBus.executeConsolidation` (`:383–406`) is `payable` and takes `ConsolidationWitnessGroup[] groups` — no amount argument, no `msg.value == amount` require. It forwards `{value: msg.value}` after the batch-hash / delay checks.

    *Scenario.* Caller sends `msg.value = 10` with a well-formed pending batch. Live forwards 10 to the gateway. Lean requires the *calldata word* `amount` to equal 10 (declared-amount convention, issue 4). A compiled bus call with the real ABI (groups, no amount) cannot even enter `busFn`. The CHECKED success numeral `run honest 10 2 3` is a different function than the mapped `executeConsolidation`.

18. **Fee is a stored slot on gateway *and* vault, not `getConsolidationRequestFee`.**
    `gatewayFn` / `vaultFn` multiply `batchSize * storage "feePerRequest"` (slot 0). `initial` writes the same seed into both accounts (`PConsolidationEth1CompositionTx.lean:324–332`). Live vault takes the fee from the EIP-7251 predeploy (`_getFeeFromContract` / `getConsolidationRequestFee`) and `_requireExactFee(count * fee)`. There is no fee `staticcall` in the ensemble.

    *Scenario.* Predeploy fee updates from `3` to `4` after the gateway computed `2·3 = 6`. Live vault reverts `IncorrectFee` / `FeeMismatch`. Lean still has slot `3` on both contracts: `run honest 10 2 3` commits `⟨0,0,0,0,0,6,4⟩`. The CHECKED split assumes a frozen, locally stored fee. A real fee change — the thing the exact-fee guard is for — cannot appear.

19. **`replay` is the same dispatcher on the recorded program, not a compiled multicall.**
    The last conjunct of `verity_tx_composes_value_flow_and_rollback` (`PConsolidationEth1.lean:521–528`) is `program.length = 6` and `replay run = observe.run.balances` for `(10,2,3)`. `replay` (`PConsolidationEth1CompositionTx.lean:395–396`) is `denoteTransaction entryWorld program` — a *different* interpreter than `step` / `run`. The equality is one numeral on which the two interpreters happen to agree.

    *Scenario.* Change `vaultFn` to send the fee to `lidoAddr`. Both `run` and `replay` mis-route the same way if they share the body, so the equality still holds. If `denoteTransaction` and `step` ever diverged on another batch, the CHECKED conjunct would not mention it. The YAML “atomic compiled multicall” is a self-consistency check of one harness, not `solc` output of `addConsolidationRequests`. Combined with issue 4 (declared-amount) and issue 17 (wrong bus ABI), the replay cannot become the deployed transaction.

20. **The Lido sink always accepts, like the refund sink.**
    `sinkNode "Lido" true 6` (`PConsolidationEth1CompositionTx.lean:229–230`) cannot revert. Live `Lido.receiveWithdrawals` (`Lido.sol:530–534`) is `_auth(_withdrawalVault())` — only the vault may call. The parent `withdrawalsToLido` constructor never runs on this ensemble (issue 15), but `lidoAddr` is still in the world and would accept any hop.

    *Scenario.* A mutant gateway pays Lido instead of the vault. Lean `Lido` sink accepts; `escrowed` still sums to `msgValue` (issue 8). Live `receiveWithdrawals` from the gateway reverts (not the vault). The CHECKED conservation conjunct cannot see a rejected Lido payment because the sink is `accepts := true`. Same shape as issue 11 (refund).
