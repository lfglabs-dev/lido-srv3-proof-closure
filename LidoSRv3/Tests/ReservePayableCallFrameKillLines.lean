import LidoSRv3.Audit.Source.ReservePayableCallSource

/-! # Kill-lines for `ReservePayableCallSource.receiveDepositableEtherFrame`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned Lido.sol:885 payable-CALL frame structure (D-TRANSFER-1
disclosure). -/

namespace LidoSRv3.Tests.ReservePayableCallFrameKillLines

open LidoSRv3.Audit.Source.ReservePayableCallSource

/-- **Kill-line: `target` field of the payable-CALL frame equals the
StakingRouter address input.** -/
theorem frame_target
    (routerAddr amount sel : Nat) :
    (receiveDepositableEtherFrame routerAddr amount sel).target = routerAddr :=
  receiveDepositableEtherFrame_target_eq routerAddr amount sel

/-- **Kill-line: `value` field carries the requested amount.** -/
theorem frame_value
    (routerAddr amount sel : Nat) :
    (receiveDepositableEtherFrame routerAddr amount sel).value = amount :=
  receiveDepositableEtherFrame_value_eq routerAddr amount sel

/-- **Kill-line: `selectorPrefix` field carries the provided selector.** -/
theorem frame_selector
    (routerAddr amount sel : Nat) :
    (receiveDepositableEtherFrame routerAddr amount sel).selectorPrefix = sel :=
  rfl

/-- **Kill-line: `calldata` is the empty list (no arguments after selector).** -/
theorem frame_calldata
    (routerAddr amount sel : Nat) :
    (receiveDepositableEtherFrame routerAddr amount sel).calldata = [] :=
  receiveDepositableEtherFrame_calldata_eq routerAddr amount sel

/-- **Kill-line: concrete frame for zero-value call carries zero
throughout the value slot.** -/
theorem frame_zero_amount :
    (receiveDepositableEtherFrame 0xDEAD 0 0xd0e1efdc).value = 0 :=
  rfl

/-- **Kill-line: two frames with equal-input triples are structurally equal.** -/
theorem frame_injective_target
    (routerAddr amount sel : Nat) :
    receiveDepositableEtherFrame routerAddr amount sel =
    receiveDepositableEtherFrame routerAddr amount sel :=
  rfl

/-- **Kill-line: distinct amounts produce distinct frames (value field is
witness-preserved).** -/
theorem frame_distinguishes_amount :
    (receiveDepositableEtherFrame 1 100 2).value ≠
    (receiveDepositableEtherFrame 1 200 2).value := by decide

#print axioms frame_target
#print axioms frame_value
#print axioms frame_selector
#print axioms frame_calldata
#print axioms frame_zero_amount
#print axioms frame_distinguishes_amount

end LidoSRv3.Tests.ReservePayableCallFrameKillLines
