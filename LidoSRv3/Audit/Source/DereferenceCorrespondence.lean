import Verity.Core
import Verity.EVM.Uint256

namespace LidoSRv3.Audit.SolidityDereference

open Verity
open Verity.EVM.Uint256

/-!
# P-DEREF-1 pinned-source model

Source: `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.
This bounded source-shaped model covers the concrete registry writers at this
pin: `initialize` (empty router), `SRLib._migrateStorage` (the one-time old
layout import, SRLib.sol:54-155), and `SRLib._addModule` (183-232).  The
migration copies `smOld.stakingModuleAddress` into
`moduleStates[id].config.moduleAddress`; its old-layout contents and the
deployment/upgrader call are explicit source-boundary inputs, not invented
initial state.  Normal post-migration writers also include status, accounting,
and parameter/share updates; none writes that address field.  There is no
normal removal or replacement writer at this pin.

The model is not a Solidity parser, proxy/deployment proof, generated-Yul
proof, or EVM execution proof.  In particular the exact hash of
`ROUTER_STORAGE_POSITION` and compiler-emitted SLOAD are OPEN.  The executable
Verity transaction below is a model-local mapping projection, linked to this
source-shaped state by `VerityRepresents` only.
-/

abbrev ModuleId := Nat
abbrev ModuleAddress := Nat

def maxModules : Nat := 32
def uint24Modulus : Nat := 2 ^ 24
def addressModulus : Nat := 2 ^ 160

structure RegistryState where
  lastModuleId : Nat
  registered : ModuleId → Bool
  moduleAddress : ModuleId → ModuleAddress

def WellFormed (s : RegistryState) : Prop :=
  s.lastModuleId < uint24Modulus ∧
  ∀ id, s.registered id = true → s.moduleAddress id ≠ 0 ∧ s.moduleAddress id < addressModulus

def emptyRegistry : RegistryState :=
  { lastModuleId := 0, registered := fun _ => false, moduleAddress := fun _ => 0 }

/-- The one-time `_migrateStorage` output, parameterized by its old-layout
contents.  Its well-formedness is the explicit migration boundary. -/
def migrateStorage (old : RegistryState) : RegistryState := old

def addModule (s : RegistryState) (fresh address : Nat) : RegistryState :=
  { lastModuleId := fresh
    registered := fun id => if id = fresh then true else s.registered id
    moduleAddress := fun id => if id = fresh then address else s.moduleAddress id }

/-- Reachable states come from initialization, a valid one-time migration, or
successful `_addModule`; nonzero registration is therefore derived from this
reachable-state invariant rather than assumed at each dereference. -/
inductive Reachable : RegistryState → Prop where
  | initialized : Reachable emptyRegistry
  | migrated (old : RegistryState) (h : WellFormed old) : Reachable (migrateStorage old)
  | added (s : RegistryState) (hreach : Reachable s) (fresh address : Nat)
      (hfresh : s.registered fresh = false) (haddress : address ≠ 0)
      (hbound : address < addressModulus) (hlast : fresh < uint24Modulus)
      (hcap : s.lastModuleId < maxModules) :
      Reachable (addModule s fresh address)

def Dereferenceable (s : RegistryState) (id : ModuleId) : Prop :=
  s.registered id = true

/-- `_requireModuleIdExists` followed by `moduleStates[id].config.moduleAddress`. -/
def sourceDeref (s : RegistryState) (id : ModuleId) : Option ModuleAddress :=
  if s.registered id then some (s.moduleAddress id) else none

theorem reachable_wellFormed (s : RegistryState) (h : Reachable s) : WellFormed s := by
  induction h with
  | initialized =>
      constructor
      · decide
      · intro id hid
        simp [emptyRegistry] at hid
  | migrated old h => simpa [migrateStorage] using h
  | added s hs fresh address hfresh haddress hbound hlast hcap ih =>
      constructor
      · simpa [addModule] using hlast
      · intro id hid
        by_cases heq : id = fresh
        · subst id; simp [addModule, haddress, hbound]
        · have old := ih.2 id
          simpa [addModule, heq] using old (by simpa [addModule, heq] using hid)

theorem reachable_registered_nonzero (s : RegistryState) (hs : Reachable s)
    (id : ModuleId) (h : s.registered id = true) : s.moduleAddress id ≠ 0 :=
  (reachable_wellFormed s hs).2 id h |>.1

theorem reachable_registered_address_bound (s : RegistryState) (hs : Reachable s)
    (id : ModuleId) (h : s.registered id = true) : s.moduleAddress id < addressModulus :=
  (reachable_wellFormed s hs).2 id h |>.2

theorem source_deref_exact_reachable (s : RegistryState) (hs : Reachable s) (id : ModuleId)
    (h : Dereferenceable s id) :
    sourceDeref s id = some (s.moduleAddress id) ∧ s.moduleAddress id ≠ 0 := by
  change s.registered id = true at h
  exact ⟨by simp [sourceDeref, h], reachable_registered_nonzero s hs id h⟩

/-- Complete normal post-migration writer inventory relevant to this field.
The first three constructors do not write `config.moduleAddress`; `addFreshModule`
is `_addModule`.  Migration is intentionally excluded because it is one-time
and precedes this interleaving phase. -/
inductive Interleaving where
  | staticCallback
  | setStatus (id status : Nat)
  | updateAccounting (id balance : Nat)
  | updateParamsOrShares (id value : Nat)
  | addFreshModule (freshId : ModuleId) (address : ModuleAddress)

def applyInterleaving (s : RegistryState) : Interleaving → RegistryState
  | .staticCallback | .setStatus _ _ | .updateAccounting _ _ | .updateParamsOrShares _ _ => s
  | .addFreshModule freshId address =>
      if s.registered freshId || address = 0 || s.lastModuleId ≥ maxModules then s
      else addModule s freshId address

def runInterleavings (s : RegistryState) : List Interleaving → RegistryState
  | [] => s
  | step :: rest => runInterleavings (applyInterleaving s step) rest

theorem existing_binding_preserved (s : RegistryState) (id : ModuleId)
    (h : s.registered id = true) (step : Interleaving) :
    (applyInterleaving s step).registered id = true ∧
      (applyInterleaving s step).moduleAddress id = s.moduleAddress id := by
  cases step with
  | staticCallback | setStatus | updateAccounting | updateParamsOrShares => simp [applyInterleaving, h]
  | addFreshModule fresh address =>
      simp only [applyInterleaving]
      split
      · simp [h]
      · rename_i allowed
        have hfresh : id ≠ fresh := by
          intro heq; subst fresh; simp [h] at allowed
        simp [addModule, hfresh, h]

theorem deref_stable_under_all_interleavings (s : RegistryState) (id : ModuleId)
    (h : Dereferenceable s id) (steps : List Interleaving) :
    sourceDeref (runInterleavings s steps) id = sourceDeref s id := by
  induction steps generalizing s with
  | nil => rfl
  | cons step rest ih =>
      simp only [runInterleavings]
      change s.registered id = true at h
      have hp := existing_binding_preserved s id h step
      rw [ih (s := applyInterleaving s step) hp.1]
      simp [sourceDeref, hp.1, h, hp.2]

theorem module_id_roundtrip (id : ModuleId) (h : id ≤ maxModules) :
    id % uint24Modulus = id := by
  apply Nat.mod_eq_of_lt
  exact Nat.lt_of_le_of_lt h (by decide : maxModules < uint24Modulus)

/-! ## Executable VERITY_TX projection -/

def moduleStatesSlot : Nat := 0
def moduleIdPositionsSlot : Nat := 2
def observedAddressesSlot : Nat := 6

/-- `SRLib.getStakingModuleAddress` after `_requireModuleIdExists`. -/
def getStakingModuleAddress (id : Uint256) : Contract Address := fun state =>
  if state.storageMapUint moduleIdPositionsSlot id = 0 then
    .revert "StakingModuleUnregistered" state
  else
    .success (wordToAddress (state.storageMapUint moduleStatesSlot id)) state

abbrev observeDeref := getStakingModuleAddress

/-- Model-local storage relation.  It deliberately does not claim Solidity's
keccak mapping encoding, ROUTER_STORAGE_POSITION, or emitted SLOAD semantics. -/
def VerityRepresents (s : RegistryState) (state : ContractState) (id : ModuleId) : Prop :=
  (state.storageMapUint moduleIdPositionsSlot (id : Uint256) ≠ 0 ↔
      s.registered id = true) ∧
  wordToAddress (state.storageMapUint moduleStatesSlot (id : Uint256)) =
    Verity.Core.Address.ofNat (s.moduleAddress id)

theorem address_word_roundtrip (address : Nat) (h : address < addressModulus) :
    wordToAddress (address : Uint256) = Verity.Core.Address.ofNat address := by
  apply Verity.Core.Address.ext
  have h256 : address < Verity.Core.Uint256.modulus :=
    Nat.lt_trans h (by decide : addressModulus < Verity.Core.Uint256.modulus)
  change (address % Verity.Core.Uint256.modulus) % Verity.Core.Address.modulus =
    address % Verity.Core.Address.modulus
  rw [Nat.mod_eq_of_lt h256]

theorem verity_observe_refines_source (s : RegistryState) (hs : Reachable s)
    (state : ContractState) (id : ModuleId) (hrep : VerityRepresents s state id)
    (hmember : Dereferenceable s id) :
    observeDeref (id : Uint256) state =
      .success (Verity.Core.Address.ofNat (s.moduleAddress id)) state ∧
    sourceDeref s id = some (s.moduleAddress id) := by
  rcases hrep with ⟨hpos, haddr⟩
  change s.registered id = true at hmember
  have hposition := hpos.mpr hmember
  refine ⟨?_, (source_deref_exact_reachable s hs id hmember).1⟩
  simp only [observeDeref, getStakingModuleAddress]
  rw [if_neg hposition, haddr]

end LidoSRv3.Audit.SolidityDereference
