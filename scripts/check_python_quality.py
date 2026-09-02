#!/usr/bin/env python3
"""Fail closed on Python complexity and file length in `scripts/`.

Every function must keep its cyclomatic complexity below `MAX_COMPLEXITY`
and every script must stay under `MAX_LINES` lines, except for the debt the
pinned baseline `audit/python-quality-baseline.txt` records. Baseline debt may
only shrink, and every shrink is pinned: a listed function or file must
measure exactly its recorded value, an improvement must lower the row, a row
whose subject has dropped under the threshold must be deleted, and each of
those edits re-pins `BASELINE_BLOB` here, where review sees the ceiling
move. Cyclomatic complexity is the enforced proxy for the cognitive and
Halstead targets, which this repository has no tool to measure.
"""

from __future__ import annotations

import argparse
import ast
import hashlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = Path("scripts")
BASELINE = Path("audit/python-quality-baseline.txt")
BASELINE_BLOB = "0de6d422f533265d54f3bbe1e1df6fa77b5ab7b9"
MAX_COMPLEXITY = 22
MAX_LINES = 500
BRANCHES = (ast.If, ast.For, ast.AsyncFor, ast.While, ast.ExceptHandler, ast.With,
            ast.AsyncWith, ast.Assert, ast.IfExp)
FUNCTIONS = (ast.FunctionDef, ast.AsyncFunctionDef)


def fail(message: str) -> None:
    raise SystemExit(f"python-quality check failed: {message}")


def git_blob_id(content: bytes) -> str:
    return hashlib.sha1(f"blob {len(content)}\0".encode() + content).hexdigest()


def own_nodes(function: ast.AST):
    """Every node of a function's body except nested function, lambda and class bodies.

    Only the body counts: a function's own decorators, default values and
    annotations run in the enclosing scope, so they are charged there, and a
    nested definition's setup fields are charged here for the same reason
    while its body is measured on its own (see `functions`). A class body
    nested in a function runs in that function. Every lambda is measured on
    its own wherever it appears, so only its default values are charged
    here. Type parameters (PEP 695 bounds and defaults) are treated like
    default values.
    """
    body = function.body if isinstance(function, FUNCTIONS) else [function.body]
    pending = list(body)
    while pending:
        node = pending.pop()
        if isinstance(node, FUNCTIONS):
            # A nested definition's decorators, defaults and annotations are
            # evaluated by the enclosing function; only its body is its own.
            pending.extend(setup_fields(node))
            continue
        if isinstance(node, ast.ClassDef):
            # A class body runs where the class is defined; its methods do not.
            pending.extend([*node.decorator_list, *node.type_params, *node.bases, *node.keywords,
                            *node.body])
            continue
        if isinstance(node, ast.Lambda):
            pending.append(node.args)
            continue
        yield node
        pending.extend(ast.iter_child_nodes(node))


def setup_fields(function: ast.AST) -> list[ast.AST]:
    """A definition's decorators, type parameters, arguments and return annotation."""
    return [*function.decorator_list, *function.type_params, function.args,
            *([function.returns] if function.returns else [])]


def complexity(function: ast.AST) -> int:
    """McCabe cyclomatic complexity of one function body."""
    count = 1
    for node in own_nodes(function):
        if isinstance(node, BRANCHES):
            count += 1
        elif isinstance(node, ast.BoolOp):
            count += len(node.values) - 1
        elif isinstance(node, ast.comprehension):
            count += 1 + len(node.ifs)
        elif isinstance(node, ast.Match):
            count += len(node.cases)
    return count


def functions(tree: ast.AST) -> list[tuple[str, ast.AST]]:
    """Every function and lambda in a module with its scope-qualified name, in source order.

    Methods carry their class, local functions carry their parent, and every
    lambda counts as a function under the name it is bound to or its line,
    wherever it appears (module or class level, a decorator, a type
    parameter, a default value, an annotation, or a function body); a name
    defined twice in the same scope carries an ordinal, so no definition can
    hide behind another that shares its bare name.
    """
    found: list[tuple[str, ast.AST]] = []
    seen: dict[str, int] = {}

    def record(scope: list[str], name: str, node: ast.AST) -> None:
        qualified = ".".join([*scope, name])
        seen[qualified] = seen.get(qualified, 0) + 1
        found.append((qualified if seen[qualified] == 1 else f"{qualified}#{seen[qualified]}", node))

    def visit(children, scope: list[str]) -> None:
        for child in children:
            if isinstance(child, FUNCTIONS):
                record(scope, child.name, child)
                inner = [*scope, child.name]
                visit(setup_fields(child), inner)
                visit(child.body, inner)
            elif isinstance(child, ast.ClassDef):
                visit(ast.iter_child_nodes(child), [*scope, child.name])
            elif isinstance(child, (ast.Assign, ast.AnnAssign)) and isinstance(child.value, ast.Lambda):
                record(scope, assigned_name(child), child.value)
                visit(ast.iter_child_nodes(child.value), scope)
            elif isinstance(child, ast.Lambda):
                record(scope, f"lambda@{child.lineno}", child)
                visit(ast.iter_child_nodes(child), scope)
            else:
                visit(ast.iter_child_nodes(child), scope)

    visit(ast.iter_child_nodes(tree), [])
    return found


