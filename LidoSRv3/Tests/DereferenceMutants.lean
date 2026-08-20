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

/-! ## Wave 3 kill-line: the registered parent is falsifiable

`PDeref1.closure` quantifies over the honest `applyInterleaving` / `runInterleavings`
where the four status/accounting writers are no-ops. The mutant below is a
syntactic edit of that same transition: the `setStatus` arm is changed from
`s` to a write that clobbers `moduleAddress id` to `0`, modeling a wide
`SSTORE` of the packed `ModuleStateConfig` word that zeros the low 160 bits
(issues 4 and 18). Every premise of the parent (`Reachable s`,
`Dereferenceable s id`) holds at the witness `registeredOne` / `1`, but the
mutant's post-interleaving dereference is `some 0` rather than
`some 0xBEEF`, so the parent's full conclusion conjunction is false on the
mutant. A second syntactic edit (`staticCallback` re-entrantly overwriting
address) gives the same shape. -/

/-- Mutant transition: `setStatus` clobbers the packed config word (issue 4/18). -/
def mutantApplyInterleavingClobber (s : RegistryState) : Interleaving → RegistryState
  | .staticCallback => s
  | .setStatus id _ =>
      { s with moduleAddress := fun q => if q = id then 0 else s.moduleAddress q }
  | .updateAccounting _ _ => s
  | .updateParamsOrShares _ _ => s
  | .addFreshModule freshId address =>
      if s.registered freshId || address = 0 || s.lastModuleId ≥ maxModules then s
      else addModule s freshId address

def mutantRunInterleavingsClobber (s : RegistryState) : List Interleaving → RegistryState
  | [] => s
  | step :: rest => mutantRunInterleavingsClobber (mutantApplyInterleavingClobber s step) rest

/-- Mutant transition: `staticCallback` re-entrantly overwrites address (issue 6). -/
def mutantApplyInterleavingReentrant (s : RegistryState) : Interleaving → RegistryState
  | .staticCallback =>
      { s with moduleAddress := fun q => if q = 1 then 0xCAFE else s.moduleAddress q }
  | .setStatus _ _ => s
  | .updateAccounting _ _ => s
  | .updateParamsOrShares _ _ => s
  | .addFreshModule freshId address =>
      if s.registered freshId || address = 0 || s.lastModuleId ≥ maxModules then s
      else addModule s freshId address

def mutantRunInterleavingsReentrant (s : RegistryState) : List Interleaving → RegistryState
  | [] => s
  | step :: rest => mutantRunInterleavingsReentrant (mutantApplyInterleavingReentrant s step) rest

/-- **Kill-line refuting the registered parent `PDeref1.closure` on a mutant of its own
transition.** The negated statement is the parent's exact predicate shape with the
clobber mutant substituted for `runInterleavings`: the same `Reachable` / `Dereferenceable`
premises and the same `List Interleaving` binder, but the conclusion
`sourceDeref (mutantRunInterleavings s steps) id = some (s.moduleAddress id) ∧ s.moduleAddress id ≠ 0`
is falsified. Witness `s = registeredOne` (`Reachable` via `migrated`), `id = 1`
(`Dereferenceable`), `steps = [.setStatus 1 0]` — the mutant zeros address 1, so
`sourceDeref` on the mutant is `some 0 ≠ some 0xBEEF`. -/
theorem packed_config_clobber_kill_line_refutes_parent :
    ¬ ∀ (s : RegistryState) (_hs : Reachable s) (id : ModuleId)
        (_h : Dereferenceable s id) (steps : List Interleaving),
        sourceDeref (mutantRunInterleavingsClobber s steps) id =
          some (s.moduleAddress id) ∧ s.moduleAddress id ≠ 0 := by
  intro h
  have hcex := h registeredOne registeredOne_reachable 1
    (by simp [Dereferenceable, registeredOne]) [.setStatus 1 0]
  revert hcex
  decide

/-- **Second kill-line: re-entrant callback overwrite.** Same refutation shape with the
re-entrant mutant (`staticCallback` writes `0xCAFE` over id 1). -/
theorem reentrant_callback_overwrite_kill_line_refutes_parent :
    ¬ ∀ (s : RegistryState) (_hs : Reachable s) (id : ModuleId)
        (_h : Dereferenceable s id) (steps : List Interleaving),
        sourceDeref (mutantRunInterleavingsReentrant s steps) id =
          some (s.moduleAddress id) ∧ s.moduleAddress id ≠ 0 := by
  intro h
  have hcex := h registeredOne registeredOne_reachable 1
    (by simp [Dereferenceable, registeredOne]) [.staticCallback]
  revert hcex
  decide

end LidoSRv3.Tests.DereferenceMutants
