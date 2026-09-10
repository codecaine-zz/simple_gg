#!/usr/bin/env python3
"""Compile or run every V code fence in UTILS_API.md."""

import argparse
from dataclasses import dataclass
from pathlib import Path
import re
import subprocess
import sys
import tempfile

SECTION_RE = re.compile(r"^# ([a-z][a-z0-9_]*) API$")


@dataclass
class Example:
    line: int
    module: str | None
    code: str


def extract_examples(document: Path) -> tuple[list[Example], dict[str, list[str]]]:
    examples: list[Example] = []
    module_imports: dict[str, list[str]] = {}
    module: str | None = None
    lines = document.read_text().splitlines()
    line_index = 0

    while line_index < len(lines):
        section = SECTION_RE.match(lines[line_index])
        if section:
            module = section.group(1)
            module_imports[module] = []

        if lines[line_index] != "```v":
            line_index += 1
            continue

        start_line = line_index + 2
        line_index += 1
        code: list[str] = []
        while line_index < len(lines) and lines[line_index] != "```":
            code.append(lines[line_index])
            line_index += 1
        if line_index == len(lines):
            raise ValueError(f"Unclosed V code fence starting on line {start_line - 1}")
        code_text = "\n".join(code)
        import_lines = [line for line in code if line.startswith("import ")]
        non_import_lines = [
            line for line in code if line.strip() and not line.startswith("import ")
        ]
        if module is not None and import_lines and not non_import_lines:
            module_imports[module] = import_lines
        examples.append(Example(start_line, module, code_text))
        line_index += 1

    return examples, module_imports


def make_source(example: Example, module_imports: dict[str, list[str]]) -> str:
    code_imports = [
        line for line in example.code.splitlines() if line.startswith("import ")
    ]
    uses_module = example.module is not None and f"{example.module}." in example.code
    needs_module_imports = not code_imports or uses_module
    inherited_imports = (
        module_imports.get(example.module or "", []) if needs_module_imports else []
    )
    prefix_imports = [line for line in inherited_imports if line not in code_imports]
    prefix = "\n".join(prefix_imports)
    if prefix:
        prefix += "\n\n"
    return f"{prefix}{example.code}\n"


def validate_example(
    example: Example,
    module_imports: dict[str, list[str]],
    root: Path,
    run: bool,
    timeout: float,
) -> str | None:
    with tempfile.TemporaryDirectory(
        prefix=".utils_api_example_", dir=root
    ) as temp_dir:
        source_path = Path(temp_dir) / "example.v"
        source_path.write_text(make_source(example, module_imports))
        command = ["v", "run" if run else "-check", str(source_path)]
        try:
            result = subprocess.run(
                command, cwd=temp_dir, text=True, capture_output=True, timeout=timeout
            )
        except subprocess.TimeoutExpired:
            return f"timed out after {timeout:g} seconds"
        if result.returncode == 0:
            return None
        return (result.stdout + result.stderr).strip()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--run", action="store_true", help="execute examples after compiling them"
    )
    parser.add_argument("--limit", type=int, help="validate only the first N examples")
    parser.add_argument(
        "--timeout",
        type=float,
        default=10,
        help="maximum seconds per example (default: 10)",
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    examples, module_imports = extract_examples(root / "UTILS_API.md")
    if args.limit is not None:
        examples = examples[: args.limit]

    failures: list[tuple[Example, str]] = []
    for example in examples:
        error = validate_example(example, module_imports, root, args.run, args.timeout)
        if error is not None:
            failures.append((example, error))

    mode = "ran" if args.run else "compiled"
    print(f"{mode.capitalize()} {len(examples)} V examples; {len(failures)} failed.")
    for example, error in failures:
        module = example.module or "unknown module"
        print(f"\n{module} example at UTILS_API.md:{example.line}")
        print(error)

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
