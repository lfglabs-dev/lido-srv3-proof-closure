import audit.trio.consolidation.Predeploy

/-! Executable vectors for the vault entrypoint against the concrete EIP-7251
predeploy body (`predeployBody`) and its fee STATICCALL body
(`predeployStaticBody`) under `Live.run`: the fee is read from the predeploy
fee slot by the line-84 `staticcall("")`, each accepted request writes the
count and three queue words, and the predeploy commits no logs of its own.
No `LogFrame` / `BalanceFrame` / `Untraced` premise is supplied anywhere here. -/

namespace LidoSRv3.Tests.TrioConsolidation.Predeploy

open audit.trio.consolidation
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.TrioReserve1.ABI

private def blob (id : Nat) : Bytes := encode pubkeyLength id
private def addr (n : Nat) : Live.Address := Verity.Core.Address.ofNat n

private def vault : Live.Address := addr 0xA1
private def gateway : Live.Address := addr 0xB2
private def inbox : Live.Address := addr 0x0000BBdDc7CE488642fb579F8B00f3a590007251

private def ctx : Context := ⟨vault, gateway⟩

/-- The predeploy has code and its fee slot holds `7`. -/
private def core : Verity.ContractState :=
  ({ Verity.defaultState with
      codeSize := fun a => if a = inbox.val then Live.word 1 else Live.word 0 } :
    Verity.ContractState).writeContractSlot inbox.val predeployFeeSlot (Live.word 7)

/-- Entry world of the vault frame: the payable credit already happened. -/
private def before (msgValue : Nat) : World :=
  ⟨core, fun a => if a = vault then msgValue else 0, []⟩

private def sources : List Bytes := [blob 11, blob 12]
private def targets : List Bytes := [blob 21, blob 22]

private def run (msgValue : Nat) : Result Unit :=
  executeVault predeployBody predeployStaticBody ctx gateway inbox (Live.word msgValue)
    sources targets (before msgValue)

private def committed : Result Unit := run 14

private def isOk (r : Result Unit) : Bool :=
  match r.outcome with
  | .ok _ => true
  | .error _ => false

private def feeOf (r : Result Live.Word) : Option Nat :=
  match r.outcome with
  | .ok f => some f.val
  | .error _ => none

private def rejectedData : Reply → Option Bytes
  | .rejected data => some data
  | _ => none

/-! ### Fee read from the predeploy slot -/

/-- `_getFeeFromContract(CONSOLIDATION_REQUEST)` reads `7` through the
line-84 `staticcall("")` against the concrete predeploy body. -/
example : feeOf (getConsolidationRequestFee predeployStaticBody ctx inbox (before 14)) =
    some 7 := by native_decide

/-! ### Committed batch, no frame premises -/

example : isOk committed = true := by native_decide

/-- One line-115 request per zipped pair, at the read fee. -/
example : committed.attempts.map (·.request) =
    [⟨vault, inbox, Live.word 7, blob 11 ++ blob 21⟩,
     ⟨vault, inbox, Live.word 7, blob 12 ++ blob 22⟩] := by
  native_decide

example : committed.attempts.map (·.accepted) = [true, true] := by native_decide

/-- Exactly `msg.value = 2 * fee` moved from the vault to the predeploy. -/
example : committed.world.balances vault = 0 := by native_decide
example : committed.world.balances inbox = 14 := by native_decide

/-- Two accepted requests counted. -/
example : (committed.world.core.readContractSlot inbox.val predeployCountSlot).val = 2 := by
  native_decide

/-- Queue words retain all 96 octets of each request, in order. -/
example : (List.range 3).map
      (fun i => committed.world.core.readContractSlot inbox.val (predeployQueueSlot + i)) =
    (List.range 3).map (requestWord (blob 11 ++ blob 21)) := by
  native_decide

example : (List.range 3).map
      (fun i => committed.world.core.readContractSlot inbox.val (predeployQueueSlot + 3 + i)) =
    (List.range 3).map (requestWord (blob 12 ++ blob 22)) := by
  native_decide

/-- The fee slot is untouched by the body. -/
example : (committed.world.core.readContractSlot inbox.val predeployFeeSlot).val = 7 := by
  native_decide

/-- The predeploy commits no logs: exactly the vault's two line-120 events. -/
example : committed.world.logs.map (·.emitter) = [vault, vault] := by native_decide
example : committed.world.logs.map (·.name) =
    ["ConsolidationRequestAdded", "ConsolidationRequestAdded"] := by native_decide

/-! ### Guards against the read fee -/

/-- `msg.value ≠ requestsCount * fee` for the read fee: `IncorrectFee`, no hop. -/
example : (run 13).outcome = .error (.reason "IncorrectFee") := by native_decide
example : (run 13).attempts = [] := by native_decide

/-- Code-less predeploy address: the low-level STATICCALL answers empty
success and the caller-side 32-byte check rejects it (`FeeInvalidData`). -/
private def codelessWorld : World :=
  ⟨Verity.defaultState.writeContractSlot inbox.val predeployFeeSlot (Live.word 7),
    fun a => if a = vault then 14 else 0, []⟩

example : (executeVault predeployBody predeployStaticBody ctx gateway inbox (Live.word 14)
    sources targets codelessWorld).outcome = .error (.reason "FeeInvalidData") := by
  native_decide

/-! ### Body arms -/

/-- A 48-octet request (not 96) is rejected with empty data. -/
example : rejectedData (predeployBody ⟨vault, inbox, Live.word 7, blob 11⟩ (before 14)) =
    some [] := by native_decide

/-- Underpayment against the fee slot is rejected with empty data. -/
example : rejectedData
    (predeployBody ⟨vault, inbox, Live.word 6, blob 11 ++ blob 21⟩ (before 14)) = some [] := by
  native_decide

/-- The body reads the fee slot of the credited world it is handed: value `7`
against a slot holding `8` is underpayment and rejects. -/
private def slot8Core : Verity.ContractState :=
  core.writeContractSlot inbox.val predeployFeeSlot (Live.word 8)

example : rejectedData (predeployBody ⟨vault, inbox, Live.word 7, blob 11 ++ blob 21⟩
    ⟨slot8Core, fun _ => 0, []⟩) = some [] := by native_decide

/-- Whole batch against a slot holding `8` with `msg.value = 14`: the fee read
returns `8`, `2 * 8 ≠ 14`, `IncorrectFee` before any hop. -/
example : (executeVault predeployBody predeployStaticBody ctx gateway inbox (Live.word 14)
    sources targets ⟨slot8Core, fun a => if a = vault then 14 else 0, []⟩).outcome =
      .error (.reason "IncorrectFee") := by native_decide

end LidoSRv3.Tests.TrioConsolidation.Predeploy
