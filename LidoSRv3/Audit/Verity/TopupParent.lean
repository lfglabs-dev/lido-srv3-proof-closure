import LidoSRv3.Audit.Source.TopupParentCorrespondence

/-! Executable whole-parent Verity transaction for P-TOPUP-1. -/

namespace LidoSRv3.Audit.Verity.TopupParent

open _root_.Verity
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.SolidityTopupParent

def reasonString : RevertReason -> String
  | .source outcome => s!"SOURCE:{repr outcome}"
  | .allocationCallFailed => "ALLOCATION_CALL_FAILED"
  | .lidoPullCallFailed => "LIDO_PULL_CALL_FAILED"
  | .beaconPushCallFailed => "BEACON_PUSH_CALL_FAILED"

/-- The executable public parent.  It starts at authentication and ends only at
the parent commit or revert boundary; no source outcome is accepted as an
argument and no transaction suffix is relabelled as the parent. -/
def execute (cfg : SourceTopupConfig) (base : SourceTopupInput)
    (gateway : Address) (iface : CalleeInterface) : Contract ParentExecution :=
  fun state =>
    let execution := sourceExecute cfg base gateway state.sender iface
    match execution.result with
    | .reverted reason => .revert (reasonString reason) state
    | _ => .success execution state

inductive ParentStatus where
  | committed
  | reverted
  deriving Repr, DecidableEq

structure ParentView where
  status : ParentStatus
  before : ContractState
  after : ContractState
  source : ParentExecution

def sourceView (cfg : SourceTopupConfig) (base : SourceTopupInput)
    (gateway : Address) (iface : CalleeInterface) (state : ContractState) : ParentView :=
  let execution := sourceExecute cfg base gateway state.sender iface
  if execution.result.reverts then
    { status := .reverted, before := state, after := state, source := execution }
  else
    { status := .committed, before := state, after := state, source := execution }

def observe (cfg : SourceTopupConfig) (base : SourceTopupInput)
    (gateway : Address) (iface : CalleeInterface) (before : ContractState)
    (result : ContractResult ParentExecution) : ParentView :=
  let source := sourceExecute cfg base gateway before.sender iface
  match result with
  | .success _ after => { status := .committed, before := before, after := after, source := source }
  | .revert _ rollback => { status := .reverted, before := before, after := rollback, source := source }

/-- Public parent proposition: the complete executable `Contract.run` result
has exactly the source transaction's success/revert classification and restores
the caller snapshot on every revert. -/
def ParentProposition (cfg : SourceTopupConfig) (base : SourceTopupInput)
    (gateway : Address) (iface : CalleeInterface) (state : ContractState) : Prop :=
  observe cfg base gateway iface state ((execute cfg base gateway iface).run state) =
    sourceView cfg base gateway iface state

theorem parent_transaction_closure (cfg : SourceTopupConfig) (base : SourceTopupInput)
    (gateway : Address) (iface : CalleeInterface) (state : ContractState) :
    ParentProposition cfg base gateway iface state := by
  unfold ParentProposition observe execute sourceView Contract.run
  cases hresult : (sourceExecute cfg base gateway state.sender iface).result <;>
    simp [hresult, ParentResult.reverts]

theorem revert_restores_caller_frame (cfg : SourceTopupConfig)
    (base : SourceTopupInput) (gateway : Address) (iface : CalleeInterface)
    (state rollback : ContractState) (reason : String)
    (h : (execute cfg base gateway iface).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

end LidoSRv3.Audit.Verity.TopupParent
