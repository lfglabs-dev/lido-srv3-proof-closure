import LidoSRv3.Audit.Source.TrioReserve1.Live

namespace LidoSRv3.Audit.Source.TrioReserve1.Erasure
open Live

/-- Source-visible result with attempted-call instrumentation removed. -/
abbrev PlainResult (α : Type) := Except Fault α × World
abbrev Plain (α : Type) := World → PlainResult α

def erase (program : Exec α) : Plain α := fun w =>
  let r := program w
  (r.outcome, r.world)

def plainBind (first : Plain α) (next : α → Plain β) : Plain β := fun w =>
  match first w with
  | (.error e, after) => (.error e, after)
  | (.ok a, after) => next a after

def plainRun (program : Plain α) (before : World) : PlainResult α :=
  match program before with
  | (.error e, _) => (.error e, before)
  | (.ok a, after) => (.ok a, after)

/-- The bind operator cannot inspect instrumentation. This holds for arbitrary
programs/callees and is the compositional trace-erasure law. -/
theorem erase_bind (first : Exec α) (next : α → Exec β) :
    erase (bindExec first next) = plainBind (erase first) (fun a => erase (next a)) := by
  funext w
  unfold erase bindExec plainBind
  cases h : (first w).outcome <;> simp [h]

theorem erase_pure (value : α) : erase (pureExec value) = fun w => (.ok value, w) := rfl

/-- Root rollback commutes with instrumentation erasure, for any failure after
any intermediate effects. Storage, all balances and all committed logs restore. -/
theorem erase_run (program : Exec α) (before : World) :
    ((run program before).outcome, (run program before).world) =
      plainRun (erase program) before := by
  unfold run plainRun erase
  cases h : (program before).outcome <;> simp [h]

theorem failure_restores_world (program : Exec α) (before : World) (fault : Fault)
    (h : (program before).outcome = .error fault) :
    (run program before).world = before := by
  simp [run, h]

/-- A contract's source-visible state never stores the attempted-call trace. -/
theorem replacing_attempts_preserves_observables (r : Result α) (trace : List Attempt) :
    (({r with attempts := trace} : Result α).outcome,
      ({r with attempts := trace} : Result α).world) = (r.outcome, r.world) := rfl

end LidoSRv3.Audit.Source.TrioReserve1.Erasure
