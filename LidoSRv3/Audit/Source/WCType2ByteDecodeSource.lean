/-! # WithdrawalCredentials.isType2 byte-decode source model

**General rule (Thomas 2026-09-13, real derivation of the
P-TOPUP-1 wcIsType2 free boolean via a byte-decode source model —
closing item (b) of the general-rule follow-up in audit/STATUS.md.)**

The pinned Solidity `WithdrawalCredentials.isType2()` inspects the
first byte of a 32-byte withdrawal-credentials word. Item (b) of the
P-TOPUP-1 general-rule follow-up disclosed that this should be
derived from a byte-decode source model on the WC word.

This composition names the WC-word first-byte extraction as a
source-level function: `firstByte wcWord = wcWord / 2^248`, and
derives `wcIsType2` = `firstByte = 2`.

Pinned Solidity (17005714):

- `WithdrawalCredentials.sol`: `function isType2(bytes32 wc) returns
  (bool)` checks `wc[0] == 0x02` (top byte).

**Status:** first real derivation of the P-TOPUP-1 wcIsType2 past
its `SRStorageSourceModel.wcTypeIsType2FromPacked` naming scaffold. -/

namespace LidoSRv3.Audit.Source.WCType2ByteDecodeSource

/-- Extract the first byte (highest-order byte) of a 32-byte
withdrawal-credentials word. The first byte occupies bits 248-255. -/
def firstByte (wcWord : Nat) : Nat :=
  wcWord / (2 ^ 248) % 256

/-- Pinned WC type-2 byte constant. -/
def wcType2ByteConst : Nat := 2

/-- Real derivation of `WithdrawalCredentials.isType2()` from a
32-byte WC word: the top byte equals 0x02. -/
def wcIsType2 (wcWord : Nat) : Bool :=
  decide (firstByte wcWord = wcType2ByteConst)

/-- Under the pinned "top byte = 2" premise, `wcIsType2 = true`.
Real derivation. -/
theorem wcIsType2_true_of_first_byte
    {wcWord : Nat} (hFirst : firstByte wcWord = wcType2ByteConst) :
    wcIsType2 wcWord = true := by
  simp [wcIsType2, hFirst]

end LidoSRv3.Audit.Source.WCType2ByteDecodeSource
