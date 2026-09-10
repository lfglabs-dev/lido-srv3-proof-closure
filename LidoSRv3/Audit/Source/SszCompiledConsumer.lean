import LidoSRv3.Audit.Source.SszCompiledMemory

/-! Consumer with the allocator, spills and loads in the pinned inspected
viaIR harness. This selected consumer carries actual memory through calls.
The complete CL verifier entry remains separate; general opcode dispatch/gas
retains the previously declared semantics boundary. -/
namespace LidoSRv3.Audit.Source.SszCompiledConsumer
open EvmYul EvmYul.EVM SszCompiledMemory SszBlsComposition

inductive Error where
  | abi (error : SszWitnessAbi.Error)
  | allocation (error : AllocationError)
  | bls (error : SszBlsComposition.Error)
  | proof (error : SszProofCalldataLoop.VerifyError)

structure Beginning where
  head : UInt256
  leaves : UInt256
  key : SszBlsComposition.Result

/-- This is consumed by `run` below. Allocation precedes key-tail admission,
as in the inspected runtime, and the public-key call receives that state. -/
def begin (fuel : Nat) (context : EVM.State) : Except Error Beginning := do
  let st := prologue context
  let h ← (SszWitnessAbi.header st).mapError Error.abi
  let (ptr,allocated) ← (allocate st 256).mapError Error.allocation
  let keySlice ← (SszWitnessAbi.tail allocated h (UInt256.ofNat 36) 1).mapError Error.abi
  let key ← (pubkeyRun fuel allocated keySlice.offset keySlice.length).mapError Error.bls
  pure ⟨h,ptr,key⟩

/-- Literal sequential decoder/store order; the calldata guards are not moved
past later calls. All addresses use uint256 addition. -/
def storeFields (st : EVM.State) (h ptr : UInt256) : Except Error EVM.State := do
  let st := store st (ptr + UInt256.ofNat 32).toNat (st.calldataload (UInt256.ofNat 36))
  let balance ← (SszWitnessAbi.read64 st (h + UInt256.ofNat 68)).mapError Error.abi
  let st := store st (ptr + UInt256.ofNat 64).toNat (chunk balance)
  let slashed ← (SszWitnessAbi.readBool st (h + UInt256.ofNat 228)).mapError Error.abi
  let st := store st (ptr + UInt256.ofNat 96).toNat (chunk (if slashed then 1 else 0))
  let eligible ← (SszWitnessAbi.read64 st (h + UInt256.ofNat 100)).mapError Error.abi
  let st := store st (ptr + UInt256.ofNat 128).toNat (chunk eligible)
  let activation ← (SszWitnessAbi.read64 st (h + UInt256.ofNat 132)).mapError Error.abi
  let st := store st (ptr + UInt256.ofNat 160).toNat (chunk activation)
  let exit ← (SszWitnessAbi.read64 st (h + UInt256.ofNat 164)).mapError Error.abi
  let st := store st (ptr + UInt256.ofNat 192).toNat (chunk exit)
  let withdrawable ← (SszWitnessAbi.read64 st (h + UInt256.ofNat 196)).mapError Error.abi
  pure (store st (ptr + UInt256.ofNat 224).toNat (chunk withdrawable))

/-- Both operands come from the current machine's mload, and the SHA result
is stored into that call's returned machine for subsequent loads. -/
def pairStore (fuel : Nat) (st : EVM.State) (leftAt rightAt dest : UInt256) :
    Except Error SszBlsComposition.Result := do
  let (left,st) := load st leftAt.toNat
  let (right,st) := load st rightAt.toNat
  let result ← (pairRun fuel st left right).mapError Error.bls
  pure ⟨store result.state dest.toNat result.digest,result.digest⟩

