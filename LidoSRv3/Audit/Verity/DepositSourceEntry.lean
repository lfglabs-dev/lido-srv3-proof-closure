import LidoSRv3.Audit.Verity.DepositNFrameTx

/-!
Additive CLI entry that exposes the registered P-DEPOSIT-1 parent
`DepositNFrameTx.execute` as JSON. It does not replace that parent or
edit any existing theorem.

`StakingRouter.sol:942-997 deposit(uint256 _stakingModuleId, bytes calldata _depositCalldata)`
is the pinned source span. This wrapper only serialises the already-registered
list-batch transaction.
-/
namespace LidoSRv3.Audit.Verity.DepositSourceEntry

open _root_.Verity
open LidoSRv3.Audit.Verity
open LidoSRv3.Audit.Verity.DepositNFrameTx

abbrev Word := Core.Uint256

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

def parseBoolRaw (s : String) : Option Bool :=
  let t := String.ofList (ltrim s.toList)
  if t.startsWith "true" then some true
  else if t.startsWith "false" then some false
  else none

def field (json key : String) : Option String :=
  afterFirst json s!"\"{key}\":"

def natField (json key : String) : Option Nat :=
  field json key >>= parseNatRaw

def boolField (json key : String) : Option Bool :=
  field json key >>= parseBoolRaw

def addrField (json key : String) : Option Address :=
  match natField json key with
  | some n => some (Core.Address.ofNat n)
  | none => none

def wordField (json key : String) : Option Word :=
  match natField json key with
  | some n =>
      if n < Core.Uint256.modulus then some (Core.Uint256.ofNat n) else none
  | none => none

