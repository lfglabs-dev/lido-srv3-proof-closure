# TOPUP-2 actual batch consumer

The registered promise is that the sum of allocations **within one batch** is
bounded by the router's configured cap. `PTopup2.actual_module_batch_bound`
now consumes `TopupBatchConsumer.run`: the existing gateway witness loop
produces the exact key bytes and wei limits used by the existing module CALL;
its raw response is decoded and checked by the existing router continuation.
The result bounds the mathematical sum of those decoded allocations, including
empty and zero replies. No count, limit, rounded-target or non-wrapping-total
bound is supplied as a caller premise.

At core `17005714f151e5502c559932319a3f2f74ac2436`:

| Promise connection | Executed source and proof |
| --- | --- |
| Gateway limits reach the module | `TopUpGateway.sol` 163–236; the accepted `TopupGatewayWitnessBatch.loop` produces the keys and limits consumed by `TopupBatchConsumer.moduleInput`, then `TopupModuleCall.execute`. |
| Cap and conversion are the stored values | `SRTypes.RouterState`, slot 5, uint64 at bit 24; `StakingRouter.sol` 696–709. `blockCap` reads that word, `target` applies the minimum and Gwei rounding, and `target_bound` derives the width and cap bound. |
| The actual reply is bounded | `StakingRouter.sol` 717–743. `run_success_bound` obtains the real raw CALL result and decode from `module_execute_success`, derives the exact mathematical sum using the gateway count/limit invariants, and applies the executed target guard. |
| Public consumer | `LidoSRv3.Audit.Guarantees.PTopup2.actual_module_batch_bound` directly consumes the preceding source theorem. The historical abstract allocator theorem and identifiers remain available. |

The preceding module-allocation result is an arbitrary uint256: the minimum
proves the cap for **every** result of that preceding computation. This avoids
requiring an allocation bound or changing the accepted ALLOC guarantees.

This is the value path, not a complete public-entry simulation. The caller
supplies typed witness rows, credential/root configuration and the starting
world. Role/pause/timing/root-age and router admission, the source view-call
prefix, public ABI admission and final gateway history writes have not yet
been connected to this executor. The public Verity simulation still uses the
historical abstract allocator; connecting the actual consumer to that registered
simulation remains necessary. `TopupModuleCall`'s documented no-code attempt
and decoder allocation-error differences remain unresolved wherever exact
observable failure behavior is claimed. These omissions are not discharged by
this successful-batch bound. The existing independent module and withdrawal
interpreters remain arbitrary; the bound is on the actual decoded allocations,
not on arbitrary extra effects an external module could perform.

General solc correctness, the declared Verity semantics, cryptographic
primitives, general gas and consensus retain their accepted status. Cross-call
history is outside this registered per-batch promise. Neither is a new delivery
gate. All eight campaign guarantees remain open pending their necessary
connections and final review.

## Verification

`lake build +LidoSRv3.Tests.TopupBatchConsumerRegression` checks the source and
public consumer plus three named kernel regressions and three arithmetic
examples. The exact payload fixture commits a zero reply and module effect;
the above-cap fixture rejects after decoding and restores provisional balances
and logs. Its constant SHA oracle is solely a structural fixture.

Five fresh Solidity tests execute the **unmodified inherited StakingRouter**
including its real allocation prefix and module CALL/decoder: stored cap and
full argument bytes, above-cap rollback of actual module storage, alignment and
per-key error ordering, and the zero-target pause guard. The packed cap getter
is checked with 1,024 fuzz cases across all neighboring fields. Fixture setup
seeds a standalone router and supplies Lido/module/locator implementations;
these tests do not establish initialization reachability, the gateway-to-router
composition, positive withdrawal/beacon execution or deployment identity.
Existing accepted gateway witness, module ABI and withdrawal/beacon checks are
reused only for unchanged sources; the receipt records those identities.
