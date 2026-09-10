# Raw witness access and actual SHA/proof consumer

This increment removes independently supplied decoded witness fields and slice lengths from a new raw-data consumer of the accepted BLS/proof primitives. `SszWitnessAbi.run` follows the inspected solc 0.8.25, via-IR, optimizer 200, Cancun `BlsCompositionHarness.verify` access/call order. That inherited wrapper invokes the unmodified pinned `_validatorHashTreeRoot` then `SSZ.verifyProof`. It is not the complete CLValidatorVerifier entrypoint.

## Executed inputs and derived invariants

`header` checks the nonpayable value, selector `3bd227c1`, static head, outer uint64 offset and eight-word witness head. `tail` retains the compiler's signed relative-pointer comparisons and uint256 arithmetic. In particular, a relative offset of -128 can wrap to an earlier valid calldata key. There is no canonical/aligned/positive-offset admission. Key SHA executes before decoding dirty witness uint64/Bool fields; proof-tail decoding follows all seven pair calls. The fields, WC, raw GIndex and root actually feed the existing BLS/proof programs on their carried EVM states.

`read64_success`, `readBool_success` and `tail_success_length` derive raw field and length facts from executed guards. `fields_success` relates all six returned fields to actual raw words. `run_success_origin` derives the executed call chain, key length 48 and proof-length cap from successful execution, with no decoded-witness, per-call reply or digest premise.

`call_environment` follows the existing EVM.call return rule, including arbitrary Theta account/substate results; caller calldata, sender, value and depth are preserved. `pubkey_environment`, `pair_environment` and `merkle_environment` compose this rule through the actual accepted primitives. They need no initial gas/depth/memory, SHA-output-size or arbitrary-callee frame premise. `run_success_input_binding` uses these invariants to bind the fields, WC, proof tail, raw GIndex and root to the **original** calldata while the final verifier receives the actual state and digest returned by the BLS calls. It does not replace those calls by a payload held in an unused result.

## Checks performed

The targeted Lean build checks ten public source theorems, three private proof helpers, two named regression theorems and nine kernel examples. Thirteen axiom-query occurrences (twelve distinct declarations) report only propext, Classical.choice and Quot.sound. Tests cover the canonical and wrapped-negative key slices, canonical proof slice, uint64 upper bound and dirty uint64/Bool words, and actual key-call rejection before later dirty fields/proof-tail faults. The failure fixture executes depth 1024, not a supplied fake SHA result. Bound-read lemmas eliminate the opaque zero-padding FFI from these kernel checks; abbreviations expose word constructors to rewriting. Failed intermediate diagnostics are retained with their original scope.

Four fresh Forge tests execute the pinned inherited leaf/verifier wrapper: accepted wrapped-negative key offset; key SHA failure before a dirty uint64; dirty Bool rejection before first pair SHA; last pair SHA failure before malformed proof-tail decoding. Fault-order tests explicitly mock selected SHA replies; the accepted negative-offset execution uses real SHA. These are finite compiler/access checks, not universal compiler equivalence or full CLValidatorVerifier tests. Compiler metadata binds all eight actual source inputs by SHA256 and Keccak256. The inspected optimized IR and its unchanged seven-input harness metadata are retained separately.

## Necessary work still open

The successful-access facts do not establish full raw-byte/typed-tree equivalence. Calldata extents and initial reachable calldata size, memory, depth and gas still require derivation for that composition. This increment imposes no new small-calldata or canonical-offset premise to evade those obligations. It makes no claim about hypothetical huge-calldata execution.

The access/call interpreter omits compiler dynamic-array allocation, free-memory-pointer checks, memory spill layout and surrounding opcode gas. Its semantic errors do not establish exact revert bytes; no full World frame or compiled rollback theorem is provided. The complete slot/root/GIndex prefix and actual verifier entrypoint must still consume this path. SHA implementation/cryptographic correctness and authentic consensus/deployed configuration remain external trust; no new deployment verification is claimed.

SSZ-1 and all eight unfinished guarantees remain OPEN. ALLOC-1/ALLOC-2/RESERVE-1 and public identifiers are unchanged. Independent full-source review of the frozen exact commit is required before integration. No site, merge or deployment acceptance is inferred from compilation.
