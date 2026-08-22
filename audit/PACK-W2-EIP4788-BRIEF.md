# Pack W2-EIP4788 brief — timestamp age-check child

One node, one PR. Not Best-of-N. No new guarantee IDs. Lean has no
EIP-4788 parent-root lookup. Do not discharge it.

## Frozen interfaces used

None from Wave 0. This child is a standalone timestamp age-check. It does
not widen `SszWitness` and does not inhabit the EIP-4788 / gateway row on
P-SSZ-1.

## Work

1. `ParentRootAnchor` and `ageCheck`: `ts ≤ now` and `now − ts ≤ maxAge`.
2. `ageCheck_ok_of_le` from those two inequalities.
3. Opaque `eip4788ParentRoot : Nat → Option Nat`. Named hyp
   `Eip4788ParentRootBound` is `isSome → True`. Unused by `ageCheck`.
   Not a `∀ ts, ∃ root, True` fake lookup.
4. `ageCheck_independent_of_parent_root` records that `ageCheck` does
   not consult the opaque lookup. The lookup stays undischarged.

## Kill-lines

- Mutant `ageCheck` that keeps only `ts ≤ now` accepts `⟨0, 100, 1⟩`.
  Honest `ageCheck` is false (age 100 exceeds `maxRootAge` 1).

## Out of scope

Discharging the parent-root lookup, live `SSZ.verifyProof`, SHA / Yul,
deployed beacon-roots precompile, gateway/bus.
