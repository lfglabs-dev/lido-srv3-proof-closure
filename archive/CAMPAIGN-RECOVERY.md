# Campaign-to-main recovery

`main` is the only active branch. History from
`campaign/lido-minimal-11@3f0d1c291a6b3e43e4255663d6a01f8b1016e65f` (PRs #9–#75)
is reachable because that commit is a merge parent.

Recovered files that still compile:

- `LidoSRv3/Audit/Source/AddressCorrespondence.lean`
- `LidoSRv3/Audit/Source/TopupParentCorrespondence.lean`
- `LidoSRv3/Audit/Verity/AddressTx.lean`
- `LidoSRv3/Audit/Verity/DepositLedgerTx.lean`
- `LidoSRv3/Audit/Verity/TopupPackedStorage.lean`
- `LidoSRv3/Audit/Verity/TopupParent.lean`
- their mutant suites
- the old seven-plane evidence index under `archive/campaign-evidence-index/`
- P-TOPUP-2 layout/runtime receipts and the Foundry harness

Verity pin: `1fe0218863a4c8d6113e6cdd4de3766a54df81c7`.

A merge is not a soundness proof. On claim files, keep the later `main`
correction. Recovered files do not promote a parent guarantee.

Active contract: a checked abstract Lean model, and a checked faithful Verity
model. Gaps are a missing Verity feature, a false property, an assumption, or
pending work. Yul/EVM/deployment are out of scope except the SSZ imported-Yul
binding.

New work targets `main`. `campaign/lido-minimal-11` is archival.
