# Continuation — not a completion claim

Read STATUS and the latest source-composition receipts first. The old gate
runner handle is absent, and full gates have no verified terminal success.
The unchanged remote wrapper rejects the submodule in complete-source mode;
use a supported complete-source/dependency transport when available. Do not poll/resubmit the failed remote job.
The final complete P-RESERVE-1 proof has not been constructed.

## Highest priority proof/implementation work

1. State the complete independent withdrawal interaction specification. A useful
   partition relation describes deposits as the maximal amount bounded by buffer
   and stored reserve, withdrawals as the maximal amount bounded by remaining
   buffer and the observed live demand, and total conservation. Relate demand
   to the ACTUAL queue CALL return observation, not an existential unrelated
   word or cached input. Lift the relation through guard precedence, saved
   locals, packed writes/events, later frame failure, seed update and ETH call.
2. Compose actual source callees rather than introduce an external-success or
   frame-preservation premise. Locator addresses are immutable constructor
   bindings (`LidoLocator.sol:46-56,78-88`). AccountingOracle.getCurrentFrame
   (439-442) calls BaseOracle._getCurrentRefSlot (357-360), which reads
   CONSENSUS_CONTRACT_POSITION and STATICCALLs IHashConsensus.getCurrentFrame.
   Timestamp at AccountingOracle:561-563 is checked GENESIS_TIME +
   slot * SECONDS_PER_SLOT. Runtime-code/config binding is an explicit
   compilation/deployment assumption; behavioral postconditions must be derived.
3. Router/RouterSpec and inherited execution now cover the actual receiver;
   maintain these while closing the full parent. The actual router receiver is 0.8.25 StakingRouter.sol:665-669: compare caller
   to immutable LIDO through _checkAppAuth (1177-1179), revert NotAuthorized(),
   then emit DepositableEthReceived(msg.value). The source compiler is now pinned to 0.8.25 with viaIR/Cancun, and tests
   run an in-process Cancun EVM. The forwarding harness is still fixture
   admission, not production router withdrawal initiation.
4. Nested call observations are missing from the current External reply type.
   Extend their representation separately from World state, prove the extended
   erasure laws, and model STATICCALL's state restrictions and failure behavior.
   Do not infer callback-freedom just from a Solidity view annotation: Lido's
   0.4.24 getters use CALL. A real-source call graph and callee semantics must
   justify any preservation result. Do not add a successful-callee hypothesis.
5. Tie Nat account balances to the relevant EVM word/input relation and credit
   semantics. Current small-balance differential vectors do not establish bounds.
6. Complete the writer inventory in SOURCE-MAP, including Aragon canPerform
   admission, reports/rewards/withdrawal finalization, initialization/migration,
   user submissions and rebalance. The physical uint128 projection bound is
   unconditional, but truncation can invalidate an intended untruncated sum;
   do not assume bounds on sums or reserve <= buffer. Internal scalar writer
   proofs are already checked; external parents and full storage frames remain.
7. Prove real queue-changing/rebalance/spending sequences, not just the existing
   fixed-demand two_spends mathematical lemma. Expand executed differential and
   mutation cases to follow the complete composed model. Keep source/payload/
   event normalization and exclusions explicit.

The comparison suite now runs 35 matching cases; receiver-auth/event mutants
join the cached-demand/rollback negative controls. See actual exit receipts. The generic
external interpreter permits arbitrary world effects; this supports failure
modeling but does not itself derive preservation by actual deployed source.
Old registered declarations remain untouched until full migration validation.
Canonical Trust/metadata/provenance registration remains missing. The component
Trust proposal is in proposed-trust.patch; it is not applied and is not a parent
registration proposal. No other closure/site PR is a dependency for independent
implementation progress.
