import LidoSRv3.Audit.Verity.TopupRollback

namespace LidoSRv3.Audit.Verity.Tests.TopupRollback

open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Verity.TopupRollback

def nominal : SourceTopupInput :=
  { callerIsTopUpGateway := true
    keyIndicesLength := 2
    operatorIdsLength := 2
    topUpLimits := [2 * pinnedConfig.minDeposit, 2 * pinnedConfig.minDeposit]
    pubkeyLengths := [48, 48]
    moduleExists := true
    moduleActive := true
    wcTypeIsType2 := true
    maxTopUpPerBlockGwei := 4 * pinnedConfig.minDeposit / pinnedConfig.gwei
    moduleAllocationEth := 4 * pinnedConfig.minDeposit
    lidoCanDeposit := true
    allocations := [pinnedConfig.minDeposit, 2 * pinnedConfig.minDeposit]
    routerBalanceBefore := 7
    lidoDepositableEther := 4 * pinnedConfig.minDeposit }

#guard totalAllocated nominal = 3 * pinnedConfig.minDeposit
#guard (run pinnedConfig nominal).pulled = (run pinnedConfig nominal).pushed
#guard (Compiler.CompilationModel.compile spec [topUpSelector]).isOk

def rollbackVector : Bool :=
  let unauthorized := { nominal with callerIsTopUpGateway := false }
  let tx := transactionObservation (topupProgram pinnedConfig unauthorized (17 : Nat)) 999 []
    { calls := [], ethMoves := [{ sender := 1, recipient := 2, amount := ⟨3⟩ }], logs := [] }
  decide (tx.committedState = 17 ∧ tx.committedTrace.ethMoves = [] ∧ tx.committedTrace.logs = [])

#guard rollbackVector

/- Mutating one extracted allocation changes the exact top-up amount. -/
#guard totalAllocated { nominal with allocations := [pinnedConfig.minDeposit] } ≠
  totalAllocated nominal

#check topup_program_declared
#check topup_success_post_state_equiv
#check topup_rollback_restores_state
#check topup_allocation_extracted_from_pinned_source
#check topup_amount_extraction_correct
#check topup_call_world_rollback

end LidoSRv3.Audit.Verity.Tests.TopupRollback
