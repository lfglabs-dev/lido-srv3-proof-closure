# P-CONSOLIDATION-1

Theorems: `PConsolidation1.source_consolidation_preserves_eligibility_value_atomicity`, `PConsolidation1.verity_tx_simulates_consolidation`.
Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

SRv3 lets a module/operator ask the beacon chain to merge two validators (EIP-7251). The user-facing path is `ConsolidationGateway.addConsolidationRequests` (witness groups, quota, refund) → `WithdrawalVault.addConsolidationRequests` → `_callAddConsolidationRequest`, which value-CALLs `source ‖ target` to the consolidation predeploy and emits `ConsolidationRequestAdded`. The intended guarantee: only eligible pairs go out, the ETH sent is exactly `n × fee`, and a revert leaves no prefix of those CALLs/events.

## Modeling

- Slice starts at the **vault** entry (`ConsolidationCorrespondence.lean` header: vault lines 199–208, EIP-7685 56–73 / 113–127 / 97–101). Gateway grouping, quota, SSZ target-witness, pause, and `ADD_CONSOLIDATION_REQUEST_ROLE` are out of scope. Deployed `addConsolidationRequests` is `payable preservesEthBalance` (`WithdrawalVault.sol:201`); the Lean journal does not check that the vault’s ETH is unchanged after the loop.
- “Eligibility” in the model is: `caller == gateway`, nonempty sources, zip-able equal-length arrays, each key length word equals 48, `n * fee` fits in `uint256`, `msg.value == n * fee`. No CL validator existence, no slash/exit, no withdrawal-credential match.
- Public keys are `Word` (a `Nat` modulo 2^256), not 48-byte arrays. `payload = [source, target]` is two words, not 96 bytes.
- `requestTarget` is an input. The constant `consolidationRequestAddress = 0x00…7251` is defined and unused by `sourceRun`.
- `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`. Official `denoteFunction` cannot execute `Expr.call` (`audit/P-CONSOLIDATION-1-VERITY-GAPS.md` item 2); the CHECKED parent uses a handwritten `Contract.run` that *journals* CALL observables instead of performing them.
- Verity `addRequests` decodes four memory arrays and writes journal + map/slot. No multi-contract world.

## Proof

**Abstract `source_consolidation_preserves_eligibility_value_atomicity`.** `sourceRun` is a nest of `if`s. The proof is a case split (`split at hobs`) along that nest:
- On `.committed`, every guard succeeded, so the witness tuple (zip, caller, nonempty, 48-byte lens, mul bound, exact fee) holds and `obs = commitObservables …` (the function that *builds* one `CallObs` and one `EventObs` per request).
- On `.reverted`, at least one guard failed, so the negation of the whole conjunction holds.

This is inversion of a decision tree, not a conservation argument about ETH.

**VERITY `verity_tx_simulates_consolidation`.** Given that the four arrays already sit in the state (`readArray = some …`), running `addRequests` and `observe` equals `sourceView`. Same guards, then persist payloads / counts. Rollback includes an injected post-write failure.

## Issues

## Resolution

**Restated Lean/English.** Abstract is the `sourceRun` if-tree (caller, 48-byte keys, `_requireExactFee`). Invented `fee ≠ 0` revert removed: `fee = 0` and `msg.value = 0` commits, matching the pinned vault.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1, 2, 4, 5, 6 | A | Caller/length/fee, input equality, if-tree named honestly. |
| 3 | A | `observe` still reports the result journal payload. |
| 7, 10, 14 | scope | Real CALL / 96-byte payload in `missing`. |
| 8 | A | Vault `addConsolidationRequests` only. |
| 9, 15, 20 | scope | Dummy oracle / 128-word / pad in `missing`. |
| 11, 13, 16, 17 | A | Unused predeploy, `feePaid := msgValue`, unused registry. |
| 12, 19 | A | Invented persist maps kept but not claimed as vault storage. |
| 18 | C | Invented `fee ≠ 0` revert dropped. `_requireExactFee(0)` commits. |


1. **“Eligibility” is not validator eligibility.**
   A pair of random 48-byte-length *words* with `caller = gateway` and exact fee is “eligible.” Scenario: source pubkey is a slashed validator, or not in the vault’s WC, or the target is not 0x02. Deployed gateway would fail `_validatePubKeyWCProof` / verifier. Vault-only model commits `commitObservables`. The CHECKED guarantee, read as “only consolidatable Lido validators are submitted,” is false of this statement.

