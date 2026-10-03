///|
/// Validate dimensions, limits, explicit overhead, IDs and individual costs.
/// Addition is guarded by subtraction, so even Int::max_value cannot wrap.
pub fn validate_input(items : Array[Item], budget : Budget) -> Array[Issue] {
  let errors : Array[Issue] = []
  let dimensions = budget.dimensions.length()
  if dimensions == 0 {
    errors.push(
      issue("no_dimensions", -1, -1, "at least one cost dimension is required"),
    )
  }
  if budget.max_items <= 0 {
    errors.push(
      issue("invalid_max_items", -1, -1, "max_items must be positive"),
    )
  }
  if budget.limits.length() != dimensions ||
    budget.batch_overhead.length() != dimensions ||
    budget.item_overhead.length() != dimensions {
    errors.push(
      issue(
        "budget_shape", -1, -1, "limits and overhead arrays must match dimensions",
      ),
    )
    return errors
  }
  let seen_dimensions : Map[String, Bool] = Map([])
  for dimension, name in budget.dimensions {
    if blank(name) {
      errors.push(
        issue(
          "blank_dimension", -1, dimension, "dimension name must be nonblank",
        ),
      )
    }
    if seen_dimensions.contains(name) {
      errors.push(
        issue(
          "duplicate_dimension", -1, dimension, "dimension names must be unique",
        ),
      )
    }
    seen_dimensions[name] = true
    let limit = budget.limits[dimension]
    let envelope = budget.batch_overhead[dimension]
    let overhead = budget.item_overhead[dimension]
    if limit < 0 || envelope < 0 || overhead < 0 {
      errors.push(
        issue(
          "negative_budget", -1, dimension, "limits and overhead must be nonnegative",
        ),
      )
    } else if envelope > limit || overhead > limit - envelope {
      errors.push(
        issue(
          "overhead_exceeds_limit", -1, dimension, "a nonempty batch cannot fit declared overhead",
        ),
      )
    }
  }
  if !errors.is_empty() {
    return errors
  }
  let seen_ids : Map[String, Bool] = Map([])
  for index, item in items {
    if blank(item.id) {
      errors.push(issue("blank_id", index, -1, "item id must be nonblank"))
    }
    if seen_ids.contains(item.id) {
      errors.push(issue("duplicate_id", index, -1, "item ids must be unique"))
    }
    seen_ids[item.id] = true
    match item.group {
      Some(group) =>
        if blank(group) {
          errors.push(
            issue("blank_group", index, -1, "use null for ungrouped items"),
          )
        }
      None => ()
    }
    if item.costs.length() != dimensions {
      errors.push(
        issue("item_shape", index, -1, "item costs must match dimensions"),
      )
      continue
    }
    for dimension, cost in item.costs {
      if cost < 0 {
        errors.push(
          issue(
            "negative_cost", index, dimension, "item costs must be nonnegative",
          ),
        )
      } else if cost >
        budget.limits[dimension] -
        budget.batch_overhead[dimension] -
        budget.item_overhead[dimension] {
        errors.push(
          issue(
            "oversized_item", index, dimension, "item plus overhead cannot fit an empty batch",
          ),
        )
      }
    }
  }
  let closed_groups : Map[String, Bool] = Map([])
  let mut previous : String? = None
  for index, item in items {
    if item.group != previous {
      match previous {
        Some(group) => closed_groups[group] = true
        None => ()
      }
      match item.group {
        Some(group) =>
          if closed_groups.contains(group) {
            errors.push(
              issue(
                "noncontiguous_group", index, -1, "a group must occupy one contiguous run",
              ),
            )
          }
        None => ()
      }
    }
    previous = item.group
  }
  errors
}
