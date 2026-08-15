import LidoSRv3.Audit.Source.DepositCorrespondence
import Verity.Core
import Verity.Macro
import Contracts.Common

/-!
# P-DEPOSIT-1 typed Verity transaction boundary

This is the bounded, source-fed transaction slice.  `SolidityDeposit.run` is
authoritative for the pinned source guard order and amounts.  The typed program
below executes the three summarized call sites with `Contract.run`; it is not a
multi-contract EVM execution claim.
-/

namespace LidoSRv3.Audit.Verity.DepositTx

open _root_.Verity
open _root_.Contracts
open LidoSRv3.Audit.SolidityDeposit

verity_contract DepositTxContract where
  storage
  linked_externals
    external obtainDepositData(Uint256)
    external withdrawDepositableEther(Uint256)
    external depositToBeacon(Uint256)

  function reentrancy_trusted execute
      (amount : Uint256, moduleOk : Bool, lidoOk : Bool, beaconOk : Bool) : Unit := do
    externalCallBind [] "obtainDepositData" [amount]
    require moduleOk "MODULE_CALL_FAILED"
    externalCallBind [] "withdrawDepositableEther" [amount]
    require lidoOk "LIDO_CALL_FAILED"
    externalCallBind [] "depositToBeacon" [amount]
    require beaconOk "BEACON_CALL_FAILED"

  function no_external_calls executeNoDeposits (_unused : Bool) : Unit := do
    require true "UNREACHABLE"

structure Balances where
  lidoDepositable : Nat
  beaconSink : Nat
  routerEth : Nat
  withdrawalReserve : Nat
  deriving Repr, DecidableEq

inductive TxStatus where
  | committed
  | reverted
  deriving Repr, DecidableEq

structure TxObservation where
  status : TxStatus
  before : ContractState
  after : ContractState
  balancesBefore : Balances
  balancesAfter : Balances

def committedBalances (before : Balances) (amount : Nat) : Balances :=
  { lidoDepositable := before.lidoDepositable - amount
    beaconSink := before.beaconSink + amount
    routerEth := before.routerEth
    withdrawalReserve := before.withdrawalReserve }

def observe (snapshot : ContractState) (balances : Balances) :
    ContractResult Balances → TxObservation
  | .success balancesAfter after =>
      ⟨.committed, snapshot, after, balances, balancesAfter⟩
  | .revert _ rollback => ⟨.reverted, snapshot, rollback, balances, balances⟩

private def executeCalls (cfg : SourceDepositConfig) (inp : SourceDepositInput) : Contract Unit :=
  let amount := Core.Uint256.ofNat (depositsValue cfg inp)
  match run cfg inp with
  | .committedDeposits _ _ _ _ => DepositTxContract.execute amount true true true
  | .committedNoDeposits => DepositTxContract.executeNoDeposits false
  | .revertLidoCannotDeposit | .revertLidoZeroAmount | .revertLidoNotEnoughEther =>
      DepositTxContract.execute amount true false true
  | .revertInvalidPublicKeysBatchLength | .revertInvalidSignaturesBatchLength
  | .revertInsufficientRouterBalance | .revertAssertBalanceUnchanged =>
      DepositTxContract.execute amount true true false
  | _ => DepositTxContract.execute amount false true true