def assigned_name(statement: ast.AST) -> str:
    """The name a lambda is bound to, or its line."""
    targets = statement.targets if isinstance(statement, ast.Assign) else [statement.target]
    if len(targets) == 1 and isinstance(targets[0], ast.Name):
        return targets[0].id
    return f"lambda@{statement.lineno}"


def measure(root: Path) -> dict[str, int]:
    """Map `path:qualified.function` to complexity and `path` to line count.

    Paths are relative to `scripts/` and the walk is recursive, so a script in
    a subdirectory is measured like one at the top.
    """
    found: dict[str, int] = {}
    for path in sorted((root / SCRIPTS).rglob("*.py")):
        source = path.read_text(encoding="utf-8")
        relative = path.relative_to(root / SCRIPTS).as_posix()
        found[relative] = len(source.splitlines())
        for name, node in functions(ast.parse(source)):
            found[f"{relative}:{name}"] = complexity(node)
    return found


def threshold(key: str) -> int:
    return MAX_COMPLEXITY if ":" in key else MAX_LINES


def load_baseline(root: Path, override: Path | None) -> dict[str, int]:
    source = override if override is not None else root / BASELINE
    if not source.is_file():
        fail(f"missing baseline {source}")
    content = source.read_bytes()
    if override is None and git_blob_id(content) != BASELINE_BLOB:
        fail(f"baseline {BASELINE} does not match pinned blob {BASELINE_BLOB}; retire debt by "
             "deleting rows and re-pinning BASELINE_BLOB in scripts/check_python_quality.py")
    rows: dict[str, int] = {}
    for number, raw in enumerate(content.decode("utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) != 2 or not parts[1].isdigit():
            fail(f"{source}:{number}: expected `<file>[:<qualified.function>] <value>`, got {line!r}")
        rows[parts[0]] = int(parts[1])
    return rows


def render_baseline(measured: dict[str, int]) -> str:
    lines = ["# Python quality debt: functions at or above the complexity limit and",
             "# scripts at or above the line limit. Rows may only shrink or disappear;",
             "# deleting a row re-pins BASELINE_BLOB in scripts/check_python_quality.py.", ""]
    for key in sorted(measured):
        if measured[key] >= threshold(key):
            lines.append(f"{key} {measured[key]}")
    return "\n".join(lines) + "\n"


def violations(measured: dict[str, int], baseline: dict[str, int]) -> list[str]:
    problems = []
    for key, value in sorted(measured.items()):
        limit = threshold(key)
        recorded = baseline.get(key)
        if recorded is None:
            if value >= limit:
                problems.append(f"{key} = {value}, limit {limit}, and it is not baseline debt")
        elif value > recorded:
            problems.append(f"{key} = {value} grew past its baseline {recorded}")
        elif limit <= value < recorded:
            problems.append(f"{key} = {value} is below its baseline {recorded}; lower the row to "
                            f"{value} and re-pin so the improvement cannot be undone")
    for key, recorded in sorted(baseline.items()):
        value = measured.get(key)
        if value is None:
            problems.append(f"baseline row {key} names nothing in scripts/; delete it and re-pin")
        elif value < threshold(key):
            problems.append(f"{key} = {value} is under the limit; delete its baseline row and re-pin")
    return problems


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--baseline", type=Path, default=None,
                        help="test-only override for the pinned baseline")
    parser.add_argument("--write-baseline", action="store_true",
                        help="rewrite the baseline from the current tree and exit")
    args = parser.parse_args()
    root = args.root.resolve()
    measured = measure(root)
    if args.write_baseline:
        target = args.baseline if args.baseline is not None else root / BASELINE
        rendered = render_baseline(measured)
        target.write_text(rendered, encoding="utf-8")
        print(f"wrote {target}; pin BASELINE_BLOB = {git_blob_id(rendered.encode('utf-8'))}")
        return
    problems = violations(measured, load_baseline(root, args.baseline))
    if problems:
        fail("; ".join(problems))
    functions = sum(1 for key in measured if ":" in key)
    print(f"python-quality ok: {functions} functions under cyclomatic {MAX_COMPLEXITY} and "
          f"{len(measured) - functions} scripts under {MAX_LINES} lines, except pinned baseline "
          f"debt (blob {BASELINE_BLOB}) which did not grow")


if __name__ == "__main__":
    main()
