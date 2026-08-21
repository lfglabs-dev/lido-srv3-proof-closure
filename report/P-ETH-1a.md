# P-ETH-1a (retired as P-ETH-1 child)

> Status: **retired**. This row is no longer a subordinate guarantee under P-ETH-1.

Its real subject is vault → Lido / WithdrawalQueue protocol returns. That does not align with the P-ETH-1 consolidation fee/refund happy path, and it is not P-RESERVE-1 buffer/spend accounting. Lean modules (`eth_flow_confined`, `PEth1RefundTx`) remain as **unregistered auxiliary** builds only. A future claim “protocol ETH exits only to Lido/WQ” should be a new guarantee (or folded into a relevant existing one), not restored as an ETH-1 child.

The historical product note and proof audit below are retained for provenance.

---

> Round 2 (2026-08-21). Product note plus proof audit, arbitrated from GPT 5.6 Pro and Opus 5. Fable 5 was unavailable (data-retention gate). Kimi K3 was not an allowed Task model. No em dashes. Lean is authority.

Child of P-ETH-1 for protocol-controlled ETH returns on the consolidation path: the gateway sends a total fee to the WithdrawalVault, refunds the remainder, and the vault can send an amount to Lido. This is not VaultHub or `StakingVault.withdraw`, where the owner picks the recipient.

- abstract `eth_flow_confined`: if every move is already tagged Lido or WithdrawalQueue, filtering to those tags removes nothing
- Verity `gateway_refund_success_moves_value`: one numeral, $\mathrm{msgValue}=5$, $\mathrm{fee}=3$, vault $+3$, refund recipient $+2$

The refund recipient is not one of the abstract approved tags. The ledger takes a single total-fee word, so $\mathrm{requestsCount} \times \mathrm{fee}$ is not here. We do not cover WithdrawalQueue claims or `receiveWithdrawals` buffer update (P-RESERVE-1).

## Proof limitations and recommendations

`eth_flow_confined` is `List.filter_eq_self` under its own hypothesis. The parent's happy path uses `.consolidationContract` and `.refundRecipient`, which `is_approved` rejects, so the child theorem does not apply to those traces. The executable model now has the producer theorem `sourceGateway_committed_splits_to_vault_and_refund` and the named `refund_misroute_kill_line`. The child row now names its inherited assumptions explicitly.

CHECKED does not mean protocol ETH returns land only on Lido or the WithdrawalQueue.

Ranked next work: the producer theorem, refund-misroute kill-line, and assumptions honesty edits landed; keep VaultHub out.

Theorems: `PEth1.eth_flow_confined` (abstract), `PEth1RefundTx.sourceGateway_committed_splits_to_vault_and_refund` (producer), `PEth1RefundTx.gateway_refund_success_moves_value` (verity), `PEth1RefundTxMutants.refund_misroute_kill_line` (kill-line).
Assumptions: `A-ABSTRACT-TX`, `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

Child of P-ETH-1. Restricts the *protocol-controlled stVault rebalance / redemption* ETH returns: money that the protocol itself sends back should land on Lido or the WithdrawalQueue, not on an arbitrary address. In the architecture that is `WithdrawalVault.withdrawWithdrawals` → `LIDO.receiveWithdrawals`, plus the gateway’s fee send to the vault and the leftover refund to the chosen refund recipient (refund is *not* Lido/WQ — see issues).

## Modeling

- Child YAML now lists the inherited assumptions explicitly: `A-ABSTRACT-TX` (not EVM traces), `A-SOURCE-SHAPED` (ledger is not extracted spans), and `A-VERITY-SCAFFOLD`.
- `EthMove` / `is_approved` only allow `.lido` and `.withdrawalQueue`.
- `StakingVault.withdraw` is **explicitly excluded** (comment on `eth_flow_confined`): the owner may pick any nonzero recipient. That is the most powerful ETH-out path on a vault.
- Verity side is a **single-contract slot ledger** (`gatewaySlot`, `vaultSlot`, `refundSlot`, `lidoSlot`). External CALLs are `require vaultOk` / `require refundOk` booleans, not value-bearing frames.
- `gatewayRefund` writes gateway += msgValue, then vault += fee / gateway −= fee, then refund += remainder / gateway −= remainder. Order matches “vault call then `_refundFee`.”
- Refund recipient is a slot, not `msg.sender` vs supplied address (source `_refundFee` lines 295–307).
- No WithdrawalQueue address exists in the ledger at all.

## Proof

**Abstract `eth_flow_confined`.** Hypothesis: every `m ∈ moves` satisfies `is_approved m` (destination is `.lido` or `.withdrawalQueue`). Then `List.filter` of that predicate is the identity (`List.filter_eq_self`), so `totalAmount moves = totalAmount (approvedReturnMoves moves)`. No induction beyond the filter lemma. The list is arbitrary; nothing constructs it from a contract.

**VERITY `gateway_refund_success_moves_value`.** A single numeral:

```
gatewayRefund 5 3 true true
  on ledger ⟨gateway=10, vault=1, refund=4, lido=7⟩
  = committed ⟨10, 4, 6, 7⟩
