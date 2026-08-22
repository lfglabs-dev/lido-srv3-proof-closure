# P-CONSOLIDATION-ETH-1b (absorbed into P-CONSOLIDATION-ETH-1)

> Status: **absorbed**. This is no longer a sibling guarantee under P-CONSOLIDATION-ETH-1.

The fee → configured consolidation-request target leg is the same consolidation ETH flow as the parent. Theorems (`consolidation_fee_path_confined`, `consolidation_fee_target_success`) are **parent evidence** under `A-CANONICAL-REQUEST-ADDRESS`. Once the canonical `0x00…7251` obligation is discharged, strengthen them into registered parent conjuncts — do not reopen a sister guarantee.

The historical product note and proof audit below are retained for provenance.

---

> Round 2 (2026-08-21). Product note plus proof audit, arbitrated from GPT 5.6 Pro and Opus 5. Fable 5 was unavailable (data-retention gate). Kimi K3 was not an allowed Task model. No em dashes. Lean is authority.

Child of P-CONSOLIDATION-ETH-1 for the fee legs: `ConsolidationBus.executeConsolidation` forwards `msg.value`, and the vault pays per-request fees to the configured EIP-7251 / EIP-7002 immutables.

- abstract `consolidation_fee_path_confined`: if the call target equals `cfg.consolidationRequest`, the one move in `ethTrace` is tagged `.consolidationContract`, hence not `.other`
- Verity `consolidation_fee_target_success`: two successful fee sends debit the vault and credit the configured consolidation-request slot

`cfg.consolidationRequest` is an arbitrary Nat. Equality with the canonical `0x00…7251` is named `A-CANONICAL-REQUEST-ADDRESS` and is not proved. The bus-forward numeral remains auxiliary. We do not cover `executeConsolidation` pending-batch / delay guards or 96-byte payloads (P-CONSOLIDATION-1).

## Proof limitations and recommendations

The abstract theorem remains a tag rename. The registered Verity theorem is now the fee-target witness `consolidation_fee_target_success`, while the bus-forward numeral remains auxiliary. Canonical-address provenance is named `A-CANONICAL-REQUEST-ADDRESS`; it is not discharged.

CHECKED does not mean fees reach the EIP-7251 predeploy.

Ranked next work: the fee-target witness and canonical-address assumption landed; do not compose into P-CONSOLIDATION-1 from here.

Theorems: `PConsolidationEth1.consolidation_fee_path_confined` (abstract), `PConsolidationEth1RequestTx.consolidation_fee_target_success` (verity).
Assumptions: `A-ABSTRACT-TX`, `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-CANONICAL-REQUEST-ADDRESS`.

## Intent

Child of P-CONSOLIDATION-ETH-1 for the *fee* legs: consolidation / withdrawal-request predeploys. In SRv3, `WithdrawalVaultEIP7685._callAddConsolidationRequest` sends `fee` wei to the immutable `CONSOLIDATION_REQUEST` (intended to be the EIP-7251 predeploy `0x00…007251`), and `_callAddWithdrawalRequest` does the same for EIP-7002 `WITHDRAWAL_REQUEST`. `ConsolidationBus.executeConsolidation` is just a value-forwarder into the gateway. The intended guarantee: that fee CALL cannot be retargeted to an arbitrary address.

## Modeling

- Child YAML lists `A-ABSTRACT-TX`, `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, and `A-CANONICAL-REQUEST-ADDRESS`.
- Abstract `Config.consolidationRequest` is an arbitrary `Nat`. Equality with the canonical EIP-7251 address is **explicitly not proved** and is named `A-CANONICAL-REQUEST-ADDRESS`.
- `ethTrace` has length 1. Destination is `.consolidationContract` if `c.target = cfg.consolidationRequest`, else `.other c.target`.
- Verity `PConsolidationEth1RequestTx` is again a **single-contract slot ledger** (bus, gateway, vault, withdrawalRequest, consolidationRequest). `busForward` is `require gatewayOk` plus slot add/sub. `sendWithdrawalFee` / `sendTwoConsolidationFees` move fee words between slots. Deployed-vs-model simplification: no predeploy code, no 96-byte `source ‖ target` calldata, no `getConsolidationRequestFee` CALL.
- Identifying the immutable with `0x00…007251` is left as “a separate provenance obligation.”

## Proof

**Abstract `consolidation_fee_path_confined`.** Assume `c.target = cfg.consolidationRequest`. Then `ethTrace` is the singleton whose destination is `.consolidationContract`. Membership plus `simp` gives `destination ≠ .other addr` for every `addr`. Definitional case split; no arithmetic.

**VERITY `bus_forward_success`.** One numeral:

```
busForward 5 true
  on ⟨bus=3, gateway=1, vault=20, wreq=0, creq=0⟩
  = committed ⟨3, 6, 20, 0, 0⟩