def objectSlice (s : String) : Option String :=
  let cs := ltrim s.toList
  if cs.head? != some '{' then none else
    let rec go (fuel depth : Nat) (acc rest : List Char) : Option String :=
      match fuel, rest with
      | 0, _ => none
      | _, [] => none
      | fuel' + 1, c :: tail =>
          let acc' := acc ++ [c]
          if c = '{' then go fuel' (depth + 1) acc' tail
          else if c = '}' then
            if depth = 1 then some (String.ofList acc')
            else go fuel' (depth - 1) acc' tail
          else go fuel' depth acc' tail
    go (cs.length + 1) 0 [] cs

def parseBatch (json : String) : Option Batch := do
  let moduleId ← wordField json "moduleId"
  let keys ← wordField json "keys"
  let amount ← wordField json "amount"
  let dynamicDataCommitment ← wordField json "dynamicDataCommitment"
  let depositDataRoot ← wordField json "depositDataRoot"
  let dataValid ← boolField json "dataValid"
  let rootValid ← boolField json "rootValid"
  let moduleCallOk ← boolField json "moduleCallOk"
  let beaconCallOk ← boolField json "beaconCallOk"
  pure {
    moduleId, keys, amount, dynamicDataCommitment, depositDataRoot,
    dataValid, rootValid, moduleCallOk, beaconCallOk
  }

def skipSep : List Char → List Char
  | ' ' :: rest => skipSep rest
  | '\n' :: rest => skipSep rest
  | '\t' :: rest => skipSep rest
  | ',' :: rest => skipSep rest
  | cs => cs

def parseBatches (s : String) : Option (List Batch) :=
  let cs := ltrim s.toList
  match cs with
  | '[' :: rest =>
      let rec go (fuel : Nat) (rest : List Char) (acc : List Batch) : Option (List Batch) :=
        match fuel with
        | 0 => none
        | fuel' + 1 =>
          let u := skipSep rest
          match u with
          | ']' :: _ => some acc.reverse
          | _ => do
              let obj ← objectSlice (String.ofList u)
              let batch ← parseBatch obj
              go fuel' (u.drop obj.length) (batch :: acc)
      go (s.length + 1) rest []
  | _ => none

def parseInputs (json : String) : Option Inputs := do
  let authorized ← boolField json "authorized"
  let moduleActive ← boolField json "moduleActive"
  let allocationValid ← boolField json "allocationValid"
  let lidoCallOk ← boolField json "lidoCallOk"
  let depositSize ← wordField json "depositSize"
  let lido ← addrField json "lido"
  let module ← addrField json "module"
  let beacon ← addrField json "beacon"
  let batchText ← field json "batches"
  let batches ← parseBatches batchText
  pure {
    authorized, moduleActive, allocationValid, lidoCallOk,
    depositSize, lido, module, beacon, batches
  }

def parseState (json : String) : Option ContractState := do
  let counter ← wordField json "counter"
  let lidoDepositable ← wordField json "lidoDepositable"
  let selfBalance ← wordField json "selfBalance"
  pure (((defaultState.writeSlot counterSlot counter).writeSlot
    lidoDepositableSlot lidoDepositable) |> fun s =>
      { s with selfBalance })

def escape (s : String) : String :=
  String.join (s.toList.map fun c =>
    if c = '"' then "\\\"" else if c = '\\' then "\\\\" else String.ofList [c])

def jsonNat (n : Nat) : String := s!"\"{toString n}\""

def jsonBool : Bool → String
  | true => "true"
  | false => "false"

def jsonString (s : String) : String :=
  s!"\"{escape s}\""

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

def pushedOf : List ExternalCall → Nat
  | [] => 0
  | c :: rest =>
      (if c.name == "depositToBeacon" then c.value else 0) + pushedOf rest

/-- Decode one registered-parent run to the observables the guarantee names. -/
def encode (inputs : Inputs) (before : ContractState) : String :=
  match (execute inputs).run before with
  | .success _ after =>
      let journal := after.calls.drop before.calls.length
      let pulled :=
        (before.readSlot lidoDepositableSlot).val - (after.readSlot lidoDepositableSlot).val
      "{" ++
        "\"ok\":true" ++
        ",\"revert\":null" ++
        ",\"committed\":true" ++
        ",\"pulled\":" ++ jsonNat pulled ++
        ",\"pushed\":" ++ jsonNat (pushedOf journal) ++
        ",\"routerBalance\":" ++ jsonNat after.selfBalance.val ++
        ",\"counter\":" ++ jsonNat (after.readSlot counterSlot).val ++
        ",\"lidoDepositable\":" ++ jsonNat (after.readSlot lidoDepositableSlot).val ++
        ",\"calls\":" ++ jsonCalls journal ++
        ",\"events\":[]" ++
      "}"
  | .revert reason after =>
      "{" ++
        "\"ok\":false" ++
        ",\"revert\":" ++ jsonString reason ++
        ",\"committed\":false" ++
        ",\"pulled\":0" ++
        ",\"pushed\":0" ++
        ",\"routerBalance\":" ++ jsonNat after.selfBalance.val ++
        ",\"counter\":" ++ jsonNat (after.readSlot counterSlot).val ++
        ",\"lidoDepositable\":" ++ jsonNat (after.readSlot lidoDepositableSlot).val ++
        ",\"calls\":[]" ++
        ",\"events\":[]" ++
      "}"

def runJson (json : String) : Except String String :=
  match parseInputs json, parseState json with
  | some inputs, some before => .ok (encode inputs before)
  | none, _ => .error "invalid DepositNFrameTx inputs JSON"
  | _, none => .error "invalid entry-state JSON"

end LidoSRv3.Audit.Verity.DepositSourceEntry

def main (args : List String) : IO UInt32 := do
  match args with
  | [json] =>
      match LidoSRv3.Audit.Verity.DepositSourceEntry.runJson json with
      | .ok out => IO.println out; return 0
      | .error msg => IO.eprintln msg; return 1
  | ["source", json] =>
      match LidoSRv3.Audit.Verity.DepositSourceEntry.runJson json with
      | .ok out => IO.println out; return 0
      | .error msg => IO.eprintln msg; return 1
  | _ =>
      IO.eprintln "usage: DepositSourceEntry [source] <json>"
      return 1
