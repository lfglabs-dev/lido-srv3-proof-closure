# Unproved PR307 statements removed from proof exports

These are archived obligations, not Lean declarations or accepted boundaries. The five receipt axioms are not replaced by assumptions. Direct kernel reduction of the physical two-claim receipt did not produce a decision; no proof of that finite receipt is claimed. The old storage-only spec/tests expected synthetic CALL journals, while the changed executor deliberately emits none; that equation is obsolete. The arbitrary-function renaming obligation does not require injectivity and permits recipient 2 to map to queue 99, making its claimed zero queue balance/70 recipient balance contradictory at that alias.

## AddressClaimBatchTx finite obligation

```lean
/-- Concrete storage receipt for a two-item live batch.  The actual recipient
CALLs are represented by the live-world bridge, not a duplicate stub journal.
The pinned Keccak backend is opaque to Lean's kernel evaluator, so this
finite receipt remains an explicit model boundary rather than falsely
replacing the physical `readSlot` path with a `mapUint` surrogate. -/
theorem two_claim_batch_observe :
    observe [1, 2]
        ((executeClaimWithdrawalsTo [1, 2] [1, 1] (2 : Address)).run twoClaimState) =
      ⟨.committed, [true, true], 0, []⟩ := by
  decide +kernel


```

## claim_bridge_receipt

```lean
/-- End-to-end receipt for the smallest recipient bridge.  The storage claim,
the exact empty-calldata CALL, and the callee-returned world agree on both the
30 wei value and address 2. -/
axiom claim_bridge_receipt :
    let result := runClaimTo acceptingCallee claimBridgeContext 1 1 (2 : Address)
      claimBridgeWorld
    result.outcome = .ok () ∧
      result.world.core.readSlot (queueMetadataPhysicalSlot 1) =
        markClaimed (requestMetadataWord twoClaimState 1) ∧
      result.world.core.selfBalance = 70 ∧
      result.world.balances claimBridgeContext.self = 40 ∧
      result.world.balances (2 : Address) = 30 ∧
      result.world.logs =
        [⟨claimBridgeContext.self, "WithdrawalClaimed", [1, 1, 2, 30]⟩,
         ⟨claimBridgeContext.self, "Transfer", [1, 0, 1]⟩] ∧
      result.attempts = [⟨⟨claimBridgeContext.self, (2 : Address), 30, []⟩,
        true, [], []⟩]
```

## claim_withdrawals_to_bridge_receipt

```lean
/-- The public two-item entrypoint retains both physical claimed writes and
executes two recipient CALLs in source loop order.  The callee's returned
world is the committed result, rather than a Boolean call-success premise. -/
axiom claim_withdrawals_to_bridge_receipt :
    let result := runClaimWithdrawalsTo acceptingCallee claimBridgeContext [1, 2] [1, 1]
      (2 : Address) claimBridgeWorld
    result.outcome = .ok () ∧
      result.world.core.readSlot (queueMetadataPhysicalSlot 1) =
        markClaimed (requestMetadataWord twoClaimState 1) ∧
      result.world.core.readSlot (queueMetadataPhysicalSlot 2) =
        markClaimed (requestMetadataWord twoClaimState 2) ∧
      result.world.core.readSlot lockedEtherAmountPosition = 0 ∧
      result.world.balances claimBridgeContext.self = 0 ∧
      result.world.balances (2 : Address) = 70 ∧
      result.world.logs =
        [⟨claimBridgeContext.self, "WithdrawalClaimed", [1, 1, 2, 30]⟩,
         ⟨claimBridgeContext.self, "Transfer", [1, 0, 1]⟩,
         ⟨claimBridgeContext.self, "WithdrawalClaimed", [2, 1, 2, 40]⟩,
         ⟨claimBridgeContext.self, "Transfer", [1, 0, 2]⟩] ∧
      result.attempts =
        [⟨⟨claimBridgeContext.self, (2 : Address), 30, []⟩, true, [], []⟩,
         ⟨⟨claimBridgeContext.self, (2 : Address), 40, []⟩, true, [], []⟩]
```

## transfer_bridge_receipt

