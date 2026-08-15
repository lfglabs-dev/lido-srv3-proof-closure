import LidoSRv3.Audit.Guarantees.PConsolidation1
import Compiler.CompilationModel
import Verity.Core.Model.Denote

/-!
# The consolidation entrypoint is outside the official denotation fragment

`audit/P-CONSOLIDATION-1-VERITY-GAPS.md` was written against Verity pin
`f485b2ca7502793ce227ede0076b7d070a0697b7` and asserts in prose that a
`FunctionSpec` performing an external call cannot be connected to the
external-call trace.  This module re-establishes the load-bearing half of that
claim as a *machine-checked fact at the currently pinned head*
`04729a9de9099e065dd09283e4f733a5fd4c2a16`, so that it cannot silently rot the
way the prose document did.

The pinned deep EDSL does have first-class external calls: `Expr.call`,
`Expr.staticcall`, `Expr.delegatecall` (`Verity/Core/Model/Types.lean:744`,
`:747`, `:750`) and `Stmt.externalCallBind`, `Stmt.tryExternalCallBind`,
`Stmt.ecm` (`Types.lean:1125`, `:1133`, `:1141`).

The *official* denotation pinned by `LidoSRv3.Audit.Verity.OfficialSemantics`
implements none of them.  Every such constructor falls through to the
catch-alls `| _ => none` (`Verity/Core/Model/Denote.lean:1030`) and
`| _, _ => .revert` (`Denote.lean:1371`); the upstream module header says so
directly (`Denote.lean:55-62`, "raw calls, ABI re-encoding returns, ECM,
unsafe Yul, `matchAdt`, internal calls").

An EIP-7251 consolidation request is *irreducibly* an external call.  The
small raw-call fragment below names a 96-byte input window but deliberately
does not claim that the two keys have been written there: this denotation has
no faithful byte-memory bridge for that preparation.  The exact theorem is
therefore narrower: unsupported `Expr.call` denotes as **unconditional
revert**, irrespective of payload preparation, for every oracle, transaction
and world.

The audit consequence is the point of this module.  Any statement of the form
`(run …).success = true → P` over such an entrypoint is **vacuously true** by
`ex falso` on a hypothesis that is provably `false`.  A future PR could
therefore "prove" an arbitrarily strong consolidation transaction property
without proving anything at all.  `success_hypotheses_are_vacuous` exhibits
exactly that degenerate derivation, so the trap is recorded rather than left
available.

Nothing here closes any plane.  P-CONSOLIDATION-1 keeps `theorem: null`,
`theorem_planes: []` and its OPEN transaction plane; this module is the
exact-head blocker record for that row.
-/

namespace LidoSRv3.Audit.Verity.ConsolidationCallFragment

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote

/-- The EIP-7251 consolidation predeploy, `0x0000BBdDc7CE488642fb579F8B00f3a590007251`. -/
def consolidationPredeploy : Nat := 0x0000BBdDc7CE488642fb579F8B00f3a590007251

/-- `source ‖ target`: two 48-byte BLS keys, no padding. -/
def payloadBytes : Nat := 96

def requestsSlot : Nat := 0

def requestsField : Field :=
  { name := "requests", ty := .uint256, «slot» := some requestsSlot }

/-- Compiler declaration for the bind-shaped foreign boundary.  It is marked
unchecked: compilation is not a denotation or refinement theorem. -/
def consolidationExternal : ExternalFunction :=
  { name := "consolidationPredeploy"
    params := [.uint256, .uint256]
    returnType := some .uint256
    proofStatus := .unchecked
    axiomNames := [] }

/-- The two guards a consolidation entrypoint performs before it calls out:
both keys must be non-zero.  These constructors *are* inside the fragment, so
they are not what makes the entrypoint revert. -/
def guards : List Stmt :=
  [ .require (.lt (.literal 0) (.param "sourceKey")) "empty source key"
  , .require (.lt (.literal 0) (.param "targetKey")) "empty target key" ]

def params : List Param :=
  [ { name := "sourceKey", ty := .uint256 }
  , { name := "targetKey", ty := .uint256 } ]

/-- A raw `Expr.call` reading the 96-byte memory window `[0, 96)`, followed by
the success return.  This fragment performs no memory writes and does not claim
that the window contains `sourceKey ‖ targetKey`. -/
def rawCallTail : List Stmt :=
  [ .require
      (.eq
        (.call (.literal 100000) (.literal consolidationPredeploy) (.literal 0)
          (.literal 0) (.literal payloadBytes) (.literal 0) (.literal 0))
        (.literal 1))
      "consolidation call failed"
  , .return (.literal 1) ]

/-- The same call expressed with the declaration-level external-call statement
instead of the raw opcode expression. -/
def bindCallTail : List Stmt :=
  [ .externalCallBind ["ok"] "consolidationPredeploy"
      [.param "sourceKey", .param "targetKey"]
  , .return (.literal 1) ]

/-- Consolidation-shaped entrypoint using the first-class low-level
`Expr.call`.  Its unsupported-call result is independent of the unwritten
96-byte input window. -/
def requestConsolidation : FunctionSpec :=
  { name := "requestConsolidation", params := params, returnType := some .uint256
    body := guards ++ rawCallTail }

/-- The same entrypoint expressed with the declaration-level external-call
statement instead of the raw opcode expression. -/
def requestConsolidationBind : FunctionSpec :=
  { requestConsolidation with
    name := "requestConsolidationBind"
    -- Required compiler disposition for this foreign-call scaffold.  This is
    -- an explicit unchecked trust annotation, not a reentrancy proof.
    reentrancyTrusted := true
    body := guards ++ bindCallTail }

/-- Identical shape with the external call deleted.  This is the control: it
isolates the call as the cause of the revert. -/
def guardsOnly : FunctionSpec :=
  { requestConsolidation with
    name := "guardsOnly"
    body := guards ++ [ .return (.literal 1) ] }

def spec : CompilationModel :=
  { name := "ConsolidationCallFragment", fields := [requestsField]
    constructor := none,
    functions := [requestConsolidation, requestConsolidationBind, guardsOnly],
    externals := [consolidationExternal] }

def selector : Nat := 0x9d1c5d81
def bindSelector : Nat := 0x9d1c5d82
def guardsOnlySelector : Nat := 0x9d1c5d83

theorem requestConsolidationBind_registered :
    requestConsolidationBind ∈ spec.functions := by
  simp [spec]

-- The bind entrypoint taken from the registered function list enters Verity's
-- official compiler.  The raw-call sibling is deliberately outside the safe
-- compiler fragment, so this guard compiles only the reviewed registered
-- element without adding a generated proof dependency.
#guard (CompilationModel.compile { spec with functions := [spec.functions[1]] }
  [bindSelector]).isOk

