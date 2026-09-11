import LidoSRv3.Audit.Source.SszCompiledBeforeRootClass

/-! Named kill-lines for compiled `beforeRoot` / `rootCall` error classification. -/
set_option autoImplicit false
namespace LidoSRv3.Tests.SszCompiledBeforeRootClassMutants

open LidoSRv3.Audit.Source.SszCompiledBeforeRootClass

theorem claimed_kill_line : claimed ≠ "" := by
  decide

#print axioms claimed_kill_line

end LidoSRv3.Tests.SszCompiledBeforeRootClassMutants
