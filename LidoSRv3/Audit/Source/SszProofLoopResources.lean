import LidoSRv3.Audit.Source.SszProofCalldataStep
/-! Resource and environment observations for SSZ's existing CALL primitive.
Core pin17005714, engine pin f7e4ee0d. These results account for the CALL's
actual access fee and SHA64 precompile charge only. They do not charge the
surrounding memory/loop opcodes or establish compiler/X execution.
-/
namespace LidoSRv3.Audit.Source.SszProofLoopResources
open EvmYul EvmYul.EVM SszShaCallMemory SszShaCallBytes

theorem access_le (st : EVM.State) : Caccess shaAddress st.substate ≤ 2600 := by
  unfold Caccess
  split <;> decide +kernel

theorem extra_eq (st : EVM.State) :
    Cextra shaAddress shaAddress (UInt256.ofNat 0) st.accountMap st.substate =
      Caccess shaAddress st.substate := by
  have hz : (UInt256.ofNat 0 != (⟨0⟩ : UInt256)) = false := by decide +kernel
  simp [Cextra, Cxfer, Cnew, hz]

/-- A conservative bound admitting both cold and warm zero-value SHA calls. -/
theorem call_admitted (st : EVM.State) (hg : 2685 ≤ st.gasAvailable.toNat) :
    84 ≤ Ccallgas shaAddress shaAddress (UInt256.ofNat 0) st.gasAvailable
      st.accountMap st.toMachineState st.substate ∧
    Ccall shaAddress shaAddress (UInt256.ofNat 0) st.gasAvailable
      st.accountMap st.toMachineState st.substate ≤ st.gasAvailable.toNat := by
  have he := extra_eq st
  have hb := access_le st
  have ha : Cextra shaAddress shaAddress (UInt256.ofNat 0) st.accountMap st.substate ≤ st.gasAvailable.toNat := by omega
  have hc : Ccallgas shaAddress shaAddress (UInt256.ofNat 0) st.gasAvailable
      st.accountMap st.toMachineState st.substate =
      Cgascap shaAddress shaAddress (UInt256.ofNat 0) st.gasAvailable
      st.accountMap st.toMachineState st.substate := by with_unfolding_all rfl
  rw [hc]
  unfold Ccall Cgascap
  simp only [ha, ↓reduceIte]
  unfold L
  omega

/-- The actual computed result, including unchanged caller environment and
word gas accounting. No claim that all World/account fields are preserved. -/
theorem call_observations (fuel gasCost : Nat) (source gas : UInt256) (st : EVM.State)
    (hdepth : st.executionEnv.depth < 1024)
    (hgas : 84 ≤ Ccallgas shaAddress shaAddress (UInt256.ofNat 0) gas
      st.accountMap st.toMachineState st.substate)
    (hinput : (st.memory.readWithPadding 0 64).size = 64)
    (houtput : (shaOutput (st.memory.readWithPadding 0 64)).size = 32) :
    ∃ afterState : EVM.State,
      callSha (fuel+2) gasCost source gas st = .ok (UInt256.ofNat 1, afterState) ∧
      afterState.returnData = shaOutput (st.memory.readWithPadding 0 64) ∧
      afterState.memory = shaOutput (st.memory.readWithPadding 0 64) ++
        st.memory.extract 32 st.memory.size ∧
      afterState.activeWords = UInt256.ofNat (max st.activeWords.toNat 2) ∧
      afterState.executionEnv = st.executionEnv ∧
      afterState.gasAvailable = (st.gasAvailable - UInt256.ofNat gasCost) +
        (UInt256.ofNat (Ccallgas shaAddress shaAddress (UInt256.ofNat 0) gas
          st.accountMap st.toMachineState st.substate) - UInt256.ofNat 84) := by
  have hfit := gas_fits gas st
  have hactual : 84 ≤ (UInt256.ofNat (Ccallgas shaAddress shaAddress
      (UInt256.ofNat 0) gas st.accountMap st.toMachineState st.substate)).toNat := by
    change 84 ≤ _ % UInt256.size
    rwa [Nat.mod_eq_of_lt hfit]
  obtain ⟨accounts, access, htheta⟩ := theta_sha fuel st
    (AccountAddress.ofUInt256 source) (st.addAccessedAccount shaAddress).substate
    (UInt256.ofNat (Ccallgas shaAddress shaAddress (UInt256.ofNat 0) gas
      st.accountMap st.toMachineState st.substate))
    (st.memory.readWithPadding 0 64) hinput hactual
  unfold callSha
  rw [EVM.call]
  simp only [show AccountAddress.ofUInt256 (UInt256.ofNat 2) = shaAddress from rfl,
    sha_selected]
  have hzero (v : UInt256) : UInt256.ofNat 0 ≤ v := by change 0 ≤ v.toNat; omega
  simp only [hzero, hdepth, and_self, ↓reduceIte]
  rw [show (UInt256.ofNat 0).toNat = 0 by decide +kernel,
      show (UInt256.ofNat 64).toNat = 64 by decide +kernel]
  rw [htheta]
  dsimp only [Bind.bind, Except.bind, Pure.pure, Except.pure]
  have hnotfunds (v : UInt256) : ¬ UInt256.ofNat 0 > v := by change ¬ 0 > v.toNat; omega
  have hnotdepth : (st.executionEnv.depth == 1024) = false := by simp; omega
  simp only [hnotfunds, hnotdepth, Bool.not_true, decide_false, Bool.or_false,
    Bool.false_eq_true, ↓reduceIte, houtput]
  refine ⟨_, rfl, rfl, ?_, ?_, rfl, rfl⟩
  · change (shaOutput (st.memory.readWithPadding 0 64)).write 0 st.memory 0 32 = _
    exact write32 _ _ houtput
  · change UInt256.ofNat (MachineState.M (MachineState.M st.activeWords.toNat 0 64) 0 32) = _
    congr 1
    simp only [MachineState.M]
    omega



