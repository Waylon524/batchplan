///|
test "next fit preserves order and stable IDs under cost and count limits" {
  let input = [item("a", 4), item("b", 6), item("c", 0), item("d", 1)]
  let output = plan(input, simple_budget(10, 2)).unwrap()
  assert_eq(output.batches.map(fn(b) { b.indices }), [[0, 1], [2, 3]])
  assert_eq(output.batches.map(fn(b) { b.item_ids }), [["a", "b"], ["c", "d"]])
  assert_eq(output.batches.map(fn(b) { b.totals }), [[10], [1]])
  assert_eq(output.batches[1].id, "batch-2")
  assert_eq(plan(input, simple_budget(10, 2)), Ok(output))
}

///|
test "empty input has no batch and multiple dimensions include overhead" {
  assert_eq(plan([], simple_budget(0, 1)).unwrap().batches, [])
  let budget : Budget = {
    dimensions: ["tokens", "bytes"],
    limits: [10, 20],
    max_items: 5,
    batch_overhead: [1, 2],
    item_overhead: [1, 3],
  }
  let input : Array[Item] = [
    { id: "a", costs: [3, 5], group: None, },
    { id: "b", costs: [3, 7], group: None, },
    { id: "c", costs: [1, 1], group: None, },
  ]
  assert_eq(plan(input, budget).unwrap().batches.map(fn(b) { b.totals }), [
    [9, 20],
    [3, 6],
  ])
}

///|
test "integer boundary splits safely and input is not mutated" {
  let costs = [2147483647]
  let input : Array[Item] = [{ id: "a", costs, group: None, }, item("b", 1)]
  let output = plan(input, simple_budget(2147483647, 2)).unwrap()
  assert_eq(output.batches.length(), 2)
  assert_eq(costs, [2147483647])
  output.batches[0].totals[0] = 0
  assert_eq(costs, [2147483647])
}
