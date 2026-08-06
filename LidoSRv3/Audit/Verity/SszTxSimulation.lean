import LidoSRv3.Audit.Trace
import LidoSRv3.Audit.Verity.SszAbstractDigest
import Compiler.CompilationModel
import Compiler.Modules.Precompiles
import Verity.Core.Model.CallProgramRollback
import Verity.Core.Model.DenoteExternalCalls
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
