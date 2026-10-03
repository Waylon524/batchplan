///|
/// Resolve only contiguous groups. Rejecting re-opened groups preserves global input order.
fn atomic_units(
  items : Array[Item],
  budget : Budget,
) -> Result[Array[UnitOfWork], Array[Issue]] {
  let units : Array[UnitOfWork] = []
  let errors : Array[Issue] = []
  let mut start = 0
  while start < items.length() {
    let mut end = start + 1
    match items[start].group {
      None => ()
      Some(group) =>
        while end < items.length() && items[end].group == Some(group) {
          end = end + 1
        }
    }
    if end - start > budget.max_items {
      errors.push(
        issue(
          "oversized_group_count", start, -1, "atomic unit exceeds max_items",
        ),
      )
    }
    let totals = Array::make(budget.dimensions.length(), 0)
    for dimension = 0; dimension < totals.length(); dimension = dimension + 1 {
      let capacity = budget.limits[dimension] - budget.batch_overhead[dimension]
      for index = start; index < end; index = index + 1 {
        let extra = items[index].costs[dimension] +
          budget.item_overhead[dimension]
        if extra > capacity - totals[dimension] {
          errors.push(
            issue(
              "oversized_group_cost", start, dimension, "atomic unit and overhead exceed the budget",
            ),
          )
          break
        }
        totals[dimension] = totals[dimension] + extra
      }
    }
    units.push({ start, end, costs: totals, })
    start = end
  }
  if errors.is_empty() {
    Ok(units)
  } else {
    Err(errors)
  }
}