```

Bus is a pass-through (3→8→3), gateway 1+5=6. Proof: `decide`. `withdrawal_fee_success` is the same style (`fee = 5`, vault 20→15, wreq 2→7). Rollback theorems are universal on `Contract.run`. `consolidation_second_failure_discards_prefix` shows the injected second-call failure rolls back the first fee write — again one numeral.

## Issues

## Resolution

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1, 2, 4, 8 | A | Registered Verity theorem is `bus_forward_success`. |
| 3, 5–7, 9, 11, 13–16 | scope | `executeConsolidation`, payloads, auth, exact-fee on two-fee body in `missing`. |
| 10 | A | Source vs `addPanic` two planes. |
| 12 | C | Extra `msg.value ≠ 0` guard removed from `busForward` / `sourceBus`. |
| 17 | C | `firstOk` added (default `true` keeps numerals). |
| 18 | C | Exact-fee then vault-balance then CALL. |


1. **Abstract confinement is a tag-renaming, not a target check.**
   If `c.target` equals the configured word, the model *calls* that destination `.consolidationContract` instead of `.other`. The theorem says a tagged-as-protocol call is not tagged-as-other. It would hold for `cfg.consolidationRequest = 0xattacker` equally well.

   *Counterexample.* Deploy (or configure the immutable to) `0xdead`. Set `c.target = 0xdead = cfg.consolidationRequest`. `consolidation_fee_path_confined` holds. On chain, the fee goes to `0xdead`. The guarantee, read as “fees go to EIP-7251,” is false; the Lean statement is true. The file itself says identifying the immutable with `0x00…007251` is unproved.

2. **The named Verity theorem is not a fee-target theorem.**
   YAML points at `bus_forward_success`, which only moves 5 wei from a bus slot to a gateway slot.

   *Scenario.* Replace the request-contract fee send with a send to `lidoSlot`. `bus_forward_success` still holds (it never reads those slots). YAML still claims “bus forward **and request-contract fee** Contract.run ledger.” Those legs are `#guard`s / unregistered theorems.

3. **Zero-fee withdrawal is allowed and CHECKED-adjacent.**
   `#guard` in `PConsolidationEth1RequestTx.lean:210–212`: `sendWithdrawalFee 0 0 true` **commits** and leaves the ledger unchanged.

   *Scenario.* `requestsCount = 0` on the live vault: `_addWithdrawalRequests` reverts on empty `pubkeys` before `_requireExactFee(0)`. The model treats a zero-value “fee send” as success. Not the named theorem, but it is in the same CHECKED module.

4. **Two-request consolidation is a pair of slot updates, not two CALLs.**
   `sendTwoConsolidationFees` writes `consolidationSlot += fee` twice with `require secondOk` in between.

   *Scenario.* Mutant that credits `withdrawalSlot` instead of `consolidationSlot` for both writes. Nothing in `bus_forward_success` notices. There is no theorem `∀ fee, sendTwoConsolidationFees fee true` credits *only* `consolidationSlot`. Source is a for-loop of N CALLs; N=2 is the only instantiated prefix-rollback.

5. **Boolean gateway / request success.**
   `gatewayOk` / `callOk` / `secondOk` are inputs.

   *Scenario.* Live EIP-7251 predeploy takes the fee and returns empty / rejects the request. The ledger cannot represent a CALL that consumes wei and still fails: `callOk = false` never subtracts, `callOk = true` always subtracts. Both disagree with “keep the fee, fail the request.”

6. **`busForward` is not `executeConsolidation`.**
   Mapped span is `ConsolidationBus.executeConsolidation` 383–406 (pending-batch hash, `_executionDelay`, delete, forward `{value: msg.value}` with `msg.sender` as refund recipient). `busForward` is `require(msgValue ≠ 0)` plus two slot updates gated by `gatewayOk`.

   *Scenario.* No pending batch / delay not passed. Live bus reverts `BatchNotFound` / `ExecutionDelayNotPassed`. Lean `bus_forward_success` still commits the 5-wei slot move. The mapped function is not the registered theorem.

7. **Fee sends debit a vault slot, not `address(this).balance`.**
   Live `_callAddWithdrawalRequest` / `_callAddConsolidationRequest` do `WITHDRAWAL_REQUEST.call{value: fee}` / `CONSOLIDATION_REQUEST.call{value: fee}` from the vault’s ETH. Lean `sendWithdrawalFee` / `sendTwoConsolidationFees` require `fee ≤ vaultSlot` and add to another slot.

   *Scenario.* Vault has 20 ETH on chain and `vaultSlot = 0`. Live fee CALL succeeds. Lean `sendWithdrawalFee 5 5 true` does `subPanic` on slot 0 and cannot represent the 20 ETH. The CHECKED module’s fee legs are not the EIP-7002/7251 CALLs.