2. **Value “conservation” is an input equality, not a balance law.**
   `msgValue.val = requests.length * fee.val` is a guard on numbers supplied with the `Inputs` record. No account is debited. Scenario: `msg.value` on the live CALL is correct but the vault’s `call{value: fee}` to the predeploy fails after the first pair; the model’s committed branch never runs a CALL, and the revert branch is a different `Inputs` (or a Verity inject) rather than a failed predeploy. Atomicity of *real* CALLs is the OPEN item in `P-CONSOLIDATION-1-VERITY-GAPS.md` (official denotation always reverts on `Expr.call`). Promoting `Contract.run` journaling to CHECKED does not execute EIP-7251.

3. **`observe` on success reports the `Result` payload, not the journal.**
   `ConsolidationTx.observe` (`:177–180`) copies `result.calls` / `result.events` / `result.payloads` from the value `addRequests` returned. Count/fee slots are read from state.

   *Counterexample mutant.* Skip `append` to `ContractState.calls` / `.events` but still return a `Result` with the journal lists. `verity_tx_simulates_consolidation` still holds. YAML “journals one CALL and one event per pair” is true of a struct field, not of an observed log.

4. **Atomicity is the other arm of the same `if`.**
   If `sourceRun` committed, it returned `commitObservables`. If it reverted, it did not. There is no prefix-event in the abstract type at all (`SourceOutcome` is `reverted reason | committed obs`). You cannot even *write down* a partial journal in `sourceRun`. The revert conjunct is therefore “the function did not take the success arm.”

   *Scenario that needs a real atomicity proof.* Vault emits event and performs CALL for pair 0, then pair 1’s CALL fails. Live 0.8 call-revert rolls back the whole tx (good), but the model never constructs that prefix, so it does not *prove* the rollback of a multi-CALL body; it proves a single-branch function has one branch.

5. **Keys as `Nat` drop 48-byte identity.**
   Two distinct 48-byte pubkeys that agree in the 32-byte word used as `source` collide. `validRequest` only checks the *length word* equals 48, not that a byte array of length 48 was provided. Scenario: `sourceLen = 48`, `source = 0`. Accepted. Deployed `_validatePublicKey` rejects a non-48-byte *array*; a 48-byte all-zero key may still be invalid for EIP-7251.

6. **Gateway / witness / quota are out of the CHECKED slice.**
   The model’s `gateway` is an input word, not “the deployed ConsolidationGateway contract.”

   *Scenario.* Anyone who can call the vault with `msg.sender` equal to the stored gateway address (or, in Lean, with `inputs.caller = inputs.gateway`) and exact fee commits. A request that should have been rejected by `_validatePubKeyWCProof`, quota, pause, or `ADD_CONSOLIDATION_REQUEST_ROLE` is in-model-committable. Fee is also an input, not a `staticcall` of the predeploy: if the real fee is 1 gwei and the model input is 0, Lean accepts a free batch.

7. **Journaled CALLs are pre-marked `.success` and `txRun = sourceRun` by `rfl`.**
   `toJournal` (`ConsolidationTx.lean:106–113`) builds an `ExternalCall` with `control := .success` and empty returndata. Nothing executes the predeploy. `txRun_eq_sourceRun` is `rfl` (`:97–99`).

   *Scenario.* The EIP-7251 contract reverts on a malformed 96-byte payload. Lean `persist` still appends a `.success` journal entry and `observe` reports it. The CHECKED “one CALL per pair” is a struct copy, not a frame that can fail.

8. **`audit/source-map.yaml` maps the Bus publisher/executor; the CHECKED theorem is the vault inner function.**
   Mapped spans include `ConsolidationBus.addConsolidationRequests` 325–370 and `executeConsolidation`. The Lean parent is `WithdrawalVault.addConsolidationRequests` after gateway auth. Bus pending-batch hash, execution delay, and `PUBLISH_ROLE` are not in `sourceRun`.

   *Scenario.* Publisher submits a group that never becomes a pending batch. Live `executeConsolidation` reverts `BatchNotFound`. Lean `source_consolidation_preserves_eligibility_value_atomicity` can still commit if `caller = gateway`. The mapped Bus span is not an input of the CHECKED theorem.

9. **Memory arrays use the same dummy `mappingSlot := fun _ _ => 0` oracle.**
   `ConsolidationTx.oracle` (`:35–36`). Premises `hSources` / `hTargets` / `hSourceLens` / `hTargetLens` assume the four arrays already decode.

   *Scenario.* Real `bytes[]` pubkeys are dynamic ABI, not word arrays at `sourcesBase`. Those premises fail for a compiled vault call, so the CHECKED equality does not apply to `addConsolidationRequests` calldata.

