import LidoSRv3.Audit.Trace
import LidoSRv3.Audit.Verity.SszAbstractDigest
import Compiler.CompilationModel
import Compiler.Modules.Precompiles
import Verity.Core.Model.CallProgramRollback
import Verity.Core.Model.DenoteExternalCalls
import Verity.Core.Model.DenoteMemory
import Verity.Core.Model.DenoteSha256

/-!
# P-SSZ-1 transaction execution simulation

This subordinate evidence executes the verification control flow around the
seven-call SSZ `DepositData` digest.  The typed Verity surface fixes calldata
copies, memory stores, address-2 SHA-256 calls, and the final root comparison.
Cryptographic functional correctness is deliberately the campaign assumption
`A-SHA256-FFI`; this file proves the bytes, widths, calls, composition, and
transaction rollback around that boundary.
-/

namespace LidoSRv3.Audit.Verity.SszTxSimulation

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.DenoteExternalCalls
open Compiler.CompilationModel.DenoteMemory
open Compiler.CompilationModel.Denote.Sha256
open LidoSRv3.Audit
open LidoSRv3.Audit.Verity.SszAbstractDigest

private def lit (value : Nat) : Expr := .literal value
private def param (name : String) : Expr := .param name
private def localExpr (name : String) : Expr := .localVar name

private def copy (destination : Nat) (source : Expr) (size : Nat) : Stmt :=
  .calldatacopy (lit destination) source (lit size)

private def store (offset : Nat) (value : Expr) : Stmt :=
  .mstore (lit offset) value

private def hashPair (name : String) : Stmt :=
  Compiler.Modules.Precompiles.sha256 name (lit 0) (lit pairBytes)
    (lit digestOutputOffset)

/-- Typed transaction entry point.  `forkVersionOffset` is copied as the
four-byte deposit-domain input supplied by the caller, while the DepositData
root itself is the source's seven-call tree and therefore does not hash the
fork version. -/
def verifyDepositData : FunctionSpec :=
  { name := "verifyDepositData"
    params :=
      [ { name := "publicKeyOffset", ty := .uint256 }
      , { name := "withdrawalCredentialsOffset", ty := .uint256 }
      , { name := "signatureOffset", ty := .uint256 }
      , { name := "amountLE", ty := .bytes32 }
      , { name := "forkVersionOffset", ty := .uint256 }
      , { name := "expectedDepositDataRoot", ty := .bytes32 } ]
    returnType := none
    localObligations :=
      [ { name := "A-SHA256-FFI"
          obligation := "Each successful address-2 staticcall returns the FIPS SHA-256 digest of its exact requested memory slice."
          proofStatus := .assumed }
      , { name := "deposit_data_layout"
          obligation := "Calldata copies and memory stores stage the exact 48/32/8/96-byte DepositData fields and the four-byte fork version."
          proofStatus := .proved } ]
    body :=
      [ copy 192 (param "forkVersionOffset") 4
      , copy 0 (param "signatureOffset") 64
      , hashPair "signaturePart1"
      , copy 0 (.add (param "signatureOffset") (lit 64)) 32
      , store 32 (lit 0)
      , hashPair "signaturePart2"
      , store 0 (localExpr "signaturePart1")
      , store 32 (localExpr "signaturePart2")
      , hashPair "signatureRoot"
      , copy 0 (param "publicKeyOffset") 48
      , store 48 (lit 0)
      , hashPair "publicKeyRoot"
      , store 0 (localExpr "publicKeyRoot")
      , copy 32 (param "withdrawalCredentialsOffset") 32
      , hashPair "publicKeyWithdrawalRoot"
      , store 0 (param "amountLE")
      , store 32 (localExpr "signatureRoot")
      , hashPair "amountSignatureRoot"
      , store 0 (localExpr "publicKeyWithdrawalRoot")
      , store 32 (localExpr "amountSignatureRoot")
      , hashPair "depositDataRoot"
      , .require (.eq (localExpr "depositDataRoot")
          (param "expectedDepositDataRoot")) "DepositDataRootMismatch"
      , .stop ] }

