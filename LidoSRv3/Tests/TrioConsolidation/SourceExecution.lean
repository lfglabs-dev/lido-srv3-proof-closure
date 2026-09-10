import audit.trio.consolidation.SourceExecution

namespace LidoSRv3.Tests.TrioConsolidation.SourceExecution

open audit.trio.consolidation

private def key (id : Nat) : Pubkey := ⟨id, 48⟩
private def wrapKey (id : Nat) : Pubkey := ⟨id + pubkeyModulus, 48⟩
private def args : ConstructorArgs :=
  ⟨word 1, word 2, word 3, word 4, word 5, word 6⟩
private def deployment : DeployedVault := ⟨args, by decide⟩
private def caller : Word := args.consolidationGateway
private def sources := [key 11, key 12]
private def targets := [key 21, key 22]
private def expectedPayloads : List (List Nat) :=
  (packedPayloads (sources.zip targets)).getD []

/-- Constructor rejection belongs to deployment, not runtime execution. -/
example : constructorConditions
    ⟨word 1, word 2, word 3, word 4, word 0, word 6⟩ = false := by decide

example : executeSourceBounded 2 deployment caller (.success (word 3))
    [.success (), .success ()] (word 6) sources targets 40 =
    .committed (sources.zip targets) expectedPayloads 40 := by decide

/-- Caller/callee: committed payloads are the 96-byte packed blobs. -/
example : expectedPayloads.length = 2 ∧
    expectedPayloads.all (fun p => p.length = 96) = true := by decide

/-- Wrapping identities are rejected at the callee-payload boundary, not
encoded to the same 48 bytes as the unshifted key. Exact fee for one pair
so the vault length/fee guards pass and the payload bound is the one that
fires. -/
example : executeSourceBounded 1 deployment caller (.success (word 3))
    [.success ()] (word 3) [wrapKey 11] [key 21] 40 =
    .reverted .invalidPubkey 40 := by decide

/-- Regression for pinned `_getFeeFromContract`: failed STATICCALL reverts. -/
example : executeSourceBounded 2 deployment caller .failure [] (word 6) sources targets 40 =
    .reverted .staticcallFailed 40 := by decide

/-- Regression for pinned `_callAddConsolidationRequest`: a later failed CALL
rolls back the earlier value transfer and restores the entry balance. -/
example : executeSourceBounded 2 deployment caller (.success (word 3))
    [.success (), .failure] (word 6) sources targets 40 =
    .reverted (.callFailed 1) 40 := by decide

/-- Too little fuel is explicitly open and therefore does not satisfy the
named source-closure obligation. -/
example : ¬ requireClosedExit 1 deployment caller (.success (word 3))
    [.success (), .success ()] (word 6) sources targets 40 := by
  unfold requireClosedExit
  have hopen : executeSourceBounded 1 deployment caller (.success (word 3))
      [.success (), .success ()] (word 6) sources targets 40 = .openExit := by
    decide
  exact fun h => h hopen

example : requireClosedExit 2 deployment caller (.success (word 3))
    [.success (), .success ()] (word 6) sources targets 40 := by
  unfold requireClosedExit
  have hcommit : executeSourceBounded 2 deployment caller (.success (word 3))
      [.success (), .success ()] (word 6) sources targets 40 =
      .committed (sources.zip targets) expectedPayloads 40 := by decide
  rw [hcommit]
  simp

/-- Both pinned runtime pre-loop failure arms inhabit the named obligation. -/
example :
    requireClosedExit 0 deployment (word 99) (.success (word 3)) []
        (word 6) sources targets 40 ∧
      requireClosedExit 0 deployment caller .failure [] (word 6) sources targets 40 := by
  constructor
  · exact (preloop_failures_requireClosedExit 0 deployment (word 99) []
      (word 6) sources targets 40).1 (by decide)
  · exact (preloop_failures_requireClosedExit 0 deployment caller []
      (word 6) sources targets 40).2 rfl

end LidoSRv3.Tests.TrioConsolidation.SourceExecution