10. **`toJournal` sets `siteId` to the predeploy address and `control := .success`.**
   `ConsolidationTx.lean:106–113`. A `CallObs.target` is used as both destination and site id. Live CALL site ids are compiler-assigned, not the predeploy address.

   *Scenario.* Two pairs, same `requestTarget`. Both journal entries have the same `siteId`. A dispatcher that keyed frames by siteId would collapse them. The CHECKED journal is not a Verity external-call frame that can fail or be distinguished by site.

11. **`consolidationRequestAddress` is unused.**
   The constant `0x00…7251` is defined and not read by `sourceRun`.

   *Scenario.* Set `inputs.requestTarget = 0xdead`. `source_consolidation_preserves_eligibility_value_atomicity` still holds and `commitObservables` journals CALLs to `0xdead`. Same provenance hole as P-ETH-1b. A more faithful 48+48-byte model exists in `ConsolidationAbstractFlowModel` and is **not** the registered parent.

12. **`persist` invents count / fee / payload maps the vault does not write.**
    `ConsolidationTx.persist` (`:123–131`) SSTOREs `countSlot = start + requestCount`, `feePaidSlot = obs.feePaid`, and `sourceMapSlot` / `targetMapSlot` per index. Live `WithdrawalVault.addConsolidationRequests` (`:199–208`) loops `_callAddConsolidationRequest` and emits; it does not keep a request-count word or a source/target map.

    *Scenario.* `countSlot` already holds `2^256 − 1`. One committed request writes `Uint256.ofNat (start + 1)` = `0`. Live vault has no such wrap because it has no such slot. `observe` on success *does* read `countSlot` / `feePaidSlot` (`:178–180`) while taking calls/events from the `Result`. The CHECKED “persisted count” is a model-local counter that can wrap and that the deployed function does not maintain.

13. **`feePaid` is the input `msgValue`, not a computed debit.**
    `commitObservables` (`ConsolidationCorrespondence.lean:112`) sets `feePaid := msgValue`. Combined with the exact-fee guard this equals `n * fee` when the success arm is taken, but no account is reduced by that amount.

    *Scenario.* `n = 2`, `fee = 5`, `msgValue = 10`, vault ETH = 0. Live `call{value: 5}` fails after the first pair (or immediately) and the tx reverts. Lean `sourceRun` commits `feePaid = 10` with two journaled `.success` CALLs and never looks at a balance. The CHECKED “value conservation” conjunct is the guard `msgValue.val = n * fee.val`, not “the vault paid `n * fee` wei.”

14. **Journaled calldata is two words, not `abi.encodePacked(source, target)` (96 bytes).**
    Live `_callAddConsolidationRequest` (`WithdrawalVaultEIP7685.sol:113–115`) sends `abi.encodePacked(sourcePubkey, targetPubkey)` — 48+48 bytes — as the EIP-7251 payload. `requestCall` / `payload` (`ConsolidationCorrespondence.lean:50–51, 99–100`) set `input := [source, target]`, two `Uint256`s. `toJournal` (`ConsolidationTx.lean:111`) maps those to `calldata := c.input.map (·.val)`.

    *Scenario.* Two distinct 48-byte keys that share the same 32-byte word (issue 5) produce the same journaled calldata. The predeploy would see different 96-byte blobs. The CHECKED “one CALL per pair” payload is not the bytes the EIP-7251 contract receives. A 48-byte key whose first 32 bytes are 0 and whose last 16 bytes differ is accepted (`sourceLen = 48`) and journals `input = [0, target]`.

15. **Toy memory aliases at 128 words (same layout as P-ALLOC-2 / P-TOPUP-2).**
    `ConsolidationTx.memoryFor` plants sources at `0x1000`, targets at `0x2000`, sourceLens at `0x3000`, targetLens at `0x4000`. Length `≥ 129` makes `sources[128]` occupy `targets[0]`.

    *Counterexample.* 129 pairs, `sources[128] = 0xAA`, `targets[0] = 0xBB`. `readArray "targets"` returns a list whose head is `0xAA`. Premises `hTargets` fail, or a raw `addRequests` zips the wrong keys. Live `bytes[]` pubkeys are separate dynamic arrays. Combined with issue 9 (dummy oracle), the CHECKED decoder is a layout that is false above 128 pairs.

