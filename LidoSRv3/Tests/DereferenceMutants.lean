import LidoSRv3.Audit.Guarantees.PDeref1

namespace LidoSRv3.Tests.DereferenceMutants

open LidoSRv3.Audit.SolidityDereference

private def registeredOne : RegistryState :=
  { lastModuleId := 1
    registered := fun id => id = 1
    moduleAddress := fun id => if id = 1 then 0xBEEF else 0 }

theorem concrete_positive_vector :
    sourceDeref (runInterleavings registeredOne
      [.staticCallback, .setStatus 1 2, .updateAccounting 1 99,
       .addFreshModule 2 0xCAFE]) 1 = some 0xBEEF := by decide

/-- Mutant: omitting `_requireModuleIdExists` aliases an absent id to address 0. -/
def uncheckedDeref (s : RegistryState) (id : ModuleId) : ModuleAddress :=
  s.moduleAddress id

theorem rejects_missing_membership_guard :
    sourceDeref registeredOne 2 = none ∧ uncheckedDeref registeredOne 2 = 0 := by decide

/-- Mutant: an address-replacement writer creates a callback/interleaving race. -/
def replaceAddress (s : RegistryState) (id address : Nat) : RegistryState :=
  { s with moduleAddress := fun query => if query = id then address else s.moduleAddress query }

theorem concrete_address_replacement_counterexample :
    sourceDeref (replaceAddress registeredOne 1 0xCAFE) 1 ≠
      sourceDeref registeredOne 1 := by decide

/-- Concrete witness showing why the `uint24` bound may not be dropped. -/
theorem concrete_uint24_bound_counterexample :
    uint24Modulus % uint24Modulus = 0 ∧ uint24Modulus ≠ 0 := by decide

end LidoSRv3.Tests.DereferenceMutants
