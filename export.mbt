///|
fn csv_cell(value : String) -> String {
  // Always quote fields. Embedded quotes are doubled; newlines remain in quoted fields.
  "\"" + value.replace_all(old="\"", new="\"\"") + "\""
}

///|
/// Export one row per assignment after independent verification.
/// Raw declared costs are named cost:<dimension>; overhead stays in the manifest.
/// This machine-readable CSV preserves text exactly; it does not sanitize formulas.
pub fn assignments_csv(
  items : Array[Item],
  budget : Budget,
  manifest : Plan,
) -> Result[String, Array[Issue]] {
  let errors = verify(items, budget, manifest)
  if !errors.is_empty() {
    return Err(errors)
  }
  let lines : Array[String] = []
  let header = ["batch_id", "source_index", "item_id", "group"]
  for dimension in budget.dimensions {
    header.push("cost:" + dimension)
  }
  lines.push(header.map(csv_cell).join(","))
  for batch in manifest.batches {
    for index in batch.indices {
      let item = items[index]
      let fields = [
        batch.id,
        index.to_string(),
        item.id,
        item.group.unwrap_or(""),
      ]
      for cost in item.costs {
        fields.push(cost.to_string())
      }
      lines.push(fields.map(csv_cell).join(","))
    }
  }
  Ok(lines.join("\r\n") + "\r\n")
}