/-- Actual allocator and memory consumers for all seven pair calls. The final
right operand is the compiler's retained value `_22`, while its left operand
is loaded from the preceding spill. -/
def merkle (fuel : Nat) (st : EVM.State) (ptr : UInt256) : Except Error SszBlsComposition.Result := do
  let (l1,st) ← (allocate st 128).mapError Error.allocation
  let a ← pairStore fuel st ptr (ptr + UInt256.ofNat 32) l1
  let b ← pairStore fuel a.state (ptr + UInt256.ofNat 64) (ptr + UInt256.ofNat 96) (l1 + UInt256.ofNat 32)
  let c ← pairStore fuel b.state (ptr + UInt256.ofNat 128) (ptr + UInt256.ofNat 160) (l1 + UInt256.ofNat 64)
  let d ← pairStore fuel c.state (ptr + UInt256.ofNat 192) (ptr + UInt256.ofNat 224) (l1 + UInt256.ofNat 96)
  let (l2,st) ← (allocate d.state 64).mapError Error.allocation
  let e ← pairStore fuel st l1 (l1 + UInt256.ofNat 32) l2
  let f ← pairStore fuel e.state (l1 + UInt256.ofNat 64) (l1 + UInt256.ofNat 96) (l2 + UInt256.ofNat 32)
  let (left,st) := load f.state l2.toNat
  (pairRun fuel st left f.digest).mapError Error.bls

/-- Raw witness execution with the compiler's real allocation, store/load and
call order. The proof verifier consumes the leaf and machine returned by the
memory-based consumer, with its proof-tail decoder executed only afterwards. -/
def run (fuel : Nat) (context : EVM.State) : Except Error EVM.State := do
  let b ← begin fuel context
  let storedKey := store b.key.state b.leaves.toNat b.key.digest
  let fields ← storeFields storedKey b.head b.leaves
  let leaf ← merkle fuel fields b.leaves
  let branch ← (SszWitnessAbi.tail leaf.state b.head (UInt256.ofNat 4) 32).mapError Error.abi
  (SszProofCalldataLoop.verify fuel leaf.state
    (leaf.state.calldataload (UInt256.ofNat 100)) leaf.digest
    (leaf.state.calldataload (UInt256.ofNat 68)) branch.offset branch.length).mapError Error.proof

private theorem bind_success {ε α β : Type} {step : Except ε α}
    {next : α → Except ε β} {value : β} (h : (step >>= next) = .ok value) :
    ∃ x, step = .ok x ∧ next x = .ok value := by
  cases step with
  | error e => cases h
  | ok x => exact ⟨x,rfl,h⟩

private theorem map_success {ε α : Type} (f : ε → Error) (step : Except ε α)
    (value : α) (h : step.mapError f = .ok value) : step = .ok value := by
  cases step with
  | error e => cases h
  | ok x => cases h; rfl

/-- Initialization and the literal first allocation derive all memory-width
conditions for the first actual SHA call; no initial-memory premise. -/
theorem begin_success (fuel : Nat) (context : EVM.State) (b : Beginning)
    (h : begin fuel context = .ok b) :
    b.leaves = UInt256.ofNat 128 ∧
    b.key.state.activeWords.toNat = 12 ∧
    b.key.state.executionEnv = context.executionEnv ∧
    (load b.key.state 64).1 = UInt256.ofNat 384 ∧
    96 ≤ b.key.state.memory.size := by
  obtain ⟨allocated,ha,hfree,hw,he,hs,hread⟩ := allocate_effects (prologue context) 128 256
    (prologue_free_pointer context) (by omega) (by omega) (by omega)
    (by rw [prologue_words]) (by rw [prologue_words];omega)
  have hwa : allocated.activeWords.toNat = 12 := by rw [hw,prologue_words];decide +kernel
  unfold begin at h
  dsimp only at h
  obtain ⟨head,_,h⟩ := bind_success h
  rw [ha] at h
  dsimp only [Except.mapError,bind,Except.bind] at h
  obtain ⟨slice,_,h⟩ := bind_success h
  obtain ⟨key,hkey,h⟩ := bind_success h
  have hk := map_success Error.bls _ _ hkey
  change Except.ok (Beginning.mk head (UInt256.ofNat 128) key) = Except.ok b at h
  cases h
  dsimp only
  have hkw := SszShaCommitted.pubkey_success_words fuel allocated slice.offset slice.length key hk
  have hke := SszWitnessAbi.pubkey_environment fuel allocated slice.offset slice.length key hk
  have hkm := pubkey_memory fuel allocated slice.offset slice.length key hk hs
  refine ⟨rfl,by rw [hkw,hwa];decide +kernel,?_,?_,by omega⟩
  · exact hke.trans (he.trans (prologue_environment context))
  · exact mload_of_read _ 64 _ (by omega) (by omega)
      (hkm.1.trans hread) (by rw [hkw,hwa];norm_num) (by rw [hkw,hwa];norm_num)

#print axioms begin_success
end LidoSRv3.Audit.Source.SszCompiledConsumer