8. **No link from `ethTrace` to the ledger.**
   `eth_flow_parent` does not call `consolidation_fee_path_confined`. Parent hardcodes `.consolidationContract` in `pathTrace`. Composition uses `requestAddr = 5`; P-CONSOLIDATION-1 uses `0x00…7251`; this child uses neither in its registered theorems.

   *Scenario.* Change `cfg.consolidationRequest` to `0xbad` (issue 1) and leave `bus_forward_success` alone. Both CHECKED theorems still hold. Three models, zero glue.

9. **`sendTwoConsolidationFees` has no `msg.value` and no exact-fee guard.**
   Live `_requireExactFee` (`WithdrawalVaultEIP7685.sol:123–127`) is `msg.value == requestsCount * fee`. The Lean two-fee program (`PConsolidationEth1RequestTx.lean:59–72`) takes only `fee` and `secondOk`. There is no `msgValue`, no `requestsCount`, and no `require(msgValue == 2 * fee)`.

   *Scenario.* Vault is called with `msg.value = 0` and two consolidation requests whose per-request fee is 5. Live `_requireExactFee` reverts `IncorrectFee`. Lean `sendTwoConsolidationFees 5 true` still commits the two slot credits if `vaultSlot ≥ 10`. The CHECKED-adjacent two-CALL body is not the vault’s fee accounting.

10. **Source consolidation / bus interpreters disagree with `addPanic` / `subPanic` on overflow.**
    `sourceTwoConsolidationFees` (`:126–128`) is `if secondOk then committed (fee + fee)` — unbounded `Nat`, no vault test. `sourceConsolidationView` then does `vault := before.vault - moved` (`Nat.sub` saturates at 0). Verity `addPanic fee fee` / `subPanic v fee` panic on overflow / underflow.

    *Counterexample.* `fee = 2^255`, `secondOk = true`, `vaultSlot = 1`. Source commits `moved = 2^256` and reports `vault = 0`. `sendTwoConsolidationFees (word (2^255)) true` reverts `Panic(0x11)` on `addPanic fee fee`. Same shape for `busForward`: `sourceBus 5 true` commits even when `busSlot = 2^256 − 1`; `addPanic b msgValue` panics. Same for `sourceWithdrawalFee`: no vault test, `sourceWithdrawalView` saturating-subs; `sendWithdrawalFee` `subPanic`s. The only “correspondence” is a `#guard` on `bus = 3`, `fee = 5`. There is no `∀` refinement; the CHECKED numeral never hits the wrap.

11. **Zero-fee two-request consolidation also commits.**
    `#guard` at `:230–232`: `sendTwoConsolidationFees (word 0) true` on vault 20 commits and leaves the ledger unchanged. Combined with issue 3 (zero withdrawal fee).

    *Scenario.* Two-request batch, `getConsolidationRequestFee() = 0`, `msg.value = 0`. Live gateway often reverts `ZeroArgument("msg.value")` before the vault loop. Lean treats a pair of zero-value “fee sends” as success. The CHECKED module’s fee legs include the empty payment.

12. **`busForward` adds a `msg.value ≠ 0` guard that `executeConsolidation` does not have.**
    Live `ConsolidationBus.executeConsolidation` (`:383–406`) hashes the pending batch, checks delay, deletes, then `CONSOLIDATION_GATEWAY.addConsolidationRequests{value: msg.value}(groups, msg.sender)`. Zero value reaches the gateway, which reverts `ZeroArgument("msg.value")` (`ConsolidationGateway.sol:189`). Lean `busForward` (`PConsolidationEth1RequestTx.lean:37`) reverts `ZeroArgument(msg.value)` *before* any slot update and has no batch hash / delay / delete.

    *Scenario.* `msg.value = 0`, no pending batch. Live reverts `BatchNotFound`. Lean `bus_forward_success` is the `(5, true)` numeral; `busForward 0 _` reverts for a reason the bus never emits. A zero-value execute of a *valid* pending batch is a live gateway revert after `delete _pendingBatches[batchHash]` — the batch is consumed and the tx reverts, so the delete rolls back. Lean never models that delete. The CHECKED bus numeral is not the pending-batch state machine.

