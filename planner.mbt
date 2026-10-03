///|
priv struct UnitOfWork {
  start : Int
  end : Int
  costs : Array[Int]
}

///|
fn fits(totals : Array[Int], extra : Array[Int], limits : Array[Int]) -> Bool {
  for dimension = 0; dimension < limits.length(); dimension = dimension + 1 {
    if extra[dimension] > limits[dimension] - totals[dimension] {
      return false
    }
  }
  true
}

///|
fn make_batch(
  index : Int,
  indices : Array[Int],
  totals : Array[Int],
  items : Array[Item],
) -> Batch {
  {
    id: batch_id(index),
    indices,
    item_ids: indices.map(fn(i) { items[i].id }),
    totals,
  }
}

///|
fn plan_units(
  items : Array[Item],
  budget : Budget,
  units : Array[UnitOfWork],
) -> Plan {
  let batches : Array[Batch] = []
  let mut indices : Array[Int] = []
  let mut totals = budget.batch_overhead.copy()
  for unit in units {
    let count = unit.end - unit.start
    if !indices.is_empty() &&
      (
        count > budget.max_items - indices.length() ||
        !fits(totals, unit.costs, budget.limits)
      ) {
      batches.push(make_batch(batches.length(), indices, totals, items))
      indices = []
      totals = budget.batch_overhead.copy()
    }
    for index = unit.start; index < unit.end; index = index + 1 {
      indices.push(index)
    }
    for dimension = 0; dimension < totals.length(); dimension = dimension + 1 {
      // The unit fits an empty batch, and the transition above checked remaining space.
      totals[dimension] = totals[dimension] + unit.costs[dimension]
    }
  }
  if !indices.is_empty() {
    batches.push(make_batch(batches.length(), indices, totals, items))
  }
  { schema_version: 1, strategy: "next-fit-preserve-order", batches, }
}

///|
/// Deterministic next-fit: append to the current batch, or start the next one.
/// Does not sort records, reorder them or claim globally optimal packing.
pub fn plan(items : Array[Item], budget : Budget) -> Result[Plan, Array[Issue]] {
  let errors = validate_input(items, budget)
  if !errors.is_empty() {
    return Err(errors)
  }
  let units : Array[UnitOfWork] = []
  for index, item in items {
    if item.group is Some(_) {
      return Err([
        issue(
          "groups_not_supported", index, -1, "atomic groups require the group planner",
        ),
      ])
    }
    units.push({
      start: index,
      end: index + 1,
      costs: item.costs.mapi(fn(d, c) { c + budget.item_overhead[d] }),
    })
  }
  Ok(plan_units(items, budget, units))
}
