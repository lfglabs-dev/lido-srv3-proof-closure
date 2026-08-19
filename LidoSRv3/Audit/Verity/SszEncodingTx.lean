import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Source.GIndexConcatCorrespondence
import LidoSRv3.Audit.Verity.SszAbstractDigest
import LidoSRv3.Audit.Verity.SszTxSimulation
import Verity.Core

/-!
# P-SSZ-1 faithful SSZ-encoding transaction

One `Contract.run` transaction computes the four P-SSZ-1 child observables
together and persists them through `writeSlot` / `writeMapUint`:

1. structural witness binding — `ValidatorWitness`, named `operation`,
   generalized index, path, and branch, accepted iff `bindOperation`
2. deposit-data-root — last digest of the pinned seven-call SHA-256 chain
3. GIndex.concat — exact source `shift`/`xor`/`or`/`pow(rhs)` result
4. abstract digest — XOR fingerprint of the seven engine digests, plus
   verification — accept iff the computed root equals the expected root

A second encoding batch may be chained: its left generalized index is the
first batch's committed concat. Any failure after intermediate writes is
normalized by `Contract.run` to the pre-call snapshot.

This is not a Yul, EVM, precompile-identity, or deployed-bytecode theorem.
SHA-256 functional correctness remains `A-SHA256-FFI`.
-/

namespace LidoSRv3.Audit.Verity.SszEncodingTx

open _root_.Verity
open LidoSRv3.Audit
open LidoSRv3.Audit.Verity.SszAbstractDigest
open LidoSRv3.Audit.Verity.SszTxSimulation
open LidoSRv3.Audit.Source.GIndexConcatCorrespondence

abbrev Word := Verity.Core.Uint256

def depositRootSlot (base : Nat) : Nat := base
def concatSlot (base : Nat) : Nat := base + 1
def digestXorSlot (base : Nat) : Nat := base + 2
def verifiedSlot (base : Nat) : Nat := base + 3
def operationSlot (base : Nat) : Nat := base + 4
def indexSlot (base : Nat) : Nat := base + 5
def pivotSlot (base : Nat) : Nat := base + 6
def traversedRootSlot (base : Nat) : Nat := base + 7
def boundSlot (base : Nat) : Nat := base + 8
def pathLengthSlot (base : Nat) : Nat := base + 9
def branchLengthSlot (base : Nat) : Nat := base + 10
def digestMapSlot (base : Nat) : Nat := 1000 + base
def pathMapSlot (base : Nat) : Nat := 2000 + base
def branchMapSlot (base : Nat) : Nat := 3000 + base
def batchStride : Nat := 16

/-- Inputs carry the four children the parent abstract composes, including the
structural witness pieces used by `composed_ssz_encoding`. -/
structure EncodingInput where
  deposit : Inputs
  lhs : GIndex
  rhs : GIndex
  expectedRoot : Bytes
  operation : Ssz.Operation
  combine : Ssz.Node → Ssz.Node → Ssz.Node
  witness : Ssz.ValidatorWitness
  expectedWitnessRoot : Ssz.Node

def widthsOk (input : EncodingInput) : Bool :=
  input.deposit.publicKey.size == 48 &&
    input.deposit.withdrawalCredentials.size == 32 &&
      input.deposit.signature.size == 96 &&
        input.deposit.amountLittleEndian.size == 8 &&
          input.expectedRoot.size == 32

/-- Child 1, exactly the abstract `bindOperation` hypothesis. -/
def structuralOk (input : EncodingInput) : Bool :=
  Ssz.bindOperation input.operation input.combine input.witness
    input.expectedWitnessRoot

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

/-- Persist the named operation through the same generalized-index slot the
abstract uses (`Ssz.operationIndex`). -/
def operationWord (op : Ssz.Operation) : Word :=
  Verity.Core.Uint256.ofNat (Ssz.operationIndex op).value

def indexWord (index : Ssz.GeneralizedIndex) : Word :=
  Verity.Core.Uint256.ofNat index.value

