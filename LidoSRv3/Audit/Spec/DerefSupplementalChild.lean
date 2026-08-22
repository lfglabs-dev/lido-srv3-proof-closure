import LidoSRv3.Audit.Guarantees.PDeref1

/-!
# Wave 2 W2-SCOPE: P-DEREF-1 remains supplemental

Unregistered child. Re-exports the existing supplemental parent shape.
P-DEREF-1 stays on `AllGuarantees.supplemental`; this node does not
promote it into the immutable minimal-11 facade and invents no
guarantee ID.
-/

namespace LidoSRv3.Audit.Spec.DerefSupplementalChild

open LidoSRv3.Audit.SolidityDereference
open LidoSRv3.Audit.Guarantees.PDeref1

/-- Citation of the supplemental `PDeref1.closure` shape. Not a promotion. -/
theorem deref_closure_exists_shape
    (s : RegistryState) (hs : Reachable s) (id : ModuleId)
    (h : Dereferenceable s id) (steps : List Interleaving) :
    sourceDeref (runInterleavings s steps) id = some (s.moduleAddress id) ∧
    s.moduleAddress id ≠ 0 :=
  PDeref1.closure s hs id h steps

/-- P-DEREF-1 remains supplemental. This node does not register it. -/
theorem deref_remains_supplemental : True := trivial

end LidoSRv3.Audit.Spec.DerefSupplementalChild
