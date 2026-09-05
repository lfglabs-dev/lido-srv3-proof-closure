#!/usr/bin/env python3
"""Negative regressions for the Python complexity and file-length ratchet."""

from __future__ import annotations

import contextlib
import io
import shutil
import sys
import tempfile
import ast
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import check_python_quality  # noqa: E402  (sibling module, located above)

DENSE_BODY = " or ".join(f"x == {n}" for n in range(24))
DENSE = "def dense(x):\n    return " + DENSE_BODY + "\n"
SCOPED = (
    "class A:\n    def dense(self, x):\n        return " + DENSE_BODY + "\n"
    "class B:\n    def dense(self, x):\n        return x\n"
    "def outer(x):\n    def dense(y):\n        return " + DENSE_BODY + "\n    return dense(x)\n"
    "def dense(x):\n    return " + DENSE_BODY + "\n"
    "def dense(x):\n    return x\n"
)


def invoke(*argv: str) -> tuple[bool, str]:
    out = io.StringIO()
    saved = sys.argv
    sys.argv = ["check_python_quality.py", *argv]
    try:
        with contextlib.redirect_stdout(out):
            check_python_quality.main()
        return True, out.getvalue()
    except SystemExit as stop:
        return False, f"{stop}"
    finally:
        sys.argv = saved


def expect(succeeds: bool, diagnostic: str, *argv: str) -> None:
    ok, text = invoke(*argv)
    if ok != succeeds:
        raise SystemExit(f"unexpected result ({ok}) for {argv}: {text}")
    if diagnostic not in text:
        raise SystemExit(f"missing diagnostic {diagnostic!r}: {text}")


def check_pinned_tree(fixture: Path) -> None:
    """A verbatim copy of scripts/ and the baseline passes; touching the baseline fails."""
    shutil.copytree(ROOT / "scripts", fixture / "scripts")
    (fixture / "audit").mkdir()
    baseline = fixture / "audit/python-quality-baseline.txt"
    shutil.copy2(ROOT / "audit/python-quality-baseline.txt", baseline)
    expect(True, "python-quality ok", "--root", str(fixture))
    original = baseline.read_text(encoding="utf-8")
    baseline.write_text(original + "# bypass\n", encoding="utf-8")
    expect(False, "does not match pinned blob", "--root", str(fixture))
    baseline.write_text(original, encoding="utf-8")
    baseline.write_bytes(original.replace("\n", "\r\n").encode("utf-8"))
    expect(True, "python-quality ok", "--root", str(fixture))
    baseline.write_text(original, encoding="utf-8")


