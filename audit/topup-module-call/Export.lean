import LidoSRv3.Audit.Source.TopupModuleCall
import Lean

open Lean
open LidoSRv3.Audit.Source TrioReserve1 Live TopupModuleCall

def vector (seed : Nat) : Input :=
  let n := seed % 5
  ⟨word 7,word (seed*1000000000),
    (List.range n).map (fun j => (List.range 48).map (fun k => UInt8.ofNat (seed*37+j*19+k))),
    (List.range n).map (fun j => word (2^255+seed*11+j)),
    (List.range n).map (fun j => word (seed*13+j)),
    (List.range n).map (fun j => word ((seed*17+j)*1000000000))⟩

def hexBytes (bs : Bytes) : String :=
  String.ofList (bs.flatMap fun b =>
    let digits := "0123456789abcdef".toList
    [digits[b.toNat/16]!,digits[b.toNat%16]!])

def main : IO Unit := do
  let rows := (List.range 64).map fun seed =>
    Lean.Json.mkObj [("seed",toJson seed),("payload",toJson (hexBytes (payload (vector seed)))),
      ("reply",toJson (hexBytes (encodeReturn (vector seed).keyIndices)))]
  IO.println (Lean.Json.compress (toJson rows))
