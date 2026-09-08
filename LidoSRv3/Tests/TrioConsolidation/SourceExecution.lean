import audit.trio.consolidation.SourceExecution

namespace LidoSRv3.Tests.TrioConsolidation.SourceExecution

open audit.trio.consolidation

private def key (id : Nat) : Pubkey := ⟨id, 48⟩
private def args : ConstructorArgs := ⟨word 1, word 2, word 3⟩
private def sources := [key 11, key 12]
private def targets := [key 21, key 22]

/-- A zero constructor immutable closes immediately, before either external
call surface is consulted. -/
example : executeSourceBounded 0 ⟨word 1, word 0, word 3⟩
    (.success (word 3)) [] (word 6) sources targets 40 =
    .reverted .invalidConstructor 40 := by decide

example : executeSourceBounded 2 args (.success (word 3))
    [.success (), .success ()] (word 6) sources targets 40 =
    .committed (sources.zip targets) 40 := by decide

/-- Regression for pinned `_getFeeFromContract`: failed STATICCALL reverts. -/
example : executeSourceBounded 2 args .failure [] (word 6) sources targets 40 =
    .reverted .staticcallFailed 40 := by decide

/-- Regression for pinned `_callAddConsolidationRequest`: a later failed CALL
rolls back the earlier value transfer and restores the entry balance. -/
example : executeSourceBounded 2 args (.success (word 3))
    [.success (), .failure] (word 6) sources targets 40 =
    .reverted (.callFailed 1) 40 := by decide

/-- Too little fuel is explicitly open and therefore does not satisfy the
named source-closure obligation. -/
example : ¬ requireClosedExit 1 args (.success (word 3))
    [.success (), .success ()] (word 6) sources targets 40 := by
  unfold requireClosedExit
  have hopen : executeSourceBounded 1 args (.success (word 3))
      [.success (), .success ()] (word 6) sources targets 40 = .openExit := by
    decide
  exact fun h => h hopen

example : requireClosedExit 2 args (.success (word 3))
    [.success (), .success ()] (word 6) sources targets 40 := by
  unfold requireClosedExit
  have hcommit : executeSourceBounded 2 args (.success (word 3))
      [.success (), .success ()] (word 6) sources targets 40 =
      .committed (sources.zip targets) 40 := by decide
  rw [hcommit]
  simp

/-- Both pinned pre-loop failure arms inhabit the named closure obligation. -/
example :
    requireClosedExit 0 ⟨word 1, word 0, word 3⟩ (.success (word 3)) []
        (word 6) sources targets 40 ∧
      requireClosedExit 0 args .failure [] (word 6) sources targets 40 := by
  constructor
  · exact (preloop_failures_requireClosedExit 0
      ⟨word 1, word 0, word 3⟩ [] (word 6) sources targets 40).1 (by decide)
  · exact (preloop_failures_requireClosedExit 0 args [] (word 6) sources
      targets 40).2 (by decide)

end LidoSRv3.Tests.TrioConsolidation.SourceExecution
