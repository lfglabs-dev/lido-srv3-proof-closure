# P-ETH-1

Theorems: `PEth1.eth_flow_parent`, `PEth1.verity_tx_composes_value_flow_and_rollback`.
Kill-lines (Tests): `misrouted_journal_kill_line_refutes_parent`, `zero_value_success_kill_line_refutes_parent` (abstract parent, Wave 4); `underfunded_batch_is_not_a_repartition`, `large_funded_batch_exhausts_fuel_budget` (Verity scope, Wave 2).
Assumptions: `A-ABSTRACT-TX`, `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Wave 4 changes (2026-08-19)

**Parent kill-lines that actually refute the registered parent.** The Wave 1
"kill-lines" refuted nothing: `rejects_unapproved_journal_entry` quantified
over a hand-built one-move list that `eth_flow_parent` never mentions (the
parent quantifies over `gatewayExecute`'s output, not over arbitrary lists),
and `rejects_zero_msg_value` *confirmed* the honest model's zero guard —
exactly what the parent's first clause already requires. Both are retained
under honest names: `confirms_lateral_journal_entry_is_not_parent_approved`
and `confirms_zero_msg_value_reverts`.

`Tests.PEth1CompositionTxMutants` now factors the parent's per-outcome
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
`MultiContract.callFunction` dispatch (`PEth1CompositionTx.step`) over an
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
Lean docstrings, `audit/P-ETH-1-COMPOSITION.md`, and `audit/guarantees.yaml`
(explicit `fidelity.missing` entry), and (b) adds two named, executable
kill-line theorems to `PEth1CompositionTxMutants.lean` that refute reading
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
- `A-SOURCE-SHAPED`: Bus / Gateway / Vault in `PEth1CompositionTx` are audit-authored `FunctionSpec`s (`executeConsolidation`, `triggerConsolidation`, `addConsolidationRequests`) — names and bodies are not the pinned Solidity functions.
- `A-VERITY-SCAFFOLD`.
- **Declared-amount convention** (PEth1CompositionTx header): every `LinkedExternal.value` is `0`. The body puts the amount in calldata word 0; the dispatcher copies it into `CallSite.value`; the callee `require`s `msg.value == amount`. Real Solidity pays via `call{value: x}`. The model cannot express a body that both transfers and forwards the same wei (it would double-debit).
- The abstract parent models one Gateway execution as `gatewayExecute approved msgValue n fee`: a guard chain (`ZeroArgument` at `msgValue = 0`, `Panic(0x11)` overflow at `n * fee ≥ 2^256`, `InsufficientValue` at `n * fee > msgValue`), then success emits `List.replicate n` fee moves of `fee` wei classified to the approved consolidation contract plus one refund move of `msgValue − n * fee` classified to the approved refund recipient (elided when the refund is zero).
- Destinations are derived from journaled call addresses classified against a two-address `ApprovedSet` (`classifyJournal`); an address outside the set becomes `EthDestination.other`, which `parentApproved` rejects — lateral leakage is *representable* and excluded by the parent, not unrepresentable. The Wave 4 misroute mutant exercises exactly that representability.
- Owner-controlled `StakingVault.withdraw`, `Lido.submit`, WithdrawalQueue claims, EL-rewards sweep, and module deposits have no `gatewayExecute` leg; VaultHub / `StakingVault.withdraw` are named out of scope on the theorem.
- Composition covers Bus→Gateway→Vault→request plus refund. The EIP-7002 and withdrawals-to-Lido legs run on neither parent (issue 15; `audit/P-ETH-1-COMPOSITION.md` says so).

## Proof

**Abstract `eth_flow_parent`.** `split_ifs` on the three `gatewayExecute` guards; each revert branch discharges its own clause (`msgValue = 0`, `n * fee ≥ 2^256`, `n * fee > msgValue`). On the success branch, membership in `List.replicate` forces a fee move, whose destination is `classifyJournal approved approved.consolidationContract = .consolidationContract`; the optional refund singleton is `.refundRecipient` under the hypothesis that the two approved addresses differ. Neither is `.other`, so `parentApproved` holds. Conservation: `totalAmount (List.replicate n {fee, …}) = n * fee` by `totalAmount_replicate` (induction on `n`), then `n * fee + (msgValue − n * fee) = msgValue` by `omega`; the zero-refund case uses `totalAmount [] = 0` and `n * fee = msgValue`.

No relation to a contract is used. The proof is arithmetic + “the list `gatewayExecute` built contains only the tags it put in it.”

**VERITY `verity_tx_composes_value_flow_and_rollback`.** Not a `∀` statement. It is a finite conjunction of concrete runs of `PEth1CompositionTx.run honest 10 2 3`, `10 1 3`, `6 2 3`, a `requestAccepts := false` run, an underfunded `10 4 3` run, plus `escrowed = msgValue` on three of those and a `replay` equality on the first (`denoteTransaction` of the discovered `List CompiledCall` matches `observe`’s balance sheet — the only non-arithmetic content, still one numeral). Proof is `decide` / kernel reduction (`audit/P-ETH-1-COMPOSITION.md`). Dispatch itself is a fueled DFS that executes each `FunctionSpec` and prepends journaled child frames.

## Issues

## Resolution

**Restated Lean/English.** Abstract is the `∀ (msgValue n fee : Nat)` match on `gatewayExecute` outcomes: three revert clauses plus an approved-and-conserving success clause. Verity is five numeral witnesses, not `∀`. Underfunded `(10,4,3)` is a counterexample to a universal split.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1 | C | Wave 1 journal classification makes lateral destinations representable; Wave 4 `misrouted_journal_kill_line_refutes_parent` refutes the parent's success conjunct on a misrouted-journal mutant of `gatewayExecute`. |
| 7, 8 | A | `finalWorld` / 7-account escrow named honestly. |
| 2 | A | Verity parent is a numeric ensemble; kill-lines `underfunded_batch_is_not_a_repartition` / `large_funded_batch_exhausts_fuel_budget` refute a `∀` reading (Wave 2). |
| 3, 5, 10, 15, 17 | scope | Extra ETH sites, hops, ABI in `missing`. |
| 4, 6, 9, 11, 18, 19, 20 | A | Declared-amount, two planes, fuel, sinks, fee slot, replay. |
| 12, 14 | C | Post-`mul` wrap-check reverts when `(a*b)/a ≠ b`. |
| 13 | C | `gatewayExecute` reverts `ZeroArgument` at `msgValue = 0` and the parent's first clause pins it; Wave 4 `zero_value_success_kill_line_refutes_parent` shows the guard is load-bearing. |
| 16 | A | 160-bit wrap documented. |


1. **“No lateral destination” was unfalsifiable on the abstract type — closed in Waves 1 and 4.**
   The pre-Wave-1 parent built its move lists by hand, so no constructor argument could place wei on `.other` and the first conjunct could not fail. Wave 1 re-derived destinations from journaled call addresses via `classifyJournal` against an `ApprovedSet`, making lateral destinations representable: `parentApproved (.other _) = False`, and any journaled address outside the set classifies to `.other`. Wave 4 then made the conjunct genuinely load-bearing: `Tests.PEth1CompositionTxMutants.misrouted_journal_kill_line_refutes_parent` runs the funded success case `(10, 2, 3)` through `gatewayExecuteMisrouted` — the same guard chain and split as `gatewayExecute`, but with the fee legs journaled to the operator-supplied `rogueFeeSink = 999`, classified `.other 999` — and proves the registered parent's exact success conjunct is false on that mutant's output. The hand-built-list theorem survives only as `confirms_lateral_journal_entry_is_not_parent_approved`, a classifier sanity check.

   *Scenario the guarantee now catches.* A patched `ConsolidationGateway` fee or refund leg that sends wei to `tx.origin` or to an operator-supplied address off the `ApprovedSet` produces an `.other` move and violates the parent's first success conjunct — proved executable on the mutant, not just asserted in prose.

2. **The Verity parent is a unit-test bundle, not a theorem about all batches.**
   The named theorem mentions only the tuples `(msgValue, batchSize, fee) ∈ {(10,2,3),(10,1,3),(6,2,3),(10,2,3 false),(10,4,3)}`. It does not quantify over `msgValue`, `feePerRequest`, or `batchSize`.

   *Counterexample to the claimed generality.* `run honest 100 10 7` (fee 70, refund 30) is not a conjunct. Nothing in the Lean statement fails if that run mis-routed the refund. Mutants (`drop` refund, `misroute` vault to Lido, `refundWholeValue`) are separate tests on `Wiring`; they are not the CHECKED theorem.

3. **Inventory is incomplete versus deployed ETH-bearing sites.**
   Pinned SRv3 also moves ETH through `VaultHub.withdraw` / `Dashboard.withdraw` (protocol-controlled, **any** `_recipient`), `StakingVault.withdraw`, `StakingVault.triggerValidatorWithdrawals` (EIP-7002 + excess refund to a caller-chosen address), `TriggerableWithdrawalsGateway`, `WithdrawalQueueBase._sendValue` (payout to the *claimant*), `Lido.submit`, and beacon `deposit{value:}`.

   *Scenario.* Owner with `WITHDRAW_ROLE` calls `Dashboard.withdraw(attacker, 100 ether)`. ETH leaves the stVault to `attacker`. No `gatewayExecute` leg models this; the theorem names VaultHub / `StakingVault.withdraw` out of scope explicitly. Separately, `TriggerableWithdrawalsGateway.triggerFullWithdrawals` (`:165–190`) — the contract the Lean gateway is *named* after — pays EIP-7002 fees and refunds; it has no `gatewayExecute` leg either. CHECKED covers the modeled gateway execution, not every ETH-bearing path of SRv3.

4. **Declared-amount convention is not the deployed calling convention.**
   Every `LinkedExternal.value` is `0`; the amount rides in calldata word 0; the dispatcher copies it into `CallSite.value`. Source never takes `amount` as calldata word 0.

   *Scenario.* A real body does `vault.call{value: fee}(...)` *and* the frame also debited `CallSite.value`. The model would double-charge, so the harness zeroed link value. That is a harness invariant, not a Lido invariant. `A-ABSTRACT-TX` plus this convention means the composition is a different protocol.

5. **FunctionSpecs are not the pinned functions.**
   The compilation model is named `TriggerableWithdrawalsGateway` (`PEth1CompositionTx.lean:131–154`) — a **different** deployed contract than `ConsolidationGateway`. Gateway is named `triggerConsolidation` with params `(amount, batchSize)`. Deployed `ConsolidationGateway.addConsolidationRequests` takes `ConsolidationWitnessGroup[]`, checks SSZ, consumes quota, expands groups, then calls the vault. Deployed `ConsolidationBus.executeConsolidation` (`:383–406`) hashes the pending batch, waits `_executionDelay`, deletes it, and forwards `{value: msg.value}` with **`msg.sender` as refund recipient**. The model refunds hardcoded `refundAddr = 6` (`senderAddr = 7`), has no batch hash / delay / delete.

   *Scenario.* A witness/quota bug sends an extra fee CALL, or the executor (`msg.sender`) is refunded instead of a supplied `refundRecipient`. The ensemble cannot represent batch-not-found / delay-not-passed / hash mismatch; the CHECKED split still holds of `(10, 2, 3)`.

6. **Abstract and Verity planes are not refined to each other.**
   No lemma relates `gatewayExecute`'s move list to `observe (run honest 10 2 3)`. Parent Verity never runs an EIP-7002 or `withdrawWithdrawals` leg, and the abstract parent has no legs for them beyond the `ApprovedSet`'s two addresses.

   *Scenario.* Change the fee-leg destination in `gatewayExecute` to `.other 0` and leave the Verity ensemble alone. `eth_flow_parent` fails; `verity_tx_composes_value_flow_and_rollback` still holds. The two CHECKED marks are independent. (The Wave 4 `gatewayExecuteMisrouted` mutant is essentially this change, executed against the abstract parent only.)

7. **Rollback / conservation-on-revert are `finalWorld` by definition.**
   `finalWorld` returns `entryWorld` on any non-`.success` (`PEth1CompositionTx.lean:343–347`). `observe` reads `finalWorld`. So the reject-request balance sheet `⟨10,0,0,0,0,0,0⟩` follows from `initial 10 _` plus the wrapper, even if the dispatcher never undid anything.

   *Scenario.* Delete the dispatcher’s restore and keep `finalWorld` as written. The registered revert conjuncts still hold. The mutant `observeWithoutRollback` only shows `lastWorld` was dirtied; it does not prove EVM CALL-revert semantics (`A-ABSTRACT-TX`).

8. **`escrowed` / `BalanceView` only see the seven seeded accounts.**
   `initial` creates sender, bus, gateway, vault, lido, request, refund. `escrowed` is the sum of those `selfBalance`s. `lidoAddr` is a sink the honest program never calls, so `lido = 0` on every success run.

   *Scenario.* Add an eighth address that a mutant gateway pays. That address is not in `BalanceView`. `escrowed` still equals `msgValue` because the missing wei is not in the sum. The CHECKED conservation conjunct cannot see an off-sheet leak.

9. **`fuelBudget = 32` silently changes the theorem’s meaning for large batches.**
   `PEth1CompositionTx.fuelBudget` is 32 frames. A 40-request batch hits `TxControl.exhausted` and `finalWorld` restores the entry world.

   *Scenario.* `run honest 40 40 1` (fee 40, exact). Source vault loops 40 CALLs. Lean stops at 32 hops and reports `exhausted`, which `observe` treats like a revert (entry balances). The registered theorem never mentions this. CHECKED “atomic compiled multicall” is a 32-frame cap.

   *Executable (Wave 2).* `PEth1CompositionTxMutants.large_funded_batch_exhausts_fuel_budget` proves `(run honest 30 29 1).control = .exhausted` — a funded (`29 * 1 ≤ 30`), guard-passing batch that still cannot reach the registered parent's success shape. This is a kill-line against generalizing the registered Verity parent to `∀` funded batches, not just against this report's prose.

10. **The abstract parent omits the Bus→Gateway and Gateway→Vault hops.**
   The inventory comment lists those CALLs. `gatewayExecute`'s success list is only `List.replicate n` fee moves plus the optional refund move. Intermediate forwards of `msg.value` / `totalFee` are not `EthMove`s. Conservation is `n*fee + refund = msg.value`, which counts the same wei once at the terminal, not at each hop.

   *Scenario.* Gateway keeps `msg.value` and also pays the vault from its own pocket. Terminal fees + refund still sum to `msg.value`. `eth_flow_parent` holds. The protocol’s intermediate balance sheet is not in the theorem.

11. **The refund sink always accepts.**
   `sinkFn "RefundRecipient" true` (`PEth1CompositionTx.lean:227–228`) cannot revert. Live `_refundFee` (`ConsolidationGateway.sol:302–304`) reverts `FeeRefundFailed` if `recipient.call{value: refund}` fails. `preservesEthBalance` then reverts the whole gateway tx.

   *Scenario.* `refundRecipient` is a contract whose fallback reverts. Live `addConsolidationRequests` reverts and rolls back the vault fee CALL. Lean `run honest 10 2 3` still commits `⟨0,0,0,0,0,6,4⟩`. The CHECKED success numeral is not the deployed refund.

12. **Gateway/vault `.mul` wraps; Solidity 0.8 reverts.**
   `evalExpr` on `.mul` is `(lhs * rhs).val` — wrapping `Uint256` (`Verity/Core/Model/Denote.lean:712–715`). The ensemble computes `fee = batchSize * feePerRequest` that way (`PEth1CompositionTx.lean:140, 172`). Live `requestsCount * fee` (`ConsolidationGateway.sol:212`) is checked `uint256` and panics on overflow.

   *Counterexample.* `batchSize = 2^128`, `feePerRequest = 2^128`, `msgValue = 1`. Live `totalFee` overflows and the tx reverts. Lean `mul` wraps to `0`. `require(0 ≤ 1)` passes. The run can succeed with fee 0 (no request value, full refund). The CHECKED numerals never hit this; the ensemble is not 0.8 multiplication.

13. **`run honest 0 0 3` is a phantom success on the Verity plane.**
   On the abstract plane this is closed: `gatewayExecute` reverts `ZeroArgument` at `msgValue = 0` and the parent's first clause pins the behaviour. Wave 4 shows the clause is load-bearing — `gatewayExecuteUnguarded` drops the value guards, `(0, 2, 3)` succeeds paying 6 wei of fees, and `zero_value_success_kill_line_refutes_parent` refutes the parent's success conjunct on that mutant. The Verity parent still does not mention the zero-value run.

   *Scenario.* `run honest 0 0 3`: fee `0`, vault `FeeMismatch` is `0 == 0`, `forEach 0`, success with no request hops. Source gateway reverts `ZeroArgument("msg.value")` / empty groups. The registered Verity theorem does not mention this run; CHECKED suggests the split law holds in general. Lean `Nat` `requestsCount * fee` also cannot overflow; Solidity 0.8 reverts.

14. **Abstract fee arithmetic is unbounded `Nat` multiply; Verity `.mul` wraps; no refinement.**
    `composed_eth_conservation` is `fee + (msgValue - fee) = msgValue` under `fee ≤ msgValue` — true of any two Nats — and the abstract parent's overflow clause (`n * fee ≥ 2^256` reverts `Panic(0x11)`) is a model-side guard inside `gatewayExecute`, not a lemma about the Verity ensemble. The Verity ensemble multiplies with wrapping `Expr.mul` (issue 12). There is no lemma relating `gatewayExecute`'s move list to `observe (run …)`.

    *Counterexample.* `n = 2^128`, `fee = 2^128`. Abstract parent: `n * fee = 2^256 ≥ 2^256`, so the model reverts overflow for any `msgValue`. Verity wrap product is `0` and can succeed with a full refund (issue 12). Both CHECKED theorems hold of their own plane; the overflow guard is not the child's multiplication.

15. **EIP-7002 / withdrawals-to-Lido legs run on neither parent.**
    `gatewayExecute` emits only consolidation-fee and refund legs; `EthDestination.withdrawalRequestContract` and `.lido` exist as tags but no `gatewayExecute` branch produces them, and `verity_tx_composes_value_flow_and_rollback` only executes the consolidation ensemble (`run honest …`). P-ETH-1a’s `withdrawToLido` and P-ETH-1b’s `sendWithdrawalFee` are different modules, different numerals.

    *Scenario.* A mutant sending the fee leg to `.lido` — an approved tag, but the wrong contract — passes the abstract parent's `parentApproved` check: within the `classifyJournal` model an approved tag can only arise from a journaled address that matches the `ApprovedSet`, so tag-vs-contract confusion is a configuration error the parent cannot see. The Wave 4 misroute mutant covers the complementary case (off-set address → `.other` → caught). The registered Verity parent is unchanged by either.

16. **Dispatcher `callee` is `Address.ofNat` of the journaled target — 160-bit wrap.**
    `PEth1CompositionTx.childPending` (`:262–271`) sets `callee := Core.Address.ofNat entry.target` and `value := entry.calldata.headD 0`. Two targets that differ by `2^160` collapse to the same registry key. The honest wiring only uses addresses 1–7, so the numerals hide this.

    *Counterexample.* A mutant gateway journals `target = 1 + 2^160` (would be a lateral address on chain). `wordToAddress` / `Address.ofNat` maps it to account 1 (`busAddr`). Dispatch re-enters the bus instead of an unknown target. `unknownTarget` is never taken. The CHECKED ensemble cannot represent a 160-bit-truncated retarget; `nodeAt` is a 6-address `if` chain.

17. **Bus `FunctionSpec` is `(amount, batchSize)` plus `require(msg.value == amount)`; live `executeConsolidation` takes groups only.**
    `busFn` (`PEth1CompositionTx.lean:115–123`) is `executeConsolidation(amount, batchSize)` with `declaredValueCheck`. Live `ConsolidationBus.executeConsolidation` (`:383–406`) is `payable` and takes `ConsolidationWitnessGroup[] groups` — no amount argument, no `msg.value == amount` require. It forwards `{value: msg.value}` after the batch-hash / delay checks.

    *Scenario.* Caller sends `msg.value = 10` with a well-formed pending batch. Live forwards 10 to the gateway. Lean requires the *calldata word* `amount` to equal 10 (declared-amount convention, issue 4). A compiled bus call with the real ABI (groups, no amount) cannot even enter `busFn`. The CHECKED success numeral `run honest 10 2 3` is a different function than the mapped `executeConsolidation`.

18. **Fee is a stored slot on gateway *and* vault, not `getConsolidationRequestFee`.**
    `gatewayFn` / `vaultFn` multiply `batchSize * storage "feePerRequest"` (slot 0). `initial` writes the same seed into both accounts (`PEth1CompositionTx.lean:317–325`). Live vault takes the fee from the EIP-7251 predeploy (`_getFeeFromContract` / `getConsolidationRequestFee`) and `_requireExactFee(count * fee)`. There is no fee `staticcall` in the ensemble.

    *Scenario.* Predeploy fee updates from `3` to `4` after the gateway computed `2·3 = 6`. Live vault reverts `IncorrectFee` / `FeeMismatch`. Lean still has slot `3` on both contracts: `run honest 10 2 3` commits `⟨0,0,0,0,0,6,4⟩`. The CHECKED split assumes a frozen, locally stored fee. A real fee change — the thing the exact-fee guard is for — cannot appear.

19. **`replay` is the same dispatcher on the recorded program, not a compiled multicall.**
    The last conjunct of `verity_tx_composes_value_flow_and_rollback` (`PEth1.lean:300–307`) is `program.length = 6` and `replay run = observe.run.balances` for `(10,2,3)`. `replay` (`PEth1CompositionTx.lean:388–389`) is `denoteTransaction entryWorld program` — a *different* interpreter than `step` / `run`. The equality is one numeral on which the two interpreters happen to agree.

    *Scenario.* Change `vaultFn` to send the fee to `lidoAddr`. Both `run` and `replay` mis-route the same way if they share the body, so the equality still holds. If `denoteTransaction` and `step` ever diverged on another batch, the CHECKED conjunct would not mention it. The YAML “atomic compiled multicall” is a self-consistency check of one harness, not `solc` output of `addConsolidationRequests`. Combined with issue 4 (declared-amount) and issue 17 (wrong bus ABI), the replay cannot become the deployed transaction.

20. **The Lido sink always accepts, like the refund sink.**
    `sinkNode "Lido" true 6` (`PEth1CompositionTx.lean:229–230`) cannot revert. Live `Lido.receiveWithdrawals` (`Lido.sol:530–534`) is `_auth(_withdrawalVault())` — only the vault may call. The parent `withdrawalsToLido` constructor never runs on this ensemble (issue 15), but `lidoAddr` is still in the world and would accept any hop.

    *Scenario.* A mutant gateway pays Lido instead of the vault. Lean `Lido` sink accepts; `escrowed` still sums to `msgValue` (issue 8). Live `receiveWithdrawals` from the gateway reverts (not the vault). The CHECKED conservation conjunct cannot see a rejected Lido payment because the sink is `accepts := true`. Same shape as issue 11 (refund).
