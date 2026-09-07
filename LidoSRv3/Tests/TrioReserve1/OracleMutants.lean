import LidoSRv3.Audit.Source.TrioReserve1.Consensus

namespace LidoSRv3.Tests.TrioReserve1.OracleMutants
open LidoSRv3.Audit.Source.TrioReserve1
open Live

/-- Executed negative control: one source expression is incorrectly widened
from uint64 to uint256. All other checked operations retain the source order.
This is test code, never imported by production/source modules. -/
def wideFrameSpan (c : Consensus.Config) (time packed : Nat) : Except Bytes (Nat × Nat) := do
  let initial := packed % 2^64
  let epochs := packed / 2^64 % 2^64
  let elapsed ← Consensus.sub time c.genesis
  let slot ← Consensus.divide elapsed c.secondsPerSlot
  let epoch ← Consensus.divide slot c.slotsPerEpoch
  if epoch < initial then throw Consensus.initialEpochNotArrived
  let difference ← Consensus.sub epoch initial
  let index ← Consensus.divide difference epochs
  let offset ← Consensus.mul index epochs
  let startEpoch ← Consensus.add initial offset
  let startSlot ← Consensus.mul startEpoch c.slotsPerEpoch
  let frameSlots ← Consensus.mul epochs c.slotsPerEpoch
  let nextSlot ← Consensus.add startSlot frameSlots
  let reference ← Consensus.sub startSlot 1
  let deadline ← Consensus.sub nextSlot 1
  pure (reference % 2^64, deadline % 2^64)

def dispatch (consensus : Address) (c : Consensus.Config) (other : StaticCall.External) :
    StaticCall.External := fun req w =>
  if req.target = consensus ∧ req.payload = encode 4 0x72f79b13 then
    match wideFrameSpan c w.core.blockTimestamp.val
        (w.core.readContractSlot consensus.val c.frameSlot).val with
    | .error data => .rejected data
    | .ok (reference, deadline) => .success (encode 32 reference ++ encode 32 deadline)
  else other req w

end LidoSRv3.Tests.TrioReserve1.OracleMutants
