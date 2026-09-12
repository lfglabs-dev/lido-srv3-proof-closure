import LidoSRv3.Audit.Source.DepositAdmissionErrors
namespace LidoSRv3.Audit.Guarantees.PDeposit1
set_option autoImplicit false
open LidoSRv3.Audit.Source TrioReserve1 audit.trio.deposit

/-- Whole new execution yields the ENTIRE328 success, exact old successful
result/journals, local error bytes with their first-failing physical origin,
and original rollback. None of these properties is a stage-success premise. -/
theorem actual_dsm_call_admission_bytes_suffix
    (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : DepositAdmissionErrors.Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World) :
    let r := DepositAdmissionErrors.execute q locator cursor hash m w ctx liveCtx i before
    (r.result.outcome = .ok () →
      r.localFailure = none ∧
      r.result = DepositDsmCall.execute q locator cursor hash m w ctx liveCtx i before ∧
      DepositDsmCall.Effects q locator cursor hash m w ctx liveCtx i before
        r.result.world r.result.attempts r.result.locatorAttempts) ∧
    (∀ dsm e, r.localFailure = some (dsm,e) →
      DepositAdmissionErrors.LocalRejection q locator cursor hash ctx liveCtx i before r dsm e) ∧
    (∀ f, r.result.outcome = .error f → r.result.world = before) := by
  dsimp only
  refine ⟨?_,?_,?_⟩
  · intro h
    obtain ⟨hn,he⟩ := DepositAdmissionErrors.success_projection _ _ _ _ _ _ _ _ _ _ h
    refine ⟨hn,he,?_⟩
    have ho : DepositDsmCall.execute q locator cursor hash m w ctx liveCtx i before =
        ⟨.ok (), (DepositAdmissionErrors.execute q locator cursor hash m w ctx liveCtx i before).result.world,
         (DepositAdmissionErrors.execute q locator cursor hash m w ctx liveCtx i before).result.attempts,
         (DepositAdmissionErrors.execute q locator cursor hash m w ctx liveCtx i before).result.locatorAttempts⟩ := by
      rw [←he]
      cases hr : (DepositAdmissionErrors.execute q locator cursor hash m w ctx liveCtx i before).result with
      | mk outcome world trace statics => simp only [hr] at h; cases h; rfl
    exact actual_dsm_call_registered_module_suffix _ _ _ _ _ _ _ _ _ _ _ _ _ ho
  · intro dsm e h
    exact DepositAdmissionErrors.local_rejection _ _ _ _ _ _ _ _ _ _ _ _ h
  · intro f h
    exact DepositAdmissionErrors.failure_restores _ _ _ _ _ _ _ _ _ _ _ h

#print axioms actual_dsm_call_admission_bytes_suffix
end LidoSRv3.Audit.Guarantees.PDeposit1
