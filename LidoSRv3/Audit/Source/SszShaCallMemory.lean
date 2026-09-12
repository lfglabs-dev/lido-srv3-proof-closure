import EvmYul.EVM.Semantics
import LidoSRv3.Audit.Source.SszShaCallBytes

/-!
Actual EvmYul CALL/Theta/SHA-precompile consumer for BLS.sol:538–560 at
17005714f151e5502c559932319a3f2f74ac2436. Opaque FFI output length is explicit;
no expected caller memory, successful callee result or new interpreter is used.
-/
namespace LidoSRv3.Audit.Source.SszShaCallMemory
open EvmYul EvmYul.EVM
open SszScratchEvmMemory SszShaCallBytes

/-- Actual opaque function used by Xi_SHA256, not the similarly named Python helper. -/
def shaOutput (input : ByteArray) : ByteArray := ffi.sha256 input input.size.toUSize

def shaAddress : AccountAddress := AccountAddress.ofUInt256 (UInt256.ofNat 2)

theorem sha_selected (accounts : AccountMap .EVM) :
    toExecute .EVM accounts shaAddress = .Precompiled shaAddress := by
  unfold toExecute
  have hp : shaAddress ∈ π := by decide +kernel
  simp only [hp, ↓reduceIte]

theorem gas_fits (gas : UInt256) (st : EVM.State) :
    Ccallgas shaAddress shaAddress (UInt256.ofNat 0) gas st.accountMap
      st.toMachineState st.substate < UInt256.size := by
  have hz : Ccallgas shaAddress shaAddress (UInt256.ofNat 0) gas st.accountMap
      st.toMachineState st.substate = Cgascap shaAddress shaAddress
        (UInt256.ofNat 0) gas st.accountMap st.toMachineState st.substate := by
    with_unfolding_all rfl
  rw [hz]
  unfold Cgascap
  split
  · exact lt_of_le_of_lt (Nat.min_le_right _ _) gas.val.isLt
  · exact gas.val.isLt

/-- Real Theta SHA route; account/bookkeeping results remain the engine's own
computed values, while flag/returndata/gas are derived from the actual callee. -/
theorem theta_sha (fuel : Nat) (st : EVM.State) (origin : AccountAddress) (access : Substate)
    (gas : UInt256) (input : ByteArray)
    (hlen : input.size = 64) (hgas : 84 ≤ gas.toNat) :
    ∃ accounts substate,
    EVM.Θ (fuel+1) st.executionEnv.blobVersionedHashes st.createdAccounts
      st.genesisBlockHeader st.blocks st.accountMap st.σ₀ access
      origin st.executionEnv.sender shaAddress (.Precompiled shaAddress)
      gas (UInt256.ofNat st.executionEnv.gasPrice) (UInt256.ofNat 0) (UInt256.ofNat 0)
      input (st.executionEnv.depth+1) st.executionEnv.header false =
      .ok (∅, accounts, gas - UInt256.ofNat 84, substate, true, shaOutput input) := by
  simp only [EVM.Θ, shaAddress, Ξ_SHA256, hlen]
  have hg : ¬ gas.toNat < 60 + 12 * ((64 + 31) / 32) := by omega
  simp only [hg, ↓reduceIte, ffi.SHA256, shaOutput]
  exact ⟨_, _, rfl⟩

/-- Existing CALL with the literal BLS SHA operands. The source word is exposed
to preserve the real caller address without a separate address-roundtrip axiom. -/
def callSha (fuel gasCost : Nat) (source gas : UInt256) (st : EVM.State) :=
  EVM.call fuel gasCost st.executionEnv.blobVersionedHashes gas source
    (UInt256.ofNat 2) (UInt256.ofNat 2) (UInt256.ofNat 0) (UInt256.ofNat 0)
    (UInt256.ofNat 0) (UInt256.ofNat 64) (UInt256.ofNat 0) (UInt256.ofNat 32) false st

