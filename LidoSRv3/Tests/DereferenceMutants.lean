import LidoSRv3.Audit.Guarantees.PDeref1

namespace LidoSRv3.Tests.DereferenceMutants

open LidoSRv3.Audit.SolidityDereference

private def registeredOne : RegistryState :=
  { lastModuleId := 1
    registered := fun id => if id = 1 then true else false
    moduleAddress := fun id => if id = 1 then 0xBEEF else 0 }

private theorem registeredOne_reachable : Reachable registeredOne := by
  apply Reachable.migrated registeredOne
  constructor
  · decide
  · intro id hid
    simp only [registeredOne] at hid ⊢
    split at hid <;> simp_all [addressModulus]

theorem concrete_positive_vector :
    sourceDeref (runInterleavings registeredOne
      [.staticCallback, .setStatus 1 2, .updateAccounting 1 99,
       .addFreshModule 2 0xCAFE]) 1 = some 0xBEEF := by decide

theorem positive_vector_is_nonzero_by_reachability :
    registeredOne.moduleAddress 1 ≠ 0 := by
  exact LidoSRv3.Audit.Guarantees.PDeref1.closure registeredOne registeredOne_reachable 1
    (by simp [Dereferenceable, registeredOne]) [] |>.2

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

/-- EnumerableSet positions are one-based and every nonzero position is a member. -/
theorem accepts_later_enumerable_set_position :
    ((2 : Verity.Core.Uint256) ≠ 0 ↔ registeredOne.registered 1 = true) := by decide

/-- Upper packed config fields do not change the low-160-bit module address. -/
theorem packed_config_upper_fields_do_not_change_address :
    Verity.wordToAddress ((7 * addressModulus + 0xBEEF : Nat) : Verity.Core.Uint256) =
      Verity.Core.Address.ofNat 0xBEEF := by decide

end LidoSRv3.Tests.DereferenceMutants