```

i.e. net gateway 0, vault +3, refund +2. Proof: `decide`. Companion `#guard`s and `withdraw_success_moves_to_lido` (withdraw 5, vault 8→3, lido 7→12) are the same style. Rollback theorems *are* universal: any `Contract.run` revert restores the snapshot (case split on `Contract.run`).

## Issues

## Resolution

**Restyle.** Gateway body is `_checkFee`, vault send, then `_refundFee`. `resolvedRefundRecipient` remaps `address(0)` / `2^160` to `msg.sender`. Registered theorems stay numeric.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1, 2 | A | `eth_flow_confined` is a tagged-list filter. |
| 3 | A | Remainder-refund numeral kept. |
| 4–7, 9, 14, 15, 17 | scope | VaultHub, WQ, `preservesEthBalance`, slot≠balance, guards, `receiveWithdrawals`, total fee in `missing`. |
| 8, 16 | C | `resolvedRefundRecipient` remaps `0` / `2^160` to sender. |
| 10, 13 | C | Invented `ExactFeeHasNoRefund` deleted; exact-fee stays on `gatewayExactFee`. |
| 11, 12 | A | Nat vs `addPanic` / pass-through documented. |


1. **`eth_flow_confined` is a filter tautology.**
   If you already assume every move is approved, filtering to approved moves does nothing, so the totals match. The theorem does not constrain any execution.

   *Counterexample to the intended reading.* `moves = [{100, .lido}, {50, .withdrawalQueue}]` satisfies the hypothesis and the equality. `moves = [{100, .other 0xbad}]` simply makes the hypothesis false — the theorem does not *reject* that execution; it does not apply. There is no “the protocol only produces approved moves” lemma on this child. P-ETH-1’s `eth_flow_parent` is the only producer, and it never emits `.withdrawalQueue` either (its Lido-bound constructor uses `.lido`; the refund uses `.refundRecipient`, which `is_approved` **rejects**).

2. **Approved-set disagrees with the Verity ledger and with the parent.**
   Parent refunds to `.refundRecipient`, which `is_approved` does not accept. Child Verity `gatewayRefund` *does* credit `refundSlot`.

   *Scenario.* Compose `eth_flow_confined` with `pathTrace (.consolidation ⟨10, 2, 3⟩)`. That trace contains a `.refundRecipient` move of 4. The hypothesis `∀ m, is_approved m` is false, so the child theorem does not apply to the parent’s own happy path. The child is CHECKED as “rebalance/redemption confined to Lido or WQ” while its Verity success theorem is a gateway fee + refund path that is neither.