/-- Unrestricted memory-copy result of the actual CALL, Theta and SHA route.
No bound on activeWords is needed for these byte observations. -/
theorem call_sha_bytes (fuel gasCost : Nat) (source gas : UInt256) (st : EVM.State)
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
      afterState.activeWords = UInt256.ofNat (max st.activeWords.toNat 2) := by
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
  refine ⟨_, rfl, rfl, ?_, ?_⟩
  · change (shaOutput (st.memory.readWithPadding 0 64)).write 0 st.memory 0 32 = _
    exact write32 _ _ houtput
  · change UInt256.ofNat (MachineState.M (MachineState.M st.activeWords.toNat 0 64) 0 32) = _
    congr 1
    simp only [MachineState.M]
    omega

/-- Existing scratch operations lifted to the existing EVM state. -/
def prepared (st : EVM.State) (offset : UInt256) : EVM.State :=
  { st with toSharedState := scratch st.toSharedState offset }

theorem prepared_words (st : EVM.State) (offset : UInt256) :
    (prepared st offset).activeWords.toNat = max st.activeWords.toNat 2 := by
  have hfit : max st.activeWords.toNat 2 < UInt256.size := by
    have h : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    unfold UInt256.size at *
    omega
  change (max ((max st.activeWords.toNat 2) % UInt256.size) 2) % UInt256.size = _
  rw [Nat.mod_eq_of_lt hfit]
  rw [max_eq_left (by omega), Nat.mod_eq_of_lt hfit]

/-- Whole source scratch plus real CALL. Calldata extent and actual FFI length
are the only byte assumptions; old scratch contents and activeWords are arbitrary. -/
theorem scratch_call_bytes (fuel gasCost : Nat) (source gas offset : UInt256)
    (st : EVM.State) (hfit : offset.toNat + 48 ≤ st.executionEnv.calldata.size)
    (hdepth : st.executionEnv.depth < 1024)
    (hgas : 84 ≤ Ccallgas shaAddress shaAddress (UInt256.ofNat 0) gas
      (prepared st offset).accountMap (prepared st offset).toMachineState
      (prepared st offset).substate)
    (houtput : (shaOutput (rawBlock st.executionEnv.calldata offset.toNat)).size = 32) :
    ∃ afterState : EVM.State,
      callSha (fuel+2) gasCost source gas (prepared st offset) =
        .ok (UInt256.ofNat 1, afterState) ∧
      afterState.returnData = shaOutput (rawBlock st.executionEnv.calldata offset.toNat) ∧
      afterState.memory.readWithPadding 0 32 =
        shaOutput (rawBlock st.executionEnv.calldata offset.toNat) ∧
      (∀ i, 64 ≤ i → afterState.memory.data.getD i 0 = st.memory.data.getD i 0) ∧
      afterState.activeWords.toNat = max st.activeWords.toNat 2 := by
  have hr : (prepared st offset).memory.readWithPadding 0 64 =
      rawBlock st.executionEnv.calldata offset.toNat := read_exact st.toSharedState offset hfit
  obtain ⟨afterState, hc, ho, hm, hw⟩ := call_sha_bytes fuel gasCost source gas
    (prepared st offset) hdepth hgas (by rw [hr]; exact rawBlock_size _ _ hfit)
    (by rw [hr]; exact houtput)
  rw [hr] at ho hm
  refine ⟨afterState, hc, ho, ?_, ?_, ?_⟩
  · rw [hm]
    exact read32_prefix _ _ houtput
  · intro i hi
    rw [hm, frame32 _ _ houtput i (by omega)]
    exact frame st.toSharedState offset hfit i hi
  · rw [hw, prepared_words]
    have hbound : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    change (max (max st.activeWords.toNat 2) 2) % UInt256.size = _
    rw [max_eq_left (by omega), Nat.mod_eq_of_lt (by unfold UInt256.size at *; omega)]

