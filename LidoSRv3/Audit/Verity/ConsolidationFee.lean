import LidoSRv3.Audit.Guarantees.PConsolidation1
import Verity.Core.Model.CallProgramRollback
import Verity.Core.Model.DenoteExternalCalls
import Verity.Proofs.LoopSimulation

/-!
# P-CONSOLIDATION-1 transaction-plane fee refinement

This executable model charges `requests.length * fee` from prepaid balance,
preserves the validator public-key map, and retains the pre-call registry as
the rollback snapshot.  Each request becomes one value-bearing Verity call.
-/

namespace LidoSRv3.Audit.Verity.ConsolidationFee

open Compiler.CompilationModel.DenoteExternalCalls
open LidoSRv3.Audit.Guarantees.PConsolidation1

def consolidationRequestAddress : Nat := 0x0000BBdDc7CE488642fb579F8B00f3a590007251

def requestSite (index : Nat) (request : ConsolidationRequest)
    (fee : FeePerConsolidation) : CallSite :=
  { siteId := index
    kind := .call
    target := consolidationRequestAddress
    value := fee
    calldata := [request.sourcePubkey, request.targetPubkey]
    gas := Verity.Core.MAX_UINT256 }

/-- Concrete Verity call program: exactly one fee-bearing call per request. -/
def requestCalls (requests : List ConsolidationRequest)
    (fee : FeePerConsolidation) (index : Nat := 0) : CallProgram Unit :=
  match requests with
  | [] => .pure ()
  | request :: rest =>
      .bind (requestSite index request fee) fun _ =>
        requestCalls rest fee (index + 1)

structure ConsolidateProgram where
  snapshot : ValidatorRegistry
  requests : List ConsolidationRequest
  fee : FeePerConsolidation
  calls : CallProgram Unit

def consolidateProgram (pre : ValidatorRegistry)
    (requests : List ConsolidationRequest) (fee : FeePerConsolidation := 0) :
    ConsolidateProgram :=
  { snapshot := pre
    requests := requests
    fee := fee
    calls := requestCalls requests fee }

def pre_balance (registry : ValidatorRegistry) : PrepaidBalance :=
  registry.prepaidBalance

/-- Successful whole-call execution relation.  Its two state clauses are the
concrete debit and the absence of registry mapping writes. -/
def CallProgramOk (program : ConsolidateProgram)
    (post : ValidatorRegistry) : Prop :=
  consolidation_fee_valid program.requests program.fee
      (pre_balance program.snapshot) ∧
    post.prepaidBalance =
      program.snapshot.prepaidBalance - program.requests.length * program.fee ∧
    post.pubkeyMapping = program.snapshot.pubkeyMapping ∧
    mapping_invariant program.snapshot

/-- Executable pre-state guard used by regression vectors. -/
def runConsolidation (pre : ValidatorRegistry)
    (requests : List ConsolidationRequest) (fee : FeePerConsolidation) :
    Option ValidatorRegistry :=
  if requests.length * fee ≤ pre_balance pre then
    some { pre with prepaidBalance := pre.prepaidBalance - requests.length * fee }
  else
    none

theorem consolidation_fee_tx_ok :
    ∀ {pre post reqs fee balance},
      CallProgramOk (consolidateProgram pre reqs fee) post →
      consolidation_fee_valid reqs fee balance →
      pre_balance post + reqs.length * fee = pre_balance pre := by
  intro pre post reqs fee balance hok _
  rcases hok with ⟨hfee, hpost, _⟩
  rw [pre_balance, hpost]
  exact Nat.sub_add_cancel hfee

theorem consolidation_pubkey_mapping_ok :
    ∀ {pre post reqs},
      CallProgramOk (consolidateProgram pre reqs) post →
      pubkey_mapping_preserved pre post reqs := by
  intro pre post reqs hok
  refine ⟨hok.2.2.1, ?_⟩
  rw [mapping_invariant, hok.2.2.1]
  exact hok.2.2.2

/-- Snapshot rollback is equality with the registry captured before calls. -/
theorem consolidation_rollback_ok :
    ∀ {pre post reqs},
      CallProgramOk (consolidateProgram pre reqs) post →
      consolidation_reverted post pre →
      post = pre := by
  intro pre post reqs _ hreverted
  exact hreverted

/-- The snapshot marker agrees with Verity's whole-program rollback theorem
for the external world: if every observed call rolls back, the final world is
the initial snapshot. -/
theorem call_world_rollback_ok (program : ConsolidateProgram)
    (adversary : AdversaryModel) (state : CallState)
    (h : ∀ entry ∈ ObservedCalls program.calls adversary state,
      RollsBack adversary entry) :
    (denote program.calls adversary state).2.world = state.world := by
  exact denoteCallProgram_all_revert_preserves_world
    program.calls adversary state h

end LidoSRv3.Audit.Verity.ConsolidationFee
