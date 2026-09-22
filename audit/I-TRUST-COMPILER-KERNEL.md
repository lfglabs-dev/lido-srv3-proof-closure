# Compiler witnesses and scoped trust

The current delivery uses Verity `600a2f7a9b07f7ea532451e7d58b106347a6817a`
and Lean 4.31.0. The compiler-success witnesses are kernel-checked proofs of
compilation acceptance. They do not prove compiler correctness or correspondence
with deployed bytecode.

The complete dependency audit checks 1,259 explicit disclosures and 16,645
compiled claims. Only `propext`, `Classical.choice` and `Quot.sound` occur;
no native proof exception is used. See the [delivery report](../report/DELIVERY-20260921.md)
and [hashed validation logs](receipts/delivery-20260921/validation.json).
Independent review remains separate and pending.

`trust-native-decide-allowlist.txt` is empty. `scripts/check_trust_axioms.py`
recomputes dependencies from the compiled environment, including supporting
claims and standalone drivers. The current gate calls `require_foundational`;
the older three-name authorization retained in `scripts/foundational_trust.py`
does not relax that gate. Saved-output checks alone are not environment validation.

The earlier authorization covered exactly three witnesses under
`LidoSRv3.Audit.Verity`: `AllocCapacityPhase3.consumed_summary_function_spec_compiles`,
`SszAbstractDigest.deposit_data_root_compiles`, and
`ConsolidationAbstractFlowModel.forward_compiles`. Their kernel replacements are
retained. The delivery also repairs the allocation, deposit and consolidation
compiler-success witnesses described in the delivery report.

Supported-module invariants, compiled memory/call fidelity and deployed runtime
identities remain separate proof boundaries.

## Historical attempts and receipts

The following record describes earlier pins and the policy in force at the time.
References to remaining compiler work or native exceptions below are historical;
the current validation and foundation-only policy are described above.

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
