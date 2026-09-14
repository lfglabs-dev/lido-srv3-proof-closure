import LidoSRv3.Tests.TrioAlloc1.VerityVectors
import LidoSRv3.Audit.Verity.AllocationTx
import LidoSRv3.Audit.Source.TrioComposition.VerityParentResult

set_option maxRecDepth 4096
namespace LidoSRv3.Tests.TrioAlloc1.AccountProducer
open LidoSRv3.Audit.Source.TrioAlloc1
open Compiler.CompilationModel

/-- Test layout/hash only; production still requires the actual deployment
layout. Conflicting unqualified words deliberately describe an empty router. -/
def accountWorld (s : Storage) : _root_.Verity.ContractState :=
  { _root_.Verity.defaultState with
    thisAddress := 99
    storageWords := fun key => match key with
      | .contractSlot owner key => if owner = 99 then
          ⟨(s (word key)).val, (s (word key)).isLt⟩ else 0
      | _ => 0 }

def badSummary : StaticOracle := fun _ _ => .returned (summary 1 0 0)

def initial : DenoteExternalCalls.CallState :=
  { world := accountWorld (LidoSRv3.Tests.TrioAlloc1.«storage» 2 (packed 21 5000 0 2) (packed 22 5000 0 1))
    gasRemaining := 2^256-1 }

def result := VerityProducer.executeAccount layout input (vmAdversary badSummary) initial []

/-- ABI-valid arbitrary replies refute unconditional allocation success. The
physical-account producer panics after the first summary, before the WC02
stake call and before the next module. This is not a supported-module proof. -/
theorem inconsistent_summary_stops_calls :
    columns result.1.1 = .error (.panic (word 0x11)) ∧
    result.1.2.map (fun item => (item.request.target.val, item.request.payload)) =
      [(21, summaryPayload)] := by decide +kernel

/-- The obsolete unqualified projection falsely takes the empty-router path
on this same world. The regression distinguishes the two executable paths. -/
theorem unqualified_projection_misses_module :
    (VerityProducer.executeWorld layout input (vmAdversary badSummary) initial []).1.2 = [] ∧
    result.1.2.length = 1 := by decide +kernel

/-- STATICCALL cannot commit the adversary's proposed selfBalance mutation. -/
theorem static_world_preserved : result.2.world = initial.world :=
  (VerityProducer.account_producer_correspondence layout input (vmAdversary badSummary)
    initial []).2

/-- The public executor retains the genuine summary counterexample through its
final result; no ABI library success can erase this earlier failure. -/
theorem public_result_preserves_summary_failure :
    let r := LidoSRv3.Audit.Source.TrioComposition.VerityParentResult.execute
      layout input.config (word input.config.maxEBType1.val) false
      (vmAdversary badSummary) initial []
    r.1.1 = .error (.panic (word 0x11)) ∧
    r.1.2.map (fun item => (item.request.target.val, item.request.payload)) =
      [(21, summaryPayload)] := by decide +kernel

/-- Both legacy theorem premises can hold while the physical registry is
nonempty. Their storage channels are distinct even in the very same world. -/
theorem legacy_empty_length_premise :
    ([] : List LidoSRv3.Audit.Verity.AllocationTx.BoundModule).length =
      min (initial.world.readSlot LidoSRv3.Audit.Verity.AllocationTx.modulesCountSlot).val 32 := by
  decide +kernel

theorem legacy_empty_binding_premise :
    (LidoSRv3.Audit.Verity.AllocationTx.bindLiveAll (vmAdversary badSummary)
      initial.world 0 0) initial.world = .success [] initial.world := rfl

/-- Counterexample to identifying the legacy observation status with the
physical result under only the registered legacy length/binding premises.
This is not a supported-deployment witness or an excuse to drop either claim. -/
theorem legacy_commits_while_physical_reverts :
    (LidoSRv3.Audit.Verity.AllocationTx.observe []
      ((LidoSRv3.Audit.Verity.AllocationTx.allocateLiveFromStorage
        (vmAdversary badSummary) ⟨32, 2048⟩ 32 false).run initial.world)).status =
      .committed ∧
    (LidoSRv3.Audit.Source.TrioComposition.VerityParentResult.execute
      layout input.config (word input.config.maxEBType1.val) false
      (vmAdversary badSummary) initial []).1.1 = .error (.panic (word 0x11)) := by
  decide +kernel

/-- A successful physical execution computes both columns from real replies;
replacing the computed capacities with zero breaks this regression. -/
theorem honest_physical_columns :
    columns (VerityProducer.executeAccount layout input (vmAdversary honest) initial []).1.1 =
      .ok ([3, 3], [8, 8]) := by decide +kernel

#print axioms inconsistent_summary_stops_calls
#print axioms unqualified_projection_misses_module
#print axioms static_world_preserved
end LidoSRv3.Tests.TrioAlloc1.AccountProducer
