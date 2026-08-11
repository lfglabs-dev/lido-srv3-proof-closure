import LidoSRv3.Audit.Source.DereferenceCorrespondence
import LidoSRv3.Audit.Verity.DereferenceYulBridge

namespace LidoSRv3.Audit.Guarantees.PDeref1

open LidoSRv3.Audit.SolidityDereference

/-!
P-DEREF-1: every successfully guarded staking-module dereference resolves the
registered nonzero address for that exact id; the binding survives every
source-permitted interleaving.  The theorem does not assume arbitrary address
mutation, module removal, or non-static callback writes because none exists on
the pinned source path.
-/

theorem closure (s : RegistryState) (id : ModuleId)
    (h : Dereferenceable s id) (steps : List Interleaving) :
    sourceDeref (runInterleavings s steps) id = some (s.moduleAddress id) := by
  rw [deref_stable_under_all_interleavings s id h steps]
  exact source_deref_exact s id h

end LidoSRv3.Audit.Guarantees.PDeref1
