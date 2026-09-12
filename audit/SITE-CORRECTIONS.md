# Site corrections for lfg_marketing #426 (chantier 8, mandate 2026-09-12)

This file lists the cards to correct before publishing lfg_marketing
#426. **Do not modify the site.** This audit-side record is the
authoritative pre-publication punch list; the site edits are handled
in the marketing repo.

Each card below identifies the misleading claim, the honest reading
under the post-chantier registered parents / disclosures, and the
exact registered artifact (theorem name or `fidelity.missing` entry)
the site copy must reflect.

## RESERVE-1 — single writer of the four in the partition

**Misleading claim on site:** framed as if the P-RESERVE-1 registered
parent covers ALL four writers in the ETH-reserve balance partition
(module deposits, top-up pull, consolidation vault credit, refund).

**Honest reading:** the registered parent
`LidoSRv3.Audit.Guarantees.PReserve1.source_spend_preserves_withdrawal_reserve`
covers ONE writer — the top-up spend path. The three other writers
in the partition are not composed into the parent; each is either an
open sub-obligation or a subordinate row.

Additional signal chantier 1 (mandate 2026-09-12) reinstated as
`fidelity.missing`:

> live `WithdrawalQueue.unfinalizedStETH()` STATICCALL —
> `LidoSRv3/Audit/Source/ReserveUnfinalizedCall.lean` is a consumer
> that derives `freshQueueCache` from a live STATICCALL, but the
> registered parent still takes `freshQueueCache` as a hypothesis.
> RECLASSED not discharged (PR #408 was a rename, not a change to
> the parent's ENUNCE).

**Site fix:** narrow the RESERVE-1 card to name exactly the one
writer covered, list the other three as open, and reference
`audit/guarantees.yaml` P-RESERVE-1 `fidelity.missing` for the
13 disclosed gaps (was 12 before chantier 1's reinstatement).

## TOPUP-1 — Verity plane ENUNCE promises match the code (chantier 2)

**Misleading claim on site (pre-chantier 2):** the Verity parent
`verity_tx_simulates_source_with_nonzero_wrap_close` was described as
delivering the wrap-close and pulled=pushed correspondence its NAME
promised, but its previous ENUNCE returned only `hCall` plus a
five-tuple of `executeGuarded` frame lemmas.

**Honest reading (post-chantier 2, mandate 2026-09-12):** the
registered Verity parent now returns a **four-conjunct** proposition
that actually delivers what the name promises:

1. `SourceTopupCallCorresponds cfg inp call`.
2. `VerityGuardedReturndataSimulation cfg call state` (five
   `executeGuarded` frame lemmas).
3. `NonzeroWrapRevertsAndRestores state` — universal nonzero-wrap
   close on the LEGACY `Verity.TopupTx.execute` plane.
4. Curried
   `hLen → hAmt → hCommit → VerityCommittingSimulation cfg inp state`
   — pulled=pushed / observation-equality / rollback correspondence
   on the LEGACY plane.

**Also disclosed (chantier 2 `fidelity.missing`):**

- `lidoPull` at `LidoSRv3/Audit/Verity/TopupTx.lean:119-122` journals
  a single-word argument `[total]` via `externalCallBindTo lidoAddress
  0 [] "withdrawDepositableEther" [(total : Uint256)]`; the pinned
  source at `StakingRouter.sol:744` calls
  `LIDO.withdrawDepositableEther(amount, 0)` with two arguments. The
  executable frame is single-argument.
- Conjuncts 3–4 are proved on the legacy `execute` plane, not on
  `executeGuarded`; the guarded-plane analogue is open.

**Site fix:** update the TOPUP-1 card to describe the four-conjunct
Verity parent honestly, and disclose the two-argument `lidoPull`
divergence + the legacy-plane-vs-guarded-plane scope narrowing.

## TOPUP-2 — narrowing signal is 'exact under gateway-shape premise, wrapped otherwise' (chantier 4bis)

**Misleading claim on site (pre-chantier 4):** the P-TOPUP-2
registered abstract parent was framed as an unconditional block-cap
bound `(transition b cfg).sum ≤ cfg.maxTopUpPerBlockGwei`.

**Honest reading (post-chantier 4bis, Thomas 2026-09-12):** two
successive corrections apply.

- Chantier 4 (mandate 2026-09-12) changed the registered abstract
  parent from `aggregate_bounded_by_block_cap` (a fact about
  `consumeBudget`, a leftover-budget walk `StakingRouter.topUp` does
  not execute; also carried a sourceless `valueWei/GWEI` term
  because `topUp` is not payable) to `router_source_cap_within_block_cap`,
  which bounds the WRAPPED accumulator (`allocSumUnchecked`, mod
  2^256) under the router's aggregate guard at `StakingRouter.sol:737`.
- Chantier 4bis (Thomas 2026-09-12) further strengthened the parent
  to `router_exact_sum_bounded_under_gateway_shape`, which proves the
  EXACT-sum bound under the `GatewayShapedInput` premise (the two
  bounds the pinned `TopUpGateway.sol:226` construction enforces:
  `allocations.length ≤ uint64Max`; each `a ≤ uint64Max * GWEI`).

**Narrowing signal: 'exact under gateway-shape premise, wrapped
otherwise'.** Under any non-gateway caller the wrapped-sum bound is
the honest statement; under the pinned gateway construction, wrap is
unreachable and the exact sum is bounded.

**Residual (`fidelity.missing`):** the `GatewayShapedInput` premise
assumes the caller matches the pinned `TopUpGateway`. Under
`StakingRouter.topUp:686` (`_checkAppAuth(_getTopUpGateway())`), the
top-up gateway is the only admitted caller today — but composing the
router's caller-admission chain into the parent's statement is the
remaining follow-up.

**Site fix:** update the TOPUP-2 card to reflect the exact-sum bound
under gateway-shape premise; do NOT describe it as unconditional; do
NOT reference `consumeBudget` or `transitionBudget`; do NOT reference
`valueWei / GWEI` (topUp is not payable).

## SSZ-1 — Verity parent is the compiled `_verifyValidator` (chantier 3)

**Misleading claim on site (pre-chantier 3):** the P-SSZ-1 registered
Verity parent was `verity_tx_simulates_ssz_encoding`, which operates
on a **dummy validator at gindex 2 with an injective `Nat.pair`
combine** — an object `CLValidatorVerifier._verifyValidator` never
checks.

**Honest reading (post-chantier 3, mandate 2026-09-12):** the
registered Verity parent is now
`LidoSRv3.Audit.Guarantees.PSsz1.actual_compiled_cl_entry_complete_declared_branch`
at `LidoSRv3/Audit/Guarantees/PSsz1DeclaredSiblings.lean:10-83`, which
runs the **compiled harness of `_verifyValidator` (selector
`0x2e77b4ba`)** and yields, on a successful whole-entry run plus the
inherited `SszProofCommitted.ShaWidth` side condition:

- calldata-decoded slot / proposer at words 36 / 68;
- one BEACON_ROOTS STATICCALL with reply-guard on `external` and
  `world.core.codeSize`;
- typed `sourceWrapper` generalized index (word 132);
- `_validatorHashTreeRoot` layout at pinned offsets (48-byte key
  octets; `FieldsMatch` decoding; credential from word 164);
- independent Merkle branch fold `Fold.Branch (SszProofCalldataStep
  .ffiPair)` from `validatorLeaf` to the returned `firstWord`;
- complete ABI-declared sibling sequence (`declaredWords =
  proofWords`; length = declared branch length = `log2 gindex`; `3 ≤
  length ≤ 247`; penultimate = paired slot/proposer chunk digest);
- typed-digest branch equivalence via `treeDigest`, `validatorTree`,
  `SszTypedFfiBridge.branch_transport`.

The demoted `verity_tx_simulates_ssz_encoding` is preserved as the
subordinate row `P-SSZ-1.encoding-simulation` — regression evidence
only; **must not be re-promoted**.

**Also disclosed (chantier 3 `fidelity.missing`):**

- Demoted parent's dummy-validator-at-gindex-2 status.
- `ShaWidth` is an inherited output-width side condition on opaque
  `Compiler.Sha256.Engine.sha256`; SHA-256 functional correctness
  stays `A-SHA256-FFI`.
- EIP-4788 history-ring authenticity is not represented; BEACON_ROOTS
  callee is `StaticCall.External` on typed `Live.World`.
- Also named in `fidelity.missing`: `SSZ.verifyProof` on production
  gindices, `_validatorHashTreeRoot` layout, EIP-4788, SHA-256 all
  remain distinct open items — the compiled-entry parent covers the
  layout on the pinned calldata offsets, not the general
  `verifyProof` surface.

**Site fix:** update the SSZ-1 card to name the compiled `_verifyValidator`
parent, describe the six-fact conjunct explicitly, list the four
distinct named-open items (verifyProof on production gindices,
`_validatorHashTreeRoot` layout distinct from calldata offsets,
EIP-4788, SHA-256), and DO NOT describe the dummy-validator model as
the registered parent.

## Global signals

- **Fidelity total:** 102 open (was 78 pre-mandate; each chantier
  disclosure added honestly-named gaps; no assumption was silently
  retired).
- **Trust axiom envelope:** unchanged at 36 (30 test/mutant-only
  native-decision axioms + 3 production exceptions + foundations).
- **Registered CHECKED semantics on the site:** must be described as
  "the named Lean theorem is buildable on the pinned model plane"
  and not as "audited, verified on chain, or closed". README carries
  this qualification; the site cards must not soften it.

## Reference

- Mandate: `~/work/goals/lido-mandate-20260912.md`.
- Chantier 1 correction receipt:
  `audit/findings/CORRECTION-2026-09-12-reclassings.md`.
- All chantier PRs (this repo, `main` branch history):
  #427 (chantier 1), #428 (chantier 2), #429 (chantier 3),
  #430 (chantier 4, narrowing), #431 (chantier 5), #432 (chantier 6),
  #433 (chantier 7), #434 (chantier 4bis, exact-sum composition).
- Post-mandate general-rule follow-up (Thomas 2026-09-12): apply the
  same real-form-premise composition pattern to the six identified
  candidates (RESERVE-1 `canDeposit`/`authorizedRouter`; DEPOSIT-1
  LinksSource `firstAmount`/`publicKeysBatchLength`; TOPUP-1
  boolean guards; ADDRESS-1 `externalCallSucceeds`; ALLOC-1
  `CheckedBounds`; CONSOLIDATION-ETH-1 fee STATICCALL / batchSize).
  Goal never ends as long as any such free boolean or free input
  remains in a registered parent.
