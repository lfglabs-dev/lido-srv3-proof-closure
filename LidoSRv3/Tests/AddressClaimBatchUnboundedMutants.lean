import LidoSRv3.Audit.Verity.AddressClaimBatchUnbounded

/-! P-ADDRESS-1 unbounded claim-batch receipt vectors. -/

namespace LidoSRv3.Tests.AddressClaimBatchUnboundedMutants

open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Verity.AddressClaimBatchUnbounded

/-- Empty batch is the nil unit-receipt map
(`WithdrawalQueue.sol:244-256`). -/
theorem empty_batch_is_nil_map (state : Verity.ContractState)
    (recipient : Verity.Address) :
    BatchUnits state [] [] recipient [] state :=
  BatchUnits.nil state recipient

/-- Swapping the two `_sendValue` CALLs disagrees with the inductive
receipt journal (`WithdrawalQueueBase.sol:477`). -/
theorem reordered_calls_rejected :
    reorderedCalls [30, 40] (2 : Verity.Address) ≠
      [payoutEntry (2 : Verity.Address) 30, payoutEntry (2 : Verity.Address) 40] :=
  reordered_calls_refute_two_item

/-- The historical two-item parent shape is the length-two instance of
the unit-receipt map: CALL order is `(30, 40)` whenever `BatchUnits`
records those payouts. -/
theorem two_item_parent_is_unit_map
    {state after : Verity.ContractState} {receipts : List UnitReceipt}
    (h : BatchUnits state [1, 2] [1, 1] (2 : Verity.Address) receipts after)
    (hp : receipts.map UnitReceipt.payout = [30, 40]) :
    receipts.map UnitReceipt.call =
      [payoutEntry (2 : Verity.Address) 30, payoutEntry (2 : Verity.Address) 40] :=
  (two_item_parent_instance h (by decide) hp).1

#print axioms LidoSRv3.Audit.Verity.AddressClaimBatchUnbounded.observe_eq_map_unit
#print axioms LidoSRv3.Audit.Verity.AddressClaimBatchUnbounded.two_item_parent_instance
#print axioms LidoSRv3.Audit.Verity.AddressClaimBatchUnbounded.reordered_calls_refute_two_item

end LidoSRv3.Tests.AddressClaimBatchUnboundedMutants
