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

    def test_owner_accepts_exact_compiler_witnesses(self):
        from foundational_trust import ACCEPTED_COMPILER_AXIOMS, require_authorized
        from check_trust_axioms import PRODUCTION_NATIVE_AXIOMS
        self.assertEqual(ACCEPTED_COMPILER_AXIOMS, PRODUCTION_NATIVE_AXIOMS)
        for axiom in ACCEPTED_COMPILER_AXIOMS:
            require_authorized([("Parent", set(FOUNDATIONAL_AXIOMS) | {axiom})])
            for mutant in (axiom + "_2", axiom.replace(".ax_1_1", ".ax_2_1"),
                           axiom.replace(".Verity.", ".Tests.")):
                with self.assertRaisesRegex(SystemExit, "authorized trust BLOCKED"):
                    require_authorized([("Parent", {mutant})])

    def test_kernel_replacements_need_no_native_dependencies(self):
        from foundational_trust import require_authorized
        require_authorized([("Parent", set(FOUNDATIONAL_AXIOMS)), ("Empty", set())])

    def test_test_names_do_not_authorize_exceptions(self):
        with self.assertRaisesRegex(SystemExit, "disclosure is not authorization"):
            require_foundational([("LidoSRv3.Tests.Witness", {"native_dependency"})])


if __name__ == "__main__":
    unittest.main()
