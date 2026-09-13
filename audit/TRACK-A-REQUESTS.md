# Track-A-REQUESTS

## 2026-09-13: dangling `#print axioms` in LidoSRv3/Audit/Trust.lean

The chantier-0 cleanup PR #550
(`spark/lido-fix-track-a-cleanup-orphan-sources-20260913`, merged in
commit `59e39f95`) removed the following source scaffold modules
without also removing their `#print axioms` lines in
`LidoSRv3/Audit/Trust.lean`. As a result `lake build LidoSRv3.Audit.Trust`
fails on `Unknown constant …` errors at those lines. Track-C
(`P-SSZ-1` chantier 1) has restored the five modules its
`real_validator_correspondence` abstract parent consumes; the
following remain to reconcile:

- `LidoSRv3.Audit.Source.ERC20StorageSource.balanceOf_eq` (Trust.lean:929)
- `LidoSRv3.Audit.Source.ERC20StorageSource.allowanceOf_eq` (Trust.lean:930)
- `LidoSRv3.Audit.Source.AddressStETHGuardsSource.callerBalanceSufficient_true_of_bound` (Trust.lean:932)
- `LidoSRv3.Audit.Source.AddressStETHGuardsSource.callerAllowanceSufficient_true_of_bound` (Trust.lean:933)
- `LidoSRv3.Audit.Source.ConsolidationRoleGuardSource.role_granted_of_acl` (Trust.lean:935)
- `LidoSRv3.Audit.Source.ConsolidationPauseGuardSource.not_paused_of_slot_zero` (Trust.lean:937)
- `LidoSRv3.Audit.Source.ConsolidationPauseGuardSource.whenResumed_passes_of_not_paused` (Trust.lean:938)
- `LidoSRv3.Audit.Source.ConsolidationQuotaGuardSource.quotaCheck_passes_of_bound` (Trust.lean:940)
- `LidoSRv3.Audit.Source.ConsolidationClProofSource.clProof_valid_of_registry` (Trust.lean:942)
- `LidoSRv3.Audit.Source.ConsolidationFeeLiveStaticcallSource.executeStaticcall_abiDecodedFee_eq` (Trust.lean:944)
- `LidoSRv3.Audit.Source.ConsolidationFeeLiveStaticcallSource.consolidationFee_from_live_env` (Trust.lean:945)
- `LidoSRv3.Audit.Source.BridgePerWriterExecutablePlane.executeBridgeCall_succeeded_of_call` (Trust.lean:947)
- `LidoSRv3.Audit.Source.BridgePerWriterExecutablePlane.executeBridgeCall_succeeded_of_transferFrom` (Trust.lean:948)
- `LidoSRv3.Audit.Source.BridgeSelectorViaOracleSource.realSelectorFor_deterministic` (Trust.lean:956)
- `LidoSRv3.Audit.Source.ERC20AllowanceKeyViaOracleSource.realAllowanceSlot_eq` (Trust.lean:963)
- `LidoSRv3.Audit.Source.ERC20AllowanceKeyViaOracleSource.realAllowanceSlot_deterministic` (Trust.lean:964)
- `LidoSRv3.Audit.Source.ConsolidationPauseSlotViaOracleSource.whenResumedGuardFromOracle_passes_of_slot_zero` (Trust.lean:968)
- `LidoSRv3.Audit.Source.SszListRootSource.mixInLength_deterministic` (Trust.lean:1175)
- `LidoSRv3.Audit.Source.SszListRootSource.mixInLength_output_length` (Trust.lean:1176)

Please either restore the source scaffolds (if Track-A intends to
consume them into a registered parent) or delete the dangling
`#print axioms` lines.

### 2026-09-13 (later): Resolved

All 119 dangling `#print axioms LidoSRv3.Audit.Source.<Name>.<sym>`
lines for the 51 modules removed by PR #550 have been stripped from
`LidoSRv3/Audit/Trust.lean` in the follow-up PR
`spark/lido-fix-track-a-trust-dangling-print-axioms-20260913`.
`lake build LidoSRv3.Audit.Trust` now succeeds (1882 jobs) and full
`lake build` succeeds (1851 jobs).
