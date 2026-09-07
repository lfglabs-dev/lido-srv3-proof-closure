"""Render the separately scoped trio composition evidence."""

def source_composition_review(source):
    """Render separately scoped source evidence without replacing primary claims."""
    if source is None:
        return []
    review = source.get("execution_review", {})
    if "scope" not in review:
        return []
    return [
        "**Trio source composition.** " + review["scope"] + "\n\n",
        "**Composition validation.** " + review["correspondence_status"] + "\n\n",
        "**Composition evidence.** " + ", ".join(
            "`" + name + "`" for name in review["supplementary_evidence"]) + "\n\n",
        "**Composition premises and exclusions.** " + " ".join(review["premises"]) + "\n\n",
    ]