def check_ratchet(fixture: Path) -> None:
    scripts = fixture / "scripts"
    override = fixture / "override.txt"
    shutil.copy2(fixture / "audit/python-quality-baseline.txt", override)
    args = ("--root", str(fixture), "--baseline", str(override))
    expect(True, "python-quality ok", *args)

    dense = scripts / "zz_dense.py"
    dense.write_text(DENSE, encoding="utf-8")
    expect(False, "zz_dense.py:dense = 24, limit 22, and it is not baseline debt", *args)
    dense.write_text("dense = lambda x: " + DENSE_BODY + "\n", encoding="utf-8")
    expect(False, "zz_dense.py:dense = 24, limit 22, and it is not baseline debt", *args)
    dense.write_text("callbacks = [lambda x: " + DENSE_BODY + "]\n", encoding="utf-8")
    expect(False, "zz_dense.py:lambda@1 = 24, limit 22, and it is not baseline debt", *args)
    dense.write_text("def f(cb=lambda x: " + DENSE_BODY + "):\n    return cb\n", encoding="utf-8")
    expect(False, "zz_dense.py:f.lambda@1 = 24, limit 22, and it is not baseline debt", *args)
    dense.write_text("chain = lambda x: x" + "".join(f" < {i}" for i in range(24)) + "\n",
                     encoding="utf-8")
    expect(False, "zz_dense.py:chain = 24, limit 22, and it is not baseline debt", *args)
    dense.write_text("def f():\n    return (lambda x: " + DENSE_BODY + ")\n", encoding="utf-8")
    expect(False, "zz_dense.py:f.lambda@2 = 24, limit 22, and it is not baseline debt", *args)
    if sys.version_info >= (3, 12):
        dense.write_text("def f[T: (lambda x: " + DENSE_BODY + ")]():\n    return 1\n", encoding="utf-8")
        expect(False, "zz_dense.py:f.lambda@1 = 24, limit 22, and it is not baseline debt", *args)
        dense.write_text("class K[T: (lambda x: " + DENSE_BODY + ")]:\n    pass\n", encoding="utf-8")
        expect(False, "zz_dense.py:K.lambda@1 = 24, limit 22, and it is not baseline debt", *args)
    dense.write_text("\n".join("if True:\n    pass" for _ in range(22)) + "\n", encoding="utf-8")
    expect(False, "zz_dense.py:<module> = 23, limit 22, and it is not baseline debt", *args)
    dense.write_text("class C:\n" + "".join("    if True:\n        pass\n" for _ in range(22)), encoding="utf-8")
    expect(False, "zz_dense.py:C = 23, limit 22, and it is not baseline debt", *args)
    dense.write_text("def f(x):\n    match x:\n        case " + " | ".join(str(n) for n in range(23)) + ":\n            pass\n        case _:\n            pass\n", encoding="utf-8")
    expect(False, "zz_dense.py:f = 24, limit 22, and it is not baseline debt", *args)
    dense.write_text("def f(x, enabled):\n    match x:\n" + "".join(f"        case {n} if enabled:\n            pass\n" for n in range(11)) + "        case _:\n            pass\n", encoding="utf-8")
    expect(False, "zz_dense.py:f = 23, limit 22, and it is not baseline debt", *args)
    dense.write_text("def f(x, enabled):\n" + "".join(
        "    match x:\n        case _ if enabled:\n            pass\n" for _ in range(22)), encoding="utf-8")
    expect(False, "zz_dense.py:f = 23, limit 22, and it is not baseline debt", *args)
    dense.write_text("from __future__ import annotations\ncallback: (lambda x: " + DENSE_BODY + ") = None\n", encoding="utf-8")
    expect(True, "python-quality ok", *args)
    if sys.version_info >= (3, 12):
        dense.write_text("def f():\n" + "".join(f"    type A{n} = int if missing else str\n" for n in range(21)), encoding="utf-8")
        expect(True, "python-quality ok", *args)
        dense.write_text("type Callback = (lambda x: " + DENSE_BODY + ")\n", encoding="utf-8")
        expect(False, "zz_dense.py:lambda@1 = 24, limit 22, and it is not baseline debt", *args)
    long = scripts / "zz_long.py"
    long.write_text("# pad\n" * 501, encoding="utf-8")
    dense.unlink()
    expect(False, "zz_long.py = 501, limit 500, and it is not baseline debt", *args)
    long.unlink()

    nested = scripts / "nested" / "zz_dense.py"
    nested.parent.mkdir()
    nested.write_text(DENSE, encoding="utf-8")
    expect(False, "nested/zz_dense.py:dense = 24, limit 22, and it is not baseline debt", *args)
    shutil.rmtree(nested.parent)

    rows = override.read_text(encoding="utf-8")
    override.write_text(rows.replace("audit_metadata.py:rendered 30", "audit_metadata.py:rendered 29"), encoding="utf-8")
    expect(False, "audit_metadata.py:rendered = 30 grew past its baseline 29", *args)
    override.write_text(rows.replace("audit_metadata.py:rendered 30", "audit_metadata.py:rendered 31"), encoding="utf-8")
    expect(False, "audit_metadata.py:rendered = 30 is below its baseline 31; lower the row to 30", *args)
    override.write_text(rows + "zz_gone.py:missing 40\n", encoding="utf-8")
    expect(False, "baseline row zz_gone.py:missing names nothing in scripts/; delete it and re-pin", *args)
    override.write_text(rows + "check_import_dag.py:layer_of 30\n", encoding="utf-8")
    expect(False, "check_import_dag.py:layer_of = 18 is under the limit; delete its baseline row and re-pin", *args)
    override.write_text(rows + "malformed row here\n", encoding="utf-8")
    expect(False, "expected `<file>[:<qualified.function>] <value>`", *args)
    override.unlink()
    expect(False, "missing baseline", *args)

    written = fixture / "written.txt"
    expect(True, "pin BASELINE_BLOB =", "--root", str(fixture), "--baseline", str(written), "--write-baseline")
    if written.read_text(encoding="utf-8") != rows:
        raise SystemExit("--write-baseline did not reproduce the checked-in baseline")


