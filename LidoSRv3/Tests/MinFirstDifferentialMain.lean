import LidoSRv3.Audit.Verity.MinFirstSourceEntry

open Verity
open LidoSRv3.Audit.Verity

def parseWord (s : String) : Except String Core.Uint256 := do
  let n ← match s.toNat? with
    | some n => .ok n
    | none => .error "expected an unsigned decimal word"
  if n < Core.Uint256.modulus then .ok (Core.Uint256.ofNat n)
  else .error "word out of range"

def parseWords (s : String) : Except String (List Core.Uint256) :=
  if s.isEmpty then .ok [] else (s.splitOn ",").mapM parseWord

def hexWord (n : Nat) : String :=
  String.ofList ((List.range 64).reverse.map fun i =>
    ("0123456789abcdef".toList)[n / 16 ^ i % 16]!)

def encodeObservation (ok : Bool) (value : Nat) (buckets : List Core.Uint256) : String :=
  "0x" ++ hexWord (if ok then 1 else 0) ++ hexWord value ++ hexWord 96 ++
    hexWord buckets.length ++ String.join (buckets.map fun w => hexWord w.val)

def main (args : List String) : IO UInt32 := do
  match args with
  | [mode, demandText, bucketsText, capacitiesText] =>
    match (do
      let demand ← parseWord demandText
      let buckets ← parseWords bucketsText
      let capacities ← parseWords capacitiesText
      pure (demand, buckets, capacities) : Except String _) with
    | .error message => IO.eprintln message; return 1
    | .ok (demand, buckets, capacities) =>
      if mode == "source" then
        match (MinFirstSourceEntry.allocateDecoded buckets capacities demand).run defaultState with
        | .success r _ => IO.println (encodeObservation true r.allocated.val r.buckets)
        | .revert reason _ =>
          let code := if reason == "Panic(0x32)" then 0x32 else 0xffffffff
          IO.println (encodeObservation false code [])
      else if mode == "legacy" then
        let s := MinFirstDistributionTx.stateFor buckets capacities defaultState
        match (MinFirstDistributionTx.allocate buckets.length capacities.length demand).run s with
        | .success r _ => IO.println (encodeObservation true r.allocated.val r.buckets)
        | .revert _ _ => IO.println (encodeObservation false 0xffffffff [])
      else
        IO.eprintln "unknown model mode"
        return 1
      return 0
  | _ => IO.eprintln "usage: model source|legacy demand bucketsCSV capacitiesCSV"; return 1
