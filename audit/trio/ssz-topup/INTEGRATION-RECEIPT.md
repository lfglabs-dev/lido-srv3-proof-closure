# Top-up provenance-obstruction integration receipt

- Candidate fetched and integrated: `de88a7bb4f341d5a561c351b1e2f65f7ffa1237b`
- Candidate parent: `7b920beab2851a94382c89a2268630c2fd53ab57`
- Default-branch base: `741f836990e2e0ba97708b5b53c81f2c8b22bbb5`
- Solidity source pin: `17005714f151e5502c559932319a3f2f74ac2436`

The source map records `StakingRouter.sol:88-99` as an address-provenance
span. It admits any nonzero `_depositContract` and copies it to
`DEPOSIT_CONTRACT`; the executed `topUp` path uses that immutable at line 750
and `BeaconChainDepositor.makeBeaconChainTopUp` calls its `deposit` method at
line 106. Therefore `A-TOPUP-BEACON-ADDRESS` and its deployment/runtime parent
`A-RUNTIME-PROVENANCE` remain OPEN. This receipt makes no claim that
`P-TOPUP-1` is fully delivered and does not alter the ALLOC1, ALLOC2, or
RESERVE1 limitations.

Commands and results:

```text
git fetch origin de88a7bb4f341d5a561c351b1e2f65f7ffa1237b
# fetched FETCH_HEAD; git cat-file -t returned "commit"

git merge-base --is-ancestor 741f836990e2e0ba97708b5b53c81f2c8b22bbb5 de88a7bb4f341d5a561c351b1e2f65f7ffa1237b
# exit 0

lake build LidoSRv3.Audit.Guarantees.PTopup1 LidoSRv3.Audit.Verity.TopupTx LidoSRv3.Tests.TopupTxMutants
# local result: sandboxed lake shim: real Lake binary not found
```

The independent review supplied for the exact candidate reports its targeted
Lake run for `TopupTx`, `PTopup1`, and `TopupTxMutants` passed (1221 jobs).
