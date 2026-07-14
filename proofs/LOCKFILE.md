# Proof Lockfile

This repository pins the source and modeling references used by the executable
SRv3 proof-closure artifacts.

| Component | Reference |
| --- | --- |
| Lido PR #1811 | `af095e48bbc1c3841c2c9936219c8461af01056b` |
| Verity | `33722270d996c7a3a520a71ecee42d7d232da100` |

The executable harness in this repository is a Lean/Lake project that imports
Verity at the pinned commit above and checks the SRv3 model under `LidoSRv3/`.
