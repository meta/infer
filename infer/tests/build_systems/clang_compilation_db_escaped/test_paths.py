#!/usr/bin/env python3
# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

"""Check invalid path diagnostics and lossless raw/escaped CDB path handling."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile


def shell_path(path):
    # Double quotes also preserve literal newlines in the shell's printf input.
    escaped = str(path).replace("\\", "\\\\").replace('"', '\\"')
    escaped = escaped.replace("$", "\\$").replace("`", "\\`")
    return '"' + escaped + '"'


def check(infer, temporary):
    source_dir = temporary / "directory with spaces"
    source_dir.mkdir()
    source = source_dir / "source with spaces.c"
    source.write_text("int cdb_bad(void) { int *p = 0; return *p; }\n")
    entry = {
        "directory": str(source_dir),
        "file": str(source),
        "arguments": ["clang", "-c", str(source), "-o", str(temporary / "source.o")],
    }

    def run(name, mode, data, error=None):
        database = temporary / (name + ".json")
        database.write_text(json.dumps([data]))
        results = temporary / name
        result = subprocess.run(
            [
                str(infer),
                "run",
                "--pulse-only",
                "--jobs",
                "1",
                "--no-progress-bar",
                "--results-dir",
                str(results),
                mode,
                str(database),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        if error:
            assert result.returncode != 0, (name, result.stdout)
            assert "Json file doesn't have the expected format" in result.stdout, result.stdout
            assert error in result.stdout, result.stdout
            assert "End_of_file" not in result.stdout, result.stdout
            assert "Uncaught Internal Error" not in result.stdout, result.stdout
        else:
            assert result.returncode == 0, (name, result.stdout)
            issues = json.loads((results / "report.json").read_text())
            assert any(issue["bug_type"] == "NULLPTR_DEREFERENCE" for issue in issues), issues
        print("PASS:", name)

    raw = "--compilation-database"
    escaped = "--compilation-database-escaped"
    encoded = {**entry, "directory": shell_path(source_dir), "file": shell_path(source)}
    run("raw_spaces", raw, entry)
    run("escaped_spaces", escaped, encoded)
    for mode, prefix, original in [(raw, "raw", entry), (escaped, "escaped", encoded)]:
        for field in ["directory", "file"]:
            run(prefix + "_empty_" + field, mode, {**original, field: ""},
                '"' + field + '" field is empty')
            run(prefix + "_null_" + field, mode, {**original, field: None},
                '"' + field + '" field is not a string')
            run(prefix + "_nonstring_" + field, mode, {**original, field: 1},
                '"' + field + '" field is not a string')
    run("quoted_empty", escaped, {**encoded, "file": '""'}, '"file" field is empty')
    run("malformed_escaping", escaped, {**encoded, "file": '"unterminated'},
        'invalid shell escaping in the "file" field')



if __name__ == "__main__":
    with tempfile.TemporaryDirectory(prefix="infer-cdb-paths-") as directory:
        check(Path(sys.argv[1]).resolve(), Path(directory))