theorem word_sub_nat (a b : UInt256) (h : b.toNat ≤ a.toNat) :
    (a - b).toNat = a.toNat - b.toNat := by
  exact Fin.sub_val_of_le h

/-- Independent natural-number accounting; both subtractions and final addition
are proved not to wrap from the admitted fee and callee cost. -/
theorem returned_gas_math (g : UInt256) (cap access : Nat)
    (hcap : 84 ≤ cap) (hfee : cap + access ≤ g.toNat) :
    ((g - UInt256.ofNat (cap + access)) +
      (UInt256.ofNat cap - UInt256.ofNat 84)).toNat + access + 84 = g.toNat := by
  have hbound : g.toNat < UInt256.size := g.val.isLt
  have h84 : (UInt256.ofNat 84).toNat = 84 := by decide +kernel
  have hc : (UInt256.ofNat (cap + access)).toNat = cap + access := Nat.mod_eq_of_lt (by omega)
  have hg : (UInt256.ofNat cap).toNat = cap := Nat.mod_eq_of_lt (by omega)
  change (UInt256.toNat (g - UInt256.ofNat (cap + access)) +
    UInt256.toNat (UInt256.ofNat cap - UInt256.ofNat 84)) % UInt256.size + access + 84 = _
  rw [word_sub_nat _ _ (by rw [hc];exact hfee), word_sub_nat _ _ (by rw [h84,hg];exact hcap), hc,hg,h84]
  rw [Nat.mod_eq_of_lt (by omega)]
  omega

theorem returned_gas (st : EVM.State) (hg : 2685 ≤ st.gasAvailable.toNat) :
    ((st.gasAvailable - UInt256.ofNat (Ccall shaAddress shaAddress (UInt256.ofNat 0)
      st.gasAvailable st.accountMap st.toMachineState st.substate)) +
      (UInt256.ofNat (Ccallgas shaAddress shaAddress (UInt256.ofNat 0)
        st.gasAvailable st.accountMap st.toMachineState st.substate) - UInt256.ofNat 84)).toNat +
      Caccess shaAddress st.substate + 84 = st.gasAvailable.toNat := by
  obtain ⟨hgas,hpaid⟩ := call_admitted st hg
  have hfee : Ccall shaAddress shaAddress (UInt256.ofNat 0) st.gasAvailable
      st.accountMap st.toMachineState st.substate =
      Ccallgas shaAddress shaAddress (UInt256.ofNat 0) st.gasAvailable
      st.accountMap st.toMachineState st.substate + Caccess shaAddress st.substate := by
    rw [Ccall, extra_eq]
    with_unfolding_all rfl
  rw [hfee]
  exact returned_gas_math st.gasAvailable _ _ hgas (by rwa [hfee] at hpaid)



/-- With sufficient initial gas, a real successful SHA call costs its actual
access fee plus84, hence at most2684. No per-call fee-admission hypothesis. -/
theorem call_resource (fuel : Nat) (st : EVM.State)
    (hdepth : st.executionEnv.depth < 1024)
    (hg : 2685 ≤ st.gasAvailable.toNat)
    (hinput : (st.memory.readWithPadding 0 64).size = 64)
    (houtput : (shaOutput (st.memory.readWithPadding 0 64)).size = 32) :
    ∃ afterState : EVM.State,
      callSha (fuel+2)
        (Ccall shaAddress shaAddress (UInt256.ofNat 0) st.gasAvailable
          st.accountMap st.toMachineState st.substate)
        (UInt256.ofNat st.executionEnv.codeOwner.val) st.gasAvailable st =
          .ok (UInt256.ofNat 1, afterState) ∧
      afterState.executionEnv = st.executionEnv ∧
      afterState.gasAvailable.toNat + Caccess shaAddress st.substate + 84 = st.gasAvailable.toNat ∧
      st.gasAvailable.toNat ≤ afterState.gasAvailable.toNat + 2684 := by
  obtain ⟨hcgas, hpaid⟩ := call_admitted st hg
  obtain ⟨afterState,hcall,_,_,_,henv,hgas⟩ := call_observations fuel _
    (UInt256.ofNat st.executionEnv.codeOwner.val) st.gasAvailable st
    hdepth hcgas hinput houtput
  have heq : afterState.gasAvailable.toNat + Caccess shaAddress st.substate + 84 = st.gasAvailable.toNat := by
    rw [hgas]
    exact returned_gas st hg
  refine ⟨afterState,hcall,henv,heq,?_⟩
  have ha := access_le st
  omega