def txOf (sourceKey targetKey : Nat) : DenoteTransaction :=
  { sender := 0xCAFE, functionSelector := selector, args := [sourceKey, targetKey] }

def run (oracle : DenoteOracle) (fn : FunctionSpec) (tx : DenoteTransaction)
    (world : Verity.ContractState) : DenoteResult :=
  denoteFunction oracle spec fn tx world

/-! ## The blocker, machine-checked

Both statements are universally quantified over the oracle, the transaction
(hence over both key arguments and the sender) and the world.  Neither assumes
anything about calldata decoding: the `bindExternalParams` failure branch
reverts too, so the case split is discharged on both sides.
-/

/-- `Expr.call` has no denotation arm, so it evaluates to `none`
(`Denote.lean:1030`) and the enclosing `require` reverts. -/
private theorem rawCallTail_reverts (oracle : DenoteOracle) (fields : List Field)
    (state : DenoteState) : execStmtList oracle fields state rawCallTail = .revert := rfl

/-- `Stmt.externalCallBind` has no denotation arm, so it reverts directly
(`Denote.lean:1371`). -/
private theorem bindCallTail_reverts (oracle : DenoteOracle) (fields : List Field)
    (state : DenoteState) : execStmtList oracle fields state bindCallTail = .revert := rfl

/-- A `require` is inside the fragment: it either continues in the *same*
state or reverts.  It can never `stop` or `return`, which is what lets the
tail decide the whole body. -/
private theorem require_continue_or_revert (oracle : DenoteOracle) (fields : List Field)
    (state : DenoteState) (cond : Expr) (msg : String) :
    execStmt oracle fields state (.require cond msg) = .continue state ∨
      execStmt oracle fields state (.require cond msg) = .revert := by
  rcases hev : evalExpr oracle fields state cond with _ | resolved
  · exact Or.inr (by simp [execStmt, hev])
  · by_cases h : resolved != 0
    · exact Or.inl (by simp [execStmt, hev, h])
    · exact Or.inr (by simp [execStmt, hev, h])

