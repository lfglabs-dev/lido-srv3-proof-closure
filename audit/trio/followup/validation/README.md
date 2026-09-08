# Follow-up validation

All commands in receipt.json executed against source commit `c88f88733a54bdf1ce1a24089ca43e06f526df2e` and exited zero. The integration commit records the original PR250 and accounting/address branch histories; its tracked tree was compared with the validated source and is identical. This archive commit adds evidence only, not a claim that the archive itself was the compilation input.

Validation ran locally on macOS with the pinned Lean toolchain, Python 3.12 and Foundry. No fresh independent reviewer is claimed. The full test command includes executed pinned-Solidity/model comparisons and four cache-leaf mutation compilations; those tests do not establish complete source or compiler correspondence.
