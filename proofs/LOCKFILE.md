# Proof Lockfile

This repository pins the source and modeling references used by the executable
SRv3 proof-closure artifacts.

| Component | Reference |
| --- | --- |
| Proof baseline (`origin/main`) | `7dedaf0d5fb4ce7c8734792d47dbf774ed570c0c` |
| Lido PR #1811 | `af095e48bbc1c3841c2c9936219c8461af01056b` |
| Verity | `bfa13e715d2a11d476e5d90f9264e87676ff7594` |
| Lean | `v4.31.0` |

The executable harness in this repository is a Lean/Lake project that imports
Verity at the pinned commit above and checks the SRv3 model under `LidoSRv3/`.

`LidoSRv3.Legacy.Model` and `LidoSRv3.Legacy.SpecProofs` are retained as legacy
pure-model regression evidence. New source-shaped claims live under
`LidoSRv3.Audit`; a proof in either layer is not by itself an end-to-end
correspondence proof for deployed Solidity.