13. **EIP-7002 payload `(pubkey ‖ amount)` is not in the ledger.**
    Live `_callAddWithdrawalRequest` (`WithdrawalVaultEIP7685.sol:103–110`) `abi.encodePacked(pubkey, amount)` (48+8 bytes) and `WITHDRAWAL_REQUEST.call{value: fee}(request)`. `sendWithdrawalFee` only requires `msgValue == fee` and moves a vault slot to a withdrawal slot. No pubkey, no uint64 amount, no returndata.

    *Scenario.* `amount = 0` or a 32-byte “pubkey”. Live still pays the fee and submits a malformed 7002 request (predeploy may keep the fee and reject the request — issue 5). Lean `withdrawal_fee_success` (`fee=5`, vault 20→15) still holds. The CHECKED fee leg is not an EIP-7002 request; it cannot be wrong about the payload because there is none.

14. **`sendWithdrawalFee` is a one-request exact-fee, not `requestsCount * fee`.**
    Live `_addWithdrawalRequests` (`WithdrawalVaultEIP7685.sol:40–54` area) loops N keys and `_requireExactFee(requestsCount * fee)`. Lean `sendWithdrawalFee` (`PConsolidationEth1RequestTx.lean:48–56`) is `require(msgValue == fee)` for a *single* fee word. There is no `requestsCount`.

    *Scenario.* Three withdrawal requests, fee 5, `msg.value = 15`. Live exact-fee passes and performs three CALLs. Lean `sendWithdrawalFee 5 15 true` reverts `IncorrectFee`. `sendWithdrawalFee 5 5 true` moves 5 once. The CHECKED-adjacent `#guard` / `withdrawal_fee_success` numeral is not the vault loop; N=1 is baked in. Contrast `sendTwoConsolidationFees`, which hard-codes N=2 (issue 4).

15. **Vault auth / array / 48-byte guards are absent from the two-fee body.**
    Live `WithdrawalVault.addConsolidationRequests` (`:199–208`) requires `msg.sender == CONSOLIDATION_GATEWAY` and `preservesEthBalance`. `_addConsolidationRequests` (`EIP7685:56–72`) reverts on empty arrays, length mismatch, and `InvalidPublicKeyLength`. `sendTwoConsolidationFees` is two slot updates gated by `secondOk`.

    *Scenario.* EOA calls the vault directly with `value: 10`, or `sourcePubkeys.length = 2` and `targetPubkeys.length = 1`, or a 32-byte “pubkey”. Live reverts. `sendTwoConsolidationFees 5 true` on vault slot 20 commits `20→10`. The YAML 7251 fee leg has none of the vault’s actual guards.

16. **EIP-7251 payload is `abi.encodePacked(source, target)` (96 bytes), not a slot credit.**
    Distinct from issue 13 (7002 `pubkey‖amount`). Live `_callAddConsolidationRequest` (`:113–115`) sends 96 packed bytes. Lean `sendTwoConsolidationFees` only `addPanic`/`subPanic`s `fee` into `consolidationSlot`.

    *Scenario.* Valid 48-byte keys vs `source == target` (bus rejects at publish, `ConsolidationBus.sol:361–363`) vs a 96-byte zero payload. Live predeploy sees different calldata. Lean `sendTwoConsolidationFees 5 true` is identical for all of them (`vault 20→10`, `creq 4→14`). CHECKED “fee path confined” never observes the bytes the predeploy is specified on.

17. **The first of the two fee writes has no success boolean.**
    `sendTwoConsolidationFees` (`:64–72`) always performs the first `subPanic`/`addPanic` pair, then `require secondOk`. There is no `firstOk`. Live `_callAddConsolidationRequest` reverts the whole function if the first predeploy CALL fails.

    *Scenario.* First EIP-7251 CALL fails, second would succeed. Live tx reverts with no fee paid. Lean with `secondOk = true` still commits both slot updates (`vault 20→10`). The only failure the two-fee body can represent after the vault-balance check is the *second* CALL. Prefix-rollback (`consolidation_second_failure_discards_prefix`) is the other boolean, not a first-CALL failure.

18. **`sendWithdrawalFee` requires `callOk` before it even reads the vault slot.**
    `PConsolidationEth1RequestTx.lean:48–56`: `require(msgValue == fee)` then `require callOk` then `subPanic vault fee`. Live `_callAddWithdrawalRequest` does the value-CALL (which needs `address(this).balance ≥ fee`) and then checks `success`.

    *Scenario.* `callOk = false`, `vaultSlot = 0`, `fee = 5`, `msgValue = 5`. Lean reverts `RequestAdditionFailed` without looking at the vault. Live `_requireExactFee` passes, then `call{value: 5}` fails for insufficient ETH (or succeeds in transferring and then reverts on `!success`). The CHECKED-adjacent `#guard` / `withdrawal_fee_success` never hits this order. Combined with issue 5 (cannot represent “keep the fee, fail the request”), the Lean failure modes are a different partition than the vault’s CALL.
