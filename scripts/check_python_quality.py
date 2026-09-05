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


def type_alias(node: ast.AST) -> bool:
    """Whether *node* is the version-dependent PEP 695 type-alias node."""
    # ast.TypeAlias is absent on 3.10 and 3.11.  Its spelling is stable, and
    # checking the instance name keeps this checker importable on both.
    return type(node).__name__ == "TypeAlias"


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


def annotation_fields(arguments: ast.arguments) -> list[ast.AST]:
    """Annotations that can be evaluated lazily, outside callable creation."""
    fields = [argument.annotation for argument in
              [*arguments.posonlyargs, *arguments.args, *arguments.kwonlyargs]
              if argument.annotation is not None]
    if arguments.vararg is not None and arguments.vararg.annotation is not None:
        fields.append(arguments.vararg.annotation)
    if arguments.kwarg is not None and arguments.kwarg.annotation is not None:
        fields.append(arguments.kwarg.annotation)
    return fields


def annotation_scope(fields: list[ast.AST]) -> ast.Module:
    """The executable PEP 649 thunk represented by its annotation expressions."""
    return ast.Module(body=[ast.Expr(value=field) for field in fields], type_ignores=[])


def assignment_annotation(node: ast.AST, lazy: bool, annotation_owner: bool) -> list[ast.AST]:
    """The PEP 649 annotation an assignment owner evaluates, if any."""
    if lazy and annotation_owner and isinstance(node, ast.AnnAssign):
        return [node.annotation]
    return []


def local_annotations(node: ast.AST) -> list[ast.AST]:
    """Annotations evaluated by a module or class annotation thunk.

    PEP 649's generated thunk covers annotations reached through the owner's
    control-flow statements, but not annotations belonging to nested lexical
    function or class scopes.
    """
    if not isinstance(node, (ast.Module, ast.ClassDef)):
        return []
    found: list[ast.AST] = []

    def visit(children) -> None:
        for child in children:
            if isinstance(child, (FUNCTIONS, ast.ClassDef)):
                continue
            if isinstance(child, ast.AnnAssign):
                found.append(child.annotation)
            visit(ast.iter_child_nodes(child))

    visit(node.body)
    return found


def setup_fields(node: ast.AST, postponed: bool) -> list[ast.AST]:
    """Expressions a definition evaluates in its enclosing executable scope."""
    if isinstance(node, FUNCTIONS):
        # PEP 695 bounds and constraints are lazy.  They can contain callable
        # syntax that `scopes` inventories, but none of their control flow is
        # executed while this definition is created.
        fields = [*node.decorator_list, *argument_fields(node.args, postponed)]
        if not postponed and node.returns is not None:
            fields.append(node.returns)
        return fields
    if isinstance(node, ast.ClassDef):
        return [*node.decorator_list, *node.bases, *node.keywords]
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
        if type_alias(node):
            # A PEP 695 alias evaluates its value lazily; neither its value
            # nor its type parameters are executable control flow here.
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


def irrefutable_pattern(pattern: ast.AST) -> bool:
    """Whether an unguarded match pattern cannot fall through."""
    if isinstance(pattern, ast.MatchAs):
        return pattern.pattern is None or irrefutable_pattern(pattern.pattern)
    if isinstance(pattern, ast.MatchOr):
        return any(irrefutable_pattern(part) for part in pattern.patterns)
    return False


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
            # An irrefutable pattern cannot fall through, whether or not it
            # has a guard.  Its guard is still one separately evaluated
            # decision below; charging the case here as well would count it
            # twice.
            count += sum(not irrefutable_pattern(case.pattern) for case in node.cases)
            count += sum(pattern_alternatives(case.pattern) + (case.guard is not None)
                         for case in node.cases)
    return count


def future_annotations(tree: ast.Module) -> bool:
    """Whether annotations are stringized by ``__future__.annotations``."""
    for statement in tree.body:
        if isinstance(statement, ast.ImportFrom) and statement.module == "__future__":
            if any(alias.name == "annotations" for alias in statement.names):
                return True
        elif not isinstance(statement, ast.Expr) or not isinstance(statement.value, ast.Constant):
            break
    return False


def postponed_annotations(tree: ast.Module, runtime_version=None) -> bool:
    """Whether this module's annotations are deferred by its runtime or future import."""
    if runtime_version is None:
        runtime_version = sys.version_info
    # PEP 649 makes annotations lazy by default starting with Python 3.14.
    return runtime_version >= (3, 14) or future_annotations(tree)


def lazy_annotations(tree: ast.Module, runtime_version=None) -> bool:
    """Whether deferred annotations retain executable objects under PEP 649."""
    if runtime_version is None:
        runtime_version = sys.version_info
    return runtime_version >= (3, 14) and not future_annotations(tree)


