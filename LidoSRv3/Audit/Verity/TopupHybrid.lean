import LidoSRv3.Audit.Source.TopupCorrespondence
import Verity.Core
import Verity.Macro
import Contracts.Common

/-!
# P-TOPUP-1 hybrid Verity transaction bridge

This module connects the independent, pinned-source-shaped P-TOPUP-1
interpreter to an actual `Verity.Contract.run` transaction.  The typed contract
contains the two value-bearing external-call sites from the pinned program:

* `Lido.withdrawDepositableEther(amount)`, reached from
  `StakingRouter.sol` line 744; and
* `BeaconChainDepositor.makeBeaconChainTopUp(..., amounts)`, reached from line
  750 and represented here by its proved aggregate value.

The source interpreter remains authoritative for the full guard order, array
shape, per-key loop, empty commit, and call-failure branches.  The Verity
transaction begins at the explicitly named hybrid boundary after those source
facts have been evaluated.  Its executable wrapper proves commit/revert
classification and snapshot rollback; its compilation model records the two
external calls and the conservation/balance checks.

This is deliberately not an EVM theorem.  Verity's executable linked-external
wrappers are summaries, not multi-contract EVM execution; generated Yul,
runtime bytecode, deployed addresses/storage, and call-world effects remain
open.  EVMYulLean is pinned transitively at
`f7e4ee0dc8f8d5265ce822a937ab5be771f182e9`, but is not used to overstate that
open plane.  Likewise Verity #2242 proves a packed TopUpGateway storage feature;
it does not establish this complete P-TOPUP-1 transaction guarantee.
-/

namespace LidoSRv3.Audit.Verity.TopupHybrid

open _root_.Verity
open _root_.Contracts
open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityTopup

/- Typed transaction suffix.  `sourceReverts` is the explicit refinement
boundary to the independently defined `SolidityTopup.run`; the remaining
arguments are observations proved from that source outcome. -/
verity_contract TopupTxContract where
  storage
  linked_externals
    external withdrawDepositableEther(Uint256)
    external makeBeaconChainTopUp(Uint256)

  function reentrancy_trusted executeTopup
      (sourceReverts : Bool, pulled : Uint256, pushed : Uint256,
       balancePreserved : Bool) : Unit := do
    require (sourceReverts == false) "SOURCE_TOPUP_REVERTED"
    require (pulled == pushed) "TOPUP_VALUE_MISMATCH"
    externalCallBind [] "withdrawDepositableEther" [pulled]
    externalCallBind [] "makeBeaconChainTopUp" [pushed]
    require balancePreserved "ROUTER_BALANCE_CHANGED"

  function no_external_calls executeNoTopup
      (sourceReverts : Bool, pulled : Uint256, pushed : Uint256) : Unit := do
    require (sourceReverts == false) "SOURCE_TOPUP_REVERTED"
    require (pulled == pushed) "TOPUP_VALUE_MISMATCH"

  /- A revert raised by `Lido.withdrawDepositableEther`: the value-bearing
  pull site is reached, but the beacon suffix is not. -/
  function reentrancy_trusted executePullRevert (pulled : Uint256) : Unit := do
    externalCallBind [] "withdrawDepositableEther" [pulled]
    require false "SOURCE_TOPUP_REVERTED_DURING_PULL"

  /- A revert raised after the Lido pull succeeded, while executing the
  beacon-depositor suffix.  Both call sites are reached before rollback. -/
  function reentrancy_trusted executePushRevert
      (pulled : Uint256, pushed : Uint256) : Unit := do
    externalCallBind [] "withdrawDepositableEther" [pulled]
    externalCallBind [] "makeBeaconChainTopUp" [pushed]
    require false "SOURCE_TOPUP_REVERTED_DURING_PUSH"

inductive TxStatus where
  | committed
  | reverted
  deriving DecidableEq, Repr

structure TxView where
  status : TxStatus
  before : ContractState
  after : ContractState

/-- Independent transaction reading of the pinned source outcome. -/
def sourceTx (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (before : ContractState) : TxView :=
  if (run cfg inp).reverts then
    ⟨.reverted, before, before⟩
  else
    ⟨.committed, before, before⟩

def observeVerity (before : ContractState) (result : ContractResult Unit) : TxView :=
  match result with
  | .success _ after => ⟨.committed, before, after⟩
  | .revert _ rollback => ⟨.reverted, before, rollback⟩

/-- The actual executable Verity transaction fed by the independent source
interpreter.  The suffix is observational: it has no local storage writes. -/
def executeSource (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Contract Unit :=
  match run cfg inp with
  | .revertLidoCannotDeposit | .revertLidoZeroAmount | .revertLidoNotEnoughEther =>
      TopupTxContract.executePullRevert (totalAllocated inp)
  | .revertArrayLengthMismatch | .revertInvalidPublicKeyLength
  | .revertDepositAmountTooLow | .revertAmountTooLarge
  | .revertInsufficientRouterBalance =>
      TopupTxContract.executePushRevert (totalAllocated inp) (pushedValue inp)
  | .revertAssertBalanceUnchanged =>
      TopupTxContract.executeTopup false (totalAllocated inp) (pushedValue inp) false
  | .committedTopUp _ pulled pushed _ =>
      TopupTxContract.executeTopup false pulled pushed true
  | .committedNoTopUp => TopupTxContract.executeNoTopup false 0 0
  | _ => TopupTxContract.executeNoTopup true 0 0

/-- Adequacy of the hybrid boundary: source conservation discharges the typed
program's equality guard, and every source revert is normalized by
`Contract.run` to the exact pre-call snapshot. -/
theorem verity_tx_simulates_source
    (cfg : SourceTopupConfig) (inp : SourceTopupInput) (state : ContractState) :
    observeVerity state ((executeSource cfg inp).run state) = sourceTx cfg inp state := by
  have hconserves := run_conserves cfg inp
  cases hrun : run cfg inp <;>
    simp [executeSource, sourceTx, observeVerity, TopupTxContract.executeTopup,
      TopupTxContract.executeNoTopup, TopupTxContract.executePullRevert,
      TopupTxContract.executePushRevert, _root_.Verity.require,
      _root_.Contracts.externalCallBind, _root_.Verity.Contract.run,
      _root_.Verity.bind, _root_.Verity.pure, Bind.bind, Pure.pure,
      Outcome.reverts, Outcome.pulled, Outcome.pushed, hrun] at hconserves ⊢
  case revertAssertBalanceUnchanged =>
    by_cases heq : Core.Uint256.ofNat (totalAllocated inp) =
        Core.Uint256.ofNat (pushedValue inp) <;> simp [heq]
  case committedTopUp =>
    subst_vars
    simp

/-- Explicit rollback half, stated directly on `Contract.run`. -/
theorem verity_revert_restores_snapshot
    (cfg : SourceTopupConfig) (inp : SourceTopupInput) (state rollback : ContractState)
    (reason : String)
    (h : (executeSource cfg inp).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

/-- The value-conservation half reused at the exact source/Verity boundary. -/
theorem source_value_observation_adequate
    (cfg : SourceTopupConfig) (inp : SourceTopupInput) :
    (run cfg inp).pulled = (run cfg inp).pushed :=
  run_conserves cfg inp

end LidoSRv3.Audit.Verity.TopupHybrid