def check_metric() -> None:
    source = ("def f(a, b):\n    if a and b:\n        return [x for x in a if x]\n"
              "    for _ in b:\n        pass\n    while a:\n        a = a if b else 0\n"
              "    try:\n        pass\n    except ValueError:\n        pass\n"
              "    match a:\n        case 1:\n            pass\n        case _:\n            pass\n"
              "    with open(b):\n        pass\n    assert a\n"
              "    def inner(c):\n        return c if a else b\n"
              "    assert 0 <= a < b <= 9\n"
              "    return (lambda d: d if a else b)(0)\n")
    (function,) = ast.parse(source).body
    if check_python_quality.complexity(function) != 15:
        raise SystemExit(f"complexity metric drifted: {check_python_quality.complexity(function)}")
    names = [name for name, _ in check_python_quality.functions(ast.parse(source))]
    if names != ["f", "f.inner", "f.lambda@23"]:
        raise SystemExit(f"scope qualification drifted: {names}")
    outside = ("def deco(f):\n    return f\n"
               "@(deco if True else deco)\n"
               "def simple(x=(1 if True else 2), *, y: (int if True else str) = 3) -> (int if True else str):\n"
               "    return x\n"
               "dense = lambda x: x if x else 0\n"
               "class K:\n    pick = lambda self, x: x if x else 1\n"
               "a, b = (lambda: 1), 2\n"
               "callbacks = [lambda x: x if x else 0, lambda y: y]\n"
               "def g(cb=lambda z: z if z else 0):\n    return cb(lambda w: w if w else 1)\n"
               "k = lambda: (lambda: 1 if True else 0)\n")
    measured = {name: check_python_quality.complexity(node)
                for name, node in check_python_quality.functions(ast.parse(outside))}
    if measured != {"deco": 1, "simple": 1, "dense": 2, "K.pick": 2, "lambda@9": 1,
                    "lambda@10": 2, "lambda@10#2": 1, "g": 1, "g.lambda@11": 2, "g.lambda@12": 2,
                    "k": 1, "lambda@13": 2}:
        raise SystemExit(f"decorator/default/annotation or lambda accounting drifted: {measured}")
    nested = ("def outer(flag):\n"
              "    def inner(x=(1 if flag else 2),\n"
              "                                      cb=lambda z=(5 if flag else 6): z if z else 0):\n"
              "        return x if flag else 0\n"
              "    class C:\n        v = 1 if flag else 2\n        w = lambda self: 7 if flag else 8\n"
              "        def m(self, y=(3 if flag else 4)):\n            return y if flag else 0\n"
              "    return inner, C\n")
    measured = {name: check_python_quality.complexity(node)
                for name, node in check_python_quality.functions(ast.parse(nested))}
    if measured != {"outer": 3, "outer.inner": 2, "outer.inner.lambda@3": 2, "outer.C.w": 2,
                    "outer.C.m": 2}:
        raise SystemExit("nested setup fields are not charged to the enclosing function, or a "
                         f"listed lambda's body is charged twice: {measured}")
    plain = ast.parse("def outer(flag):\n    def inner(x: int if flag else str):\n        pass\n")
    deferred = ast.parse("from __future__ import annotations\ndef outer(flag):\n    def inner(x: int if flag else str):\n        pass\n")
    if check_python_quality.complexity(plain.body[0]) != 2:
        raise SystemExit("runtime annotations were not charged to their enclosing scope")
    if check_python_quality.complexity(deferred.body[1], check_python_quality.postponed_annotations(deferred)) != 1:
        raise SystemExit("postponed annotations were charged to their enclosing scope")
    deferred_lambda = ast.parse("from __future__ import annotations\ndef f(x: (lambda y: y if y else 0)):\n    pass\n")
    if [name for name, _ in check_python_quality.functions(deferred_lambda)] != ["f"]:
        raise SystemExit("a postponed annotation created a runtime lambda scope")
    nested_or = ast.parse("def f(x):\n    match x:\n        case [0 | 1] | [2 | 3]:\n            pass\n        case _:\n            pass\n").body[0]
    if check_python_quality.complexity(nested_or) != 5:
        raise SystemExit("nested MatchOr alternatives were not counted recursively")
    if sys.version_info >= (3, 12):
        generic = ast.parse("def f[T: (lambda q: q if q else 0)]():\n    return 1\n")
        generic_names = [name for name, _ in check_python_quality.functions(generic)]
        if generic_names != ["f", "f.lambda@1"]:
            raise SystemExit(f"generic type-parameter traversal drifted: {generic_names}")
    (annotated,) = [node for node in ast.parse("g: int = lambda: 1 if True else 0\n").body]
    if check_python_quality.assigned_name(annotated) != "g":
        raise SystemExit("an annotated lambda assignment lost its name")
    (tupled,) = ast.parse("(a, b) = lambda: 1, 2\n").body if False else [ast.parse("(a, b) = lambda: 1\n").body[0]]
    if check_python_quality.assigned_name(tupled) != "lambda@1":
        raise SystemExit("a lambda without a single-name target should be keyed by its line")


