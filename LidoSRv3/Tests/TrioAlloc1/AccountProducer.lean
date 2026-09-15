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

/-! The legacy relation compares router inputs only. Persisted observation
arrays have no Solidity storage counterpart. The state relation does not equate
call observations; the oracle below separately ignores world/site numbering.
[SRLib first loop](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/SRLib.sol#L508-L532).
-/
namespace RelatedStorage
abbrev Legacy := LidoSRv3.Audit.Verity.AllocationTx.BoundModule

/-- Ordered decoded registry fields, before any module call. -/
def legacyRows (world : _root_.Verity.ContractState) :=
  (List.range (world.readSlot LidoSRv3.Audit.Verity.AllocationTx.modulesCountSlot).val).map
    fun i =>
      let m := LidoSRv3.Audit.Verity.AllocationTx.sourceBindConfigOne world i
      let packed := world.readMapUint LidoSRv3.Audit.Verity.AllocationTx.moduleConfigSlot m.moduleId
      (m.moduleId.val, m.moduleAddress.val, m.shareLimit.val,
        LidoSRv3.Audit.Verity.AllocationTx.configStatus packed,
        LidoSRv3.Audit.Verity.AllocationTx.configWcType packed, m.accountingExitedCount.val)

def physicalRows (l : Layout) (world : _root_.Verity.ContractState) :=
  let words := VerityProducer.accountStorage world
  (List.range (words (countSlot l)).val).map fun i =>
    let m := readModule l words i
    (m.identity.moduleId.val, m.identity.moduleAddress.val, m.share.val,
      m.status.val, m.wcType.val, m.accountingExited.val)

/-- Full ordered input relation for this comparison, including the legacy cap.
It is intentionally not a relation between final results or expected poststates. -/
def Related (l : Layout) (modelState physical : _root_.Verity.ContractState) : Prop :=
  (modelState.readSlot LidoSRv3.Audit.Verity.AllocationTx.modulesCountSlot).val =
    ((VerityProducer.accountStorage physical) (countSlot l)).val ∧
  (modelState.readSlot LidoSRv3.Audit.Verity.AllocationTx.modulesCountSlot).val ≤ 32 ∧
  legacyRows modelState = physicalRows l physical

def module (id address : Nat) (wc2 : Bool) : Legacy :=
  { moduleId := _root_.Verity.Core.Uint256.ofNat id
    moduleAddress := _root_.Verity.Core.Uint256.ofNat address
    shareLimit := 5000, isActive := true, isType2 := wc2
    depositableCount := 0, depositedCount := 0, summaryExitedCount := 0
    accountingExitedCount := 0, totalModuleStake := 0 }

def legacyWorld :=
  (LidoSRv3.Audit.Verity.AllocationTx.stateFor [module 7 21 true, module 9 22 false]).writeSlot
    LidoSRv3.Audit.Verity.AllocationTx.modulesCountSlot 2

theorem inputs_related : Related layout legacyWorld initial.world := by
  unfold Related
  decide +kernel

/-- Same replies for both representations and independent of site numbering:
summary (5,4,20) underflows; the subsequent stake request reverts with 0xaa. -/
def replies := vmAdversary underflow

/-- Matching storage does not repair the hoisted call order. The legacy binder
reaches the reverting stake call. The physical execution stops with Panic(0x11)
after the summary, so that stake call is absent from its transcript. These are
explicit, distinct error observations; neither implies a deployment claim. -/
theorem interleaving_changes_first_failure :
    (LidoSRv3.Audit.Verity.AllocationTx.bindLiveAll replies legacyWorld 0 2) legacyWorld =
      .revert "TotalModuleStakeCallFailed" legacyWorld ∧
    columns (VerityProducer.executeAccount layout input replies
      { initial with world := initial.world } []).1.1 = .error (.panic (word 0x11)) ∧
    (VerityProducer.executeAccount layout input replies initial []).1.2.map
      (fun item => (item.request.target.val, item.request.payload)) = [(21, summaryPayload)] := by
  constructor
  · rfl
  · decide +kernel

/-- The honest fixture agrees on successful columns under the same storage
relation. This finite positive control is not a universal success theorem and
says nothing about full call, error, gas or post-storage equivalence. -/
theorem honest_success_columns :
    let execution := (LidoSRv3.Audit.Verity.AllocationTx.allocateLiveFromStorage
      (vmAdversary honest) ⟨32, 2048⟩ 10 false).run legacyWorld
    (LidoSRv3.Audit.Verity.AllocationTx.observe [] execution).allocations.map
        (fun w => w.val) = [3, 3] ∧
    (LidoSRv3.Audit.Verity.AllocationTx.observe [] execution).capacities.map
        (fun w => w.val) = [8, 8] := by
  decide +kernel
end RelatedStorage

/-- A successful physical execution computes both columns from real replies;
replacing the computed capacities with zero breaks this regression. -/
theorem honest_physical_columns :
    columns (VerityProducer.executeAccount layout input (vmAdversary honest) initial []).1.1 =
      .ok ([3, 3], [8, 8]) := by decide +kernel

#print axioms inconsistent_summary_stops_calls
#print axioms unqualified_projection_misses_module
#print axioms static_world_preserved
end LidoSRv3.Tests.TrioAlloc1.AccountProducer
