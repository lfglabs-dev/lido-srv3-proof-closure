# P-RESERVE-1

The registered executable theorem is `PReserve1LiveWriters.actual_reserve_physical_history`. It consumes finite histories of existing source operations, passing each actual returned World into the next operation. Its shared callee is the existing physical queue finalizer combined with the locator/queue/router/oracle/consensus pipeline, using concrete Keccak. Unknown selectors remain explicit external behavior.

The previous executable registration, `PReserve1.verity_tx_simulates_reserve_spec`, and the abstract `source_spend_preserves_withdrawal_reserve` remain unchanged. Their cached-demand/model observation premises are not used to establish the new physical-history statement. The optional UnfinalizedStaticcall record bridge is not treated as an executable producer.

The new parent consumes:

- Internal target writes: target is updated, effective reserve becomes min(previous reserve, requested target), buffer/balances remain unchanged and events retain source order.
- Internal report rebalance: effective reserve becomes max(reserve,target), with unchanged target/buffer/balances and the conditional reserve event.
- Actual report execution: ordered authorization/vault/finalization results feed independent checked physical accounting and rebalance. Queue finalization executes its role/pause/range/delta checks, checkpoint/lockedETH/finalized-ID writes and events. Subsequent demand reads use the resulting queue state.
- Actual withdrawal execution: successful status/router/spend/tail stages provide their Worlds and traces. The spending-stage allocation and guard derive its admitted amount and independent partition from actual locator/queue-return bytes and decoding. No cache freshness or independent successful-call receipt is supplied. Failed transactions restore their own entry World.

A history denotes separate operations, not a new Solidity atomic batch. Earlier committed writes remain when a later transaction reverts.

Source pin: `lido-core@17005714f151e5502c559932319a3f2f74ac2436`. Relevant source is Lido.sol670-680,839-886,1125-1132 and WithdrawalQueueBase.sol332-362,143-146. Reused source commits include `b06cf0dc0861b93592f1de80820b68ff10b6905f` (live queue/internal writers), `043a845b5db3ef538eff0cf4e6328f400375ccc8` (report parent) and `e8d8c8964289fb1277c1dd8b8a220be781994c01` (physical queue finalization).

Remaining obligations:

- Configured locator/queue/router/oracle/consensus identities and parameters must be tied to deployment. Actual dispatch is included; deployed identity, role distinctness and general compiler/runtime correctness are not proved.
- The partition is derived at the actual spending-stage entry. Final protected-reserve invariance after arbitrary unknown callbacks requires their physical preservation contract; it is not inferred here.
- Target/rebalance actions are internal writers. The target setter outer ACL, outer ABI/payable frame setup and broader deployment context remain explicit entry boundaries.
- Unknown callees and general precompile/gas/LOG ABI/bytecode correspondence remain outside this source-shaped claim.

Targeted validation passed at `6044da2ba6a3d8547327889bb6b33f780eeed197` in dgx-spark job `05c5bfba-4727-4be4-bc9a-ab470c21e4d6` (1,273 build jobs):

```sh
lake build LidoSRv3.Audit.Guarantees.PReserve1LiveWriters LidoSRv3.Tests.TrioReserve1.Differential LidoSRv3.Tests.TrioReserve1.ReportDifferential LidoSRv3.Tests.TrioReserve1.QueueFinalizeDifferential
```

Both history theorems printed only foundational axioms. Earlier failed jobs are retained in the mission receipts; their parser/case-split errors are corrected at this SHA. Those historical runs used Lean v4.31.0 and Verity e977aaad6e1a9e92e0132d41b3d33a14135a4d46. The current dependency pin is recorded in `proofs/LOCKFILE.md`. Building differential entry modules is not execution of their external harness cases. The historical 15-case Solidity RESERVE harness pass applies to its earlier SHA/scope. Combined-SHA validation and fresh independent audit remain required.
