/-! # Solidity address type uint160 truncation source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
Solidity `address` type's uint160-truncation semantics as a source-
level function.)**

Solidity's `address` is a uint160; when a wider integer is cast to
`address`, only the low 160 bits are preserved. Packed-decoder
extractions for address fields (WithdrawalRequest.owner,
ERC-20 owner/spender keys, StakingRouterDeployment.lidoAddress, etc.)
therefore truncate at 160 bits per the pinned Solidity semantics.

This composition names the `address` type's uint160 truncation as a
source-level function, and proves the idempotence law (an
already-truncated address is fixed by re-truncation) plus a bounded
round-trip.

**Status:** first real derivation naming the Solidity address type's
uint160 truncation as a shared source-level function. Downstream
consumers (WithdrawalRequest.owner extraction, ERC-20 allowance
key `owner`/`spender` extraction, deployment-identity checks) can
compose through this to eliminate free `Nat` slots for address
values. -/

namespace LidoSRv3.Audit.Source.SolidityAddressTypeSource

/-- uint160 upper bound: 2^160 - 1. -/
def uint160Max : Nat := 2 ^ 160 - 1

/-- uint160 modulus: 2^160. -/
def uint160Modulus : Nat := 2 ^ 160

/-- Solidity `address(x)` cast: truncate to uint160. -/
def toAddress (x : Nat) : Nat := x % uint160Modulus

/-- The truncated value is strictly less than `uint160Modulus`. -/
theorem toAddress_lt_modulus (x : Nat) : toAddress x < uint160Modulus := by
  have hToAddr : toAddress x = x % (2 ^ 160) := rfl
  have hMod : uint160Modulus = 2 ^ 160 := rfl
  rw [hToAddr, hMod]
  apply Nat.mod_lt
  exact Nat.two_pow_pos 160

/-- Idempotence: `toAddress ∘ toAddress = toAddress`. -/
theorem toAddress_idem (x : Nat) : toAddress (toAddress x) = toAddress x := by
  unfold toAddress
  exact Nat.mod_mod x uint160Modulus

/-- Under the pinned "`x ≤ uint160Max`" premise, the truncation is
the identity. -/
theorem toAddress_id_of_bounded {x : Nat} (hLe : x ≤ uint160Max) :
    toAddress x = x := by
  unfold toAddress
  apply Nat.mod_eq_of_lt
  unfold uint160Modulus uint160Max at *
  omega

end LidoSRv3.Audit.Source.SolidityAddressTypeSource