/-- The bounded summarized-call world returned by the executable transaction.
Unlike an observer-side projection, this result is produced only after the
typed call program succeeds; `Contract.run` discards it on every revert. -/
def executeOutcome (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (balances : Balances) : Contract Balances := do
  executeCalls cfg inp
  match run cfg inp with
  | .committedDeposits _ pulled _ _ => _root_.Verity.pure (committedBalances balances pulled)
  | .committedNoDeposits => _root_.Verity.pure balances
  | _ => _root_.Verity.pure balances

def sourceObservation (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (snapshot : ContractState) (balances : Balances) : TxObservation :=
  match run cfg inp with
  | .committedDeposits _ pulled _ _ =>
      ⟨.committed, snapshot, snapshot, balances, committedBalances balances pulled⟩
  | .committedNoDeposits => ⟨.committed, snapshot, snapshot, balances, balances⟩
  | _ => ⟨.reverted, snapshot, snapshot, balances, balances⟩

theorem run_simulates_source (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (snapshot : ContractState) (balances : Balances)
    (hBound : depositsValue cfg inp ≤ Core.MAX_UINT256) :
    observe snapshot balances
      ((executeOutcome cfg inp balances).run snapshot) =
        sourceObservation cfg inp snapshot balances ∧
      (Core.Uint256.ofNat (depositsValue cfg inp)).val = depositsValue cfg inp := by
  have hAmountLt : depositsValue cfg inp < Core.Uint256.modulus := by
    rw [← Core.Uint256.max_uint256_succ_eq_modulus]
    omega
  cases hrun : run cfg inp <;>
    simp [executeOutcome, executeCalls, sourceObservation, observe, DepositTxContract.execute,
      _root_.Contracts.externalCallBind, _root_.Verity.require,
      DepositTxContract.executeNoDeposits, _root_.Verity.Contract.run, _root_.Verity.bind,
      _root_.Verity.pure, Bind.bind, Pure.pure, hrun, Core.Uint256.ofNat,
      Nat.mod_eq_of_lt hAmountLt]

theorem one_unit_exact_transfer
    {cfg : SourceDepositConfig} {inp : SourceDepositInput}
    {snapshot : ContractState} {balances : Balances} {amount : Nat}
    (hRun : run cfg inp = .committedDeposits 1 amount amount inp.routerBalanceBefore)
    (hBound : amount ≤ Core.MAX_UINT256)
    (hFunds : amount ≤ balances.lidoDepositable) :
    let tx := observe snapshot balances ((executeOutcome cfg inp balances).run snapshot)
    tx.status = .committed ∧
      (Core.Uint256.ofNat amount).val = amount ∧
      tx.balancesAfter.lidoDepositable + amount = balances.lidoDepositable ∧
      tx.balancesAfter.beaconSink = balances.beaconSink + amount ∧
      tx.balancesAfter.routerEth = balances.routerEth ∧
      tx.balancesAfter.withdrawalReserve = balances.withdrawalReserve := by
  have hAmount : depositsValue cfg inp = amount :=
    (committed_deposits_spec hRun).2.2.1.symm
  have hAmountLt : amount < Core.Uint256.modulus := by
    rw [← Core.Uint256.max_uint256_succ_eq_modulus]
    omega
  simp [executeOutcome, executeCalls, hRun, observe, DepositTxContract.execute,
    _root_.Contracts.externalCallBind, _root_.Verity.require,
    _root_.Verity.Contract.run, _root_.Verity.bind,
    _root_.Verity.pure, Bind.bind, Pure.pure, committedBalances, Nat.sub_add_cancel hFunds,
    Core.Uint256.ofNat, Nat.mod_eq_of_lt hAmountLt]

theorem failure_restores_snapshot
    (amount : Uint256) (moduleOk lidoOk beaconOk : Bool)
    (snapshot rollback : ContractState) (reason : String)
    (h : (DepositTxContract.execute amount moduleOk lidoOk beaconOk).run snapshot =
      .revert reason rollback) : rollback = snapshot := by
  unfold Contract.run at h
  split at h <;> simp_all

theorem source_revert_restores_committed_effects
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (snapshot : ContractState) (balances : Balances)
    (hBound : depositsValue cfg inp ≤ Core.MAX_UINT256)
    (h : (run cfg inp).reverts = true) :
    let tx := observe snapshot balances
      ((executeOutcome cfg inp balances).run snapshot)
    tx.status = .reverted ∧ tx.after = snapshot ∧ tx.balancesAfter = balances := by
  rw [(run_simulates_source cfg inp snapshot balances hBound).1]
  cases hrun : run cfg inp <;> simp [sourceObservation, Outcome.reverts, hrun] at h ⊢

end LidoSRv3.Audit.Verity.DepositTx
