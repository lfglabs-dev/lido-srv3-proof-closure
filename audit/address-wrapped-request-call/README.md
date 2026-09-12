# WithdrawalQueue wrapped request call composition

This additive public consumer covers one item of `requestWithdrawalsWstETH`: WithdrawalQueue calls WSTETH `transferFrom`, calls WSTETH `unwrap` on the actual returned world, decodes the returned uint256 amount, checks that amount, asks STETH for shares with STATICCALL, and consumes the same returned state in the existing physical enqueue. There is no extra STETH transferFrom. No prior public consumer or shared definition is changed.

## Public consequence and composition

`PAddress1.actual_wrapped_request_withdrawal_enqueue` takes the whole new runner's successful outcome as its only execution hypothesis. `AddressWrappedRequestCalls.RequestEffect` derives:

- The actual first CALL request/reply, code check, decoded canonical bool (0 or 1), returned world and observed nested attempts.
- The actual second CALL on that returned world, its raw returndata of at least 32 bytes, and the decoded first uint256 word. Trailing bytes are allowed.
- The 100 ≤ decoded stETH amount ≤ 1000 × 10^18 bounds, and therefore its uint128 fit. These checks occur after unwrap, not on the wrapped input before either call.
- The actual STETH quote request using that very decoded amount, with the static reply interpreted on the unwrap-returned world. The shares cast is truncating modulo 2^128; no shares-fit premise is supplied.
- The unchanged `AddressRequestCalls.EnqueueEffect`: checked cumulative shares/stETH and ID, source-ordered physical request writes and checked owner-set insertion, then WithdrawalRequested and Transfer on the same state. Entry TIMESTAMP is captured independently of the arbitrary returned model environment; the report timestamp is read from physical storage at its existing post-ID-write position.
- A single chronological journal: transferFrom attempts ++ unwrap attempts ++ quote attempts. The enqueue makes no external calls.

`actual_wrapped_request_withdrawal_failure_restores` restores the complete entry World, including both callees' modeled changes, when the runner fails. Attempts remain audit observations. No internal success, received-payload, fit-shares, stage, frame or storage-nonalias premise is added.

## Actual source and compiler checks

Pinned core is `17005714f151e5502c559932319a3f2f74ac2436`. The entire unmodified WithdrawalQueue/WithdrawalQueueBase closure is vendored: seven core files and nine OpenZeppelin 4.4.1 files, checked against Git objects and the integrity-checked npm tarball. The new harness subclasses the real queue and calls the actual `_requestWithdrawalWstETH`; its one-item wrapper only resolves a zero owner. Its seed/read helpers and WSTETH/STETH doubles are test setup. The doubles are intentionally arbitrary external implementations, not copies of real token behavior.

`solidity/WrappedRequestHarness.asm` is the full actual legacy assembly from solc 0.8.9, optimizer 200, London. This fixture profile differs from the production Istanbul profile; it is not deployed-bytecode identity. Source WithdrawalQueue.sol lines 383–392 and assembly's `tag_291` show transferFrom CALL → unwrap CALL → amount guards → shares STATICCALL → enqueue → Transfer. Both mutable calls check code and bubble their rejected bytes. The bool decoder at `tag_654` checks minimum length/canonicality, and the caller pops its returned bool. The uint256 decoder at `tag_660` requires at least 32 bytes, loads the first word and does not demand exact returndata length. The observed zero bool and trailing 33/64 bytes are exercised by the fixture.

`check-slots.py` independently recomputes the four consumed queue bases from the exact Solidity namespace preimages using `cast keccak`, checks the repaired Lean literals, and finds them in this fresh assembly. It also checks transferFrom, getSharesByPooledEth and unwrap selectors with `cast sig`. Queue mapping and owner-set nested mapping/array helpers are reused unchanged: key/address then base in two 32-byte words, metadata at the next word, owner array at Keccak(length-slot), index map at owner-base+1. No obsolete pre-repair constant or isolated alternate storage implementation is introduced. The full existing enqueue preserves arbitrary alias behavior rather than asserting unjustified final slot re-reads.

## Remaining boundaries

This lot proves the WithdrawalQueue caller composition with arbitrary WSTETH and STETH interpreters. It does not prove the implementation of WstETH, its burn, balances, allowances, or the immutables' deployed provenance. No unused adapter to the older standalone unwrap model is offered as a substitute. The caller itself has no zero-wrapped-input guard: the actual WstETH implementation can reject zero, while an arbitrary callee may accept it; the successful zero-input diagnostic makes that distinction explicit.

Initial pause/permit/batch and outer calldata/array allocation are outside this one-item phase, as in the stETH request consumer. Caller addresses and the designated queue storage lens use the existing typed World interface. The whole EVM dispatcher, memory/gas/returndata allocation and compiler/runtime equivalence are not proved. Guard faults preserve their model categories; full custom-error argument/LOG ABI byte encodings are not claimed by Lean. The actual Solidity tests separately compare raw error bytes and event fields. StaticExternal has no mutable returned-world channel; it is not a proof of arbitrary EVM static execution. The inherited Keccak primitives and model package trust limits remain. This increment neither weakens old claims nor promotes token-conservation or full ADDRESS closure.

## Validation and reproduction

Normal targeted source build passed 1261 jobs (new source actively compiled in 1.6 s). Final public/tests target passed 1263 jobs (tests actively compiled in 2.6 s, with unchanged source/public cached). There are four exported source theorems, two public theorems, 18 kernel regressions and a public rollback instance. Five fresh scoped axiom queries contain only propext/Classical.choice/Quot.sound; the unwrap effect uses only propext/Quot.sound. Existing dependency linter warnings remain in logs; no new-source warning or admitted proof is accepted.

Four complete native diagnostics pass: successful physical enqueue/event amount consumption, immutable entry TIMESTAMP despite changed model callee environment, zero wrapped input accepted by an arbitrary callee, and late owner-set rejection with global rollback. They use the actual existing EvmYul FFI sources compiled into a temporary dylib, with runtime inputs recorded. These executable checks are not kernel theorems or positive kernel instances. No new native_decide, axiom, interpreter or cryptographic theorem is introduced.

Nine fresh actual Solidity tests pass, including 1024 fuzz cases. Tests cover both returned-world mutations, exact input/output amount use, accepted false bool/trailing returndata, noncanonical and short decoders, amount failure before quote, bubbled failures, static write failure, late owner-set failure, owner fallback, event order and uint128 shares truncation. Post-revert zero counters are rollback observations, not independent evidence that a call was never attempted.

The final imported closure checks 1246 source identities and 11 package pins against base `f9f5639bdcc30a5f653fe679c9caba306a84df19`; all old bodies and the selected old local olean artifacts are unchanged. Build identities are recorded after successful commands and do not pretend to be contemporaneous hashes of development failures. Raw assembly's blank EOF is preserved as the sole whitespace exception.

```sh
lake build LidoSRv3.Tests.AddressWrappedRequestCalls
python3 audit/address-wrapped-request-call/validate.py
python3 audit/address-wrapped-request-call/run-diagnostics.py
python3 audit/address-wrapped-request-call/check-slots.py
forge test --root audit/address-wrapped-request-call/solidity --fuzz-seed 0x20260911 -vv
forge inspect --root audit/address-wrapped-request-call/solidity WrappedRequestHarness assembly
```

`check-slots.py` uses the pinned checkout at `/tmp/lido-ssz-proof-committed/lido-core`; adjust that read-only location if reproducing elsewhere. No full repository build, global wiring, publication or deployment is included in this source candidate.
