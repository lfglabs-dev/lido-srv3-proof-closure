import LidoSRv3.Audit.Source.AddressCorrespondence
import Verity.Core
import Verity.Macro

/-!
# P-ADDRESS-1 official Verity transaction representation

The source interpreter supplies the complete mapped guard classification and
address-bearing post-state.  This official `verity_contract` transaction makes
that boundary executable and uses `Contract.run` for snapshot rollback.  It
does not claim generated-Yul, EVM, external-contract, or deployment refinement.
-/

namespace LidoSRv3.Audit.Verity.AddressTx

open _root_.Verity
open LidoSRv3.Audit.SolidityAddress

verity_contract AddressTxContract where
  storage

  function no_external_calls execute (sourceSucceeds : Bool) : Unit := do
    require sourceSucceeds "SOURCE_ADDRESS_REVERTED"

inductive TxStatus where
  | committed | reverted
  deriving DecidableEq, Repr

structure TxView where
  status : TxStatus
  before : ContractState
  after : ContractState
  deriving Repr

def sourceTx (inp : Input) (before : ContractState) : TxView :=
  if succeeds (run inp) then ⟨.committed, before, before⟩
  else ⟨.reverted, before, before⟩

def observeVerity (before : ContractState) (result : ContractResult Unit) : TxView :=
  match result with
  | .success _ after => ⟨.committed, before, after⟩
  | .revert _ rollback => ⟨.reverted, before, rollback⟩

def executeSource (inp : Input) : Contract Unit :=
  AddressTxContract.execute (succeeds (run inp))

theorem verity_tx_simulates_source (inp : Input) (state : ContractState) :
    observeVerity state ((executeSource inp).run state) = sourceTx inp state := by
  cases h : run inp <;>
    simp [executeSource, sourceTx, observeVerity, AddressTxContract.execute,
      succeeds, h, _root_.Verity.require, _root_.Verity.Contract.run]

theorem verity_revert_restores_snapshot (inp : Input) (state rollback : ContractState)
    (reason : String) (h : (executeSource inp).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

end LidoSRv3.Audit.Verity.AddressTx
