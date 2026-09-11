# Physical StakingRouter deposit admission

This additive consumer derives registry membership, active status and the selected withdrawal credential from physical router storage before invoking the unchanged accepted `ModulePhysicalMetadata.program`. Its public success theorem retains the entire previous module → metadata → withdrawal/beacon conclusion on the same worlds and attempt journal, and identifies the credential of that very commitment with the physically selected word and its 32 encoded octets. The public failure theorem restores the complete entry world. No old source or global guarantee wiring changes in this source candidate.

## Source correspondence

Pinned core: `17005714f151e5502c559932319a3f2f74ac2436`. The Solidity dossier vendors and checks the full import closure of StakingRouter with OpenZeppelin 5.2.0. `AdmissionHarness.ir` is optimized IR from the complete actual inherited router, not an invented interpreter or a replacement deposit body.

| Executed prefix | Actual source | Model |
| --- | --- | --- |
| Caller authorization first | StakingRouter.deposit 943; `_checkAppAuth` | Comparison with the already resolved DSM address; no new call |
| Registry existence | `_getModuleState` → SRUtils → SRStorage.isModuleExists → EnumerableSet.contains | Nonzero `_positions[id]`, mapping at ERC-7201 root + 2 |
| Status conversion and check | ModuleStateConfig status byte; compiler enum conversion | Bits 224–231; values ≥3 panic 0x21, 1/2 inactive, only 0 admitted |
| Type and raw credential | config type byte; `_getWithdrawalCredentialsWithType`; WithdrawalCredentials.setType | Bits 232–239; raw storage root + 4; low 248 bits preserved and top byte overwritten |
| Actual module and suffix | Unchanged #321 ModulePhysicalMetadata program/public theorem | Same input/entry world, derived context, module-returned world, physical metadata and actual withdrawal/beacon suffix |

The ERC-7201 root is checked independently from the namespace formula in the real Solidity fixture. Module mapping uses two 32-byte words `(id, root)`; registry membership uses `(id, root+2)`. Membership does not consult `lastModuleId`. The compiler layout and full IR confirm the field offsets and invalid-enum panic, including authorization before membership and status. `setType` accepts every uint8 byte; no invented restriction to 1/2 is imposed. `selectedOctets_head` proves that the leading encoded byte equals this selected type; the public effect additionally identifies the complete encoded credential with the same suffix commitment.

## What is and is not composed

`actual_registered_module_call_metadata_suffix` assumes only the whole new runner returned `.ok`; it derives authorization, membership, active status and the complete existing public effect. It supplies no `hcfg`, internal stage success, root-match, nonalias or hash-injectivity premise. `ctx.moduleActive` and `ctx.withdrawalCredentials` are deliberately false/absent in the successful regression: the physical prefix replaces them. A successful module may change the entire world, including its config; the captured credential remains the entry-selected credential used by the returned commitment.

This is an admission adapter around the accepted phase consumer, not the whole deployed deposit entrypoint. DSM locator resolution, earlier `getDepositableEther` and ALLOC execution/returned state, selected allocation, constructor-immutable identity of `maxEB`, and the module return-buffer cursor's earlier memory origin remain supplied boundaries. In particular, this adapter does not prove that a possibly stateful omitted prelude preserves the reads captured by the source entrypoint. Actual constructor maxEB arguments are nonzero but not necessarily 32 ETH: the fixture uses 7 and 11. The arbitrary phase input still has the old zero-divisor panic. The source's later beacon helper uses its fixed 32 ETH deposits; existing success/ledger conditions are retained rather than equating that constant with arbitrary maxEB.

The old typed World, module/withdrawal external interpretations, natural-number ETH ledger, SHA/Keccak/ABI and gas/runtime/deployment limits remain. This prefix uses the same opaque Keccak function and exact mapping preimages; it proves no cryptographic implementation. It introduces no final slot facts that require slot separation. The old metadata consumer reads its module-returned environment fields; this lot does not establish that an arbitrary model external corresponds to immutable EVM timestamp/block fields. Existing original P-DEPOSIT models and their other open assumptions are unchanged.

## Validation

- Normal targeted Lake build: `lake build LidoSRv3.Tests.DepositPhysicalAdmission`, exit 0, 1328 jobs. Final tests actively compiled in 1.9 s; unchanged source/public/dependencies were accepted from Lake's current cache. This is not a fresh dependency rebuild. Development failures and interrupted attempts are retained as diagnostics, not successful receipts.
- 8 source theorems including one private encoding helper; 2 public theorems; 16 executable kernel examples, a kernel positive composition instance and a public rejection/rollback instance. The positive proof transports through the accepted actual CALL equation and positive withdrawal/beacon theorem; it supplies no successful stage as a theorem premise and does not introduce `native_decide` or a new `#eval`.
- Six active axiom queries: only `propext`, `Classical.choice`, `Quot.sound` (rollback uses only propext/Quot.sound). `validate.py` checks 1311 actual imported/new source identities and 11 package pins, selected local cached artifacts and unchanged old sources against base `10e2b693d00cbbeab65f60cd8964ced87297336a`.
- Six actual Solidity tests pass, including two fuzz tests at 1024 runs and complete sweeps of all 256 status/type bytes. The harness calls actual inherited admission accessors/auth and the exact source status check, with already resolved DSM supplied. It does not execute `deposit` through Lido allocation, module funding or beacon calls. The full inherited deposit body is separately present in the compiler IR. Fixture tests establish finite source correspondence checks, not universal deployment or cryptographic correctness.

Reproduction from the proof repository root:

```sh
lake build LidoSRv3.Tests.DepositPhysicalAdmission
python3 audit/deposit-physical-admission/validate.py
forge test --root audit/deposit-physical-admission/solidity --fuzz-seed 0x20260911 -vv
forge inspect --root audit/deposit-physical-admission/solidity AdmissionHarness irOptimized
forge inspect --root audit/deposit-physical-admission/solidity AdmissionHarness storageLayout --json
```

The fresh fixture uses solc 0.8.25, optimizer 200, via IR, Cancun, and Forge 1.5.0. This profile is explicit compiler evidence, not a claim that a deployed artifact has those settings. Raw compiler IR may contain trailing whitespace/blank EOF; it is preserved byte-for-byte.
