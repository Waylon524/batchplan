# Scoped ecosystem comparison

Registry descriptions were checked on 2026-10-03. This is a limited discovery check, not an exhaustive novelty claim or source-code audit. The search did not identify a directly matching budget-aware record-batch planner; repeat the search before planning a new feature because the ecosystem changes.

## Adjacent packages

- [YM-ai-nb/rectloom 0.1.0](https://mooncakes.io/docs/YM-ai-nb/rectloom@0.1.0) advertises deterministic rectangle packing and layout verification. It addresses geometric layout; BatchPlan partitions ordered records under additive resource and count budgets.
- [mizchi/kagura_core 0.6.0, packing2d](https://mooncakes.io/docs/mizchi/kagura_core@0.6.0/packing2d) advertises 2D rectangle allocation using MaxRects BestShortSideFit, with width/height input and x/y output. BatchPlan models scalar cost dimensions, stable input IDs and atomic record groups rather than spatial rectangles.
- [mjfmjf879/moonbit_constraint 0.1.0](https://mooncakes.io/docs/mjfmjf879/moonbit_constraint@0.1.0) advertises general finite-domain constraint programming. BatchPlan supplies a bounded ready-to-use next-fit policy, structured diagnostics, portable manifests and an independently implemented safety validator. It is not a general solver.

The comparison reflects inspected registry metadata. It does not assert these projects' implementations cannot express batching, and does not establish that no related package exists.

## Deliberate reuse and omitted scope

The library reuses MoonBit's core JSON parser, typed decoder and primitive encoder. It implements a small domain-specific assignment CSV exporter rather than a generic CSV framework. It does not add a tokenizer, HTTP client, scheduler, retry engine, service-specific SDK, globally optimal bin-packing solver or distributed execution system.
