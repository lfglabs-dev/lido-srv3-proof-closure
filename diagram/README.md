# Lido SRv3 architecture diagram

Interactive component map of the Lido protocol at `lidofinance/core@af095e48`
(SRv3, PR #1811): contracts with source files and mainnet addresses, off-chain
actors, and seven toggleable protocol flows with the actual function calls as
edge labels.

## Usage

Open `index.html` in a browser (no build step, no dependencies, works offline).

- Toggle flow pills (F1 to F7) to highlight a flow's path; combine several to compare.
- Hover a node for the full address and role.
- **export PNG / export SVG** downloads the current view, including whichever
  flows are toggled, as a standalone image (`lido-map-f3.png`,
  `lido-map-f2-f3.svg`, ...).

Styling follows the lfglabs.dev design system (Plus Jakarta Sans, teal accent
`#2dd4bf`, `#f5f7fa` cards on white). The webfont loads from Google Fonts and
falls back to the system stack offline.

## exports/

Pre-rendered PNGs of the structural view (`lido-map-all.png`) and of each flow
in isolation (`lido-map-f1.png` ... `lido-map-f7.png`), generated with the
export button. Referenced by `verity/targets/srv3-flow-map.md`.

## Provenance

Edges were checked against the pinned source in `tmp/core-af095e48.../contracts`
(for example `DepositSecurityModule.sol:485`, `StakingRouter.sol:983`,
`TopUpGateway.sol:232`, `AccountingOracle.sol:618`, `Accounting.sol:409`,
`ConsolidationGateway.sol:220`). Mainnet addresses follow
docs.lido.fi/deployed-contracts (July 2026); SRv3 contracts are marked
"not deployed".
