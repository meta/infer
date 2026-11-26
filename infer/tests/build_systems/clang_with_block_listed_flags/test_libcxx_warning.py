#!/usr/bin/env python3
"""Keep diagnostic and runtime semantics when checking comparator callability."""
import json
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path

infer = Path(sys.argv[1]).resolve()
# Resolve the directory, not the binary: infer picks its integration from the basename of the
# compiler, and the shipped `clang` is a symlink to a versioned binary, so resolving the file
# yields e.g. `clang-21` and infer stops with "Unsupported build command".
compiler = (infer.parent / '../../facebook-clang-plugins/clang/install/bin').resolve() / 'clang'
source = Path(__file__).with_name('disabled_libcxx_warning.cpp')

with tempfile.TemporaryDirectory(prefix='infer-libcxx-warning-') as directory:
    root = Path(directory)
    cases = [(f'cpp{standard}', standard, None, 0, 'warning_contextual_bool')
             for standard in (11, 17, 20)]
    cases += [('false_assert', 20, 'ASSERT_FALSE', 1, 'language assertion must fail'),
              ('direct_comparators', 17, 'DIRECT_COMPARATORS', 0, 'direct_comparator_control'),
              ('error_attr', 20, 'ERROR_ATTRIBUTE', 1, 'diagnostic guard'),
              ('error_macro', 20, 'ERROR_IN_WARNING_MACRO', 1, 'diagnostic guard'),
              ('enabled_warning', 20, 'WARNING_ENABLED', 0, 'diagnostic guard'),
              ('promoted_warning', 20, 'WARNING_AS_ERROR', 1, 'diagnostic guard'),
              ('late_promoted_warning', 20, 'LATE_WARNING_AS_ERROR', 1, 'diagnostic guard'),
              ('matched_warning', 20, 'MATCHING_WARNING_ENABLED', 0, 'specified comparator type'),
              ('matched_error', 20, 'MATCHING_WARNING_AS_ERROR', 1, 'specified comparator type'),
              ('nonmatching_condition', 20, 'NONMATCHING_CONDITION', 1, 'incomplete')]
    for name, standard, define, expected, witness in cases:
        out = root / name
        command = [str(infer), 'capture', '--jobs', '1', '--no-progress-bar',
                   '--results-dir', str(out), '--', str(compiler), '-x', 'c++',
                   f'-std=c++{standard}']
        if define:
            command += ['-D' + define]
        command += ['-c', str(source), '-o', str(root / (name + '.o'))]
        result = subprocess.run(command, capture_output=True, text=True, timeout=120)
        log = result.stdout + result.stderr
        assert (result.returncode != 0) == bool(expected), (name, log)
        if expected or define in ('WARNING_ENABLED', 'MATCHING_WARNING_ENABLED'):
            assert witness in log, (name, log)
        else:
            db = sqlite3.connect(out / 'capture.db')
            names = [p[0] for p in db.execute('select proc_uid from procedures where cfg is not null')]
            db.close()
            assert any(witness in p for p in names), (name, names)
        print('PASS:', name)

    out = root / 'runtime'
    command = [str(infer), 'run', '--pulse-only', '--jobs', '1', '--no-progress-bar',
               '--results-dir', str(out), '--', str(compiler), '-x', 'c++', '-std=c++20',
               '-DRUNTIME_MACRO', '-c', str(source), '-o', str(root / 'runtime.o')]
    result = subprocess.run(command, capture_output=True, text=True, timeout=120)
    assert result.returncode == 0, result.stdout + result.stderr
    reports = json.loads((out / 'report.json').read_text())
    assert any(r['bug_type'] == 'NULLPTR_DEREFERENCE' and
               r['procedure'] == 'runtime_macro_null_bad' for r in reports), reports
    print('PASS: runtime macro is preserved and its null dereference reports')

    # Loading the exporter directly does not promise the injected helper header.
    plugin = (infer.parent / '../../facebook-clang-plugins/libtooling/build/'
              'FacebookClangPlugin.dylib').resolve()
    command = [str(compiler), '-std=c++20', '-fsyntax-only', '-DMATCHING_WARNING_ENABLED',
               '-Xclang', '-load', '-Xclang', str(plugin), '-Xclang', '-add-plugin',
               '-Xclang', 'BiniouASTExporter', '-Xclang', '-plugin-arg-BiniouASTExporter',
               '-Xclang', str(root / 'without-helper.ast'), str(source)]
    result = subprocess.run(command, capture_output=True, text=True, timeout=120)
    log = result.stdout + result.stderr
    assert result.returncode == 0 and 'specified comparator type' in log, log
    assert (root / 'without-helper.ast').stat().st_size > 0
    print('PASS: plugin without helper preserves the original diagnostic')
