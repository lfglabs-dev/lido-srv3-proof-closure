import LidoSRv3.Audit.Source.SubmitReportFeeCorrespondence

/-!
# Node P3: executable `submitReportData` entry with a computed mint

Executable oracle entry for the pinned
`AccountingOracle.submitReportData` → `_handleConsensusReportData` →
`Accounting.handleOracleReport` path.  The body checks the two entry
premises this row actually models — the sender-allowed gate of
`_checkMsgSenderIsAllowedToSubmitData` and the consensus-hash equality of
`_checkConsensusData` — and then runs the already-proved
`handleOracleReportComputed` wrapper at the pair the entry *computes* from
its report data (`entryFeeWei` / `entryShareRate` of
`SubmitReportFeeCorrespondence`).

The signature is `SubmitReportData → Contract Result`: there is no
`sharesToMintAsFees` argument anywhere at the entry.  The still-free and
skipped-`_simulateOracleReport` mutants in
`Tests/PackP3SubmitReportEntryMutants` are the parent-shaped kill-lines for
exactly that claim.

Contract-version / consensus-version / ref-slot / deadline checks,
extra-data shape checks, exited-validator processing, the withdrawal-queue
`onOracleReport` call, and the lazy-oracle update are outside this modeled
body; see the source module's honesty boundary.
-/

namespace LidoSRv3.Audit.Verity.SubmitReportEntryTx

open _root_.Verity
open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.SolidityAccounting.SubmitReportEntry
open LidoSRv3.Audit.Spec.OracleMintCorrespondence
open LidoSRv3.Audit.Verity.HandleOracleReportTx

/-! ## AccountingOracle.submitReportData (AccountingOracle.sol:360-366) -/

/-- `AccountingOracle.sol:360-366 submitReportData(ReportData calldata data, uint256 contractVersion)`.

Not transcribed: AccountingOracle.sol:362 `_checkContractVersion(contractVersion);`
and 364 `uint256 prevRefSlot = _startProcessing();` (contract-version, ref-slot
and deadline bookkeeping, outside the modeled body); the body of 361 and 363
(the sender gate and the consensus-hash equality are the boolean inputs
`senderAllowed` / `consensusHashMatches`, not recomputed).
Added by the model: the revert strings `"SENDER_NOT_ALLOWED"` /
`"UNEXPECTED_DATA_HASH"` (Solidity uses custom errors), and the entry-computed
mint `entryFeeWei d` / `entryShareRate d` handed to
`handleOracleReportComputed` (P-ORACLE-SUPPLY-1) in place of the opaque
`sharesToMintAsFees` of `HandleOracleReportTx.handleOracleReport`.

Modeled oracle entry.  Guard order follows the pinned entry: the sender
gate first, then the consensus-hash check, then the report body — here the
computed-mint wrapper `handleOracleReportComputed` at the entry-computed
`entryFeeWei d` / `entryShareRate d`.  No free mint argument exists in this
signature. -/
def submitReportDataTx (d : SubmitReportData) : Contract Result := fun snapshot =>
  -- AccountingOracle.sol:361  _checkMsgSenderIsAllowedToSubmitData();
  if senderAllowed d then
    -- AccountingOracle.sol:363  _checkConsensusData(data.refSlot, data.consensusVersion, keccak256(abi.encode(data)));
    if consensusHashMatches d then
      -- AccountingOracle.sol:365  _handleConsensusReportData(data, prevRefSlot);
      handleOracleReportComputed d.report (entryFeeWei d) (entryShareRate d)
        (failAfterWrites := false) snapshot
    else .revert "UNEXPECTED_DATA_HASH" snapshot
  else .revert "SENDER_NOT_ALLOWED" snapshot

/-- On the two checked entry premises, the entry *is* the computed wrapper
at the entry-computed pair: the mint fed forward is `mintedShares
(entryFeeWei d) (entryShareRate d)`, a function of the report data, not an
argument. -/
theorem entry_is_computed_wrapper (d : SubmitReportData)
    (state : ContractState)
    (hSender : senderAllowed d = true)
    (hHash : consensusHashMatches d = true) :
    (submitReportDataTx d).run state =
      (handleOracleReportComputed d.report (entryFeeWei d) (entryShareRate d)).run
        state := by
  unfold submitReportDataTx Contract.run
  simp [hSender, hHash]

/-- The sender premise is checked, not assumed: a disallowed sender reverts
with the pre-state restored. -/
theorem entry_reverts_on_disallowed_sender (d : SubmitReportData)
    (state : ContractState) (h : senderAllowed d = false) :
    (submitReportDataTx d).run state = .revert "SENDER_NOT_ALLOWED" state := by
  unfold submitReportDataTx Contract.run
  simp [h]

/-- The consensus-hash premise is checked, not assumed: a hash mismatch
reverts with the pre-state restored. -/
theorem entry_reverts_on_hash_mismatch (d : SubmitReportData)
    (state : ContractState)
    (hSender : senderAllowed d = true) (h : consensusHashMatches d = false) :
    (submitReportDataTx d).run state = .revert "UNEXPECTED_DATA_HASH" state := by
  unfold submitReportDataTx Contract.run
  simp [hSender, h]

/-- The admitted entry has the observables of the pinned source view at the
computed mint: `handleOracleReportComputed` at the entry-computed pair is
the mint path already proved by `computed_tx_simulates_computed_source`. -/
theorem entry_observe_simulates_source_at_computed_mint
    (d : SubmitReportData) (state : ContractState)
    (hSender : senderAllowed d = true)
    (hHash : consensusHashMatches d = true) :
    observe d.report ((submitReportDataTx d).run state) =
      sourceView d.report (mintedShares (entryFeeWei d) (entryShareRate d)) := by
  rw [entry_is_computed_wrapper d state hSender hHash]
  exact computed_tx_simulates_computed_source d.report (entryFeeWei d)
    (entryShareRate d) state

end LidoSRv3.Audit.Verity.SubmitReportEntryTx
