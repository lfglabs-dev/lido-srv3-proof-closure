import LidoSRv3.Tests.TrioIntegration.ParentFixtures

namespace LidoSRv3.Tests.TrioIntegration.Parent
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition

open ParentFixtures

private def check (count status unit amount : Nat) (oracle : StaticOracle)
    (expected : Except Failure ParentOutput) (calls : Nat) : IO Unit := do
  let (result, trace) := getDepositAllocations layout (storage count status) oracle
    (config unit) (word amount) false []
  let equal := match result, expected with
    | .ok actual, .ok wanted => decide (actual = wanted)
    | .error actual, .error wanted => decide (actual = wanted)
    | _, _ => false
  unless equal && trace.length == calls do
    throw (IO.userError s!"parent mismatch: {repr result}, {trace.length} calls")
  let (abiResult, abiTrace) := getDepositAllocationsABI layout (storage count status) oracle
    (config unit) (word amount) false []
  let abiEqual := match abiResult, expected with
    | .ok actual, .ok wanted => decide (actual = wanted)
    | .error actual, .error wanted => decide (actual = wanted)
    | _, _ => false
  unless abiEqual && decide (abiTrace = trace) do
    throw (IO.userError s!"ABI parent mismatch: {repr abiResult}, {abiTrace.length} calls")

-- Empty enumeration takes precedence over unit division and arbitrary rejection.
#eval check 0 0 0 10 rejects (.ok ⟨word 0, [], []⟩) 0
-- Nonempty enumeration divides before the first module call, including amount 0.
#eval check 1 0 0 0 rejects (.error (.panic (word 0x12))) 0
-- Successful positive demand and round-down leave the sub-unit remainder unused.
#eval check 1 0 32 65 (summary 1) (.ok ⟨word 64, [word 64], [word 96]⟩) 1
-- Zero demand still observes the producer, then returns the current Ether total.
#eval check 1 0 32 31 (summary 1) (.ok ⟨word 0, [word 0], [word 32]⟩) 1
#eval check 1 0 32 0 rejects (.error (.revertData [byte 0xab])) 1
-- A paused module can produce a valid word that overflows only at conversion.
#eval check 1 1 32 0 (summary (2^256 - 1)) (.error (.panic (word 0x11))) 1

private def checkConversion (actual expected : Except Failure (List Word × List Word)) : IO Unit := do
  let equal := match actual, expected with
    | .ok a, .ok b => decide (a = b)
    | .error a, .error b => decide (a = b)
    | _, _ => false
  unless equal do throw (IO.userError s!"conversion mismatch: {repr actual}")

#eval checkConversion (convertPositive (word 32) 1 [word 5] [word 4])
  (.error (.panic (word 0x11)))
-- Failure after an earlier row has converted returns no partial output arrays.
#eval checkConversion (convertPositive (word 32) 2 [word 1, word 0] [word 2, word (2^256 - 1)])
  (.error (.panic (word 0x11)))
#eval checkConversion (convertPositive (word 32) 1 [word 0] [])
  (.error (.panic (word 0x32)))
/-- A changed result or trace cannot satisfy the exact SOURCE parent relation.
This is a consequence of public_iff, not an independent equality oracle. -/
theorem changed_observation_rejected
    (layout : Layout) (storage : Storage) (oracle : StaticOracle)
    (cfg : Config) (amount : Word) (topup : Bool) (before : Transcript)
    (result : Except Failure ParentOutput) (after : Transcript)
    (different : getDepositAllocations layout storage oracle cfg amount topup before ≠ (result, after)) :
    ¬ ParentSpec.Public layout storage oracle cfg amount topup before result after := by
  intro specified
  exact different ((ParentSpec.public_iff layout storage oracle cfg amount topup before after result).mp specified)

private def divisionBeforeEmpty (count status unit amount : Nat) (oracle : StaticOracle) : Execution ParentOutput := do
  let _ ← liftChecked (checkedDiv (word amount) (word unit))
  getDepositAllocations layout (storage count status) oracle (config unit) (word amount) false

private def skipZeroDemand (count status unit amount : Nat) (oracle : StaticOracle) : Execution ParentOutput :=
  if amount = 0 then pure ⟨word 0, [], []⟩
  else getDepositAllocations layout (storage count status) oracle (config unit) (word amount) false

private def wrongUnits (count status unit amount : Nat) (oracle : StaticOracle) : Execution ParentOutput := do
  let out ← getDepositAllocations layout (storage count status) oracle (config unit) (word amount) false
  pure { out with totalAllocated := word (out.totalAllocated.val / unit) }

private def eraseFailureCalls (count status unit amount : Nat) (oracle : StaticOracle) : Execution ParentOutput :=
  fun before =>
    let (result, after) := getDepositAllocations layout (storage count status) oracle (config unit) (word amount) false before
    match result with
    | .error error => (.error error, before)
    | .ok out => (.ok out, after)

/-- Each evaluated discrepancy is rejected by changed_observation_rejected. These
are SOURCE parent mutants; canonical registered-parent and VM mutants remain open. -/
private def killMutant (count status unit amount : Nat) (oracle : StaticOracle)
    (mutant : Execution ParentOutput) : IO Unit := do
  let actual := getDepositAllocations layout (storage count status) oracle (config unit) (word amount) false []
  let altered := mutant []
  let sameResult := match actual.1, altered.1 with
    | .ok a, .ok b => decide (a = b)
    | .error a, .error b => decide (a = b)
    | _, _ => false
  if sameResult && decide (actual.2 = altered.2) then
    throw (IO.userError "SOURCE parent mutant survived")

#eval killMutant 0 0 0 1 rejects (divisionBeforeEmpty 0 0 0 1 rejects)
#eval killMutant 1 0 32 0 rejects (skipZeroDemand 1 0 32 0 rejects)
#eval killMutant 1 0 32 65 (summary 1) (wrongUnits 1 0 32 65 (summary 1))
#eval killMutant 1 0 32 0 rejects (eraseFailureCalls 1 0 32 0 rejects)

#print axioms changed_observation_rejected
end LidoSRv3.Tests.TrioIntegration.Parent
