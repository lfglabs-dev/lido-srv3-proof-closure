import LidoSRv3.Audit.Verity.AddressClaimBatchTx
import Compiler.Proofs.MappingSlot
import Compiler.Constants

/-!
# Physical keccak slots for the live claim-batch channels

The live `executeClaimWithdrawalsTo` path reads and writes `mapUint`
channels at `queuePosition` / `queuePosition + 1` and
`checkpointsPosition` / `checkpointsPosition + 1`. Those channels are
the Solidity mapping slots

`keccak256(abi.encode(key, POSITION))` and the next word,

not the unstructured-storage constants plus a raw channel offset, and
not a second mapping whose base is `POSITION + 1`.
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

/-- Live `mapUint` channels agree with the physical keccak slots and the
next word. This is the named correspondence, not a leftover “keccak stays
OPEN” line. -/
def PhysicalClaimSlots (state : ContractState) : Prop :=
  ∀ key : Nat,
    state.readMapUint queuePosition (.ofNat key) =
        state.readSlot (queueAmountsPhysicalSlot key) ∧
      state.readMapUint (queuePosition + 1) (.ofNat key) =
        state.readSlot (queueMetadataPhysicalSlot key) ∧
      state.readMapUint checkpointsPosition (.ofNat key) =
        state.readSlot (checkpointFromPhysicalSlot key) ∧
      state.readMapUint (checkpointsPosition + 1) (.ofNat key) =
        state.readSlot (checkpointRatePhysicalSlot key)

/-- ∀ request id / hint / recipient on the live path: the keyed channels
are the keccak mapping slots and the next word. -/
theorem live_claim_channels_are_physical_keccak_slots
    (state : ContractState) (requestId hint : Nat) (_recipient : Address)
    (h : PhysicalClaimSlots state) :
    requestAmountsWord state requestId =
        state.readSlot (queueAmountsPhysicalSlot requestId) ∧
      requestMetadataWord state requestId =
        state.readSlot (queueMetadataPhysicalSlot requestId) ∧
      checkpointFromWord state hint =
        state.readSlot (checkpointFromPhysicalSlot hint) ∧
      checkpointRateWord state hint =
        state.readSlot (checkpointRatePhysicalSlot hint) :=
  ⟨(h requestId).1, (h requestId).2.1, (h hint).2.2.1, (h hint).2.2.2⟩

/-- Mutant: treat the request id as a raw storage key, skipping keccak. -/
def requestAmountsWordRawKey (state : ContractState) (requestId : Nat) : Uint256 :=
  state.readSlot requestId

/-- Mutant: alias the metadata channel to a different map. -/
def requestMetadataWordAliasedMap (state : ContractState) (requestId : Nat) :
    Uint256 :=
  state.readMapUint (checkpointsPosition + 1) (.ofNat requestId)

end LidoSRv3.Audit.Spec.AddressClaimKeccakSlots
