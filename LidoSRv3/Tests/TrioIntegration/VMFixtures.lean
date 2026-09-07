import LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer

namespace LidoSRv3.Tests.TrioIntegration.VMFixtures
open LidoSRv3.Audit.Source.TrioAlloc1
open Compiler.CompilationModel

/-- Seed the same physical words into the VM; every other storage channel is zero. -/
def vmWorld (s : Storage) : _root_.Verity.ContractState :=
  { _root_.Verity.defaultState with storageWords := fun key => match key with
    | .slot slot => ⟨(s (word slot)).val, (s (word slot)).isLt⟩
    | _ => _root_.Verity.Core.Uint256.ofNat 0 }

/-- The shared fixtures depend on call target/payload, not transcript history.
The VM still executes all calls and response-dependent continuations itself. -/
def vmAdversary (oracle : StaticOracle) : DenoteExternalCalls.AdversaryModel :=
  { stateTransition := fun _ world => { world with selfBalance := _root_.Verity.Core.Uint256.ofNat 123 }
    result := fun site _ =>
      let request : CallRequest :=
        { target := ⟨site.target % 2^160, Nat.mod_lt _ (by decide)⟩
          payload := site.calldata.map byte }
      match oracle [] request with
      | .returned bytes => .success (bytes.map Fin.val)
      | .reverted bytes => .revert (bytes.map Fin.val)
      | .exceptional => .failure []
    gasUsed := fun _ _ => 0 }

end LidoSRv3.Tests.TrioIntegration.VMFixtures
