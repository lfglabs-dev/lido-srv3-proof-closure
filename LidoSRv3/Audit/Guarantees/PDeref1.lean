import LidoSRv3.Audit.Source.DereferenceCorrespondence
import LidoSRv3.Audit.Verity.DereferenceYulBridge
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PDeref1

open LidoSRv3.Audit.SolidityDereference

/-- Supplemental, bounded registry-dereference evidence. It is not one of the
immutable minimal-11 campaign guarantees. -/
def guarantee : LidoSRv3.Audit.Guarantees.Guarantee :=
  ⟨.pDeref1, [.model, .source, .verityTx]⟩

/-!
P-DEREF-1: every successfully guarded staking-module dereference resolves the
registered nonzero address for that exact id; the binding survives every
source-permitted interleaving.  The theorem does not assume arbitrary address
mutation, module removal, or non-static callback writes because none exists on
the pinned source path.
-/

theorem closure (s : RegistryState) (hs : Reachable s) (id : ModuleId)
    (h : Dereferenceable s id) (steps : List Interleaving) :
    sourceDeref (runInterleavings s steps) id = some (s.moduleAddress id) ∧
    s.moduleAddress id ≠ 0 := by
  rw [deref_stable_under_all_interleavings s id h steps]
  exact source_deref_exact_reachable s hs id h

end LidoSRv3.Audit.Guarantees.PDeref1