def scopes(tree: ast.Module, postponed: bool = False, lazy: bool = False) -> list[tuple[str, ast.AST]]:
    """Module, class, function, and lambda scopes with stable qualified keys.

    Methods carry their class, local functions carry their parent, and every
    lambda counts as a function under the name it is bound to or its line,
    wherever it appears in an evaluated or PEP-649-lazy expression (module
    or class level, a decorator, a type parameter, a default value, an
    annotation, or a function body); a name
    defined twice in the same scope carries an ordinal, so no definition can
    hide behind another that shares its bare name.
    """
    found: list[tuple[str, ast.AST]] = [("<module>", tree)]
    seen: dict[str, int] = {}

    def record(scope: list[str], name: str, node: ast.AST) -> None:
        qualified = ".".join([*scope, name])
        seen[qualified] = seen.get(qualified, 0) + 1
        bound = qualified if seen[qualified] == 1 else f"{qualified}#{seen[qualified]}"
        found.append((bound, node))
        if lazy and isinstance(node, (*FUNCTIONS, ast.ClassDef)):
            fields = (annotation_fields(node.args) +
                      ([node.returns] if node.returns is not None else [])
                      if isinstance(node, FUNCTIONS) else local_annotations(node))
            if fields:
                record([bound], "__annotate__", annotation_scope(fields))

    def visit(children, scope: list[str], annotation_owner: bool) -> None:
        for child in children:
            if isinstance(child, FUNCTIONS):
                record(scope, child.name, child)
                inner = [*scope, child.name]
                visit(argument_fields(child.args, postponed), inner, False)
                visit([*child.decorator_list, *type_params(child),
                       *([child.returns] if not postponed and child.returns is not None else []),
                       *(annotation_fields(child.args) if lazy else []),
                       *([child.returns] if lazy and child.returns is not None else [])], inner, False)
                visit(child.body, inner, False)
            elif isinstance(child, ast.ClassDef):
                record(scope, child.name, child)
                inner = [*scope, child.name]
                visit([*child.decorator_list, *type_params(child), *child.bases, *child.keywords], inner, False)
                visit(child.body, inner, True)
            elif type_alias(child):
                # A PEP 695 alias's value and parameters are lazy, so they
                # must not add complexity to the containing executable scope.
                # They can nevertheless contain independently owned lambdas,
                # which are inventory-worthy callable scopes.
                alias_name = child.name.id if isinstance(child.name, ast.Name) else f"alias@{child.lineno}"
                record(scope, f"{alias_name}.__value__", annotation_scope([child.value]))
                visit([*type_params(child), child.value], scope, annotation_owner)
            elif isinstance(child, (ast.Assign, ast.AnnAssign)) and isinstance(child.value, ast.Lambda):
                record(scope, assigned_name(child), child.value)
                # The assigned lambda has just been recorded above, but an
                # evaluated assignment target can itself contain callable
                # syntax (for example, ``callbacks[(lambda x: x)] = ...``).
                # Visit it alongside the RHS's nested syntax so each
                # independently-owned callable remains inventory-visible.
                targets = child.targets if isinstance(child, ast.Assign) else [child.target]
                fields = [*targets, *ast.iter_child_nodes(child.value)]
                fields.extend(assignment_annotation(child, lazy, annotation_owner))
                visit(fields, scope, annotation_owner)
            elif isinstance(child, ast.Lambda):
                record(scope, f"lambda@{child.lineno}", child)
                visit(ast.iter_child_nodes(child), scope, annotation_owner)
            elif postponed and isinstance(child, ast.AnnAssign):
                # Unlike the assigned value, the annotation is not evaluated.
                fields = [part for part in (child.target, child.value) if part is not None]
                fields.extend(assignment_annotation(child, lazy, annotation_owner))
                visit(fields, scope, annotation_owner)
            else:
                visit(ast.iter_child_nodes(child), scope, annotation_owner)

    if lazy:
        fields = local_annotations(tree)
        if fields:
            record([], "__annotate__", annotation_scope(fields))
    visit(ast.iter_child_nodes(tree), [], True)
    return found


def functions(tree: ast.AST) -> list[tuple[str, ast.AST]]:
    """Backward-compatible callable-only view used by the regression harness."""
    postponed = postponed_annotations(tree) if isinstance(tree, ast.Module) else False
    lazy = lazy_annotations(tree) if isinstance(tree, ast.Module) else False
    return [(name, node) for name, node in scopes(tree, postponed, lazy)
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
        for name, node in scopes(tree, postponed, lazy_annotations(tree)):
            found[f"{relative}:{name}"] = complexity(node, postponed)
    return found


def threshold(key: str) -> int:
    return MAX_COMPLEXITY if ":" in key else MAX_LINES


def load_baseline(root: Path, override: Path | None) -> dict[str, int]:
    source = override if override is not None else root / BASELINE
    if not source.is_file():
        fail(f"missing baseline {source}")
    # Git's blob identity is based on normalized LF bytes.  A checkout using
    # core.autocrlf must therefore validate the same pinned baseline.
    content = source.read_bytes().replace(b"\r\n", b"\n")
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
