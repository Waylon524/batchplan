# BatchPlan

Deterministic, order-preserving batching with multiple integer budgets, explicit overhead, atomic groups and independent manifest verification. The library is pure MoonBit; the optional CLI uses a small Node.js IO boundary.

## Why

Fixed-count chunks can exceed a payload or token budget. BatchPlan lets the caller declare several costs per record and budget all of them at once. It retains stable item IDs and original positions, so downstream code can execute or audit the plan without losing provenance.

Useful for embedding-request planning, database bulk payloads and export shards. [Three runnable examples](examples/README.md) use synthetic data and illustrative limits. They are not live service integrations.

## Quick start

Requirements: MoonBit stable toolchain, Node.js 22.16+ for the CLI, Python 3 for integration checks. Development verified with moon 0.1.20260920 and moonc v0.10.14+7d59c7ec9. Install MoonBit from its [official download page](https://www.moonbitlang.com/download/).

```sh
moon test --target js
moon run cmd/main --target js -- plan < examples/embedding_requests.json
moon run cmd/main --target js -- csv < examples/database_bulk.json
bash scripts/check.sh
```

The core library also checks, tests and builds for Wasm-GC and native. The CLI is JavaScript-only. No third-party Mooncakes packages are needed; JSON parsing/encoding uses MoonBit's standard library.

## Library example

After copying this local module into your project setup, import `dot-agent/batchplan` as `@batchplan`. That namespace is provisional and has not been published.

```moonbit
let budget : @batchplan.Budget = {
  dimensions: ["tokens", "bytes"],
  limits: [100, 1024],
  max_items: 3,
  batch_overhead: [0, 40],
  item_overhead: [0, 12],
}
let items : Array[@batchplan.Item] = [
  { id: "doc-a", costs: [40, 300], group: None },
  { id: "doc-b", costs: [50, 350], group: None },
  { id: "doc-c", costs: [20, 100], group: None },
]
match @batchplan.plan(items, budget) {
  Ok(manifest) => {
    assert_eq(manifest.batches.length(), 2)
    assert_eq(@batchplan.verify(items, budget, manifest), [])
    println(manifest.to_json_string())
  }
  Err(issues) => println(@batchplan.issues_json(issues))
}
```

This example is compiled as a black-box API test in `api_test.mbt`. See [generated public API](pkg.generated.mbti) for the full interface.

## Guarantees and limits

- Every accepted input record appears once, in original order, with its ID and zero-based source position
- All dimensions and the record-count cap are enforced, including declared per-batch and per-record overhead
- Adjacent records sharing a group stay together; noncontiguous or oversized groups are rejected
- Individual oversized records, malformed costs and duplicate IDs return structured errors; no partial plan is returned
- Arithmetic is checked before adding, including near the signed 32-bit integer maximum
- Independent verification recomputes totals and checks assignments; it does not call the planner

The strategy is next-fit: append to the current batch if it fits, otherwise start the next. It does not optimize global batch count. Costs must be accurate or conservative; BatchPlan does not tokenize text, measure real payloads, send requests, execute database transactions, schedule or retry work. Inputs are held in memory. Read [the precise domain contract](docs/DESIGN.md) and [scoped ecosystem comparison](docs/ECOSYSTEM.md).

## JSON and CLI

`plan` and `csv` read `{ "budget": ..., "items": [...] }` from stdin. `verify` reads the same data plus `"manifest"`. See the complete JSON fixtures under `examples/`.

```sh
moon build --target js
# Or invoke the compiled Node program directly after the build:
node _build/js/debug/build/cmd/main/main.js plan < examples/export_shards.json
node _build/js/debug/build/cmd/main/main.js --help
```

Success uses stdout and exit code 0. Validation or usage failure uses stderr and exit code 2. Runtime/IO failures may use the runtime's error exit code. Verification succeeds with `{"valid":true}`; failures are JSON arrays of `{code,index,dimension,message}`. `index` and `dimension` use -1 when not applicable.

All numeric JSON fields use integer literals, from -2,147,483,648 to 2,147,483,647 at decoding; costs and budgets additionally require nonnegative values. Decimal/exponent notation is rejected rather than truncated. A group may be omitted or `null` for ungrouped records. Output JSON keys are sorted deterministically. CSV preserves text exactly; do not open untrusted formula-like IDs directly in spreadsheets.

## Development and release status

`bash scripts/check.sh` checks formatting, checks/tests/builds the core on JS/Wasm-GC/native, tests release JS, generates API signatures, and runs CLI and three-example integration checks. A GitHub Actions workflow is prepared; no hosted run has occurred because this repository is local-only. CI follows the current stable official toolchain and prints its exact version.

The prototype was implemented with AI assistance. Commits use an explicit AI-assistant identity and actual timestamps. No public repository, package registration/publication or competition submission was performed. Provisional namespace and license require owner decisions. MIT is proposed for review; no license grant has been activated. See [owner review checklist](docs/OWNER_REVIEW.md), [中文上手指南](docs/QUICKSTART.zh-CN.md), and [verification report](docs/VERIFICATION.md).