```lean
/-- Owner-operated `transferFrom` receipt: no approval flag is supplied. The
caller is the request owner, so the physical token-approval word is deleted
and only the owner field of the packed request metadata becomes address 2. -/
axiom transfer_bridge_receipt :
    let result := runTransferFrom transferBridgeContext (1 : Address) (2 : Address) 1
      transferBridgeWorld
    result.outcome = .ok () ∧
      result.world.core.readMapUint tokenApprovalsPosition 1 = 0 ∧
      requestOwner (requestMetadataWord result.world.core 1) = (2 : Address) ∧
      result.world.core.readSlot (queueMetadataPhysicalSlot 1) =
        withRequestOwner (requestMetadataWord transferBridgeWorld.core 1) (2 : Address) ∧
      result.world.logs = [⟨transferBridgeContext.self, "Transfer", [1, 2, 1]⟩] ∧
      result.attempts = []
```

## request_bridge_receipt

```lean
/-- One-item `requestWithdrawals` receipt. The owner fallback is caller 1,
and the successful post-call enqueue writes request id 1 with cumulative
amount/shares `(100, 10)` and the packed owner/timestamp/report word. -/
axiom request_bridge_receipt :
    let result := runRequestWithdrawals requestCallee requestBridgeContext (2 : Address)
      100 zeroAddress requestBridgeWorld
    result.outcome = .ok 1 ∧
      result.world.core.readSlot lastRequestIdPosition = 1 ∧
      requestAmountsWord result.world.core 1 = packEnqueuedAmounts 100 10 ∧
      requestMetadataWord result.world.core 1 = packEnqueuedMetadata (1 : Address) 5 9 ∧
      result.world.logs =
        [⟨requestBridgeContext.self, "WithdrawalRequested", [1, 1, 1, 100, 10]⟩,
         ⟨requestBridgeContext.self, "Transfer", [0, 1, 1]⟩] ∧
      result.attempts =
        [⟨⟨requestBridgeContext.self, (2 : Address), 0,
            stETHTransferFromCalldata requestBridgeContext.sender requestBridgeContext.self 100⟩,
            true, abiWord 1, []⟩,
         ⟨⟨requestBridgeContext.self, (2 : Address), 0, stETHSharesCalldata 100⟩,
            true, abiWord 10, []⟩]
```

## Unaccepted public finite surface and renaming obligation

