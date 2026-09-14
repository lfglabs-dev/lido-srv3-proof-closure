# P-DEPOSIT-1

The registered executable theorem is now `PDeposit1.actual_deposit_call_slot_success_and_revert` in `LidoSRv3/Audit/Guarantees/PDeposit1DsmCall.lean`. It consumes one actual `DepositDsmCall.execute` result: success implies the complete existing call/slot effects; failure restores the entire entry `Live.World`.

Previously the executable registration pointed to `NFrame.verity_tx_composes_nframe_deposit_under_router_shape`, a conditional source-link theorem over aggregate batch journals and model-local observation slots. That theorem and the abstract `source_deposit_conserves_and_rolls_back` remain unchanged and available. Their source-link, shape and conservation hypotheses do not establish the new executable limb, and this change does not turn their model slots into physical storage.

The new parent fixes hashing to `KeccakEngine.keccak256`. Its successful execution obtains the DSM address from actual locator STATICCALL return bytes, checks authorization and physical module membership/status/credentials, calls the selected module, decodes its returned byte arrays and computes preparation values. Physical metadata writes consume the module-returned World, preserve the upper packed bits, and append the metadata event before withdrawal/beacon execution. A zero-key result makes no withdrawal or beacon calls. A nonzero result consumes `LiveBeaconCommitted.SuffixCommitment`: the actual withdrawal result, per-key beacon loop, returned World, journal and final router-balance assertion. Failure restores state, balances and logs together; attempted calls remain observations.

The pinned source is `lido-core@17005714f151e5502c559932319a3f2f74ac2436`, particularly `StakingRouter.sol:942-997`. Existing `DepositDsmCall`, `DepositPhysicalAdmission`, `ModuleCall`, `ModulePhysicalMetadata`, `PhysicalMetadata` and `LiveBeaconCommitted` derivations are reused rather than replaced with supplied success receipts. The actual DSM locator derivation is retained from `73c6360efdcd5b25a7188b4ed3de292001128f1d`.

Remaining obligations are explicit:

- `ModuleCall.Input.selected` comes from an upstream allocation phase. The parent does not execute its allocation/view-call producer. Module id/calldata, immutable maxEB and locator identities also retain input/deployment provenance boundaries.
- Locator and module-return memory cursors are supplied phase inputs. Decoder guards execute; their upstream memory-state origins and general memory/gas correspondence remain open.
- The Lido withdrawal body executes. Its getter/receiver callbacks remain an arbitrary External; the parent proves the actual body and callback-result continuation, not deployed callee correspondence. Existing physical-ledger conservation consumers need their explicit locator/role hypotheses; unconditional deployed conservation is not claimed.
- The physical storage and beacon executables are source-shaped models. General bytecode/compiler/deployment, precompile-dispatch and LOG ABI/gas proofs stay outside scope.

Validation at `be77c30c6bc06add31e5816fa9076b9324878d9b` used Lean `v4.31.0` and Verity `e977aaad6e1a9e92e0132d41b3d33a14135a4d46`:

```sh
REMOTE_BUILD_NODE_ID=dgx-spark REMOTE_BUILD_PASSIVE=1 remote-lean-build lake build LidoSRv3.Audit.Guarantees.PDeposit1DsmCall LidoSRv3.Tests.DepositDsmCall LidoSRv3.Tests.DepositPhysicalAdmission LidoSRv3.Tests.DepositPhysicalMetadataRegression
```

Job `52552f68-a486-4cc6-929a-20fd944061f0` succeeded with exit 0 (1,344 jobs). The registered theorem reports only `propext`, `Classical.choice`, and `Quot.sound`. Tests include actual locator success/rejection/late rollback, physical admission and metadata regressions. This receipt applies to that SHA; combined-candidate validation and fresh independent review remain pending.
