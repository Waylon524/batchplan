# Three reproducible workflows

All records are synthetic and all limits are illustrative. These are local planning demonstrations, not live integrations or vendor-specific recommendations. No network requests are made.

## 1. Embedding request planning

`embedding_requests.json` supplies two independent dimensions: caller-calculated tokens and encoded payload bytes. Six records become three batches, respecting a three-record cap, token cap and payload cap. The caller must use the target model's tokenizer and actual wire encoding outside BatchPlan. The example accounts for a 40-byte request envelope and 12 bytes per record.

Expected original positions: `[0,1]`, `[2,3,4]`, `[5]`. Totals: `[90,714]`, `[95,676]`, `[0,72]`.

## 2. Database bulk payloads

`database_bulk.json` preserves the order of six rows. Three adjacent records belonging to `order-42` form an atomic group. That group cannot fit behind the first record, so it moves intact to the next batch. Overhead includes a 16-byte envelope and 2 bytes per record. Grouping constrains planning only; it does not establish a database transaction or execute an import.

Expected positions: `[0]`, `[1,2,3]`, `[4,5]`. Byte totals: `108`, `192`, `240`.

## 3. Export shard planning

`export_shards.json` uses caller-estimated byte counts and a three-record cap. A record with zero declared bytes still counts as one item. The example includes a 64-byte file header and one byte per record. Actual serialized sizes must be measured by the caller when hard byte limits matter.

Expected positions: `[0,1]`, `[2,3]`, `[4,5]`. Totals: `966`, `166`, `956`.

## Run

```sh
moon build --target js
python3 scripts/test_examples.py
moon run cmd/main --target js -- plan < examples/embedding_requests.json
moon run cmd/main --target js -- csv < examples/database_bulk.json
```

`expected.json` contains hand-calculated expected assignments and totals. The runner checks them, independently recomputes totals in Python, asks the MoonBit verifier to check the manifest, and roundtrips each CSV with Python's standard CSV reader.
