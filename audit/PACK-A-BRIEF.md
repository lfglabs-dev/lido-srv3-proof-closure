# Pack A brief — Allocation Spec projections and LinksSource

One node, one PR. Not Best-of-N: ALLOC ↛ LinksSource is already proved, so
this node keeps the hypothesis and projects onto frozen Spec interfaces.
No new guarantee IDs.

## Frozen interfaces used

`Spec.Allocation` (`moduleId`, `capacity`, `amount`) from Wave 0.
`amount` and `capacity` are validator counts, not wei and not top-up gwei.

## Work

1. Unregistered P-ALLOC-1 child: successful `checked_execute` rows project to
   `Spec.Allocation` whose `capacity` column equals `MathView.capacities`.
2. Unregistered P-ALLOC-2 child: a successful proportional step projects to
   `Spec.Allocation` whose `amount` is the checked increment and respects
   remaining capacity. Router index stands in for `moduleId` because MinFirst
   rows are not module-id-keyed.
3. Named `LinksSource` child: `Spec.Allocation` validator amounts do not
   imply `LinksSource.firstAmount`. Keep the hyp. Do not merge ALLOC into
   DEPOSIT. Do not register a composition ID.
4. P-TOPUP-1 wrap and P-TOPUP-2 per-key stay on those parents. They are not
   stuffed into `Spec.Allocation.amount : Validators`.

## Kill-lines

- Mutant projection that reads `targetValidators` as `capacity` falsifies
  the ALLOC-1 Spec capacity correspondence on a `CheckedBounds` witness.
- Spec amounts equal to per-batch key counts still fail
  `LinksSource.firstAmount` (wei), so ALLOC ↛ LinksSource remains explicit.

## Out of scope

Composition ID, deposit/top-up ETH journal (Join), live wei conversion,
VaultHub, packs B–F.
