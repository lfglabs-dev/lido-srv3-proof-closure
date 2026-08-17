import LidoSRv3.Audit.Source.GIndexConcatCorrespondence
import LidoSRv3.Audit.Verity.SszAbstractDigest
import LidoSRv3.Audit.Verity.SszTxSimulation
import Verity.Core

/-!
# P-SSZ-1 faithful SSZ-encoding transaction

One `Contract.run` transaction computes the four P-SSZ-1 child observables
together and persists them through `writeSlot` / `writeMapUint`:

1. deposit-data-root — last digest of the pinned seven-call SHA-256 chain
2. GIndex.concat — exact source `shift`/`xor`/`or`/`pow(rhs)` result
3. abstract digest — XOR fingerprint of the seven engine digests
4. verification — accept iff the computed root equals the expected root

A second encoding batch may be chained: its left generalized index is the
first batch's committed concat. Any failure after intermediate writes is
normalized by `Contract.run` to the pre-call snapshot.

This is not a Yul, EVM, precompile-identity, or deployed-bytecode theorem.
SHA-256 functional correctness remains `A-SHA256-FFI`.
-/

namespace LidoSRv3.Audit.Verity.SszEncodingTx

open _root_.Verity
open LidoSRv3.Audit.Verity.SszAbstractDigest
open LidoSRv3.Audit.Verity.SszTxSimulation
open LidoSRv3.Audit.Source.GIndexConcatCorrespondence

abbrev Word := Verity.Core.Uint256

def depositRootSlot (base : Nat) : Nat := base
def concatSlot (base : Nat) : Nat := base + 1
def digestXorSlot (base : Nat) : Nat := base + 2
def verifiedSlot (base : Nat) : Nat := base + 3
def digestMapSlot (base : Nat) : Nat := 10 + base

structure EncodingInput where
  deposit : Inputs
  lhs : GIndex
  rhs : GIndex
  expectedRoot : Bytes

def widthsOk (input : EncodingInput) : Bool :=
  input.deposit.publicKey.size == 48 &&
    input.deposit.withdrawalCredentials.size == 32 &&
      input.deposit.signature.size == 96 &&
        input.deposit.amountLittleEndian.size == 8 &&
          input.expectedRoot.size == 32

def foldBytesBE (bytes : List UInt8) : Nat :=
  bytes.foldl (fun acc b => acc * 256 + b.toNat) 0

def bytesToWord (bytes : Bytes) : Word :=
  Verity.Core.Uint256.ofNat (foldBytesBE bytes.toList)

def packConcat (index pow : Nat) : Word :=
  Verity.Core.Uint256.ofNat (index * 256 + pow)

def xorWord (a b : Word) : Word :=
  Verity.Core.Uint256.ofNat (a.val ^^^ b.val)

def xorWords : List Word → Word
  | [] => 0
  | w :: rest => xorWord w (xorWords rest)

def computedRootBytes (deposit : Inputs) : Bytes :=
  (digestChain deposit).getLast?.getD (zeros digestBytes)

def writeDigests (base : Nat) : ContractState → Nat → List Word → ContractState
  | state, _, [] => state
  | state, index, word :: rest =>
      writeDigests base
        (state.writeMapUint (digestMapSlot base) (Verity.Core.Uint256.ofNat index) word)
        (index + 1) rest

theorem readSlot_writeDigests (base : Nat) (state : ContractState)
    (index slot : Nat) (words : List Word) :
    (writeDigests base state index words).readSlot slot = state.readSlot slot := by
  induction words generalizing state index with
  | nil => simp [writeDigests]
  | cons word rest ih =>
      simp [writeDigests]
      rw [ih]
      simp [ContractState.readSlot, ContractState.storage_writeMapUint]

structure Observables where
  depositDataRoot : Word
  concat : Word
  digestXor : Word
  verified : Word
  deriving DecidableEq, Repr

inductive Status where
  | committed
  | reverted
  deriving DecidableEq, Repr

structure View where
  status : Status
  observables : Observables
  deriving DecidableEq, Repr

def zeroObs : Observables := ⟨0, 0, 0, 0⟩

def readObs (state : ContractState) (base : Nat) : Observables :=
  ⟨state.readSlot (depositRootSlot base),
    state.readSlot (concatSlot base),
    state.readSlot (digestXorSlot base),
    state.readSlot (verifiedSlot base)⟩

