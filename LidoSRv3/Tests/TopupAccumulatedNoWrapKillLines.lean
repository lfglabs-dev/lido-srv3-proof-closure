import LidoSRv3.Audit.Source.TopupCorrespondence

/-! # Kill-lines for `TopupCorrespondence` accumulated/wrappedTotal + NoUncheckedWrap

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned `wrappedTotal = exactTotal % 2^256` alias and the
NoUncheckedWrap side condition together with the faithful-wrap
identity. -/

namespace LidoSRv3.Tests.TopupAccumulatedNoWrapKillLines

open LidoSRv3.Audit.SolidityTopup

/-- Universally quantified identity: `allocSumUnchecked_eq_allocSum`
under `allocSum inp.allocations < 2^256` yields the faithful reading. -/
theorem totalAllocated_faithful_kill
    (inp : SourceTopupInput) (h : NoUncheckedWrap inp) :
    accumulated inp = totalAllocated inp :=
  totalAllocated_faithful h

/-- **Kill-line: `wrappedTotal inp = accumulated inp` alias.** -/
theorem wrappedTotal_eq_accumulated (inp : SourceTopupInput) :
    wrappedTotal inp = accumulated inp := rfl

/-- **Kill-line: `accumulated inp = allocSumUnchecked inp.allocations`
composition.** -/
theorem accumulated_composition (inp : SourceTopupInput) :
    accumulated inp = allocSumUnchecked inp.allocations := rfl

/-- **Kill-line: `totalAllocated inp = allocSum inp.allocations`
composition.** -/
theorem totalAllocated_composition (inp : SourceTopupInput) :
    totalAllocated inp = allocSum inp.allocations := rfl

/-- **Kill-line: `NoUncheckedWrap inp = (totalAllocated inp < 2^256)`
definition.**

A mutant that changed the threshold would refute the pinned
A-TOPUP-NOWRAP assumption shape. -/
theorem NoUncheckedWrap_composition (inp : SourceTopupInput) :
    NoUncheckedWrap inp ↔ totalAllocated inp < uint256Modulus :=
  Iff.rfl

#print axioms totalAllocated_faithful_kill
#print axioms wrappedTotal_eq_accumulated
#print axioms accumulated_composition
#print axioms totalAllocated_composition
#print axioms NoUncheckedWrap_composition

end LidoSRv3.Tests.TopupAccumulatedNoWrapKillLines
