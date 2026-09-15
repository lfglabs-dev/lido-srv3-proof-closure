import Compiler.CompilationModel
import Lean

set_option pp.maxSteps 500
set_option pp.deepTerms.threshold 12

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

private def exceptUnitDecEq : DecidableEq (Except String Unit) := fun x y =>
  match x, y with
  | .ok _, .ok _ => isTrue rfl
  | .error a, .error b =>
    if h : a = b then isTrue (h ▸ rfl)
    else isFalse (by intro heq; cases heq; exact h rfl)
  | .ok _, .error _ => isFalse (by intro h; cases h)
  | .error _, .ok _ => isFalse (by intro h; cases h)

local instance : DecidableEq (Except String Unit) := exceptUnitDecEq

/-- Validation uses the declared local obligations; the opaque mechanics
collector need not be evaluated to establish that this guard is discharged. -/
theorem forward_validates : validateFunctionSpec forward = .ok () := by
  have documented : forward.localObligations.isEmpty = false := rfl
  simp only [validateFunctionSpec, documented, Bool.and_false, Bool.false_and]
  decide +kernel

set_option maxRecDepth 16384 in
set_option maxHeartbeats 4000000 in
theorem forward_inputs_validate : validateCompileInputs spec [selector] = .ok () := by
  unfold validateCompileInputs
  run_tac do
    let env ← Lean.getEnv
    let candidates := env.constants.toList.filter fun (name, _) =>
      name.toString.endsWith ".validateCompileInputsBeforeFieldWriteConflict"
    match candidates with
    | [(name, _)] =>
        let id := Lean.mkIdent name
        Lean.Elab.Tactic.evalTactic (← `(tactic| unfold $id:ident))
    | _ => throwError "expected one pinned compiler precheck definition"
  have hi : forward.isInternal = false := rfl
  have hn : forward.name = "forwardConsolidationRequest" := rfl
  simp [spec, forward_validates, hi, hn, List.filter_cons,
    Bind.bind, Except.bind, Pure.pure, Except.pure]
  all_goals decide +kernel

theorem forward_body_compiles :
    (compileStmtListWithFork [] [] [] .calldata [] false [] [] .cancun forward.body []).isOk = true := by
  simp [forward, lit, compileStmtListWithFork, compileStmtWithFork,
    compileExprWithInternals, compileRequireFailCondWithInternals,
    Bind.bind, Except.bind, Pure.pure, Except.pure, Except.isOk, Except.toBool]

theorem forward_no_templates : (templateIntrinsicItems spec).isEmpty = true := by
  decide +kernel

set_option maxRecDepth 16384 in
set_option maxHeartbeats 4000000 in
theorem forward_core_compiles :
    (compileValidatedCore spec [selector]).isOk = true := by
  have hi : forward.isInternal = false := rfl
  have hn : forward.name = "forwardConsolidationRequest" := rfl
  have hs : isInteropEntrypointName "forwardConsolidationRequest" = false := by decide +kernel
  have hf : applySlotAliasRanges [] [] = [] := rfl
  have hp : forward.params = [] := rfl
  have hl : forward.nonReentrantLock = none := rfl
  have hr : functionReturns forward = .ok [.uint256] := rfl
  have ht := List.nil_of_isEmpty forward_no_templates
  have hbody := forward_body_compiles
  cases hb : compileStmtListWithFork [] [] [] .calldata [] false [] [] .cancun forward.body [] with
  | error err => simp [hb, Except.isOk, Except.toBool] at hbody
  | ok body =>
    unfold compileValidatedCore
    rw [ht]
    simp [spec, compileGuardedFunctionSpec, compileFunctionSpec,
      forward_validates, hi, hn, hs, hf, hp, hl, hr, hb,
      attachNonReentrantGuard, compileConstructor,
      pickUniqueFunctionByName, List.filter_cons, List.mapM_cons,
      Bind.bind, Except.bind, Pure.pure, Except.pure, Except.isOk, Except.toBool]

theorem forward_compiles :
    (CompilationModel.compile spec [selector]).isOk = true := by
  unfold CompilationModel.compile
  rw [forward_inputs_validate]
  exact forward_core_compiles

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