```lean
/-- Bounded live `claimWithdrawalsTo` evidence. This is the recipient-CALL
bridge, not the storage-only batch abstraction: it
commits both packed claims, both ordered empty-calldata value CALLs, their two
events per claim, and the returned callee world. This remains a bounded model
slice; it is deliberately not claimed to establish universal renaming. -/
theorem bounded_live_claim_recipient_call_surface :
    (let result := LidoSRv3.Audit.Verity.AddressRecipientCallBridge.runClaimWithdrawalsTo
      LidoSRv3.Audit.Verity.AddressRecipientCallBridge.acceptingCallee
      LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext [1, 2] [1, 1]
      (2 : Verity.Address) LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeWorld
    result.outcome = .ok () ∧
      result.world.core.readSlot
        (LidoSRv3.Audit.Verity.AddressClaimBatchTx.queueMetadataPhysicalSlot 1) =
          LidoSRv3.Audit.Verity.AddressClaimBatchTx.markClaimed
            (LidoSRv3.Audit.Verity.AddressClaimBatchTx.requestMetadataWord
              LidoSRv3.Audit.Verity.AddressClaimBatchTx.twoClaimState 1) ∧
      result.world.core.readSlot
        (LidoSRv3.Audit.Verity.AddressClaimBatchTx.queueMetadataPhysicalSlot 2) =
          LidoSRv3.Audit.Verity.AddressClaimBatchTx.markClaimed
            (LidoSRv3.Audit.Verity.AddressClaimBatchTx.requestMetadataWord
              LidoSRv3.Audit.Verity.AddressClaimBatchTx.twoClaimState 2) ∧
      result.world.core.readSlot LidoSRv3.Audit.Verity.AddressClaimBatchTx.lockedEtherAmountPosition = 0 ∧
      result.world.balances LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self = 0 ∧
      result.world.balances (2 : Verity.Address) = 70 ∧
      result.world.logs =
        [⟨LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self, "WithdrawalClaimed", [1, 1, 2, 30]⟩,
         ⟨LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self, "Transfer", [1, 0, 1]⟩,
         ⟨LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self, "WithdrawalClaimed", [2, 1, 2, 40]⟩,
         ⟨LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self, "Transfer", [1, 0, 2]⟩] ∧
      result.attempts =
        [⟨⟨LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self, (2 : Verity.Address), 30, []⟩, true, [], []⟩,
         ⟨⟨LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self, (2 : Verity.Address), 40, []⟩, true, [], []⟩]) ∧
    (∀ (callee : LidoSRv3.Audit.Verity.AddressRecipientCallBridge.External)
      (ctx : LidoSRv3.Audit.Verity.AddressRecipientCallBridge.Context)
      (requestIds hints : List Nat) (recipient : Verity.Address)
      (before : LidoSRv3.Audit.Verity.AddressRecipientCallBridge.World)
      (fault : LidoSRv3.Audit.Source.TrioReserve1.Live.Fault),
      (LidoSRv3.Audit.Verity.AddressRecipientCallBridge.runClaimWithdrawalsTo
        callee ctx requestIds hints recipient before).outcome = .error fault →
      (LidoSRv3.Audit.Verity.AddressRecipientCallBridge.runClaimWithdrawalsTo
        callee ctx requestIds hints recipient before).world = before) := by
  exact ⟨LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claim_withdrawals_to_bridge_receipt,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claim_withdrawals_to_revert_restores_caller_and_callee_world⟩

/-- Remaining OPEN obligation for P-ADDRESS-1.  A caller/recipient renaming
must consume the *live* receipt, not merely the source post-state: it has to
relate the two physical claimed words, caller and recipient balances, and the
ordered CALL/event/attempt journals.  No theorem proves this definition yet. -/
def live_claim_receipt_renaming_obligation : Prop :=
  ∀ (ρ : Verity.Address → Verity.Address), ρ 0 = 0 → ρ 1 = 1 → ρ 99 = 99 →
    ρ 2 ≠ 0 →
    let result := LidoSRv3.Audit.Verity.AddressRecipientCallBridge.runClaimWithdrawalsTo
      LidoSRv3.Audit.Verity.AddressRecipientCallBridge.acceptingCallee
      LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext [1, 2] [1, 1]
      (ρ 2) LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeWorld
    result.outcome = .ok () ∧
      result.world.core.readSlot
        (LidoSRv3.Audit.Verity.AddressClaimBatchTx.queueMetadataPhysicalSlot 1) =
          LidoSRv3.Audit.Verity.AddressClaimBatchTx.markClaimed
            (LidoSRv3.Audit.Verity.AddressClaimBatchTx.requestMetadataWord
              LidoSRv3.Audit.Verity.AddressClaimBatchTx.twoClaimState 1) ∧
      result.world.core.readSlot
        (LidoSRv3.Audit.Verity.AddressClaimBatchTx.queueMetadataPhysicalSlot 2) =
          LidoSRv3.Audit.Verity.AddressClaimBatchTx.markClaimed
            (LidoSRv3.Audit.Verity.AddressClaimBatchTx.requestMetadataWord
              LidoSRv3.Audit.Verity.AddressClaimBatchTx.twoClaimState 2) ∧
      result.world.core.readSlot LidoSRv3.Audit.Verity.AddressClaimBatchTx.lockedEtherAmountPosition = 0 ∧
      result.world.balances LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self = 0 ∧
      result.world.balances (ρ 2) = 70 ∧
      result.world.logs =
        [⟨LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self, "WithdrawalClaimed", [1, 1, .ofNat (ρ 2).toNat, 30]⟩,
         ⟨LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self, "Transfer", [1, 0, 1]⟩,
         ⟨LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self, "WithdrawalClaimed", [2, 1, .ofNat (ρ 2).toNat, 40]⟩,
         ⟨LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self, "Transfer", [1, 0, 2]⟩] ∧
      result.attempts =
        [⟨⟨LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self, ρ 2, 30, []⟩, true, [], []⟩,
         ⟨⟨LidoSRv3.Audit.Verity.AddressRecipientCallBridge.claimBridgeContext.self, ρ 2, 40, []⟩, true, [], []⟩]


```