def nodeWord (n : Ssz.Node) : Word :=
  Verity.Core.Uint256.ofNat n

def siblingWord : Ssz.SiblingSide → Word
  | .right => 0
  | .left => 1

def traversedRoot (input : EncodingInput) : Ssz.Node :=
  Ssz.traverseBranch input.combine
    (Ssz.validatorRoot input.combine input.witness.validator)
    input.witness.path input.witness.branch

def writeWords (mapSlot : Nat) : ContractState → Nat → List Word → ContractState
  | state, _, [] => state
  | state, index, word :: rest =>
      writeWords mapSlot
        (state.writeMapUint mapSlot (Verity.Core.Uint256.ofNat index) word)
        (index + 1) rest

def writeDigests (base : Nat) (state : ContractState) (index : Nat)
    (words : List Word) : ContractState :=
  writeWords (digestMapSlot base) state index words

def writePath (base : Nat) (state : ContractState) (index : Nat)
    (words : List Word) : ContractState :=
  writeWords (pathMapSlot base) state index words

def writeBranch (base : Nat) (state : ContractState) (index : Nat)
    (words : List Word) : ContractState :=
  writeWords (branchMapSlot base) state index words

/-- Successful named-operation witnesses have depth at most two. Persisting a
fixed two-entry readback window also clears unused entries and prevents an
arbitrary pre-state map value from entering the outcome observable. -/
def twoWords (words : List Word) : List Word :=
  [words.getD 0 0, words.getD 1 0]

/-- The pinned digest chain always has exactly seven entries (`seven_calls`).
Persisting a fixed seven-entry readback window mirrors `twoWords` above and
lets the outcome observable *reread the persisted digest words from storage*
rather than trusting the pre-write local `chain` list. -/
def sevenWords (words : List Word) : List Word :=
  [words.getD 0 0, words.getD 1 0, words.getD 2 0, words.getD 3 0,
    words.getD 4 0, words.getD 5 0, words.getD 6 0]

/-- Intermediate child writes (including structural path/branch maps). -/
def persistChildren (base : Nat) (state : ContractState)
    (digestWords pathWords branchWords : List Word)
    (root concat fingerprint opW idxW pivotW travW : Word) : ContractState :=
  let s := writeDigests base state 0 (sevenWords digestWords)
  let s := writePath base s 0 (twoWords pathWords)
  let s := writeBranch base s 0 (twoWords branchWords)
  let s := s.writeSlot (concatSlot base) concat
  let s := s.writeSlot (depositRootSlot base) root
  let s := s.writeSlot (digestXorSlot base) fingerprint
  let s := s.writeSlot (operationSlot base) opW
  let s := s.writeSlot (indexSlot base) idxW
  let s := s.writeSlot (pivotSlot base) pivotW
  let s := s.writeSlot (traversedRootSlot base) travW
  let s := s.writeSlot (pathLengthSlot base) pathWords.length
  s.writeSlot (branchLengthSlot base) branchWords.length

/-- Final commit bits for verification and structural bind. -/
def persistCommit (base : Nat) (state : ContractState) : ContractState :=
  (state.writeSlot (verifiedSlot base) 1).writeSlot (boundSlot base) 1

theorem readSlot_writeWords (mapSlot : Nat) (state : ContractState)
    (index slot : Nat) (words : List Word) :
    (writeWords mapSlot state index words).readSlot slot = state.readSlot slot := by
  induction words generalizing state index with
  | nil => simp [writeWords]
  | cons word rest ih =>
      simp [writeWords]
      rw [ih]
      simp [ContractState.readSlot, ContractState.storage_writeMapUint]

theorem readSlot_writeDigests (base : Nat) (state : ContractState)
    (index slot : Nat) (words : List Word) :
    (writeDigests base state index words).readSlot slot = state.readSlot slot :=
  readSlot_writeWords _ _ _ _ _

