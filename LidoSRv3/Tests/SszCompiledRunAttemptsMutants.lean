import LidoSRv3.Audit.Source.SszCompiledRunAttempts

set_option autoImplicit false
namespace LidoSRv3.Tests.SszCompiledRunAttemptsMutants

open LidoSRv3.Audit.Source.SszCompiledRunAttempts

theorem claimed_kill_line : claimed ≠ "" := by decide

#print axioms claimed_kill_line

end LidoSRv3.Tests.SszCompiledRunAttemptsMutants