def check_scoping(fixture: Path) -> None:
    """Same-named and nested definitions are measured on their own."""
    scripts = fixture / "scripts"
    override = fixture / "override.txt"
    shutil.copy2(fixture / "audit/python-quality-baseline.txt", override)
    args = ("--root", str(fixture), "--baseline", str(override))
    scoped = scripts / "zz_scoped.py"
    scoped.write_text(SCOPED, encoding="utf-8")
    ok, text = invoke(*args)
    if ok:
        raise SystemExit("same-named and nested dense functions passed the gate")
    for expected in ("zz_scoped.py:A.dense = 24", "zz_scoped.py:outer.dense = 24", "zz_scoped.py:dense = 24"):
        if expected not in text:
            raise SystemExit(f"missing {expected!r}: {text}")
    for hidden in ("zz_scoped.py:outer =", "zz_scoped.py:B.dense", "zz_scoped.py:dense#2"):
        if hidden in text:
            raise SystemExit(f"a simple definition was charged with its neighbour's branches: {hidden}")
    scoped.unlink()
    override.unlink()


def check_scope_ownership() -> None:
    """A module, class, function, and lambda each own only their executable body."""
    tree = ast.parse("if flag:\n    pass\nclass C:\n    if flag:\n        pass\n    f = lambda: 1 if flag else 0\n    def method():\n        return 1 if flag else 0\n")
    measured = {name: check_python_quality.complexity(node)
                for name, node in check_python_quality.scopes(tree)}
    expected = {"<module>": 2, "C": 2, "C.f": 2, "C.method": 2}
    if measured != expected:
        raise SystemExit(f"module/class/function/lambda ownership drifted: {measured}")


def check_deferred_surfaces() -> None:
    """Lazy annotations and irrefutable fallbacks do not create false debt."""
    fallback = ast.parse("def f(x):\n" + "".join(
        f"    match x:\n        case {n}:\n            pass\n        case _:\n            pass\n"
        for n in range(11))).body[0]
    if check_python_quality.complexity(fallback) != 12:
        raise SystemExit("irrefutable match fallbacks were counted as decisions")
    guarded = ast.parse("def f(x, enabled):\n" + "".join(
        "    match x:\n        case _ if enabled:\n            pass\n" for _ in range(11))).body[0]
    if check_python_quality.complexity(guarded) != 12:
        raise SystemExit("guarded irrefutable cases counted their guard twice")
    lazy = ast.parse("def outer(flag):\n" + "".join(
        f"    def f{n}(x: int if flag else str):\n        pass\n" for n in range(21)))
    postponed = check_python_quality.postponed_annotations(lazy, (3, 14))
    if not postponed or check_python_quality.complexity(lazy.body[0], postponed) != 1:
        raise SystemExit("Python 3.14 lazy annotations were charged to their enclosing scope")


def check_lazy_type_parameters() -> None:
    """PEP 695 bounds are discoverable syntax, not enclosing control flow."""
    if sys.version_info < (3, 12):
        return
    lazy_bound = ast.parse("def outer(flag):\n" + "".join(
        f"    def f{n}[T: int if flag else str]():\n        pass\n" for n in range(21)))
    if check_python_quality.complexity(lazy_bound.body[0]) != 1:
        raise SystemExit("lazy type-parameter bounds were charged to their enclosing scope")


def check_lazy_type_aliases() -> None:
    """Alias bodies are lazy control flow but still expose callable scopes."""
    if sys.version_info < (3, 12):
        return
    module_aliases = ast.parse("".join(
        f"type A{number} = int if flag else str\n" for number in range(21)))
    if check_python_quality.complexity(module_aliases) != 1:
        raise SystemExit("lazy type-alias bodies were charged to their containing module")
    function_aliases = ast.parse("def outer(flag):\n" + "".join(
        f"    type A{number} = int if flag else str\n" for number in range(21)))
    if check_python_quality.complexity(function_aliases.body[0]) != 1:
        raise SystemExit("lazy type-alias bodies were charged to their containing function")
    alias = ast.parse("type Callback = (lambda x: x if x else 0)\n")
    measured = {name: check_python_quality.complexity(node)
                for name, node in check_python_quality.scopes(alias)}
    if measured != {"<module>": 1, "lambda@1": 2}:
        raise SystemExit(f"lazy alias lambda inventory drifted: {measured}")


with tempfile.TemporaryDirectory() as tmp:
    fixture = Path(tmp)
    check_pinned_tree(fixture)
    check_ratchet(fixture)
    check_scoping(fixture)
check_metric()
check_scope_ownership()
check_deferred_surfaces()
check_lazy_type_parameters()
check_lazy_type_aliases()
print("python-quality mutants ok: pinned baseline, new dense function, new long script, growth "
      "past baseline, stale row, retired-but-listed row, malformed row, missing baseline, "
      "baseline rewrite, nested directories, an un-pinned improvement, scope-qualified and nested definitions, module-level lambdas, body-only traversal, and the branch metric")
