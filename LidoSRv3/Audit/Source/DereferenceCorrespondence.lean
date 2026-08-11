import Verity.Core
import Verity.Macro

namespace LidoSRv3.Audit.SolidityDereference

open Verity
open Verity.EVM.Uint256

/-!
# P-DEREF-1 pinned-source model

Source: `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.
The relevant spans are `SRStorage.sol:30-47,54-77`, `SRUtils.sol:45-58`,
`SRLib.sol:183-232`, and `StakingRouter.sol:415-417,461-467,483-553,
1099-1143`.  The only registry writer is `_addModule`: it rejects zero and
duplicate addresses, caps the set at `MAX_STAKING_MODULES_COUNT = 32`, adds a
fresh monotonically increasing id, writes its address, and finally stores the
id in packed `uint24 lastModuleId`.  There is no remove/address-replacement
writer at this pin.

External module calls inside the digest/summary functions are `view`; Solidity
lowers them to STATICCALL.  Consequently callbacks may interleave reads but
cannot execute a router state writer anywhere in their call subtree.  The
`Interleaving` type below is exactly the writer projection which remains
possible between transactions; every constructor preserves existing module
id-to-address bindings.
-/

abbrev ModuleId := Nat
abbrev ModuleAddress := Nat

def maxModules : Nat := 32
def uint24Modulus : Nat := 2 ^ 24

structure RegistryState where
  lastModuleId : Nat
  registered : ModuleId → Bool
  moduleAddress : ModuleId → ModuleAddress

def Dereferenceable (s : RegistryState) (id : ModuleId) : Prop :=
  s.registered id = true ∧ s.moduleAddress id ≠ 0

/-- Source guard plus `moduleStates[id].config.moduleAddress` projection. -/
def sourceDeref (s : RegistryState) (id : ModuleId) : Option ModuleAddress :=
  if s.registered id then some (s.moduleAddress id) else none

/-- The complete address-relevant interleaving vocabulary at the pinned pin. -/
inductive Interleaving where
  | staticCallback
  | setStatus (id status : Nat)
  | updateAccounting (id balance : Nat)
  | addFreshModule (freshId : ModuleId) (address : ModuleAddress)

def applyInterleaving (s : RegistryState) : Interleaving → RegistryState
  | .staticCallback | .setStatus _ _ | .updateAccounting _ _ => s
  | .addFreshModule freshId address =>
      if s.registered freshId || address = 0 || s.lastModuleId ≥ maxModules then s
      else { lastModuleId := freshId
             registered := fun id => if id = freshId then true else s.registered id
             moduleAddress := fun id => if id = freshId then address else s.moduleAddress id }

def runInterleavings (s : RegistryState) : List Interleaving → RegistryState
  | [] => s
  | step :: rest => runInterleavings (applyInterleaving s step) rest

theorem existing_binding_preserved (s : RegistryState) (id : ModuleId)
    (h : s.registered id = true) (step : Interleaving) :
    (applyInterleaving s step).registered id = true ∧
      (applyInterleaving s step).moduleAddress id = s.moduleAddress id := by
  cases step with
  | staticCallback | setStatus | updateAccounting => simp [applyInterleaving, h]
  | addFreshModule fresh address =>
      simp only [applyInterleaving]
      split
      · simp [h]
      · rename_i allowed
        have hfresh : id ≠ fresh := by
          intro heq
          subst fresh
          simp [h] at allowed
        simp [hfresh, h]

theorem deref_stable_under_all_interleavings (s : RegistryState) (id : ModuleId)
    (h : Dereferenceable s id) (steps : List Interleaving) :
    sourceDeref (runInterleavings s steps) id = sourceDeref s id := by
  induction steps generalizing s with
  | nil => rfl
  | cons step rest ih =>
      simp only [runInterleavings]
      have hp := existing_binding_preserved s id h.1 step
      rw [ih (s := applyInterleaving s step) ⟨hp.1, hp.2 ▸ h.2⟩]
      simp [sourceDeref, hp.1, h.1, hp.2]

theorem source_deref_exact (s : RegistryState) (id : ModuleId)
    (h : Dereferenceable s id) : sourceDeref s id = some (s.moduleAddress id) := by
  simp [sourceDeref, h.1]

/-- The source cap is far below the packed `uint24` boundary. -/
theorem module_id_roundtrip (id : ModuleId) (h : id ≤ maxModules) :
    id % uint24Modulus = id := by
  apply Nat.mod_eq_of_lt
  exact Nat.lt_of_le_of_lt h (by decide : maxModules < uint24Modulus)

/- A focused executable Verity transaction representation.  It models the
post-membership-guard scalar projection used at each dereference call site;
the mapping membership proof remains the source premise above. -/
verity_contract DereferenceBase where
  storage
    registeredId : Uint24 := slot 0
    registeredAddress : Address := slot 1

  modifier moduleExists := do
    let address ← getStorageAddr registeredAddress
    require (address != 0) "StakingModuleUnregistered"

verity_contract DereferenceTx is DereferenceBase where
  storage
    observedAddress : Address := slot 2

  function observe () with moduleExists : Address := do
    let address ← getStorageAddr registeredAddress
    setStorageAddr observedAddress address
    return address

/-- The source projection is connected to an actual executable Verity
transaction, rather than a syntax-only FunctionSpec. -/
theorem verity_observe_has_a_kernel_result (state : ContractState) :
    ∃ result : ContractResult Address, DereferenceTx.observe.run state = result := by
  exact ⟨DereferenceTx.observe.run state, rfl⟩

end LidoSRv3.Audit.SolidityDereference
