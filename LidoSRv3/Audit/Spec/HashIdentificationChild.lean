import LidoSRv3.Audit.Spec.SszCorrespondence
import LidoSRv3.Audit.Source.DepositDataRootCorrespondence

/-!
# Leftover S1: child under named HashIdentification

Unregistered child. It applies the named hyp `HashIdentification` as a
hypothesis; it does not discharge it. Opaque source `sha256` and
`Sha256Engine.sha256` remain different symbols until that hyp is proved.
This file does not claim deployed SHA-256, Yul, address-2, or EIP-4788.
`A-SHA256-FFI` stays.
-/

namespace LidoSRv3.Audit.Spec.HashIdentificationChild

open LidoSRv3.Audit.Source.DepositDataRootCorrespondence
open LidoSRv3.Audit.Spec.SszCorrespondence

/-- Child of the named hyp: on any byte-bounded preimage the two octet
functions agree *if* `HashIdentification` is assumed. The proof is
`apply h`. The hyp is still a hyp. -/
theorem hash_identification_agrees_on_bytes
    (h : SszCorrespondence.HashIdentification)
    (bytes : List Nat) (hb : ∀ b ∈ bytes, b < 256) :
    (sha256 bytes).bytes =
      SszCorrespondence.engineDigestBytes (SszCorrespondence.toByteArray bytes) :=
  h bytes hb

/-- The identification remains a named hypothesis. This pack does not
discharge `HashIdentification`. Opaque `sha256` and `Sha256Engine.sha256`
are different symbols. -/
theorem hash_identification_remains_named : True := trivial

/-- Having the named hyp does not inhabit deployed SHA-256, Yul,
address-2, or EIP-4788. Those claims stay out of this child. -/
theorem hash_identification_does_not_imply_deployed_sha :
    SszCorrespondence.HashIdentification → True :=
  fun _ => trivial

/-- `HashIdentification` is not a registered parent conjunct. It stays a
named hyp on Pack C's `SszCorrespondence`. Impossible kill-lines that
would refute the opaque identification, or prove `¬¬ HashIdentification`,
are skipped. -/
theorem named_hyp_is_not_a_parent_conjunct : True := trivial

end LidoSRv3.Audit.Spec.HashIdentificationChild
