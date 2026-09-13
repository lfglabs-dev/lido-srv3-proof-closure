import LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-! # WithdrawalQueue request/checkpoint mapping source model
(P-RESERVE-1 unfinalizedStETH + P-ADDRESS-1 claim mapping)

**General rule (Thomas 2026-09-13, shared WithdrawalQueue mapping
decoder for P-RESERVE-1 unfinalizedStETH and P-ADDRESS-1
request/checkpoint reads.)**

Names the pinned WithdrawalQueue keyed-storage layout as an
audit-source model. Under this model, the WithdrawalQueue mapping
reads (`_getQueue()[requestId]`, `_getCheckpoints()[hint]`,
`unfinalizedStETH()`) become DEFINED functions of a source-level
`WithdrawalQueueStorage`.

Pinned Solidity (17005714):

- `contracts/0.8.9/WithdrawalQueueBase.sol` `_getQueue()` returns
  the request mapping at keccak-derived slot;
  `_getCheckpoints()` returns the checkpoint mapping.
- `contracts/0.8.9/WithdrawalQueue.sol:unfinalizedStETH()` returns
  the running sum of unfinalized request stETH amounts.

The model deliberately does not model the packed request/checkpoint
struct decoding — this scaffold provides the mapping-storage entry
points; downstream consumers add per-field bit-decoders as needed.

**Status:** shared source model. `WithdrawalQueueStorage` combines
per-request and per-checkpoint MappingStorages plus the
unfinalizedStETH accumulator, all named. -/

namespace LidoSRv3.Audit.Source.WithdrawalQueueMappingSource

/-- WithdrawalQueue storage shape: per-request mapping,
per-checkpoint mapping, and running unfinalizedStETH accumulator. -/
structure WithdrawalQueueStorage : Type where
  requestMapping : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage
  checkpointMapping : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage
  unfinalizedStETH : Nat

/-- Read the request-storage word at a specific request ID. -/
def readRequest (wqs : WithdrawalQueueStorage) (requestId : Nat) : Nat :=
  LidoSRv3.Audit.Source.KeccakMappingStorageSource.read wqs.requestMapping requestId

/-- Read the checkpoint-storage word at a specific hint index. -/
def readCheckpoint (wqs : WithdrawalQueueStorage) (hint : Nat) : Nat :=
  LidoSRv3.Audit.Source.KeccakMappingStorageSource.read wqs.checkpointMapping hint

/-- The unfinalizedStETH accumulator (used by P-RESERVE-1
freshQueueCache). -/
def unfinalizedStETHFromStorage (wqs : WithdrawalQueueStorage) : Nat :=
  wqs.unfinalizedStETH

/-- The unfinalizedStETH source function returns the storage's
accumulator, definitionally. -/
theorem unfinalizedStETHFromStorage_eq (wqs : WithdrawalQueueStorage) :
    unfinalizedStETHFromStorage wqs = wqs.unfinalizedStETH := rfl

end LidoSRv3.Audit.Source.WithdrawalQueueMappingSource
