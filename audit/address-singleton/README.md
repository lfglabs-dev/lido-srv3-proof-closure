# P-ADDRESS-1 — live singleton-actor exclusion

## CLAIM

- **Guarantee:** `P-ADDRESS-1`
- **fidelity.missing entry:** `singleton-actor exclusion is by omission: singletonActorEntryPoint is False for every modeled tag, so the parent carries no live exclusion proof`
- **Branch:** `grok/lido-address-singleton-20260912`
- **Base:** `origin/main` @ `0debc40f5f7b1a1b687782710484397eaa7f781b`
- **Pinned Solidity:** `17005714f151e5502c559932319a3f2f74ac2436`
- **Claimed by:** grok cloud agent, 2026-09-12
- **Status:** closed on this consumer — Spark raccord pending

This lot does **not** claim the ACCOUNT fee-computation entry (PR #402) and
does **not** claim Trust registration of existing ADDRESS consumers
(`spark/lido-address-*-registration-20260911`).

## Targeted gap

Parent `singletonActorEntryPoint` is definitionally `False` for every
`EntryPoint` (`AddressCorrespondence.lean:110-111`). That excludes
singleton-actor writers by omission. This lot adds a **live** exclusion
beside the parent: for each modeled tag, no fixed owner/admin is required
of every admitted call. There is no pinned-Solidity counterexample on the
four modeled writers.

The parent `singletonActorEntryPoint`, `universal_address_writer_equivariance`,
and `guarantees.yaml` are not edited.

## What is proved

Additive files:

- `LidoSRv3/Audit/Source/AddressSingleton.lean`
- `LidoSRv3/Tests/AddressSingletonMutants.lean`

`requiresFixedActor ep` holds iff some **fixed** address is the caller of
every admitted run of `ep`. Request-relative gates (`caller = requestOwner`)
do not satisfy this.

| Theorem | Source span | Claim |
|---|---|---|
| `requestWithdrawals_admitted` | WithdrawalQueue.sol:125-136 | any caller, `_checkResumed` only |
| `unwrap_admitted` | WstETH.sol:69-75 | any caller with nonzero amount/balance |
| `claimWithdrawalsTo_admitted` | WithdrawalQueue.sol:244-256 / Base.sol:467 | per-request owner, not a protocol admin |
| `transferFrom_admitted` | WithdrawalQueueERC721.sol:218-220 / 241-245 | owner-operated or approved caller |
| `no_fixed_actor` | all four tags | `¬ requiresFixedActor ep` |
| `fixed_owner_mutant_requires_actor` | mutant `caller = 7` | live predicate is not another `False` |
| `parent_omission_is_definitional` | AddressCorrespondence:110-111 | parent predicate stays omitted `False` |

Mutants: callers `1` and `2` are admitted on every honest tag; the
`caller = 7` mutant admits 7 and rejects 1 on `requestWithdrawals`.

Axioms of every export: `propext` only (or none). No `sorryAx`.

## Spark raccord (do not apply in this lot)

In `audit/guarantees.yaml` under `P-ADDRESS-1`:

1. Remove this exact `fidelity.missing` string:
   ```
   - "singleton-actor exclusion is by omission: singletonActorEntryPoint is False for every modeled tag, so the parent carries no live exclusion proof"
   ```
2. Add a `fidelity.covered` bullet that `no_fixed_actor` proves each modeled
   writer admits distinct callers, so no fixed owner/admin is required.

## Honesty (not this entry)

Unmodeled singleton-actor surfaces remain outside the four tags:
`WithdrawalQueue.sol:97` `RESUME_ROLE`, `322` `ORACLE_ROLE`, and the
vault/gateway helpers named in `PAddress1` (`withdrawWithdrawals`,
`addWithdrawalRequests`, `addConsolidationRequests`). This lot does not
widen the parent to those functions and does not call all four writers
permissionless (`transferFrom` / `claimWithdrawalsTo` stay request-relative).
