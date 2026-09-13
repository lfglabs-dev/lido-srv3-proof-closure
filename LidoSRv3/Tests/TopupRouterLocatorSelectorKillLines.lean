import LidoSRv3.Audit.Source.TopupRouterLocatorCall

/-! # Kill-lines for `TopupRouterLocatorCall.selector`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned TopUpGateway `LOCATOR.stakingRouter()` STATICCALL
selector against ABI-selector mutations. -/

namespace LidoSRv3.Tests.TopupRouterLocatorSelectorKillLines

open LidoSRv3.Audit.Source.TopupRouterLocatorCall

/-- **Kill-line: pinned LidoLocator `stakingRouter()` STATICCALL
selector.**

bytes4(keccak256("stakingRouter()")) = 0xef6c064c. -/
theorem selector_pinned : selector = 0xef6c064c := rfl

/-- **Kill-line: the selector fits uint32 (bytes4).** -/
theorem selector_fits_uint32 : selector < 2 ^ 32 := by decide

/-- **Kill-line: the selector is non-zero.** -/
theorem selector_nonzero : selector ≠ 0 := by decide

/-- **Kill-line: this locator selector differs from every other
Piste-A STATICCALL selector.**

Distinctness against `TopupCredentialCall.selector` (0xf85c6ceb),
`TopupBeaconCallee.selector` (0x22895118), and the two admission
selectors — refuting mutants that would collapse two selectors. -/
theorem selector_distinct_from_credential :
    selector ≠ 0xf85c6ceb := by decide
theorem selector_distinct_from_beacon_deposit :
    selector ≠ 0x22895118 := by decide
theorem selector_distinct_from_auth :
    selector ≠ 0x644862de := by decide
theorem selector_distinct_from_canDeposit :
    selector ≠ 0xe78a5875 := by decide

#print axioms selector_pinned
#print axioms selector_fits_uint32
#print axioms selector_nonzero
#print axioms selector_distinct_from_credential

end LidoSRv3.Tests.TopupRouterLocatorSelectorKillLines
