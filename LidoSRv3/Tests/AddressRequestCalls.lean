import LidoSRv3.Audit.Guarantees.PAddress1RequestCalls


namespace LidoSRv3.Tests.AddressRequestCalls
open LidoSRv3.Audit.Source.AddressRequestCalls
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge
  (StaticExternal abiWord lastRequestIdPosition lastReportTimestampPosition)
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Guarantees.PAddress1

def ctx : Context := ⟨99, 1⟩
def initial : World :=
  { core := { Verity.defaultState with codeSize := fun _ => 1, blockTimestamp := 5 }
    balances := fun _ => 0 }
def acceptsFalse : External := fun _ w => .success (abiWord 0) w
def staticTen : StaticExternal := fun _ _ => .ok (abiWord 10)
def mutates : External := fun _ w => .success (abiWord 0)
  { w with core := ({ w.core with blockTimestamp := 9999 }.writeSlot lastRequestIdPosition 7).writeSlot lastReportTimestampPosition 99 }
def staticTruncates : StaticExternal := fun _ _ => .ok (abiWord (2 ^ 128 + 7))
def badBool : External := fun _ w => .success (abiWord 2) w
def shortBool : External := fun _ w => .success [0] w
def quoteFailure : StaticExternal := fun _ _ => .error (.bubbled [99])

def live := runRequest acceptsFalse staticTen ctx 2 100 0 initial
example : (runRequest badBool staticTen ctx 2 100 0 initial).outcome = .error .empty := by decide +kernel
example : (runRequest shortBool staticTen ctx 2 100 0 initial).outcome = .error .empty := by decide +kernel
example : (runRequest acceptsFalse staticTen ctx 2 99 0 initial).outcome =
    .error (.reason "RequestAmountTooSmall") := by decide +kernel
example : (runRequest acceptsFalse staticTen ctx 2 (1000 * 10 ^ 18 + 1) 0 initial).outcome =
    .error (.reason "RequestAmountTooLarge") := by decide +kernel
example : (runRequest mutates quoteFailure ctx 2 100 0 initial).outcome =
    .error (.bubbled [99]) := by decide +kernel
example : (runRequest mutates quoteFailure ctx 2 100 0 initial).attempts.length = 2 := by decide +kernel
example : resolvedOwner ctx 0 = 1 ∧ resolvedOwner ctx 3 = 3 := by decide +kernel
example : metadataWord (.ofNat (171 * 2 ^ 248)) 3 5 9 =
    .ofNat (171 * 2 ^ 248 + 3 + 5 * 2 ^ 160 + 9 * 2 ^ 208) := by decide +kernel

example : (transferStage acceptsFalse ctx 2 100 initial).outcome = .ok () := by decide +kernel
example : (quoteStage staticTen ctx 2 100 initial).outcome = .ok 10 := by decide +kernel
example : (quoteStage staticTruncates ctx 2 100 initial).outcome = .ok (.ofNat (2 ^ 128 + 7)) := by decide +kernel
example : (enqueue ctx 1 (2 ^ 128) 0 5 initial).outcome = .error (.reason "Panic(0x11)") := by decide +kernel
example : (enqueue ctx 1 0 (2 ^ 128) 5 initial).outcome = .error (.reason "Panic(0x11)") := by decide +kernel

/-- Full world equality, with a real successful mutating transfer before failure. -/
theorem public_late_rollback_instance :
    (runRequest mutates quoteFailure ctx 2 100 0 initial).world = initial :=
  actual_request_withdrawal_failure_restores _ _ _ _ _ _ _ (.bubbled [99]) (by decide +kernel)

/-- Runtime diagnostics only. Unlike the kernel theorems above, these execute
Keccak via the accepted implemented_by FFI. They add no theorem or axiom. -/
def diagnostics : IO Unit := do
  let shifted := runRequest mutates staticTruncates ctx 2 100 0 initial
  let maxSet := { initial with core := (initial.core.writeSlot (ownerRequestValuesLengthSlot 1)
      (.ofNat (2 ^ 256 - 1))) }
  let maximum := runRequest acceptsFalse staticTen ctx 2 100 0 maxSet
  let checks : List (String × Bool) := [
    ("false bool success", live.outcome == .ok 1),
    ("ordered attempts", live.attempts.length == 2),
    ("ordered semantic events", live.world.logs.map (·.name) == ["WithdrawalRequested", "Transfer"]),
    ("owner zero and amount", live.world.logs.map (·.values) == [[1,1,1,100,10],[0,1,1]]),
    ("post-transfer id and shares truncation", shifted.world.logs.map (·.values) == [[8,1,1,100,7],[0,1,8]]),
    ("entry TIMESTAMP survives adversarial model metadata", (requestMetadataWord shifted.world.core 8).val / 2 ^ 160 % 2 ^ 40 == 5),
    ("legacy maximum set length accepts", maximum.outcome == .ok 1),
    ("legacy length wraps", ownerRequestValuesLength maximum.world.core 1 == 0)]
  for (name, passed) in checks do
    if passed then IO.println ("EXEC PASS: " ++ name)
    else throw (IO.userError ("EXEC FAIL: " ++ name))

#print axioms LidoSRv3.Audit.Source.AddressRequestCalls.insert_success
#print axioms LidoSRv3.Audit.Source.AddressRequestCalls.enqueue_success
#print axioms LidoSRv3.Audit.Source.AddressRequestCalls.transfer_success
#print axioms LidoSRv3.Audit.Source.AddressRequestCalls.quote_success
#print axioms actual_request_withdrawal_enqueue
#print axioms actual_request_withdrawal_failure_restores
#print axioms public_late_rollback_instance
end LidoSRv3.Tests.AddressRequestCalls