def spec : CompilationModel :=
  { name := "PSSZ1TxExecutionSimulation"
    fields := []
    constructor := none
    functions := [verifyDepositData] }

def selector : Nat := 0x5825b4a5

def programCompiles : Bool :=
  (CompilationModel.compile spec [selector]).isOk

#guard programCompiles

structure TxInputs extends Inputs where
  forkVersion : Bytes
  expectedDepositDataRoot : Bytes

def exactTxWidths (input : TxInputs) : Prop :=
  exactWidths input.toInputs ∧ input.forkVersion.size = 4 ∧
    input.expectedDepositDataRoot.size = digestBytes

def computedRoot (input : TxInputs) : Bytes :=
  (digestChain input.toInputs).getLastD (zeros digestBytes)

inductive VerificationOutcome where
  | accept
  | revertRootMismatch
  deriving DecidableEq, Repr

namespace VerificationOutcome

def reverts : VerificationOutcome → Bool
  | .accept => false
  | .revertRootMismatch => true

end VerificationOutcome

def runVerification (input : TxInputs) : VerificationOutcome :=
  if computedRoot input = input.expectedDepositDataRoot then
    .accept
  else
    .revertRootMismatch

def transactionObservation (input : TxInputs) (before after : State)
    (attempts : List CallAttempt) (trace : CommitTrace) : TxObservation State :=
  { before := before
    attemptedCalls := attempts
    result := if (runVerification input).reverts then .reverted else .committed after trace }

/-- A SHA-256 precompile site.  The payload records the exact bytes supplied
to address 2; functional correctness of the response is `A-SHA256-FFI`. -/
def sha256Site (index : Nat) (preimage : Bytes) : CallSite :=
  { siteId := index
    kind := .staticcall
    target := precompileAddress
    value := 0
    calldata := preimage.toList.map UInt8.toNat
    gas := Verity.Core.MAX_UINT256 }

def digestPreimages (input : Inputs) : List Bytes :=
  let signaturePart1 := Sha256Engine.sha256 (slice input.signature 0 64)
  let signaturePart2 := Sha256Engine.sha256 (slice input.signature 64 32 ++ zeros 32)
  let signatureRoot := Sha256Engine.sha256 (signaturePart1 ++ signaturePart2)
  let publicKeyRoot := Sha256Engine.sha256 (input.publicKey ++ zeros 16)
  let publicKeyWithdrawalRoot := publicKeyRoot ++ input.withdrawalCredentials
  let amountSignatureRoot := input.amountLittleEndian ++ zeros 24 ++ signatureRoot
  [ slice input.signature 0 64
  , slice input.signature 64 32 ++ zeros 32
  , signaturePart1 ++ signaturePart2
  , input.publicKey ++ zeros 16
  , publicKeyWithdrawalRoot
  , amountSignatureRoot
  , Sha256Engine.sha256 publicKeyWithdrawalRoot ++
      Sha256Engine.sha256 amountSignatureRoot ]

/-! ## Faithful byte-memory and SHA-256 precompile denotation

The source function first owns one contiguous scratch allocation.  The first
304 bytes bind the three dynamic inputs (including their zero-filled tails),
and byte 304 begins the seven 64-byte SHA-256 preimages.  Keeping the preimages
in disjoint slots makes the exact bytes consumed by every call independently
inspectable; it is observationally equivalent to the Solidity/Yul reuse of a
64-byte scratch pair.
-/

def pubkeyOffset : Nat := 0
def withdrawalCredentialsOffset : Nat := 48
def signatureOffset : Nat := 96
def depositPreimageOffset : Nat := 304
def preimageOffset (index : Nat) : Nat := depositPreimageOffset + index * pairBytes

private def memoryByte (byte : UInt8) : Byte :=
  ⟨byte.toNat, UInt8.toNat_lt byte⟩

def zeroWord : Word := fun _ => zeroByte

