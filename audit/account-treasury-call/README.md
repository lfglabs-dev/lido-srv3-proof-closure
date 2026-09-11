# ACCOUNT actual treasury STATICCALL and consumed recipient

Base `eee5d6700e5d99cc35eab7bf3e1e2b51a2465857` (integrated ACCOUNT322).
Solidity pin `17005714f151e5502c559932319a3f2f74ac2436`.

## Public improvement and composition

`PAccount1.actual_report_fee_mint_treasury_call` consumes the new
`ReportFeeTreasuryCall.execute`. It performs the same report/getter/checked-fee
mint, then the actual sequential module transfers, then the locator read on
**that exact ACCOUNT World**, then the treasury transfer to the decoded result.
It retains the accepted ACCOUNT322 Success and pointwise share Ledger, including
mint/casts/checked split, exact events and transfers, arbitrary duplicate/self
recipients, and paid shares equalling the actual fee shares minted.

The new ReadEffects gives the concrete pre-read module execution, caller/target/
zero-value/4-byte-selector request, positive code guard, actual external raw
return on the post-module World, canonical decoded address and its bound, actual
payment of that same address, exact payment/event order, and the successful
readonly attempt. The caller's Nat address bound and untruncated request address
are **derived from successful transfer execution**, not new input hypotheses.
Zero mint has no attempts. A successful zero treasury branch has no locator
attempt. `actual_report_treasury_failure_restores` restores the complete ACCOUNT
entry world on every failure, including already executed mint/module transfers.
Failed read bytes and attempted requests are retained separately from committed
state; a successful read followed by ABI/transfer rejection is not erased.

The actual executor calls the external exactly once when required. The old
TreasuryRead adapter is used only in the proved extensional projection to
ACCOUNT322; it is not an extra call in the executor. No old source/claim/executor
is changed or silently widened, and no stage-success, ABI, frame, array-alignment
or code-presence premise is supplied.

## Source and compiler correspondence

1. Pinned `Accounting.sol:403–407` supplies the same report/mint result and
   conditional positive-fee distribution. `:470–488` loops through the module
   payments before the positive-treasury branch and calls
   `LIDO.transferShares(LIDO_LOCATOR.treasury(), treasuryShares)`. The actual
   complete `_distributeFee` source body is copied byte-identically into the
   retained DistributionHarness, checked by `solidity/check.py`.
2. Fresh `solidity/DistributionHarness.asm`, solc0.8.9 optimizer200, fixture
   target **Byzantium**, lines625–669: immutable locator masked to an address;
   selector **0x61d027b3** encoded as exactly four bytes; **EXTCODESIZE guard
   before STATICCALL**. The actual caller is the executing Accounting address.
   TreasuryCall executes that code guard; missing code fails empty without an
   attempted external. It passes the actual `ReportFeeMint.World`, not a fresh
   default/old world, into the readonly interpreter.
3. Assembly670–679 bubbles rejected returndata; success then runs the ABI
   decoder. `TreasuryCall.call` retains rejection bytes and the failed attempt;
   forbidden state change is a failed static attempt, not successful execution
   whose effects were discarded. The interpreter has no post-world channel.
4. Assembly1561–1605 (tag57) performs signed `(dataEnd-headStart) < 32`, then
   loads a word; tag66 at907–931 requires the word equal its low160-bit cleanup.
   `decodeAddress` applies the signed word-size check (negative high-bit or
   smaller than32 fails), then canonical160-bit check. It admits trailing bytes
   and address zero; zero subsequently reaches the actual transfer guard.
   Host byte-list length is projected to uint256. Full memory allocation/copy
   or pointer-provenance equivalence is not claimed by this decoder.
5. The already accepted StETH transfer source and share-rate implementation
   remains unchanged. `distribute_success` projects the identical actual module
   and treasury transfers to FeeDistribution.execute; `execute_success` then
   applies ACCOUNT322's full Success/Ledger to the exact same mint and result.
   No fake Live-world embedding or new shares storage slot is introduced.

## Exact boundary

ACCOUNT keeps its accepted `ReportFeeMint.World`: separate router core,
StETH physical word core, and the abstract shares map. TreasuryCall reuses Live
Request/NestedAttempt and StaticCall.Reply, with a readonly interpreter over
**this actual ACCOUNT world**. It does not claim an ACCOUNT↔Live.World state
correspondence or physical mapping-key derivation.

The immutable locator address and address-indexed code metadata are explicit
context inputs, not proved deployment/context provenance. The external reply
remains arbitrary and read-only; the proof establishes the actual request,
guards/ABI decoding, and consumption of its result, not correctness of a
particular deployed locator implementation. The earlier locatorAccounting
mint authorization input remains distinct. Scalar ABI/byte view, compiler,
memory/copy, general gas and existing Verity boundaries retain their stated
scope; this is not a full compiled Accounting/Lido/report theorem. Neither
reportRewardsMinted nor the later rebase/full-report suffix is introduced.

## Verified checks

- Cached prerequisites (35 jobs) and all four new modules compile sequentially
  using `build.py`, without changing any package registration or global facade.
- Twelve kernel regressions/consumer checks: real report→mint→module transfers
  visible to the actual request; canonical returned address paid with trailing
  bytes; public composed consumer; noncanonical and short decoder failures;
  zero address decoded then transfer rejection; malformed post-module reply
  rollback; code guard before external; exact bubbled bytes; forbidden static
  write; zero-mint and zero-treasury no-attempt paths.
- **Nine fresh Foundry cases** execute the unchanged full inherited StETH and
  exact Accounting distribution fragment. RawTreasury checks selector, exact
  calldata length, actual msg.sender, and actual module share effects before
  returning bytes. Cases cover trailing/canonical consumption, short/noncanonical
  rejection, byte-exact `dead` propagation, an actual SSTORE rejected by
  STATICCALL, zero address transfer error, no-code rejection/rollback, and both
  zero skip paths. No-code case does not assert Foundry-intercepted revert bytes.
- Fixture setup/mint/rate overrides remain explicit; this is not a full
  production Accounting deployment. Full31/32-byte returndata edge cases cannot
  prove arbitrary memory provenance. The unusual static-write gas report is
  not credited as a gas guarantee.
- `solidity/check.py` verifies32 actual compiler input Keccaks,29 unchanged
  original StETH dependencies, exact pinned Accounting body, four artifact
  snapshots and fresh assembly. `validate.py` checks actual import source
  identities/pins and independently recomputes scoped kernel axiom closures.

Author stops at the frozen commit. Independent exact-source/Solidity review and
integration remain pending; this dossier is evidence, not a second roadmap.
