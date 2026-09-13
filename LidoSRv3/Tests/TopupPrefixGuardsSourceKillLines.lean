import LidoSRv3.Audit.Source.TopupPrefixGuardsSource

/-! # Kill-lines for `TopupPrefixGuardsSource`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned StakingRouter.topUp:686-716 prefix guards.**

`TopupPrefixGuardsSource` defines:
- `callerIsTopupGateway caller topupGateway = decide (caller = topupGateway)`.
- `keysListNonEmpty keyIndices = decide (keyIndices.length ≠ 0)`.
- `wcTypeIsType2 wcTypeByte = decide (wcTypeByte = 2)`.
- `wcType2Byte = 2`.
- Composite `allPrefixGuardsPass`.

These kill-lines pin the exact semantics and demonstrate boundary
cases. -/

namespace LidoSRv3.Tests.TopupPrefixGuardsSourceKillLines

open LidoSRv3.Audit.Source.TopupPrefixGuardsSource

/-- **Kill-line: caller equal to gateway is admitted.** -/
theorem callerIsTopupGateway_at_witness :
    callerIsTopupGateway 100 100 = true := by
  unfold callerIsTopupGateway
  decide

/-- **Kill-line: distinct caller and gateway is rejected.** -/
theorem callerIsTopupGateway_rejects_distinct :
    callerIsTopupGateway 100 200 = false := by
  unfold callerIsTopupGateway
  decide

/-- **Kill-line: nonempty keys list is admitted.** -/
theorem keysListNonEmpty_at_witness :
    keysListNonEmpty [1, 2, 3] = true := by
  unfold keysListNonEmpty
  decide

/-- **Kill-line: empty keys list is rejected.** -/
theorem keysListNonEmpty_rejects_empty :
    keysListNonEmpty [] = false := by
  unfold keysListNonEmpty
  decide

/-- **Kill-line: wcType2Byte pinned at 2 (WC_TYPE_2 constant).** -/
theorem wcType2Byte_pinned :
    wcType2Byte = 2 := rfl

/-- **Kill-line: wcTypeIsType2 admits wcTypeByte = 2.** -/
theorem wcTypeIsType2_at_two :
    wcTypeIsType2 2 = true := by
  unfold wcTypeIsType2
  decide

/-- **Kill-line: wcTypeIsType2 rejects wcTypeByte = 1 (type-1 module).** -/
theorem wcTypeIsType2_rejects_type_1 :
    wcTypeIsType2 1 = false := by
  unfold wcTypeIsType2
  decide

/-- **Kill-line: wcTypeIsType2 rejects wcTypeByte = 0 (uninitialized).** -/
theorem wcTypeIsType2_rejects_zero :
    wcTypeIsType2 0 = false := by
  unfold wcTypeIsType2
  decide

#print axioms callerIsTopupGateway_at_witness
#print axioms callerIsTopupGateway_rejects_distinct
#print axioms keysListNonEmpty_at_witness
#print axioms keysListNonEmpty_rejects_empty
#print axioms wcType2Byte_pinned
#print axioms wcTypeIsType2_at_two
#print axioms wcTypeIsType2_rejects_type_1
#print axioms wcTypeIsType2_rejects_zero

end LidoSRv3.Tests.TopupPrefixGuardsSourceKillLines
