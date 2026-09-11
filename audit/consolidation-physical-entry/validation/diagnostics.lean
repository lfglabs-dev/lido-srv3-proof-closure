import LidoSRv3.Tests.TrioConsolidation.PhysicalEntrySettlement
open LidoSRv3.Audit.Source.TrioReserve1 LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Tests LidoSRv3.Tests.ConsolidationSettlementRegression

def diagnostics : IO Unit := do
  let base := TrioConsolidation.PhysicalQuotaSettlement.entry
  let roleKey := audit.trio.consolidation.PhysicalEntrySettlement.roleSlot ctx.sender
  let granted := base.core.writeContractSlot ctx.self.val roleKey (Live.word (2^255+2))
  let granted := granted.writeContractSlot ctx.self.val audit.trio.consolidation.PhysicalEntrySettlement.resumeSlot (Live.word 100)
  let w := {base with core := granted}
  let go := fun refund world => audit.trio.consolidation.PhysicalEntrySettlement.execute (dispatch refund)
    TrioConsolidation.PhysicalQuotaSettlement.quotaFees ctx (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups world
  let success := go TrioConsolidation.PhysicalQuotaSettlement.quotaRefund w
  unless success.outcome == .ok () && success.trace.length == 7 &&
      success.world.core.readContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position == TrioConsolidation.PhysicalQuotaSettlement.expectedQuota &&
      (success.world.core.readContractSlot 300 777).val == 2 && (success.world.core.readContractSlot 400 888).val == 42 do
    throw (IO.userError s!"physical Keccak/normal-time full success: {repr success.outcome}")
  let denied := go refundReject {w with core := w.core.writeContractSlot 100 roleKey (Live.word (2^255)),balances := fun _ => 0}
  unless denied.outcome == .error (.bubbled (audit.trio.consolidation.PhysicalEntrySettlement.unauthorized ctx.sender)) && denied.suffix.isNone do
    throw (IO.userError "role must reject before balance/pause")
  let charged := go refundReject {w with balances := (fun _ => 0), core := w.core.writeContractSlot 100 audit.trio.consolidation.PhysicalEntrySettlement.resumeSlot (Live.word 101)}
  unless charged.outcome == .error audit.trio.consolidation.PhysicalQuotaSettlement.arithmetic && charged.suffix.isNone do
    throw (IO.userError "balance must reject before pause")
  let paused := go refundReject {w with core := w.core.writeContractSlot 100 audit.trio.consolidation.PhysicalEntrySettlement.resumeSlot (Live.word 101)}
  unless paused.outcome == .error (.bubbled (encode 4 0x14378398)) && paused.suffix.isNone do
    throw (IO.userError "pause before quota")
  let late := go refundReject w
  unless late.outcome == .error (.reason "FeeRefundFailed") && late.trace.length == 7 &&
      late.world.core.readContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position == base.core.readContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position &&
      late.world.core.readContractSlot 100 roleKey == w.core.readContractSlot 100 roleKey &&
      (late.world.core.readContractSlot 300 777).val == 0 do
    throw (IO.userError "late original entry rollback")
  let wrong := audit.trio.consolidation.PhysicalEntrySettlement.gates {ctx with sender := addr 17} (Live.word 6) w
  unless wrong == .error (.bubbled (audit.trio.consolidation.PhysicalEntrySettlement.unauthorized (addr 17))) do
    throw (IO.userError "actual caller mapping")
  let rows ← IO.FS.readFile "audit/consolidation-physical-entry/validation/mapping-vectors.tsv"
  for line in rows.splitOn "\n" do
    if line.isEmpty then continue
    let fields := line.splitOn "\t"
    let some caller := fields[0]!.toNat? | throw (IO.userError "bad caller")
    let some expected := fields[1]!.toNat? | throw (IO.userError "bad slot")
    unless audit.trio.consolidation.PhysicalEntrySettlement.roleSlot (addr caller) == expected do
      throw (IO.userError "independent nested Keccak vector")
  IO.println "PASS 6 pure-native execution groups: actual Keccak normal-time complete success, role/balance/pause priorities, late rollback, actual caller mapping;4 independent nested64-byte Keccak vectors. Pure Keccak definition with EvmYul byte-array runtime support."
#eval diagnostics
