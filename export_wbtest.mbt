///|
test "CSV preserves identity punctuation and line breaks with deterministic columns" {
  let input = [item("a,\"b\"\nc", 4)]
  let budget = simple_budget(10, 5)
  let text = assignments_csv(input, budget, plan(input, budget).unwrap()).unwrap()
  assert_eq(
    text, "\"batch_id\",\"source_index\",\"item_id\",\"group\",\"cost:bytes\"\r\n\"batch-1\",\"0\",\"a,\"\"b\"\"\nc\",\"\",\"4\"\r\n",
  )
}

///|
test "CSV refuses invalid manifests and emits header for empty inputs" {
  let budget = simple_budget(10, 5)
  let output = plan([], budget).unwrap()
  assert_eq(
    assignments_csv([], budget, output).unwrap(),
    "\"batch_id\",\"source_index\",\"item_id\",\"group\",\"cost:bytes\"\r\n",
  )
  assert_true(assignments_csv([item("a", 1)], budget, output) is Err(_))
}
