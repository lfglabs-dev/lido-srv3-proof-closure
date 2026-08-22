import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Spec.SszCorrespondence
import Compiler.Sha256.Engine

/-!
# Pack C fail-closed vectors

Structural `verifyProof` must consult the generalized index. A one-byte
engine mutant shows `HashIdentification` names a specific pair.
-/

namespace LidoSRv3.Tests.PackCSszMutants

open LidoSRv3.Audit
open LidoSRv3.Audit.Spec.SszCorrespondence

/-- Mutant verifier: skip pivot / path / gindex / arity; only reconstruct. -/
def verifyProofSkipGindex (combine : Ssz.Node → Ssz.Node → Ssz.Node)
    (leaf : Ssz.Node) (_index : Ssz.GeneralizedIndex) (_pivotBoundary : Nat)
    (_path : List Ssz.SiblingSide) (_branch : List Ssz.Node)
    (expectedRoot : Ssz.Node) : Bool :=
  Ssz.traverseBranch combine leaf _path _branch == expectedRoot

private def combineAdd (a b : Ssz.Node) : Ssz.Node := a + b

private def indexTwo : Ssz.GeneralizedIndex := ⟨2, by decide⟩

/-- Kill-line for `verifyProof_implies_gindex`. Empty-path reconstruction
succeeds, but pivot `1` is not the generalized-index pivot of `2`, so
`HasGeneralizedIndex` is false. Honest `verifyProof` rejects the same
witness. -/
theorem skip_gindex_kill_line_refutes_structural_child :
    verifyProofSkipGindex combineAdd 1 indexTwo 1 [] [] 1 = true ∧
      Ssz.verifyProof combineAdd 1 indexTwo 1 [] [] 1 = false ∧
      ¬ Ssz.HasGeneralizedIndex indexTwo 1 [] := by
  refine ⟨rfl, rfl, ?_⟩
  intro h
  have : (1 : Nat) = Ssz.pivot indexTwo := h.1
  exact (by decide : (1 : Nat) ≠ 2) (this.trans (by decide))

/-- One-byte mutant of the Verity engine. Identification is with
`Sha256Engine.sha256`, not an arbitrary function of the same type. -/
def mutantEngine (data : ByteArray) : ByteArray :=
  let d := Sha256Engine.sha256 data
  match d.data.toList with
  | [] => d
  | b :: rest => ByteArray.mk (Array.mk ((b + 1) :: rest))

theorem engine_mutant_disagrees_with_sha256engine :
    (Sha256Engine.sha256 ByteArray.empty).data.toList ≠
      (mutantEngine ByteArray.empty).data.toList := by
  native_decide

end LidoSRv3.Tests.PackCSszMutants
