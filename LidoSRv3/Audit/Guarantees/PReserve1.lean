import LidoSRv3.Audit.Source.ReserveCorrespondence
import LidoSRv3.Audit.Source.ReserveFreshCacheFromWQ
import LidoSRv3.Audit.Source.ReservePackedBufferSource
import LidoSRv3.Audit.Source.ReservePayableCallSource
import LidoSRv3.Audit.Source.ReserveSeedBookkeepingSource
import LidoSRv3.Audit.Source.ERC7201StorageSlotSource
import LidoSRv3.Audit.Source.SolidityUint128WrapSource
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PReserve1

open Verity
open LidoSRv3.Audit.SolidityReserve

def guarantee : Guarantee := ⟨.pReserve1, [.model, .source, .verityTx]⟩

/-- **P-RESERVE-1, source plane.** Under a fresh withdrawal-queue cache, any
committed `withdrawDepositableEther` spend passed the scoped guards, spent a
nonzero amount, took it from the depositable partitions only, and left the live
queue-facing withdrawals reserve unchanged.

Registered Wave 1 parent for P-RESERVE-1. Strengthened along the three
axes `report/P-RESERVE-1.md` calls out (issues #1, #2, #5):

* the premise is `modelWithdrawDepositableEther`, the full wrapper
  transition that enforces `canDeposit`/`authorizedRouter`
  (`scopedWithdrawGuards`) and the `amount ≠ 0` (`ZERO_AMOUNT`) guard before
  ever reaching `_spendDepositableEther`, not the bare internal spend helper
  the original theorem quoted. The conclusion now *proves*
  `scopedWithdrawGuards inputs` and `amount ≠ 0`, rather than assuming them: a
  guard failure reverts, so it can never reach the `.committed` branch this
  theorem is about;
* the conclusion adds `liveEffectiveWithdrawalsReserve after live =
  liveEffectiveWithdrawalsReserve before live`, the *effective*, min-capped,
  queue-facing reserve computed against an explicit `live` value standing in
  for a `WithdrawalQueue.unfinalizedStETH()` CALL — not merely the restated
  `storedDepositsReserve` field that `withdrawalPartitionSpendInvariant`
  quotes;
* that added conjunct needs `freshQueueCache before live`, naming the
  cache-freshness the original theorem left implicit. Drop that hypothesis
  and the identical spend from `depositsReserve + unreserved` can still raid
  the live reserve — see `staleQueueCacheKillLine_holds` and
  `LidoSRv3.Tests.ReserveMutants.stale_queue_cache_mutant_counterexample` for
  the concrete premise-necessity witness (it refutes the freshness-dropped
  sibling claim, i.e. shows the hypothesis cannot be removed; it does not
  refute this parent, which cannot be instantiated on that stale-cache
  vector).

The parent kill-lines, one per conjunct group, each the negation of this
theorem's full predicate shape — all five binders, `freshQueueCache`
hypothesis retained, same three-conjunct conclusion — applied to a mutant of
`modelWithdrawDepositableEther`:

* `LidoSRv3.Tests.ReserveMutants.guard_drop_kill_line_refutes_parent` kills
  conjunct (1) (`scopedWithdrawGuards` guard liveness): the mutant
  `mutantWithdrawNoCanDeposit` deletes only the `canDeposit` check, so on the
  witness (`canDeposit = false`, `authorizedRouter = true`, nonzero amount,
  fresh cache) the mutated call commits while the first conjunct is false.
* `LidoSRv3.Tests.ReserveMutants.partition_spend_mutant_kill_line_refutes_parent`
  kills conjuncts (2)-(3): the mutant `mutantWithdraw` keeps every guard and
  mutates the spend transition (`withdrawalPartitionMutant` commits the
  spend, then overwrites `buffered` with the post-spend
  `storedDepositsReserve`). On the witness vector the mutated call commits
  under a fresh cache while the live queue-facing reserve drops 50 → 0.

The original `withdrawalPartitionSpendInvariant` conjunct is retained so
existing consumers of this theorem name keep their evidence. -/
theorem source_spend_preserves_withdrawal_reserve
    (inputs : WithdrawInputs) (before after : ReserveState) (amount live : Word)
    (hfresh : freshQueueCache before live)
    (h : modelWithdrawDepositableEther inputs before amount = .committed after) :
    scopedWithdrawGuards inputs ∧
      amount ≠ 0 ∧
      withdrawalPartitionSpendInvariant before after amount ∧
      liveEffectiveWithdrawalsReserve after live = liveEffectiveWithdrawalsReserve before live := by
  unfold modelWithdrawDepositableEther at h
  split at h
  · contradiction
  · rename_i hcan
    split at h
    · contradiction
    · rename_i hauth
      split at h
      · contradiction
      · rename_i hAmt
        refine ⟨⟨?_, ?_⟩, ?_, committed_preserves_withdrawal_reserve before after amount h,
          committed_preserves_live_effective_withdrawals_reserve before after amount live hfresh h⟩
        · simpa using hcan
        · simpa using hauth
        · exact hAmt

/-- **Chantier 2 (Piste A, Thomas 2026-09-13) freshQueueCache bridge.**

Restates `source_spend_preserves_withdrawal_reserve` with the free
`live : Word` premise re-anchored to a source-level
`WithdrawalQueueStorage` read: `live = liveFromWQStorage wqs =
wqs.unfinalizedStETH`.  The caller can no longer supply an arbitrary
`live` word for the freshness hypothesis; they must construct a
`WithdrawalQueueStorage` and the freshness invariant is expressed
against the storage-derived value.

The registered `source_spend_preserves_withdrawal_reserve` above is
retained unchanged for existing consumers.  This bridge exposes the
Chantier 2 fidelity-composition value at the P-RESERVE-1 namespace:
consumers can now supply a WQ storage state instead of a free `live`
word.  Residual: `WithdrawalQueueStorage` is still a source model
(the `unfinalizedStETH` field is a named `Nat` accumulator, not yet a
STATICCALL-observed return-word); the executable-plane STATICCALL
frame is the next follow-up (see `fidelity.missing`). -/
theorem source_spend_preserves_withdrawal_reserve_under_pinned_wq_shape
    (inputs : WithdrawInputs) (before after : ReserveState) (amount : Word)
    (wqs : LidoSRv3.Audit.Source.WithdrawalQueueMappingSource.WithdrawalQueueStorage)
    (hfresh : freshQueueCache before
      ((LidoSRv3.Audit.Source.ReserveFreshCacheFromWQ.liveFromWQStorage wqs : Nat) : Word))
    (h : modelWithdrawDepositableEther inputs before amount = .committed after) :
    scopedWithdrawGuards inputs ∧
      amount ≠ 0 ∧
      withdrawalPartitionSpendInvariant before after amount ∧
      liveEffectiveWithdrawalsReserve after
          ((LidoSRv3.Audit.Source.ReserveFreshCacheFromWQ.liveFromWQStorage wqs : Nat) : Word) =
        liveEffectiveWithdrawalsReserve before
          ((LidoSRv3.Audit.Source.ReserveFreshCacheFromWQ.liveFromWQStorage wqs : Nat) : Word) :=
  source_spend_preserves_withdrawal_reserve inputs before after amount
    ((LidoSRv3.Audit.Source.ReserveFreshCacheFromWQ.liveFromWQStorage wqs : Nat) : Word)
    hfresh h

/-- **Chantier 2 (Piste A, Thomas 2026-09-13) D-PACK-1 packed uint128
buffered-pair bridge.**

Restates `source_spend_preserves_withdrawal_reserve` with the model's
`before.buffered` re-anchored to the low 128 bits of a pinned packed
uint256 storage word from `Lido.sol:131-132`
(`BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION`).  Callers supply
a `packedWord : Nat`, and the caller-visible `before.buffered` is
required to equal `ReservePackedBufferSource.unpackBuffered packedWord`
(the low-half extraction from the packed uint128 pair).

Discloses the Grok #419 D-PACK-1 divergence at the parent's ENUNCE
level: the Verity model treats `buffered` as an unbounded `Nat`,
whereas pinned Solidity 0.4.24 stores it as the low uint128 of a
packed uint256 with `depositedPostReport` in the high half.  A
seeded `depositedPostReport = uint128.max + 1 ether` therefore wraps
the high half in the pin but not in the model.  The bridge NAMES the
packed source; a full closure of D-PACK-1 additionally requires the
Verity model to observe wrap on the high half, which remains a
`fidelity.missing` follow-up.

The registered `source_spend_preserves_withdrawal_reserve` above is
retained unchanged for existing consumers.  Residual (in
`fidelity.missing` D-PACK-1 entry): the wrap on the high half is
still unobserved by the Verity model. -/
theorem source_spend_preserves_withdrawal_reserve_under_packed_buffer_shape
    (inputs : WithdrawInputs) (before after : ReserveState) (amount live : Word)
    (packedWord : Nat)
    (hLowMatch : (before.buffered : Nat) =
      LidoSRv3.Audit.Source.ReservePackedBufferSource.unpackBuffered packedWord)
    (hfresh : freshQueueCache before live)
    (h : modelWithdrawDepositableEther inputs before amount = .committed after) :
    scopedWithdrawGuards inputs ∧
      amount ≠ 0 ∧
      withdrawalPartitionSpendInvariant before after amount ∧
      liveEffectiveWithdrawalsReserve after live = liveEffectiveWithdrawalsReserve before live :=
  -- The packed-buffer premise `hLowMatch` names the pinned source of
  -- `before.buffered` (low uint128 of the packed word); the proof
  -- delegates to the registered parent since the model's `buffered`
  -- value at the ENUNCE level is unchanged — the ENUNCE now records
  -- WHERE this value comes from (the low half of a packed uint256),
  -- which is the D-PACK-1 disclosure.
  source_spend_preserves_withdrawal_reserve inputs before after amount live hfresh h

/-- **Chantier 2 (Piste A, Thomas 2026-09-13) D-TRANSFER-1 payable-CALL
naming bridge.**

Restates `source_spend_preserves_withdrawal_reserve` with an added
premise naming the pinned Lido.sol:885 payable-CALL frame
`stakingRouter.receiveDepositableEther.value(_amount)()`.  Callers
must supply a `stakingRouterAddr : Nat` and a
`selectorPrefix : Nat` (bytes4(keccak256("receiveDepositableEther()")))
plus the `amount : Word` already consumed by the parent, and the
bridge names the expected payable-CALL frame at the pinned call site
as
`ReservePayableCallSource.receiveDepositableEtherFrame stakingRouterAddr amount.toNat selectorPrefix`.

Discloses the Grok #419 D-TRANSFER-1 divergence at the parent's
ENUNCE level: `modelWithdrawDepositableEther` updates reserve words
only; the Verity plane's journal does NOT contain the payable CALL
that pinned Solidity emits after the spend writes at line 885.  The
bridge NAMES the pinned CALL frame (target = StakingRouter proxy,
value = _amount, selector = 4-byte
`bytes4(keccak256("receiveDepositableEther()"))`, empty calldata
tail) as a source-level `PayableCallFrame`; downstream consumers of
the Verity Reserve journal can compare their frame against the
named pinned shape.

**This is a NAMING composition, not a full closure of D-TRANSFER-1.**
The Verity model's actual `withdrawWithGuards` journal still omits
the payable CALL; disclosing the pinned frame's shape via the ENUNCE
records what the executable-plane extension will have to journal
when the model is extended.  The `withdrawalPartitionSpendInvariant`
+ `liveEffectiveWithdrawalsReserve` conclusions of the registered
parent are unchanged. -/
theorem source_spend_preserves_withdrawal_reserve_under_payable_call_shape
    (inputs : WithdrawInputs) (before after : ReserveState) (amount live : Word)
    (stakingRouterAddr selectorPrefix : Nat)
    (_hPinnedFrame :
      (LidoSRv3.Audit.Source.ReservePayableCallSource.receiveDepositableEtherFrame
        stakingRouterAddr (amount : Nat) selectorPrefix).target = stakingRouterAddr ∧
      (LidoSRv3.Audit.Source.ReservePayableCallSource.receiveDepositableEtherFrame
        stakingRouterAddr (amount : Nat) selectorPrefix).value = (amount : Nat) ∧
      (LidoSRv3.Audit.Source.ReservePayableCallSource.receiveDepositableEtherFrame
        stakingRouterAddr (amount : Nat) selectorPrefix).calldata = [])
    (hfresh : freshQueueCache before live)
    (h : modelWithdrawDepositableEther inputs before amount = .committed after) :
    scopedWithdrawGuards inputs ∧
      amount ≠ 0 ∧
      withdrawalPartitionSpendInvariant before after amount ∧
      liveEffectiveWithdrawalsReserve after live = liveEffectiveWithdrawalsReserve before live :=
  -- The pinned-frame premise names the pinned Solidity payable-CALL
  -- frame at `Lido.sol:885`; the proof delegates to the registered
  -- parent since the model's spend-word transition is unchanged —
  -- the ENUNCE now records the pinned CALL shape the model omits
  -- (D-TRANSFER-1 disclosure).
  source_spend_preserves_withdrawal_reserve inputs before after amount live hfresh h

/-- **Chantier 2 (Piste A, Thomas 2026-09-13) D-SEED-1 / D-EVENT-1
`_seedDepositsCount` bookkeeping + events naming bridge.**

Restates `source_spend_preserves_withdrawal_reserve` with an added
`_hSeedShape` premise NAMING the pinned Lido.sol:877-882
`_seedDepositsCount` bookkeeping and event-emission shape as a
source-level `SeedDepositsCountResult` via
`ReserveSeedBookkeepingSource.seedDepositsCount`.

Discloses the Grok #419 D-SEED-1 / D-EVENT-1 divergences at the
parent's ENUNCE level: the Verity model omits the
`_seedDepositsCount` bookkeeping (`depositedPostReport += _amount`
at Lido.sol:878, `_setBufferedEther(...sub(_amount))` at line 881)
and the paired `Unbuffered(_amount)` / `DepositedPostReportUpdated(newTotal)`
events.  The bridge NAMES the pinned bookkeeping+event tuple as a
`SeedDepositsCountResult` structure with the source-level equations
`newDepositedPostReport = currentDepositedPostReport + amount`,
`newBuffered = currentBuffered - amount`, and the two event frames.

**NAMING composition, not full closure of D-SEED-1 / D-EVENT-1.**
The registered `source_spend_preserves_withdrawal_reserve` is
retained unchanged; adding the seed-count bookkeeping writes and
event journal entries to the Verity `withdrawWithGuards` interpreter
is the follow-up.

Signature-level constraint: the caller supplies pinned current
values `currentDepositedPostReport, currentBuffered : Nat` and
receives a witness to the source-level result of applying the seed
bookkeeping.  The bridge does not require these to match `before` —
this is a naming disclosure, so the shape is the value proposition. -/
theorem source_spend_preserves_withdrawal_reserve_under_seed_bookkeeping_shape
    (inputs : WithdrawInputs) (before after : ReserveState) (amount live : Word)
    (currentDepositedPostReport currentBuffered : Nat)
    (_hSeedShape :
      (LidoSRv3.Audit.Source.ReserveSeedBookkeepingSource.seedDepositsCount
        currentDepositedPostReport currentBuffered (amount : Nat)).newDepositedPostReport =
        currentDepositedPostReport + (amount : Nat) ∧
      (LidoSRv3.Audit.Source.ReserveSeedBookkeepingSource.seedDepositsCount
        currentDepositedPostReport currentBuffered (amount : Nat)).newBuffered =
        currentBuffered - (amount : Nat) ∧
      (LidoSRv3.Audit.Source.ReserveSeedBookkeepingSource.seedDepositsCount
        currentDepositedPostReport currentBuffered (amount : Nat)).events.1.amount =
        (amount : Nat) ∧
      (LidoSRv3.Audit.Source.ReserveSeedBookkeepingSource.seedDepositsCount
        currentDepositedPostReport currentBuffered (amount : Nat)).events.2.newTotal =
        currentDepositedPostReport + (amount : Nat))
    (hfresh : freshQueueCache before live)
    (h : modelWithdrawDepositableEther inputs before amount = .committed after) :
    scopedWithdrawGuards inputs ∧
      amount ≠ 0 ∧
      withdrawalPartitionSpendInvariant before after amount ∧
      liveEffectiveWithdrawalsReserve after live = liveEffectiveWithdrawalsReserve before live :=
  -- The seed-bookkeeping premise names the pinned Lido.sol:877-882
  -- `_seedDepositsCount` writes and the paired Unbuffered/DepositedPostReportUpdated
  -- events as a source-level tuple; the proof delegates to the
  -- registered parent since the model's spend-word transition is
  -- unchanged — the ENUNCE records the pinned bookkeeping+event
  -- shape the model currently omits (D-SEED-1 / D-EVENT-1
  -- disclosure).
  source_spend_preserves_withdrawal_reserve inputs before after amount live hfresh h

/-- **Chantier 2 (Piste A, Thomas 2026-09-13) D-SLOT-1 ERC-7201 slot
provenance naming bridge.**

Restates `source_spend_preserves_withdrawal_reserve` with added
`_hSlotProvenance` premises NAMING the pinned Lido ERC-7201-style
keccak-derived storage positions for the reserve-partition slots.
The Verity plane uses model-local flat slots 0-4
(`ReserveContract.buffered.slot = 0`,
`ReserveContract.storedDepositsReserve.slot = 1`,
`ReserveContract.unfinalizedStETH.slot = 2`,
`ReserveContract.depositedPostReport.slot = 3`,
`ReserveContract.depositedNextReportAdjusted.slot = 4`); the pinned
deployment uses keccak-derived unstructured storage positions
(`BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION`,
`DEPOSITS_RESERVE_POSITION`, ...).  This bridge NAMES the pinned
ERC-7201-style derivation via `ERC7201StorageSlotSource.realERC7201BaseSlot`
on a shared `KeccakOracle`, so the ENUNCE records the pinned slot
provenance the model's local slots stand in for.

**NAMING composition, not full closure of D-SLOT-1.**  The Verity
model still writes to slots 0-4; extending the model to observe the
keccak-derived positions (or proving a bijection between the
model's local slot indexing and the deployed layout) is the next
follow-up.  Discloses Grok #419 D-SLOT-1 at the parent's ENUNCE
level. -/
theorem source_spend_preserves_withdrawal_reserve_under_erc7201_slot_shape
    (inputs : WithdrawInputs) (before after : ReserveState) (amount live : Word)
    (oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle)
    (_hSlotProvenance :
      -- The pinned keccak-derived slot for each reserve-partition namespace
      -- is a deterministic function of the shared KeccakOracle.
      (∀ ns1 ns2, ns1 = ns2 →
        LidoSRv3.Audit.Source.ERC7201StorageSlotSource.realERC7201BaseSlot oracle ns1 =
          LidoSRv3.Audit.Source.ERC7201StorageSlotSource.realERC7201BaseSlot oracle ns2))
    (hfresh : freshQueueCache before live)
    (h : modelWithdrawDepositableEther inputs before amount = .committed after) :
    scopedWithdrawGuards inputs ∧
      amount ≠ 0 ∧
      withdrawalPartitionSpendInvariant before after amount ∧
      liveEffectiveWithdrawalsReserve after live = liveEffectiveWithdrawalsReserve before live :=
  -- The slot-provenance premise names the pinned ERC-7201-style
  -- keccak-derived slot derivation as a function of the shared
  -- KeccakOracle.  The proof delegates to the registered parent
  -- since the model's local slot indexing is unchanged — the ENUNCE
  -- records the pinned slot-derivation shape the model's flat slots
  -- 0-4 stand in for (D-SLOT-1 disclosure).
  source_spend_preserves_withdrawal_reserve inputs before after amount live hfresh h

/-- **Chantier 2 (Piste A, Thomas 2026-09-13) D-WRAP-1 uint128 wrap
naming bridge.**

Restates `source_spend_preserves_withdrawal_reserve` with added
`_hWrapShape` premises NAMING the pinned Solidity uint128 wrap
semantics via `SolidityUint128WrapSource.toUint128` and
`wrappedAdd`.  The Verity model's allocation helper uses `safeSub`
and returns `ALLOCATION_ARITHMETIC` on overflow; the pinned 0.4.24
helper does raw `remaining -=` (unchecked wrap).  On the packed
uint128 pair `buffered` / `depositedPostReport` at Lido.sol:131-132,
each half wraps mod 2^128 — the model treats them as unbounded
`Nat` accumulators.

This bridge NAMES the pinned uint128 wrap semantics at the parent's
ENUNCE via three `SolidityUint128WrapSource` equations:
- `toUint128 x = x % 2^128` (truncation to uint128).
- `wrappedAdd a b = (a + b) % 2^128` (modular addition).
- `toUint128_lt_modulus`: the truncated value is strictly less than
  `2^128`.

**NAMING composition, not full closure of D-WRAP-1.**  The Verity
model still uses `safeSub` in the allocation helper; extending to
model the unchecked wrap is the follow-up.  The min-bound
premises make the divergence unreachable on the grok #419 harness
witness vectors, but the ENUNCE now names the pinned wrap semantics
explicitly. -/
theorem source_spend_preserves_withdrawal_reserve_under_uint128_wrap_shape
    (inputs : WithdrawInputs) (before after : ReserveState) (amount live : Word)
    (x : Nat)
    (_hWrapShape :
      -- The pinned uint128 wrap semantics: truncation, modular
      -- addition, and boundedness of the truncated value.
      LidoSRv3.Audit.Source.SolidityUint128WrapSource.toUint128 x =
        x % LidoSRv3.Audit.Source.SolidityUint128WrapSource.uint128Modulus ∧
      (∀ a b, LidoSRv3.Audit.Source.SolidityUint128WrapSource.wrappedAdd a b =
        (a + b) % LidoSRv3.Audit.Source.SolidityUint128WrapSource.uint128Modulus) ∧
      LidoSRv3.Audit.Source.SolidityUint128WrapSource.toUint128 x <
        LidoSRv3.Audit.Source.SolidityUint128WrapSource.uint128Modulus)
    (hfresh : freshQueueCache before live)
    (h : modelWithdrawDepositableEther inputs before amount = .committed after) :
    scopedWithdrawGuards inputs ∧
      amount ≠ 0 ∧
      withdrawalPartitionSpendInvariant before after amount ∧
      liveEffectiveWithdrawalsReserve after live = liveEffectiveWithdrawalsReserve before live :=
  -- The wrap-shape premise names the pinned Solidity uint128 wrap
  -- semantics (truncation, modular addition, boundedness) that the
  -- Verity model's `safeSub` / unbounded-Nat arithmetic replaces
  -- with checked bounds.  The proof delegates to the registered
  -- parent since the model's arithmetic transition is unchanged —
  -- the ENUNCE records the pinned wrap semantics the model treats
  -- as unbounded Nat (D-WRAP-1 disclosure).
  source_spend_preserves_withdrawal_reserve inputs before after amount live hfresh h

/--
**P-RESERVE-1, Verity plane.** The executable `withdrawWithGuards` observes the
abstract reserve transaction `specTx`, and every revert restores the pre-call
snapshot.

Faithful VERITY_TX closure for P-RESERVE-1. This theorem starts with the actual
`Verity.Contract.run` result of the source-shaped reserve spend and proves that
its committed/reverted observable transition is the abstract reserve
transaction. In particular, every `safeAdd`/`safeSub` failure and
`NOT_ENOUGH_ETHER` branch observes Verity's pre-call rollback state.

This is not an EVM theorem: storage-slot numbers are a model-local projection,
and no Solidity compiler, Yul, runtime bytecode, proxy layout, deployed code,
or external-call semantics is claimed.
-/
theorem verity_tx_simulates_reserve_spec (inputs : WithdrawInputs)
    (state : ContractState) (amount : Word) :
    observeVerity state ((ReserveContract.withdrawWithGuards inputs amount).run state) =
      specTx inputs (decode state) amount ∧
    ∀ reason rollback,
      (ReserveContract.withdrawWithGuards inputs amount).run state = .revert reason rollback →
      rollback = state :=
  ⟨verity_execution_simulates_spec state amount inputs,
    fun reason rollback h =>
      verity_revert_rolls_back inputs state amount reason rollback h⟩

/-- On a committing executable Verity transition, the prohibited reserve state
is observationally unchanged. -/
theorem verity_tx_preserves_withdrawal_reserve
    (inputs : WithdrawInputs) (state after : ContractState) (amount : Word)
    (h : (ReserveContract.withdrawWithGuards inputs amount).run state = .success () after) :
    withdrawalPartitionSpendInvariant (decode state) (decode after) amount :=
  verity_commit_preserves_withdrawal_reserve inputs state after amount h

/-- **Chantier 2 (Piste A, Thomas 2026-09-13) D-PACK-1 registered
consumer of the pinned uint128 packed pair round-trip.**

The pinned `Lido.sol:131-132` packs `buffered` (low 128 bits) and
`depositedPostReport` (high 128 bits) into a single `uint256` storage
slot.  Reading `buffered` from that packed slot requires the low-half
extraction `packedWord & type(uint128).max`; the source-level function
is `LidoSRv3.Audit.Source.ReservePackedBufferSource.unpackBuffered`.

`unpackBuffered_of_packPair_of_bounded` (in the source module) proves
the pack/unpack round-trip: under the pinned `buffered ≤ uint128Max`
type-width premise on `buffered : uint128`, the low-half extraction
of `packPair buffered depositedPostReport` recovers `buffered`.

This registered consumer theorem carries the round-trip fact into the
P-RESERVE-1 namespace, so any downstream consumer that receives a
`packedWord` and a bounded `buffered` witness gets the projection
identity as a proved P-RESERVE-1 lemma.  This is not a naming scaffold:
the proof invokes the round-trip theorem non-trivially (it is not a
`rfl` — the modular arithmetic on `+` and `*` inside `packPair` needs
the boundedness premise to eliminate the low-half mod, which the source
module discharges via `Nat.add_mul_mod_self_right` + `Nat.mod_eq_of_lt`). -/
theorem reserve_buffered_matches_packed_low_half
    (buffered depositedPostReport : Nat)
    (hLow : buffered ≤ LidoSRv3.Audit.Source.ReservePackedBufferSource.uint128Max) :
    LidoSRv3.Audit.Source.ReservePackedBufferSource.unpackBuffered
        (LidoSRv3.Audit.Source.ReservePackedBufferSource.packPair
          buffered depositedPostReport) = buffered :=
  LidoSRv3.Audit.Source.ReservePackedBufferSource.unpackBuffered_of_packPair_of_bounded
    hLow

/-- **Chantier 2 (Piste A, Thomas 2026-09-13) D-SEED-1/D-EVENT-1
registered consumer of the pinned `_seedDepositsCount` bookkeeping.**

The pinned `Lido.sol:877-882` `_seedDepositsCount(_amount)` performs
`depositedPostReport += _amount` and `buffered -= _amount`, then emits
`Unbuffered(_amount)` and `DepositedPostReportUpdated(newTotal)`.
`ReserveSeedBookkeepingSource.seedDepositsCount` captures the two
writes and the paired events as a source-level function.

`seedDepositsCount_depositedPostReport_eq` and `_buffered_eq` in the
source module prove the arithmetic identities; this registered
consumer re-exports them into the P-RESERVE-1 namespace as a single
pair, so downstream consumers get the seed-bookkeeping identity as
proved P-RESERVE-1 lemmas without pulling in the source-module import
directly. -/
theorem reserve_seed_bookkeeping_identities
    (currentDepositedPostReport currentBuffered amount : Nat) :
    (LidoSRv3.Audit.Source.ReserveSeedBookkeepingSource.seedDepositsCount
      currentDepositedPostReport currentBuffered amount).newDepositedPostReport =
        currentDepositedPostReport + amount ∧
    (LidoSRv3.Audit.Source.ReserveSeedBookkeepingSource.seedDepositsCount
      currentDepositedPostReport currentBuffered amount).newBuffered =
        currentBuffered - amount :=
  ⟨LidoSRv3.Audit.Source.ReserveSeedBookkeepingSource.seedDepositsCount_depositedPostReport_eq
      currentDepositedPostReport currentBuffered amount,
   LidoSRv3.Audit.Source.ReserveSeedBookkeepingSource.seedDepositsCount_buffered_eq
      currentDepositedPostReport currentBuffered amount⟩

/-- Registered consumers for the payable transfer, uint128 wrapping, and
ERC-7201 slot-determinism source facts (PR #671). -/
theorem reserve_payable_call_frame_projections
    (stakingRouterAddr amount selectorPrefix : Nat) :
    (LidoSRv3.Audit.Source.ReservePayableCallSource.receiveDepositableEtherFrame
        stakingRouterAddr amount selectorPrefix).target = stakingRouterAddr ∧
    (LidoSRv3.Audit.Source.ReservePayableCallSource.receiveDepositableEtherFrame
        stakingRouterAddr amount selectorPrefix).value = amount ∧
    (LidoSRv3.Audit.Source.ReservePayableCallSource.receiveDepositableEtherFrame
        stakingRouterAddr amount selectorPrefix).calldata = [] :=
  ⟨LidoSRv3.Audit.Source.ReservePayableCallSource.receiveDepositableEtherFrame_target_eq
      stakingRouterAddr amount selectorPrefix,
   LidoSRv3.Audit.Source.ReservePayableCallSource.receiveDepositableEtherFrame_value_eq
      stakingRouterAddr amount selectorPrefix,
   LidoSRv3.Audit.Source.ReservePayableCallSource.receiveDepositableEtherFrame_calldata_eq
      stakingRouterAddr amount selectorPrefix⟩

theorem reserve_uint128_wrap_identities
    (x a b : Nat)
    (hSum : a + b < LidoSRv3.Audit.Source.SolidityUint128WrapSource.uint128Modulus) :
    LidoSRv3.Audit.Source.SolidityUint128WrapSource.toUint128
        (LidoSRv3.Audit.Source.SolidityUint128WrapSource.toUint128 x) =
      LidoSRv3.Audit.Source.SolidityUint128WrapSource.toUint128 x ∧
    LidoSRv3.Audit.Source.SolidityUint128WrapSource.checkedAddOverflow a b = false :=
  ⟨LidoSRv3.Audit.Source.SolidityUint128WrapSource.toUint128_idem x,
   LidoSRv3.Audit.Source.SolidityUint128WrapSource.checkedAddOverflow_false_of_bounded hSum⟩

theorem reserve_erc7201_slot_deterministic
    (oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle)
    (ns1 ns2 : String) (h : ns1 = ns2) :
    LidoSRv3.Audit.Source.ERC7201StorageSlotSource.realERC7201BaseSlot oracle ns1 =
      LidoSRv3.Audit.Source.ERC7201StorageSlotSource.realERC7201BaseSlot oracle ns2 :=
  LidoSRv3.Audit.Source.ERC7201StorageSlotSource.realERC7201BaseSlot_deterministic
    (oracle := oracle) (ns1 := ns1) (ns2 := ns2) h

end LidoSRv3.Audit.Guarantees.PReserve1
