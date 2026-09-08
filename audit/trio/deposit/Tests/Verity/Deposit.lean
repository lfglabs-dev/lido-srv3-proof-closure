import audit.trio.deposit.Deposit

namespace audit.trio.deposit.Tests.Verity
open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioComposition
open audit.trio.deposit

def config : Config := ⟨word 32, word 64⟩
def allocation : ParentOutput := ⟨word 64, [word 64], [word 64]⟩
def moduleData : ModuleDepositData := ⟨2⟩
def selection : SelectedAllocation allocation 0 where
  selected := word 64
  selected_eq := by native_decide
def link : LinksSource config moduleData selection where
  nonzeroUnit := by native_decide
  moduleReturnWithinTarget := by native_decide

example :
    (composeValues selection.selected config moduleData 32).lidoPullWei = 64 ∧
    (composeValues selection.selected config moduleData 32).beaconTotalWei = 64 := by
  native_decide

example : PinnedConstructorAdmitted openConstructorCounterexample :=
  pinned_constructor_does_not_discharge_artifact_identities.1
example : ¬ ArtifactAssumptions openConstructorCounterexample :=
  pinned_constructor_does_not_discharge_artifact_identities.2

/-- ALLOC alone does not determine the independently returned key count. -/
def tooManyModuleKeys : ModuleDepositData := ⟨3⟩
example : ¬ LinksSource config tooManyModuleKeys selection := by
  intro h
  have selectedVal : (word 64).val = 64 := by native_decide
  have unitVal : (word 32).val = 32 := by native_decide
  have impossible := h.moduleReturnWithinTarget
  change 3 ≤ (word 64).val / (word 32).val at impossible
  rw [selectedVal, unitVal] at impossible
  omega

end audit.trio.deposit.Tests.Verity
