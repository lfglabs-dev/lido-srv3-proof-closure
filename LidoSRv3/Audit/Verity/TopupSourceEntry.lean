import LidoSRv3.Audit.Verity.TopupTx

/-!
Additive CLI entry that exposes the registered P-TOPUP-1 parent
`TopupTx.execute` as JSON. It does not replace that parent or edit any
existing theorem.

`StakingRouter.sol:679-759 topUp(...)` is the pinned source span. This
wrapper only serialises the already-registered allocation-suffix transaction.
-/
namespace LidoSRv3.Audit.Verity.TopupSourceEntry

open _root_.Verity
open LidoSRv3.Audit.Verity.TopupTx

def afterFirst (hay needle : String) : Option String :=
  match hay.splitOn needle with
  | _ :: rest@(_ :: _) => some (String.intercalate needle rest)
  | _ => none

def ltrim : List Char → List Char
  | ' ' :: rest => ltrim rest
  | '\n' :: rest => ltrim rest
  | '\t' :: rest => ltrim rest
  | cs => cs

def takeDigits : List Char → List Char
  | c :: rest => if c.isDigit then c :: takeDigits rest else []
  | [] => []

def parseNatRaw (s : String) : Option Nat :=
  let t := ltrim s.toList
  match t with
  | '"' :: rest => String.ofList (takeDigits rest) |>.toNat?
  | _ => String.ofList (takeDigits t) |>.toNat?

def field (json key : String) : Option String :=
  afterFirst json s!"\"{key}\":"

def parseFailure (s : String) : Option FailurePoint :=
  let t := String.ofList (ltrim s.toList)
  if t.startsWith "\"none\"" || t.startsWith "none" then some .none
  else if t.startsWith "\"afterAllocationWrite\"" || t.startsWith "afterAllocationWrite" then
    some .afterAllocationWrite
  else if t.startsWith "\"afterLidoPull\"" || t.startsWith "afterLidoPull" then
    some .afterLidoPull
  else if t.startsWith "\"afterFirstBeaconPush\"" || t.startsWith "afterFirstBeaconPush" then
    some .afterFirstBeaconPush
  else none

def skipSep : List Char → List Char
  | ' ' :: rest => skipSep rest
  | '\n' :: rest => skipSep rest
  | '\t' :: rest => skipSep rest
  | ',' :: rest => skipSep rest
  | cs => cs

def parseNatList (s : String) : Option (List Nat) :=
  let cs := ltrim s.toList
  match cs with
  | '[' :: rest =>
      let rec go (fuel : Nat) (rest : List Char) (acc : List Nat) : Option (List Nat) :=
        match fuel with
        | 0 => none
        | fuel' + 1 =>
          let u := skipSep rest
          match u with
          | ']' :: _ => some acc.reverse
          | _ =>
            match String.ofList (takeDigits u) |>.toNat? with
            | some n => go fuel' (u.drop (toString n).length) (n :: acc)
            | none =>
              match u with
              | '"' :: more =>
                  match String.ofList (takeDigits more) |>.toNat? with
                  | some n => go fuel' (more.drop ((toString n).length + 1)) (n :: acc)
                  | none => none
              | _ => none
      go (s.length + 1) rest []
  | _ => none

def jsonNat (n : Nat) : String := s!"\"{toString n}\""

def jsonString (s : String) : String :=
  s!"\"{String.join (s.toList.map fun c =>
    if c = '"' then "\\\"" else String.ofList [c])}\""

def jsonNats (xs : List Nat) : String :=
  "[" ++ String.intercalate "," (xs.map jsonNat) ++ "]"

def jsonCall (c : ExternalCall) : String :=
  "{" ++
    "\"name\":" ++ jsonString c.name ++
    ",\"target\":" ++ jsonNat c.target ++
    ",\"value\":" ++ jsonNat c.value ++
    ",\"args\":" ++ jsonNats c.calldata ++
  "}"

def jsonCalls (cs : List ExternalCall) : String :=
  "[" ++ String.intercalate "," (cs.map jsonCall) ++ "]"

def encode (allocations : List Nat) (failure : FailurePoint) : String :=
  match (execute allocations failure).run defaultState with
  | .success _ after =>
      let obs := observe defaultState allocations.length (.success () after)
      "{" ++
        "\"ok\":true" ++
        ",\"revert\":null" ++
        ",\"committed\":true" ++
        ",\"pulled\":" ++ jsonNat obs.pulled ++
        ",\"pushed\":" ++ jsonNat obs.pushed ++
        ",\"allocationTotal\":" ++ jsonNat obs.allocationTotal ++
        ",\"calls\":" ++ jsonCalls (after.calls.drop defaultState.calls.length) ++
        ",\"events\":[]" ++
      "}"
  | .revert reason after =>
      "{" ++
        "\"ok\":false" ++
        ",\"revert\":" ++ jsonString reason ++
        ",\"committed\":false" ++
        ",\"pulled\":\"0\"" ++
        ",\"pushed\":\"0\"" ++
        ",\"allocationTotal\":" ++ jsonNat (after.readSlot allocationTotalSlot).val ++
        ",\"calls\":[]" ++
        ",\"events\":[]" ++
      "}"

def runJson (json : String) : Except String String :=
  match field json "allocations" >>= parseNatList, field json "failure" >>= parseFailure with
  | some allocations, some failure => .ok (encode allocations failure)
  | none, _ => .error "invalid allocations JSON"
  | _, none => .error "invalid failure JSON"

end LidoSRv3.Audit.Verity.TopupSourceEntry

def main (args : List String) : IO UInt32 := do
  match args with
  | [json] =>
      match LidoSRv3.Audit.Verity.TopupSourceEntry.runJson json with
      | .ok out => IO.println out; return 0
      | .error msg => IO.eprintln msg; return 1
  | ["source", json] =>
      match LidoSRv3.Audit.Verity.TopupSourceEntry.runJson json with
      | .ok out => IO.println out; return 0
      | .error msg => IO.eprintln msg; return 1
  | _ =>
      IO.eprintln "usage: TopupSourceEntry [source] <json>"
      return 1
