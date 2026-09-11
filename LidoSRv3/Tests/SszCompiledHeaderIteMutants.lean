import LidoSRv3.Audit.Source.SszCompiledHeaderIte

set_option autoImplicit false
namespace LidoSRv3.Tests.SszCompiledHeaderIteMutants

open LidoSRv3.Audit.Source.SszCompiledHeaderIte

theorem claimed_kill_line : claimed ≠ "" := by decide

#print axioms claimed_kill_line

end LidoSRv3.Tests.SszCompiledHeaderIteMutants