/-- Bounded word-level result. The bound belongs only to EvmYul's UInt256
memory-extent representation; the byte-copy theorem above is unrestricted. -/
theorem scratch_call_mload (fuel gasCost : Nat) (source gas offset : UInt256)
    (st : EVM.State) (hfit : offset.toNat + 48 ≤ st.executionEnv.calldata.size)
    (hdepth : st.executionEnv.depth < 1024)
    (hgas : 84 ≤ Ccallgas shaAddress shaAddress (UInt256.ofNat 0) gas
      (prepared st offset).accountMap (prepared st offset).toMachineState
      (prepared st offset).substate)
    (houtput : (shaOutput (rawBlock st.executionEnv.calldata offset.toNat)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    ∃ afterState : EVM.State,
      callSha (fuel+2) gasCost source gas (prepared st offset) =
        .ok (UInt256.ofNat 1, afterState) ∧
      afterState.returnData = shaOutput (rawBlock st.executionEnv.calldata offset.toNat) ∧
      (afterState.toMachineState.mload (UInt256.ofNat 0)).1 =
        UInt256.ofNat (fromByteArrayBigEndian
          (shaOutput (rawBlock st.executionEnv.calldata offset.toNat))) := by
  have hr : (prepared st offset).memory.readWithPadding 0 64 =
      rawBlock st.executionEnv.calldata offset.toNat := read_exact st.toSharedState offset hfit
  obtain ⟨afterState, hc, ho, hm, hw⟩ := call_sha_bytes fuel gasCost source gas
    (prepared st offset) hdepth hgas (by rw [hr]; exact rawBlock_size _ _ hfit)
    (by rw [hr]; exact houtput)
  rw [hr] at ho hm
  have hwords : afterState.activeWords.toNat = max st.activeWords.toNat 2 := by
    rw [hw, prepared_words]
    change (max (max st.activeWords.toNat 2) 2) % UInt256.size = _
    rw [max_eq_left (by omega), Nat.mod_eq_of_lt (by unfold UInt256.size; omega)]
  refine ⟨afterState, hc, ho, ?_⟩
  exact mload32 afterState.toMachineState _ _ hm houtput
    (by rw [hwords]; omega) (by rw [hwords]; omega)

/-- Literal BLS `gas()` request and the existing STATICCALL fee function. This
still calls the public CALL helper; it is not gas-charged EVM.X or compiled ABI. -/
def blsCall (fuel : Nat) (st : EVM.State) (offset : UInt256) :=
  let st' := prepared st offset
  callSha (fuel+2)
    (Ccall shaAddress shaAddress (UInt256.ofNat 0) st'.gasAvailable
      st'.accountMap st'.toMachineState st'.substate)
    (UInt256.ofNat st'.executionEnv.codeOwner.val) st'.gasAvailable st'

/-- Source literal gas/caller operands, derived BLS success-and-size guard, and
the actual mload word. The fee-admission hypothesis excludes wrapped subtraction
for this physically bounded consumer, without claiming EVM.X execution. -/
theorem bls_call_success (fuel : Nat) (st : EVM.State) (offset : UInt256)
    (hfit : offset.toNat + 48 ≤ st.executionEnv.calldata.size)
    (hdepth : st.executionEnv.depth < 1024)
    (hgas : 84 ≤ Ccallgas shaAddress shaAddress (UInt256.ofNat 0)
      (prepared st offset).gasAvailable (prepared st offset).accountMap
      (prepared st offset).toMachineState (prepared st offset).substate)
    (hpaid : Ccall shaAddress shaAddress (UInt256.ofNat 0)
      (prepared st offset).gasAvailable (prepared st offset).accountMap
      (prepared st offset).toMachineState (prepared st offset).substate ≤
      (prepared st offset).gasAvailable.toNat)
    (houtput : (shaOutput (rawBlock st.executionEnv.calldata offset.toNat)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    ∃ afterState : EVM.State,
      blsCall fuel st offset = .ok (UInt256.ofNat 1, afterState) ∧
      afterState.returnData.size = 32 ∧
      (afterState.toMachineState.mload (UInt256.ofNat 0)).1 =
        UInt256.ofNat (fromByteArrayBigEndian
          (shaOutput (rawBlock st.executionEnv.calldata offset.toNat))) ∧
      Ccall shaAddress shaAddress (UInt256.ofNat 0)
        (prepared st offset).gasAvailable (prepared st offset).accountMap
        (prepared st offset).toMachineState (prepared st offset).substate < UInt256.size := by
  obtain ⟨afterState, hc, ho, hm⟩ := scratch_call_mload fuel _
    (UInt256.ofNat (prepared st offset).executionEnv.codeOwner.val)
    (prepared st offset).gasAvailable offset st hfit hdepth hgas houtput hwidth
  refine ⟨afterState, hc, ?_, hm, ?_⟩
  · rw [ho]; exact houtput
  · exact lt_of_le_of_lt hpaid (prepared st offset).gasAvailable.val.isLt

end LidoSRv3.Audit.Source.SszShaCallMemory
