# Verity Targets

The executable SRv3 model lives in `LidoSRv3/` as Lean files checked through the
pinned Verity dependency in `lakefile.lean`.

The model covers:

- `StakingRouter.deposit`
- deposit reserve and withdrawal reserve separation
- module balances and `validatorsBalanceGwei`
- accepted balance reports
- `reportRewardsMinted`
- active, deposits-paused, and stopped status gating
- Wei/Gwei and basis-point integer rounding

The external Verity reference is pinned in `proofs/LOCKFILE.md` and
`lake-manifest.json`.

Run:

```sh
make test
make prove
```
