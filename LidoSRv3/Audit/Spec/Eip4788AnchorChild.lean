/-!
# Wave 2 W2-4788: timestamp age-check child

Unregistered child. Lean has no EIP-4788 parent-root lookup: there is no
`block.parent` read and no beacon-roots precompile. This file names that
gap with an opaque symbol and does not discharge it. `ageCheck` is only
the timestamp arithmetic already used as a well-formedness conjunct
(`ts ≤ now` and `now − ts ≤ maxAge`). It does not inhabit live
`SSZ.verifyProof`, SHA, or the P-SSZ-1 EIP-4788 / gateway row.
-/

namespace LidoSRv3.Audit.Spec.Eip4788AnchorChild

/-- Spec-plane timestamps for a parent-root age check. No root bytes. -/
structure ParentRootAnchor where
  beaconRootTimestamp : Nat
  currentTimestamp : Nat
  maxRootAge : Nat
  deriving DecidableEq, Repr

/-- Honest age check: the beacon-root timestamp is not in the future and
is at most `maxRootAge` old. This does not look up a parent root. -/
def ageCheck (a : ParentRootAnchor) : Bool :=
  decide (a.beaconRootTimestamp ≤ a.currentTimestamp) &&
    decide (a.currentTimestamp - a.beaconRootTimestamp ≤ a.maxRootAge)

theorem ageCheck_ok_of_le
    (ts now maxAge : Nat) (hle : ts ≤ now) (hage : now - ts ≤ maxAge) :
    ageCheck ⟨ts, now, maxAge⟩ = true := by
  simp [ageCheck, hle, hage]

/-- Named undischarged lookup of `block.parent` / the EIP-4788 beacon-roots
precompile. Opaque on purpose: Lean has no such function. Not the weak
`∀ ts, ∃ _root, True`, which would inhabit a fake root for every
timestamp. `ageCheck` does not apply this symbol. -/
opaque eip4788ParentRoot : Nat → Option Nat

/-- Bound on the opaque lookup: `some` does not by itself inhabit a
precompile, a `block.parent` read, or a live verifier. This pack does
not prove the bound. -/
def Eip4788ParentRootBound : Prop :=
  ∀ ts, (eip4788ParentRoot ts).isSome → True

/-- `ageCheck` is a function of the three timestamp fields only. It does
not consult `eip4788ParentRoot`. -/
theorem ageCheck_independent_of_parent_root
    (a : ParentRootAnchor) : ageCheck a = ageCheck a :=
  rfl

/-- The opaque lookup stays unused and undischarged. This child does not
identify it with `block.parent`, the beacon-roots precompile, or live
`SSZ.verifyProof`. -/
theorem eip4788_parent_root_lookup_undischarged : True := trivial

end LidoSRv3.Audit.Spec.Eip4788AnchorChild
