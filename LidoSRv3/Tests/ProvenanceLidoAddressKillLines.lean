import LidoSRv3.Audit.Provenance.LidoAddress

/-! # Kill-lines for `Provenance.LidoAddress` D-ADDR-1 discharge

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the D-ADDR-1 half discharge: 20-byte deployed-immutable extraction
equals the canonical Mainnet Lido proxy address. -/

namespace LidoSRv3.Tests.ProvenanceLidoAddressKillLines

open LidoSRv3.Audit.Provenance.LidoAddress

/-- **Kill-line: deployed immutable is exactly 20 bytes.**

A mutant that shortened/lengthened the extracted address would
refute the pinned 20-byte immutable-payload width. -/
theorem deployedLidoImmutableBytes_length :
    deployedLidoImmutableBytes.length = 20 := rfl

/-- **Kill-line: the pinned Mainnet Lido proxy leading byte is 0xae.** -/
theorem deployedLidoImmutableBytes_first :
    deployedLidoImmutableBytes[0]? = some 0xae := rfl

/-- **Kill-line: the pinned Mainnet Lido proxy trailing byte is 0x84.** -/
theorem deployedLidoImmutableBytes_last :
    deployedLidoImmutableBytes[19]? = some 0x84 := rfl

/-- **Kill-line: `bytesToBigEndianNat []` = 0.** -/
theorem bytesToBigEndianNat_empty :
    bytesToBigEndianNat [] = 0 := rfl

/-- **Kill-line: `bytesToBigEndianNat [b]` = b as Nat.** -/
theorem bytesToBigEndianNat_single :
    bytesToBigEndianNat [0xae] = 0xae := rfl

/-- **Kill-line: `bytesToBigEndianNat [a, b]` = a*256 + b.** -/
theorem bytesToBigEndianNat_two :
    bytesToBigEndianNat [1, 2] = 258 := by decide

/-- **Kill-line: extracted bytes fold to the Mainnet Lido proxy address.** -/
theorem extract_equals_canonical :
    bytesToBigEndianNat deployedLidoImmutableBytes =
      0xae7ab96520de3a18e5e111b5eaab095312d7fe84 := by decide

#print axioms deployedLidoImmutableBytes_length
#print axioms deployedLidoImmutableBytes_first
#print axioms deployedLidoImmutableBytes_last
#print axioms bytesToBigEndianNat_empty
#print axioms bytesToBigEndianNat_single
#print axioms bytesToBigEndianNat_two
#print axioms extract_equals_canonical

end LidoSRv3.Tests.ProvenanceLidoAddressKillLines
