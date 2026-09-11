import LidoSRv3.Audit.Source.DepositPhysicalAdmission
namespace LidoSRv3.Audit.Guarantees.PDeposit1
set_option autoImplicit false
open LidoSRv3.Audit.Source
open TrioReserve1
open audit.trio.deposit

/-- Additional actual module/metadata/withdrawal/beacon consumer with registry,
status and credential provenance derived by execution of physical router reads.
Its Effects retains the complete previous public conclusion on the same module
and suffix worlds, and the selected Word/octet credential for that commitment.
DSM locator resolution, prior allocation/return-buffer phase and constructor
maxEB identity remain explicit boundaries; no supplied config or stage success. -/
theorem actual_registered_module_call_metadata_suffix
    (hash : DepositPhysicalAdmission.Keccak) (m w : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (i : ModuleCall.Input)
    (before after : Live.World) (attempts : List Live.Attempt)
    (h : DepositPhysicalAdmission.execute hash m w ctx liveCtx i before = ⟨.ok (),after,attempts⟩) :
    DepositPhysicalAdmission.Effects hash m w ctx liveCtx i before after attempts :=
  DepositPhysicalAdmission.success_effects hash m w ctx liveCtx i before after attempts h

theorem actual_registered_module_failure_restores
    (hash : DepositPhysicalAdmission.Keccak) (m w : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (i : ModuleCall.Input)
    (before after : Live.World) (attempts : List Live.Attempt) (fault : Live.Fault)
    (h : DepositPhysicalAdmission.execute hash m w ctx liveCtx i before = ⟨.error fault,after,attempts⟩) :
    after = before :=
  DepositPhysicalAdmission.failure_restores hash m w ctx liveCtx i before after attempts fault h
end LidoSRv3.Audit.Guarantees.PDeposit1
