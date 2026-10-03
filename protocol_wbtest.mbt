///|
test "JSON roundtrip stable keys and unicode IDs" {
  let request : Request = {
    budget: simple_budget(10, 2),
    items: [item("文档\"\n1", 4), item("b", 6)],
  }
  let text = stable_json(@json.to_json(request))
  assert_eq(parse_request(text), Ok(request))
  let manifest = plan(request.items, request.budget).unwrap()
  assert_eq(plan_json(text), Ok(manifest.to_json_string()))
  let verification : VerificationRequest = {
    budget: request.budget,
    items: request.items,
    manifest,
  }
  assert_eq(verify_json(stable_json(@json.to_json(verification))), [])
  assert_true(manifest.to_json_string().has_prefix("{\"batches\":"))
}

///|
test "malformed missing fractional and out-of-range integer JSON fails" {
  for text in ["{", "{}", "null", "[]", "{\"budget\":null,\"items\":[]}"] {
    assert_true(parse_request(text) is Err(_))
  }
  let request : Request = {
    budget: simple_budget(10, 2),
    items: [item("a", 4)],
  }
  let text = stable_json(@json.to_json(request))
  assert_true(parse_request(text.replace(old="[4]", new="[4.5]")) is Err(_))
  assert_true(
    parse_request(text.replace(old="[4]", new="[2147483648]")) is Err(_),
  )
  assert_eq(codes(verify_json("no")), ["invalid_json"])
}

///|
test "explicit null group is accepted as ungrouped" {
  let request : Request = {
    budget: simple_budget(10, 2),
    items: [item("a", 4)],
  }
  let text = stable_json(@json.to_json(request)).replace(
    old="\"id\":\"a\"",
    new="\"group\":null,\"id\":\"a\"",
  )
  assert_eq(parse_request(text), Ok(request))
}
