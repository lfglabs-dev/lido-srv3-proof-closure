# TOPUP-2 scoped assurance review — `PTopup2.actual_module_batch_bound` on main `fc45c1fb`

**Verdict: CLEAN for the existing per-batch successful allocation-bound promise. Not campaign delivery. P-TOPUP-2 remains OPEN on the campaign matrix until root/site record this scope. Hermes does not merge/push/mark delivered.**

Packets (read-only, hashes not re-sealed here):
- Proof closure = main `fc45c1fb` contents under `consol698-review-input` (TOPUP code identical to reviewed 306 / f49 / 28585ee9).
- Site `site295-review-input` head `39589d4c`, registered original TOPUP-2 presentation hash `630010d1d7fff03a594fbe229f229030f92abd5f9e0d4dea62f0775fda8c0d9a` (unchanged since SITE306).
- Pin: `17005714f151e5502c559932319a3f2f74ac2436` (`StakingRouter.sol` `topUp`, `SRTypes.RouterState` slot 5, `IStakingModuleV2.allocateDeposits`).

No new writer. ACCOUNT `23e86519` / ADDRESS `a4865aa2` untouched. 39c EnumerableSet findings still stand.

## Promise under review (exact)

Site `plainGuarantee` (current, not historical greedy math):

> For a successful run of the registered actual-batch source consumer, the decoded module allocations sum to at most the stored router cap multiplied by one gwei.

Public consumer: `LidoSRv3.Audit.Guarantees.PTopup2.actual_module_batch_bound` (`PTopup2ActualBatch.lean`).

Conclusion proved:
`(TopupRouterContinuation.values allocations).sum ≤ (blockCap ctx.sender before).val * GWEI`
given `TopupBatchConsumer.run = .ok result` and `result.outcome = .ok ()`.

This is **one successful consumer run / one `topUp` batch**. Not cumulative across calls. Not TOPUP-1 conservation. Not full gateway admission.

## Source / theorem mapping

| Source (pin 17005714) | Model consumed on success |
|---|---|
| `RouterState` slot 5: `uint24 lastModuleId` then `uint64 maxTopUpPerBlockGwei` | `blockCap`: `(readContractSlot router (routerRoot+5)).val / 2^24 % 2^64`. `blockCap_packed`: any word `moduleId + cap*2^24 + upper*2^88` with widths yields `cap`. Initialization of the slot is irrelevant. |
| `maxTopUpPerBlockWei = uint256(maxTopUpPerBlockGwei) * 1 gwei` | `* 10^9` / `GWEI` |
| `smDepositableEthAmount = min(moduleAllocation, maxTopUpPerBlockWei)` then gwei-round down | `routerBudget` / `target`; `moduleAllocation` is a free `Word` (arbitrary prefix allocation). Bound uses `min`, so every allocation value is ≤ cap·gwei. |
| `allocateDeposits(...)` returns `uint256[]` (wei); loop 723–737: gwei-align, `≤ _topUpLimits[i]`, unchecked sum, `amount > rounded ⇒ revert` | `TopupModuleCall.call` + `decodeReturn` (ABI offset/length/words) + `guardSum` / `router_unchecked_sum_exact` / `allocationGuards`. Module effects arbitrary; no greedy policy. Zero/empty included. |
| Witness-derived `_topUpLimits` / keys fed into the module | `loop` then `moduleInput.limits/pubkeys`; same values in continuation input (`continuation_input` rfl). |
| Successful batch only | Premises are `run` success and `outcome = .ok`. Reverts never inhabit the conclusion. |

Transitive assumptions that **are** in the theorem (not hidden as new globals): opaque `Keccak` / ERC-7201 `routerRoot` constant; Live CALL+ABI decoder as the module reply; `readConfig`/`loop` as the witness limit producer; `ctx.sender` is the router whose slot 5 is read (`blockCap ctx.sender`). Accepted solc/Verity/crypto/gas/consensus unchanged; none is used as a new gate for this inequality.

## Why omitted full-entry paths cannot falsify this implication

Roles, pause, DSM, timing, root-age, view-calls, history/`lastTopUp`, outer error bytes, announced rollback, no-code attempt-trace mismatch (`CallData.invoke` vs typed CALL): on pin, those either revert before the allocation-sum check or do not return a successful `allocations` array. A successful `topUp` that reached the sum check already executed `amount ≤ rounded ≤ cap·gwei` regardless of how admission was proved. Cross-call reserve/conservation is not this guarantee (`topUp` does not accumulate a same-block remainder in this function). Pipeline.Bound at post-module world is a TOPUP-1 composition obligation, not a premise of this cap.

A blanket “full-entry missing” is therefore **not** a counterexample to the cap implication.

## What this is not

- Not “every bytecode path of TopUpGateway+StakingRouter is simulated.” The registered consumer is `TopupBatchConsumer.run` (length guards + witness loop + raw module execute). That is the value path named by the current public theorem and site `plainGuarantee`.
- Not ABI/error/rollback completeness. `decodeReturn` covers successful dynamic `uint256[]`; failed/malformed returns are outside `hs`.
- Not equality with historical greedy `aggregate_bounded_by_block_cap` (audit JSON still lists that parent; site correctly labels it historical).
- Not permission to flip campaign P-TOPUP-2 to CLOSED or to rewrite site without root. UX2/`IMPLEMENTATION_PENDING` still advertise full-entry leftover; that is **scope of the card**, not a hole in this inequality.

## CLEAN meaning (this scope only)

Necessary Lido-specific obligation for **successful per-batch allocation ≤ packed cap · 1 gwei** is discharged by `actual_module_batch_bound` on the actual decoded module reply and the packed slot-5 cap, for arbitrary prefix allocation and arbitrary module effects. Root may treat full-entry/roles/errors as **out of this promise**, not as blockers of it. All eight campaign IDs remain OPEN until root/site verification of this verdict.
