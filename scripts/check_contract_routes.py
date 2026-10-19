#!/usr/bin/env python3
"""Check that every curl call in the api.sh examples is an operation in the contract.

Reads contract/ibee-cloud.yaml (the public API contract) and every api.sh file.
A call's method comes from -X/--request, else POST when it sends data, else GET.
Its path is the part after $API (or an api.ibee.ai/v1 or api.ibee.co.in/v1 URL),
without the query string; shell variables in the path stand for one segment.
Standard library only. Exits 1 and lists the calls that are not in the contract.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "contract" / "ibee-cloud.yaml"
METHODS = {"get", "put", "post", "patch", "delete", "head", "options"}
API_PATH = re.compile(r"""(?:\$\{?API\}?|https://api\.ibee\.(?:ai|co\.in)/v1)(/[^"'\s?]*)""")
METHOD = re.compile(r"(?:-X|--request)\s*['\"]?([A-Za-z]+)")
DATA = re.compile(r"(?:^|\s)(?:-d|--data(?:-raw|-binary|-urlencode)?|--json|-F|--form)(?:\s|=|$)")
SHELL_VAR = re.compile(r"\$\{?\w+\}?")


def contract_operations():
    operations, in_paths, current = [], False, None
    for line in CONTRACT.read_text().splitlines():
        line = line.rstrip()
        if line == "paths:":
            in_paths = True
        elif not in_paths or not line.strip() or line.lstrip().startswith("#"):
            continue
        elif not line.startswith(" "):
            in_paths = False
        elif re.match(r"""^  ['"]?/""", line):
            current = line.strip().rstrip(":").strip("'\"")
        elif re.match(r"^    \w+:", line) and current:
            method = line.strip().rstrip(":")
            if method in METHODS:
                literal = re.split(r"\{[^/{}]+\}", current)
                operations.append((method.upper(), re.compile("^" + "[^/]+".join(map(re.escape, literal)) + "$"), current))
    if not operations:
        sys.exit(f"No operations found in {CONTRACT.relative_to(ROOT)}")
    return operations


def curl_calls(path):
    """Yield (line number, method, API path or None) for each curl command."""
    lines = path.read_text().splitlines()
    i = 0
    while i < len(lines):
        start, command = i + 1, lines[i]
        while command.rstrip().endswith("\\") and i + 1 < len(lines):
            i += 1
            command = command.rstrip()[:-1] + " " + lines[i]
        i += 1
        code = command.split("#", 1)[0] if not command.lstrip().startswith("#") else ""
        if not re.search(r"(?:^|[\s;|&(])curl\s", code):
            continue
        found = API_PATH.findall(code)
        match = METHOD.search(code)
        method = match.group(1).upper() if match else ("POST" if DATA.search(code) else "GET")
        if not found:
            yield start, method, None
        for api_path in found:
            yield start, method, SHELL_VAR.sub("x", api_path)


def main():
    operations = contract_operations()
    files = sorted(p for p in ROOT.rglob("api.sh") if "node_modules" not in p.parts)
    if not files:
        sys.exit("No api.sh files found.")
    problems, checked = [], 0
    for path in files:
        for line, method, api_path in curl_calls(path):
            where = f"{path.relative_to(ROOT)}:{line}"
            if api_path is None:
                problems.append(f"{where}: curl call without an $API path")
                continue
            checked += 1
            if not any(m == method and pattern.match(api_path) for m, pattern, _ in operations):
                problems.append(f"{where}: {method} {api_path} is not an operation in contract/ibee-cloud.yaml")
    if problems:
        print("\n".join(problems))
        sys.exit(1)
    print(f"Checked {checked} API calls in {len(files)} api.sh file(s) against {len(operations)} contract operations.")


if __name__ == "__main__":
    main()
