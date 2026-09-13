/-! # ERC-2612 permit-signature source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
ERC-2612 permit-request calldata as a source-level function of its
constituent fields.)**

The pinned WithdrawalQueueERC721 permit-then-request path
`requestWithdrawalsWithPermit(...)` decodes calldata into
`(amounts, recipient, PermitInput{value, deadline, v, r, s})` and
invokes stETH's ERC-2612 `permit` before proceeding with the
request. The Verity plane models the permit input as a single
opaque record; this composition names each field extraction as a
source-level function on a source-level `PermitInput`.

Pinned Solidity (17005714):

- `WithdrawalQueueERC721.sol`
   `permit(owner, spender, value, deadline, v, r, s)` calls stETH
   ERC-2612; the caller supplies the six-tuple.
- ERC-2612 `permit` requires `deadline ≥ block.timestamp`, else it
   reverts with `ERC20Permit: expired deadline`.

**Status:** first real derivation naming the permit-input source
extraction and the pinned deadline-check semantics as source-level
functions. -/

namespace LidoSRv3.Audit.Source.PermitDecodeSource

/-- Source-level ERC-2612 permit-input record. -/
structure PermitInput : Type where
  owner : Nat
  spender : Nat
  value : Nat
  deadline : Nat
  v : Nat
  r : Nat
  s : Nat

/-- Source-level extraction of each PermitInput field. -/
def ownerFromPermit (p : PermitInput) : Nat := p.owner
def spenderFromPermit (p : PermitInput) : Nat := p.spender
def valueFromPermit (p : PermitInput) : Nat := p.value
def deadlineFromPermit (p : PermitInput) : Nat := p.deadline

/-- Pinned ERC-2612 deadline check: the block timestamp must be
at most the permit deadline. -/
def deadlineNotExpired (p : PermitInput) (blockTimestamp : Nat) : Bool :=
  decide (blockTimestamp ≤ p.deadline)

/-- Under the pinned "block ≤ deadline" premise, the deadline check
passes. Real derivation. -/
theorem deadlineNotExpired_true_of_le
    {p : PermitInput} {blockTimestamp : Nat}
    (hLe : blockTimestamp ≤ p.deadline) :
    deadlineNotExpired p blockTimestamp = true := by
  simp [deadlineNotExpired, hLe]

/-- Under the "block > deadline" premise, the deadline check fails. -/
theorem deadlineNotExpired_false_of_gt
    {p : PermitInput} {blockTimestamp : Nat}
    (hGt : p.deadline < blockTimestamp) :
    deadlineNotExpired p blockTimestamp = false := by
  simp [deadlineNotExpired]
  omega

end LidoSRv3.Audit.Source.PermitDecodeSource
