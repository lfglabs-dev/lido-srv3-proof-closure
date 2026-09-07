import LidoSRv3.Audit.Source.TrioReserve1.ACL

namespace LidoSRv3.Audit.Source.TrioReserve1.ACLBounds
open Live ACL

/-- More evaluation capacity preserves any completed result, including its
ordered oracle attempts. This does not identify capacity with EVM gas. -/
def Extends (before after : ACL.Result α) : Prop :=
  before.outcome ≠ .error .exhausted → after = before

theorem refl (r : ACL.Result α) : Extends r r := fun _ => rfl

theorem ite_extends (p : Prop) [Decidable p] (a a' b b' : ACL.Result α)
    (ha : Extends a a') (hb : Extends b b') :
    Extends (if p then a else b) (if p then a' else b') := by
  by_cases h : p
  · simpa only [h, ite_true] using ha
  · simpa only [h, ite_false] using hb

theorem bind_extends (r r' : ACL.Result α) (f f' : α → ACL.Result β)
    (hr : Extends r r') (hf : ∀ a, Extends (f a) (f' a)) :
    Extends (ACL.bindResult r f) (ACL.bindResult r' f') := by
  intro h
  cases he : r.outcome with
  | error e =>
    cases e with
    | exhausted => simp [ACL.bindResult, he] at h
    | invalidOpcode =>
      rw [hr (by rw [he]; intro hn; cases hn)]
      simp [ACL.bindResult, he]
  | ok a =>
    have hn : r.outcome ≠ .error .exhausted := by rw [he]; intro hn; cases hn
    rw [hr hn]
    have hfn : (f a).outcome ≠ .error .exhausted := by simpa [ACL.bindResult, he] using h
    simp [ACL.bindResult, he, hf a hfn]

theorem eval_succ (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (fuel index : Nat) :
    Extends (ACL.eval k external self hash who where_ role how w fuel index)
      (ACL.eval k external self hash who where_ role how w (fuel+1) index) := by
  induction fuel generalizing index with
  | zero => intro h; exact False.elim (h rfl)
  | succ fuel ih =>
    rw [ACL.eval, ACL.eval]
    dsimp only
    repeat' first
      | exact refl _
      | exact ih _
      | apply ite_extends
      | apply bind_extends
      | intro

theorem trans (a b c : ACL.Result α) (hab : Extends a b) (hbc : Extends b c) : Extends a c := by
  intro h
  have hb := hab h
  exact (hbc (by rw [hb]; exact h)).trans hb

theorem eval_mono (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (fuel extra index : Nat) :
    Extends (ACL.eval k external self hash who where_ role how w fuel index)
      (ACL.eval k external self hash who where_ role how w (fuel+extra) index) := by
  induction extra with
  | zero => exact refl _
  | succ extra ih => exact trans _ _ _ ih (eval_succ k external self hash who where_ role how w _ index)

theorem params_succ (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World) (fuel : Nat) :
    Extends (ACL.evalParams k external self hash who where_ role how w fuel)
      (ACL.evalParams k external self hash who where_ role how w (fuel+1)) := by
  unfold ACL.evalParams
  apply ite_extends
  · exact refl _
  · exact eval_succ k external self hash who where_ role how w fuel 0

theorem permission_succ (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (ctx : Context) (role : Word) (how : List Word) (w : World) (fuel : Nat) :
    Extends (ACL.hasPermission k external self ctx role how w fuel)
      (ACL.hasPermission k external self ctx role how w (fuel+1)) := by
  unfold ACL.hasPermission
  dsimp only
  repeat' first
    | exact refl _
    | exact params_succ _ _ _ _ _ _ _ _ _ _
    | apply ite_extends
    | apply bind_extends
    | intro

theorem permission_mono (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (ctx : Context) (role : Word) (how : List Word) (w : World) (fuel extra : Nat) :
    Extends (ACL.hasPermission k external self ctx role how w fuel)
      (ACL.hasPermission k external self ctx role how w (fuel+extra)) := by
  induction extra with
  | zero => exact refl _
  | succ extra ih => exact trans _ _ _ ih (permission_succ k external self ctx role how w _)

/-- Once the source query finishes, increasing host depth changes neither the
ACL reply nor its nested trace. Other calls are still delegated as before. -/
theorem dispatch_stable (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (ctx : Context) (role : Word) (w : World) (fuel extra : Nat) (req : Request)
    (onExhausted other : External)
    (h : (ACL.hasPermission k external self ctx role [] w fuel).outcome ≠ .error .exhausted) :
    ACL.dispatch k external self ctx role (fuel+extra) onExhausted other req w =
      ACL.dispatch k external self ctx role fuel onExhausted other req w := by
  simp only [ACL.dispatch, permission_mono k external self ctx role [] w fuel extra h]

/-- Two completed runs cannot disagree on value, invalid-opcode failure or
oracle trace, regardless of their chosen recursion capacities. -/
theorem eval_unique (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (first second index : Nat)
    (hfirst : (ACL.eval k external self hash who where_ role how w first index).outcome ≠ .error .exhausted)
    (hsecond : (ACL.eval k external self hash who where_ role how w second index).outcome ≠ .error .exhausted) :
    ACL.eval k external self hash who where_ role how w first index =
      ACL.eval k external self hash who where_ role how w second index := by
  have h1 := eval_mono k external self hash who where_ role how w first second index hfirst
  have h2 := eval_mono k external self hash who where_ role how w second first index hsecond
  rw [Nat.add_comm second first] at h2
  exact h1.symm.trans h2

theorem permission_unique (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (ctx : Context) (role : Word) (how : List Word) (w : World) (first second : Nat)
    (hfirst : (ACL.hasPermission k external self ctx role how w first).outcome ≠ .error .exhausted)
    (hsecond : (ACL.hasPermission k external self ctx role how w second).outcome ≠ .error .exhausted) :
    ACL.hasPermission k external self ctx role how w first =
      ACL.hasPermission k external self ctx role how w second := by
  have h1 := permission_mono k external self ctx role how w first second hfirst
  have h2 := permission_mono k external self ctx role how w second first hsecond
  rw [Nat.add_comm second first] at h2
  exact h1.symm.trans h2

end LidoSRv3.Audit.Source.TrioReserve1.ACLBounds
