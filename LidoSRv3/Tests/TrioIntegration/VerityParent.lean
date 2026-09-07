import LidoSRv3.Audit.Source.TrioComposition.VerityParent
import LidoSRv3.Tests.TrioIntegration.ParentFixtures
import LidoSRv3.Tests.TrioIntegration.VMFixtures

namespace LidoSRv3.Tests.TrioIntegration.VerityParent
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition ParentFixtures

private def check (name : String) (count status unit amount : Nat) (oracle : StaticOracle) : IO Unit := do
  let world := VMFixtures.vmWorld (storage count status)
  let actual := TrioComposition.VerityParent.execute ParentFixtures.layout (config unit) (word amount) false
    (VMFixtures.vmAdversary oracle)
    { world, gasRemaining := 2^256-1 } []
  let expected := getDepositAllocationsABI ParentFixtures.layout (storage count status) oracle
    (config unit) (word amount) false []
  let sameResult := match actual.1.1, expected.1 with
    | .ok a, .ok b => decide (a = b)
    | .error a, .error b => decide (a = b)
    | _, _ => false
  unless sameResult && decide (actual.1.2 = expected.2) do
    throw (IO.userError s!"VM parent result or transcript mismatch: {name}")
  unless actual.2.world.selfBalance.val == world.selfBalance.val do
    throw (IO.userError s!"VM parent accepted adversarial STATICCALL write: {name}")
  IO.println s!"VERITY_PARENT_VECTOR_PASS {name} calls={actual.1.2.length} result={repr actual.1.1}"

def runVectors : IO Unit := do
  check "empty-before-division" 0 0 0 10 rejects
  check "division-before-calls" 1 0 0 0 rejects
  check "positive-rounded-demand" 1 0 32 65 (summary 1)
  check "zero-demand-still-calls" 1 0 32 31 (summary 1)
  check "module-rejection" 1 0 32 0 rejects
  check "late-conversion-overflow" 1 1 32 0 (summary (2^256-1))

end LidoSRv3.Tests.TrioIntegration.VerityParent

def main : IO Unit := LidoSRv3.Tests.TrioIntegration.VerityParent.runVectors