def writeBytesFrom : Memory → Nat → List UInt8 → Memory
  | memory, _, [] => memory
  | memory, offset, byte :: rest =>
      writeBytesFrom (memory.writeByte offset (memoryByte byte)) (offset + 1) rest

def writeBytes (memory : Memory) (offset : Nat) (bytes : Bytes) : Memory :=
  writeBytesFrom memory offset bytes.toList

def writeZeros (memory : Memory) (offset count : Nat) : Memory :=
  writeBytes memory offset (zeros count)

/-- Byte-for-byte source input allocation: pubkey at 0--47, withdrawal
credentials plus its 16-byte zero tail at 48--95, and signature plus its
112-byte scratch tail at 96--303.  The initial `writeWord` records the EVM
word allocation primitive; the following `writeByte`s refine overlapping
partial words exactly. -/
def inputMemory (input : Inputs) : Memory :=
  let memory := Memory.empty.writeWord pubkeyOffset zeroWord
  let memory := writeBytes memory pubkeyOffset input.publicKey
  let memory := writeBytes memory withdrawalCredentialsOffset input.withdrawalCredentials
  let memory := writeZeros memory (withdrawalCredentialsOffset + 32) 16
  let memory := writeBytes memory signatureOffset input.signature
  writeZeros memory (signatureOffset + 96) 112

def writePreimagesFrom : Memory → Nat → List Bytes → Memory
  | memory, _, [] => memory
  | memory, index, preimage :: rest =>
      writePreimagesFrom (writeBytes memory (preimageOffset index) preimage)
        (index + 1) rest

/-- Complete memory image used by the faithful model.  The deposit-data-root
preimage area starts at 304 and contains the nested digest pairs in call order. -/
def sha256Memory (input : Inputs) : Memory :=
  writePreimagesFrom (inputMemory input) 0 (digestPreimages input)

private def wordNat (word : Word) : Nat :=
  (List.ofFn word).foldl (fun value byte => value * 256 + byte.val) 0

/-- Embed byte-precise `DenoteMemory` in the canonical word-addressed world
consumed by `DenoteSha256`.  Each word is obtained through `Memory.readWord`. -/
def memoryWorld (base : Verity.ContractState) (memory : Memory) : Verity.ContractState :=
  { base with memory := fun offset => wordNat (memory.readWord offset) }

structure Sha256Input where
  oracle : StaticCallOracle
  world : Verity.ContractState
  memory : Memory
  inputOffset : Nat
  inputSize : Nat := pairBytes
  outputOffset : Nat := digestOutputOffset

/-- Typed address-2 precompile denotation used at every one of the seven sites. -/
def denoteSha256 (input : Sha256Input) : Outcome :=
  Compiler.CompilationModel.Denote.Sha256.denote input.oracle
    (memoryWorld input.world input.memory) input.inputOffset input.inputSize
    input.outputOffset

def denotedSha256Calls (oracle : StaticCallOracle) (world : Verity.ContractState)
    (input : Inputs) : List Outcome :=
  (List.range 7).map fun index => denoteSha256
    { oracle := oracle
      world := world
      memory := sha256Memory input
      inputOffset := preimageOffset index }

@[simp] theorem denoted_sha256_calls_length (oracle : StaticCallOracle)
    (world : Verity.ContractState) (input : Inputs) :
    (denotedSha256Calls oracle world input).length = 7 := by
  simp [denotedSha256Calls]

theorem sha256_site_is_address_two_staticcall (index : Nat) (preimage : Bytes) :
    (sha256Site index preimage).kind = .staticcall ∧
      (sha256Site index preimage).target = precompileAddress := by
  constructor <;> rfl

/-- Phase 1G bridge: the external-call observation for each typed SHA-256 site
is obtained with `denoteCall`, and static-call semantics preserve the world. -/
theorem sha256_denoteCall_preserves_world (index : Nat) (preimage : Bytes)
    (adversary : AdversaryModel) (state : CallState) :
    (denoteCall adversary (sha256Site index preimage) state).state.world = state.world := by
  exact denoteCall_staticcall_world adversary (sha256Site index preimage) state rfl

