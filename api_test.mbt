///|
test "readme public API usage" {
  let budget : @batchplan.Budget = {
    dimensions: ["tokens", "bytes"],
    limits: [100, 1024],
    max_items: 3,
    batch_overhead: [0, 40],
    item_overhead: [0, 12],
  }
  let items : Array[@batchplan.Item] = [
    { id: "doc-a", costs: [40, 300], group: None, },
    { id: "doc-b", costs: [50, 350], group: None, },
    { id: "doc-c", costs: [20, 100], group: None, },
  ]
  match @batchplan.plan(items, budget) {
    Ok(manifest) => {
      assert_eq(manifest.batches.length(), 2)
      assert_eq(@batchplan.verify(items, budget, manifest), [])
      assert_true(manifest.to_json_string().contains("doc-a"))
    }
    Err(_) => fail("documented API example must plan successfully")
  }
}
