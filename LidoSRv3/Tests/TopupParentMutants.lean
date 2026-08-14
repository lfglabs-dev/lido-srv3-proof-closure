import LidoSRv3.Audit.Guarantees.PTopup1

namespace LidoSRv3.Tests.TopupParentMutants

open _root_.Verity
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.SolidityTopupParent
open LidoSRv3.Audit.Verity.TopupParent

set_option maxRecDepth 5000

private def cfg : SourceTopupConfig :=
  { pubkeyLength := 48, publicKeyLength := 48, gwei := 1, minDeposit := 1,
    uint64Max := uint256Modulus + 1 }

private def base : SourceTopupInput :=
  { callerIsTopUpGateway := false
    keyIndicesLength := 2
    operatorIdsLength := 2
    topUpLimits := [uint256Modulus + 1, uint256Modulus + 1]
    pubkeyLengths := [48, 48]
    moduleExists := true
    moduleActive := true
    wcTypeIsType2 := true
    maxTopUpPerBlockGwei := uint256Modulus + 1
    moduleAllocationEth := uint256Modulus + 1
    lidoCanDeposit := true
    allocations := []
    routerBalanceBefore := uint256Modulus
    lidoDepositableEther := uint256Modulus + 1 }

private def ok : CallResponse := ⟨.success, []⟩
private def failed : CallResponse := ⟨.failure, [0xde, 0xad]⟩

private def iface (allocations : List Nat) : CalleeInterface :=
  { allocation := ⟨ok, allocations⟩, lidoPull := ok,
    beaconPushes := allocations.filterMap (fun amount => if amount = 0 then none else some ok) }

private def gateway : Address := 17
private def authorized : ContractState := { defaultState with sender := gateway }
private def unauthorized : ContractState := { defaultState with sender := 18 }

/- Authentication is the first parent guard and no call is attempted. -/
#guard (sourceExecute cfg base gateway unauthorized.sender (iface [1, 1])).result =
  .reverted (.source .revertNotAuthorized)
#guard (sourceExecute cfg base gateway unauthorized.sender (iface [1, 1])).calls = []

/- A short positive module return reaches the Beacon array-shape guard. -/
#guard (sourceExecute cfg base gateway authorized.sender (iface [1])).result =
  .reverted (.source .revertArrayLengthMismatch)

/- A short zero-sum return is the successful empty commit at line 741.  The
allocation call remains observable and neither value-bearing call occurs. -/
#guard (sourceExecute cfg base gateway authorized.sender (iface [0])).result =
  .committedNoTopUp
#guard (sourceExecute cfg base gateway authorized.sender (iface [0])).calls.length = 1

/- Allocation-module failure is a parent revert with its returndata retained. -/
private def allocationFailed : CalleeInterface :=
  { allocation := ⟨failed, [1, 1]⟩, lidoPull := ok, beaconPushes := [ok, ok] }
#guard (sourceExecute cfg base gateway authorized.sender allocationFailed).result =
  .reverted .allocationCallFailed

/- Failed Lido pull and failed Beacon push remain distinct parent failures. -/
private def lidoFailed : CalleeInterface :=
  { allocation := ⟨ok, [1, 1]⟩, lidoPull := failed, beaconPushes := [ok, ok] }
#guard (sourceExecute cfg base gateway authorized.sender lidoFailed).result =
  .reverted .lidoPullCallFailed

private def beaconFailed : CalleeInterface :=
  { allocation := ⟨ok, [1, 1]⟩, lidoPull := ok, beaconPushes := [ok, failed] }
#guard (sourceExecute cfg base gateway authorized.sender beaconFailed).result =
  .reverted .beaconPushCallFailed

/- `MAX_UINT256 + 2` wraps to one at line 732.  With enough pre-existing router
balance the push is fundable, so the source reaches and fails the line-755
amount/balance assertion instead of silently using an unbounded sum. -/
private def wrapping : CalleeInterface := iface [uint256Modulus - 1, 2]
#guard accumulated { base with allocations := wrapping.allocation.allocations } = 1
#guard (sourceExecute cfg base gateway authorized.sender wrapping).result =
  .reverted (.source .revertAssertBalanceUnchanged)

/- Every high-risk failure above is normalized by executable `Contract.run` to
the exact caller snapshot. -/
#guard match (execute cfg base gateway wrapping).run authorized with
  | .revert _ rollback => rollback.sender == authorized.sender &&
      rollback.selfBalance == authorized.selfBalance
  | .success _ _ => false

/- Positive parent commit: equal accumulated/pushed amount and all three calls. -/
#guard (sourceExecute cfg base gateway authorized.sender (iface [1, 1])).result =
  .committedTopUp 2
#guard (sourceExecute cfg base gateway authorized.sender (iface [1, 1])).calls.length = 4

#check LidoSRv3.Audit.Guarantees.PTopup1.parent_verity_transaction_closure
#check parent_transaction_closure
#check revert_restores_caller_frame

end LidoSRv3.Tests.TopupParentMutants
