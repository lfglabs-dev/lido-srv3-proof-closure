import LidoSRv3.Tests.TrioAlloc1.Execution

namespace LidoSRv3.Tests.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1

private def hexDigit (n : Nat) : String :=
  String.singleton (("0123456789abcdef".toList)[n % 16]!)
private def hexBytes (bytes : Bytes) : String :=
  "0x" ++ String.join (bytes.map fun b => hexDigit (b.val / 16) ++ hexDigit b.val)
private def quoted (s : String) : String := "\"" ++ s ++ "\""
private def array (xs : List String) : String := "[" ++ String.intercalate "," xs ++ "]"
private def numbers (xs : List Word) : String := array (xs.map fun x => toString x.val)

private def failureData : Failure → Bytes
  | .revertData data => data
  | .decoderFailure => []
  | .exceptionalCall => []
  | .panic code => [byte 0x4e, byte 0x48, byte 0x7b, byte 0x71] ++ encodeWord code

private def resultJSON : CapacityResult → String
  | .error e => quoted (hexBytes (failureData e))
  | .ok o => array [numbers o.allocations, numbers o.capacities]

private def responseOracle (s0 s1 t0 : Bytes) (reject0 reject1 rejectStake : Bool := false) :
    StaticOracle := fun _ call =>
  let is0 := call.target.val = 21
  let isSummary := call.payload = summaryPayload
  let data := if isSummary then (if is0 then s0 else s1) else t0
  let reject := if isSummary then (if is0 then reject0 else reject1) else rejectStake
  if reject then .reverted data else .returned data

private def standard := responseOracle (summary 0 1 1) (summary 0 1 1) (encodeWord (word 65))

private def seed (count : Nat := 1) (share : Nat := 10000) (status : Nat := 0)
    (wc : Nat := 1) : Storage :=
  storage count (packed 21 share status wc) (packed 22 10000 0 1)

private def vectorWith (run : Layout → Storage → StaticOracle → CapacityInput → Execution CapacityOutput) (name : String) (s : Storage) (oracle : StaticOracle)
    (inp : CapacityInput := input) : String :=
  let (result, trace) := run layout s oracle inp []
  let calls := trace.map fun c => quoted (
    (if c.request.target.val = 21 then "0:" else "1:") ++
    ((hexBytes c.request.payload).drop 2).toString)
  "{\"name\":" ++ quoted name ++ ",\"actual\":" ++ resultJSON result ++
    ",\"calls\":" ++ array calls ++ "}"

-- The program actually evaluates `produce`; it does not print expected outputs.
def solidityVectorsWith (run : Layout → Storage → StaticOracle → CapacityInput → Execution CapacityOutput) : String :=
  array [
  vectorWith run "mixed" (storage 2 (packed 21 5000 0 1) (packed 22 5000 1 2)) honest,
  vectorWith run "underflow-before-stake" (seed 1 10000 0 2) underflow,
  vectorWith run "late-rejection" (seed 2)
    (responseOracle (summary 0 1 1) [byte 0xde, byte 0xad] [] false true),
  vectorWith run "short-summary" (seed) (responseOracle (List.replicate 95 (byte 0)) [] []),
  vectorWith run "short-stake" (seed 1 10000 0 2)
    (responseOracle (summary 0 1 1) [] (List.replicate 31 (byte 0))),
  vectorWith run "trailing-summary" (seed)
    (responseOracle (summary 0 1 1 ++ [byte 0xff]) [] []),
  vectorWith run "zero-ceil-divisor" (seed 1 10000 0 2)
    (responseOracle (summary 0 1 1) [] (encodeWord (word 0)))
    { input with config := { maxEBType1 := word 0, maxEBType2 := word 2048 } },
  vectorWith run "invalid-enum-before-call" (seed 1 10000 3) standard,
  vectorWith run "below-allocation" (seed 1 0) standard,
  vectorWith run "topup-product-before-division" (seed 1 10000 0 2)
    (responseOracle (summary 0 2 0) [] (encodeWord (word 0)))
    { input with isTopUp := true, config := { maxEBType1 := word 1, maxEBType2 := word (2^256-1) } },
  vectorWith run "empty-zero-divisor" (seed 0) standard
    { input with config := { maxEBType1 := word 0, maxEBType2 := word 0 } },
  vectorWith run "total-overflow-before-next-row" (seed 2) standard
    { input with depositsToAllocate := word (2^256-1) }
]

def solidityVectors : String := solidityVectorsWith produce

end LidoSRv3.Tests.TrioAlloc1

