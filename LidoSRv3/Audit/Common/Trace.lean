import LidoSRv3.Audit.Common.Units

namespace LidoSRv3.Audit.Common

inductive Attempt
  | call (target : Nat) (value : Wei)
  | emitLog (emitter topic0 : Nat) (data : List Nat)
  deriving DecidableEq, Repr

inductive Effect
  | stateWrite (slot value : Nat)
  | transfer (sender recipient : Nat) (amount : Wei)
  | log (emitter topic0 : Nat) (data : List Nat)
  deriving DecidableEq, Repr

structure Trace where
  attempted : List Attempt
  committed : List Effect
  deriving DecidableEq, Repr

def Trace.rollback (trace : Trace) : Trace :=
  { attempted := trace.attempted, committed := [] }

@[simp] theorem Trace.rollback_preserves_attempts (trace : Trace) :
    trace.rollback.attempted = trace.attempted := rfl

@[simp] theorem Trace.rollback_erases_committed (trace : Trace) :
    trace.rollback.committed = [] := rfl

end LidoSRv3.Audit.Common
