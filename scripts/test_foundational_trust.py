#!/usr/bin/env python3
"""No Lean invocation: policy regressions independent of native provenance."""
import unittest
from foundational_trust import FOUNDATIONAL_AXIOMS, require_foundational


class FoundationalTrustTests(unittest.TestCase):
    def test_foundations_and_empty_proofs(self):
        require_foundational([("Parent", set(FOUNDATIONAL_AXIOMS)), ("Empty", set())])

    def test_each_current_compiler_exception_is_rejected(self):
        from check_trust_axioms import PRODUCTION_NATIVE_AXIOMS
        for axiom in PRODUCTION_NATIVE_AXIOMS:
            with self.subTest(axiom=axiom):
                with self.assertRaisesRegex(SystemExit, "foundational-only trust BLOCKED"):
                    require_foundational([("Parent", set(FOUNDATIONAL_AXIOMS) | {axiom})])

    def test_test_names_do_not_authorize_exceptions(self):
        with self.assertRaisesRegex(SystemExit, "disclosure is not authorization"):
            require_foundational([("LidoSRv3.Tests.Witness", {"native_dependency"})])


if __name__ == "__main__":
    unittest.main()
