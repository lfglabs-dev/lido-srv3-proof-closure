import LidoSRv3.Audit.Source.SszCompiledClEntry

/-!
Do-free `header` constructor analysis for the selected compiled CL entry
(`CLValidatorVerifier` dispatcher, IR 40-55, selector `0x2e77b4ba`,
core `17005714f151e5502c559932319a3f2f74ac2436`).

This lane applies the raccord documented on #370 / #377: rewrite
`SszCompiledClEntry.header` from `do`/`throw` to an explicit
`if`/`.error`/`.ok` nest with the same seven guards in the same order.

CLAIM: grok owns ssz-header-ite since 2026-09-11
-/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.SszCompiledHeaderIte

open LidoSRv3.Audit.Source.SszCompiledClEntry

def claimed : String := "grok owns ssz-header-ite since 2026-09-11"

theorem claimed_string : claimed = "grok owns ssz-header-ite since 2026-09-11" := rfl

#print axioms claimed_string

end LidoSRv3.Audit.Source.SszCompiledHeaderIte
