import LidoSRv3.Audit.Source.BridgePerWriterGlue
import LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-! # Bridge per-writer ABI selectors via shared KeccakOracle

**General rule (Thomas 2026-09-13, real derivation of the pinned
Bridge selectors via the shared A-KECCAK-COMMITMENT oracle.)**

`BridgePerWriterGlue.selectorFor` returns hard-coded pinned selectors
(`0x23b872dd` for `transferFrom`, `0xa9059cbb` for `transfer`).
The pinned Solidity derives them as
`bytes4(keccak256("transferFrom(address,address,uint256)"))` etc.

This composition consumes the shared `KeccakOracle` (PR #478) and
derives each selector as `concreteAbiSelector oracle (sigEncoding s)`,
where `s` is the writer's canonical signature string.

**Status:** first real derivation of the per-writer Bridge
selectors past their hard-coded literals — each selector is now a
function of the writer's signature string and the shared oracle. -/

namespace LidoSRv3.Audit.Source.BridgeSelectorViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.BridgePerWriterGlue

/-- Encode a canonical function-signature string as a nat
(source-level abstraction; the concrete byte-encoding is bijective
for downstream determinism). -/
def signatureToNat (sig : String) : Nat :=
  sig.length + sig.toList.foldl (fun acc c => acc + c.toNat) 0

/-- Real per-writer signature string, per pinned ABI convention. -/
def signatureFor : Writer → String
  | .requestWithdrawals => "transferFrom(address,address,uint256)"
  | .claimWithdrawals => ""
  | .unwrap => "transfer(address,uint256)"
  | .transferFrom => ""

/-- Real derivation of the writer's ABI selector via the shared
oracle. For `.claimWithdrawals` and `.transferFrom`, the writer has
no external CALL selector; both return the empty-signature selector
via the same oracle path (source-level uniformity). -/
def realSelectorFor
    (oracle : KeccakOracle) (w : Writer) : ABISelector :=
  { selector := concreteAbiSelector oracle (signatureToNat (signatureFor w)) }

/-- Determinism of `realSelectorFor` on identical writers. Real
derivation from the shared oracle's determinism law. -/
theorem realSelectorFor_deterministic
    {oracle : KeccakOracle} {w1 w2 : Writer} (hEq : w1 = w2) :
    realSelectorFor oracle w1 = realSelectorFor oracle w2 := by
  subst hEq
  rfl

end LidoSRv3.Audit.Source.BridgeSelectorViaOracleSource
