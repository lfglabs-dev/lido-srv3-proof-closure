# Actual physical claim → recipient CALL → final events

This candidate replaces five unproved finite receipt declarations from the
unaccepted ADDRESS branch with necessary execution consumers. It preserves the
accepted source-shaped equivariance helpers; it does not claim full four-entry
address-renaming correspondence. Base: `85a1f338990020f1b41cfbcf260609ed90675252`.
Pinned Solidity: `17005714f151e5502c559932319a3f2f74ac2436`.

## Public consumers

`PAddress1.actual_claim_recipient_effect` takes one successful root claim-iteration
execution and derives `ClaimEffect`. The certificate includes actual physical
request finalization/claimed/owner checks; the actual `prepareClaim` result and
checked locked-ETH subtraction; payout word fit; actual empty-calldata CALL
request, provisional transfer, successful returned world (and nested attempts);
and the final WithdrawalClaimed then Transfer events on that returned world.

`PAddress1.actual_claim_withdrawals_to_chain` takes the actual root batch success
and derives nonzero recipient, equal array lengths and an ordered `ClaimChain`.
Each subsequent physical claim starts on the preceding callback/event world.
The chain is an output theorem, not supplied successful-stage hypotheses.
`actual_claim_withdrawals_failure_restores` restores the complete entry world on
any root failure, including earlier callback writes/events and value transfers.
Attempted-call traces remain available under the existing Live semantics.

Arbitrary successful callbacks may alter storage, logs and balances. The result
does not assert recipient net credit, unchanged claimed bits after a callback,
a balance/log frame, or the correctness of a separately supplied receipt.

## Executable source correspondence

- WithdrawalQueueBase.sol `_claim` 460–479: validate zero/finalization/claimed/
  owner in source order, mark the physical packed claimed byte, perform actual
  owner-set removal, then calculate from the post-removal request/checkpoint
  state and subtract the freshly read locked amount before the CALL.
- `_calculateClaimableEther` 484–514 and `_calcBatch` 534–543: actual hint range,
  cumulative subtraction, nonzero shares and conditional discount multiplication.
  The cumulative fields are uint128 reads, so multiplying their difference by
  1e27 fits uint256. Discount multiplication is checked explicitly. Successful
  locked subtraction derives payout <2^256 rather than assuming it.
- OZ EnumerableSet v4.4.1 `_remove`: distinguish assertion/missing member,
  checked zero-length subtraction, invalid array indexing, conditional tail
  swap, and pop with its fresh post-swap length. Aliases are not ruled out with
  keccak injectivity premises. All reads/writes use the existing physical slots;
  base85a index, packed-field and swap/pop fixes remain.
- `_sendValue` 525–531: check actual incoming balance, CALL with empty bytes,
  adopt successful callback world, source error on rejection. Source event is
  emitted only after callback return. WithdrawalQueue.sol244–255 supplies
  recipient/array guards and the ordered loop plus ERC721 Transfer event.

The public typed executor retains its existing semantics boundary: the queue
storage is the root ContractState storage; deployment/self/code correspondence,
raw whole-entry ABI, precise revert-data and raw LOG encoding, gas and compiler
semantics are not newly proved. Its zero-code branch models ordinary EOAs;
precompile dispatch is not represented and must not be advertised as a theorem
about every zero-code EVM address. Keccak implementation identity is retained;
these necessary consumers do not assume slot injectivity. Raw Nat inputs are a
typed model domain; successful finalized/hint checks and payout subtraction
supply the relevant word bounds inside actual physical claims.

Other existing transfer/request/unwrap model issues remain outside this lot.
The legacy AddressTx changes are proof-only normalization and branch handling;
no definitions, theorem statements or hypothesis domains are changed.

## Validation methods

1. Targeted Lean builds and independently recomputed theorem dependency sets
   cover the new public consumers, physical storage lemmas and migrated tests.
   No global AllGuarantees/Trust/lake files were modified. Root integration must
   replace obsolete finite receipt queries and old PackD query names.
2. Three kernel regressions execute actual CALL requests/entry guards to detect
   wrong target, changed order and zero recipient. A general root-failure theorem
   covers rollback. They use `decide +kernel`, not native-decision axioms.
3. RuntimeRegression.lean executes the actual physical claim executor for five
   cases: two physical claims/CALL30→40; callback observes marked request and
   locked40, then commits returned storage before events; later callback failure
   restores prior callback storage/balance/logs; funding failure; duplicate claim.
   This is runtime evaluation using the existing EvmYul FFI, NOT kernel proof
   evidence. The temporary dylib is ignored and is not committed. `run-runtime.sh`
   links only the existing pinned FFI and generated wrapper objects.
4. Five Forge tests run the byte-identical pinned WithdrawalQueueBase and
   UnstructuredStorage plus byte-checked OZ v4.4.1. The small harness supplies
   storage setup and reproduces claimWithdrawalsTo guards/loop with the Transfer
   event. It does not instantiate the full WithdrawalQueueERC721 deployment.
   Tests cover two actual base claims and callback observation, later callback
   rollback, duplicate rollback, funding failure and ordinary code-less target.

`validate.py` records exact imported source-body identities, eleven dependency
pins and independently collected axiom sets. Unchanged local dependencies must
match base85a git objects; package sources must match their pinned git bodies.
The five old finite statements are retained only as Markdown historical
unproved text, never as axioms or imported declarations. Initial handoff patch
and KernelProbe are diagnostic history, not completed validation claims.
