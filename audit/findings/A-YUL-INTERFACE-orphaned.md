# Finding: A-YUL-INTERFACE is orphaned from the registered P-SSZ-1 parents

**Category:** Assumption discharge — outcome (a) per the goal loop.
**Severity:** N/A (bookkeeping — no runtime risk change).
**Scope:** Only P-SSZ-1 declares `A-YUL-INTERFACE`; no other guarantee references it.
**Status:** Assumption retired from `audit/assumptions.yaml` and from
`P-SSZ-1.assumptions` in `audit/guarantees.yaml` in the same commit.

## Claim

The two registered P-SSZ-1 parents,
`LidoSRv3.Audit.Guarantees.PSsz1.deposit_root_iff`
and
`LidoSRv3.Audit.Guarantees.PSsz1.verity_tx_simulates_ssz_encoding`,
do **not** consume anything about handwritten Yul or direct bytecode
interface composition. `A-YUL-INTERFACE` is a stale registry
identifier for these parents.

## Structural evidence (grep)

```bash
grep -rn "yul\|Yul\|YUL\|YulInterface\|handwritten" \
  LidoSRv3/Audit/Guarantees/PSsz1.lean \
  LidoSRv3/Audit/SszDepositEquivalence.lean
# (empty)

grep -rn "yul\|Yul" \
  LidoSRv3/Audit/Verity/SszEncodingTx.lean \
  LidoSRv3/Audit/Verity/SszTxSimulation.lean \
  LidoSRv3/Audit/Verity/SszAbstractDigest.lean \
  LidoSRv3/Audit/Source/DepositDataRootCorrespondence.lean
# LidoSRv3/Audit/Verity/SszEncodingTx.lean:24:This is not a Yul, EVM, precompile-identity, or deployed-bytecode theorem.
# LidoSRv3/Audit/Verity/SszTxSimulation.lean:173:inspectable; it is observationally equivalent to the Solidity/Yul reuse of a
```

The only matches are two comment strings, both of which explicitly
**disclaim** Yul: `SszEncodingTx.lean:24` states "This is not a Yul,
EVM, precompile-identity, or deployed-bytecode theorem." and
`SszTxSimulation.lean:173` describes observational equivalence with the
Solidity/Yul reuse pattern as a **negative** — the theorem is not about
Yul semantics.

The `special_bindings.deployed_yul` binding in `P-SSZ-1` (see
`audit/guarantees.yaml`) is scoped `"SSZ helper/wrapper Yul fragment
only"` with `status: OPEN` and `assumption: A-SOLC-TRUSTED` — i.e. that
scoped binding rides on the accepted `A-SOLC-TRUSTED` boundary, not on
the separately-listed `A-YUL-INTERFACE`. `A-YUL-INTERFACE` was
therefore duplicative registry text with no dependency inside the
registered parents.

## Companion Lean evidence

The Lean orphanage proofs registered in
`LidoSRv3.Audit.Provenance.SszPerfectHashOrphaned.abstract_parent_applies_universally`
(and its Verity sibling) show that `PSsz1.deposit_root_iff` /
`PSsz1.verity_tx_simulates_ssz_encoding` apply universally without any
additional premise beyond `wellFormedDeposit src` (abstract) or nothing
at all (Verity). Any additional caller-supplied hypothesis — including
one about Yul — is unused by the registered parents.

## Reproduction

```bash
lake build LidoSRv3.Audit.Guarantees.PSsz1
python3 scripts/check_trust_axioms.py
python3 scripts/audit_metadata.py check
```

All three should report OK. The `#print axioms` of both P-SSZ-1
registered parents depends only on `{propext, Classical.choice,
Quot.sound}` — no external Yul module contributes anything.

## Action taken

In the same commit as this finding:
- Removed `A-YUL-INTERFACE` from `audit/assumptions.yaml`.
- Removed `A-YUL-INTERFACE` from `P-SSZ-1.assumptions` in `audit/guarantees.yaml`.
- Updated `EXPECTED_CANONICAL_DETAIL_SHA256["P-SSZ-1"]` in `scripts/audit_metadata.py`.
- Updated `R1_REPORT_INPUT_SHA256["audit/guarantees.yaml"]` in `scripts/audit_metadata.py`.
- Regenerated `audit/STATUS.md`, `audit/ROADMAP.md`, `audit/R1-FINAL-AUDITOR-REPORT.md`.
- Advanced `R1_REVIEW_BASE` to the commit that contains the yaml edit.
