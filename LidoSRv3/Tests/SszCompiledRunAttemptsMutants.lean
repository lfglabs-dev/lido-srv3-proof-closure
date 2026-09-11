import LidoSRv3.Audit.Source.SszCompiledRunAttempts

/-! Named kill-lines for the compiled `run` STATICCALL journal. -/
set_option autoImplicit false
namespace LidoSRv3.Tests.SszCompiledRunAttemptsMutants

open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.SszCompiledRunAttempts
open LidoSRv3.Audit.Source.SszCompiledClEntry
open LidoSRv3.Audit.Source.SszWrapperIndex hiding Error
open LidoSRv3.Audit.Source.TrioReserve1

/-- Kill-line: a `beforeRoot` failure does not journal a STATICCALL. -/
theorem beforeRoot_error_empty_journal_kill_line
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (e : SszCompiledClEntry.Error)
    (h : beforeRoot fuel context = .error e) :
    (run fuel cfg external world context).attempts = [] :=
  run_attempts_of_beforeRoot_error fuel cfg external world context e h

/-- Kill-line: a `rootCall` overflow does not journal a STATICCALL. -/
theorem rootCall_error_empty_journal_kill_line
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (b : Before)
    (e : SszCompiledClEntry.Error)
    (hbr : beforeRoot fuel context = .ok b)
    (hrc : rootCall external world b.state b.timestamp = .error e) :
    (run fuel cfg external world context).attempts = [] :=
  run_attempts_of_rootCall_error fuel cfg external world context b e hbr hrc

/-- Kill-line: after `rootCall` returns, the journal is not an independent
caller-supplied list. -/
theorem rootCall_ok_journal_is_outcome_kill_line
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context : EVM.State) (b : Before)
    (st : EVM.State) (out : RootOutcome)
    (hbr : beforeRoot fuel context = .ok b)
    (hrc : rootCall external world b.state b.timestamp = .ok (st, out)) :
    (run fuel cfg external world context).attempts = out.attempts :=
  run_attempts_of_rootCall_ok fuel cfg external world context b st out hbr hrc

#print axioms beforeRoot_error_empty_journal_kill_line
#print axioms rootCall_error_empty_journal_kill_line
#print axioms rootCall_ok_journal_is_outcome_kill_line

end LidoSRv3.Tests.SszCompiledRunAttemptsMutants
