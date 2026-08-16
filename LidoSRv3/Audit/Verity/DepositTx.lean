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

/-- The exact `ContractState.calls` journal the committing deposit program is
expected to append, in call order: module data fetch, Lido pull, beacon push.
Since Verity #2334 each `externalCallBind` appends a name-keyed entry carrying
the exact argument words, so this list is an observable prediction rather than
a comment. -/
def declaredDepositCalls (amount : Uint256) : List ExternalCall :=
  [ linkedCallEntry "obtainDepositData" [amount]
  , linkedCallEntry "withdrawDepositableEther" [amount]
  , linkedCallEntry "depositToBeacon" [amount] ]

def sourceObservation (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (snapshot : ContractState) (balances : Balances) : TxObservation :=
  match run cfg inp with
  | .committedDeposits _ pulled _ _ =>
      ⟨.committed, snapshot,
        { snapshot with
            calls := snapshot.calls ++
              declaredDepositCalls (Core.Uint256.ofNat (depositsValue cfg inp)) },
        balances, committedBalances balances pulled⟩
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
      _root_.Contracts.externalCallBind, _root_.Verity.require, declaredDepositCalls,
      DepositTxContract.executeNoDeposits, _root_.Verity.Contract.run, _root_.Verity.bind,
      _root_.Verity.pure, Bind.bind, hrun, Core.Uint256.ofNat,
      _root_.Contracts.ExternalArg.toWords, Nat.mod_eq_of_lt hAmountLt]

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
    _root_.Verity.pure, Bind.bind, committedBalances, Nat.sub_add_cancel hFunds,
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

/-! ### Executable-plane call-journal evidence

Before Verity #2334 `Contracts.externalCallBind` was `pure ()`, so the audited
program and every call-sequence mutant were *definitionally equal* and the
separations below were unstatable. Since #2334 each call site appends a
name-keyed entry carrying its exact argument words, so the theorems here reject
a change to the executed program itself, not to a handwritten record.

Scope: these are executable-plane (`Contract.run`) facts about call name,
argument words, multiplicity and order. They do not establish callee address,
call kind, ABI byte layout, gas, or any deployed-runtime semantics. -/

/-- The committing deposit program journals exactly the three declared calls,
in pinned-source order, each carrying the deposit amount as its calldata. -/
theorem execute_journals_declared_calls (amount : Uint256) (s : ContractState) :
    (DepositTxContract.execute amount true true true).run s =
      .success () { s with calls := s.calls ++ declaredDepositCalls amount } := by
  simp [DepositTxContract.execute, _root_.Contracts.externalCallBind,
    _root_.Verity.require, _root_.Verity.Contract.run, _root_.Verity.bind,
    Bind.bind, declaredDepositCalls,
    _root_.Contracts.ExternalArg.toWords]

/-- Mutant: the Lido pull at `StakingRouter.sol` line 744 is omitted. -/
private def mutantOmittedPull (amount : Uint256) : Contract Unit := do
  externalCallBind ([] : List String) "obtainDepositData" [amount]
  externalCallBind ([] : List String) "depositToBeacon" [amount]

/-- Mutant: the beacon push is executed twice (double-send). -/
private def mutantDoubledPush (amount : Uint256) : Contract Unit := do
  externalCallBind ([] : List String) "obtainDepositData" [amount]
  externalCallBind ([] : List String) "withdrawDepositableEther" [amount]
  externalCallBind ([] : List String) "depositToBeacon" [amount]
  externalCallBind ([] : List String) "depositToBeacon" [amount]

/-- Mutant: the pull and the push are swapped, so the router pushes to the
beacon before it has pulled the ether. -/
private def mutantSwappedOrder (amount : Uint256) : Contract Unit := do
  externalCallBind ([] : List String) "obtainDepositData" [amount]
  externalCallBind ([] : List String) "depositToBeacon" [amount]
  externalCallBind ([] : List String) "withdrawDepositableEther" [amount]

/-- Omitting the Lido pull is observable in every pre-state. -/
theorem omitted_pull_rejected (amount : Uint256) (s : ContractState) :
    ((mutantOmittedPull amount).run s).snd.calls ≠
      ((DepositTxContract.execute amount true true true).run s).snd.calls := by
  rw [execute_journals_declared_calls]
  simp only [mutantOmittedPull, _root_.Contracts.externalCallBind,
    _root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind,
    ContractResult.snd, declaredDepositCalls, _root_.Contracts.ExternalArg.toWords]
  intro h
  have hlen := congrArg List.length h
  simp only [List.length_append, List.length_cons, List.length_nil] at hlen
  omega

/-- Double-sending the beacon push is observable in every pre-state. -/
theorem doubled_push_rejected (amount : Uint256) (s : ContractState) :
    ((mutantDoubledPush amount).run s).snd.calls ≠
      ((DepositTxContract.execute amount true true true).run s).snd.calls := by
  rw [execute_journals_declared_calls]
  simp only [mutantDoubledPush, _root_.Contracts.externalCallBind,
    _root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind,
    ContractResult.snd, declaredDepositCalls, _root_.Contracts.ExternalArg.toWords]
  intro h
  have hlen := congrArg List.length h
  simp only [List.length_append, List.length_cons, List.length_nil] at hlen
  omega

/-- Pushing to the beacon before pulling from Lido is observable in every
pre-state: the journal records call order. -/
theorem swapped_order_rejected (amount : Uint256) (s : ContractState) :
    ((mutantSwappedOrder amount).run s).snd.calls ≠
      ((DepositTxContract.execute amount true true true).run s).snd.calls := by
  rw [execute_journals_declared_calls]
  simp only [mutantSwappedOrder, _root_.Contracts.externalCallBind,
    _root_.Verity.Contract.run, _root_.Verity.bind, Bind.bind,
    ContractResult.snd, declaredDepositCalls, _root_.Contracts.ExternalArg.toWords,
    List.append_assoc, List.cons_append, List.nil_append]
  intro h
  have hpair := List.append_cancel_left h
  simp [_root_.Contracts.linkedCallEntry] at hpair

/-- A guard failure rolls the whole journal back: no call survives a revert,
matching EVM top-level revert observability. -/
theorem revert_rolls_back_journal (amount : Uint256) (s : ContractState) :
    ((DepositTxContract.execute amount true true false).run s).snd.calls = s.calls := by
  simp [DepositTxContract.execute, _root_.Contracts.externalCallBind,
    _root_.Verity.require, _root_.Verity.Contract.run, _root_.Verity.bind,
    Bind.bind, ContractResult.snd]

end LidoSRv3.Audit.Verity.DepositTx
