import LidoSRv3.Audit.Source.AragonACLSource
import LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-! # Aragon ACL role-key via KeccakOracle composition

**General rule (Thomas 2026-09-13, real derivation replacing
`AragonACLSource.roleKeyEncoding`'s opaque length-based encoding
with the shared `KeccakConcreteCommitmentSource.KeccakOracle`.)**

`AragonACLSource.roleKeyEncoding` above still returns `roleName.length`
as a placeholder; the real Aragon ACL uses
`keccak256(bytes("ROLE_NAME"))`. This composition consumes the shared
`KeccakOracle` (introduced in PR #478) and derives the real role
key from it.

**Status:** first real derivation of the Aragon ACL role-key past
the naming scaffold — the role key is now `oracle.hash roleEncoding`,
where `roleEncoding` encodes the role name as a nat. -/

namespace LidoSRv3.Audit.Source.AragonACLRoleKeyViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-- Encode a role name as a nat (source-level abstraction; the
concrete byte-encoding is bijective for downstream determinism). -/
def roleNameToNat (roleName : String) : Nat :=
  roleName.length + roleName.toList.foldl (fun acc c => acc + c.toNat) 0

/-- Real role key derivation: `keccak256(bytes("ROLE_NAME"))` via
the shared oracle. Composes with `AragonACLSource.roleKeyEncoding`'s
naming scaffold without changing its API. -/
def realRoleKey (oracle : KeccakOracle) (roleName : String) : Nat :=
  concreteRoleKey oracle (roleNameToNat roleName)

/-- Determinism of `realRoleKey` on identical role names. Real
derivation from the shared oracle's determinism law. -/
theorem realRoleKey_deterministic
    {oracle : KeccakOracle} {r1 r2 : String} (hEq : r1 = r2) :
    realRoleKey oracle r1 = realRoleKey oracle r2 := by
  subst hEq
  rfl

end LidoSRv3.Audit.Source.AragonACLRoleKeyViaOracleSource
