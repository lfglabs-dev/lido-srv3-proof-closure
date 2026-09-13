import LidoSRv3.Audit.Source.Topup2Correspondence

/-!
Additive CLI entry that exposes the registered P-TOPUP-2 parent
`Source.Topup2.sourceRun` as JSON. It does not replace that parent or
edit any existing theorem.

Pinned span: `TopUpGateway.sol:160-237 topUp` composed with
`TopUpGateway.sol:396-415 _evaluateTopUpLimit` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
-/
namespace LidoSRv3.Audit.Verity.Topup2SourceEntry

open LidoSRv3.Audit.Source.Topup2
open Verity.Core

abbrev Word := LidoSRv3.Audit.Source.Topup2.Word

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

def jsonNats (xs : List Nat) : String :=
  "[" ++ String.intercalate "," (xs.map jsonNat) ++ "]"

def toWords (xs : List Nat) : List Word :=
  xs.map Uint256.ofNat

def wordVals (xs : List Word) : List Nat :=
  xs.map (·.val)

def encode (effective pending requested topUpLimits : List Nat)
    (target minTopUp remainingCap moduleLimit valueGwei : Nat) : String :=
  let eW := toWords effective
  let pW := toWords pending
  let rW := toWords requested
  let lW := toWords topUpLimits
  let tW := Uint256.ofNat target
  let mW := Uint256.ofNat minTopUp
  let cW := Uint256.ofNat remainingCap
  let sW := Uint256.ofNat moduleLimit
  let vW := Uint256.ofNat valueGwei
  let limits :=
    match sourceLimits eW pW tW mW with
    | some xs => wordVals xs
    | none => ([] : List Nat)
  match sourceRun eW pW rW lW tW mW cW sW vW with
  | some (allocs, remaining, used) =>
      "{" ++
        "\"ok\":true" ++
        ",\"revert\":null" ++
        ",\"allocs\":" ++ jsonNats (wordVals allocs) ++
        ",\"remaining\":" ++ jsonNat remaining.val ++
        ",\"used\":" ++ jsonNat used.val ++
        ",\"limits\":" ++ jsonNats limits ++
        ",\"limitN\":" ++ jsonNat limits.length ++
        ",\"n\":" ++ jsonNat allocs.length ++
      "}"
  | none =>
      "{" ++
        "\"ok\":false" ++
        ",\"revert\":\"none\"" ++
        ",\"allocs\":[]" ++
        ",\"remaining\":\"0\"" ++
        ",\"used\":\"0\"" ++
        ",\"limits\":" ++ jsonNats limits ++
        ",\"limitN\":" ++ jsonNat limits.length ++
        ",\"n\":\"0\"" ++
      "}"

def runJson (json : String) : Except String String :=
  match
    field json "effective" >>= parseNatList,
    field json "pending" >>= parseNatList,
    field json "requested" >>= parseNatList,
    field json "topUpLimits" >>= parseNatList,
    field json "target" >>= parseNatRaw,
    field json "minTopUp" >>= parseNatRaw,
    field json "remainingCap" >>= parseNatRaw,
    field json "moduleLimit" >>= parseNatRaw,
    field json "valueGwei" >>= parseNatRaw
  with
  | some e, some p, some r, some l, some t, some m, some c, some s, some v =>
      .ok (encode e p r l t m c s v)
  | none, _, _, _, _, _, _, _, _ => .error "invalid effective JSON"
  | _, none, _, _, _, _, _, _, _ => .error "invalid pending JSON"
  | _, _, none, _, _, _, _, _, _ => .error "invalid requested JSON"
  | _, _, _, none, _, _, _, _, _ => .error "invalid topUpLimits JSON"
  | _, _, _, _, none, _, _, _, _ => .error "invalid target JSON"
  | _, _, _, _, _, none, _, _, _ => .error "invalid minTopUp JSON"
  | _, _, _, _, _, _, none, _, _ => .error "invalid remainingCap JSON"
  | _, _, _, _, _, _, _, none, _ => .error "invalid moduleLimit JSON"
  | _, _, _, _, _, _, _, _, none => .error "invalid valueGwei JSON"

end LidoSRv3.Audit.Verity.Topup2SourceEntry

def main (args : List String) : IO UInt32 := do
  match args with
  | [json] =>
      match LidoSRv3.Audit.Verity.Topup2SourceEntry.runJson json with
      | .ok out => IO.println out; return 0
      | .error msg => IO.eprintln msg; return 1
  | ["source", json] =>
      match LidoSRv3.Audit.Verity.Topup2SourceEntry.runJson json with
      | .ok out => IO.println out; return 0
      | .error msg => IO.eprintln msg; return 1
  | _ =>
      IO.eprintln "usage: Topup2SourceEntry [source] <json>"
      return 1