/-- Persist the four observables after the child computations. The injected
failure hook and the root-mismatch branch both revert *after* those writes so
`Contract.run` can restore the snapshot. -/
def encodeAt (base : Nat) (input : EncodingInput)
    (failAfterWrites : Bool := false) : Contract Observables := fun snapshot =>
  if widthsOk input = false then .revert "WIDTH_MISMATCH" snapshot
  else
    match sourceConcat input.lhs input.rhs with
    | .depthOverflow => .revert "GINDEX_DEPTH" snapshot
    | .packOverflow => .revert "GINDEX_PACK" snapshot
    | .value index pow =>
        let chain := digestChain input.deposit
        let rootBytes := computedRootBytes input.deposit
        let root := bytesToWord rootBytes
        let concat := packConcat index pow
        let fingerprint := xorWords (chain.map bytesToWord)
        let dirty := writeDigests base snapshot 0 (chain.map bytesToWord)
        let dirty := dirty.writeSlot (concatSlot base) concat
        let dirty := dirty.writeSlot (depositRootSlot base) root
        let dirty := dirty.writeSlot (digestXorSlot base) fingerprint
        if rootBytes = input.expectedRoot then
          if failAfterWrites then
            .revert "INJECTED_AFTER_WRITES" dirty
          else
            let dirty := dirty.writeSlot (verifiedSlot base) 1
            .success ⟨root, concat, fingerprint, 1⟩ dirty
        else
          .revert "DepositDataRootMismatch" dirty

def encode (input : EncodingInput) (failAfterWrites : Bool := false) :
    Contract Observables :=
  encodeAt 0 input failAfterWrites

/-- Two-batch chaining: the second encoding uses the first concat value as its
left generalized index. Intermediate first-batch writes are discarded if the
second batch fails. -/
def encodeTwo (first second : EncodingInput) (failAfterWrites : Bool := false) :
    Contract (Observables × Observables) := fun snapshot =>
  match encodeAt 0 first false snapshot with
  | .revert reason state => .revert reason state
  | .success firstObs state =>
      match sourceConcat first.lhs first.rhs with
      | .value index pow =>
          if hIndex : index ≤ maxUint248 then
            if hPow : pow < 256 then
              let chained : EncodingInput :=
                { second with lhs := ⟨index, pow, hIndex, hPow⟩ }
              match encodeAt 4 chained failAfterWrites state with
              | .revert reason state => .revert reason state
              | .success secondObs state => .success (firstObs, secondObs) state
            else .revert "CHAIN_POW" snapshot
          else .revert "CHAIN_INDEX" snapshot
      | .depthOverflow => .revert "GINDEX_DEPTH" snapshot
      | .packOverflow => .revert "GINDEX_PACK" snapshot

def observe : ContractResult Observables → View
  | .success _ state => ⟨.committed, readObs state 0⟩
  | .revert _ _ => ⟨.reverted, zeroObs⟩

def observeTwo : ContractResult (Observables × Observables) → View × View
  | .success _ state =>
      (⟨.committed, readObs state 0⟩, ⟨.committed, readObs state 4⟩)
  | .revert _ _ => (⟨.reverted, zeroObs⟩, ⟨.reverted, zeroObs⟩)

def sourceObs (input : EncodingInput) : Option Observables :=
  if widthsOk input = false then none
  else
    match sourceConcat input.lhs input.rhs with
    | .depthOverflow | .packOverflow => none
    | .value index pow =>
        let chain := digestChain input.deposit
        let rootBytes := computedRootBytes input.deposit
        if rootBytes = input.expectedRoot then
          some ⟨bytesToWord rootBytes, packConcat index pow,
            xorWords (chain.map bytesToWord), 1⟩
        else none

def sourceView (input : EncodingInput) : View :=
  match sourceObs input with
  | none => ⟨.reverted, zeroObs⟩
  | some obs => ⟨.committed, obs⟩

def chainedInput (first second : EncodingInput) : Option EncodingInput :=
  match sourceConcat first.lhs first.rhs with
  | .value index pow =>
      if hIndex : index ≤ maxUint248 then
        if hPow : pow < 256 then
          some { second with lhs := ⟨index, pow, hIndex, hPow⟩ }
        else none
      else none
  | .depthOverflow | .packOverflow => none

