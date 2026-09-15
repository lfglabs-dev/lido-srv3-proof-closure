import LidoSRv3.Audit.Source.AccountingCorrespondence
import LidoSRv3.Audit.Verity.HandleOracleReportTx
import LidoSRv3.Audit.Guarantees.Registry
import ReportFeeMint

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

The registered parent also covers modeled write-before-read ordering. The
source first [pushes validator balances](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.9/oracle/AccountingOracle.sol#L513-L521)
and later [reads rewards distribution](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.9/Accounting.sol#L265-L277).
Connecting these modeled steps to the actual cross-contract execution and
fee calculation remains required. -/
theorem mint_after_read_discipline : mintAfterReadDiscipline :=
  mintAfterReadDiscipline_holds

/-- "The balances write is stamped strictly before any nonzero read step",
over the two raw ticks: `0 < readTick → balancesTick < readTick`. -/
abbrev writeRouterBeforeRead :=
  LidoSRv3.Audit.Verity.HandleOracleReportTx.writeRouterBeforeRead

/-- "On every committed execution of `tx`, the `balancesWrittenSlot` tick is
`writeRouterBeforeRead` the `rewardsReadSlot` tick". -/
abbrev writeRouterBeforeReadDisciplineOf :=
  LidoSRv3.Audit.Verity.HandleOracleReportTx.writeRouterBeforeReadDisciplineOf

/-- Write-router-before-read discipline applied to the modeled transaction. -/
abbrev writeRouterBeforeReadDiscipline :=
  LidoSRv3.Audit.Verity.HandleOracleReportTx.writeRouterBeforeReadDiscipline

/-- Combined write-before-read and read-before-mint discipline on the same
modeled transaction, corresponding to the intended cross-contract source path. -/
abbrev routerAccountingOrderDisciplineOf :=
  LidoSRv3.Audit.Verity.HandleOracleReportTx.routerAccountingOrderDisciplineOf

/-- Combined ordering discipline applied to the modeled transaction. -/
abbrev routerAccountingOrderDiscipline :=
  LidoSRv3.Audit.Verity.HandleOracleReportTx.routerAccountingOrderDiscipline

/-- **P-ACCOUNT-1, abstract plane.**

On every committed execution of the modeled `handleOracleReport`, the
transaction step clock records both orderings:

1. the modeled router-balances write precedes the modeled rewards read;
2. the rewards read precedes any nonzero modeled fee mint.

These ticks do not establish that `sharesToMintAsFees` was computed from
the report, prestate or router distribution: it is still a caller-supplied
argument. The source's actual fee producer and public cross-contract
transport must be connected separately. In particular, ordering alone does
not prove that a minted amount uses the just-written module weights.

The ticks are `stampStep`'s reads of the transaction-local `sequenceSlot`
clock (reset at the top of the commit branch), not per-call-site constants,
so this is an ordering claim about execution and not about which numeral
appears on which line. Moving either the `stampStep balancesWrittenSlot`
call below `stampStep rewardsReadSlot`, or `stampStep rewardsReadSlot` below
`stampStep rewardsMintedSlot`, without touching any literal, changes the
tick the moved write records and refutes the corresponding conjunct — see
`write_router_before_read_kill_line` and `mint_order_kill_line` below. -/
theorem router_accounting_order_discipline : routerAccountingOrderDiscipline :=
  LidoSRv3.Audit.Verity.HandleOracleReportTx.routerAccountingOrderDiscipline_holds

/-- Sub-theorem: the write-router-before-read conjunct of the registered
parent, extracted from the conjunction so it is available on its own. -/
theorem write_router_before_read_discipline : writeRouterBeforeReadDiscipline :=
  LidoSRv3.Audit.Verity.HandleOracleReportTx.writeRouterBeforeReadDiscipline_holds

/-- Kill-line for the write-router-before-read conjunct.
`handleOracleReportReadBeforeWrite` is a pure call-site reordering of the
real transaction: the `stampStep balancesWrittenSlot` call moves *below*
`stampStep rewardsReadSlot`, and nothing else changes — every slot binding
is identical and no literal is edited. Because `stampStep` sources its tick
from the clock rather than from the call site, the balances-write step now
records a strictly greater tick than the read step, violating
`writeRouterBeforeReadDisciplineOf` for that mutant — the same predicate
`write_router_before_read_discipline` proves for the real transaction. -/
theorem write_router_before_read_kill_line :
    LidoSRv3.Audit.Verity.HandleOracleReportTx.writeRouterBeforeReadKillLine :=
  LidoSRv3.Audit.Verity.HandleOracleReportTx.writeRouterBeforeReadKillLine_holds

/-- The registered ACCOUNT consumer for the physical report/write/getter/mint
path.  Its mint event is produced by the same `StETHMintShares.State` that
holds both the abstract account-share map and the packed total/external-shares
word; the share amount is not an input independent of the committed getter.
This supplements the registered parent rather than creating a P-MINT node. -/
theorem committed_fee_mint_consumes_checked_result
    (x : AccountAddress.ReportFeeMint.Input) (before post : AccountAddress.ReportFeeMint.World)
    (fee : AccountAddress.ReportWriteFee.FeeResult)
    (events : List AccountAddress.StETHMintShares.Event)
    (h : AccountAddress.ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before =
      .committed post fee events)
    (hfee : 0 < fee.sharesToMintAsFees) :
    ∃ pooled, events = [.transfer 0 before.steth.locatorAccounting pooled,
      .transferShares 0 before.steth.locatorAccounting fee.sharesToMintAsFees] :=
  AccountAddress.ReportFeeMint.committed_nonzero_mint_uses_fee_result
    x before post fee events h hfee

/-- The same consumer through the restored root transaction name. -/
theorem root_committed_fee_mint_consumes_checked_result
    (x : LidoSRv3.Audit.Verity.HandleOracleReportTx.ReportWriteFeeMintInput)
    (before post : AccountAddress.ReportFeeMint.World)
    (fee : AccountAddress.ReportWriteFee.FeeResult)
    (events : List AccountAddress.StETHMintShares.Event)
    (h : LidoSRv3.Audit.Verity.HandleOracleReportTx.handleOracleReportFromCommittedFeeProducts
      x before = .committed post fee events)
    (hfee : 0 < fee.sharesToMintAsFees) :
    ∃ pooled, events = [.transfer 0 before.steth.locatorAccounting pooled,
      .transferShares 0 before.steth.locatorAccounting fee.sharesToMintAsFees] := by
  simpa [LidoSRv3.Audit.Verity.HandleOracleReportTx.handleOracleReportFromCommittedFeeProducts]
    using AccountAddress.ReportFeeMint.committed_nonzero_mint_uses_fee_result
      { accountingAddress := x.accountingAddress, layout := x.layout, registeredModuleIds := x.registeredModuleIds,
        reportedModuleIds := x.reportedModuleIds, balancesGwei := x.balancesGwei,
        report := x.accountingReport } before post fee events h hfee

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

/-- Necessary result of the bounded report/getter/checked-fee/mint executor.
The positive branch includes authorization derived from actual success, exact
packed total/external halves, pointwise abstract account-share increase and
conversion/events on the updated mint state. No later fee transfers or router
reward callback are included in this bounded composition. -/
theorem actual_report_fee_mint
    (x : AccountAddress.ReportFeeMint.Input) (before post : AccountAddress.ReportFeeMint.World)
    (fee : AccountAddress.ReportWriteFee.FeeResult) (events : List AccountAddress.StETHMintShares.Event)
    (h : AccountAddress.ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before =
      .committed post fee events) :
    AccountAddress.ReportFeeMint.Success x before post fee events :=
  AccountAddress.ReportFeeMint.committed_success x before post fee events h

theorem actual_report_fee_mint_failure_restores
    (x : AccountAddress.ReportFeeMint.Input) (before rollback : AccountAddress.ReportFeeMint.World)
    (error : AccountAddress.ReportFeeMint.Error)
    (h : AccountAddress.ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before =
      .reverted error rollback) : rollback = before :=
  AccountAddress.ReportFeeMint.failure_restores x before rollback error h

#print axioms actual_report_fee_mint
#print axioms actual_report_fee_mint_failure_restores

end LidoSRv3.Audit.Guarantees.PAccount1
