#!/usr/bin/env python3
"""Run all three workflows against hand-calculated expectations and an independent Python check."""
import csv
import io
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
cli = max((root / '_build/js').glob('**/cmd/main/main.js'), key=lambda p: p.stat().st_mtime)
expected = json.loads((root / 'examples/expected.json').read_text())
for name, reference in expected.items():
    request = json.loads((root / f'examples/{name}.json').read_text())
    result = subprocess.run(['node', str(cli), 'plan'], input=json.dumps(request), text=True, capture_output=True, check=True)
    manifest = json.loads(result.stdout)
    assert [b['indices'] for b in manifest['batches']] == reference['indices'], name
    assert [b['totals'] for b in manifest['batches']] == reference['totals'], name
    # Deliberately independent arithmetic using Python's arbitrary-precision integers.
    budget, items = request['budget'], request['items']
    seen, groups = [], {}
    for batch_no, batch in enumerate(manifest['batches']):
        assert 0 < len(batch['indices']) <= budget['max_items']
        totals = list(budget['batch_overhead'])
        for slot, index in enumerate(batch['indices']):
            seen.append(index)
            item = items[index]
            assert batch['item_ids'][slot] == item['id']
            for d in range(len(totals)):
                totals[d] += item['costs'][d] + budget['item_overhead'][d]
            if item['group'] is not None:
                assert groups.setdefault(item['group'], batch_no) == batch_no
        assert totals == batch['totals']
        assert all(total <= limit for total, limit in zip(totals, budget['limits']))
    assert seen == list(range(len(items)))
    verify = subprocess.run(['node', str(cli), 'verify'], input=json.dumps({**request, 'manifest': manifest}), text=True, capture_output=True, check=True)
    assert json.loads(verify.stdout) == {'valid': True}
    output = subprocess.run(['node', str(cli), 'csv'], input=json.dumps(request), text=True, capture_output=True, check=True)
    rows = list(csv.DictReader(io.StringIO(output.stdout)))
    assert [row['item_id'] for row in rows] == [item['id'] for item in items]
    print(f'{name}: {len(items)} items -> {len(manifest["batches"])} verified batches; CSV roundtrip passed')
