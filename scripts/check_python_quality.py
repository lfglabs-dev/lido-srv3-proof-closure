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
BASELINE_BLOB = "15b0ca24c348987dcf61dabde5064a29dd31fb4f"
MAX_COMPLEXITY = 22
MAX_LINES = 500
BRANCHES = (ast.If, ast.For, ast.AsyncFor, ast.While, ast.ExceptHandler, ast.With,
            ast.AsyncWith, ast.Assert, ast.IfExp)
FUNCTIONS = (ast.FunctionDef, ast.AsyncFunctionDef)


def fail(message: str) -> None:
    raise SystemExit(f"python-quality check failed: {message}")


def git_blob_id(content: bytes) -> str:
    return hashlib.sha1(f"blob {len(content)}\0".encode() + content).hexdigest()


def type_params(node: ast.AST) -> list[ast.AST]:
    """PEP 695 parameters, when the running Python exposes them."""
    return list(getattr(node, "type_params", []))


def argument_fields(arguments: ast.arguments, postponed: bool) -> list[ast.AST]:
    """Expressions evaluated while a callable is created, not its body."""
    fields = [*arguments.defaults, *arguments.kw_defaults]
    if postponed:
        return [field for field in fields if field is not None]
    fields.extend(argument.annotation for argument in
                  [*arguments.posonlyargs, *arguments.args, *arguments.kwonlyargs]
                  if argument.annotation is not None)
    if arguments.vararg is not None and arguments.vararg.annotation is not None:
        fields.append(arguments.vararg.annotation)
    if arguments.kwarg is not None and arguments.kwarg.annotation is not None:
        fields.append(arguments.kwarg.annotation)
    return [field for field in fields if field is not None]


def setup_fields(node: ast.AST, postponed: bool) -> list[ast.AST]:
    """Expressions a definition evaluates in its enclosing executable scope."""
    if isinstance(node, FUNCTIONS):
        fields = [*node.decorator_list, *type_params(node), *argument_fields(node.args, postponed)]
        if not postponed and node.returns is not None:
            fields.append(node.returns)
        return fields
    if isinstance(node, ast.ClassDef):
        return [*node.decorator_list, *type_params(node), *node.bases, *node.keywords]
    if isinstance(node, ast.Lambda):
        return argument_fields(node.args, postponed)
    return []


def own_nodes(scope: ast.AST, postponed: bool):
    """Nodes executed by exactly one lexical executable scope.

    Module, class, function, and lambda bodies are separate owners.  A nested
    definition contributes only its creation-time setup to the containing
    scope; its body belongs to its own metric.  With postponed annotations,
    annotation expressions are intentionally not runtime-owned by any scope.
    """
    if isinstance(scope, ast.Module):
        pending = list(scope.body)
    elif isinstance(scope, (FUNCTIONS, ast.ClassDef)):
        pending = list(scope.body)
    else:  # Lambda
        pending = [scope.body]
    while pending:
        node = pending.pop()
        if isinstance(node, (FUNCTIONS, ast.ClassDef, ast.Lambda)):
            pending.extend(setup_fields(node, postponed))
            continue
        if postponed and isinstance(node, ast.AnnAssign):
            pending.extend(part for part in [node.target, node.value] if part is not None)
            continue
        yield node
        pending.extend(ast.iter_child_nodes(node))


def pattern_alternatives(pattern: ast.AST) -> int:
    """Additional decisions represented by MatchOr, including nested alternatives."""
    total = 0
    for node in ast.walk(pattern):
        if isinstance(node, ast.MatchOr):
            total += len(node.patterns) - 1
    return total


def complexity(scope: ast.AST, postponed: bool = False) -> int:
    """McCabe cyclomatic complexity of one independently-owned scope."""
    count = 1
    for node in own_nodes(scope, postponed):
        if isinstance(node, BRANCHES):
            count += 1
        elif isinstance(node, ast.BoolOp):
            count += len(node.values) - 1
        elif isinstance(node, ast.Compare):
            # `a < b < c` short-circuits like `a < b and b < c`.
            count += len(node.comparators) - 1
        elif isinstance(node, ast.comprehension):
            count += 1 + len(node.ifs)
        elif isinstance(node, ast.Match):
            count += len(node.cases)
            count += sum(pattern_alternatives(case.pattern) + (case.guard is not None)
                         for case in node.cases)
    return count


def postponed_annotations(tree: ast.Module) -> bool:
    """Whether this module's annotations are deferred by its future import."""
    for statement in tree.body:
        if isinstance(statement, ast.ImportFrom) and statement.module == "__future__":
            if any(alias.name == "annotations" for alias in statement.names):
                return True
        elif not isinstance(statement, ast.Expr) or not isinstance(statement.value, ast.Constant):
            break
    return False


def scopes(tree: ast.Module, postponed: bool = False) -> list[tuple[str, ast.AST]]:
    """Module, class, function, and lambda scopes with stable qualified keys.

    Methods carry their class, local functions carry their parent, and every
    lambda counts as a function under the name it is bound to or its line,
    wherever it appears (module or class level, a decorator, a type
    parameter, a default value, an annotation, or a function body); a name
    defined twice in the same scope carries an ordinal, so no definition can
    hide behind another that shares its bare name.
    """
    found: list[tuple[str, ast.AST]] = [("<module>", tree)]
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
                visit(argument_fields(child.args, postponed), inner)
                visit([*child.decorator_list, *type_params(child),
                       *([child.returns] if not postponed and child.returns is not None else [])], inner)
                visit(child.body, inner)
            elif isinstance(child, ast.ClassDef):
                record(scope, child.name, child)
                inner = [*scope, child.name]
                visit([*child.decorator_list, *type_params(child), *child.bases, *child.keywords], inner)
                visit(child.body, inner)
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


def functions(tree: ast.AST) -> list[tuple[str, ast.AST]]:
    """Backward-compatible callable-only view used by the regression harness."""
    postponed = postponed_annotations(tree) if isinstance(tree, ast.Module) else False
    return [(name, node) for name, node in scopes(tree, postponed)
            if isinstance(node, (*FUNCTIONS, ast.Lambda))]


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
        tree = ast.parse(source)
        postponed = postponed_annotations(tree)
        for name, node in scopes(tree, postponed):
            found[f"{relative}:{name}"] = complexity(node, postponed)
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
    lines = ["# Python quality debt: executable scopes at or above the complexity limit and",
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
    scope_count = sum(1 for key in measured if ":" in key)
    print(f"python-quality ok: {scope_count} executable scopes under cyclomatic {MAX_COMPLEXITY} and "
          f"{len(measured) - scope_count} scripts under {MAX_LINES} lines, except pinned baseline "
          f"debt (blob {BASELINE_BLOB}) which did not grow")


if __name__ == "__main__":
    main()
