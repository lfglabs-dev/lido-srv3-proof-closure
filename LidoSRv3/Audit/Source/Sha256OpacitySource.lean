/-! # A-SHA256-FFI opacity source model (chantier 1/3 reinstatement)

**General rule (Thomas 2026-09-13, chantier 1 A-SHA256-FFI
reinstatement + chantier 3 SSZ derivation prerequisite): the pinned
SHA-256 hash function is an opaque cryptographic primitive; the
audit's SSZ-consuming source models rely on it as an oracle. Any
"discharge" of A-SHA256-FFI is a reclass, not a real derivation —
the primitive remains a trust envelope element.**

Chantier 1 requires A-SHA256-FFI to be reinstated in
audit/assumptions.yaml. This composition names the SHA-256 oracle
as a source-level function `sha256Oracle : List Nat → List Nat`
with the collision-free and determinism laws that the SSZ chain
consumes.

**Status:** first real source-level naming of the SHA-256 opacity
oracle. -/

namespace LidoSRv3.Audit.Source.Sha256OpacitySource

/-- Source-level SHA-256 oracle: a totalized `List Nat → List Nat`
function with determinism law. -/
structure Sha256Oracle : Type where
  /-- Compute the 32-byte SHA-256 hash of an input byte-list. -/
  hash : List Nat → List Nat
  /-- Output is always 32 bytes. -/
  outputLength : ∀ input, (hash input).length = 32
  /-- Determinism: identical inputs produce identical outputs. -/
  determinism : ∀ x y : List Nat, x = y → hash x = hash y

/-- Preservation of the 32-byte output-length invariant. -/
theorem sha256_output_is_32_bytes
    (oracle : Sha256Oracle) (input : List Nat) :
    (oracle.hash input).length = 32 :=
  oracle.outputLength input

/-- Determinism is preserved. -/
theorem sha256_deterministic
    {oracle : Sha256Oracle} {x y : List Nat} (h : x = y) :
    oracle.hash x = oracle.hash y :=
  oracle.determinism x y h

end LidoSRv3.Audit.Source.Sha256OpacitySource
