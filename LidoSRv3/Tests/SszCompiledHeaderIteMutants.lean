import LidoSRv3.Audit.Source.SszCompiledHeaderIte

/-! Named kill-lines for the do-free compiled `header`. -/
set_option autoImplicit false
namespace LidoSRv3.Tests.SszCompiledHeaderIteMutants

open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.SszCompiledHeaderIte
open LidoSRv3.Audit.Source.SszCompiledClEntry
open LidoSRv3.Audit.Source.SszWrapperIndex hiding Error
open LidoSRv3.Audit.Source.TrioReserve1

/-- Kill-line: nonzero `msg.value` is ABI, not a successful dispatcher. -/
theorem header_value_kill_line (st : EVM.State)
    (hv : st.executionEnv.weiValue.toNat ≠ 0) :
    header st = .error (.abi .abi) :=
  header_of_nonzero_value st hv

/-- Kill-line: calldata shorter than the selector is ABI. -/
theorem header_short_calldata_kill_line (st : EVM.State)
    (hv : st.executionEnv.weiValue.toNat = 0)
    (hs : (UInt256.ofNat st.executionEnv.calldata.size).toNat < 4) :
    header st = .error (.abi .abi) :=
  header_of_short_calldata st hv hs

/-- Kill-line: a `header` error is never a slot-panic. -/
theorem header_error_not_panic11_kill_line (st : EVM.State)
    (e : SszCompiledClEntry.Error)
    (h : header st = .error e) :
    e ≠ .panic11 := by
  have he := header_error_is_abi st e h
  intro hp
  rw [he] at hp
  cases hp

/-- Kill-line: nonzero value cannot be a successful compiled `run`. -/
theorem run_value_kills_success
    (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context afterState : EVM.State)
    (hv : context.executionEnv.weiValue.toNat ≠ 0)
    (h : (run fuel cfg external world context).outcome = .ok afterState) :
    False := by
  have hr := run_of_nonzero_value fuel cfg external world context hv
  rw [hr] at h
  cases h

/-- Kill-line: a `beforeRoot` error is not a proof-loop constructor. -/
theorem beforeRoot_error_not_proof_kill_line
    (fuel : Nat) (context : EVM.State) (e : SszCompiledClEntry.Error)
    (h : beforeRoot fuel context = .error e) :
    e ≠ .proof .invalidProof := by
  have hc := beforeRoot_error_is_beforeRootClass fuel context e h
  intro hp
  rw [hp] at hc
  exact hc

#print axioms header_value_kill_line
#print axioms header_short_calldata_kill_line
#print axioms header_error_not_panic11_kill_line
#print axioms run_value_kills_success
#print axioms beforeRoot_error_not_proof_kill_line

end LidoSRv3.Tests.SszCompiledHeaderIteMutants
