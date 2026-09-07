import LidoSRv3.Audit.Source.TrioAlloc1.Properties

namespace LidoSRv3.Tests.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1

private instance [DecidableEq ε] [DecidableEq α] : DecidableEq (Except ε α) :=
  fun a b => match a, b with
  | .ok a, .ok b => decidable_of_iff (a = b) (by simp)
  | .error a, .error b => decidable_of_iff (a = b) (by simp)
  | .ok _, .error _ => isFalse (by intro h; cases h)
  | .error _, .ok _ => isFalse (by intro h; cases h)

/-- Test hash projection only. Production layout retains an explicit actual-keccak relation. -/
def layout : Layout := { routerSlot := word 10, keccak := fun bs =>
  if bs.length = 32 then word 100 else word (1000 + (decodeWord bs 0).val * 4) }

def packed (address share status wc : Nat) : Word :=
  word (address + share * 2^192 + status * 2^224 + wc * 2^232)

def storage (count : Nat) (config0 config1 : Word) : Storage := fun slot =>
  if slot.val = 11 then word count
  else if slot.val = 100 then word 7
  else if slot.val = 101 then word 9
  else if slot.val = 1028 then config0
  else if slot.val = 1036 then config1
  else word 0

def input : CapacityInput := {
  config := { maxEBType1 := word 32, maxEBType2 := word 2048 }
  depositsToAllocate := word 10
  isTopUp := false }

def summary (exited deposited depositable : Nat) : Bytes :=
  encodeWord (word exited) ++ encodeWord (word deposited) ++ encodeWord (word depositable)

def columns (result : CapacityResult) : Except Failure (List Nat × List Nat) :=
  result.map fun o => (o.allocations.map Fin.val, o.capacities.map Fin.val)

def honest : StaticOracle := fun _ call =>
  if call.payload = stakePayload then .returned (encodeWord (word 65))
  else .returned (summary 1 4 20)

-- Width decoding, the complete order, and below-allocation inactive/active distinction.
example : (readModule layout (storage 2 (packed 21 5000 0 1) (packed 22 5000 1 2)) 1).identity.moduleId = word 9 := by decide

example : columns (produce layout (storage 2 (packed 21 5000 0 1) (packed 22 5000 1 2))
    honest input []).1 = .ok ([3, 3], [8, 3]) := by decide

example : ((produce layout (storage 2 (packed 21 5000 0 1) (packed 22 5000 1 2))
    honest input []).2.map fun c => (c.request.target.val, c.request.payload)) =
    [(21, summaryPayload), (22, summaryPayload), (22, stakePayload)] := by decide

example : columns (produce layout (storage 1 (packed 21 0 0 1) (word 0)) honest input []).1 =
    .ok ([3], [0]) := by decide

-- Active WC01 is retained during top-up; WC02 uses active * maxEB2 / maxEB1.
example : columns (produce layout (storage 2 (packed 21 10000 0 1) (packed 22 10000 0 2))
    honest { input with isTopUp := true } []).1 = .ok ([3, 3], [16, 16]) := by decide

-- Empty helper does not divide by maxEB1 or call any module.
example : columns (produce layout (storage 0 (word 0) (word 0)) honest
    { input with config := { maxEBType1 := word 0, maxEBType2 := word 0 } } []).1 =
    .ok ([], []) := by decide

-- Underflow wins over a would-be failing stake call and prevents the next module call.
def underflow : StaticOracle := fun _ call =>
  if call.payload = summaryPayload then .returned (summary 5 4 20)
  else .reverted [byte 0xaa]

example : columns (produce layout (storage 2 (packed 21 5000 0 2) (packed 22 5000 0 1))
    underflow input []).1 = .error (.panic (word 0x11)) := by decide
example : (produce layout (storage 2 (packed 21 5000 0 2) (packed 22 5000 0 1))
    underflow input []).2.length = 1 := by decide

-- A late summary rejection retains its raw bytes and all attempted calls.
def lateReject : StaticOracle := fun trace _ =>
  if trace.length = 1 then .reverted [byte 0xde, byte 0xad]
  else .returned (summary 0 1 1)
example : columns (produce layout (storage 2 (packed 21 5000 0 1) (packed 22 5000 0 1))
    lateReject input []).1 = .error (.revertData [byte 0xde, byte 0xad]) := by decide
example : (produce layout (storage 2 (packed 21 5000 0 1) (packed 22 5000 0 1))
    lateReject input []).2.length = 2 := by decide

-- Malformed calldata return lengths fail closed; extra return bytes are accepted.
example : decodeSummary (List.replicate 95 (byte 0)) = .error .decoderFailure := by decide
example : decodeStake (List.replicate 31 (byte 0)) = .error .decoderFailure := by decide
example : decodeSummary (summary 1 2 3 ++ [byte 0xff]) =
    .ok { exited := word 1, deposited := word 2, depositable := word 3 } := by decide
example : checkedCeilDiv (word 0) (word 0) = .error (.panic (word 0x12)) := by decide
example : checkedCeilDiv (word (2^256-1)) (word 1) = .ok (word (2^256-1)) := by decide

-- The available calculation overflows before zero division or a target calculation.
def topupRow : CachedRow := {
  stored := readModule layout (storage 1 (packed 21 10000 0 2) (word 0)) 0
  summary := { exited := word 0, deposited := word 2, depositable := word 0 }
  active := word 2
  allocation := word 1 }
example : rowCapacity { input with isTopUp := true, config := { maxEBType1 := word 0, maxEBType2 := word (2^256-1) } }
    (word (2^256-1)) topupRow = .error (.panic (word 0x11)) := by decide

-- Whole-producer mutation witness: prefetching stake calls after summary underflow
-- changes the observed trace. A target-only mutant changes a successful capacity.
example : (produce layout (storage 1 (packed 21 10000 0 2) (word 0)) underflow input []).2.length
    ≠ 2 := by decide
example : columns (produce layout (storage 1 (packed 21 10000 0 1) (word 0))
    (fun _ _ => .returned (summary 0 1 0)) input []).1 ≠ .ok ([1], [11]) := by decide

end LidoSRv3.Tests.TrioAlloc1
