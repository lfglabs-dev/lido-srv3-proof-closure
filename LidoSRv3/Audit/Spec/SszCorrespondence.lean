import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Source.DepositDataRootCorrespondence
import LidoSRv3.Audit.Source.GIndexConcatCorrespondence
import Compiler.Sha256.Engine

/-!
# Pack C: hash identification and structural verifyProof/gindex

Unregistered children. They do not replace the registered P-SSZ-1 parent,
do not discharge `PerfectDepositEncoding`, and do not claim deployed SHA-256,
Yul, EIP-4788, or a consolidation gateway.
-/

namespace LidoSRv3.Audit.Spec.SszCorrespondence

open LidoSRv3.Audit
open LidoSRv3.Audit.Source.DepositDataRootCorrespondence
open LidoSRv3.Audit.Source.GIndexConcatCorrespondence

/-- Octet list as the ByteArray the Verity engine consumes. Same cast as
`PSsz1.toByteArray`: each `Nat` is already `< 256`. -/
def toByteArray (bytes : List Nat) : ByteArray :=
  ByteArray.mk (List.toArray (bytes.map UInt8.ofNat))

def engineDigestBytes (data : ByteArray) : List Nat :=
  (Sha256Engine.sha256 data).data.toList.map UInt8.toNat

/-- Named hyp `HashIdentification` / `A-HASH-IDENTIFICATION`.

The opaque source `sha256` and `Sha256Engine.sha256` agree as octet
functions on every byte-bounded preimage. This pack does not discharge the
hyp. It is not a claim that either symbol is deployed SHA-256, the address-2
precompile, or Yul. -/
def HashIdentification : Prop :=
  ∀ (bytes : List Nat),
    (∀ b ∈ bytes, b < 256) →
      (sha256 bytes).bytes = engineDigestBytes (toByteArray bytes)

/-- Unregistered structural child: a successful `verifyProof` supplies a
generalized index, matching branch arity, and reconstructs the expected
root. No SHA-256. -/
theorem verifyProof_implies_gindex
    (combine : Ssz.Node → Ssz.Node → Ssz.Node) (leaf : Ssz.Node)
    (index : Ssz.GeneralizedIndex) (pivotBoundary : Nat)
    (path : List Ssz.SiblingSide) (branch : List Ssz.Node)
    (expectedRoot : Ssz.Node)
    (h : Ssz.verifyProof combine leaf index pivotBoundary path branch
      expectedRoot = true) :
    Ssz.HasGeneralizedIndex index pivotBoundary path ∧
      branch.length = path.length ∧
      Ssz.traverseBranch combine leaf path branch = expectedRoot := by
  simp [Ssz.verifyProof, beq_iff_eq] at h
  rcases h with ⟨⟨⟨⟨hPivot, hDepth⟩, hValue⟩, hArity⟩, hRoot⟩
  exact ⟨⟨hPivot, hDepth, hValue⟩, hArity, hRoot⟩

/-- Existing GIndex SOURCE child, re-exported so Pack C names the concat
layer next to `verifyProof` without restyling it as a live verifier. -/
theorem gindex_concat_matches_spec (lhs rhs : GIndex) :
    sourceConcat lhs rhs = specConcat lhs rhs :=
  source_concat_matches_spec lhs rhs

end LidoSRv3.Audit.Spec.SszCorrespondence
