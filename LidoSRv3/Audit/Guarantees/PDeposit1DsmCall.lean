import LidoSRv3.Audit.Source.DepositDsmCall
import Compiler.Proofs.MappingSlot
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

/-- Concrete Keccak for ERC-7201 module/metadata addressing in the registered
consumer. The generic source lemmas remain parameterized, but this parent
cannot be instantiated with a constant-slot test hash. -/
def depositPhysicalKeccak : DepositDsmCall.Keccak := fun bytes =>
  Live.word (EvmYul.fromByteArrayBigEndian
    (KeccakEngine.keccak256 (ByteArray.mk bytes.toArray)))

/-- Registered actual call/slot consumer: locator STATICCALL, DSM admission,
physical module status/credentials, real module-return bytes, metadata writes
and per-key withdrawal/beacon continuation, or complete root rollback.
Allocation and phase-cursor producers remain explicit upstream boundaries;
no LinksSource, supplied successful stage or synthetic observation slot is used. -/
theorem actual_deposit_call_slot_success_and_revert
    (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (m w : Live.External) (ctx : RouterDeposit.Context) (liveCtx : Live.Context)
    (i : ModuleCall.Input) (before : Live.World) :
    let result := DepositDsmCall.execute q locator cursor depositPhysicalKeccak m w ctx liveCtx i before
    match result.outcome with
    | .ok _ => DepositDsmCall.Effects q locator cursor depositPhysicalKeccak m w ctx liveCtx i before
        result.world result.attempts result.locatorAttempts
    | .error _ => result.world = before := by
  dsimp only
  cases h : DepositDsmCall.execute q locator cursor depositPhysicalKeccak m w ctx liveCtx i before with
  | mk outcome after attempts staticTrace =>
    cases outcome with
    | ok value =>
      cases value
      exact actual_dsm_call_registered_module_suffix q locator cursor depositPhysicalKeccak m w ctx liveCtx i
        before after attempts staticTrace h
    | «error» fault =>
      exact actual_dsm_call_failure_restores q locator cursor depositPhysicalKeccak m w ctx liveCtx i
        before after attempts staticTrace fault h

#print axioms actual_deposit_call_slot_success_and_revert
end LidoSRv3.Audit.Guarantees.PDeposit1
