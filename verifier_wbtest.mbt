///|
fn has_code(issues : Array[Issue], code : String) -> Bool {
  issues.any(fn(i) { i.code == code })
}

///|
test "verifier accepts generated plans across a deterministic input grid" {
  for limit = 1; limit <= 20; limit = limit + 1 {
    for count = 0; count <= 35; count = count + 1 {
      let input = Array::makei(count, fn(i) {
        item("item-\{i}", (i * 17 + count * 3) % (limit + 1))
      })
      let budget = simple_budget(limit, 1 + count % 7)
      assert_eq(verify(input, budget, plan(input, budget).unwrap()), [])
    }
  }
}

///|
test "verifier detects duplicate missing stale identity and out-of-range assignments" {
  let input = [item("a", 2), item("b", 3)]
  let budget = simple_budget(10, 5)
  let manifest = plan(input, budget).unwrap()
  let bad = {
    ..manifest,
    batches: [
      {
        id: "wrong",
        indices: [0, 0, 99],
        item_ids: ["stale", "a"],
        totals: [99],
      },
    ],
  }
  let errors = verify(input, budget, bad)
  for
    code in [
      "batch_id", "identity_shape", "identity_mismatch", "duplicate_assignment",
      "source_order", "index_bounds", "totals_mismatch", "missing_assignment",
    ] {
    assert_true(has_code(errors, code))
  }
}

///|
test "verifier catches budgets independently of declared totals" {
  let input = [item("a", 6), item("b", 6)]
  let budget = simple_budget(10, 1)
  let bad : Plan = {
    schema_version: 1,
    strategy: "next-fit-preserve-order",
    batches: [
      { id: "batch-1", indices: [0, 1], item_ids: ["a", "b"], totals: [0], },
    ],
  }
  assert_true(has_code(verify(input, budget, bad), "batch_count"))
  assert_true(has_code(verify(input, budget, bad), "batch_capacity"))
}

///|
test "verifier detects split groups unsupported schema and empty batches" {
  let input = [grouped("a", 1, "g"), grouped("b", 1, "g")]
  let bad : Plan = {
    schema_version: 2,
    strategy: "other",
    batches: [
      { id: "batch-1", indices: [0], item_ids: ["a"], totals: [1], },
      { id: "batch-2", indices: [1], item_ids: ["b"], totals: [1], },
      { id: "batch-3", indices: [], item_ids: [], totals: [], },
    ],
  }
  let errors = verify(input, simple_budget(10, 5), bad)
  for
    code in [
      "split_group", "schema_version", "strategy", "empty_batch", "totals_shape",
    ] {
    assert_true(has_code(errors, code))
  }
}
