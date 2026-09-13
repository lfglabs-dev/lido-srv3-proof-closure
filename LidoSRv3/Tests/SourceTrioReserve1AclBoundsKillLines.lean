import LidoSRv3.Audit.Source.TrioReserve1.ACLBounds

/-!
Kill-lines pinning `TrioReserve1.ACLBounds.Extends` reflexivity,
transitivity, and if-then-else composability. These are the
capacity-monotonicity witnesses used by TrioReserve1 ACL evaluation.
-/

namespace LidoSRv3.Tests.SourceTrioReserve1AclBoundsKillLines

open LidoSRv3.Audit.Source.TrioReserve1.ACLBounds
open LidoSRv3.Audit.Source.TrioReserve1

/-! ## Reflexivity — Extends r r. -/

theorem refl_restated {α : Type} (r : ACL.Result α) :
    Extends r r :=
  refl r

/-! ## Transitivity — Extends a b + Extends b c ⇒ Extends a c. -/

theorem trans_restated {α : Type}
    (a b c : ACL.Result α)
    (hab : Extends a b) (hbc : Extends b c) :
    Extends a c :=
  trans a b c hab hbc

/-! ## If-then-else composition. -/

theorem ite_extends_restated {α : Type}
    (p : Prop) [Decidable p] (a a' b b' : ACL.Result α)
    (ha : Extends a a') (hb : Extends b b') :
    Extends (if p then a else b) (if p then a' else b') :=
  ite_extends p a a' b b' ha hb

end LidoSRv3.Tests.SourceTrioReserve1AclBoundsKillLines