def sha256CallsFrom (preimages : List Bytes) (index : Nat) : CallProgram Unit :=
  match preimages with
  | [] => .pure ()
  | preimage :: rest =>
      .bind (sha256Site index preimage) fun _ => sha256CallsFrom rest (index + 1)

def sha256Calls (input : Inputs) : CallProgram Unit :=
  sha256CallsFrom (digestPreimages input) 0

@[simp] theorem digest_preimages_length (input : Inputs) :
    (digestPreimages input).length = 7 := by
  simp [digestPreimages]

theorem accepted_iff_root_matches (input : TxInputs) :
    runVerification input = .accept ↔
      computedRoot input = input.expectedDepositDataRoot := by
  simp [runVerification]

theorem root_mutant_rejected (input : TxInputs)
    (hmutant : computedRoot input ≠ input.expectedDepositDataRoot) :
    runVerification input = .revertRootMismatch := by
  simp [runVerification, hmutant]

/-- A failed root check restores the complete transaction snapshot and commits
neither ETH movement nor logs. -/
theorem verification_failure_rolls_back (input : TxInputs)
    (before after : State) (attempts : List CallAttempt) (trace : CommitTrace)
    (hfail : runVerification input = .revertRootMismatch) :
    (transactionObservation input before after attempts trace).committedState = before ∧
      (transactionObservation input before after attempts trace).committedTrace.ethMoves = [] ∧
      (transactionObservation input before after attempts trace).committedTrace.logs = [] := by
  have hrevert : (runVerification input).reverts = true := by
    simp [hfail, VerificationOutcome.reverts]
  simp [transactionObservation, hrevert, TxObservation.committedState,
    TxObservation.committedTrace]

private theorem observed_sha256_calls_roll_back (preimages : List Bytes)
    (index : Nat) (adversary : AdversaryModel) (state : CallState) :
    ∀ entry ∈ ObservedCalls (sha256CallsFrom preimages index) adversary state,
      RollsBack adversary entry := by
  induction preimages generalizing index state with
  | nil => simp [sha256CallsFrom, ObservedCalls]
  | cons preimage rest ih =>
      intro entry hentry
      simp [sha256CallsFrom, ObservedCalls] at hentry
      rcases hentry with hhead | htail
      · left
        simpa [hhead, sha256Site]
      · exact ih (index + 1)
          (denoteCall adversary (sha256Site index preimage) state).state entry htail

/-- `CallProgramRollback` also fixes the external world: the seven SHA-256
sites are static, hence every dynamically observed call rolls back by kind. -/
theorem sha256_call_world_rollback (input : Inputs)
    (adversary : AdversaryModel) (state : CallState) :
    (denote (sha256Calls input) adversary state).2.world = state.world := by
  apply denoteCallProgram_all_revert_preserves_world
  exact observed_sha256_calls_roll_back (digestPreimages input) 0 adversary state

/-- Registry-facing transaction simulation theorem.  It composes the typed
program, exact seven-call digest, root check, and whole-transaction rollback;
only SHA-256 functional correctness remains under `A-SHA256-FFI`. -/
theorem ssz_tx_simulation_correct (input : TxInputs)
    (before after : State) (attempts : List CallAttempt) (trace : CommitTrace)
    (hwidths : exactTxWidths input) :
    exactTxWidths input ∧
      (digestPreimages input.toInputs).length = 7 ∧
      (runVerification input = .accept ↔
        computedRoot input = input.expectedDepositDataRoot) ∧
      (runVerification input = .revertRootMismatch →
        (transactionObservation input before after attempts trace).committedState = before) := by
  refine ⟨hwidths, digest_preimages_length input.toInputs,
    accepted_iff_root_matches input, ?_⟩
  intro hfail
  exact (verification_failure_rolls_back input before after attempts trace hfail).1

#check ssz_tx_simulation_correct
#check sha256_call_world_rollback
#check denote_success_compose

end LidoSRv3.Audit.Verity.SszTxSimulation
