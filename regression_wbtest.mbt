///|
test "JSON object keys use lexical order across backends" {
  let output = plan([item("a", 1)], simple_budget(2, 2))
    .unwrap()
    .to_json_string()
  assert_eq(
    output, "{\"batches\":[{\"id\":\"batch-1\",\"indices\":[0],\"item_ids\":[\"a\"],\"totals\":[1]}],\"schema_version\":1,\"strategy\":\"next-fit-preserve-order\"}",
  )
  assert_eq(
    issues_json([issue("bad", 0, 1, "test")]),
    "[{\"code\":\"bad\",\"dimension\":1,\"index\":0,\"message\":\"test\"}]",
  )
}

///|
test "wire preflight ignores escaped string contents but forbids exponent costs" {
  let request : Request = {
    budget: simple_budget(10, 2),
    items: [item("quote\\\"e-1.5 [ ]", 4)],
  }
  let text = stable_json(@json.to_json(request))
  assert_eq(parse_request(text), Ok(request))
  for value in ["4.0", "4e0", "4E+0", "4.0000000000000001"] {
    assert_true(
      parse_request(text.replace(old="[4]", new="[" + value + "]")) is Err(_),
    )
  }
  assert_true(parse_request("[".repeat(65) + "0" + "]".repeat(65)) is Err(_))
}

///|
test "dimension names must be unique nonblank and nonempty" {
  let budget = simple_budget(10, 3)
  assert_true(
    has_code(
      validate_input([], { ..budget, dimensions: [" "], }),
      "blank_dimension",
    ),
  )
  assert_true(
    has_code(
      validate_input([], {
        ..budget,
        dimensions: ["x", "x"],
        limits: [1, 1],
        item_overhead: [0, 0],
        batch_overhead: [0, 0],
      }),
      "duplicate_dimension",
    ),
  )
  assert_eq(
    codes(
      validate_input([], {
        ..budget,
        dimensions: [],
        limits: [],
        batch_overhead: [],
        item_overhead: [],
      }),
    ),
    ["no_dimensions"],
  )
}

///|
test "verifier detects stale costs and order and rejects malformed source input" {
  let input = [item("a", 2), item("b", 3)]
  let budget = simple_budget(10, 5)
  let original = plan(input, budget).unwrap()
  assert_true(
    has_code(
      verify([item("a", 3), item("b", 3)], budget, original),
      "totals_mismatch",
    ),
  )
  let reversed = {
    ..original,
    batches: [{ ..original.batches[0], indices: [1, 0], item_ids: ["b", "a"], }],
  }
  assert_true(has_code(verify(input, budget, reversed), "source_order"))
  assert_true(
    has_code(verify([item("a", -1)], budget, original), "negative_cost"),
  )
}

///|
test "zero resource limits still respect item caps and groups with overhead" {
  let budget = simple_budget(0, 2)
  let input = [item("a", 0), item("b", 0), item("c", 0)]
  assert_eq(plan(input, budget).unwrap().batches.map(fn(b) { b.indices }), [
    [0, 1],
    [2],
  ])
  let grouped_input = [grouped("a", 3, "g"), grouped("b", 3, "g")]
  let overhead = {
    ..simple_budget(9, 2),
    batch_overhead: [2],
    item_overhead: [1],
  }
  match plan(grouped_input, overhead) {
    Err(errors) => assert_true(has_code(errors, "oversized_group_cost"))
    Ok(_) => fail("overhead must count for every group member")
  }
}
