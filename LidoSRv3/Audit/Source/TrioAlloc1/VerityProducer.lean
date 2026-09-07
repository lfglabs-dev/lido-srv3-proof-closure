import LidoSRv3.Audit.Source.TrioAlloc1.CallTree
import Verity.Core.Model.DenoteExternalCalls

/-!
Full call-tree interpretation in pinned Verity's executable external-call DenoteExternalCalls.
Every continuation decodes and checks the preceding response before constructing
later calls. Staticcall world preservation is supplied by the VM, even against an
adversary proposing arbitrary writes. This is the call-VM boundary, not a proof
of compiler memory allocation, gas sufficiency, or bytecode execution.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace VerityProducer
open Compiler.CompilationModel

def site (before : Transcript) (request : CallRequest) : DenoteExternalCalls.CallSite :=
  { siteId := before.length, kind := .staticcall, target := request.target.val
    value := 0, calldata := request.payload.map Fin.val, gas := 2^256-1 }

/-- The VM represents bytes as Naturals; this boundary takes their low byte.
A VM exceptional failure has no SOURCE returndata; raw reverts retain bytes. -/
def response : DenoteExternalCalls.ExternalCallResult → CallResponse
  | .success data => .returned (data.map byte)
  | .revert data => .reverted (data.map byte)
  | .failure _ => .exceptional

def sourceOracle (adversary : DenoteExternalCalls.AdversaryModel) (world : _root_.Verity.ContractState) : StaticOracle :=
  fun before request => response (adversary.result (site before request) world)

def translate (before : Transcript) : CallTree.Program α → DenoteExternalCalls.CallProgram (Except Failure α × Transcript)
  | .done result => .pure (result, before)
  | .call request next => .bind (site before request) fun observation =>
    let answer := response observation.result
    translate (before ++ [{ request, response := answer }]) (next answer)

/-- Actual VM execution, including the final VM world, gas and returndata. -/
def execute (l : Layout) (s : Storage) (input : CapacityInput)
    (adversary : DenoteExternalCalls.AdversaryModel) (state : DenoteExternalCalls.CallState) (before : Transcript := []) :=
  DenoteExternalCalls.denote (translate before (CallTree.producer l s input)) adversary state

theorem translation_correspondence (program : CallTree.Program α)
    (adversary : DenoteExternalCalls.AdversaryModel) (state : DenoteExternalCalls.CallState) (before : Transcript) :
    (DenoteExternalCalls.denote (translate before program) adversary state).1 =
      CallTree.evaluate (sourceOracle adversary state.world) program before ∧
    (DenoteExternalCalls.denote (translate before program) adversary state).2.world = state.world := by
  induction program generalizing state before with
  | done result => exact ⟨rfl, rfl⟩
  | call request next ih =>
    let observation := DenoteExternalCalls.denoteCall adversary (site before request) state
    have world : observation.state.world = state.world :=
      DenoteExternalCalls.denoteCall_staticcall_world adversary (site before request) state rfl
    have step := ih (response observation.result) observation.state
      (before ++ [{ request, response := response observation.result }])
    rw [world] at step
    exact ⟨step.1, step.2⟩

theorem producer_correspondence (l : Layout) (s : Storage) (input : CapacityInput)
    (adversary : DenoteExternalCalls.AdversaryModel) (state : DenoteExternalCalls.CallState) (before : Transcript) :
    (execute l s input adversary state before).1 =
      produce l s (sourceOracle adversary state.world) input before ∧
    (execute l s input adversary state before).2.world = state.world := by
  have h := translation_correspondence (CallTree.producer l s input) adversary state before
  rw [CallTree.producer_correspondence] at h
  exact h

end VerityProducer
end LidoSRv3.Audit.Source.TrioAlloc1
