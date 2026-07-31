# SRV3-P10 Reward-Minted Reporting

Source reference:

- `contracts/0.8.25/sr/SRLib.sol::_reportRewardsMinted`

Model artifact:

- `LidoSRv3/Legacy/Model.lean::RewardMintedReportRow`
- `LidoSRv3/Legacy/Model.lean::rewardMintedReportRows`
- `LidoSRv3/Legacy/Model.lean::rewardMintedRowsValid`
- `LidoSRv3/Legacy/Model.lean::reportRewardsMintedTransition`
- `LidoSRv3/Legacy/SpecProofs.lean::P10_report_rewards_minted_requires_equal_lengths`
- `LidoSRv3/Legacy/SpecProofs.lean::P10_report_rewards_minted_requires_valid_rows`
- `LidoSRv3/Legacy/SpecProofs.lean::P10_report_rewards_minted_nonzero_module_exists`
- `LidoSRv3/Legacy/SpecProofs.lean::P10_report_rewards_minted_zero_rows_skip_module_check`
- `LidoSRv3/Legacy/SpecProofs.lean::P10_report_rewards_minted_returns_generated_rows`
- `LidoSRv3/Legacy/SpecProofs.lean::P10_report_rewards_minted_preserves_row_length`
- `LidoSRv3/Legacy/SpecProofs.lean::P10_report_rewards_minted_preserves_module_ids`
- `LidoSRv3/Legacy/SpecProofs.lean::P10_report_rewards_minted_preserves_total_shares`

Math statement:

```text
successfulReportRewardsMinted(ids, shares, rows) => len(ids) == len(shares)
successfulReportRewardsMinted(ids, shares, rows) => validRewardMintedRows(rows)
successfulReportRewardsMinted(ids, shares, rows) => rows == zip(ids, shares)
successfulReportRewardsMinted(ids, shares, rows) => len(rows) == len(ids)
successfulReportRewardsMinted(ids, shares, rows) => map(row.moduleId, rows) == ids
successfulReportRewardsMinted(ids, shares, rows) => map(row.totalShares, rows) == shares
row in rows and row.totalShares != 0 => moduleExists(row.moduleId)
row.totalShares == 0 => the Solidity loop skips the module-existence check
```

Proof command:

```sh
lake build LidoSRv3
```

Result:

```text
SRV3-P10 Lean-checked, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-EXT-01`
- `A-MOD-13`
