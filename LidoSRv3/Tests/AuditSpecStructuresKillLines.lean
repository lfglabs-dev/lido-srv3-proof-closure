import LidoSRv3.Audit.Spec

/-! # Kill-lines for `Audit.Spec` composition-interface structures

**Chantier (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the Wave 0 frozen composition-interface record accessors for
Allocation / Spend / EthJournalLeg / OracleFrame. -/

namespace LidoSRv3.Tests.AuditSpecStructuresKillLines

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Common

/-- Concrete allocation fixture. -/
def sampleAllocation : Allocation :=
  { moduleId := 1, capacity := ⟨100⟩, amount := ⟨50⟩ }

/-- Concrete spend fixture. -/
def sampleSpend : Spend := { amount := ⟨1000⟩ }

/-- Concrete leg fixture. -/
def sampleLeg : EthJournalLeg :=
  { dest := .lidoPull, wei := ⟨2000⟩ }

/-- **Kill-line: Allocation.moduleId accessor.** -/
theorem sampleAllocation_moduleId :
    sampleAllocation.moduleId = 1 := rfl

/-- **Kill-line: Allocation.capacity accessor.** -/
theorem sampleAllocation_capacity :
    sampleAllocation.capacity.value = 100 := rfl

/-- **Kill-line: Allocation.amount accessor.** -/
theorem sampleAllocation_amount :
    sampleAllocation.amount.value = 50 := rfl

/-- **Kill-line: Spend.amount accessor.** -/
theorem sampleSpend_amount : sampleSpend.amount.value = 1000 := rfl

/-- **Kill-line: EthJournalLeg.dest accessor.** -/
theorem sampleLeg_dest :
    sampleLeg.dest = ApprovedDestination.lidoPull := rfl

/-- **Kill-line: EthJournalLeg.wei accessor.** -/
theorem sampleLeg_wei :
    sampleLeg.wei.value = 2000 := rfl

/-- **Kill-line: EthJournal is a list.** -/
theorem ethJournal_empty : ([] : EthJournal) = [] := rfl

/-- **Kill-line: OracleFrame accessor identity.** -/
theorem oracleFrame_composition :
    let f : OracleFrame := { balances := [10, 20, 30],
                             sharesMinted := 5, shareRateDelta := 1 }
    f.balances = [10, 20, 30] ∧
    f.sharesMinted = 5 ∧
    f.shareRateDelta = 1 := ⟨rfl, rfl, rfl⟩

#print axioms sampleAllocation_moduleId
#print axioms sampleAllocation_capacity
#print axioms sampleAllocation_amount
#print axioms sampleSpend_amount
#print axioms sampleLeg_dest
#print axioms sampleLeg_wei
#print axioms oracleFrame_composition

end LidoSRv3.Tests.AuditSpecStructuresKillLines
