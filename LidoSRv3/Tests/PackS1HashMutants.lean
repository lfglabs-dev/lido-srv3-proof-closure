import LidoSRv3.Audit.Spec.SszCorrespondence
import LidoSRv3.Audit.Spec.HashIdentificationChild
import LidoSRv3.Tests.PackCSszMutants
import Compiler.Sha256.Engine

/-!
# Leftover S1 fail-closed vectors

The Pack C engine mutant already shows `HashIdentification` names a
specific pair. This child re-exports that kill-line. It does not refute
the named hyp (opaque `sha256` has no closed value) and does not claim
deployed SHA-256, Yul, address-2, or EIP-4788.
-/

namespace LidoSRv3.Tests.PackS1HashMutants

/-- Kill-line inherited from Pack C: a one-byte mutant of
`Sha256Engine.sha256` disagrees with the engine. Identification is with
that engine, not an arbitrary function of the same type. -/
theorem engine_mutant_still_disagrees :
    (Sha256Engine.sha256 ByteArray.empty).data.toList ≠
      (PackCSszMutants.mutantEngine ByteArray.empty).data.toList :=
  PackCSszMutants.engine_mutant_disagrees_with_sha256engine

end LidoSRv3.Tests.PackS1HashMutants
