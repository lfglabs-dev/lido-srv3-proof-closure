import LidoSRv3.Audit.Verity.AddressClaimBatchTx
import Compiler.Proofs.MappingSlot
import Compiler.Constants

/-!
# Physical keccak slots for the live claim-batch channels

The live `executeClaimWithdrawalsTo` path reads and writes the Solidity
mapping slots directly.  The physical words are

`keccak256(abi.encode(key, POSITION))` and the next word,

not the unstructured-storage constants plus a raw channel offset, and not a
second mapping whose base is `POSITION + 1`.
-/

namespace LidoSRv3.Audit.Spec.AddressClaimKeccakSlots

open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open _root_.Verity
open Compiler.Proofs

/-- Hyp-free naming of the keccak derivation. Metadata is the next word
after `keccak256(abi.encode(requestId, queuePosition))`, and the
`queuePosition + 1` channel is a different mapping base. -/
theorem physical_queue_slots_are_keccak_derivation (requestId : Nat) :
    queueAmountsPhysicalSlot requestId = solidityMappingSlot queuePosition requestId ∧
      queueMetadataPhysicalSlot requestId =
        (solidityMappingSlot queuePosition requestId + 1) %
          Compiler.Constants.evmModulus ∧
      solidityMappingSlot (queuePosition + 1) requestId ≠
        solidityMappingSlot queuePosition requestId :=
  ⟨mappingSlotLocation_zero queuePosition requestId, rfl,
    solidityMappingSlot_ne (Or.inl (Nat.succ_ne_self queuePosition))⟩

theorem physical_checkpoint_slots_are_keccak_derivation (hint : Nat) :
    checkpointFromPhysicalSlot hint = solidityMappingSlot checkpointsPosition hint ∧
      checkpointRatePhysicalSlot hint =
        (solidityMappingSlot checkpointsPosition hint + 1) %
          Compiler.Constants.evmModulus ∧
      solidityMappingSlot (checkpointsPosition + 1) hint ≠
        solidityMappingSlot checkpointsPosition hint :=
  ⟨mappingSlotLocation_zero checkpointsPosition hint, rfl,
    solidityMappingSlot_ne (Or.inl (Nat.succ_ne_self checkpointsPosition))⟩

/-- The `EnumerableSet.UintSet._indexes` mapping is the struct member after
`_values`: its base is the owner's outer-map value plus one *before* the
request-id keccak.  This is deliberately a slot-identity statement, not a
keccak injectivity assumption. -/
theorem owner_request_index_slot_is_keccak_derivation (owner : Address) (requestId : Nat) :
    ownerRequestIndexSlot owner requestId =
      solidityMappingSlot (solidityMappingSlot requestsByOwnerPosition owner.toNat + 1)
        requestId := by
  simp [ownerRequestIndexSlot, ownerRequestSetBase]

/-- The executable storage lenses themselves are the physical keccak slots.
This is an invariant of every state, rather than a correspondence hypothesis
that a caller must supply. -/
def PhysicalClaimSlots (state : ContractState) : Prop :=
  ∀ key : Nat,
    requestAmountsWord state key =
        state.readSlot (queueAmountsPhysicalSlot key) ∧
      requestMetadataWord state key =
        state.readSlot (queueMetadataPhysicalSlot key) ∧
      checkpointFromWord state key =
        state.readSlot (checkpointFromPhysicalSlot key) ∧
      checkpointRateWord state key =
        state.readSlot (checkpointRatePhysicalSlot key)

/-- Every state satisfies the physical-slot invariant by definition of the
live executable lenses. -/
theorem physical_claim_slots (state : ContractState) : PhysicalClaimSlots state := by
  intro key
  exact ⟨rfl, rfl, rfl, rfl⟩

/-- ∀ request id / hint / recipient on the live path: the keyed channels
are the keccak mapping slots and the next word. -/
theorem live_claim_channels_are_physical_keccak_slots
    (state : ContractState) (requestId hint : Nat) (_recipient : Address)
    (_h : PhysicalClaimSlots state) :
    requestAmountsWord state requestId =
        state.readSlot (queueAmountsPhysicalSlot requestId) ∧
      requestMetadataWord state requestId =
        state.readSlot (queueMetadataPhysicalSlot requestId) ∧
      checkpointFromWord state hint =
        state.readSlot (checkpointFromPhysicalSlot hint) ∧
      checkpointRateWord state hint =
        state.readSlot (checkpointRatePhysicalSlot hint) :=
  ⟨rfl, rfl, rfl, rfl⟩

/-- Mutant: treat the request id as a raw storage key, skipping keccak. -/
def requestAmountsWordRawKey (state : ContractState) (requestId : Nat) : Uint256 :=
  state.readSlot requestId

/-- Mutant: alias the metadata channel to a different map. -/
def requestMetadataWordAliasedMap (state : ContractState) (requestId : Nat) :
    Uint256 :=
  state.readMapUint (checkpointsPosition + 1) (.ofNat requestId)

end LidoSRv3.Audit.Spec.AddressClaimKeccakSlots
