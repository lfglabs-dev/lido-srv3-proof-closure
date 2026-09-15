"""The owner's allowed axiom set; disclosure never grants an exception."""

FOUNDATIONAL_AXIOMS = frozenset({"propext", "Quot.sound", "Classical.choice"})


def require_foundational(reports):
    """Reject every non-foundational dependency, including disclosed native ones."""
    offenders = [(theorem, sorted(axioms - FOUNDATIONAL_AXIOMS))
                 for theorem, axioms in reports if axioms - FOUNDATIONAL_AXIOMS]
    if offenders:
        details = "; ".join(f"{theorem}: {', '.join(axioms)}"
                            for theorem, axioms in sorted(offenders))
        raise SystemExit("foundational-only trust BLOCKED; disclosure is not authorization: " + details)
