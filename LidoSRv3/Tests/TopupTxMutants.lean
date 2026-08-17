import LidoSRv3.Audit.Verity.TopupTx

namespace LidoSRv3.Tests.TopupTxMutants

open Verity
open Contracts
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Verity.TopupTx

private def twoBatch : List Nat := [11, 13]

/-- Positive two-batch chaining: both allocation writes contribute to the
running total and both beacon calls retain their individual values. -/
example : allocSum twoBatch = 24 := by decide
example : (beaconJournal twoBatch 0).map (·.value) = [11, 13] := by decide
example : callValue "makeBeaconChainTopUp" (expectedCalls twoBatch) = 24 := by decide

/-- Omission and duplicate/reuse mutants are fail-closed by the call journal. -/
private def omitSecond : List ExternalCall := beaconJournal [11] 0
private def duplicateFirst : List ExternalCall := beaconJournal [11, 11] 0
private def reuseAggregate : List ExternalCall := beaconJournal [24] 0

theorem omitted_second_batch_rejected : beaconJournal twoBatch 0 != omitSecond := by decide
theorem duplicated_first_batch_rejected : beaconJournal twoBatch 0 != duplicateFirst := by decide
theorem reused_aggregate_batch_rejected : beaconJournal twoBatch 0 != reuseAggregate := by decide

/-- A failure after real intermediate writes is normalized to the exact input
snapshot by `Contract.run`. -/
theorem allocation_write_failure_rolls_back (state : ContractState) :
    (execute twoBatch .afterAllocationWrite).run state =
      .revert "FAIL_AFTER_ALLOCATION_WRITE" state := by rfl

theorem lido_pull_failure_rolls_back (state : ContractState) :
    (execute twoBatch .afterLidoPull).run state =
      .revert "FAIL_AFTER_LIDO_PULL" state := by rfl

theorem first_beacon_failure_rolls_back (state : ContractState) :
    (execute twoBatch .afterFirstBeaconPush).run state =
      .revert "FAIL_AFTER_FIRST_BEACON_PUSH" state := by rfl

end LidoSRv3.Tests.TopupTxMutants
