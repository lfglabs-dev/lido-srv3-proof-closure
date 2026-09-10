# Actual root/module batch to physical TOPUP effects

Additive public consumer: `LidoSRv3.Audit.Guarantees.PTopup1.actual_root_module_batch_effects`.
Base: `09a09ad875f8e1519586a04932efd4dbacdf713f` (ACCOUNT302 union with the reviewed ordinary-no-code module-call correction).
Pinned Lido source: `17005714f151e5502c559932319a3f2f74ac2436`.

## Proposition and useful increment

Success of the existing `TopupBatchRootCalls.run` implies a single joint proposition relating its actual root-authenticated rows, evaluated limits, exact module CALL/raw reply/decoded allocations and executed zero or positive continuation. The mathematical sum of those same allocations is below 2^256 and bounded by the packed router cap. The unchecked guard sum equals that mathematical sum. Zero means the actual post-module world is preserved except for the zero-amount router event, with no withdrawal/helper attempt. Positive means the existing `TopupRouterCommitted.PositiveEffects` on the same allocations, same post-module world and same executed suffix: actual withdrawal/helper worlds and attempts, router balance restoration relative to the post-module world, helper transfer relation, actual deposit-contract slot32 increase relative to the post-withdrawal world, and actual final router event. Module and suffix attempts concatenate after the root phase.

The only proposition supplied by the caller is success of the complete covered root/module batch. No count, sum, width, length, per-stage success, module-return frame or locator-preservation premise is added. `run_success` supplies ordered authenticated rows and the derived limit sum bound. `module_execute_success` reads the same actual execution, obtaining the exact reply and guard/effects. `allocations_sum_le` and `uncheckedSum_exact` derive the mathematical sum; the proof does not invent a smaller input domain. No executor, adapter or executable semantics is changed.

This strengthens the earlier public cap-only joint result with the physical continuation already justified for that same actual execution. Existing TOPUP1/TOPUP2 claims are retained unchanged; this is not a replacement or narrowing.

## Source correspondence and retained boundaries

- `TopUpGateway.sol:203-232`: ordered validator witnesses, verification, exact pubkeys/evaluated limits and unchecked accumulation feed the router call. Existing `TopupGatewayRootCalls`/`TopupBatchRootCalls` provide the typed covered path with actual EIP-4788 calls and actual SHA-output projection; no `RootOracle` premise is introduced.
- `sr/StakingRouter.sol:717-758`: same actual module payload/reply, allocation alignment and per-limit guards, unchecked sum, target guard, zero skip, actual withdrawal then helper, balance assertion, and router event. `TopupModuleCall` is the corrected consumed low-level CALL/decoder implementation from the base, including ordinary-no-code accepted-empty then decode rejection. This proof-only increment changes neither success nor failure semantics.
- `lib/BeaconChainDepositor.sol:61-107`: empty-key early return, length checks, key width, zero skip, amount range, actual deposit-data encoding and deposit calls. `TopupRouterCommitted.PositiveEffects` retains the exact `helperAmount`/`helperCount` definitions, including empty-key behavior; it does not silently substitute an assumed count. Its slot32 conclusion comes from `TopupBeaconCommitted` and `TopupBeaconCallee`, which read/write the actual modeled deposit-contract storage slot.

This is a theorem of the existing source-corresponding typed covered phase, not compiled full gateway/router entry equivalence. Prior role/timing/locator/admission checks and the final gateway history update remain outside this proposition. The root ABI/memory/branch SHA and ordinary-address/staticcall boundaries keep their prior scope. Physical helper state and deposit semantics keep the retained compiler/crypto/Verity/gas/consensus boundaries; this increment introduces none stronger.

Arbitrary module and withdrawal interpreters remain explicit. No ETH conservation from the pre-module world is asserted: the actual module may change that world. The positive transfer/count conclusions are deliberately relative to the worlds named by the executed withdrawal/helper, not supplied frame hypotheses. No locator binding is claimed to survive an arbitrary module. Root and module/helper observations use their existing distinct diagnostic attempt types; they are not on-chain emitted events.

## Verification and non-vacuity

`lake build LidoSRv3.Tests.TopupRootCallEffectsRegression` builds the source consumer, public theorem and regressions, using unchanged dependency caches. The named kernel checks cover:

- two actual root calls and exact module-accepted arrays, zero allocations, preservation of the module's changed core/balances/logs plus only the router zero event and one module attempt;
- three actual root calls with distinct ordered keys, exact 2/2/2 ETH limits consumed by the module, actual 1/0/2 ETH returned allocations, and the public joint theorem;
- transport to the retained positive physical fixture by equality of the executed program, proving actual router/Lido/beacon balances 7 / 97 ETH / (11 + 3 ETH), and physical beacon count slot32 from 3 to 5;
- an actual decoded 2/2/0 ETH reply rejected above the 3 ETH target after three root attempts and one module attempt, with whole-entry world rollback.

Opaque beacon SHA primitives prevent direct evaluation of the positive world; the regression therefore uses the already kernel-proved physical fixture via an exact program equality. It does not add an evaluation axiom or FFI result. All named propositions, including the public theorem, have independently queried foundation-only kernel dependencies.

`validate.py` recomputes actual build import-closure source identities against the base and all 11 dependency pins, and independently queries the theorem axiom closure. `check_inherited.py` rechecks the 45 exact source/fixture identities behind the three retained SSZ-root/gateway/module Solidity receipts. These are identity-based reuse, not new Solidity execution or a compiled composition proof. No executable or compiler input changed in this lot; the earlier no-code corrected CALL/IR/test dossier is retained unchanged at the base.

Reproduce:

```sh
lake build LidoSRv3.Tests.TopupRootCallEffectsRegression
python3 audit/topup-root-physical-effects/validate.py
python3 audit/topup-root-physical-effects/check_inherited.py
```

Independent full-source/Solidity review and global facade/Trust integration are pending; this directory is a local candidate dossier, not a delivery verdict.
