import LidoSRv3.Audit.Source.TrioAlloc1.ShareWriter

/-!
Kill-lines pinning `TrioAlloc1.ShareWriter` `replaceShares`
field-decomposition theorems and the pinned ACL base slot literal.
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1ShareWriterKillLines

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1.ShareWriter

/-! ## Pinned ACL base slot for `updateModuleShares`. -/

theorem aclBase_val :
    aclBase =
      word 0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800 :=
  rfl

/-! ## `replaceShares` — field decomposition witnesses. -/

theorem replaceShares_share_restated
    (original : Word) (share threshold : Fin (2^16)) :
    field (replaceShares original share threshold) 192 16 = share.val :=
  replaceShares_share original share threshold

theorem replaceShares_threshold_restated
    (original : Word) (share threshold : Fin (2^16)) :
    field (replaceShares original share threshold) 208 16 = threshold.val :=
  replaceShares_threshold original share threshold

theorem replaceShares_preserves_low_restated
    (original : Word) (share threshold : Fin (2^16)) :
    (replaceShares original share threshold).val % 2^192 =
      original.val % 2^192 :=
  replaceShares_preserves_low original share threshold

theorem replaceShares_preserves_high_restated
    (original : Word) (share threshold : Fin (2^16)) :
    (replaceShares original share threshold).val / 2^224 =
      original.val / 2^224 :=
  replaceShares_preserves_high original share threshold

end LidoSRv3.Tests.SourceTrioAlloc1ShareWriterKillLines
