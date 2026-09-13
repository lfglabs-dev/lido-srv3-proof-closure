import LidoSRv3.Audit.Source.TrioAlloc1.FirstPass

/-!
Kill-lines pinning `TrioAlloc1.FirstPass` `checkedCeilDiv` /
`checkedSub_word` arithmetic-contract theorems for P-ALLOC-1.
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1FirstPassKillLines

open LidoSRv3.Audit.Source.TrioAlloc1

/-! ## `checkedCeilDiv_nonzero` — restated. -/

theorem checkedCeilDiv_nonzero_restated
    (stake divisor : Word) (positive : divisor.val ≠ 0) :
    ∃ count, checkedCeilDiv stake divisor = .ok count ∧
      Ceiling stake.val divisor.val count.val :=
  checkedCeilDiv_nonzero stake divisor positive

/-! ## `checkedSub_word_success` — restated. -/

theorem checkedSub_word_success_restated
    (deposited : Word) (exited : Nat) (active : Word)
    (h : checkedSub deposited.val exited = .ok active) :
    active.val + exited = deposited.val :=
  checkedSub_word_success deposited exited active h

end LidoSRv3.Tests.SourceTrioAlloc1FirstPassKillLines