/-- A `require` prefix cannot escape a reverting tail. -/
private theorem cons_require_reverts (oracle : DenoteOracle) (fields : List Field)
    (state : DenoteState) (cond : Expr) (msg : String) (rest : List Stmt)
    (hrest : ∀ s, execStmtList oracle fields s rest = .revert) :
    execStmtList oracle fields state (.require cond msg :: rest) = .revert := by
  show (match execStmt oracle fields state (.require cond msg) with
        | .continue next => execStmtList oracle fields next rest
        | .stop next => .stop next
        | .return value next => .return value next
        | .revert => .revert) = .revert
  rcases require_continue_or_revert oracle fields state cond msg with h | h <;> rw [h]
  exact hrest state

/-- The two guards either revert outright or leave the state untouched, so the
tail decides — and both tails revert. -/
private theorem guarded_body_reverts (oracle : DenoteOracle) (fields : List Field)
    (state : DenoteState) (tail : List Stmt)
    (htail : ∀ s, execStmtList oracle fields s tail = .revert) :
    execStmtList oracle fields state (guards ++ tail) = .revert :=
  cons_require_reverts _ _ _ _ _ _ fun s =>
    cons_require_reverts _ _ s _ _ _ htail

/-- Shared shape: if the body reverts under every possible parameter binding,
the whole denotation reports failure — including the calldata-decode failure
branch, which reverts too. -/
private theorem denote_fails_of_body_reverts (oracle : DenoteOracle) (fn : FunctionSpec)
    (tx : DenoteTransaction) (world : Verity.ContractState)
    (h : ∀ bindings, execStmtList oracle (effectiveFields spec)
        { world := withTransactionContext world tx, bindings := bindings,
          selector := tx.functionSelector } fn.body = .revert) :
    (denoteFunction oracle spec fn tx world).success = false := by
  simp only [denoteFunction]
  cases bindExternalParams tx.functionSelector fn.params tx.args with
  | none => rfl
  | some bindings => simp only [h bindings]; rfl

theorem raw_call_entrypoint_always_reverts
    (oracle : DenoteOracle) (tx : DenoteTransaction) (world : Verity.ContractState) :
    (run oracle requestConsolidation tx world).success = false :=
  denote_fails_of_body_reverts oracle _ tx world fun _ =>
    guarded_body_reverts _ _ _ _ (rawCallTail_reverts oracle _)

theorem external_call_bind_entrypoint_always_reverts
    (oracle : DenoteOracle) (tx : DenoteTransaction) (world : Verity.ContractState) :
    (run oracle requestConsolidationBind tx world).success = false :=
  denote_fails_of_body_reverts oracle _ tx world fun _ =>
    guarded_body_reverts _ _ _ _ (bindCallTail_reverts oracle _)

/-- The registered bind entrypoint has the same reverting behavior; the
statement fixes the function to the member proved above rather than accepting
an arbitrary caller-supplied `FunctionSpec`. -/
theorem registered_external_call_bind_entrypoint_always_reverts
    (oracle : DenoteOracle) (tx : DenoteTransaction) (world : Verity.ContractState) :
    (denoteFunction oracle spec spec.functions[1] tx world).success = false := by
  simpa [run, spec] using external_call_bind_entrypoint_always_reverts oracle tx world

/-! ## The revert is caused by the call, not by the guards

Without this control the two theorems above would be uninformative: an
entrypoint that reverts for an unrelated reason would satisfy them just as
well.  `guardsOnly` is byte-identical except that the external call is
removed, and it succeeds.
-/

def witnessOracle : DenoteOracle :=
  { mappingSlot := fun _ key => key + 100
    keccakMemorySlice := fun _ _ _ => 0 }

def witnessWorld : Verity.ContractState := Verity.defaultState

theorem guards_only_succeeds :
    (run witnessOracle guardsOnly (txOf 1 2) witnessWorld).success = true := by
  rfl

/-! ## Why a success-conditioned consolidation claim would be vacuous

`P` is an arbitrary predicate: no property of the post-state is used.  Any
"transaction closure" for consolidation phrased as an implication out of
`success = true` is derivable this way and therefore carries no content.
-/

theorem success_hypotheses_are_vacuous
    (P : DenoteResult → Prop)
    (oracle : DenoteOracle) (tx : DenoteTransaction) (world : Verity.ContractState)
    (h : (run oracle requestConsolidation tx world).success = true) :
    P (run oracle requestConsolidation tx world) := by
  rw [raw_call_entrypoint_always_reverts oracle tx world] at h
  exact absurd h (by simp)

end LidoSRv3.Audit.Verity.ConsolidationCallFragment
