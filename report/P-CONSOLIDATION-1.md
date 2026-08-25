# P-CONSOLIDATION-1

> Round 2 (2026-08-21). Product note plus proof audit, arbitrated from GPT 5.6 Pro and Opus 5. Fable 5 was unavailable (data-retention gate). Kimi K3 was not an allowed Task model. No em dashes. Lean is authority.

P-CONSOLIDATION-1 covers the inner half of Lido's EIP-7251 path. `ConsolidationGateway.addConsolidationRequests` does role, pause, witness, quota, and refund, then calls `withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys)`. The registered guarantee starts at that vault call.

A batch commits only if the caller is the stored gateway, the source array is nonempty, source and target zip by index, every key carries a 48-byte length word, $n \times \mathrm{fee}$ fits in `uint256`, and $\mathrm{msg.value} = n \times \mathrm{fee}$. A commit produces one predeploy CALL and one event per pair, payload ordered source then target. Anything that fails a guard produces no CALL and no event.

`source_consolidation_preserves_eligibility_value_atomicity` is that characterization, under the caller-supplied premise `caller = gateway → msg.value ≠ 0`, from which a committed run derives $\mathrm{fee} \ne 0$. That premise remains on the wrong outer-gateway value surface and is scheduled for relocation. `verity_tx_simulates_consolidation` matches `sourceView` when four memory arrays decode. We do not cover beacon eligibility, grouping, quota, or the Bus. Do not compose with P-CONSOLIDATION-ETH-1.

## Proof limitations and recommendations

The parent is an unbounded $\forall$ hypothesized on `hGatewayAdmittedNonzero`. The cited `ConsolidationGateway.sol:189` guards the gateway's own `msg.value`, not the vault's forwarded `totalFee`. If fee is zero the gateway can still call the vault with `value: 0`. `preservesEthBalance` is a `String` gap: journaled CALLs are pre-marked successful and move no wei. Lean and YAML now state the pinned obligation precisely: the vault forwards exactly `msg.value`. Verity rollback is the `Contract.run` combinator, true of every program. `observe` does not reread payload maps.

CHECKED does not mean eligibility in the beacon sense, that the vault paid $n \times \mathrm{fee}$, or gateway grouping.

Ranked next work: drop or relocate the outer-gateway nonzero-value premise; keep the P-CONSOLIDATION-ETH-1 fence until an ABI/interpreter bridge exists. `observe` now rereads `sourceMapSlot`/`targetMapSlot` payload storage for the new request indices rather than reconstructing payloads from the call journal.

