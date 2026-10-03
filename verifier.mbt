///|
/// Independently check manifest safety against the exact current input and budget.
/// This scans assignments and recomputes totals; it never calls the planner.
/// It checks order, coverage, identity, group integrity and capacity, not optimality.
pub fn verify(
  items : Array[Item],
  budget : Budget,
  manifest : Plan,
) -> Array[Issue] {
  let errors = validate_input(items, budget)
  if !errors.is_empty() {
    return errors
  }
  if manifest.schema_version != 1 {
    errors.push(issue("schema_version", -1, -1, "unsupported manifest schema"))
  }
  if manifest.strategy != "next-fit-preserve-order" {
    errors.push(issue("strategy", -1, -1, "unsupported manifest strategy"))
  }
  let assigned = Array::make(items.length(), false)
  let group_batches : Map[String, Int] = Map([])
  let mut next_index = 0
  for batch_index, batch in manifest.batches {
    if batch.id != batch_id(batch_index) {
      errors.push(
        issue("batch_id", -1, -1, "batch identifiers must match manifest order"),
      )
    }
    if batch.indices.is_empty() {
      errors.push(issue("empty_batch", -1, -1, "empty batches are not allowed"))
    }
    if batch.indices.length() > budget.max_items {
      errors.push(issue("batch_count", -1, -1, "batch exceeds max_items"))
    }
    if batch.item_ids.length() != batch.indices.length() {
      errors.push(
        issue("identity_shape", -1, -1, "item_ids must align with indices"),
      )
    }
    if batch.totals.length() != budget.dimensions.length() {
      errors.push(
        issue("totals_shape", -1, -1, "batch totals must match dimensions"),
      )
    }
    let totals = budget.batch_overhead.copy()
    let exceeded = Array::make(totals.length(), false)
    for slot, index in batch.indices {
      if index < 0 || index >= items.length() {
        errors.push(
          issue("index_bounds", index, -1, "source position does not exist"),
        )
        continue
      }
      if assigned[index] {
        errors.push(
          issue(
            "duplicate_assignment", index, -1, "source record appears more than once",
          ),
        )
      }
      assigned[index] = true
      if index != next_index {
        errors.push(
          issue(
            "source_order", index, -1, "assignments must preserve source order",
          ),
        )
      }
      next_index = index + 1
      let item = items[index]
      if slot < batch.item_ids.length() && batch.item_ids[slot] != item.id {
        errors.push(
          issue(
            "identity_mismatch", index, -1, "manifest item id differs from source",
          ),
        )
      }
      match item.group {
        Some(group) =>
          match group_batches.get(group) {
            Some(previous) =>
              if previous != batch_index {
                errors.push(
                  issue(
                    "split_group", index, -1, "an atomic group crosses batch boundaries",
                  ),
                )
              }
            None => group_batches[group] = batch_index
          }
        None => ()
      }
      for dimension = 0; dimension < totals.length(); dimension = dimension + 1 {
        if exceeded[dimension] {
          continue
        }
        let remaining = budget.limits[dimension] - totals[dimension]
        let overhead = budget.item_overhead[dimension]
        let cost = item.costs[dimension]
        if overhead > remaining || cost > remaining - overhead {
          exceeded[dimension] = true
          errors.push(
            issue(
              "batch_capacity", index, dimension, "recomputed costs exceed budget",
            ),
          )
        } else {
          totals[dimension] = totals[dimension] + overhead + cost
        }
      }
    }
    if batch.totals.length() == totals.length() {
      for dimension = 0; dimension < totals.length(); dimension = dimension + 1 {
        if !exceeded[dimension] && batch.totals[dimension] != totals[dimension] {
          errors.push(
            issue(
              "totals_mismatch", -1, dimension, "declared total differs from recomputed costs including overhead",
            ),
          )
        }
      }
    }
  }
  for index, found in assigned {
    if !found {
      errors.push(
        issue(
          "missing_assignment", index, -1, "source record is absent from the manifest",
        ),
      )
    }
  }
  errors
}
