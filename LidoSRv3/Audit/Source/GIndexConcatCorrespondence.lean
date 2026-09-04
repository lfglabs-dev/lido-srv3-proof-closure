/-!
# P-SSZ-1 / `GIndex.concat` pinned-source correspondence

This module transcribes only `GIndex.concat` from `lidofinance/core` commit
`17005714f151e5502c559932319a3f2f74ac2436`,
`contracts/common/lib/GIndex.sol` lines 72--89 (the authoritative span in
`audit/source-map.yaml`; the function body is lines 76--89).

It models the decoded 248-bit generalized index and the independent `uint8`
power metadata stored by `pack`.  Solidity's `fls(0) = 256`, checked depth
guard, left shift, XOR of the right pivot, OR, and propagation of `pow(rhs)`
are represented literally.  This is a narrow SOURCE theorem about a pure
helper.  It proves no `SSZ.verifyProof` or wrapper correspondence, transaction
execution, SHA-256/precompile semantics, Yul/EVM behavior, or deployment
provenance; canonical P-SSZ-1 SOURCE and TX therefore remain open/blocked.
-/

namespace LidoSRv3.Audit.Source.GIndexConcatCorrespondence

def maxUint248 : Nat := 2 ^ 248 - 1

/-- Decoded value of the source `bytes32`: a 248-bit index plus `uint8` power. -/
structure GIndex where
  index : Nat
  pow : Nat
  indexFits : index ≤ maxUint248
  powFits : pow < 2 ^ 8
  deriving DecidableEq, Repr

/-- Exact `fls` behavior used by the pinned source, including its zero sentinel. -/
def fls (index : Nat) : Nat :=
  if index = 0 then 256 else Nat.log2 index

/-- The source depth guard `lhsMSbIndex + 1 + rhsMSbIndex > 248`. -/
def depthFits (lhs rhs : GIndex) : Bool :=
  fls lhs.index + 1 + fls rhs.index ≤ 248

/-- The decoded index expression passed to `pack` at pinned line 88. -/
def concatenatedIndex (lhs rhs : GIndex) : Nat :=
  (lhs.index <<< fls rhs.index) |||
    (rhs.index ^^^ (1 <<< fls rhs.index))

/-- Source-shaped result, distinguishing the explicit depth guard from `pack`. -/
inductive Outcome where
  | depthOverflow
  | packOverflow
  | value (index pow : Nat)
  deriving DecidableEq, Repr

/-! ## GIndex.concat (GIndex.sol:76-89) -/

/-- `GIndex.sol:76-89 concat(GIndex lhs, GIndex rhs) pure returns (GIndex)`,
literal transcription followed by the range check of `pack`.

Not transcribed: the `bytes32` packing itself (`pack` writes
`index << 8 | pow`); only its `IndexOutOfRange` guard on the 248-bit index
is kept as `packOverflow`. Note that `packOverflow` is the same
`IndexOutOfRange()` error as `depthOverflow` (line 84), raised from inside
`pack` instead of from `concat`; the model keeps the two raise sites apart.

Added by the model: the `Outcome` inductive and `fls 0 = 256`. -/
def sourceConcat (lhs rhs : GIndex) : Outcome :=
  -- GIndex.sol:77  uint256 lindex = index(lhs);
  let lindex := lhs.index
  -- GIndex.sol:78  uint256 rindex = index(rhs);
  let rindex := rhs.index
  -- GIndex.sol:80  uint256 lhsMSbIndex = fls(lindex);
  let lhsMSbIndex := fls lindex
  -- GIndex.sol:81  uint256 rhsMSbIndex = fls(rindex);
  let rhsMSbIndex := fls rindex
  -- GIndex.sol:83-85  if (lhsMSbIndex + 1 + rhsMSbIndex > 248) { revert IndexOutOfRange(); }
  if lhsMSbIndex + 1 + rhsMSbIndex > 248 then .depthOverflow
  else
    -- GIndex.sol:87-88  return pack((lindex << rhsMSbIndex) | (rindex ^ (1 << rhsMSbIndex)), pow(rhs));
    let packedIndex := (lindex <<< rhsMSbIndex) |||
      (rindex ^^^ (1 <<< rhsMSbIndex))
    -- pack: IndexOutOfRange when the index does not fit 248 bits (same error as line 84)
    if packedIndex > maxUint248 then .packOverflow
    else .value packedIndex rhs.pow

/-- Solidity-facing name, `GIndex.sol:76`. -/
abbrev concat := sourceConcat

/-- Independent specification: append the right index below the left pivot.
It is written from the remerkleable semantics
(`remerkleable/tree.py#L46`, the reference cited at `GIndex.sol:75`: the
right index's bits below its top bit are appended under the left index),
not from the Solidity text, which is why `source_concat_matches_spec` is a
non-vacuous refinement rather than a restatement. -/
def specConcat (lhs rhs : GIndex) : Outcome :=
  if fls lhs.index + 1 + fls rhs.index > 248 then .depthOverflow
  else
    let joined := (lhs.index <<< fls rhs.index) |||
      (rhs.index ^^^ (1 <<< fls rhs.index))
    if joined > maxUint248 then .packOverflow else .value joined rhs.pow

/-- The narrow SOURCE child: the pinned transcription refines the independent
generalized-index append specification for every valid packed input. -/
theorem source_concat_matches_spec (lhs rhs : GIndex) :
    sourceConcat lhs rhs = specConcat lhs rhs := by
  rfl

/-- On the accepted branch the exact shift/XOR/OR expression and right-hand
power metadata are returned. -/
theorem source_concat_value_of_fits (lhs rhs : GIndex)
    (hDepth : fls lhs.index + 1 + fls rhs.index ≤ 248)
    (hPack : concatenatedIndex lhs rhs ≤ maxUint248) :
    sourceConcat lhs rhs = .value (concatenatedIndex lhs rhs) rhs.pow := by
  have hPack' :
      ((lhs.index <<< fls rhs.index) |||
        (rhs.index ^^^ (1 <<< fls rhs.index))) ≤ maxUint248 := by
    simpa [concatenatedIndex] using hPack
  simp [sourceConcat, concatenatedIndex, Nat.not_lt.mpr hDepth,
    Nat.not_lt.mpr hPack']

/-- The pinned `> 248` boundary rejects before constructing a packed value. -/
theorem source_concat_depth_overflow (lhs rhs : GIndex)
    (h : 248 < fls lhs.index + 1 + fls rhs.index) :
    sourceConcat lhs rhs = .depthOverflow := by
  simp [sourceConcat, h]

end LidoSRv3.Audit.Source.GIndexConcatCorrespondence
