import LidoSRv3.Audit.Source.ReservePayableCallSource

/-! # Kill-lines for `ReservePayableCallSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned payable CALL frame shape (D-TRANSFER-1).**

`ReservePayableCallSource.receiveDepositableEtherFrame` names the
pinned `Lido.sol:885 stakingRouter.receiveDepositableEther.value(_amount)()`
frame as `{ target, value, selectorPrefix, calldata }`.  Three
projection identities are proved:
- `receiveDepositableEtherFrame_target_eq`: target = stakingRouterAddr.
- `receiveDepositableEtherFrame_value_eq`: value = amount.
- `receiveDepositableEtherFrame_calldata_eq`: calldata = [] (empty
  payload after selector).

These kill-lines exhibit concrete counterexamples for mutants that
would rewrite any of the three projections. -/

namespace LidoSRv3.Tests.ReservePayableCallKillLines

open LidoSRv3.Audit.Source.ReservePayableCallSource

/-- **Kill-line: the frame's target is exactly `stakingRouterAddr`, not
zero.**

Applied to `stakingRouterAddr = 0x1234`, the pinned frame has
`target = 0x1234`.  A mutant that hard-coded `target = 0` would fail. -/
theorem receiveDepositableEtherFrame_target_at_witness :
    (receiveDepositableEtherFrame 0x1234 100 0xdeadbeef).target = 0x1234 := rfl

/-- **Kill-line: the frame's value equals the requested amount.**

Applied to `amount = 100`, the pinned frame has `value = 100`.  A
mutant that zero'd the value (spending nothing on a payable CALL)
would fail. -/
theorem receiveDepositableEtherFrame_value_at_witness :
    (receiveDepositableEtherFrame 0x1234 100 0xdeadbeef).value = 100 := rfl

/-- **Kill-line: the frame's calldata is empty (no payload after
selector).**

The pinned `receiveDepositableEther.value(_amount)()` has NO extra
arguments after the selector — the value transfer is the entire
payload.  A mutant that stuffed extra calldata would fail. -/
theorem receiveDepositableEtherFrame_calldata_is_empty :
    (receiveDepositableEtherFrame 0x1234 100 0xdeadbeef).calldata = [] := rfl

/-- **Kill-line: the frame's selectorPrefix passes through the argument.**

The frame carries the caller-supplied `selectorPrefix` (the 4-byte
function selector).  A mutant that hard-coded a different selector
would fail on any non-trivial witness. -/
theorem receiveDepositableEtherFrame_selectorPrefix_passes_through :
    (receiveDepositableEtherFrame 0x1234 100 0xdeadbeef).selectorPrefix = 0xdeadbeef := rfl

/-- **Kill-line: the frame's target does NOT equal the value.**

`target = 0x1234, value = 100` — these are distinct fields of the
payable-CALL frame.  A mutant that conflated the two (e.g., wrote
`value` into `target`) would produce `target = 100 ≠ 0x1234`. -/
theorem receiveDepositableEtherFrame_target_distinct_from_value :
    (receiveDepositableEtherFrame 0x1234 100 0xdeadbeef).target ≠
      (receiveDepositableEtherFrame 0x1234 100 0xdeadbeef).value := by
  simp [receiveDepositableEtherFrame]

#print axioms receiveDepositableEtherFrame_target_at_witness
#print axioms receiveDepositableEtherFrame_value_at_witness
#print axioms receiveDepositableEtherFrame_calldata_is_empty
#print axioms receiveDepositableEtherFrame_selectorPrefix_passes_through
#print axioms receiveDepositableEtherFrame_target_distinct_from_value

end LidoSRv3.Tests.ReservePayableCallKillLines