16. **Facade `ValidatorRegistry` / prepaid-balance model is unused by the CHECKED theorems.**
    `PConsolidation1.lean:14–45` defines `ValidatorRegistry`, `mapping_invariant`, `consolidation_fee_valid` (`n * fee ≤ balance`), `pubkey_mapping_preserved`. None of these appear in `source_consolidation_preserves_eligibility_value_atomicity` or `verity_tx_simulates_consolidation`.

    *Scenario.* A reader of the facade file sees a prepaid-balance conservation story. The CHECKED parent is an if-tree on `Inputs` with no `prepaidBalance` field (issue 2). You can break `consolidation_fee_valid` (set `balance = 0`, `n*fee = 10`) and both CHECKED theorems still hold. The unused model is closer to “operator escrow” than the vault slice that was actually proved.

17. **Mapped `preservesEthBalance` is not in `sourceRun`.**
    Live `WithdrawalVault.addConsolidationRequests` (`:201`) is `preservesEthBalance`: snapshot `address(this).balance` and revert if it changed after the loop. Lean `sourceRun` / `addRequests` never read a self-balance. `commitObservables` journals CALLs marked `.success` without moving wei (issue 2, 13).

    *Scenario.* A predeploy CALL that consumes `fee` but also leaves leftover wei on the vault (or a failed CALL that still transferred). Live modifier reverts the whole `addConsolidationRequests`. Lean `source_consolidation_preserves_eligibility_value_atomicity` commits if the input guards pass. Same hole as P-ETH-1a issue 6, on the vault parent this row actually names.

18. **Zero fee and zero `msg.value` is a committed free batch.**
    `sourceRun` accepts `n ≥ 1`, `fee = 0`, `msgValue = 0` (`0 == n * 0`, mul bound holds). Live vault `_requireExactFee(0)` also passes, then `call{value: 0}`. The *gateway* (`ConsolidationGateway.sol:189`) reverts `ZeroArgument("msg.value")` before the vault is called.

    *Scenario.* One pair, `fee = 0`, `msgValue = 0`, `caller = gateway`. Lean commits `commitObservables` with two journaled 0-value CALLs. Live users never reach the vault: the gateway rejects zero value. The CHECKED vault slice therefore includes a free-consolidation success the user-facing path cannot take (unless someone calls the vault as the gateway with `value: 0` after a 0-fee predeploy read — still a different entry than the mapped Bus/Gateway story).

19. **`persist` can wrap `countSlot` and overwrite payload index 0 on the next batch.**
    `persist` writes `countSlot = Uint256.ofNat (start + requestCount)` (`ConsolidationTx.lean:126–127`). If `start = 2^256 − 1` and `requestCount = 1`, the stored count is `0`. A second `addRequests` reads `start = 0` and `writePayloads` clobbers map index 0.

    *Counterexample.* First committed request writes `count = 0` (wrap) and payload 0. Second committed request writes payload 0 again. Live vault has no such counter; each CALL is independent. Combined with issue 12 (invented slots), the CHECKED “persisted count” can alias two batches onto the same map key. The registered theorem is one `addRequests` at a time, so sequential wrap is outside the equality — and that is the hole: there is no `∀` about two successive commits.

20. **Decode length is `inputs.sources.length`; short memory pads with 0.**
    `addRequests` (`ConsolidationTx.lean:147–151`) reads `inputs.sources.length` words from each base. `memoryFor` returns 0 outside the planted range (same layout as issue 15). Live `bytes[]` length is the ABI length; a short array is a shorter array, not zero-padded keys.

    *Scenario.* `inputs.sources.length = 2`, planted one source word `0xAA`. `readArray` returns `[0xAA, 0]`. `validRequest` only checks `sourceLen = 48` (issue 5). If lens are `[48, 48]`, Lean commits a second pair with `source = 0`. Live `sourcePubkeys` of length 1 cannot yield a second key. Combined with issue 9 (dummy oracle), the CHECKED decoder invents a zero pubkey.

## Wave 1 changes (2026-08-19)

1. **Gateway-nonzero-value premise.** Added
   hGatewayAdmittedNonzero to the parent theorem. The fee = 0 with
   msg.value = 0 arm stays a correct vault fact but is no longer
   user-reachable (the gateway reverts ZeroArgument before the vault
   is called).

2. **Packing-order kill-line.** packing_order_kills_swapped_concat proves
   that a swapped target-then-source concat produces a different
   commitObservables than the canonical source-then-target when
   source != target. One pair suffices.

3. **Cheap mutant.** ConsolidationTxMutants now includes a native_decide
   example that the committed view with swapped inputs differs from the
   canonical view.

4. **preservesEthBalance named gap.** Documented as preservesEthBalance_gap
   in the Lean file and in fidelity.missing. Closing it requires
   value-bearing CALL frames, not the current success stubs with empty
   returndata.

5. **No P-ETH-1 composition.** Explicitly noted in YAML classification.work
   and next_gate.
