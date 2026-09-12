import LidoSRv3.Audit.Source.ReserveCorrespondence

/-!
Additive CLI entry that exposes the registered P-RESERVE-1 parent
`modelWithdrawDepositableEther` as JSON. It does not replace that parent
or edit any existing theorem.

Pinned span: `Lido.sol:869-886 withdrawDepositableEther` composed with
`Lido.sol:605-616 _getBufferedEtherAllocation` and
`Lido.sol:839-859 _spendDepositableEther` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
-/
namespace LidoSRv3.Audit.Verity.ReserveSourceEntry

open LidoSRv3.Audit.SolidityReserve
open Verity.Core

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

def parseBool (s : String) : Option Bool :=
  let t := String.ofList (ltrim s.toList)
  if t.startsWith "true" then some true
  else if t.startsWith "false" then some false
  else none

def jsonNat (n : Nat) : String := s!"\"{toString n}\""

def jsonString (s : String) : String :=
  s!"\"{String.join (s.toList.map fun c =>
    if c = '"' then "\\\"" else String.ofList [c])}\""

def encode (canDeposit authorizedRouter : Bool) (amount : Nat)
    (buffered storedDepositsReserve unfinalizedStETH
      depositedPostReport depositedNextReportAdjusted : Nat) : String :=
  let inputs : WithdrawInputs := { canDeposit, authorizedRouter }
  let before : ReserveState := {
    buffered := Uint256.ofNat buffered
    storedDepositsReserve := Uint256.ofNat storedDepositsReserve
    unfinalizedStETH := Uint256.ofNat unfinalizedStETH
    depositedPostReport := Uint256.ofNat depositedPostReport
    depositedNextReportAdjusted := Uint256.ofNat depositedNextReportAdjusted
  }
  let wrBefore := (effectiveWithdrawalsReserve before).val
  match modelWithdrawDepositableEther inputs before (Uint256.ofNat amount) with
  | .committed after =>
      "{" ++
        "\"ok\":true" ++
        ",\"revert\":null" ++
        ",\"buffered\":" ++ jsonNat after.buffered.val ++
        ",\"storedDepositsReserve\":" ++ jsonNat after.storedDepositsReserve.val ++
        ",\"unfinalizedStETH\":" ++ jsonNat after.unfinalizedStETH.val ++
        ",\"depositedPostReport\":" ++ jsonNat after.depositedPostReport.val ++
        ",\"depositedNextReportAdjusted\":" ++ jsonNat after.depositedNextReportAdjusted.val ++
        ",\"withdrawalsReserveBefore\":" ++ jsonNat wrBefore ++
        ",\"withdrawalsReserveAfter\":" ++ jsonNat (effectiveWithdrawalsReserve after).val ++
      "}"
  | .reverted reason =>
      "{" ++
        "\"ok\":false" ++
        ",\"revert\":" ++ jsonString reason ++
        ",\"buffered\":" ++ jsonNat before.buffered.val ++
        ",\"storedDepositsReserve\":" ++ jsonNat before.storedDepositsReserve.val ++
        ",\"unfinalizedStETH\":" ++ jsonNat before.unfinalizedStETH.val ++
        ",\"depositedPostReport\":" ++ jsonNat before.depositedPostReport.val ++
        ",\"depositedNextReportAdjusted\":" ++ jsonNat before.depositedNextReportAdjusted.val ++
        ",\"withdrawalsReserveBefore\":" ++ jsonNat wrBefore ++
        ",\"withdrawalsReserveAfter\":" ++ jsonNat wrBefore ++
      "}"

def runJson (json : String) : Except String String :=
  match
    field json "canDeposit" >>= parseBool,
    field json "authorizedRouter" >>= parseBool,
    field json "amount" >>= parseNatRaw,
    field json "buffered" >>= parseNatRaw,
    field json "storedDepositsReserve" >>= parseNatRaw,
    field json "unfinalizedStETH" >>= parseNatRaw,
    field json "depositedPostReport" >>= parseNatRaw,
    field json "depositedNextReportAdjusted" >>= parseNatRaw
  with
  | some c, some a, some amt, some b, some d, some u, some p, some n =>
      .ok (encode c a amt b d u p n)
  | none, _, _, _, _, _, _, _ => .error "invalid canDeposit JSON"
  | _, none, _, _, _, _, _, _ => .error "invalid authorizedRouter JSON"
  | _, _, none, _, _, _, _, _ => .error "invalid amount JSON"
  | _, _, _, none, _, _, _, _ => .error "invalid buffered JSON"
  | _, _, _, _, none, _, _, _ => .error "invalid storedDepositsReserve JSON"
  | _, _, _, _, _, none, _, _ => .error "invalid unfinalizedStETH JSON"
  | _, _, _, _, _, _, none, _ => .error "invalid depositedPostReport JSON"
  | _, _, _, _, _, _, _, none => .error "invalid depositedNextReportAdjusted JSON"

end LidoSRv3.Audit.Verity.ReserveSourceEntry

def main (args : List String) : IO UInt32 := do
  match args with
  | [json] =>
      match LidoSRv3.Audit.Verity.ReserveSourceEntry.runJson json with
      | .ok out => IO.println out; return 0
      | .error msg => IO.eprintln msg; return 1
  | ["source", json] =>
      match LidoSRv3.Audit.Verity.ReserveSourceEntry.runJson json with
      | .ok out => IO.println out; return 0
      | .error msg => IO.eprintln msg; return 1
  | _ =>
      IO.eprintln "usage: ReserveSourceEntry [source] <json>"
      return 1
