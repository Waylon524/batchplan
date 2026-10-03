///|
fn simple_budget(limit : Int, max_items : Int) -> Budget {
  {
    dimensions: ["bytes"],
    limits: [limit],
    max_items,
    batch_overhead: [0],
    item_overhead: [0],
  }
}

///|
fn item(id : String, cost : Int) -> Item {
  { id, costs: [cost], group: None, }
}

///|
fn codes(issues : Array[Issue]) -> Array[String] {
  issues.map(fn(e) { e.code })
}

///|
test "shape and invalid budget rejection" {
  assert_eq(codes(validate_input([], simple_budget(10, 0))), [
    "invalid_max_items",
  ])
  assert_eq(
    codes(validate_input([], { ..simple_budget(10, 1), limits: [], })),
    ["budget_shape"],
  )
  assert_eq(codes(validate_input([], simple_budget(-1, 1))), ["negative_budget"])
  assert_eq(
    codes(validate_input([], { ..simple_budget(10, 1), batch_overhead: [11], })),
    ["overhead_exceeds_limit"],
  )
}

///|
test "metadata cost shape and duplicate IDs have stable diagnostics" {
  assert_eq(
    codes(
      validate_input(
        [
          item("a", -1),
          item("a", 11),
          item(" ", 0),
          { id: "x", costs: [], group: Some(""), },
        ],
        simple_budget(10, 2),
      ),
    ),
    [
      "negative_cost", "duplicate_id", "oversized_item", "blank_id", "blank_group",
      "item_shape",
    ],
  )
}

///|
test "budget accounts for both overheads and zero costs" {
  let budget = {
    ..simple_budget(10, 2),
    batch_overhead: [2],
    item_overhead: [3],
  }
  assert_eq(validate_input([item("a", 5)], budget), [])
  assert_eq(codes(validate_input([item("a", 6)], budget)), ["oversized_item"])
  assert_eq(validate_input([item("a", 0)], simple_budget(0, 1)), [])
}

///|
test "maximum integer validation never adds before checking" {
  let max = 2147483647
  assert_eq(validate_input([item("a", max)], simple_budget(max, 1)), [])
  assert_eq(
    codes(
      validate_input([item("a", max)], {
        ..simple_budget(max, 1),
        item_overhead: [1],
      }),
    ),
    ["oversized_item"],
  )
}