3. **The Verity theorem is one arithmetic example, not the refund spec.**
   `gateway_refund_success_moves_value` does not quantify over `msgValue`, `fee`, or starting balances.

   *Scenario.* Mutant `vault += fee + 1`. The registered theorem only mentions the `5/3` run (vault `1 → 4`). A different numeral, or a `∀`, would fail; this one might still be killed by the `5/3` vector — but a mutant that is wrong only when `fee = 0` is not. The `#guard`s are more examples, not a `∀`. YAML still claims “gateway fee send, refund, **and vault withdraw**”; `withdraw_success_moves_to_lido` is a different unregistered numeral.

4. **`StakingVault.withdraw` exclusion plus unmodeled protocol withdraw.**
   The comment excludes the raw owner function. The YAML summary still claims the *protocol-controlled* stVault rebalance/redemption interface.

   *Scenario.* `VaultHub.withdraw(vault, attacker, 50 ether)` (owner, fresh report, amount ≤ withdrawable) goes through `_withdrawFromVault` → `StakingVault.withdraw`. This is protocol-controlled, not the excluded raw entrypoint. ETH lands on `attacker`. The YAML “rebalance” path is `VaultHub.rebalance` → `LIDO.rebalanceExternalEtherToInternal{value:}` — also unmodeled. P-ETH-1a has no `VaultHub` / `Dashboard` model. CHECKED confinement is silent on both protocol vault exits.

5. **WithdrawalQueue is named in `is_approved` and never appears in `PEth1RefundTx`.**
   No theorem of this child moves wei to a WQ address. Live redemptions pay the **claimant** (`WithdrawalQueueBase._sendValue`), not the WQ contract.

   *Scenario.* User claims 10 ETH. Destination is the user’s EOA. `is_approved` would reject `.other user` and does not mention claimants. The abstract destination `.withdrawalQueue` is ornamental.

6. **Mapped `preservesEthBalance` is not in the ledger.**
   `audit/source-map.yaml` for P-ETH-1a includes `ConsolidationGateway.preservesEthBalance` 118–122 and `WithdrawalVault.preservesEthBalance` 81–85. Those modifiers snapshot `address(this).balance` and revert if it changed. `gatewayRefund` / `withdrawToLido` never read a self-balance; they add/sub slots.

   *Scenario.* A vault CALL that leaves leftover wei on the gateway. Live `preservesEthBalance` reverts the whole `addConsolidationRequests`. Lean `gatewayRefund` with `vaultOk = true` commits the slot updates. The mapped modifier is not executed.

7. **`withdrawToLido` spends a slot, not `address(this).balance`.**
   Live `withdrawWithdrawals` (`WithdrawalVault.sol:107–120`) requires `_amount ≤ address(this).balance` and then `LIDO.receiveWithdrawals{value: _amount}`. Lean requires `amount ≤ vaultSlot` (`PEth1RefundTx.lean:70–79`). The slot is only what `gatewayRefund` wrote.

   *Scenario.* Vault holds 10 ETH from EL rewards / withdrawals sweep; `vaultSlot` is still 1. Live Lido call `withdrawWithdrawals(5)` succeeds. Lean `withdrawToLido 5 true` reverts `NotEnoughEther`. Conversely, Lean can “withdraw” slot credit that was never real ETH. The CHECKED `withdraw_success_moves_to_lido` numeral (`vault 8→3`) is slot arithmetic, not the vault’s ETH.

8. **Zero refund recipient is not remapped to `msg.sender`.**
   Live `_refundFee` (`ConsolidationGateway.sol:297–300`): if `recipient == address(0)` then `recipient = msg.sender`. Lean `gatewayRefund` always credits `refundSlot`. No sender, no zero-address check.

   *Scenario.* Caller passes `refundRecipient = 0`. Live refunds `msg.sender`. Lean `gateway_refund_success_moves_value` credits slot 2 (`4→6` in the numeral) with no sender in the state. The CHECKED refund is not the deployed recipient resolution.

