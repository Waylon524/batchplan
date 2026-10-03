# Design and guarantees

## Core contract

Inputs are ordered records with a unique, nonblank string ID, an array of nonnegative 32-bit integer costs, and an optional group ID. Named budget dimensions, limits, and both overhead vectors have identical lengths. Dimensions must be nonblank and unique. At least one dimension is required; a count-only budget can use a zero-valued dimension. Limits may be zero and `max_items` must be positive.

For each nonempty batch and dimension d:

`total[d] = batch_overhead[d] + sum(item.costs[d] + item_overhead[d])`

The total must not exceed `limits[d]`; number of records must not exceed `max_items`. Zero-cost records still count. Empty input produces no batches. The budget itself must be capable of fitting at least one zero-cost item, even for empty input.

Overhead is caller declared. Include request/file envelopes and per-record framing or separators. If a separator exists only between records, counting one per record is conservative; the library does not infer a wire format or adjust a final separator automatically. Hard limits are guaranteed only with accurate, appropriately conservative caller costs.

## Strategy

`next-fit-preserve-order` scans records from left to right. Each ungrouped record or contiguous group is an atomic unit. Add the unit to the current batch if both count and every cost dimension fit; otherwise close that batch and open the next. No already-closed batch is revisited. The entire request fails if any unit cannot fit on its own; no partial manifest is returned.

All groups must be contiguous. Reopening a group after an ungrouped item or different group is an error. This rule avoids a conflict between global source order and atomicity. Group IDs are exact, case-sensitive strings. Groups describe partitioning constraints only, not database transaction guarantees.

The planner is deterministic for the same ordered input and budget. It does not search for a globally minimum batch count. Source positions are zero-based; batch IDs are `batch-1`, `batch-2`, etc. Identical IDs across input records are rejected, even when their costs differ.

## Overflow safety

MoonBit `Int` is signed 32-bit. Limits/costs/overhead are nonnegative; additions happen only after comparing against remaining capacity using subtraction. The maximum supported dimension value is 2,147,483,647. To work above that bound, choose a documented coarser conservative unit or extend the implementation to checked Int64; do not silently scale or wrap.

## Independent verification

`verify(items,budget,manifest)` checks public input rules and independently scans assignments. It does not invoke `plan`, `plan_units` or `atomic_units`. It checks schema, strategy, batch identifiers, nonempty batches, per-batch count, source bounds/order/coverage/exactly-once assignment, ID alignment, group integrity and recomputed totals including overhead.

It accepts any safe order-preserving grouping satisfying these invariants, including underfilled batches. It does not certify that a supplied manifest was actually produced by next-fit, that batching is optimal, or that estimated costs equal actual serialized sizes. Reverification uses the supplied current input; the manifest is not a cryptographic snapshot. Use content-derived stable IDs or retain the original input alongside the manifest if stronger provenance is needed.

## Boundaries and complexity

- Pure library: no network, filesystem, clock, randomness, tokenizer, vendor SDK, scheduler, retries or side effects
- The CLI has a tiny Node-only stdin/stdout/stderr boundary; Node 22.16+ is required
- Planner and verifier take O(n × d) time for n records and d dimensions, aside from identifier-map operations; stable JSON export sorts object keys
- Inputs and complete plans are held in memory; this is not a streaming planner
- Mutable arrays are public for interoperability. The planner does not mutate input or alias its cost arrays into returned totals, but callers must not concurrently mutate data during a call
- No optimal-packing, throughput, performance benchmark or live integration claim is made

## Wire format and text exports

The standard MoonBit JSON parser/encoder is reused. The domain boundary adds an integer-literal preflight because the standard typed Int decoder accepts fractional values by truncation. This protocol rejects decimal/exponent numeric notation, out-of-range integers and nesting deeper than 64. An absent group or explicit `null` means ungrouped. Unknown object fields are ignored by the standard typed decoder; duplicate keys follow the standard parser's last-value-wins behavior. Produce unambiguous JSON with unique keys.

Object keys in exported JSON are sorted; array order is preserved. This is deterministic serialization, not RFC 8785 or cryptographic canonicalization. CSV is a narrow assignment exporter, not a general CSV parser. It always quotes fields and doubles embedded quotes. It preserves untrusted text exactly, so opening IDs beginning with formula characters in spreadsheet software can be unsafe; use a CSV parser or sanitize separately for spreadsheet display.
