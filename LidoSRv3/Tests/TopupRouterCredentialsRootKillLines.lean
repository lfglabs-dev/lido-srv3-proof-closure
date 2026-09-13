import LidoSRv3.Audit.Source.TopupRouterCredentials

/-! # Kill-lines for `TopupRouterCredentials.routerRoot` and `typeOf`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned StakingRouter ERC-7201 SRStorage root and the packed
ModuleStateConfig type-byte extraction. -/

namespace LidoSRv3.Tests.TopupRouterCredentialsRootKillLines

open LidoSRv3.Audit.Source.TopupRouterCredentials

/-- **Kill-line: pinned StakingRouter SRStorage ERC-7201 root.**

`keccak256(abi.encode(uint256(keccak256("SRStorage")) - 1)) &
~bytes32(uint256(0xff))` = 0x5648d366...d000. -/
theorem routerRoot_pinned :
    routerRoot =
      0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000 :=
  rfl

/-- **Kill-line: routerRoot fits uint256.** -/
theorem routerRoot_fits_uint256 : routerRoot < 2 ^ 256 := by decide

/-- **Kill-line: routerRoot is non-zero.** -/
theorem routerRoot_nonzero : routerRoot ≠ 0 := by decide

/-- **Kill-line: routerRoot's low byte is 0 (ERC-7201 zero-page requirement).** -/
theorem routerRoot_zero_lowbyte : routerRoot % 256 = 0 := by decide

/-- **Kill-line: `typeOf config` extracts the top byte (bits 232..239).**

A mutant that shifted the extraction location would refute the
pinned SRTypes.ModuleStateConfig layout: address20 (0..159), four
uint16 (160..223), status uint8 (224..231), type uint8 (232..239). -/
theorem typeOf_zero : typeOf ⟨0, by decide⟩ = 0 := by decide

/-- **Kill-line: `typeOf` returns byte at offset 232.**

Witness: a word with just the `2` byte at offset 232 extracts to 2. -/
theorem typeOf_type2 :
    typeOf ⟨2 * 2^232, by decide⟩ = 2 := by decide

/-- **Kill-line: `typeOf` returns byte at offset 232 (255 case).**

Witness: 0xff at offset 232 (upper 8 bits of top byte). -/
theorem typeOf_max_byte :
    typeOf ⟨255 * 2^232, by decide⟩ = 255 := by decide

#print axioms routerRoot_pinned
#print axioms routerRoot_zero_lowbyte
#print axioms typeOf_type2
#print axioms typeOf_max_byte

end LidoSRv3.Tests.TopupRouterCredentialsRootKillLines