def sourceViewTwo (first second : EncodingInput) : View × View :=
  match sourceObs first, chainedInput first second with
  | some firstObs, some chained =>
      match sourceObs chained with
      | some secondObs => (⟨.committed, firstObs⟩, ⟨.committed, secondObs⟩)
      | none => (⟨.reverted, zeroObs⟩, ⟨.reverted, zeroObs⟩)
  | _, _ => (⟨.reverted, zeroObs⟩, ⟨.reverted, zeroObs⟩)

private theorem readObs_success_slots (base : Nat) (state : ContractState)
    (words : List Word) (root concat fingerprint : Word) :
    readObs
      (((((writeDigests base state 0 words).writeSlot (concatSlot base) concat).writeSlot
          (depositRootSlot base) root).writeSlot
          (digestXorSlot base) fingerprint).writeSlot
          (verifiedSlot base) 1)
      base =
      ⟨root, concat, fingerprint, 1⟩ := by
  simp [readObs, depositRootSlot, concatSlot, digestXorSlot, verifiedSlot,
    ContractState.readSlot_writeSlot_same, ContractState.readSlot_writeSlot_other]

/-- Composed faithful-plane theorem: the executable encoding transaction's
outcome observables are exactly the independently stated source-view of the
four children. -/
theorem verity_tx_simulates_pinned_source
    (input : EncodingInput) (state : ContractState) :
    observe ((encode input).run state) = sourceView input := by
  by_cases hW : widthsOk input = false
  · unfold encode sourceView observe Contract.run encodeAt
    simp [hW, sourceObs]
  · have hW' : widthsOk input = true := by
      cases h : widthsOk input <;> simp_all
    unfold encode sourceView observe Contract.run encodeAt
    simp [hW, sourceObs]
    cases hC : sourceConcat input.lhs input.rhs with
    | depthOverflow => rfl
    | packOverflow => rfl
    | value index pow =>
        simp [hC]
        by_cases hRoot : computedRootBytes input.deposit = input.expectedRoot
        · simp [hRoot, readObs_success_slots]
        · simp [hRoot]

/-- Any failure, including injected failure after intermediate writes, returns
the exact pre-transaction snapshot. -/
theorem revert_restores_snapshot
    (input : EncodingInput) (inject : Bool)
    (state rollback : ContractState) (reason : String)
    (h : (encode input inject).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

theorem revert_restores_snapshot_two
    (first second : EncodingInput) (inject : Bool)
    (state rollback : ContractState) (reason : String)
    (h : (encodeTwo first second inject).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

/-- Child 2 is not downgraded: every encoding uses the exact source concat. -/
theorem encoding_uses_source_concat (lhs rhs : GIndex) :
    sourceConcat lhs rhs = specConcat lhs rhs :=
  source_concat_matches_spec lhs rhs

/-- Child 3 is not downgraded: the persisted digest chain is the seven-call
reference-engine composition. -/
theorem encoding_uses_exact_digest (deposit : Inputs) :
    ExactDigestComposition deposit ∧ (digestChain deposit).length = 7 :=
  ⟨digest_composition deposit, seven_calls deposit⟩

/-- Child 4 is not downgraded: acceptance is exactly the root-match check. -/
theorem encoding_accepts_iff_root_matches (input : EncodingInput)
    (hW : widthsOk input = true)
    (hC : ∃ index pow, sourceConcat input.lhs input.rhs = .value index pow) :
    (sourceObs input).isSome = true ↔
      computedRootBytes input.deposit = input.expectedRoot := by
  rcases hC with ⟨index, pow, hC⟩
  unfold sourceObs
  simp [hW, hC]

/-- Child 1 layout is preserved: a successful encoding requires the pinned
deposit-data widths. -/
theorem encoding_requires_pinned_widths (input : EncodingInput)
    (h : (sourceObs input).isSome = true) :
    widthsOk input = true := by
  unfold sourceObs at h
  split at h
  · simp at h
  · cases hW : widthsOk input
    · simp [hW] at *
    · rfl

end LidoSRv3.Audit.Verity.SszEncodingTx
