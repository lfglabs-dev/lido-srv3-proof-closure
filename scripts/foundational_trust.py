"""Foundations and the owner-approved compiler exceptions (2026-09-15)."""

FOUNDATIONAL_AXIOMS = frozenset({"propext", "Quot.sound", "Classical.choice"})


def require_foundational(reports):
    """Reject every non-foundational dependency, including disclosed native ones."""
    offenders = [(theorem, sorted(axioms - FOUNDATIONAL_AXIOMS))
                 for theorem, axioms in reports if axioms - FOUNDATIONAL_AXIOMS]
    if offenders:
        details = "; ".join(f"{theorem}: {', '.join(axioms)}"
                            for theorem, axioms in sorted(offenders))
        raise SystemExit("foundational-only trust BLOCKED; disclosure is not authorization: " + details)


# Authorization is independent of the emitted inventory. Kernel replacements
# may remove these dependencies; disclosure cannot authorize other names.
ACCEPTED_COMPILER_AXIOMS = frozenset(
    "LidoSRv3.Audit.Verity." + witness + "._native.native_decide.ax_1_1"
    for witness in (
        "AllocCapacityPhase3.consumed_summary_function_spec_compiles",
        "SszAbstractDigest.deposit_data_root_compiles",
        "ConsolidationAbstractFlowModel.forward_compiles",
    )
)


def require_authorized(reports):
    """Policy check only; the caller must also verify types and re-evaluate claims."""
    allowed = FOUNDATIONAL_AXIOMS | ACCEPTED_COMPILER_AXIOMS
    offenders = [(theorem, sorted(axioms - allowed))
                 for theorem, axioms in reports if axioms - allowed]
    if offenders:
        details = "; ".join(f"{theorem}: {', '.join(axioms)}"
                            for theorem, axioms in sorted(offenders))
        raise SystemExit("authorized trust BLOCKED; disclosure is not authorization: " + details)
