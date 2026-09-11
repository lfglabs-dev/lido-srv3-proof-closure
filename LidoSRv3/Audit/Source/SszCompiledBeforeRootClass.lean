import LidoSRv3.Audit.Source.SszCompiledClEntry

/-!
Classification of `beforeRoot` / `slotSibling` / `rootCall` errors on the
selected compiled CL entry
(`SszRootCallHarness.verify` → `_verifyValidator`,
`CLValidatorVerifier.sol:44-57` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
selector `0x2e77b4ba`, inspected IR
`audit/ssz-compiled-cl-entry/solidity/inspected-cl-entry-ir.yul` 43-114).

EIP-4788 authenticity/freshness remain declared. Compilation, crypto,
gas and consensus stay outside. Additive: no existing file is edited.

CLAIM: grok owns ssz-beforeroot-class since 2026-09-11
-/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.SszCompiledBeforeRootClass

open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.SszCompiledClEntry
open LidoSRv3.Audit.Source.SszWrapperIndex hiding Error
open LidoSRv3.Audit.Source.TrioReserve1

def claimed : String := "grok owns ssz-beforeroot-class since 2026-09-11"

#print axioms claimed

end LidoSRv3.Audit.Source.SszCompiledBeforeRootClass
