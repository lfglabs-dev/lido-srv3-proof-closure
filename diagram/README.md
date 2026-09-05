# Lido SRv3 architecture diagram

`index.html` maps contracts, mainnet addresses, off-chain actors, and seven
protocol flows at `lidofinance/core@17005714`. Edge labels are function calls.

Open `index.html` in a browser. No build.

- Flow pills F1–F7 highlight paths. Several pills may be on at once.
- Hover a node for address and role.
- Export PNG or SVG of the current view.

Typeface is Plus Jakarta Sans; accent `#2dd4bf`. The webfont loads from Google
Fonts and falls back offline.

Exports are not versioned. `archive/legacy-p1-p15/verity-targets/srv3-flow-map.md`
points here.

Edges were checked against the pinned source (`lidofinance/core@17005714`, the
v4.0.0 release merge, in a local `tmp/core-17005714.../contracts` checkout)
(examples: `DepositSecurityModule.sol:485`, `StakingRouter.sol:983`,
`TopUpGateway.sol:232`, `AccountingOracle.sol:618`, `Accounting.sol:409`,
`ConsolidationGateway.sol:220`). Mainnet addresses follow
docs.lido.fi/deployed-contracts (July 2026). The SRv3 contracts were deployed
with v4.0.0 on 2026-07-24 and carry their mainnet addresses (TopUpGateway proxy
`0x3FC2C71579D80790Aaa3fc7Be8B66ac39dC57374`, ConsolidationGateway
`0x17be979344f2c2cC806229a532D92f8742C10462`, ConsolidationBus proxy
`0xd907CE33B4Be423823d1CFFe80BD147E8b8554C8`, ConsolidationMigrator proxy
`0x9Dc70b5A4f4F5E4AF9058C983D560564F031f1D7`, Curated Module v2 proxy
`0xDa5F930cE326EB5205085D66c72A4E79d60cB8C1`).

## Taxonomy

A node's colour says what makes it trustworthy, not where it runs. The two are
easy to conflate, so the six classes are pinned here and enforced by
`scripts/check_diagram_taxonomy.py`:

- `el` — an EL contract whose behaviour is fixed by its own code.
- `proof` — an EL contract that additionally gates on an EIP-4788 beacon-root
  proof (`TopUpGateway` via `CLValidatorVerifier`, `ConsolidationGateway` via
  the separate `CLProofVerifier`). The canvas draws the consolidation path as
  one combined `Consolidation pipeline` box and the notes card names its
  `ConsolidationGateway`; both spellings are required in this class, on their
  own surface, so repainting either one fails the check.
- `com` — an EL contract whose power is held by a quorum or a committee, i.e.
  the contract that itself stores the member set and the threshold:
  `HashConsensus` (`_quorum`, `HashConsensus.sol:225,455-461,945`),
  `DepositSecurityModule` (`:97-98`, `getGuardianQuorum :227-231`), EasyTrack,
  the Aragon DAO. `AccountingOracle` and `ValidatorsExitBusOracle` are **not**
  in this class: both are `BaseOracle` (`AccountingOracle.sol:69`,
  `ValidatorsExitBusOracle.sol:16`) and defer the quorum to `HashConsensus`
  (`BaseOracle.sol:38,115-116`).
- `sys` — an Ethereum system predeploy. EIP-4788, EIP-7002 and EIP-7251 belong
  here. They execute on the EL and are reached by ordinary `call` /
  `staticcall` (`CLValidatorVerifier.sol:104`,
  `TriggerableWithdrawals.sol:51,131,144`), so drawing them as consensus layer
  overstates how far outside the EL trust boundary they sit.
- `bot` — off-chain: picks when and what, never how much. No actor in this
  class can redirect principal: every Lido validator's withdrawal credentials
  point at the `WithdrawalVault` and are write-once. What a compromise costs is
  then per actor and not an invariant of the class. For the staker and the
  depositor bot it is liveness only — they choose module and timing, so a
  compromise stalls or mistimes a deposit and nothing else. Node operators are
  the exception: they hold the validator signing keys, and a compromised
  signing key can sign slashable messages, so validator balances can be reduced
  even though the principal itself stays out of the attacker's reach. The
  oracle daemons compute a deterministic, replayable report and hold no quorum
  of their own; the quorum they must reach lives in `HashConsensus` (`com`).
- `cl` — genuinely consensus layer: the validator set itself.

Two authority claims in the consolidation pipeline are easy to get backwards
and are stated here for the record. Adding a CMv1→CMv2 operator pair is
`ConsolidationMigrator.ALLOW_PAIR_ROLE` (`:118,181-185`), granted only to the
EasyTrack `EVMScriptExecutor` (`UpgradeTemporaryAdmin.sol:68,91-92`;
`UpgradeTemplate.sol:340-341`) — an allow-only power. Removing a committed
batch is `ConsolidationBus.REMOVE_ROLE` (`:168,250`), held by the consolidation
committee (`UpgradeTemporaryAdmin.sol:99`; `UpgradeTemplate.sol:331`), so the
Bus execution delay is that committee's veto window and not the DSM guardians'.
The guardians' only reach into consolidation is the `isDepositsPaused()` flag
(`DepositSecurityModule.sol:88`) that `ConsolidationGateway` reads
(`:276-277`).
