# P-DEPOSIT-1

The registered executable theorem is now `PDeposit1.actual_deposit_call_slot_success_and_revert` in `LidoSRv3/Audit/Guarantees/PDeposit1DsmCall.lean`. It retains the `DepositDsmCall.execute` suffix result and additionally consumes `DepositAllocation.execute`: the executed allocation feeds the physical suffix. Success implies the corresponding call/slot effects; failure restores the entire entry `Live.World`.

Previously the executable registration pointed to `NFrame.verity_tx_composes_nframe_deposit_under_router_shape`, a conditional source-link theorem over aggregate batch journals and model-local observation slots. That theorem and the abstract `source_deposit_conserves_and_rolls_back` remain unchanged and available. Their source-link, shape and conservation hypotheses do not establish the new executable limb, and this change does not turn their model slots into physical storage.

The new parent fixes hashing to `KeccakEngine.keccak256`. Its successful execution obtains the DSM address from actual locator STATICCALL return bytes, checks authorization and physical module membership/status/credentials, calls the selected module, decodes its returned byte arrays and computes preparation values. Physical metadata writes consume the module-returned World, preserve the upper packed bits, and append the metadata event before withdrawal/beacon execution. A zero-key result makes no withdrawal or beacon calls. A nonzero result consumes `LiveBeaconCommitted.SuffixCommitment`: the actual withdrawal result, per-key beacon loop, returned World, journal and final router-balance assertion. Failure restores state, balances and logs together; attempted calls remain observations.

The pinned source is `lido-core@17005714f151e5502c559932319a3f2f74ac2436`, particularly `StakingRouter.sol:942-997`. Existing `DepositDsmCall`, `DepositPhysicalAdmission`, `ModuleCall`, `ModulePhysicalMetadata`, `PhysicalMetadata` and `LiveBeaconCommitted` derivations are reused rather than replaced with supplied success receipts. The actual DSM locator derivation is retained from `73c6360efdcd5b25a7188b4ed3de292001128f1d`.

Remaining obligations are explicit:

- The retained suffix conjunct takes `ModuleCall.Input.selected`; the allocation conjunct derives it from the executed ALLOC1/ALLOC2 source/ABI producer over physical router words. `Lido.getDepositableEther`, actual allocation STATICCALL/DELEGATECALL realization, module-id/calldata provenance, immutable maxEB and locator/deployment identities remain open.
- Locator and module-return memory cursors are supplied phase inputs. Decoder guards execute; their upstream memory-state origins and general memory/gas correspondence remain open.
- The Lido withdrawal body executes. Its getter/receiver callbacks remain an arbitrary External; the parent proves the actual body and callback-result continuation, not deployed callee correspondence. Existing physical-ledger conservation consumers need their explicit locator/role hypotheses; unconditional deployed conservation is not claimed.
- The physical storage and beacon executables are source-shaped models. Bytecode/compiler/deployment, precompile-dispatch and LOG ABI/gas correspondences remain in scope and unproved under the expanded proof-only goal.

Validation at `be77c30c6bc06add31e5816fa9076b9324878d9b` used Lean `v4.31.0` and Verity `e977aaad6e1a9e92e0132d41b3d33a14135a4d46`:

```sh
REMOTE_BUILD_NODE_ID=dgx-spark REMOTE_BUILD_PASSIVE=1 remote-lean-build lake build LidoSRv3.Audit.Guarantees.PDeposit1DsmCall LidoSRv3.Tests.DepositDsmCall LidoSRv3.Tests.DepositPhysicalAdmission LidoSRv3.Tests.DepositPhysicalMetadataRegression
```

Job `52552f68-a486-4cc6-929a-20fd944061f0` succeeded with exit 0 (1,344 jobs). The registered theorem reports only `propext`, `Classical.choice`, and `Quot.sound`. Tests include actual locator success/rejection/late rollback, physical admission and metadata regressions. This receipt applies to that SHA; combined-candidate validation and fresh independent review remain pending.

## Executed allocation before module calls

The registered parent retains its prior supplied-allocation suffix conclusion and
adds DepositAllocation.execute. DSM lookup and physical admission precede the
allocation producer. The producer uses account-qualified count/record reads,
executes the existing ALLOC1/ALLOC2 source/ABI composition, then checked-subtracts
one from physical membership and indexes the returned allocation. Its selected
amount and matching maxEB feed the actual module/metadata/per-key suffix. A failed
allocation cannot issue obtainDepositData. All suffix failures restore the entry
world; attempted allocation calls are retained separately.

Remaining boundaries: Lido.getDepositableEther executable return producer, actual
allocation STATICCALL/DELEGATECALL realization, constructor/config and phase-memory
cursor provenance, and deployment/runtime/hash correspondence. The generic test
hash is only a fixture; the registered parent supplies concrete Keccak. The ALLOC
arbitrary-summary counterexample remains valid and is exercised through DEPOSIT.
No paired Solidity differential or independent full-gate acceptance is implied.

## Terminal allocation failures

The registered allocation conjunct now also consumes
`DepositAllocation.AllocationFailureStops`. For every actual successful DSM
lookup and admitted active physical module, an executed allocation failure yields
the exact mapped fault, the complete entry World, no module/withdrawal/beacon
attempts, and the unchanged locator and allocation transcripts. This covers every
allocation failure constructor, not only the arbitrary-module arithmetic example.
The statement does not assume allocation success or legacy/physical equivalence.

`Tests/DepositAllocation.lean` retains the genuine arbitrary-module underflow
counterexample and adds malformed successful summary bytes against an accepting
module callback. It also projects the universal failure statement directly from
the registered parent. These are Lean source-execution regressions, not additional
paired Solidity differential vectors. The available-ether producer, supported
module reachability, compiled/deployed allocation and other boundaries above
remain open.
