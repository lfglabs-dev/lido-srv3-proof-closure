# Leftover DAG — provenance, Join journals, hash hyp, bridge gap

One node, one brief, one PR. No new guarantee IDs. Named hyps stay named.
Compose Spec → Source → Verity. Integrator owns `LidoSRv3.lean`,
`Trust.lean`, and `audit/validation-receipt.txt`.

```
                G0 Spec widen
               /    |     \
             /      |      \
    G-DEPOSIT   G-TOPUP   G-ETH1     S1 hash     C-GAP
    (G1+G2)      (G3)      (G4)     named hyp    ABI gap
        \          |         |
         \         |         |
          J-DEPOSIT J-TOPUP  (C2 blocked)
               \     /
                \   /
              integrator
```

Wave G0 is this branch. Later nodes branch from it and must not edit
`Spec.lean` except G0.

## Wave G0 (this node)

Widen `ApprovedDestination` with `beaconDeposit` and `lidoPull` only.
Not VaultHub. Not all SRv3 ETH. Pack B mapping is unchanged.

## Wave 1 — parallel (own files only)

| Node | Branch suffix | Own files | Honest claim | Must not |
| --- | --- | --- | --- | --- |
| G-DEPOSIT | `leftover-g-deposit` | `Audit/Provenance/Deposit.lean`, `Tests/PackGDepositProvenanceMutants.lean`, `audit/PACK-G-DEPOSIT-BRIEF.md` | Model pins equal production literals; a conserving config at 32e18 exists. `A-DEPOSIT-CONTRACT` / `A-DEPOSIT-32-ETHER` stay OPEN (no deployed artifact in-repo). | Add decls to `PDeposit1.lean`. Discharge the A-* hyps. ALLOC→LinksSource. |
| G-TOPUP | `leftover-g-topup` | `Audit/Provenance/TopupBeacon.lean`, `Tests/PackGTopupProvenanceMutants.lean`, `audit/PACK-G-TOPUP-BRIEF.md` | `TopupTx.beaconAddress` equals the production beacon pin. `A-TOPUP-BEACON-ADDRESS` stays OPEN. | Add decls to `PTopup1.lean`. Top-up LinksSource from ALLOC. |
| G-ETH1 | `leftover-g-eth1` | `Audit/Provenance/ConsolidationRequest.lean`, `Tests/PackGEth1ProvenanceMutants.lean`, `audit/PACK-G-ETH1-BRIEF.md` | Unregistered child: ensemble `requestAddr` (5) maps to `canonicalRequestAddress` in a Spec-shaped observe rewrite. Registered Verity parent stays on ensemble 5. `A-CANONICAL-REQUEST-ADDRESS` stays OPEN. | Change registered ETH-1 parent. Compose with P-CONSOLIDATION-1. VaultHub. `native_decide` on parents. |
| J-DEPOSIT | `leftover-j-deposit` | `Audit/Spec/DepositEthJournalCorrespondence.lean`, `Tests/PackJDepositEthJournalMutants.lean`, `audit/PACK-J-DEPOSIT-BRIEF.md` | Success two-batch deposit journal projects onto `Spec.EthJournal` (`lidoPull` + two `beaconDeposit`). `LinksSource` stays named. | Merge ALLOC into DEPOSIT. VaultHub. Live SSZ verifier. |
| J-TOPUP | `leftover-j-topup` | `Audit/Spec/TopupEthJournalCorrespondence.lean`, `Tests/PackJTopupEthJournalMutants.lean`, `audit/PACK-J-TOPUP-BRIEF.md` | Value-moving top-up journal projects (`lidoPull` + `beaconDeposit`s). Wrap-to-zero is empty journal. | Discharge wrap. All SRv3 ETH. |
| S1 | `leftover-s1-hash` | `Audit/Spec/HashIdentificationChild.lean`, `Tests/PackS1HashMutants.lean`, `audit/PACK-S1-BRIEF.md` | Child under named `HashIdentification`. Do not discharge it. Opaque `sha256` ≠ engine until proved. | Deployed SHA, Yul, EIP-4788, address-2. |
| C-GAP | `leftover-c-gap` | `Audit/Spec/ConsolidationBridgeGap.lean`, `Tests/PackCGapMutants.lean`, `audit/PACK-C-GAP-BRIEF.md` | Name the official-denotation gap: `Expr.call` reverts. `A-CONSOLIDATION-GATEWAY-NONZERO` stays named. | Discharge the hyp. Start the bus. Compose ETH-1 with CONSOLIDATION-1. |

## Wave 2 — blocked (do not start in Wave 1)

- Live `SSZ.verifyProof` / production gindices / EIP-4788 (needs S1 discharge + FFI)
- ABI/interpreter so request CALLs do not revert (C1), then C2/C3/C4
- VaultHub, pause, oracle split, promote P-DEREF-1 (new IDs)

## Shared-file rule

Agents must not edit `LidoSRv3.lean`, `LidoSRv3/Audit/Trust.lean`,
`audit/validation-receipt.txt`, `audit/guarantees.yaml`,
`audit/assumptions.yaml`, or `LidoSRv3/Audit/Guarantees/PDeposit1.lean` /
`PTopup1.lean` (public-claim allowlist). Integrator wires imports and
rebinds the receipt once.
