///|
/// Input to plan_json and the planning CLI.
pub(all) struct Request {
  budget : Budget
  items : Array[Item]
} derive(Eq, @debug.Debug, ToJson, FromJson)

///|
/// Verification deliberately receives source inputs as well as the manifest.
pub(all) struct VerificationRequest {
  budget : Budget
  items : Array[Item]
  manifest : Plan
} derive(Eq, @debug.Debug, ToJson, FromJson)

///|
/// Parse via MoonBit's standard JSON parser and typed decoder, with bounded nesting.
pub fn parse_request(text : String) -> Result[Request, Array[Issue]] {
  try {
    if !wire_preflight(text) {
      return Err([
        issue(
          "invalid_integer", -1, -1, "JSON numbers must be 32-bit integer literals; nesting is limited to 64",
        ),
      ])
    }
    Ok(@json.from_json(normalize_groups(@json.parse(text))))
  } catch {
    error => Err([issue("invalid_json", -1, -1, error.to_string())])
  }
}

///|
pub fn parse_verification_request(
  text : String,
) -> Result[VerificationRequest, Array[Issue]] {
  try {
    if !wire_preflight(text) {
      return Err([
        issue(
          "invalid_integer", -1, -1, "JSON numbers must be 32-bit integer literals; nesting is limited to 64",
        ),
      ])
    }
    Ok(@json.from_json(normalize_groups(@json.parse(text))))
  } catch {
    error => Err([issue("invalid_json", -1, -1, error.to_string())])
  }
}

///|
/// Stable JSON for this package's output: sorted object keys, preserved array order.
/// Uses the standard JSON writer for primitive escaping and numeric encoding.
/// This is not an implementation of a cryptographic JSON canonicalization standard.
fn stable_json(value : Json) -> String {
  match value {
    Object(object) => {
      let keys = object.keys().to_array()
      keys.sort()
      "{" +
      keys
      .map(fn(key) {
        Json::string(key).stringify() + ":" + stable_json(object[key])
      })
      .join(",") +
      "}"
    }
    Array(values) => "[" + values.map(stable_json).join(",") + "]"
    _ => value.stringify()
  }
}

///|
pub fn Plan::to_json_string(self : Plan) -> String {
  stable_json(@json.to_json(self))
}

///|
pub fn issues_json(issues : Array[Issue]) -> String {
  stable_json(@json.to_json(issues))
}

///|
/// Return a deterministic portable manifest, or structured input/planning errors.
pub fn plan_json(text : String) -> Result[String, Array[Issue]] {
  match parse_request(text) {
    Err(errors) => Err(errors)
    Ok(request) =>
      match plan(request.items, request.budget) {
        Err(errors) => Err(errors)
        Ok(manifest) => Ok(manifest.to_json_string())
      }
  }
}

///|
/// A JSON convenience boundary around the independently implemented verifier.
pub fn verify_json(text : String) -> Array[Issue] {
  match parse_verification_request(text) {
    Err(errors) => errors
    Ok(request) => verify(request.items, request.budget, request.manifest)
  }
}

///|
/// Guard the typed decoder, which otherwise truncates fractional JSON numbers.
/// This is a preflight only; the standard parser still validates JSON grammar.
fn wire_preflight(text : String) -> Bool {
  let mut quoted = false
  let mut escaped = false
  let mut number = false
  let mut depth = 0
  for char in text {
    if quoted {
      if escaped {
        escaped = false
      } else if char == '\\' {
        escaped = true
      } else if char == '"' {
        quoted = false
      }
      continue
    }
    if char == '"' {
      quoted = true
      number = false
      continue
    }
    if char == '{' || char == '[' {
      depth = depth + 1
      if depth > 64 {
        return false
      }
    }
    if char == '}' || char == ']' {
      depth = depth - 1
    }
    if (char >= '0' && char <= '9') || char == '-' {
      number = true
      continue
    }
    if number && (char == '.' || char == 'e' || char == 'E' || char == '+') {
      return false
    }
    number = false
  }
  true
}

///|
/// Standard typed decoding treats an omitted optional field as None.
/// Accept explicit JSON null for group as well; this operates on fresh parsed data.
fn normalize_groups(value : Json) -> Json {
  if value is Object(root) {
    if root.get("items") is Some(Array(items)) {
      for item in items {
        if item is Object(fields) {
          if fields.get("group") is Some(Null) {
            fields.remove("group")
          }
        }
      }
    }
  }
  value
}
