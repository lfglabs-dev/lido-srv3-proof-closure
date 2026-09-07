import LidoSRv3.Audit.Source.TrioComposition.VerityParent
import LidoSRv3.Tests.TrioIntegration.ParentFixtures
import LidoSRv3.Tests.TrioIntegration.VMFixtures

/-! Actual call-VM checks of interleaved producer guards inside the parent.
The supplied pointers are source-model inputs, not physical VM memory. -/
namespace LidoSRv3.Tests.TrioIntegration.MemoryParentVM
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition

private def check (name : String) (pointer count : Nat) (oracle : StaticOracle)
    (failure : Option Failure) (calls : Nat) : IO Unit := do
  let world := VMFixtures.vmWorld (ParentFixtures.storage count 0)
  let actual := TrioComposition.VerityParent.executeWithMemory (word pointer)
    ParentFixtures.layout (ParentFixtures.config 32) (word 0) false
    (VMFixtures.vmAdversary oracle) { world, gasRemaining := 2^256-1 } []
  let equal := match actual.1.1,failure with
    | .ok result,none => decide (result.totalAllocated = word 0 ∧
        result.allocated = List.replicate count (word 0) ∧
        result.newAllocations = List.replicate count (word 32))
    | .error got,some wanted => decide (got = wanted)
    | _,_ => false
  unless equal && actual.1.2.length == calls &&
      actual.2.world.selfBalance.val == world.selfBalance.val do
    throw (IO.userError s!"VM interleaved parent memory mismatch: {name}")
  IO.println s!"VERITY_MEMORY_PARENT_PASS {name} calls={calls}"

def runVectors : IO Unit := do
  check "one-row" 128 1 (ParentFixtures.summary 1) none 1
  check "scratch-before-call" (2^64-512) 1 ParentFixtures.rejects
    (some (.panic (word 0x41))) 0
  check "capacity-after-call" (2^64-896) 1 (ParentFixtures.summary 1)
    (some (.panic (word 0x41))) 1
  check "first-pass-before-capacity" (2^64-896) 1
    (fun _ _ => .returned (encodeWord (word 2) ++ encodeWord (word 1) ++ encodeWord (word 0)))
    (some (.panic (word 0x11))) 1
  check "capacity-before-second-pass" (2^64-896) 1 (ParentFixtures.summary (2^256-1))
    (some (.panic (word 0x41))) 1
  check "second-pass-overflow" 128 1 (ParentFixtures.summary (2^256-1))
    (some (.panic (word 0x11))) 1
  check "prefix-before-call" 128 (2^64) ParentFixtures.rejects
    (some (.panic (word 0x41))) 0
  check "two-rows" 128 2 (ParentFixtures.summary 1) none 2

end LidoSRv3.Tests.TrioIntegration.MemoryParentVM

def main : IO Unit := LidoSRv3.Tests.TrioIntegration.MemoryParentVM.runVectors
