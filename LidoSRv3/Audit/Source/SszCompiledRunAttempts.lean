import LidoSRv3.Audit.Source.SszCompiledClEntry

/-!
Journal of the selected compiled CL entry
(`SszRootCallHarness.verify` → `_verifyValidator`,
`CLValidatorVerifier.sol:44-57` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
selector `0x2e77b4ba`).

`run.attempts` is the STATICCALL journal of `rootCall` (IR 101-114) and
is empty when the compiled prefix fails before that call
(`SszCompiledClEntry.lean:164-171`). EIP-4788 authenticity/freshness
remain declared. Compilation, crypto, gas and consensus stay outside.
Additive: no existing file is edited.

CLAIM: grok owns ssz-compiled-run-attempts since 2026-09-11
-/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.SszCompiledRunAttempts

open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.SszCompiledClEntry
open LidoSRv3.Audit.Source.SszWrapperIndex hiding Error
open LidoSRv3.Audit.Source.TrioReserve1

def claimed : String := "grok owns ssz-compiled-run-attempts since 2026-09-11"

theorem claimed_string : claimed = "grok owns ssz-compiled-run-attempts since 2026-09-11" := rfl

/-- A `beforeRoot` failure (IR 43-100) journals no STATICCALL. -/
theorem run_attempts_of_beforeRoot_error
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (e : SszCompiledClEntry.Error)
    (h : beforeRoot fuel context = .error e) :
    (run fuel cfg external world context).attempts = [] := by
  simp [run, h]

/-- A `rootCall` failure (IR 101-114 overflow) journals no STATICCALL. -/
theorem run_attempts_of_rootCall_error
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (b : Before)
    (e : SszCompiledClEntry.Error)
    (hbr : beforeRoot fuel context = .ok b)
    (hrc : rootCall external world b.state b.timestamp = .error e) :
    (run fuel cfg external world context).attempts = [] := by
  simp [run, hbr, hrc]

/-- Once `rootCall` returns, `run.attempts` is that call's journal
(`lowLevelStaticCall` / IR 101-114), including when `afterRoot` later
reverts. -/
theorem run_attempts_of_rootCall_ok
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (b : Before)
    (st : EVM.State) (out : RootOutcome)
    (hbr : beforeRoot fuel context = .ok b)
    (hrc : rootCall external world b.state b.timestamp = .ok (st, out)) :
    (run fuel cfg external world context).attempts = out.attempts := by
  simp [run, hbr, hrc]

/-- A `beforeRoot` failure is the `run` outcome (IR 43-100). -/
theorem run_outcome_of_beforeRoot_error
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (e : SszCompiledClEntry.Error)
    (h : beforeRoot fuel context = .error e) :
    (run fuel cfg external world context).outcome = .error e := by
  simp [run, h]

/-- A `rootCall` failure is the `run` outcome (IR 101-114). -/
theorem run_outcome_of_rootCall_error
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (b : Before)
    (e : SszCompiledClEntry.Error)
    (hbr : beforeRoot fuel context = .ok b)
    (hrc : rootCall external world b.state b.timestamp = .error e) :
    (run fuel cfg external world context).outcome = .error e := by
  simp [run, hbr, hrc]

/-- Once `rootCall` returns, `run.outcome` is exactly `afterRoot`
(IR 116-417) on that state, flag and index. -/
theorem run_outcome_of_rootCall_ok
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (b : Before)
    (st : EVM.State) (out : RootOutcome)
    (hbr : beforeRoot fuel context = .ok b)
    (hrc : rootCall external world b.state b.timestamp = .ok (st, out)) :
    (run fuel cfg external world context).outcome =
      afterRoot fuel cfg st b.head out.success b.index := by
  simp [run, hbr, hrc]

/-- Prefix failure of `run` (beforeRoot or rootCall) has an empty journal. -/
theorem run_attempts_empty_of_prefix_error
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (e : SszCompiledClEntry.Error)
    (hphase :
      beforeRoot fuel context = .error e ∨
        ∃ b, beforeRoot fuel context = .ok b ∧
          rootCall external world b.state b.timestamp = .error e) :
    (run fuel cfg external world context).attempts = [] := by
  rcases hphase with hbr | ⟨b, hbr, hrc⟩
  · exact run_attempts_of_beforeRoot_error fuel cfg external world context e hbr
  · exact run_attempts_of_rootCall_error fuel cfg external world context b e hbr hrc

#print axioms claimed_string
#print axioms run_attempts_of_beforeRoot_error
#print axioms run_attempts_of_rootCall_error
#print axioms run_attempts_of_rootCall_ok
#print axioms run_outcome_of_beforeRoot_error
#print axioms run_outcome_of_rootCall_error
#print axioms run_outcome_of_rootCall_ok
#print axioms run_attempts_empty_of_prefix_error

end LidoSRv3.Audit.Source.SszCompiledRunAttempts
