import LidoSRv3.Audit.Source.Sha256OpacitySource

/-! # SSZ List hash-tree-root (mix_in_length) source model

**General rule (Thomas 2026-09-13, chantier 3 SSZ derivation
prerequisite): the pinned SSZ `List[T, N]` type's hash-tree-root
mixes in the list length via `hash(concat(merkleize(chunks, N),
length_as_32_bytes))`. This composition names the pinned
mix_in_length transform.**

**Status:** first real source-level naming of the pinned SSZ
List root's mix_in_length layer. -/

namespace LidoSRv3.Audit.Source.SszListRootSource

open LidoSRv3.Audit.Source.Sha256OpacitySource

/-- Encode a Nat length as a 32-byte little-endian sequence.
Source-level abstraction; downstream consumers refine to the
concrete uint256 little-endian encoder. -/
def lengthAs32Bytes (n : Nat) : List Nat := [n]

/-- Concatenate two hashes into a 64-byte input. -/
def concatHashes (l r : List Nat) : List Nat := l ++ r

/-- Mix_in_length: hash(concat(mainRoot, length_as_32_bytes)). -/
def mixInLength
    (oracle : Sha256Oracle) (mainRoot : List Nat) (length : Nat) : List Nat :=
  oracle.hash (concatHashes mainRoot (lengthAs32Bytes length))

/-- Mix_in_length is deterministic on identical inputs. -/
theorem mixInLength_deterministic
    {oracle : Sha256Oracle} {m1 m2 : List Nat} {n1 n2 : Nat}
    (hMain : m1 = m2) (hLen : n1 = n2) :
    mixInLength oracle m1 n1 = mixInLength oracle m2 n2 := by
  subst hMain
  subst hLen
  rfl

/-- Mix_in_length output has the SHA-256 32-byte length. -/
theorem mixInLength_output_length
    (oracle : Sha256Oracle) (mainRoot : List Nat) (length : Nat) :
    (mixInLength oracle mainRoot length).length = 32 := by
  unfold mixInLength
  exact oracle.outputLength (concatHashes mainRoot (lengthAs32Bytes length))

end LidoSRv3.Audit.Source.SszListRootSource
