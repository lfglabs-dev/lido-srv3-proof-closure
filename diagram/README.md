# Lido SRv3 architecture diagram

`index.html` maps contracts, mainnet addresses, off-chain actors, and seven
protocol flows at `lidofinance/core@af095e48`. Edge labels are function calls.

Open `index.html` in a browser. No build.

- Flow pills F1–F7 highlight paths. Several pills may be on at once.
- Hover a node for address and role.
- Export PNG or SVG of the current view.

Typeface is Plus Jakarta Sans; accent `#2dd4bf`. The webfont loads from Google
Fonts and falls back offline.

Exports are not versioned. `archive/legacy-p1-p15/verity-targets/srv3-flow-map.md`
points here.

Edges were checked against pinned source under `tmp/core-af095e48.../contracts`
(examples: `DepositSecurityModule.sol:485`, `StakingRouter.sol:983`,
`TopUpGateway.sol:232`, `AccountingOracle.sol:618`, `Accounting.sol:409`,
`ConsolidationGateway.sol:220`). Mainnet addresses follow
docs.lido.fi/deployed-contracts (July 2026). SRv3 contracts are marked
“not deployed”.
