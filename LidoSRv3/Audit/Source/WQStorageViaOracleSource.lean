import LidoSRv3.Audit.Source.WithdrawalQueueMappingSource
import LidoSRv3.Audit.Source.MappingSlotViaOracleSource

/-! # WithdrawalQueue request/checkpoint storage via shared KeccakOracle

**General rule (Thomas 2026-09-13, chain
`WithdrawalQueueMappingSource.WithdrawalQueueStorage`'s two
MappingStorage fields through the shared oracle-backed
realMappingStorage.)**

`WithdrawalQueueMappingSource.WithdrawalQueueStorage` holds two
free `MappingStorage` fields (`requestMapping` at the queue's
storage-position constant, `checkpointMapping` at another). This
composition specialises both to `realMappingStorage` instances
backed by the shared A-KECCAK-COMMITMENT oracle.

**Status:** first real derivation of the WithdrawalQueue storage past
its two free MappingStorage fields — both are now functions of
`(oracle, queueBaseSlot, checkpointBaseSlot)`. -/

namespace LidoSRv3.Audit.Source.WQStorageViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.WithdrawalQueueMappingSource

/-- Real WithdrawalQueue storage: two MappingStorages backed by the
shared oracle at pinned base slots, plus the running
unfinalizedStETH accumulator. -/
def realWQStorage
    (oracle : KeccakOracle)
    (queueBaseSlot checkpointBaseSlot : Nat)
    (unfinalizedStETH : Nat) : WithdrawalQueueStorage :=
  { requestMapping := realMappingStorage oracle queueBaseSlot,
    checkpointMapping := realMappingStorage oracle checkpointBaseSlot,
    unfinalizedStETH := unfinalizedStETH }

/-- The real WQ storage's `readRequest` traces through the pinned
Solidity mapping-slot rule. -/
theorem realWQStorage_readRequest_eq
    (oracle : KeccakOracle)
    (queueBaseSlot checkpointBaseSlot unfinalizedStETH requestId : Nat) :
    readRequest (realWQStorage oracle queueBaseSlot checkpointBaseSlot
                    unfinalizedStETH) requestId =
      (realMappingStorage oracle queueBaseSlot).slotAt requestId :=
  rfl

/-- The real WQ storage's `readCheckpoint` traces through the pinned
Solidity mapping-slot rule. -/
theorem realWQStorage_readCheckpoint_eq
    (oracle : KeccakOracle)
    (queueBaseSlot checkpointBaseSlot unfinalizedStETH hint : Nat) :
    readCheckpoint (realWQStorage oracle queueBaseSlot checkpointBaseSlot
                       unfinalizedStETH) hint =
      (realMappingStorage oracle checkpointBaseSlot).slotAt hint :=
  rfl

/-- The real WQ storage's `unfinalizedStETHFromStorage` equals the
passed-in accumulator, definitionally. -/
theorem realWQStorage_unfinalized_eq
    (oracle : KeccakOracle)
    (queueBaseSlot checkpointBaseSlot unfinalizedStETH : Nat) :
    unfinalizedStETHFromStorage
      (realWQStorage oracle queueBaseSlot checkpointBaseSlot unfinalizedStETH) =
      unfinalizedStETH :=
  rfl

end LidoSRv3.Audit.Source.WQStorageViaOracleSource
