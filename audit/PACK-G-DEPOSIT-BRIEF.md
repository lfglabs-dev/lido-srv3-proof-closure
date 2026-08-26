# Pack G-DEPOSIT brief — model-side deposit pins

One node, one PR. No new guarantee IDs. Pins are Lean literals only.

## Honest claim

`PDeposit1.canonicalDepositContractAddress` equals the production beacon
deposit address, and `PDeposit1.thirtyTwoEtherWei` equals `32 * 10 ^ 18`.
A conserving source config exists at that 32-ether scale. These are
model-side pins.

`A-DEPOSIT-CONTRACT` and `A-DEPOSIT-32-ETHER` stay OPEN. This repository
has no deployed bytecode artifacts that can identify the live
`DEPOSIT_CONTRACT` immutable or the production constructor scales.

The pinned constructor source is a counterexample to discharging either fact
from source alone: it checks only that `_depositContract` and `_maxEBType1` are
nonzero, then assigns them directly. `openAssumptionsCounterexample` supplies
`0xDEAD` and `64 ether`; both pass those guards while violating the desired
canonical-address and 32-ether identities. This is not a deployment artifact.

## Work

1. Pin the production beacon deposit address and 32 ether as provenance
   abbreviations.
2. Prove the P-DEPOSIT-1 defs equal those abbreviations.
3. Record that the contract-identity assumption remains OPEN: it is
   deployed-immutable identity, not the Lean pin.
4. Exhibit a conserving config at 32 ether. Do not treat that exhibit as
   a deployment proof.

## Kill-lines

- A wrong pin `0xDEAD` is not the canonical P-DEPOSIT-1 address.
- The same wrong pin is not `productionBeaconDeposit`.
- Nonzero `0xDEAD` / `64 ether` constructor inputs are source-admitted while
  violating both deployment facts.

## Out of scope

Adding decls to `PDeposit1.lean`. Discharging the OPEN assumptions.
ALLOC → `LinksSource`. Join ETH journals. VaultHub. Live SSZ verifier.
