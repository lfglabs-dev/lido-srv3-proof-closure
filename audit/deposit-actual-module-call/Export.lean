import audit.trio.deposit.ModuleCall
open LidoSRv3.Audit.Source.TrioReserve1
open audit.trio.deposit.ModuleCall

def hexByte (b : UInt8) : String :=
  let digits := "0123456789abcdef".toList.toArray
  String.ofList [digits[b.toNat/16]!,digits[b.toNat%16]!]
def hex (bs : Live.Bytes) : String := String.join (bs.map hexByte)
def main : IO Unit := do
  IO.println "["
  for seed in List.range 64 do
    let count := (2^255 + seed*17)
    let data : Live.Bytes := (List.range (seed%35)).map (fun n => UInt8.ofNat (seed*13+n))
    let keys : Live.Bytes := (List.range (seed%4*48)).map (fun n => UInt8.ofNat (seed*37+n))
    let sigs : Live.Bytes := (List.range (seed%3*96)).map (fun n => UInt8.ofNat (seed*19+n))
    let row := Lean.Json.compress (Lean.Json.mkObj [("seed",Lean.toJson seed),("payload",Lean.toJson (hex (payload count data))),("reply",Lean.toJson (hex (encodeReturn keys sigs)))])
    IO.println (row ++ (if seed<63 then "," else ""))
  IO.println "]"
