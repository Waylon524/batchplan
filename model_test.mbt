///|
test "public data structures preserve caller inputs" {
  let item : Item = { id: "document-1", costs: [12, 50], group: None, }
  assert_eq(item.id, "document-1")
  assert_eq(item.costs, [12, 50])
  assert_eq(batch_id(0), "batch-1")
}
