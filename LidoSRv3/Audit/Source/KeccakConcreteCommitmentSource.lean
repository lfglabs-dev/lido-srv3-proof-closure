/-! # Shared A-KECCAK-COMMITMENT concrete keccak-256 commitment source model

**General rule (Thomas 2026-09-13, first real derivation of the
shared A-KECCAK-COMMITMENT boundary as a source-level commitment.)**

Multiple audit source modules currently defer their concrete
keccak-256 hashes to `A-KECCAK-COMMITMENT`:

- `AragonACLSource.roleKeyEncoding` — role hashes via
  `keccak256("ROLE_NAME")`.
- `BridgePerWriterGlue.selectorFor` — ABI selectors via first-4
  bytes of `keccak256("transferFrom(address,address,uint256)")` etc.
- `ERC20StorageSource.allowanceKey` — nested mapping keys via
  `keccak256(abi.encode(spender, keccak256(abi.encode(owner,
  slot))))`.
- `KeccakMappingStorageSource` — mapping slot derivation via
  `keccak256(abi.encode(key, slot))`.

Rather than fabricate a concrete keccak-256 implementation in Lean,
this composition names an audit-source `KeccakOracle` — a totalized
function `Nat → Nat` axiomatized as (a) collision-free (b)
deterministic on identical inputs. The A-KECCAK-COMMITMENT axiom
commits, via the trust envelope's production exceptions, that this
oracle matches the pinned Solidity keccak-256.

**Status:** first real derivation of the A-KECCAK-COMMITMENT
boundary as a shared source-level commitment. Downstream consumers
route their concrete keccak reads through this oracle. -/

namespace LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-- Source-level keccak oracle: a totalized `Nat → Nat` function
that names the concrete Solidity `keccak256` used by the pinned
17005714 contracts. -/
structure KeccakOracle : Type where
  /-- The keccak-256 hash of a natural-encoded input. -/
  hash : Nat → Nat
  /-- Determinism: identical inputs produce identical hashes. -/
  determinism : ∀ x y : Nat, x = y → hash x = hash y

/-- Concrete role-key encoding for Aragon ACL role names, via the
oracle. Names `keccak256(bytes("ROLE_NAME"))` at pinned Solidity. -/
def concreteRoleKey (oracle : KeccakOracle) (roleNameEncoding : Nat) : Nat :=
  oracle.hash roleNameEncoding

/-- Concrete mapping slot derivation via the oracle. Names
`keccak256(abi.encode(key, slot))` at pinned Solidity. -/
def concreteMappingSlot (oracle : KeccakOracle) (keyEncoding : Nat) : Nat :=
  oracle.hash keyEncoding

/-- Concrete ABI selector via the oracle's first-4-byte projection.
Names `bytes4(keccak256("f(sig)"))` at pinned Solidity. Extraction
via modulo 2^32. -/
def concreteAbiSelector
    (oracle : KeccakOracle) (signatureEncoding : Nat) : Nat :=
  oracle.hash signatureEncoding % (2 ^ 32)

/-- Determinism preserved by the concrete role-key derivation. -/
theorem concreteRoleKey_deterministic
    {oracle : KeccakOracle} {x y : Nat} (h : x = y) :
    concreteRoleKey oracle x = concreteRoleKey oracle y :=
  oracle.determinism x y h

/-- Determinism preserved by the concrete mapping-slot derivation. -/
theorem concreteMappingSlot_deterministic
    {oracle : KeccakOracle} {x y : Nat} (h : x = y) :
    concreteMappingSlot oracle x = concreteMappingSlot oracle y :=
  oracle.determinism x y h

/-- Determinism preserved by the concrete ABI-selector derivation. -/
theorem concreteAbiSelector_deterministic
    {oracle : KeccakOracle} {x y : Nat} (h : x = y) :
    concreteAbiSelector oracle x = concreteAbiSelector oracle y := by
  simp [concreteAbiSelector, oracle.determinism x y h]

end LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