9. **Boolean CALLs; rollback is the `Contract.run` monad.**
   `vaultOk` / `refundOk` / `callerIsLido` are inputs. `refund_failure_restores_snapshot` is `unfold Contract.run; split` — `run` definitionally replaces any revert state with the pre-state.

   *Scenario.* Live vault CALL keeps the fee, then `_refundFee` fails; the EVM reverts the whole tx. The Lean program never performs an external CALL: it writes slot 1 then `require refundOk`. Proving the slot write disappears is the monad, not `addConsolidationRequests`. Extra revert `ExactFeeHasNoRefund` does not exist in Solidity (`gatewayRefund` rejects `fee = msgValue`; source just skips `_refundFee`).

10. **`sourceGateway` and `gatewayRefund` disagree on exact fee.**
    `sourceGateway` (`PEth1RefundTx.lean:123–128`) has no `fee != msgValue` arm: when `fee = msgValue` it returns `.committed fee 0`. `gatewayRefund` (`:39`) reverts `ExactFeeHasNoRefund` on that input. The exact-fee path is a *different* function (`gatewayExactFee`).

    *Counterexample.* `msgValue = 5`, `fee = 5`, `vaultOk = refundOk = true`, ledger `⟨10, 1, 4, 7⟩`. `sourceGatewayView` commits `⟨10, 6, 4, 7⟩` (vault +5, refund +0). `gatewayRefund 5 5 true true` reverts. The `#guard` that compares the two interpreters uses `(5, 3)` only. There is no `∀` correspondence. CHECKED “source-shaped refund” is two programs that part on the `msg.value = fee` case the live gateway actually takes (`_refundFee` is skipped, not reverted).

11. **Source `Nat` add/sub vs Verity `addPanic` / `subPanic`.**
    `sourceGatewayView` does `vault := before.vault + feeToVault` and `refundDest := before.refundDest + refundToDest` (`:142–145`) in unbounded `Nat`. `gatewayRefund` uses `addPanic` / `subPanic`.

    *Counterexample.* `vaultSlot` word is `2^256 − 1`, `fee = 3`, `msgValue = 5`. Source commits `vault = 2^256 + 2`. `addPanic v fee` reverts `Panic(0x11)`. Same for `refundDest = 2^256 − 1`. The registered `gateway_refund_success_moves_value` numeral (`vault 1→4`) never hits the wrap; the CHECKED success is not the 0.8 addition the comments advertise.

12. **`gatewayRefund` credits `gatewaySlot` by `msgValue` then subtracts fee and refund — a pass-through the live gateway never stores.**
    Live `addConsolidationRequests` is `payable preservesEthBalance`: ETH arrives as `msg.value`, the vault CALL spends `totalFee`, `_refundFee` spends the rest, and the modifier requires `address(this).balance` unchanged. There is no “gateway balance slot” that is incremented by `msg.value`. Lean `gatewayRefund` (`:42–55`) does `g += msgValue; g -= fee; g -= refund`, ending at the original `g` when the arithmetic does not wrap.

    *Scenario.* `gatewaySlot = 2^256 − 1`, `msgValue = 5`, `fee = 3`. `addPanic g msgValue` panics (issue 11) even though the *net* change of a pass-through is 0 and live `preservesEthBalance` would succeed (balance starts +5, vault takes 3, refund takes 2). The CHECKED ledger can revert on a conservative intermediate overflow that the deployed modifier never sees. The numeral `gateway 10→10` hides this.

13. **Live `_checkFee` is `unchecked` subtraction; Lean `subPanic`s the refund.**
    `ConsolidationGateway.sol:286–292`: if `msg.value < fee` revert; else `unchecked { refund = msg.value - fee; }`. `gatewayRefund` does `subPanic msgValue fee` after `fee ≤ msgValue`. They agree when the guard holds. `_refundFee` then skips on `refund == 0` (exact fee) — the case Lean invented `ExactFeeHasNoRefund` for (issue 10).

    *Scenario.* `msg.value = fee = 5`. Live `_checkFee` returns 0 (unchecked), `_refundFee` is a no-op, vault CALL of 5 proceeds. Lean `gatewayRefund 5 5` reverts (issue 10). `gatewayExactFee` is a different function and is not the registered theorem. The CHECKED refund path is not `_checkFee` + `_refundFee`.

