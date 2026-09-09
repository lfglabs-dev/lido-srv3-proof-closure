# TOPUP-2: post-return timing increment

Candidate local arithmetic/source slice; not closure of the inter-call budget
obligation. Source pin:
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

## Concrete contribution

The positive delay is derived from the actual uint16 setter's successful
branches, including initialization and arbitrary subsequent valid changes.
A successful positive-limit return stamps the current block. On the explicit
operational horizon `0 < block.number < 2^32`, another entry at that block then
fails the distance guard. Any successful change of delay preserves that
rejection: the proof does not assume configuration is frozen.

Calls with zero total limits cannot allocate positive value under the router's
actual per-key guards. This uses `gateway_wei_bounds` and
`allocations_sum_le` from the preceding source-sized arithmetic increment;
it does not assume the unchecked sum is exact. Such calls leave gateway timing
unchanged, but may still produce external module effects. Conversely, positive
limits with zero actual allocations DO update gateway timing.

## Correspondence and explicit domain

| Source | Module operation/result | Limits |
|---|---|---|
| TopUpGateway.sol:43-45 | `TimingState` | Actual uint32 last block/timestamp, uint16 delay. |
| initialize:97; setter:362-366 | `setDistance`, `Configured`, `configured_positive` | Zero and out-of-width settings rejected. `Configured` is local reachability through these operations, not full protocol reachability or a role invariant. |
| 323-330 | `distancePassed` | Zero-sentinel short circuit and checked subtraction are represented separately; underflow is `none`, ordinary failed distance is `some false`. |
| 232 followed by 234-236 and 340-345 | `finish` | Takes state after the external call returns. Positive **limits**, not positive allocations, trigger both truncating writes. |
| Successful return then next guard | `same_block_rejects_after_return` | Requires positive nonzero block below 2^32; this domain is stated, not proved from chain history. |
| Return, valid delay change, next guard | `same_block_rejects_after_setter` | Derives positive new delay and preserved last-block field directly from setter success. |
| StakingRouter.sol:725-741 and gateway:227,234 | `zero_limits_zero_allocations` | Uses exact uint64-derived sum bounds and source per-key guards; no allocator strategy assumed. |

`finish` is not a full successful-topUp theorem: authorization, witness checks,
router effects and returning successfully must still be connected to the
source execution. No rollback theorem is added. A reverted whole call must
roll back module and gateway effects before any historical invariant can rely
on it; the EVM/source bridge remains necessary.

## Why this does not yet prove the total per-block cap

1. **External-call interval before the update.** The router call at line 232
   precedes both last-top-up writes. The timing guard alone therefore allows a
   second admission using the old state during that interval. The regression
   witness demonstrates only this arithmetic guard fact. It does not prove an
   authorized reentrant execution or deployed exploit. `TOP_UP_ROLE`, the
   relevant role assignment invariant, the router/module/callback paths, and
   their successful/reverting behavior need a common execution proof. A theorem
   must derive that nested positive admissions are impossible on the intended
   domain, or account for them; adding a `noReentry` premise would not close it.
2. **Real truncating storage boundary.** At block 2^32, writing the block yields
   zero and activates the sentinel. At block 2^32+100, subtraction from stored
   100 also permits another call. Likewise timestamp 2^32 is stored as zero.
   These are source arithmetic counterexamples to unrestricted timing claims,
   not claims about currently reachable chain events. Deployment lifetime and
   chain-context bounds remain to establish if used by the eventual guarantee.
3. **Root age and source admission.** Lines 380-388 require childBlockTimestamp
   newer than the stored timestamp and reject roots whose child timestamp plus
   maxRootAge is too old. The uint64+uint16 addition has a checked uint64 result;
   the last stored timestamp is only uint32. This slice does not prove root
   lookup/canonical timestamp correspondence or that a future root is
   unavailable. It does not silently use freshness as a reentrancy lock.
4. **Role/configuration/state lifecycle.** Valid delay setters are covered;
   access control, role grants/revocations, proxy upgrades/raw storage changes,
   pause/resume and full initialization lifecycle are not. They are not claimed
   to preserve a full per-block allocation invariant.

## Next verifiable result and calibrated effort

Next: inspect and record the complete `Gateway → Router → allocateDeposits →
withdrawal/deposit` callback graph together with actual TOP_UP_ROLE grants on
the intended configuration. Then state an admissible-history invariant that
addresses nested entries and failures. This can be done without changing
shared metadata or claiming deployment provenance has been completed.

A focused 2–4 hour source/configuration analysis should decide whether role
invariants can exclude nested admission or nested accounting is necessary.
A subsequent source-model proof is provisionally 0.5–2 working days, low
confidence until that interface is explicit; composing the EVM/call/rollback
parent is additional work. These are estimates for remaining work, not
validation receipts or commitments.

## Verification

`lake build LidoSRv3.Audit.Source.TopupCallHistory LidoSRv3.Tests.TopupCallHistoryMutants` passed with Lean v4.31.0. See `validation.log` and `validated-inputs.sha256`. Printed axioms for configuration positivity, rejection after setter and zero-limit allocation are only `propext` and `Quot.sound`. The pinned gateway file was independently compared byte-for-byte with its immutable git object; see `source-check.json`.
The tests distinguish early guard admission from post-return rejection, reject
zero/out-of-range delay settings, exercise block/timestamp truncation, distinguish
zero allocation from zero limit, and check subtraction panic behavior.
No full repository build, independent review, deployment check or inter-call
closure is claimed by this candidate dossier.
