import LidoSRv3.Audit.Source.ReportRewardsMintedCorrespondence
import LidoSRv3.Audit.Verity.ReportRewardsMintedTx

/-! ## Vocabulary
P-MINT-CONSUMER-1 covers the router-snapshot re-read, fee split, distribution,
and callback-last try/catch consumer path.  It intentionally registers no
Guarantee entry; registry wiring is deferred. -/
namespace LidoSRv3.Audit.Guarantees.PMintConsumer1

open LidoSRv3.Audit.SolidityAccounting.ReportRewardsMinted
open LidoSRv3.Audit.Verity.ReportRewardsMintedTx

theorem abstract_rereads_written_router_snapshot (balances fees : List Nat) :
    getStakingRewardsDistribution (writeValidatorBalances balances fees) = fees :=
  consumer_rereads_writer balances fees

theorem verity_observe_eq_sourceView (i : Input) (s : Verity.ContractState) :
    observe ((reportRewardsMinted i).run s) = sourceView i :=
  observe_eq_sourceView i s

theorem verity_revert_restores_snapshot (i : Input) (s r : Verity.ContractState)
    (reason : String) (h : (reportRewardsMinted i).run s = .revert reason r) : r = s :=
  revert_restores_snapshot i s r reason h

end LidoSRv3.Audit.Guarantees.PMintConsumer1
