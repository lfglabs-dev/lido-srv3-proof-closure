# Verity Model

`verity/src/verity_srv3/` contains a deterministic, standard-library Python
translation of the SRv3 economic state machine used by this repository's
executable proof checks.

The model covers:

- `StakingRouter.deposit`
- deposit reserve and withdrawal reserve separation
- module balances and `validatorsBalanceGwei`
- accepted balance reports
- `reportRewardsMinted`
- active, deposits-paused, and stopped status gating
- Wei/Gwei and basis-point integer rounding

The external Verity reference is pinned in `proofs/LOCKFILE.md`; this repository
does not require a Verity binary to run the local evidence commands.

Run:

```sh
make test
make prove
```
