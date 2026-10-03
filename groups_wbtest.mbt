///|
fn grouped(id : String, cost : Int, group : String) -> Item {
  { id, costs: [cost], group: Some(group), }
}

///|
test "atomic groups move as one without changing record order" {
  let input = [
    item("a", 4),
    grouped("b", 4, "g"),
    grouped("c", 3, "g"),
    item("d", 1),
  ]
  let output = plan(input, simple_budget(10, 9)).unwrap()
  assert_eq(output.batches.map(fn(b) { b.indices }), [[0], [1, 2, 3]])
  assert_eq(output.batches.map(fn(b) { b.totals }), [[4], [8]])
}

///|
test "noncontiguous groups and oversized atomic units are rejected" {
  match
    plan(
      [grouped("a", 1, "g"), item("b", 1), grouped("c", 1, "g")],
      simple_budget(9, 9),
    ) {
    Err(errors) => assert_eq(codes(errors), ["noncontiguous_group"])
    Ok(_) => fail("must reject a reopened group")
  }
  match
    plan([grouped("a", 6, "g"), grouped("b", 6, "g")], simple_budget(10, 1)) {
    Err(errors) =>
      assert_eq(codes(errors), ["oversized_group_count", "oversized_group_cost"])
    Ok(_) => fail("must not split an oversized group")
  }
}

///|
test "group cost summation is overflow safe at Int maximum" {
  match
    plan(
      [grouped("a", 2147483647, "g"), grouped("b", 1, "g")],
      simple_budget(2147483647, 5),
    ) {
    Err(errors) => assert_eq(codes(errors), ["oversized_group_cost"])
    Ok(_) => fail("must reject an overflowing group")
  }
}
