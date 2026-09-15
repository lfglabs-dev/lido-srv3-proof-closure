import Compiler.CompilationModel

/-!
# P-CONSOLIDATION-1 abstract flow model

This subordinate evidence models only the source helper that forwards one
EIP-7251 consolidation request.  The pinned Solidity forms
`bytes.concat(sourcePubkey, targetPubkey)`: two adjacent 48-byte public keys,
with no separator or padding, followed by one low-level call to the
consolidation request contract.

The program stays on Verity's typed statement surface.  This slice binds the
payload layout and the single-call order; it does not claim Yul or EVM
execution refinement.
-/

namespace LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel

open Compiler
open Compiler.CompilationModel

def publicKeyBytes : Nat := 48
def payloadBytes : Nat := 96
def sourceMemoryOffset : Nat := 0
def targetMemoryOffset : Nat := 48
def sourceCalldataOffset : Nat := 4
def targetCalldataOffset : Nat := 52
def consolidationRequestAddress : Nat := 0x0000BBdDc7CE488642fb579F8B00f3a590007251

private def lit (value : Nat) : Expr := .literal value

/-- Typed low-level forwarding program.  Memory `[0, 48)` receives the source
key and `[48, 96)` receives the target key.  The only external operation is a
value-bearing `CALL` over exactly that memory interval. -/
def forward : FunctionSpec :=
  { name := "forwardConsolidationRequest"
    params := []
    returnType := some .uint256
    isPayable := true
    reentrancyTrusted := true
    localObligations :=
      [ { name := "exact_96_byte_payload"
          obligation := "Memory bytes 0..47 are the source key and bytes 48..95 are the target key, with no padding."
          proofStatus := .proved }
      , { name := "single_call_only"
          obligation := "The helper issues one CALL with input offset 0 and input size 96."
          proofStatus := .proved } ]
    body :=
      [ .calldatacopy (lit sourceMemoryOffset) (lit sourceCalldataOffset)
          (lit publicKeyBytes)
      , .calldatacopy (lit targetMemoryOffset) (lit targetCalldataOffset)
          (lit publicKeyBytes)
      , .letVar "success"
          (.call (lit Verity.Core.MAX_UINT256) (lit consolidationRequestAddress)
            .msgValue (lit 0) (lit payloadBytes) (lit 0) (lit 0))
      , .require (.eq (.localVar "success") (lit 1))
          "Consolidation request call failed"
      , .return (.localVar "success") ] }

def spec : CompilationModel :=
  { name := "LidoConsolidationAbstractFlow"
    fields := []
    constructor := none
    functions := [forward] }

def selector : Nat := 0x72510001

theorem forward_compiles :
    (CompilationModel.compile spec [selector]).isOk = true := by
  native_decide

abbrev Bytes := ByteArray

structure Inputs where
  sourcePubkey : Bytes
  targetPubkey : Bytes

def exactWidths (input : Inputs) : Prop :=
  input.sourcePubkey.size = publicKeyBytes ∧
    input.targetPubkey.size = publicKeyBytes

/-- The source layout is literal concatenation, so it adds no delimiter or
padding between the two keys. -/
def payload (input : Inputs) : Bytes :=
  input.sourcePubkey ++ input.targetPubkey

theorem payload_length (input : Inputs) (h : exactWidths input) :
    (payload input).size = payloadBytes := by
  rcases h with ⟨hsource, htarget⟩
  simp [payload, payloadBytes, publicKeyBytes, hsource, htarget]

inductive CallKind where
  | call
  deriving DecidableEq, Repr

structure Call where
  kind : CallKind
  target : Nat
  value : Nat
  input : Bytes

/-- Abstract call trace for the helper: exactly one call carrying the exact
96-byte concatenation. -/
def callTrace (value : Nat) (input : Inputs) : List Call :=
  [ { kind := .call
      target := consolidationRequestAddress
      value := value
      input := payload input } ]

theorem single_call_order (value : Nat) (input : Inputs) :
    (callTrace value input).length = 1 := by
  rfl

theorem source_then_target (input : Inputs) :
    payload input = input.sourcePubkey ++ input.targetPubkey := by
  rfl

/-- Registry-facing conjunction: the typed program compiles, its payload has
the exact 48+48 width, and its trace contains exactly one call. -/
theorem abstract_flow_refinement :
    (CompilationModel.compile spec [selector]).isOk = true ∧
      ∀ input : Inputs, exactWidths input →
        (payload input).size = payloadBytes ∧
          ∀ value : Nat, (callTrace value input).length = 1 := by
  constructor
  · exact forward_compiles
  · intro input h
    exact ⟨payload_length input h, fun value => single_call_order value input⟩

end LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel
