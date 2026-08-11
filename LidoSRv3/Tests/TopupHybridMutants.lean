import LidoSRv3.Audit.Verity.TopupHybrid

namespace LidoSRv3.Tests.TopupHybridMutants

open _root_.Verity
open LidoSRv3.Audit.Verity.TopupHybrid

private def state : ContractState := { defaultState with sender := 17 }

private def revertedWith (expected : String) (result : ContractResult Unit) : Bool :=
  match result with
  | .revert reason rollback => reason == expected && rollback.sender == state.sender
  | .success _ _ => false

/- A mutant that lets the source-revert flag pass is rejected before either
external call and `Contract.run` exposes the original snapshot. -/
#guard revertedWith "SOURCE_TOPUP_REVERTED"
  ((TopupTxContract.executeTopup true 7 7 true).run state)

/- Pulling and pushing different aggregate values is a transaction revert. -/
#guard revertedWith "TOPUP_VALUE_MISMATCH"
  ((TopupTxContract.executeTopup false 7 8 true).run state)

/- A mutant that strands value in the router is rejected after the two declared
call sites by the balance observation. -/
#guard revertedWith "ROUTER_BALANCE_CHANGED"
  ((TopupTxContract.executeTopup false 7 7 false).run state)

/- The zero-top-up commit uses the call-free entrypoint. -/
#guard match (TopupTxContract.executeNoTopup false 0 0).run state with
  | .success _ after => after.sender == state.sender
  | .revert _ _ => false

#check verity_tx_simulates_source
#check verity_revert_restores_snapshot
#check source_value_observation_adequate

end LidoSRv3.Tests.TopupHybridMutants
