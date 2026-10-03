///|
/// Caller-provided nonnegative integer costs, one per budget dimension.
/// Adjacent items sharing a nonempty group identifier must stay together.
pub(all) struct Item {
  id : String
  costs : Array[Int]
  group : String?
} derive(Eq, @debug.Debug, ToJson, FromJson)

///|
/// All overhead is explicit and uses the same units as limits.
/// Every nonempty batch pays batch_overhead once and item_overhead per item.
pub(all) struct Budget {
  dimensions : Array[String]
  limits : Array[Int]
  max_items : Int
  batch_overhead : Array[Int]
  item_overhead : Array[Int]
} derive(Eq, @debug.Debug, ToJson, FromJson)

///|
/// Stable source positions are zero-based. Totals include all declared overhead.
pub(all) struct Batch {
  id : String
  indices : Array[Int]
  item_ids : Array[String]
  totals : Array[Int]
} derive(Eq, @debug.Debug, ToJson, FromJson)

///|
/// A portable, inspectable manifest. Caller inputs are required for verification.
pub(all) struct Plan {
  schema_version : Int
  strategy : String
  batches : Array[Batch]
} derive(Eq, @debug.Debug, ToJson, FromJson)

///|
/// Structured diagnostic. index/dimension are zero-based; -1 means not applicable.
pub(all) struct Issue {
  code : String
  index : Int
  dimension : Int
  message : String
} derive(Eq, @debug.Debug, ToJson, FromJson)

///|
fn issue(
  code : String,
  index : Int,
  dimension : Int,
  message : String,
) -> Issue {
  { code, index, dimension, message, }
}

///|
fn blank(value : String) -> Bool {
  value.trim().is_empty()
}

///|
fn batch_id(index : Int) -> String {
  "batch-\{index + 1}"
}
