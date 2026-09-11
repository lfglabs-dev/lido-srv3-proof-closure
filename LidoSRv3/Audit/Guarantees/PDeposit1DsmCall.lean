import LidoSRv3.Audit.Source.DepositDsmCall
namespace LidoSRv3.Audit.Guarantees.PDeposit1
set_option autoImplicit false
open LidoSRv3.Audit.Source TrioReserve1 audit.trio.deposit

/-- Actual locator STATICCALL → canonical DSM → authorization → complete326
physical admission/module/metadata/withdrawal/beacon effect. Locator immutable
identity, independent phase cursors and omitted allocation prelude remain
boundaries. No successful lookup, DSM address or admission premise is supplied. -/
theorem actual_dsm_call_registered_module_suffix
    (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : DepositDsmCall.Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before after : Live.World)
    (attempts : List Live.Attempt) (staticTrace : List Live.NestedAttempt)
    (h : DepositDsmCall.execute q locator cursor hash m w ctx liveCtx i before = ⟨.ok (),after,attempts,staticTrace⟩) :
    DepositDsmCall.Effects q locator cursor hash m w ctx liveCtx i before after attempts staticTrace :=
  DepositDsmCall.success_effects q locator cursor hash m w ctx liveCtx i before after attempts staticTrace h

theorem actual_dsm_call_failure_restores
    (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : DepositDsmCall.Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before after : Live.World)
    (attempts : List Live.Attempt) (staticTrace : List Live.NestedAttempt) (fault : Live.Fault)
    (h : DepositDsmCall.execute q locator cursor hash m w ctx liveCtx i before = ⟨.error fault,after,attempts,staticTrace⟩) :
    after = before :=
  DepositDsmCall.failure_restores q locator cursor hash m w ctx liveCtx i before after attempts staticTrace fault h
end LidoSRv3.Audit.Guarantees.PDeposit1
