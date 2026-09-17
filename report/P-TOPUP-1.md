# P-TOPUP-1

The registered executable theorem is `PTopupRouterAdmissionCall.actual_topup_admission_calls_wei_and_revert`. It consumes `TopupRouterAdmissionCall.run` with concrete Keccak hashing. The success branch provides the complete existing admission/root/module/per-key/history conjunction; every error restores the entry World. It supplies no independent stage-success or desired frame-equality premise.

Previously the executable registration pointed to `PTopup1.verity_tx_simulates_source_with_nonzero_wrap_close`, whose conjunction mixes guarded and legacy allocation-only planes. That theorem and `source_topup_conserves_and_rolls_back` remain unchanged and available. Their Boolean/source-link and abstract-observation premises are not used as evidence for this actual chain.

The executed prefix checks physical gateway role/resume, array lengths and timing, calls the router locator, obtains physical credentials through its getter, and executes the witness/root loop. Before the module continuation, actual router locator return bytes determine caller admission; input lengths, module registration/status/type and conditional zero-target Lido canDeposit checks execute in source order. The external admission calls retain their actual requests and decoded results.

Physical uint64 gateway fields and checked witness headroom produce the wei limits passed to the module. The retained `TopupBatchRootCalls.Success` proves the total is exact and below one word. `TopupRootCallEffects.Effects` connects the same arrays to actual allocateDeposits request/reply bytes and decoded allocations, whose guarded sum is exact and bounded by the physical router block cap times 10^9. The actual module-returned World feeds the continuation: zero total emits an event without withdrawal; positive total executes Lido withdrawal with zero seed count and the per-key beacon helper. Its calls, payloads, values, balances, physical count at beacon slot32, events and attempts feed the parent. Physical gateway history updates use the returned World.

Source pin: `lido-core@17005714f151e5502c559932319a3f2f74ac2436`, `contracts/0.8.25/sr/StakingRouter.sol:686-756` and `TopUpGateway.sol`. No new executor replaces the existing derivations. Reused source commits include `ed043832023c75e04adf76ea05c3ac96f3353897` (consumed router admission calls) and `c0e2fe625f423c3f9b804b64e65d635c5af6d896` (actual root batch physical effects).

Explicit remaining boundaries:

- The outer gateway-to-router ABI CALL is not executed by this typed composition. Transported arguments and identities have no assumed deployed frame equality.
- `Input.allocation` is an arbitrary upstream word. The cap/rounding proof works for every such value, but the preceding getDepositableEther/module-allocation view calls and their failures are omitted.
- Outer ABI and phase-memory-cursor origins, fork/gindex configuration, beacon data/divisor and SHA precompile identities need separate binding.
- Lido withdrawal accounting executes; its getter/receiver callbacks still require named-callee correspondence. Module and callback effects are consumed without assumed ledger preservation. The beacon helper is a source-shaped physical callee model, not general deployed bytecode/LOG ABI/gas closure.

The preserved Solidity differential harness passed 19 tests at `bcc5ef6873b524242db7a7c1e1921510c80cc052` on dgx-spark (job `666c5a01-838a-488f-93cf-e313d3280215`). It tests the historical CLI and deliberately exhibits caller, empty-key and missing-journal divergences. That pass does not certify this new registered chain.

Targeted validation at `62008e7d34602b1b40fa0f716a63bc3a59a26257` passed with exit 0 (1,390 jobs) as job `f35d5eca-6c18-4e37-af6b-2bc3d934ac0d`, using Lean v4.31.0 and Verity e977aaad6e1a9e92e0132d41b3d33a14135a4d46:

```sh
REMOTE_BUILD_NODE_ID=dgx-spark REMOTE_BUILD_PASSIVE=1 remote-lean-build lake build LidoSRv3.Audit.Guarantees.PTopupRouterAdmissionCall LidoSRv3.Tests.TopupRouterAdmissionCallRegression LidoSRv3.Tests.TopupRootCallEffectsRegression LidoSRv3.Tests.TopupWeiBoundsMutants LidoSRv3.Tests.TopupTimingHistory
```

The registered theorem reports only `propext`, `Classical.choice` and `Quot.sound`. Admission, actual root/per-key effects, wei bounds and physical history regressions passed.

The earlier job `46b9f3c2` failed during checkout because submission preceded push; no Lean result came from it. Combined exact-SHA validation and fresh independent audit remain required.

## No re-entry (A-NO-REENTRY, 2026-09-17)

[PTopup1NoReentry](../LidoSRv3/Audit/Guarantees/PTopup1NoReentry.lean) restates `actual_continuation_locator_conserves` under the accepted assumption `A-NO-REENTRY` on the residual module/beacon interpreter (`NoReentry other [lido, router]`) and adds `Confined other [lido, router]`: storage of Lido and the router is unchanged by every CALL reaching that interpreter, no such CALL into them succeeds, and no accepted nested call into them is recorded. The premise is assumed, not proved for the deployed callees.