structure Observables where
  depositDataRoot : Word
  concat : Word
  digestXor : Word
  verified : Word
  operation : Word
  index : Word
  pivotBoundary : Word
  traversedRoot : Word
  bound : Word
  pathLength : Word
  branchLength : Word
  path : List Word
  branch : List Word
  /-- The seven persisted digest-chain words, reread from `digestMapSlot`
  storage (not the pre-write local `chain` list). -/
  digest : List Word
  deriving DecidableEq, Repr

inductive Status where
  | committed
  | reverted
  deriving DecidableEq, Repr

structure View where
  status : Status
  observables : Observables
  deriving DecidableEq, Repr

def zeroObs : Observables := ⟨0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, [], [], []⟩

def readWords (mapSlot : Nat) (state : ContractState) : Nat → Nat → List Word
  | _, 0 => []
  | index, count + 1 =>
      state.readMapUint mapSlot (Verity.Core.Uint256.ofNat index) ::
        readWords mapSlot state (index + 1) count

def readObs (state : ContractState) (base : Nat) : Observables :=
  ⟨state.readSlot (depositRootSlot base),
    state.readSlot (concatSlot base),
    state.readSlot (digestXorSlot base),
    state.readSlot (verifiedSlot base),
    state.readSlot (operationSlot base),
    state.readSlot (indexSlot base),
    state.readSlot (pivotSlot base),
    state.readSlot (traversedRootSlot base),
    state.readSlot (boundSlot base),
    state.readSlot (pathLengthSlot base),
    state.readSlot (branchLengthSlot base),
    readWords (pathMapSlot base) state 0 2,
    readWords (branchMapSlot base) state 0 2,
    -- Reread the seven persisted digest words from `digestMapSlot` storage,
    -- not the pre-write local `chain` list.
    readWords (digestMapSlot base) state 0 7⟩

/-- Persist every child after the child computations. The injected failure
hook, a failed `bindOperation`, and the root-mismatch branch all revert
*after* those writes so `Contract.run` can restore the snapshot. -/
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
        let opW := operationWord input.operation
        let idxW := indexWord input.witness.index
        let pivotW := nodeWord input.witness.pivotBoundary
        let travW := nodeWord (traversedRoot input)
        let dirty := persistChildren base snapshot
          (chain.map bytesToWord)
          (input.witness.path.map siblingWord)
          (input.witness.branch.map nodeWord)
          root concat fingerprint opW idxW pivotW travW
        if structuralOk input = true then
          if rootBytes = input.expectedRoot then
            if failAfterWrites then
              .revert "INJECTED_AFTER_WRITES" dirty
            else
              .success ⟨root, concat, fingerprint, 1, opW, idxW, pivotW, travW, 1,
                input.witness.path.length, input.witness.branch.length,
                twoWords (input.witness.path.map siblingWord),
                twoWords (input.witness.branch.map nodeWord),
                sevenWords (chain.map bytesToWord)⟩
                (persistCommit base dirty)
          else
            .revert "DepositDataRootMismatch" dirty
        else
          .revert "WITNESS_BIND" dirty

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
              match encodeAt batchStride chained failAfterWrites state with
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
      (⟨.committed, readObs state 0⟩,
        ⟨.committed, readObs state batchStride⟩)
  | .revert _ _ => (⟨.reverted, zeroObs⟩, ⟨.reverted, zeroObs⟩)

def committedObs (input : EncodingInput) (index pow : Nat) : Observables :=
  let chain := digestChain input.deposit
  ⟨bytesToWord (computedRootBytes input.deposit), packConcat index pow,
    xorWords (chain.map bytesToWord), 1,
    operationWord input.operation,
    indexWord input.witness.index,
    nodeWord input.witness.pivotBoundary,
    nodeWord (traversedRoot input), 1,
    input.witness.path.length, input.witness.branch.length,
    twoWords (input.witness.path.map siblingWord),
    twoWords (input.witness.branch.map nodeWord),
    sevenWords (chain.map bytesToWord)⟩

