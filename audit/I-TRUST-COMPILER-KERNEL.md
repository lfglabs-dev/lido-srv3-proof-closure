# Compiler witnesses and scoped trust

Owner20260915 authorizes native evaluation for exactly these existing witnesses
under `LidoSRv3.Audit.Verity`:

- `AllocCapacityPhase3.consumed_summary_function_spec_compiles`
- `SszAbstractDigest.deposit_data_root_compiles`
- `ConsolidationAbstractFlowModel.forward_compiles`

This permits additional trust in Lean's compiler and native runtime for those
Boolean decisions. It is not kernel-only evidence and does not prove Solidity
runtime, deployment or compiler correctness. It authorizes no unrelated axiom,
including a test-native dependency inherited by a production theorem.

## Current candidate

The salvaged proofs retain the same compilation statements and replace these
three native decisions with structured kernel proofs, using Verity
`1e95e925736d9253df41918ce1e4858cdd8e8a8d` ([dependency PR2409](https://github.com/lfglabs-dev/verity/pull/2409)).
Targeted bundled runs compiled these replacements; final exact-SHA environment
checks and independent review remain required. No whole-candidate trust pass is
inferred from those builds.

`trust-native-decide-allowlist.txt` records the exact emitted inventory, now
expected empty. Authorization is a separate fixed three-name set in
`scripts/foundational_trust.py`; a kernel replacement need not keep an accepted
native dependency alive. `check_trust_axioms.py` independently recomputes named
dependencies, verifies exact emitted inventory, and checks any emitted native
axiom's safe Boolean reflection type, source module/site and closed expression
by native reevaluation. Source-declared generated names, hidden dependencies,
false/unevaluable expressions and unrelated axioms remain rejected. Saved-output
mode checks a report only; it is not environment validation.

The static inventory delta is recorded in
[ kernel-witness-inventory.json ](metadata-reconcile/kernel-witness-inventory.json):
407 to 404 tactic sites, exactly three removed and one existing site moved.
Project-wide test tactic occurrences are distinct from dependencies emitted by
`Audit.Trust`. Kernel proof replacements do not settle ALLOC reachability,
compiled memory/call fidelity or deployed runtime identities.

## Historical attempts and receipts

The following record describes earlier pins and the policy in force at the time;
its rejected native dependencies are accepted only under the later scope above.

At Verity `e977aaad6e1a9e92e0132d41b3d33a14135a4d46`,
`Compiler/CompilationModel/ScopeValidation.lean:55,64` calls
`staticParamBindingNames`. `Compiler/CompilationModel/InternalArgs.lean:6,30`
defines that helper and `internalParamYulNamesForType` using `partial def`.
The pinned source exposes no kernel reduction equations for those helpers in the
paths inspected. A prior direct kernel-decision attempt at `b164f2e72796aae7c7da1411b0cf6be2401cf9c8`
failed in registered job `b33c8f90-856b-43fb-9148-bd853185bf18`; its original proofs
were restored, not relabeled foundational. Repeating it unchanged is not a repair.

Remaining work is a kernel-checkable proof of the same compiler result, including
the opaque validation helpers it consumes. A total/equational compiler change
requires separately declared linked-dependency PR ownership and validation; linked dependency PR #2409 is now owned by this same writer (session 19395ff6).
The PR918 pin remains unchanged pending validation. There is
no premise assuming the desired compilation result. Runtime/deployment and
supported-module reachability obligations are separate and remain open.


The retained test.log of job 8fddeaae was recovered by registered read-only job
75bf7dfb-b70c-4a36-b177-9e94a03c8947. Its line 1069 identifies precisely these
three unauthorized compiler dependencies; no inventory mismatch caused that run.
The excerpt and SHA256 are committed under audit/receipts/8fddeaae/.

A subsequent `cbv` attempt on the unchanged consolidation compilation statement
failed: 6aae3cd9 reached recursion 16384; 67983778 reached the separate simplifier
step limit with recursion 65536; 5f04dc8d reached recursion with a 2,000,000-step
budget; 765c03e6 reached recursion after registering the existing Bool.and_false
kernel theorem as a local evaluation rule. No axiom was removed. The original
proof was restored. These resource-limit failures do not prove impossibility or
identify an opaque helper as the sole cause. In particular, consolidation's
forward.params is empty, so scalar parameter-binding helpers alone do not
explain that witness's failure. A structured compiler proof remains necessary.

Review 8f198d99 at df0845148a3f9de24b334035811e68d01a73eaf9 again
identified the same three unauthorized dependencies. In addition to scalar
parameter bindings, the pinned `Verity/Core/Model/Types.lean:1274,1281,1366`
defines `Stmt.fold`, `foldList`, and control-flow traversal as `partial def`.
`Validation.lean:1337` consumes the fold even for consolidation's empty
parameter list, and its return-path check consumes `controlFlowList`.

The separately owned dependency repair is
https://github.com/lfglabs-dev/verity/pull/2409. It retains compiler validation
and proposes total traversal definitions, with kernel-only tests. Its existence
does not discharge any compiler witness; PR918 must pin a validated successor
and replace/recompute the actual witnesses before this dependency is closed.
