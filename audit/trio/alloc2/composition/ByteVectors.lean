import audit.trio.alloc2.composition.ByteIndexed

namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteVectors
open ByteIndexed
private def readArray (memory : ByteMemory.Memory) (pointer : Nat) : List Word :=
  MemoryWrite.readArray (ByteMemory.load memory) pointer
private def writeWords (memory : ByteMemory.Memory) (start : Nat) : List Word → ByteMemory.Memory
  | [] => memory
  | value :: rest => writeWords (ByteMemory.store memory start value) (start+32) rest
private def w := TrioAlloc1.word
private def json (values : List Word) : String :=
  "[" ++ String.intercalate "," (values.map fun x => "\"" ++ toString x.val ++ "\"") ++ "]"
private def seed (ap cp : Nat) (buckets capacities : List Word) : ByteMemory.Memory :=
  writeWords (writeWords (fun _ => TrioAlloc1.byte 0xa5) ap (w buckets.length :: buckets))
    cp (w capacities.length :: capacities)
private def emit (name : String) (ap cp : Nat) (bs cs : List Nat) (d1 d2 : Nat) : IO Unit := do
  let buckets := bs.map w
  let capacities := cs.map w
  let memory := seed ap cp buckets capacities
  match run memory ap cp (w d1) with
  | .error e => throw (IO.userError s!"first run failed: {repr e}")
  | .ok (firstAmount, firstMemory) =>
    match run firstMemory ap cp (w d2) with
    | .error e => throw (IO.userError s!"second run failed: {repr e}")
    | .ok (secondAmount, secondMemory) =>
      if secondMemory 7 ≠ memory 7 then throw (IO.userError "outside frame changed")
      if readArray secondMemory cp ≠ capacities then throw (IO.userError "capacities changed")
      IO.println ("ALLOC2_BYTE_MEMORY_SEQUENCE {\"name\":\"" ++ name ++ "\",\"buckets\":" ++ json buckets ++
        ",\"capacities\":" ++ json capacities ++ ",\"d1\":\"" ++ toString d1 ++ "\",\"d2\":\"" ++ toString d2 ++
        "\",\"firstAmount\":\"" ++ toString firstAmount.val ++ "\",\"secondAmount\":\"" ++ toString secondAmount.val ++
        "\",\"first\":" ++ json (readArray firstMemory ap) ++ ",\"second\":" ++ json (readArray secondMemory ap) ++
        ",\"frame\":\"" ++ toString (secondMemory 7).val ++ "\"}")
#eval do
  emit "two-calls" 128 512 [0,0] [100,100] 5 5
  emit "reverse-regions" 512 128 [0,0] [100,100] 5 5
  emit "below-capacity" 128 512 [7,0] [3,10] 3 20
  emit "zero-first" 128 512 [0,0] [100,100] 0 5
  emit "129-rows" 128 8192 (List.replicate 129 0) (List.replicate 129 2) 129 129
end LidoSRv3.Audit.Source.TrioAlloc2.ByteVectors
