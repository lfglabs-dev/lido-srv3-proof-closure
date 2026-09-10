import LidoSRv3.Audit.Source.AccountingCorrespondence
import LidoSRv3.Audit.Verity.HandleOracleReportTx
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAccount1

open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Verity.HandleOracleReportTx

def guarantee : Guarantee := ⟨.pAccount1, [.model, .source, .verityTx]⟩

/-! ## Vocabulary

The registered abstract statement is the one-liner
`mint_after_read_discipline : mintAfterReadDiscipline`.  The three names below
are the definitions it unfolds to; they live in
`LidoSRv3.Audit.Verity.HandleOracleReportTx` and are only re-exported here
under their English reading so the statement can be read without leaving this
file. -/

/-- "The read step is stamped strictly before any nonzero mint step", over the
two raw ticks: `0 < mintTick → readTick < mintTick`. -/
abbrev mintAfterRead := LidoSRv3.Audit.Verity.HandleOracleReportTx.mintAfterRead

/-- "On every committed execution of `tx`, the `rewardsReadSlot` tick is
`mintAfterRead` the `rewardsMintedSlot` tick", for every input, fee and
starting state; a reverting execution claims nothing. -/
abbrev mintAfterReadDisciplineOf :=
  LidoSRv3.Audit.Verity.HandleOracleReportTx.mintAfterReadDisciplineOf

/-- "The modeled `handleOracleReport` has mint-after-read discipline":
`mintAfterReadDisciplineOf` applied to the real transaction. -/
abbrev mintAfterReadDiscipline :=
  LidoSRv3.Audit.Verity.HandleOracleReportTx.mintAfterReadDiscipline

/-- Child: source-plane constructor order only, not the registered P-ACCOUNT-1
parent. The retired child has no `fullReportSucceeds` binder: if the locally
modeled `sourceTraceRetired` accepts and fee shares are strictly positive,
then its trace is exactly
`[balancesWritten b, accountingCalled, rewardsRead b, rewardsMinted]`
for one shared `b`. This is the constructor order of `successfulSteps`,
not `submitReportData`. `successfulSteps` is a hardcoded four-constructor
list, so this fact
carries no kill-line of its own: see `mint_after_read_discipline` for the
registered parent that the `mint_order_kill_line` mutant actually refutes. -/
theorem source_report_before_reward
    (i : LidoSRv3.Audit.SolidityAccounting.ReportInput)
    (sharesToMintAsFees : Nat)
    (hFees : 0 < sharesToMintAsFees)
    (trace : List LidoSRv3.Audit.SolidityAccounting.Step)
    (h : LidoSRv3.Audit.SolidityAccounting.sourceTraceRetired i
      sharesToMintAsFees = some trace) :
    ∃ balances, trace = [
      .balancesWritten balances, .accountingCalled,
      .rewardsRead balances, .rewardsMinted] :=
  LidoSRv3.Audit.SolidityAccounting.source_report_before_reward_retired
    i sharesToMintAsFees hFees trace h

/-- **P-ACCOUNT-1, Verity plane.**  `observe` of `handleOracleReport` equals
`sourceView`.

Verity child. `observe` of `handleOracleReport` (balance array + total/flag
slots) equals the independently stated `sourceView`. Not `submitReportData`;
`sharesToMintAsFees` is an argument, not a computed fee. -/
theorem verity_tx_simulates_oracle_report
    (i : ReportInput) (sharesToMintAsFees : Nat) (state : Verity.ContractState) :
    observe i ((handleOracleReport i sharesToMintAsFees).run state) =
      sourceView i sharesToMintAsFees :=
  verity_tx_simulates_pinned_source i sharesToMintAsFees state

/-- On every reverting executable Verity transition the pre-call snapshot
is restored, including after intermediate mapping and slot writes. -/
theorem verity_tx_revert_restores_snapshot
    (i : ReportInput) (sharesToMintAsFees : Nat) (inject : Bool)
    (state rollback : Verity.ContractState) (reason : String)
    (h : (handleOracleReport i sharesToMintAsFees inject).run state =
      .revert reason rollback) :
    rollback = state :=
  revert_restores_snapshot i sharesToMintAsFees inject state rollback reason h

/-- **P-ACCOUNT-1, abstract plane.**  On every committed execution of the
modeled `handleOracleReport`, the `rewardsRead` step is written strictly before
any nonzero `rewardsMinted` step, read directly from the transaction step
clock: whenever `0 < tick(mint)`, then `tick(read) < tick(mint)`.

Registered P-ACCOUNT-1 parent. Independent tx-storage-flag order
discipline: on every committed execution of the real `handleOracleReport`,
the `rewardsReadSlot` tick is written strictly before any nonzero
`rewardsMintedSlot` tick. This reads the two raw ticks directly and does not
go through `storedSteps`; exact expected ticks make the same reordering visible
at the `View` boundary, but this theorem states the order predicate directly
rather than obtaining it through source-view equality. `Result.steps` (and the
`View.steps` it feeds) is built from these same tx storage flags and never
calls `AccountingCorrespondence.successfulSteps`; the two planes share no
step-list bridge. Unlike the demoted `source_report_before_reward` child,
this parent is directly refuted by the `mint_order_kill_line` mutant below,
so the registered claim has an adversarial witness rather than being true by
construction. The ticks are not call-site constants: every step write goes
through `stampStep`, which reads the transaction-local step clock in
`sequenceSlot` and stores `clock + 1`, so the number a slot ends up holding is
the position at which that write actually ran. Moving a `stampStep` call
therefore changes the tick it records, which is what makes this an ordering
claim rather than a fact about which numeral a line of program text
contains. -/
theorem mint_after_read_discipline : mintAfterReadDiscipline :=
  mintAfterReadDiscipline_holds

/-- Kill-line for the registered parent `mint_after_read_discipline`.
`handleOracleReportMintBeforeRead` is a pure call-site reordering of the real
transaction: the `stampStep rewardsMintedSlot` call moves above the
`stampStep rewardsReadSlot` call, and nothing else changes — every slot
binding is identical and no literal is edited, the same fault as calling
`reportRewardsMinted` before re-reading the freshly written balances. Because
`stampStep` takes its tick from the step clock rather than from the call site,
the mint step now records `2` and the read step `3`, violating
`mintAfterReadDisciplineOf` for that mutant — the same predicate the
registered parent proves for the real transaction. This closes the reordering
gap `report/P-ACCOUNT-1.md` issue 5 previously disclosed as open. If a future
edit merges the two tick writes back into a shared order-insensitive flag, or
reverts them to per-call-site constants, this theorem's witness fails and the
regression is caught here, not only by informal review. -/
theorem mint_order_kill_line : mintOrderKillLine :=
  mintOrderKillLine_holds

end LidoSRv3.Audit.Guarantees.PAccount1
