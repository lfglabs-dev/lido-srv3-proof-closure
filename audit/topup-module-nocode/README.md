# TOPUP module CALL to an ordinary no-code target

Base: integrated proof `64f73f101187992db5b9b446852c3063a5a6d5b7` (#315).
Solidity: core `17005714f151e5502c559932319a3f2f74ac2436`, StakingRouter.sol:717–719, solc 0.8.25, optimizer 200, via IR, Cancun.

The existing consumed `TopupModuleCall.call` now uses the existing zero-value low-level CALL primitive. This matches the pinned compiler's typed `allocateDeposits` call: no code-size precheck, actual CALL first, successful empty return for an ordinary EOA/undeployed address, then rejection by the caller's return decoder. Generic Live/CallData primitives are untouched. This is not an unused adapter: TopupModuleCall.program/execute, TopupBatchConsumer and the #315 actual root/module batch already consume this definition.

`call_success_origin` keeps its public name but explicitly generalizes its formerly unconditional positive-code conclusion to no-code empty acceptance OR a positive-code actual interpreter result. `decoded_call_has_code` and `execute_success_has_code` derive the positive-code domain from decoder/execution success; no new consumer premise is added. Code-bearing successful and rejected calls retain their actual payload/value/returned world/nested attempts. At zero value funding cannot fail. Root rollback retains the attempted CALL while restoring storage, balances and semantic logs.

New public consumers in PTopup2ModuleFailure:

- `actual_module_no_code_failure` derives the exact consumed empty-decoder error, restored world and successful attempted module CALL from the physical no-code condition.
- `actual_root_batch_no_code_failure` covers the whole actual root/module batch without assuming successful admission or a successful root phase. Earlier gateway rejection makes no module attempt; otherwise actual successful-empty module CALL occurs after the executed root prefix and fails at decoding. All cases reject and restore the entry world.

The kernel regression executes the actual #315 root/module batch with BEACON_ROOTS still coded and only the module code absent. It observes the accepted root call, then accepted zero-value empty-return module call, then decoder error and full entry-world restoration. Existing successful batch and positive withdrawal/beacon regressions still pass. No successful claim domain is narrowed.

## Compiler and Solidity evidence

The fresh Solidity test inherits the existing fixture that invokes unmodified pinned StakingRouter.topUp. The two preceding module view getters are mocked to allow entry into the covered call site; allocateDeposits itself is not mocked. Module code is explicitly erased after mock registration and checked absent. `expectCall` verifies the exact actual allocateDeposits payload, then the caller fails and its balance remains unchanged. The fixture is not a claim that an ordinary EOA naturally answers those preceding view getters.

The retained verbose execution trace shows actual allocateDeposits CALL -> empty STOP -> parent rejection. Foundry substitutes a human-readable non-contract diagnostic into the caught parent revert data. Accordingly this test asserts rejection, NOT byte-exact empty EVM revert data. An initial stricter empty-byte assertion failed because of that diagnostic and was corrected; the failed run is not credited as PASS.

The independent recompilation packet uses the exact BatchRouter metadata source set and settings, requesting only optimized IR. Retained full `router-ir.txt` shows physical module-address SLOAD, actual selector/array encoding, `call(gas(), cleaned_4, 0, ...)` without EXTCODESIZE, the call-success branch copying returndata, and `abi_decode_array_uint256_dyn_fromMemory` with `if slt(sub(dataEnd, headStart), 32) { revert(0, 0) }`. For empty returndata this decoder guard proves the selected emitted empty-revert branch. This is source/compiler-artifact correspondence, not a formal whole-bytecode simulation.

## Boundaries unchanged

No-code means the inherited model's ordinary EOA/undeployed-address branch; precompile dispatch is outside it. The model condition does not redefine Ethereum precompiles as EOAs. Full gateway/router admission, raw outer ABI, memory-allocation failure equivalence, deployed consensus/crypto/gas/compiler correctness and full call-trace equivalence remain outside the existing covered-phase claims. Unlike the old code, ordinary no-code **module** attempt omission is no longer a residual gap. Expected withdrawal credentials and root configuration retain the #315 typed input boundaries.

Only four Lean paths and this dossier are in the writer's scope. AllGuarantees, Trust, dependency pins and site are untouched. Independent exact-source review and root integration are required before release. The writer does not review or approve this candidate.