14. **`withdrawToLido` does not call `LIDO.receiveWithdrawals`.**
    Live `withdrawWithdrawals` (`WithdrawalVault.sol:120`) does `LIDO.receiveWithdrawals{value: _amount}()`. That function (`Lido.sol:530–534`) is only `_auth(_withdrawalVault())` plus `WithdrawalsReceived`. It does **not** `_setBufferedEther`. The stored buffer is raised later, in `collectRewardsAndProcessWithdrawals` (`:1104–1109`), by adding a *declared* `_withdrawalsToWithdraw`. Lean `withdrawToLido` adds `amount` to `lidoSlot` and subtracts `vaultSlot`. No Lido function runs.

    *Scenario.* Vault holds 8, stored Lido buffer is 0, `withdrawWithdrawals(5)`. Live ETH lands on Lido; stored `buffered` is still 0 until the next accounting report names 5 (or some other number). Lean `withdraw_success_moves_to_lido` shows `lido 7→12` on a toy slot that P-RESERVE-1 never reads. The two CHECKED ETH/reserve theorems do not compose, and the live “to Lido” hop is not even a buffer write.

15. **Every pre-fee gateway guard is dropped.**
    Live `addConsolidationRequests` (`ConsolidationGateway.sol:185–223`) is `onlyRole(ADD_CONSOLIDATION_REQUEST_ROLE)`, `whenResumed`, nonempty groups, no `EmptyGroup`, `_checkConsolidationPreconditions` (DSM / `Lido.canDeposit()`), WC proofs, `_consumeConsolidationRequestLimit`, then `fee = getConsolidationRequestFee()`. `gatewayRefund` is `msgValue≠0`, `fee≤msgValue`, invented `fee≠msgValue`, then slot add/sub gated by booleans. `fee` is an argument.

    *Scenario.* Paused gateway, or caller without the role, or `groups = []`, or DSM paused, or requests over the frame quota. Live reverts before any vault CALL. `gateway_refund_success_moves_value` (`5/3` on `⟨10,1,4,7⟩`) still commits. The CHECKED success is a fee+refund arithmetic example with the real admission surface deleted.

16. **`refundRecipient = 2^160` is `address(0)` and remaps to `msg.sender`.**
    Extends issue 8 (zero recipient). Live `_refundFee` (`:297–300`): `if (recipient == address(0)) recipient = msg.sender`. `address(2^160) == address(0)`. Lean always credits `refundSlot`; no 160-bit mask.

    *Counterexample.* `refundRecipient = 2^160`, `msg.value = 5`, `fee = 3`, `msg.sender = 0xabc`. Live refunds 2 wei to `0xabc`. Lean `gatewayRefund` credits slot 2 regardless. `run honest 10 2 3` (P-ETH-1) still pays account `6`. CHECKED refund confinement is not 160-bit recipient resolution.

17. **There is no `requestsCount * fee` in `gatewayRefund`.**
    Live `addConsolidationRequests` (`:211–213`) does `fee = getConsolidationRequestFee()`, `totalFee = requestsCount * fee` (0.8 checked), then `_checkFee(totalFee)`. Lean `gatewayRefund` takes a single `fee` word. There is no `requestsCount` and no multiply (contrast P-ETH-1 issue 12, wrapping `Expr.mul` on the parent ensemble).

    *Scenario.* `requestsCount = 2`, per-request fee 5, `msg.value = 10`. Live `totalFee = 10`, refund 0, `_refundFee` skipped. Lean `gatewayRefund 10 5 true true` treats 5 as the *total* vault credit and refunds 5. `gateway_refund_success_moves_value` is the numeral `(5, 3)` — not `n * fee`. The CHECKED refund path cannot represent a multi-request exact-fee (refund 0) without the invented `ExactFeeHasNoRefund` revert (issue 10).