def sourceObs (input : EncodingInput) : Option Observables :=
  if widthsOk input = false then none
  else if structuralOk input = false then none
  else
    match sourceConcat input.lhs input.rhs with
    | .value index pow =>
        if computedRootBytes input.deposit = input.expectedRoot then
          some (committedObs input index pow)
        else none
    | .depthOverflow | .packOverflow => none

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
    (digestWords pathWords branchWords : List Word)
    (root concat fingerprint opW idxW pivotW travW : Word) :
    readObs
      (persistCommit base
        (persistChildren base state digestWords pathWords branchWords
          root concat fingerprint opW idxW pivotW travW))
      base =
      ⟨root, concat, fingerprint, 1, opW, idxW, pivotW, travW, 1,
        pathWords.length, branchWords.length,
        twoWords pathWords, twoWords branchWords, sevenWords digestWords⟩ := by
  simp (config := { decide := true }) [readObs, persistCommit, persistChildren, writeBranch,
    writePath, writeDigests, writeWords, readWords, twoWords, sevenWords,
    depositRootSlot, concatSlot, digestXorSlot, verifiedSlot,
    operationSlot, indexSlot, pivotSlot, traversedRootSlot, boundSlot,
    pathLengthSlot, branchLengthSlot, digestMapSlot, pathMapSlot, branchMapSlot,
    ContractState.readSlot, ContractState.storage, ContractState.readMapUint,
    ContractState.storageMapUint, ContractState.writeMapUint,
    ContractState.writeSlot]

