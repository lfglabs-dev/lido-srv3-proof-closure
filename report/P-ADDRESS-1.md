# P-ADDRESS-1

The registered `LidoSRv3.Audit.Guarantees.PAddress1.universal_address_writer_equivariance` preserves the original source-shaped equivariance conclusions and additionally consumes actual claim-batch execution. Targeted Lean validation passed at `6f44fcae7738896385a102e56e78e30769d5db04` on registered `dgx-spark`, job `2ccd4fd6-8ec8-4eb3-a9b2-49f27b017cb4` (1276 build jobs), including both parent-shaped and actual-CALL mutants. Combined-candidate validation remains pending.

For arbitrary nonzero callers `a₁`, `a₂` and every `SolidityAddress.Input`, its conclusion is:

```
(AdmissionIsCallerBlind a₁ a₂ inp ∧ PostStateRenamesWithCaller a₁ a₂ inp)
  ∧ LiveClaimBatchBehavior
```

The first conjunct retains admission equality and successful post-state renaming under the caller swap for `transferFrom`, `requestWithdrawals`, `claimWithdrawalsTo`, and `unwrap`. It remains a source-shaped projection with environment booleans. Only `requestWithdrawals` and `unwrap` have the pause/balance/allowance permissionless-admission result. No singleton-actor entrypoint was added or used to restrict the claim.

`LiveClaimBatchBehavior` universally quantifies over the actual external-callee function, context, request and hint lists, recipient, and input world. It examines `AddressRecipientCallBridge.runClaimWithdrawalsTo` itself:

- A successful root result derives a nonzero recipient, matching array lengths, and an ordered `ClaimChain` connecting the input world to the actual final world and call attempts.
- Any root error restores the entire input world, including earlier caller and callback writes, balances, and events.

No admission boolean, `BatchReady` bundle, desired boundary equality, or independent stage-success premise supplies this live result. Each chain step derives `ClaimEffect` from execution. The physical queue/checkpoint/EnumerableSet operations compute the payout and locked-ETH write; that payout feeds the sole recipient/value/empty-calldata CALL. `PayoutEffect` records the provisional balance transfer, EOA or code-bearing path, actual callee return data and nested attempts, and the returned world. `WithdrawalClaimed` and `Transfer` follow the successful callback in source order. The next request runs against that returned world.

The source basis is `lido-core@17005714f151e5502c559932319a3f2f74ac2436`: `WithdrawalQueue.sol:244-255`, `WithdrawalQueueBase.sol:460-479` and its claimable-ether calculation, plus `StETH.sol:252-255` for allowance-before-transfer ordering. The projection's guard order was corrected to finalized-before-claimed/owner, owner-before-hint, and allowance-before-balance. The physical claim already marks/removes the request before hint calculation and checks the external recipient before array lengths.

The preserved ADDRESS patch, based on `d56a7c40b7d120ac81f26c979195357a2f3262c6`, proposed attaching an unbounded journal result. Its composition intent is retained using the stronger current physical executor. Its old `AddressClaimUnboundedCorrespondence` result now belongs to `Model.AddressClaimJournalLegacy`; it is not a live callback proof. The preserved metadata-script edit only changed an expected fingerprint and was not copied.

Remaining obligations:

- Global live-world renaming remains unproved. The source-projection theorem does not show that jointly permuting sender, packed owner state, owner-indexed sets, balances, code and arbitrary callee behavior commutes with actual execution.
- Physical keccak slot formulas are used directly, but `World.core` models the active contract's storage. General deployed runtime/EVM-interpreter correspondence and external-code correctness remain outside this scoped result; `External` is the named executable callee interface.
- A successful arbitrary callback can spend its credit or change claim storage. The parent preserves its exact returned world; it does not assert final recipient net credit or final claimed-bit preservation against such callbacks.
- Full state/callee equivariance for token transfers, `requestWithdrawals`, `unwrap`, and ERC-721 approval branches is not supplied by the claim-batch limb. The existing boolean/source projections and naming helpers do not close those gaps.
- Source error ABI bytes and general gas/deployment behavior are not established by the reason-tagged execution model.

The admission and owner-write mutant theorems retain the strengthened parent's live conjunct while refuting its original renaming conjunct. `PackDAddressClaimMutants` separately checks actual payout-order/target changes, zero-recipient rejection and full-world rollback. Legacy journal mutants remain historical diagnostics.

Reproduce with the pinned Lean toolchain and registered remote runner:

```sh
lake build LidoSRv3.Audit.Guarantees.PAddress1 \
  LidoSRv3.Audit.Verity.AddressTx LidoSRv3.Audit.Verity.AddressClaimBatchTx \
  LidoSRv3.Tests.AddressSourceMutants LidoSRv3.Tests.PackDAddressClaimMutants
```

This is an unfinished candidate for independent audit, not a claim of deployed closure.

## No re-entry (A-NO-REENTRY, 2026-09-17)

[PAddress1NoReentry](../LidoSRv3/Audit/Guarantees/PAddress1NoReentry.lean) proves `claim_returns_committed_storage` (under `NoReentry callee [queue]`, the world after the recipient CALL holds exactly the claim's committed dirty storage, so the claimed bit and the locked-ether write are final, and the queue balance is the provisional payout transfer) and the registered-parent corollary `actual_claim_batch_no_reentry` (the same-world claim chain of `runClaimWithdrawalsTo_success` plus: no accepted nested attempt in the batch transcript targets the queue). Final recipient net credit is still not asserted. The premise is assumed, not proved for the recipient.

## Live renaming of the claim batch (2026-09-19)

[PAddress1LiveRenaming](../LidoSRv3/Audit/Guarantees/PAddress1LiveRenaming.lean) proves that renaming two nonzero addresses in the sender and in the request owners commutes with the registered live executor `runClaimWithdrawalsTo`. The renaming is an abstract `LiveRenaming` (owner fields of the request metadata words and the owner-indexed set cells renamed, every other claim channel, balances and code fixed, the queue's two claim events renamed): the queue's channels live at computable keccak slots, so no renaming can be written on raw storage without a collision-freedom premise, and that premise is exactly the existence of a `LiveRenaming`. The recipient callee's equivariance under the renaming is an explicit hypothesis. `runClaimWithdrawalsTo_rename`: the renamed run has the same outcome and CALL transcript and the renamed final world, rollback included. `actual_claim_batch_rename`: a committed batch stays committed with the transported `ClaimChain` and, under A-NO-REENTRY, no accepted nested call into the queue. The other live writer bodies (`transferFrom`, `requestWithdrawals`, `unwrap`) remain source-shaped only. Axioms: `propext`, `Classical.choice`, `Quot.sound`.
