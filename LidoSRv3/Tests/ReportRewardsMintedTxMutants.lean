import LidoSRv3.Audit.Verity.ReportRewardsMintedTx

namespace LidoSRv3.Tests.ReportRewardsMintedTxMutants

open LidoSRv3.Audit.SolidityAccounting.ReportRewardsMinted
open LidoSRv3.Audit.Verity.ReportRewardsMintedTx

/-- The outcome-boundary predicate satisfied by the parent transaction.  A
mutant is refuted by one input on which its independently reconstructed view
does not match the source view. -/
def parentShape (candidate : Input → View) : Prop :=
  ∀ i, candidate i = sourceView i

private def zero : Input := ⟨[7], [9], [0], 1, [.accept]⟩
private def one : Input := ⟨[7], [9], [1], 1, [.accept]⟩
private def short : Input := ⟨[7], [9], [1], 1, []⟩
private def empty : Input := ⟨[7], [9], [1], 1, [.revertEmpty]⟩

def zeroSkipDropped (_ : Input) : View :=
  ⟨.committed, [.minted, .callback 7 0], ⟨[0], 1⟩⟩
def callbackBeforeDistribute (_ : Input) : View :=
  ⟨.committed, [.minted, .callback 7 1, .distributed 7 1], ⟨[1], 0⟩⟩
def lengthMismatchDropped (_ : Input) : View := ⟨.committed, [], ⟨[1], 0⟩⟩
def emptyRevertSwallowed (_ : Input) : View := ⟨.committed, [], ⟨[1], 0⟩⟩

/-- Dropping SRLib's zero skip makes a callback observable for zero shares. -/
theorem zero_skip_dropped_refutes_parent : zeroSkipDropped zero ≠ sourceView zero := by decide
/-- Calling router before distribution conflicts with the callback-last trace. -/
theorem callback_before_distribute_refutes_parent :
    callbackBeforeDistribute one ≠ sourceView one := by decide
/-- Dropping the length guard cannot preserve ArraysLengthMismatch behavior. -/
theorem length_mismatch_dropped_refutes_parent :
    lengthMismatchDropped short ≠ sourceView short := by decide
/-- Empty low-level revert must roll back rather than be swallowed. -/
theorem empty_revert_swallowed_refutes_parent :
    emptyRevertSwallowed empty ≠ sourceView empty := by decide

/-- Each local counterexample above is also a refutation of the universal
parent-shaped predicate, rather than merely an assertion about an arbitrary
trace literal. -/
theorem zero_skip_dropped_not_parent_shape : ¬ parentShape zeroSkipDropped := by
  intro h
  exact zero_skip_dropped_refutes_parent (h zero)

theorem callback_before_distribute_not_parent_shape :
    ¬ parentShape callbackBeforeDistribute := by
  intro h
  exact callback_before_distribute_refutes_parent (h one)

theorem length_mismatch_dropped_not_parent_shape : ¬ parentShape lengthMismatchDropped := by
  intro h
  exact length_mismatch_dropped_refutes_parent (h short)

theorem empty_revert_swallowed_not_parent_shape : ¬ parentShape emptyRevertSwallowed := by
  intro h
  exact empty_revert_swallowed_refutes_parent (h empty)

end LidoSRv3.Tests.ReportRewardsMintedTxMutants