open SszProofCalldataStep

/-- One actual source iteration preserves its calldata environment and carries
its computed gas and memory-word extent forward. Byte layout and FFI output
length are explicit. Neither forwarded-gas nor paid-fee admission is supplied;
both follow from the initial gas bound. This is not whole-opcode gas charging. -/
theorem step_resources (fuel : Nat) (st : EVM.State) (index leaf : UInt256)
    (prebytes suffix : ByteArray) (before after : List UInt256) (sibling : UInt256)
    (hlayout : st.executionEnv.calldata = layout prebytes suffix before sibling after)
    (hsize : st.executionEnv.calldata.size < UInt256.size)
    (hindex : 1 < index.toNat)
    (hdepth : st.executionEnv.depth < 1024)
    (hg : 2685 ≤ st.gasAvailable.toNat)
    (hout : (shaOutput (pairInput index leaf sibling)).size = 32) :
    ∃ result : StepResult,
      sourceStep fuel st index leaf (proofOffset prebytes before)
        (sourceEnd prebytes (before ++ sibling :: after).length) = .ok result ∧
      result.state.executionEnv = st.executionEnv ∧
      result.state.gasAvailable.toNat + Caccess shaAddress st.substate + 84 = st.gasAvailable.toNat ∧
      result.state.activeWords.toNat = max st.activeWords.toNat 2 := by
  let prep := preparedStep st index leaf (proofOffset prebytes before)
  have hgas : 2685 ≤ prep.gasAvailable.toNat := hg
  obtain ⟨hcgas,hpaid⟩ := call_admitted prep hgas
  have hr := prepared_read st index leaf prebytes suffix before after sibling hlayout hsize
  obtain ⟨called,hcall,hret,hmem,hwords,henv,hgasWord⟩ := call_observations fuel
    (Ccall shaAddress shaAddress (UInt256.ofNat 0) prep.gasAvailable prep.accountMap prep.toMachineState prep.substate)
    (UInt256.ofNat prep.executionEnv.codeOwner.val) prep.gasAvailable prep
    hdepth hcgas (by rw [hr];exact pair_size index leaf sibling) (by rw [hr];exact hout)
  have hc : stepCall fuel st index leaf (proofOffset prebytes before) = .ok (UInt256.ofNat 1,called) := hcall
  have hp : parentIndex index ≠ UInt256.ofNat 0 := by
    intro hz
    have hh := congrArg UInt256.toNat hz
    rw [parent_nat] at hh
    change index.toNat / 2 = 0 at hh
    omega
  let next := proofOffset prebytes before + UInt256.ofNat 32
  let result : StepResult := {
    state := {called with toSharedState := {called.toSharedState with toMachineState :=
      (called.toMachineState.mload (UInt256.ofNat 0)).2}},
    index := parentIndex index,
    leaf := (called.toMachineState.mload (UInt256.ofNat 0)).1,
    offset := next,
    continues := decide (next < sourceEnd prebytes (before ++ sibling :: after).length)}
  have hnat : called.activeWords.toNat = max st.activeWords.toNat 2 := by
    rw [hwords]
    change (max prep.activeWords.toNat 2) % UInt256.size = _
    rw [SszProofCalldataStep.prepared_words]
    have hs : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    rw [max_eq_left (by omega),Nat.mod_eq_of_lt (by unfold UInt256.size at *;omega)]
  refine ⟨result,?_,henv,?_,?_⟩
  · simp only [sourceStep,hp,↓reduceIte,hc]
    have hn : UInt256.ofNat 1 ≠ UInt256.ofNat 0 := by decide +kernel
    simp only [hn,↓reduceIte]
    rfl
  · change called.gasAvailable.toNat + Caccess shaAddress prep.substate + 84 = prep.gasAvailable.toNat
    rw [hgasWord]
    exact returned_gas prep hgas
  · change (max called.activeWords.toNat 1) % UInt256.size = _
    rw [hnat,max_eq_left (by omega),Nat.mod_eq_of_lt (by have hs : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt;unfold UInt256.size at *;omega)]


end LidoSRv3.Audit.Source.SszProofLoopResources