/-- Composed faithful-plane theorem: the executable encoding transaction's
outcome observables are exactly the independently stated source-view of the
four children, including structural witness binding. -/
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
    | depthOverflow =>
        cases structuralOk input <;> simp
    | packOverflow =>
        cases structuralOk input <;> simp
    | value index pow =>
        by_cases hBind : structuralOk input = false
        · simp [hBind]
        · have hBind' : structuralOk input = true := by
            cases h : structuralOk input <;> simp_all
          simp [hBind']
          by_cases hRoot : computedRootBytes input.deposit = input.expectedRoot
          · simp [hRoot, committedObs, traversedRoot, readObs_success_slots]
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

/-- Child 3 is not downgraded: every encoding uses the exact source concat. -/
theorem encoding_uses_source_concat (lhs rhs : GIndex) :
    sourceConcat lhs rhs = specConcat lhs rhs :=
  source_concat_matches_spec lhs rhs

/-- Child 4 is not downgraded: the persisted digest chain is the seven-call
reference-engine composition. -/
theorem encoding_uses_exact_digest (deposit : Inputs) :
    ExactDigestComposition deposit ∧ (digestChain deposit).length = 7 :=
  ⟨digest_composition deposit, seven_calls deposit⟩

/-- Child 4 is not downgraded: acceptance is exactly the root-match check. -/
theorem encoding_accepts_iff_root_matches (input : EncodingInput)
    (hW : widthsOk input = true)
    (hBind : structuralOk input = true)
    (hC : ∃ index pow, sourceConcat input.lhs input.rhs = .value index pow) :
    (sourceObs input).isSome = true ↔
      computedRootBytes input.deposit = input.expectedRoot := by
  rcases hC with ⟨index, pow, hC⟩
  unfold sourceObs
  simp [hW, hBind, hC]

/-- Child 2 layout is preserved: a successful encoding requires the pinned
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

/-- Child 1 is preserved: a successful encoding requires `bindOperation`. -/
theorem encoding_requires_structural_bind (input : EncodingInput)
    (h : (sourceObs input).isSome = true) :
    structuralOk input = true := by
  unfold sourceObs at h
  split at h
  · simp at h
  · split at h
    · simp at h
    · cases hB : structuralOk input
      · simp [hB] at *
      · rfl

theorem sourceObs_committed_fields {input : EncodingInput} {obs : Observables}
    (h : sourceObs input = some obs) :
    obs.bound = 1 ∧ obs.verified = 1 ∧
      obs.operation = operationWord input.operation ∧
      obs.index = indexWord input.witness.index ∧
      obs.pivotBoundary = nodeWord input.witness.pivotBoundary ∧
      obs.traversedRoot = nodeWord (traversedRoot input) ∧
      obs.pathLength = input.witness.path.length ∧
      obs.branchLength = input.witness.branch.length ∧
      obs.path = twoWords (input.witness.path.map siblingWord) ∧
      obs.branch = twoWords (input.witness.branch.map nodeWord) := by
  unfold sourceObs at h
  split at h
  · cases h
  · split at h
    · cases h
    · split at h
      · split at h
        · injection h with hEq
          subst hEq
          simp [committedObs]
        · cases h
      · cases h
      · cases h

/-- The abstract structural-witness conjunct, copied from
`composed_ssz_encoding` / `Ssz.structural_witness_binding_sound`. -/
def structuralWitnessConjunct (input : EncodingInput) : Prop :=
  input.witness.operation = input.operation ∧
    input.witness.index = Ssz.operationIndex input.operation ∧
    Ssz.HasGeneralizedIndex input.witness.index input.witness.pivotBoundary
      input.witness.path ∧
    input.witness.branch.length = input.witness.path.length ∧
    Ssz.traverseBranch input.combine
      (Ssz.validatorRoot input.combine input.witness.validator)
      input.witness.path input.witness.branch = input.expectedWitnessRoot

theorem structuralOk_implies_conjunct (input : EncodingInput)
    (h : structuralOk input = true) :
    structuralWitnessConjunct input :=
  Ssz.structural_witness_binding_sound h

/-- Child 1 is executed, not merely hypothesized: a committed `Contract.run`
implies `bindOperation` and therefore the parent structural conjunct, and the
persisted observables are the witness pieces that conjunct talks about. -/
theorem encoding_commits_structural_witness
    (input : EncodingInput) (state : ContractState)
    (h : (observe ((encode input).run state)).status = .committed) :
    structuralOk input = true ∧
      structuralWitnessConjunct input ∧
      (observe ((encode input).run state)).observables.bound = 1 ∧
      (observe ((encode input).run state)).observables.operation =
        operationWord input.operation ∧
      (observe ((encode input).run state)).observables.index =
        indexWord input.witness.index ∧
      (observe ((encode input).run state)).observables.pivotBoundary =
        nodeWord input.witness.pivotBoundary ∧
      (observe ((encode input).run state)).observables.traversedRoot =
        nodeWord (traversedRoot input) ∧
      (observe ((encode input).run state)).observables.pathLength =
        input.witness.path.length ∧
      (observe ((encode input).run state)).observables.branchLength =
        input.witness.branch.length ∧
      (observe ((encode input).run state)).observables.path =
        twoWords (input.witness.path.map siblingWord) ∧
      (observe ((encode input).run state)).observables.branch =
        twoWords (input.witness.branch.map nodeWord) := by
  have hSim := verity_tx_simulates_pinned_source input state
  have hStatus : (sourceView input).status = .committed := by
    rwa [hSim] at h
  unfold sourceView at hStatus
  cases hObs : sourceObs input with
  | none => simp [hObs] at hStatus
  | some obs =>
      have hBind := encoding_requires_structural_bind input (by simp [hObs])
      have hFields := sourceObs_committed_fields hObs
      have hConj := structuralOk_implies_conjunct input hBind
      refine ⟨hBind, hConj, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
      · rw [hSim]; simp [sourceView, hObs, hFields]
      · rw [hSim]; simp [sourceView, hObs, hFields]
      · rw [hSim]; simp [sourceView, hObs, hFields]
      · rw [hSim]; simp [sourceView, hObs, hFields]
      · rw [hSim]; simp [sourceView, hObs, hFields]
      · rw [hSim]; simp [sourceView, hObs, hFields]
      · rw [hSim]; simp [sourceView, hObs, hFields]
      · rw [hSim]; simp [sourceView, hObs, hFields]
      · rw [hSim]; simp [sourceView, hObs, hFields]

end LidoSRv3.Audit.Verity.SszEncodingTx
