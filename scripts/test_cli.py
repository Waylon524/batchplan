#!/usr/bin/env python3
"""Black-box tests of the compiled MoonBit CLI; uses Python standard library only."""
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CANDIDATES = list((ROOT / '_build/js').glob('**/cmd/main/main.js'))
if not CANDIDATES:
    raise SystemExit('Build the CLI first: moon build --target js')
CLI = max(CANDIDATES, key=lambda path: path.stat().st_mtime)

def run(command, payload):
    return subprocess.run(['node', str(CLI), command], input=payload, text=True, capture_output=True)

request = {'budget': {'dimensions': ['bytes'], 'limits': [10], 'max_items': 2,
                     'batch_overhead': [1], 'item_overhead': [1]},
           'items': [{'id': 'a', 'costs': [3], 'group': None},
                     {'id': 'b', 'costs': [4], 'group': None},
                     {'id': 'c', 'costs': [5], 'group': None}]}
text = json.dumps(request)
result = run('plan', text)
assert result.returncode == 0, result.stderr
manifest = json.loads(result.stdout)
assert [batch['totals'] for batch in manifest['batches']] == [[10], [7]]
assert result.stdout == run('plan', text).stdout
verification = {**request, 'manifest': manifest}
result = run('verify', json.dumps(verification))
assert result.returncode == 0 and json.loads(result.stdout) == {'valid': True}
manifest['batches'][0]['totals'][0] = 0
result = run('verify', json.dumps(verification))
assert result.returncode == 2 and 'totals_mismatch' in result.stderr and not result.stdout
result = run('plan', '{')
assert result.returncode == 2 and 'invalid_json' in result.stderr
result = run('plan', text.replace('[3]', '[3.5]'))
assert result.returncode == 2 and 'invalid_integer' in result.stderr
result = run('unknown', text)
assert result.returncode == 2
result = run('csv', text)
assert result.returncode == 0 and '"cost:bytes"' in result.stdout
assert len(result.stdout.splitlines()) == 4
result = run('--help', '')
assert result.returncode == 0 and 'Usage:' in result.stdout
print('CLI smoke: 9 checks passed')
