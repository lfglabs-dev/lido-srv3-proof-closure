# P-ETH-1

Theorems: `PEth1.eth_flow_parent`, `PEth1.verity_tx_composes_value_flow_and_rollback`.
Assumptions: `A-ABSTRACT-TX`, `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

SRv3 moves ETH along a small set of protocol paths: `ConsolidationBus` forwards `msg.value` to `ConsolidationGateway`; the gateway pays `requestsCount × fee` into `WithdrawalVault` and refunds the rest; the vault pays the EIP-7251 `CONSOLIDATION_REQUEST` predeploy (and, separately, EIP-7002 `WITHDRAWAL_REQUEST`); `WithdrawalVault.withdrawWithdrawals` sends finalized EL rewards / withdrawals to Lido. The intended guarantee is that those paths never leak wei to a lateral address and that what goes out equals what came in.

## Modeling

- `A-ABSTRACT-TX`: success/revert are not EVM traces.
- `A-SOURCE-SHAPED`: Bus / Gateway / Vault in `PEth1CompositionTx` are audit-authored `FunctionSpec`s (`executeConsolidation`, `triggerConsolidation`, `addConsolidationRequests`) — names and bodies are not the pinned Solidity functions.
- `A-VERITY-SCAFFOLD`.
- **Declared-amount convention** (PEth1CompositionTx header): every `LinkedExternal.value` is `0`. The body puts the amount in calldata word 0; the dispatcher copies it into `CallSite.value`; the callee `require`s `msg.value == amount`. Real Solidity pays via `call{value: x}`. The model cannot express a body that both transfers and forwards the same wei (it would double-debit).
- `EthPath` has three constructors only: `consolidation`, `withdrawalRequests`, `withdrawalsToLido`. Owner-controlled `StakingVault.withdraw`, `Lido.submit`, WithdrawalQueue claims, EL-rewards sweep, and module deposits are not constructors.
- `pathTrace` never builds `EthDestination.other`. Lateral leakage is unrepresentable.
- Composition covers Bus→Gateway→Vault→request plus refund. Abstract `withdrawalsToLido` / `withdrawalRequests` are *not* in the composed Verity run (`audit/P-ETH-1-COMPOSITION.md` says so).

## Proof

**Abstract `eth_flow_parent`.** Case split on `EthPath`.
- `consolidation`: `pathFunded` is `count * fee ≤ msg.value`. `pathTrace` is `replicate count {fee, consolidationContract} ++ refundMoves`. Membership in `replicate` gives destination `consolidationContract`; `refundMoves` is empty or `{refund, refundRecipient}`. Neither is `.other`, so `parentApproved` holds by constructor. Sum: `count * fee + (msg.value − count * fee) = msg.value` (`omega`), with the zero-refund branch using `totalAmount [] = 0`.
- `withdrawalRequests` / `withdrawalsToLido`: the trace is a `replicate` or a singleton of an approved destination; the sum is `n * fee` or `amount` by `totalAmount_replicate` (induction on `n`) / `totalAmount_cons`.

No relation to a contract is used. The proof is arithmetic + “the list we built contains only the tags we put in it.”

**VERITY `verity_tx_composes_value_flow_and_rollback`.** Not a `∀` statement. It is a finite conjunction of concrete runs of `PEth1CompositionTx.run honest 10 2 3`, `10 1 3`, `6 2 3`, a `requestAccepts := false` run, an underfunded `10 4 3` run, plus `escrowed = msgValue` on three of those and a `replay` equality on the first (`denoteTransaction` of the discovered `List CompiledCall` matches `observe`’s balance sheet — the only non-arithmetic content, still one numeral). Proof is `decide` / kernel reduction (`audit/P-ETH-1-COMPOSITION.md`). Dispatch itself is a fueled DFS that executes each `FunctionSpec` and prepends journaled child frames.

## Issues

## Resolution

**Restated Lean/English.** Abstract is the three-constructor `EthPath` + `pathFunded`. Verity is five numeral witnesses, not `∀`. Underfunded `(10,4,3)` is a counterexample to a universal split.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1, 7, 8 | A | Tagged inventory / `finalWorld` / 7-account escrow named honestly. |
| 2 | A | Verity parent is a numeric ensemble. |
| 3, 5, 10, 15, 17 | scope | Extra ETH sites, hops, ABI in `missing`. |
| 4, 6, 9, 11, 18, 19, 20 | A | Declared-amount, two planes, fuel, sinks, fee slot, replay. |
| 12, 14 | C | Post-`mul` wrap-check reverts when `(a*b)/a ≠ b`. |
| 13 | C | `pathFunded` now requires `0 < msgValue`. |
| 16 | A | 160-bit wrap documented. |


1. **“No lateral destination” is unfalsifiable on the abstract type.**
   `parentApproved (.other _) = False` and `parentApproved _ = True`. `pathTrace` only ever inserts `.consolidationContract`, `.refundRecipient`, `.withdrawalRequestContract`, `.lido`. There is no constructor argument that could place wei on `.other`. The first conjunct of `eth_flow_parent` cannot fail for any `EthPath`.

   *Scenario the guarantee should catch.* A patched `ConsolidationGateway._refundFee` sends the remainder to `tx.origin` or to an operator-supplied address that is not the documented refund recipient. That destination is not an `EthPath` constructor, so the parent is silent. The CHECKED theorem still holds of the hand-built lists.

2. **The Verity parent is a unit-test bundle, not a theorem about all batches.**
   The named theorem mentions only the tuples `(msgValue, batchSize, fee) ∈ {(10,2,3),(10,1,3),(6,2,3),(10,2,3 false),(10,4,3)}`. It does not quantify over `msgValue`, `feePerRequest`, or `batchSize`.

   *Counterexample to the claimed generality.* `run honest 100 10 7` (fee 70, refund 30) is not a conjunct. Nothing in the Lean statement fails if that run mis-routed the refund. Mutants (`drop` refund, `misroute` vault to Lido, `refundWholeValue`) are separate tests on `Wiring`; they are not the CHECKED theorem.

3. **Inventory is incomplete versus deployed ETH-bearing sites.**
   Pinned SRv3 also moves ETH through `VaultHub.withdraw` / `Dashboard.withdraw` (protocol-controlled, **any** `_recipient`), `StakingVault.withdraw`, `StakingVault.triggerValidatorWithdrawals` (EIP-7002 + excess refund to a caller-chosen address), `TriggerableWithdrawalsGateway`, `WithdrawalQueueBase._sendValue` (payout to the *claimant*), `Lido.submit`, and beacon `deposit{value:}`.

   *Scenario.* Owner with `WITHDRAW_ROLE` calls `Dashboard.withdraw(attacker, 100 ether)`. ETH leaves the stVault to `attacker`. There is no `EthPath` constructor for this. Separately, `TriggerableWithdrawalsGateway.triggerFullWithdrawals` (`:165–190`) — the contract the Lean gateway is *named* after — pays EIP-7002 fees and refunds; it is not a constructor either. The parent comment’s “complete inventory” is a scope cut. CHECKED “every ETH-bearing path” is false of SRv3.

4. **Declared-amount convention is not the deployed calling convention.**
   Every `LinkedExternal.value` is `0`; the amount rides in calldata word 0; the dispatcher copies it into `CallSite.value`. Source never takes `amount` as calldata word 0.

   *Scenario.* A real body does `vault.call{value: fee}(...)` *and* the frame also debited `CallSite.value`. The model would double-charge, so the harness zeroed link value. That is a harness invariant, not a Lido invariant. `A-ABSTRACT-TX` plus this convention means the composition is a different protocol.

5. **FunctionSpecs are not the pinned functions.**
   The compilation model is named `TriggerableWithdrawalsGateway` (`PEth1CompositionTx.lean:131–154`) — a **different** deployed contract than `ConsolidationGateway`. Gateway is named `triggerConsolidation` with params `(amount, batchSize)`. Deployed `ConsolidationGateway.addConsolidationRequests` takes `ConsolidationWitnessGroup[]`, checks SSZ, consumes quota, expands groups, then calls the vault. Deployed `ConsolidationBus.executeConsolidation` (`:383–406`) hashes the pending batch, waits `_executionDelay`, deletes it, and forwards `{value: msg.value}` with **`msg.sender` as refund recipient**. The model refunds hardcoded `refundAddr = 6` (`senderAddr = 7`), has no batch hash / delay / delete.

   *Scenario.* A witness/quota bug sends an extra fee CALL, or the executor (`msg.sender`) is refunded instead of a supplied `refundRecipient`. The ensemble cannot represent batch-not-found / delay-not-passed / hash mismatch; the CHECKED split still holds of `(10, 2, 3)`.

6. **Abstract and Verity planes are not refined to each other.**
   No lemma `pathTrace (.consolidation ⟨10,2,3⟩) ↔ observe (run honest 10 2 3)`. Parent Verity never runs the EIP-7002 or `withdrawWithdrawals` legs the abstract parent “covers.”

   *Scenario.* Change `pathTrace`’s Lido tag to `.other 0` and leave the Verity ensemble alone. `eth_flow_parent` fails; `verity_tx_composes_value_flow_and_rollback` still holds. The two CHECKED marks are independent.

7. **Rollback / conservation-on-revert are `finalWorld` by definition.**
   `finalWorld` returns `entryWorld` on any non-`.success` (`PEth1CompositionTx.lean:343–347`). `observe` reads `finalWorld`. So the reject-request balance sheet `⟨10,0,0,0,0,0,0⟩` follows from `initial 10 _` plus the wrapper, even if the dispatcher never undid anything.

   *Scenario.* Delete the dispatcher’s restore and keep `finalWorld` as written. The registered revert conjuncts still hold. The mutant `observeWithoutRollback` only shows `lastWorld` was dirtied; it does not prove EVM CALL-revert semantics (`A-ABSTRACT-TX`).

8. **`escrowed` / `BalanceView` only see the seven seeded accounts.**
   `initial` creates sender, bus, gateway, vault, lido, request, refund. `escrowed` is the sum of those `selfBalance`s. `lidoAddr` is a sink the honest program never calls, so `lido = 0` on every success run.

   *Scenario.* Add an eighth address that a mutant gateway pays. That address is not in `BalanceView`. `escrowed` still equals `msgValue` because the missing wei is not in the sum. The CHECKED conservation conjunct cannot see an off-sheet leak.

9. **`fuelBudget = 32` silently changes the theorem’s meaning for large batches.**
   `PEth1CompositionTx.fuelBudget` is 32 frames. A 40-request batch hits `TxControl.exhausted` and `finalWorld` restores the entry world.

   *Scenario.* `run honest 40 40 1` (fee 40, exact). Source vault loops 40 CALLs. Lean stops at 32 hops and reports `exhausted`, which `observe` treats like a revert (entry balances). The registered theorem never mentions this. CHECKED “atomic compiled multicall” is a 32-frame cap.

10. **`pathTrace` omits the Bus→Gateway and Gateway→Vault hops.**
   The inventory comment lists those CALLs. `pathTrace (.consolidation t)` is only `replicate count {fee, consolidationContract} ++ refundMoves`. Intermediate forwards of `msg.value` / `totalFee` are not `EthMove`s. Conservation is `n*fee + refund = msg.value`, which ignores that the same wei is counted once at the terminal, not at each hop.

   *Scenario.* Gateway keeps `msg.value` and also pays the vault from its own pocket. Terminal fees + refund still sum to `msg.value`. `eth_flow_parent` holds. The protocol’s intermediate balance sheet is not in the theorem.

11. **The refund sink always accepts.**
   `sinkFn "RefundRecipient" true` (`PEth1CompositionTx.lean:227–228`) cannot revert. Live `_refundFee` (`ConsolidationGateway.sol:302–304`) reverts `FeeRefundFailed` if `recipient.call{value: refund}` fails. `preservesEthBalance` then reverts the whole gateway tx.

   *Scenario.* `refundRecipient` is a contract whose fallback reverts. Live `addConsolidationRequests` reverts and rolls back the vault fee CALL. Lean `run honest 10 2 3` still commits `⟨0,0,0,0,0,6,4⟩`. The CHECKED success numeral is not the deployed refund.

12. **Gateway/vault `.mul` wraps; Solidity 0.8 reverts.**
   `evalExpr` on `.mul` is `(lhs * rhs).val` — wrapping `Uint256` (`Verity/Core/Model/Denote.lean:712–715`). The ensemble computes `fee = batchSize * feePerRequest` that way (`PEth1CompositionTx.lean:140, 172`). Live `requestsCount * fee` (`ConsolidationGateway.sol:212`) is checked `uint256` and panics on overflow.

   *Counterexample.* `batchSize = 2^128`, `feePerRequest = 2^128`, `msgValue = 1`. Live `totalFee` overflows and the tx reverts. Lean `mul` wraps to `0`. `require(0 ≤ 1)` passes. The run can succeed with fee 0 (no request value, full refund). The CHECKED numerals never hit this; the ensemble is not 0.8 multiplication.

13. **`pathFunded` is `True` for two of three constructors; `run honest 0 0 3` is a phantom success.**
   `pathFunded (.withdrawalRequests _ _) = True` and `pathFunded (.withdrawalsToLido _) = True`. The prose “provided the Gateway fee guard holds” does not apply to 2/3 of the inventory.

   *Scenario.* `run honest 0 0 3`: fee `0`, vault `FeeMismatch` is `0 == 0`, `forEach 0`, success with no request hops. Source gateway reverts `ZeroArgument("msg.value")` / empty groups. The registered theorem does not mention this run; CHECKED suggests the split law holds in general. Lean `Nat` `requestsCount * fee` also cannot overflow; Solidity 0.8 reverts.

14. **Abstract `consolidationFee` is unbounded `Nat` multiply; Verity `.mul` wraps; no refinement.**
    `PEth1.consolidationFee t = t.requestsCount * t.feePerRequest` (`PEth1.lean:157–158`). `composed_eth_conservation` is `fee + (msgValue - fee) = msgValue` under `fee ≤ msgValue` — true of any two Nats. The Verity ensemble multiplies with wrapping `Expr.mul` (issue 12). There is no lemma `pathTrace t = observe (run … t)`.

    *Counterexample.* `requestsCount = 2^128`, `feePerRequest = 2^128`. Abstract fee is `2^256`; `pathTrace` wants `2^256` wei of consolidation moves (or the parent does not apply if `msgValue < 2^256`). Verity wrap product is `0` and can succeed with a full refund (issue 12). Both CHECKED theorems hold of their own plane. The parent “split law” is not the child’s multiplication.

15. **`withdrawalsToLido` / EIP-7002 constructors never run on the Verity parent.**
    `eth_flow_parent` cases on all three `EthPath` constructors. `verity_tx_composes_value_flow_and_rollback` only executes the consolidation ensemble (`run honest …`). P-ETH-1a’s `withdrawToLido` and P-ETH-1b’s `sendWithdrawalFee` are different modules, different numerals.

    *Scenario.* Change `pathTrace (.withdrawalsToLido 5)` to send 5 wei to `.other 0`. `eth_flow_parent` fails on that constructor. The registered Verity parent is unchanged (it never builds that path). CHECKED “every ETH-bearing path” is an abstract `Inductive` plus one consolidation harness.

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
