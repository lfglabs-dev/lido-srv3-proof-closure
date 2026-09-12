# P-DEPOSIT-1 — LinksSource derived from the pinned router

## CLAIM

- **Guarantee:** `P-DEPOSIT-1`
- **fidelity.missing entry:** `LinksSource is a caller-supplied hypothesis: Wave 4 kill-line alloc_derived_linkssource_kill_line_refutes_bridge shows P-ALLOC-1 CheckedBounds and P-ALLOC-2 step premises plus key-count composition still do not imply LinksSource, because ALLOC does not constrain per-batch wei (firstAmount) and does not constrain publicKeysBatchLength`
- **Branch:** `grok/lido-deposit-linkssource-20260912`
- **Base:** `origin/main` @ `0debc40f5f7b1a1b687782710484397eaa7f781b`
- **Pinned Solidity:** `17005714f151e5502c559932319a3f2f74ac2436`
- **Claimed by:** grok cloud agent, 2026-09-12
- **Status:** closed on this consumer — Spark raccord pending

This lot does **not** claim the closed ACCOUNT / ADDRESS / RESERVE fidelity
entries (PRs #402, #403, #404). Spark `lido-deposit-*-registration` branches
register existing DEPOSIT consumers; they do not close this LinksSource
hypothesis.

## Targeted gap

Establish what the pinned router actually imposes on `firstAmount` and
`publicKeysBatchLength`, prove the derivable part, and honestly shrink the
remainder. Additive files only; no parent / yaml / Trust edits.

`NFrame.LinksSource` stays an explicit hypothesis on the registered parent.
The Spec router's per-allocation unit multiply stays explicit. ALLOC parents
are **not** used to manufacture the link.

## What the pinned router imposes

`StakingRouter.deposit` (`StakingRouter.sol:942-997`) is one module per
call. After `obtainDepositData` (`:962-963`):

| Field | Source | Constraint |
|---|---|---|
| `publicKeysBatchLength` | `:966` `WrongPubkeyLength` | `length % PUBKEY_LENGTH = 0` (`PUBKEY_LENGTH = 48` at `:57`) |
| key count | `:967` | `actualDepositsCount = length / PUBKEY_LENGTH` |
| same length | `BeaconChainDepositor.sol:43-45` | `length == PUBLIC_KEY_LENGTH * _keysCount` (`PUBLIC_KEY_LENGTH = 48` at `:21`); the router passes `_keysCount = actualDepositsCount` at `:985-991` |
| `firstAmount` (per-batch wei) | `BeaconChainDepositor.sol:53-63` / `:57` | each key sends `DEPOSIT_SIZE`; `loopPushed n = n * DEPOSIT_SIZE` |

ALLOC outputs validator counts. It never writes those two fields.

## What is proved

Additive files:

- `LidoSRv3/Audit/Source/DepositLinksSource.lean`
- `LidoSRv3/Tests/DepositLinksSourceMutants.lean`

| Theorem | Source span | Claim |
|---|---|---|
| `derivedKeys` | `:966-967` + BCD:43-45 | fail-closed key count from the returned byte length |
| `derivedKeys_misaligned` | `:966` | a non-multiple of 48 is `none`, not a truncated count |
| `derivedKeys_length_mismatch` | BCD:43-45 | `length ≠ PUBLIC_KEY_LENGTH * keys` is `none` |
| `committed_implies_derivedKeys` | `:980-996` | a committed push determines `publicKeysBatchLength` → keys |
| `derivedBatchAmount` / `routerShapedAmount` | BCD:53-63 / `:57` | per-batch wei is `loopPushed`, not a free `Nat` |
| `committed_pushed_is_derived_amount` | `:985-991` | committed `pushed` equals that loop total |
| `linksSource_of_router_fields` | two-batch parent | `LinksSource` follows from the two router fields |
| `nframe_linksSource_of_router_fields` | n-frame parent | same for `NFrame.LinksSource` |
| `derivedTwoBatchInputs_linksSource` | fail-closed constructor | overwrites wei with the loop product |
| `alloc_key_counts_do_not_constrain_firstAmount` | residual | keys `2,3` do not force wei `64` (`65 ≠ 2*32`) |
| `alloc_matching_count_does_not_constrain_publicKeysBatchLength` | residual | `241/48 = 5` matches ALLOC composition but fails `:966` |

Mutants: happy 240→5 / 64+96; `WrongPubkeyLength` 145; truncated 241; one-key 48 vs 2+3 split; free wei 65; constructor repairs skewed `(65,95)`; disagreed `PUBLIC_KEY_LENGTH`; zero `PUBKEY_LENGTH`; committed canonical run; n-frame two-leg lift.

Axioms: `propext` only (the ALLOC length residual is axiom-free). No `sorryAx`.

## Spark raccord (do not apply in this lot)

In `audit/guarantees.yaml` under `P-DEPOSIT-1`:

1. Remove this exact `fidelity.missing` string:
   ```
   - "LinksSource is a caller-supplied hypothesis: Wave 4 kill-line alloc_derived_linkssource_kill_line_refutes_bridge shows P-ALLOC-1 CheckedBounds and P-ALLOC-2 step premises plus key-count composition still do not imply LinksSource, because ALLOC does not constrain per-batch wei (firstAmount) and does not constrain publicKeysBatchLength"
   ```
2. Add a `fidelity.covered` bullet that `derivedKeys` / `derivedBatchAmount`
   obtain `publicKeysBatchLength` and per-batch wei from
   `StakingRouter.sol:966-967` and `BeaconChainDepositor.sol:43-45,53-63`,
   and that `linksSource_of_router_fields` / `nframe_linksSource_of_router_fields`
   cite `LinksSource` from those router fields. Keep NFrame.LinksSource
   explicit on the registered parent. Do not merge ALLOC into DEPOSIT.

## Honesty (not this entry)

- Wave 4 `alloc_derived_linkssource_kill_line_refutes_bridge` remains true:
  ALLOC still does not imply `LinksSource`. The two fields are router
  facts, not ALLOC facts.
- `NFrame.LinksSource` stays a caller hypothesis on the registered parent.
- The 2+3 key *split* is still caller-chosen (Verity two-batch aggregation
  of one `deposit()` call). Only the *sum* is derived from
  `publicKeysBatchLength`.
- `depositSize` is the configuration field. `A-DEPOSIT-32-ETHER` is already
  discharged from artifacts and is not re-proved here.
- Signature-batch length (`BCD:46-48`) is a sibling guard, not this entry.
- The remaining P-DEPOSIT-1 missing entries (unbounded-Nat word-domain
  gap; pull bound outside `ConservingConfig`; vacuous revert conjunct on
  the registered parent) are untouched.
