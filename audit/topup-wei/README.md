# TOPUP-2: uint64-derived wei bounds and arbitrary allocations

Candidate increment; independent review and integration acceptance are pending.

Source pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

## Useful result

`router_success` proves that a successful arithmetic admission returns the true
mathematical sum of the module's arbitrary allocations and that this sum is at
most `maxTopUpPerBlockGwei * 10^9`. It does not replace the module with a greedy
allocator. The unchecked sum cannot wrap and thereby evade the final budget
check: the proof derives its range from the gateway's actual uint64 target and
uint64 maximum-validator count, plus the router's per-key comparisons.

`gateway_wei_bounds` also proves that the gateway's own unchecked sum of limits
is exact and that every gwei limit survives conversion to wei and back. This
sum is the sum of **limits**, not the amount later allocated or deposited. It
must not be identified with the historical `sourceRun.used` quantity.

## Correspondence

| Pinned Solidity | New definition or proof | Exact relationship |
|---|---|---|
| TopUpGateway.sol:42,47-48 | `GatewayConfig` | `Fin (2^64)` represents the actual three storage field widths; no 32 ETH restriction. |
| ValidatorWitness.sol:18,21,23; TopUpData pending array | `ValidatorInput` | uint64 effective/exit, bool slashed, uint256 pending. Paired input records represent arrays after equal-length checks. |
| TopUpGateway.sol:403-414 | `evaluate`, `evaluate_bound` | Early exit/slash returns precede checked addition. Addition overflow yields `none`; successful gap is bounded by target. |
| TopUpGateway.sol:174-175 | `hcount` | Explicit successful admission guard `validatorsCount ≤ maxValidatorsPerTopUp`, not a no-wrap assumption. |
| TopUpGateway.sol:226 | `weiLimits`, `conversion_exact`, `conversion_roundtrip` | Unchecked multiplication is represented modulo 2^256; its exactness is proved. |
| TopUpGateway.sol:227 | `uncheckedSum`, `gateway_wei_bounds` | Left-to-right modular accumulation, proved equal to the mathematical sum. |
| SRTypes.sol:192; StakingRouter.sol:696,700,706 | `routerBudget`, `uint64_wei_fits` | Actual uint64 block cap converts safely, budget takes minimum then discards wei dust. Module share allocation remains an arbitrary input. |
| StakingRouter.sol:723-734 | `allocationGuards`, `router_unchecked_sum_exact` | Arbitrary allocations must align to gwei and fit their corresponding limits. A longer list fails indexing; a shorter list is allowed by this arithmetic loop. |
| StakingRouter.sol:737-739 | `routerAccept`, `router_success` | Successful final comparison bounds the true sum; no assumed no-wrap premise. |

The comparison is a manual source transcription pending independent review backed by textual
anchors and exact file comparisons, not a machine-checked Solidity/EVM
translation. `check_source.py` verifies all four files against the immutable
git object and checks 24 relevant anchors; `source-check.json` contains hashes.
The script is deliberately explicit that textual checks do not prove semantic
equivalence or deployed provenance.

## Domain and remaining obligations

The top-level theorem requires (1) the source cardinality guard, (2) successful
limit evaluation of paired inputs, and (3) successful execution of the new
arithmetic admission function. Config widths are structural source facts, not
assumed bounds on computed sums. No gas bound or synthetic iteration limit is
introduced. Finite lists may reach the full uint64 cardinality domain.

This increment does not prove array extraction/ABI decoding, physical storage
reads, SSZ verification, activation/freshness/auth checks, module-share
calculation, the module call itself, execution of the ETH pull/deposits,
rollback, or block-history invariants. It does not compose with the existing
Verity `PTopup2` parent; that explicit bridge remains necessary for any claim
that the existing parent now executes these source-faithful arithmetic steps.
Per-call block-cap arithmetic is not a proof of an aggregate cap across calls
in the same block. Runtime codehash/fork provenance is also separate.

## Validation

- `lake env lean LidoSRv3/Audit/Source/TopupWeiBounds.lean`: passed on 2026-09-09
  with `leanprover/lean4:v4.31.0`.
- `python3 audit/topup-wei/check_source.py`: passed; source files equal pinned
  git objects, all 24 anchors present.
- `lake build LidoSRv3.Audit.Source.TopupWeiBounds LidoSRv3.Tests.TopupWeiBoundsMutants`: passed; see `validation.log`. Axioms for both principal theorems are only `propext` and `Quot.sound`. The 495 jobs include reused Mathlib dependencies; this was not a full repository rebuild.

`TopupWeiBoundsMutants.lean` contains kernel-checked branch witnesses and
counterexamples for missing pending balance, wrong conversion units, missing
alignment/per-key/aggregate checks, unchecked helper addition, and unrestricted
modular sums. It also exercises maximal uint64 bounds, arbitrary non-greedy
allocations, short/long results, and rounding dust. These are Lean regression
witnesses, not differential EVM tests. They do not independently certify the
source transcription. No full repository rebuild is claimed.

## Pinned Solidity execution check

`solidity/TopupWeiBounds.t.sol` inherits the actual pinned TopUpGateway and
calls its unchanged `_evaluateTopUpLimit` body. Five Foundry tests pass with
solc 0.8.25: three fuzz tests of 1,024 inputs each (including an explicitly
active-validator distribution and accepted gaps), maximal target, checked
overflow and early filtering. `solidity-validation.log` and `validation.json`
record the commands, package integrity and scope. This checks the evaluator
and conversion; it does not test the real router or execute Lean through FFI.

To reproduce, extract `npm pack @openzeppelin/contracts@5.2.0` into
`/tmp/lido-topup-wei-deps/package` and verify the tarball integrity against
`validation.json`, then run the recorded Foundry command from repository root.
The dependency matches the version in the pinned `lido-core/package.json`.
The harness is outside the default test directory to avoid changing shared
Foundry configuration. No dependency pin or root import was modified.
