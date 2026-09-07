import LidoSRv3.Audit.Source.TrioComposition.ParentABI

namespace LidoSRv3.Tests.TrioIntegration.ParentFixtures
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition

def layout : Layout :=
  { routerSlot := word 0, keccak := fun bytes => if bytes.length = 32 then word 100 else word 200 }

def storage (count status : Nat) : Storage := fun slot =>
  if slot.val = 1 then word count
  else if slot.val = 100 then word 7
  else if slot.val = 200 then word (11 + 10000 * 2^192 + status * 2^224 + 2^232)
  else word 0

def config (unit : Nat) : Config := ⟨word unit, word 2048⟩
def summary (deposited : Nat) : StaticOracle := fun _ _ =>
  .returned (encodeWord (word 0) ++ encodeWord (word deposited) ++ encodeWord (word 5))
def rejects : StaticOracle := fun _ _ => .reverted [byte 0xab]

end LidoSRv3.Tests.TrioIntegration.ParentFixtures
