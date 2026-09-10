# Independent TOPUP actual-root physical-effects source review

**CLEAN — exact frozen `c0e2fe625f423c3f9b804b64e65d635c5af6d896`.** No blocking proof, source-correspondence, consumer, scope or receipt issue found. Checkout `/tmp/lido-topup-root-physical-effects` is clean; author stopped before review. Reviewer `/root/topup_root_call_batch` authored none of this increment. Reviewer authored previously accepted #315 actual-root substrate; this review independently assesses the new composition and its use of that substrate, not a new independent certification of the reviewer-authored old code. Date 2026-09-10.

## Complete increment and actual consumer

Compared the complete tree against base `09a09ad875f8e1519586a04932efd4dbacdf713f`: only three new Lean files and the new audit dossier are added (14 files total). Every inherited source, executable, theorem, test, manifest, global wiring and previous receipt is unchanged. Read complete TopupRootCallEffects, PTopup1RootCalls and TopupRootCallEffectsRegression, the inherited batch success consumer, full TopupRouterCommitted and TopupBeaconCommitted, and the relevant actual continuation, beacon callee, root authentication and sum-bound definitions/proofs.

`PTopup1.actual_root_module_batch_effects` assumes only success of the existing complete typed `TopupBatchRootCalls.run`. Its single joint Effects proposition connects the actual gateway loop result, ordered authenticated rows, exact evaluated wei limits and pubkeys, actual flattened root attempts, exact module CALL/raw reply/decoded allocations, mathematical sum and the executed zero/positive physical suffix.

The proof uses the existing batch success theorem to obtain an actual loop output and success of the exact module executor. It then inverts that same executor with `module_execute_success`, obtaining its actual reply, decoder result, post-module World, guard sum and physical effects. It does not combine unrelated stage witnesses: both paths use the identical moduleInput constructed from the same loop output, module ID, key/operator arrays, router target calculation and initial World. Result-world and module-attempt equalities are composed through that same executor and suffix.

The returned allocation sum fits uint256 because actual per-allocation guards bound it by the actual evaluated limit sum, whose width is derived from the gateway cardinality/configuration. `uncheckedSum_exact` therefore identifies the executed guard result with the mathematical allocation sum. The real target guard and computed packed router cap give its cap bound. No count, sum, width, exact-total, array-length, stage-success or external-frame premise is added.

## Physical scope and transitive conditions

For zero sum, the actual post-module World is preserved except for the router zero event; there are no withdrawal/helper attempts. The module's own arbitrary state and log effects are retained.

For positive sum, the existing PositiveEffects relation names the actual successful withdrawal and helper results and traces. It derives final core/balances from that helper World, the router's balance restoration relative to the post-module World, the helper's pointwise balance transfer relation relative to the post-withdrawal World, actual deposit-contract count slot32 increment, conditional final capacity bound and final router event. Module attempts concatenate with suffix attempts after the retained root phase.

These relative Worlds matter: no conservation from the pre-module snapshot and no locator/state preservation through an arbitrary module or withdrawal interpreter is asserted. The helper transfer/count retain their exact `if pubkeys=[] then 0 else ...` definitions. No unconditional count or amount is substituted for the helper's real empty-key early return. PositiveEffects still uses its actual helper and withdrawal execution equations; the new public consumer derives them from whole-batch success rather than accepting them.

Physical count results come from the existing executed TopupBeaconCallee: real slot32 read, capacity check, slot32 increment and binary-carry branch update; branch footprint excludes countSlot. Funding/value width/frame consequences are derived inside the existing successful helper/callee proofs. Existing opaque SHA is not treated as a newly evaluated or cryptographically verified function. The foundation-only transitive closure contains no added precompile/hash success axiom.

## Pinned Solidity and reused runtime evidence

Read pinned core `17005714f151e5502c559932319a3f2f74ac2436` TopUpGateway loop/call around 203–232, StakingRouter module/guard/withdrawal/helper/event sequence 717–758, BeaconChainDepositor helper 61–107 and deposit_contract.sol deposit body 101–159. Order corresponds to the inherited model: gateway pubkey/order/activation/authentication/headroom evaluation, actual module call and decode, allocation alignment/limit guards and unchecked sum, target check, zero skip or withdrawal then current credentials/helper, balance assertion and final event. Helper key-width checks precede zero-amount skip; nonzero amount guards precede actual deposit. Deposit callee checks widths/value/root/capacity before committed count/tree effects, retaining its source event placement.

Independently replayed `check_inherited.py` with its deterministic output write intercepted as an exact comparison: PASS, 45 unchanged compiler-source/fixture path identities across three historical SSZ-root/gateway/module receipts. The packet is explicit that this is identity-based reuse, with no fresh Solidity test and no compiled composition refinement. The historical harness foundry.toml is intentionally outside those current identity checks, as the checker documents. Independently compared the physical deposit_contract.sol body with the same Git pin as an additional source read; SHA256 `2a8db249155e8502e1132f14410b8d7b2a924512723ed07a08167477d8f8c073`.

The reviewed no-code module transport/decoder correction remains unchanged in the base. Its ordinary non-precompile interpretation and prior compiler/ABI boundaries carry forward; no new evidence is claimed for precompiles, full outer ABI or full deployed execution.

## Kernel non-vacuity and receipts

Ran all three new modules directly with normal `lake env lean`, without output writes or kernel bypass: PASS. This rechecks all 12 named regression propositions, including two public consumer instances. Zero execution retains a module-mutated World and only appends the zero router event. Positive execution computes three actual ordered root rows, exact 2/2/2 ETH module limits and accepts the exact payload before decoding 1/0/2 ETH allocations.

The positive regression does not directly evaluate opaque beacon SHA. It proves equality of the actual module program with the retained physical fixture, then transports the existing kernel result. Its physical conclusions are router balance 7, Lido balance 97 ETH, beacon balance 11+3 ETH, and deposit count slot32 from 3 to 5. An actual 2/2/0 ETH reply exceeds the 3 ETH target and is rejected after three root attempts and one module attempt; the complete entry World is restored. These tests exercise actual execution composition, not assumed success or a synthetic counter.

Replayed `validate.py` with the two deterministic JSON writes intercepted as comparisons: PASS, 1,288 actual three-target import-closure source identities, 11 exact package pins and 14 independently recomputed theorem axiom sets. Both retained JSON files match exactly. Every scoped set is contained in propext/Classical.choice/Quot.sound; no added custom or native-decision axiom. Inspected actual setup artifacts and normal build traces: root/module/physical consumer providers resolve locally to this candidate, with empty setup options and no kernel bypass.

Independently checked all 13 candidate receipt hashes. The retained named target build completed 1,305 jobs successfully; unchanged dependencies were reused. Direct normal-kernel checks and exact identities validate reuse, so no redundant named build was run. Complete diff preservation and `git diff --check` passed. Final HEAD remains c0e2fe62 and status is clean. No full AllGuarantees/Trust build or new Solidity run is credited by this source review.

## Boundaries and disposition

This is a stronger necessary-success theorem for the existing source-corresponding typed covered phase. Omitted gateway/router role/timing/locator admission, final gateway history update, full outer ABI/memory semantics, compiler/crypto/consensus/gas correctness and deployed-address identity remain outside. Diagnostic root/module/helper attempts retain their existing distinct types and are not claimed to be on-chain events. Earlier TOPUP1/TOPUP2 guarantees remain unchanged.

No candidate corrections requested. Root owns global facade/Trust wiring, combined checks, independent final integration review and publication. Reviewer made no candidate edits and is stopped after this report. CLEAN applies only to exact c0e2fe62 and the stated boundaries.
