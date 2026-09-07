import LidoSRv3.Audit.Source.TrioComposition.Parent

namespace LidoSRv3.Tests.TrioIntegration.Parent
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition

private def layout : Layout :=
  { routerSlot := word 0, keccak := fun bytes => if bytes.length = 32 then word 100 else word 200 }

private def storage (count status : Nat) : Storage := fun slot =>
  if slot.val = 1 then word count
  else if slot.val = 100 then word 7
  else if slot.val = 200 then word (11 + 10000 * 2^192 + status * 2^224 + 2^232)
  else word 0

private def config (unit : Nat) : Config := ⟨word unit, word 2048⟩
private def summary (deposited : Nat) : StaticOracle := fun _ _ =>
  .returned (encodeWord (word 0) ++ encodeWord (word deposited) ++ encodeWord (word 5))
private def rejects : StaticOracle := fun _ _ => .reverted [byte 0xab]

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
end LidoSRv3.Tests.TrioIntegration.Parent
