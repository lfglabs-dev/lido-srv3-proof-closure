# P-ALLOC-1

The registered parents remain `PAlloc1.checked_execute` and `PAlloc1.verity_tx_simulates_allocation_count_from_storage`. The former proves successful checked execution and equality of its capacity column with MathView under all five `CheckedBounds` fields. The latter consumes mapped summary/stake calls and decoded rows at `allocateLiveFromStorage`, under explicit length/binding premises, and compares persisted model observations with sourceView. Neither claims unconditional success for every reachable router.

At source pin `17005714f151e5502c559932319a3f2f74ac2436`, `contracts/0.8.25/sr/SRLib.sol:374-378` returns external `uint256` exited/deposited/depositable counts. Lines517-522 use those values in checked `deposited - max(externalExited, accountingExited)`. Type2 stake is another external uint256 value (529); subsequent totals, available capacity and target multiplication also use checked arithmetic (532,546,548,552). Router-local uint64 accounting and the32-module bound cannot establish unrestricted reply invariants.

The new `AllocationTxMutants` witness uses an ABI-valid `(1,0,0)` summary. It checks decoding, refutes `CheckedBounds.active_subtraction`, proves sourceExecute failure, and checks ALLOC_ARITHMETIC at the existing live callback/decoder entry. This is a counterexample to deriving unconditional bounds from the interface alone, not evidence that an honest deployed module produces it. The test does not certify exact source call ordering.

The useful conditional arithmetic from #652/#653 remains. The invented #662 addValidators/updateExitedCounters history was removed in phase1; the remaining naming-scaffold comments now identify their premises as external summary relations. No assumed uint64 bound on an external uint256 reply is presented as derived storage behavior.

Explicit remaining obligations:

- External module semantics must establish summary consistency and adequate numeric bounds. Configuration/input bounds, including nonzero maxEBType1, remain explicit. Removing CheckedBounds without these facts would make the successful-execution claim false.
- `bindLiveAll` hoists calls before arithmetic. Solidity interleaves each row's calls and arithmetic; a failure may prevent later calls. Full trace/error-order equivalence remains open.
- Model-local slots/maps and output observation arrays are not physical ERC7201 storage. Packed field decoding and model rollback do not establish general runtime/storage correspondence.
- `_addModule` rejects duplicate addresses (SRLib.sol200-205), while migration copies legacy addresses (101-113). A uniqueness history requires initial/migrated registry evidence and writers; it is not derived by this row.
- Caller getDepositAllocations, P-ALLOC-2, ALLOC-to-DEPOSIT and general deployed Yul/EVM closure remain outside this claim.

Targeted validation at `b0faa1161e7b3c3aad36839c7e492bd9ec39d100` (job `425295b7-1e7a-467f-aad4-dd9bf1a93ae2`) found two test syntax errors. Commit `269a10eb` fixes the record-update layout and comment before #guard. Corrected validation passed at `2f2316c769b7e5fc3921e473679238ad15b007c4`, job `36947603-d597-4506-9f41-619405ae6fd4` on dgx-spark, exit0 (1,235 jobs), with this command:

```sh
REMOTE_BUILD_NODE_ID=dgx-spark REMOTE_BUILD_PASSIVE=1 remote-lean-build lake build LidoSRv3.Audit.Guarantees.PAlloc1 LidoSRv3.Audit.Verity.AllocationTx LidoSRv3.Tests.AllocationTxMutants
```

Lean v4.31.0 and Verity e977aaad6e1a9e92e0132d41b3d33a14135a4d46 are pinned. Earlier phase1 targeted builds passed, but do not validate this new witness or the final combined SHA. Fresh independent audit remains required.