Theorems: `PConsolidation1.source_consolidation_preserves_eligibility_value_atomicity`, `PConsolidation1.verity_tx_simulates_consolidation`, `PConsolidation1.fee_blind_commit_kill_line_refutes_parent`, `PConsolidation1.gateway_admitted_nonzero_kill_line`.
Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`, `A-CONSOLIDATION-GATEWAY-NONZERO`.

## Intent

SRv3 lets a module/operator ask the beacon chain to merge two validators (EIP-7251). The user-facing path is `ConsolidationGateway.addConsolidationRequests` (witness groups, quota, refund) → `WithdrawalVault.addConsolidationRequests` → `_callAddConsolidationRequest`, which value-CALLs `source ‖ target` to the consolidation predeploy and emits `ConsolidationRequestAdded`. The intended guarantee: only eligible pairs go out, the ETH sent is exactly `n × fee`, and a revert leaves no prefix of those CALLs/events.

## Modeling

- Slice starts at the **vault** entry (`ConsolidationCorrespondence.lean` header: vault lines 199–208, EIP-7685 56–73 / 113–127 / 97–101). Gateway grouping, quota, SSZ target-witness, pause, and `ADD_CONSOLIDATION_REQUEST_ROLE` are out of scope. Deployed `addConsolidationRequests` is `payable preservesEthBalance` (`WithdrawalVault.sol:201`); the Lean journal does not check that the vault’s ETH is unchanged after the loop.
- “Eligibility” in the model is: `caller == gateway`, nonempty sources, zip-able equal-length arrays, each key length word equals 48, `n * fee` fits in `uint256`, `msg.value == n * fee`. No CL validator existence, no slash/exit, no withdrawal-credential match.
- Public keys are `Word` (a `Nat` modulo 2^256), not 48-byte arrays. `payload = [source, target]` is two words, not 96 bytes.
- `requestTarget` is an input. The pinned source literal `consolidationRequestAddress = 0x0000BBdDc7CE488642fb579F8B00f3a590007251` is defined and unused by `sourceRun`; it does not bind that free endpoint to a deployment.
- `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`. Official `denoteFunction` cannot execute `Expr.call` (`audit/P-CONSOLIDATION-1-VERITY-GAPS.md` item 2); the CHECKED parent uses a handwritten `Contract.run` that *journals* CALL observables instead of performing them.
- Verity `addRequests` decodes four memory arrays and writes journal + map/slot. No multi-contract world.

## Proof

**Abstract `source_consolidation_preserves_eligibility_value_atomicity`.** `sourceRun` is a nest of `if`s. The proof is a case split (`split at hobs`) along that nest:
- On `.committed`, every guard succeeded, so the witness tuple (zip, caller, nonempty, 48-byte lens, mul bound, exact fee) holds and `obs = commitObservables …` (the function that *builds* one `CallObs` and one `EventObs` per request).
- On `.reverted`, at least one guard failed, so the negation of the whole conjunction holds.

This is inversion of a decision tree, not a conservation argument about ETH.

**`hGatewayAdmittedNonzero` is threaded and used (2026-08-19 fix).** The theorem takes `hGatewayAdmittedNonzero : inputs.caller = inputs.gateway → inputs.msgValue.val ≠ 0` and now forwards it to `SolidityConsolidation.source_consolidation_preserves_eligibility_value_atomicity`, which takes the same hypothesis. On the `.committed` branch, `hEq : inputs.caller = inputs.gateway` plus the hypothesis gives `inputs.msgValue.val ≠ 0`; combined with the branch's own `inputs.msgValue.val = requests.length * inputs.fee.val` and `requests.length ≠ 0` (transported from `inputs.sources.length ≠ 0` via `zipRequests_some_length`), a zero fee would force `msgValue.val = 0`, contradicting the hypothesis. The committed-branch witness tuple therefore gains an explicit `inputs.fee.val ≠ 0` conjunct. `gateway_admitted_nonzero_kill_line` proves the hypothesis is necessary for that conjunct: on a concrete gateway-authorized, nonempty, 48-byte-aligned batch with `fee = 0` and `msg.value = 0`, `sourceRun` still commits, so "every committed run has a nonzero fee" is false of `sourceRun` unconditionally (i.e. without the hypothesis — that witness itself violates the premise, so this is premise-necessity evidence, not a refutation of the hypothesis-conditioned parent). Wave 4 adds the parent-refuting kill-line proper: `fee_blind_commit_kill_line_refutes_parent` keeps the premise satisfied and falsifies the hypothesis-conditioned committed-arm conjunction on the mutant interpreter `sourceRunFeeBlind` (exact-fee guard dropped) — see the Wave 4 section below. Previously the wrapper declared this hypothesis but never forwarded it — an inert, decorative premise that Lean's unused-variable linter flagged and that changed nothing about the theorem's applicability or conclusion.

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
| 3 | A | Refreshed 2026-08-19: `observe` reads the `state.calls` / `state.events` journal suffix, not the `Result` payload; the skip-append mutant is now caught. |
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

3. **`observe` reads the journal appended to `state.calls` / `state.events` (wording refreshed 2026-08-19).**
   `ConsolidationTx.observe` (`ConsolidationTx.lean:191–200`) drops the pre-call prefix of `state.calls` / `state.events` and maps the freshly appended journal entries; the view's payloads are the calldata of those calls, and count/fee come from `countSlot` / `feePaidSlot`. The `Result` payload is ignored on success. The earlier wording of this issue (“observe reports the `Result` payload, not the journal”, with a counterexample mutant that skips the journal `append` but returns the lists in the `Result`) is **stale**: `persist` appends to `state.calls` / `state.events` (`:123–131`) and `observe` reads that suffix, so the skip-append mutant is now caught (the Tests call-drop/event-drop/memory-drop vectors exercise exactly this). The residual gap is narrower and is issues 7/10: the journaled CALLs are pre-marked `.success` stubs with empty returndata, so the observed log is a journal of intended CALLs, not executed frames.

4. **Atomicity is the other arm of the same `if`.**
   If `sourceRun` committed, it returned `commitObservables`. If it reverted, it did not. There is no prefix-event in the abstract type at all (`SourceOutcome` is `reverted reason | committed obs`). You cannot even *write down* a partial journal in `sourceRun`. The revert conjunct is therefore “the function did not take the success arm.”

   *Scenario that needs a real atomicity proof.* Vault emits event and performs CALL for pair 0, then pair 1’s CALL fails. Live 0.8 call-revert rolls back the whole tx (good), but the model never constructs that prefix, so it does not *prove* the rollback of a multi-CALL body; it proves a single-branch function has one branch.

5. **Keys as `Nat` drop 48-byte identity.**
   Two distinct 48-byte pubkeys that agree in the 32-byte word used as `source` collide. `validRequest` only checks the *length word* equals 48, not that a byte array of length 48 was provided. Scenario: `sourceLen = 48`, `source = 0`. Accepted. Deployed `_validatePublicKey` rejects a non-48-byte *array*; a 48-byte all-zero key may still be invalid for EIP-7251.

6. **Gateway / witness / quota are out of the CHECKED slice.**
   The model’s `gateway` is an input word, not “the deployed ConsolidationGateway contract.”

   *Scenario.* Anyone who can call the vault with `msg.sender` equal to the stored gateway address (or, in Lean, with `inputs.caller = inputs.gateway`) and exact fee commits. A request that should have been rejected by `_validatePubKeyWCProof`, quota, pause, or `ADD_CONSOLIDATION_REQUEST_ROLE` is in-model-committable. Fee is also an input, not a `staticcall` of the predeploy: if the real fee is 1 gwei and the model input is 0, Lean accepts a free batch.

7. **Journaled CALLs are pre-marked `.success`, and the executor and the observable share one `sourceRun`.**
   `toJournal` (`ConsolidationTx.lean:80–87`) builds an `ExternalCall` with `control := .success` and empty returndata. Nothing executes the predeploy. There is no separate tx-side transcription to bridge: the executor `addRequests` (`:157`) and the observable `sourceView` (`:203`) both call the same `sourceRun`, so the two planes agree by definition rather than by a proved correspondence.

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
   The pinned source literal `0x0000BBdDc7CE488642fb579F8B00f3a590007251` is defined and not read by `sourceRun`.

   *Scenario.* Set `inputs.requestTarget = 0xdead`. `source_consolidation_preserves_eligibility_value_atomicity` still holds and `commitObservables` journals CALLs to `0xdead`. Same provenance hole as P-CONSOLIDATION-ETH-1b. A more faithful 48+48-byte model exists in `ConsolidationAbstractFlowModel` and is **not** the registered parent.

12. **`persist` invents count / fee / payload maps the vault does not write.**
    `ConsolidationTx.persist` (`:123–131`) SSTOREs `countSlot = start + requestCount`, `feePaidSlot = obs.feePaid`, and `sourceMapSlot` / `targetMapSlot` per index. Live `WithdrawalVault.addConsolidationRequests` (`:199–208`) loops `_callAddConsolidationRequest` and emits; it does not keep a request-count word or a source/target map.

    *Scenario.* `countSlot` already holds `2^256 − 1`. One committed request writes `Uint256.ofNat (start + 1)` = `0`. Live vault has no such wrap because it has no such slot. `observe` on success *does* read `countSlot` / `feePaidSlot` (`:178–180`) while taking calls/events from the `Result`. The CHECKED “persisted count” is a model-local counter that can wrap and that the deployed function does not maintain.

13. **`feePaid` is the input `msgValue`, not a computed debit.**
    `commitObservables` (`ConsolidationCorrespondence.lean:144–150`) sets `feePaid := msgValue`. Combined with the exact-fee guard this equals `n * fee` when the success arm is taken, but no account is reduced by that amount.

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

    *Scenario.* A predeploy CALL that consumes `fee` but also leaves leftover wei on the vault (or a failed CALL that still transferred). Live modifier reverts the whole `addConsolidationRequests`. Lean `source_consolidation_preserves_eligibility_value_atomicity` commits if the input guards pass. Same hole as P-CONSOLIDATION-ETH-1a issue 6, on the vault parent this row actually names.

18. **Zero fee and zero `msg.value` is a committed free batch of `sourceRun` itself.**
    `sourceRun` accepts `n ≥ 1`, `fee = 0`, `msgValue = 0` (`0 == n * 0`, mul bound holds). Live vault `_requireExactFee(0)` also passes, then `call{value: 0}`. The *gateway* (`ConsolidationGateway.sol:189`) reverts `ZeroArgument("msg.value")` before its own call proceeds.

    *Scenario.* One pair, `fee = 0`, `msgValue = 0`, `caller = gateway`. `sourceRun` on its own commits `commitObservables` with two journaled 0-value CALLs (`Tests/ConsolidationTxMutants.lean`'s `_requireExactFee(0)` vector exercises exactly this on the Verity transaction, and still holds — that fact is honest and unchanged). The registered parent's `hGatewayAdmittedNonzero` premise (`caller = gateway → msg.value ≠ 0`) is a caller-supplied hypothesis, not a fact `sourceRun` proves on its own: it is the wrapper's job, when invoked on an `Inputs` value for which the premise is supplied, to derive `inputs.fee.val ≠ 0` on the committed branch (2026-08-19 fix, see Proof section above) — that is what excludes this free-batch arm from *the parent's conclusion*, not from `sourceRun`'s decision tree, which is unaffected and still commits it. `gateway_admitted_nonzero_kill_line` pins this distinction with a proof: drop the premise and the same free batch refutes the strengthened claim's hypothesis-free projection (the witness itself violates the premise, so this is premise-necessity evidence; Wave 4's `fee_blind_commit_kill_line_refutes_parent` is the parent-refuting kill-line, on the exact-fee-guard-dropped mutant `sourceRunFeeBlind` with a premise-satisfying witness). The premise itself is still not derived from a modeled `ConsolidationGateway` (`fidelity.missing`); it is accepted based on the pinned source excerpt above.

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

   **Superseded by Wave 3 below: this premise was declared but never
   forwarded to the source theorem, so it was an unused, decorative
   hypothesis that changed nothing about the theorem's applicability or
   conclusion — the "no longer user-reachable" claim above was not
   actually proved.**

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

5. **No P-CONSOLIDATION-ETH-1 composition.** Explicitly noted in YAML classification.work
   and next_gate.

## Wave 3 changes (2026-08-19): P-CONSOLIDATION-1 unused-hypothesis remediation

**Defect (P-CONSOLIDATION-1).** The registered parent
`source_consolidation_preserves_eligibility_value_atomicity` declared
`hGatewayAdmittedNonzero` but its proof term forwarded only `inputs` to
`SolidityConsolidation.source_consolidation_preserves_eligibility_value_atomicity`,
which did not take that hypothesis at all — Lean's unused-variable linter
flagged it. The Wave 1 claim that this premise made the `fee = 0 ∧
msg.value = 0` free-batch commit "no longer user-reachable" was false: the
conclusion was identical with or without the hypothesis, and
`Tests/ConsolidationTxMutants.lean` already exercised a free batch
committing two zero-value CALLs.

**Fix: threaded the hypothesis (load-bearing option).**
`SolidityConsolidation.source_consolidation_preserves_eligibility_value_atomicity`
now takes `hGatewayAdmittedNonzero` and the `PConsolidation1` wrapper
forwards it. On the `.committed` branch, the hypothesis (applied to
`hEq : inputs.caller = inputs.gateway`) gives `inputs.msgValue.val ≠ 0`;
combined with the branch's own `inputs.msgValue.val = requests.length *
inputs.fee.val` and `requests.length ≠ 0` (new helper lemma
`zipRequests_some_length` transports `inputs.sources.length ≠ 0` onto
`requests.length`), a zero fee is excluded by contradiction. The
committed-branch witness tuple gains an explicit `inputs.fee.val ≠ 0`
conjunct — the parent statement itself changed, not just its proof.

**New kill-line: `gateway_admitted_nonzero_kill_line`.** Proves
`¬ (∀ inputs obs, sourceRun inputs = .committed obs → inputs.fee.val ≠ 0)`
via a concrete gateway-authorized, nonempty, 48-byte-aligned batch with
`fee = 0` and `msg.value = 0` that still commits `sourceRun` (checked by
`native_decide`). This refutes the registered parent's own strengthened
conjunct when the `hGatewayAdmittedNonzero` premise is dropped, so a future
regression that quietly stops threading the premise (making it decorative
again) fails to compile as a proof of the un-strengthened claim. Both the
source-plane theorem (`ConsolidationCorrespondence.lean`) and the
`PConsolidation1` wrapper expose this theorem; `Tests/ConsolidationTxMutants.lean`
re-exposes it as `gateway_admitted_nonzero_kill_line_refutes_parent` so the
required test-target build (`LidoSRv3.Tests.ConsolidationTxMutants`)
covers it.

**Scope corrected by Wave 4 below:** the free-batch witness violates the
premise (`caller = gateway` but `msg.value = 0`), so this theorem refutes
only the hypothesis-free projection of the committed arm — it is
premise-necessity evidence, not a refutation of the hypothesis-conditioned
parent. The Tests re-export is renamed
`gateway_admitted_nonzero_premise_necessity`, and the
"…_refutes_parent" name moved to the model-mutant kill-line
`fee_blind_commit_kill_line_refutes_parent`.

**What did not change.** `sourceRun`'s decision tree, `commitObservables`,
`Tests/ConsolidationTxMutants.lean`'s pre-existing `_requireExactFee(0)`
vector (still committing on the raw, hypothesis-free function — this is
honest and expected, see issue 18), the Verity `verity_tx_simulates_consolidation`
theorem, and `packing_order_kills_swapped_concat` are all unchanged. No
`sorry`/`admit`.

**Build.** `lake build LidoSRv3.Audit.Guarantees.PConsolidation1
LidoSRv3.Tests.ConsolidationTxMutants`: exit 0, no new warnings (the
pre-existing `hGatewayAdmittedNonzero` unused-variable warning is gone).
`python3 scripts/audit_metadata.py generate && check`: exit 0 (11 canonical
guarantees + 14 subordinate evidence rows).

## Wave 4 changes (2026-08-19): P-CONSOLIDATION-1 kill-line scope remediation

**Defect (found in wave-4 review).** `gateway_admitted_nonzero_kill_line`
(re-exported in Tests as `gateway_admitted_nonzero_kill_line_refutes_parent`)
proved `¬ (∀ inputs obs, sourceRun inputs = .committed obs →
inputs.fee.val ≠ 0)` via `freeBatchWitness` (caller = gateway, `fee = 0`,
`msg.value = 0`). That witness VIOLATES the registered parent's
`hGatewayAdmittedNonzero` premise, so the theorem refutes only the
hypothesis-free projection of the parent's committed arm: under the premise
the witness is out of scope, and no kill-line refuted the
hypothesis-conditioned parent on a mutant of its own model. The
"…_refutes_parent" naming, and YAML/report wording that called this a
refutation of "the registered parent's own strengthened statement",
overclaimed.

**Fix: model-mutant kill-line with the premise satisfied.**
`SolidityConsolidation.sourceRunFeeBlind` is `sourceRun` with the exact-fee
guard (`inputs.msgValue.val = requests.length * inputs.fee.val`, pinned
`_requireExactFee`) dropped and nothing else changed.
`fee_blind_commit_kill_line_refutes_parent` (proved in
`ConsolidationCorrespondence.lean`, re-exported by the `PConsolidation1`
wrapper and by `Tests/ConsolidationTxMutants.lean`, where the
"…_refutes_parent" name now lives) exhibits `feeBlindWitness` — a
gateway-authorized batch with one valid 48-byte pair, `fee = 0`,
`msg.value = 1` — and proves: (i) the witness SATISFIES
`hGatewayAdmittedNonzero` (`caller = gateway → msg.value ≠ 0`); (ii)
`sourceRunFeeBlind` commits it; (iii) every fee-independent conjunct of the
parent's committed arm holds of that commit (zip, caller = gateway,
nonempty, 48-byte-valid, `uint256` bound, canonical observables); (iv)
`inputs.fee.val = 0`, so the full committed-arm conjunction — which includes
`inputs.fee.val ≠ 0` — is false on the mutant commit. The parent's own
hypothesis-conditioned predicate is thereby refuted on a mutant of its own
model, which the wave-3 free-batch theorem could not show.

**Relabeling.** `gateway_admitted_nonzero_kill_line` stays, but its
docstrings, the YAML row, and this report now describe it as
premise-necessity evidence (the parent's strengthened conjunct would be
false without `hGatewayAdmittedNonzero`), not as the parent-refuting
kill-line; the Tests re-export is renamed
`gateway_admitted_nonzero_premise_necessity`.

**Also refreshed.** Issue 3 was stale: `observe` reads the journal appended
to `state.calls` / `state.events` (`ConsolidationTx.lean:191–200`), not the
`Result` payload, so the skip-append mutant it described is already caught
by the existing call-drop/event-drop vectors.

**What did not change.** The registered parent's statement and proof,
`sourceRun`, `commitObservables`, `verity_tx_simulates_consolidation`,
`packing_order_kills_swapped_concat`, the `_requireExactFee(0)` vector, and
every pre-existing Tests vector are unchanged. `abstract.theorem`,
`verity.theorem`, `classification`, and `assumptions` in the YAML row are
untouched; only `summary`, `fidelity.covered`, and `reproduction.expected`
were re-scoped, and `EXPECTED_CANONICAL_DETAIL_SHA256["P-CONSOLIDATION-1"]`
was recomputed. No `sorry`/`admit`/new axioms: the new theorems use the
codebase's existing `native_decide` idiom for ground `Word` computations.

**Build.** `lake build LidoSRv3` and `lake build
LidoSRv3.Tests.ConsolidationTxMutants`: exit 0. `python3
scripts/audit_metadata.py generate && check`: exit 0 (11 canonical
guarantees + 14 subordinate evidence rows).
