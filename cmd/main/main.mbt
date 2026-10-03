// Node-only IO boundary. All planning, parsing and verification are pure MoonBit.

///|
extern "js" fn read_stdin() -> String =
  #|() => process.getBuiltinModule("node:fs").readFileSync(0, "utf8")

///|
extern "js" fn arguments() -> FixedArray[String] =
  #|() => process.argv.slice(2)

///|
extern "js" fn stdout(text : String) -> Unit =
  #|(text) => { process.stdout.write(text); }

///|
extern "js" fn stderr(text : String) -> Unit =
  #|(text) => { process.stderr.write(text); process.exitCode = 2; }

///|
fn fail(errors : Array[@batchplan.Issue]) -> Unit {
  stderr(@batchplan.issues_json(errors) + "\n")
}

///|
fn main {
  let args = arguments()
  let command = if args.length() == 0 { "plan" } else { args[0] }
  if command == "--help" || command == "help" {
    stdout(
      "BatchPlan 0.1.0\nUsage: batchplan [plan|verify|csv] < request.json\nplan: {budget,items} -> manifest JSON\nverify: {budget,items,manifest} -> {\"valid\":true} or errors\ncsv: {budget,items} -> verified assignment CSV\nExit 0: success; exit 2: invalid input/plan/usage. Node >=22.16.\n",
    )
    return
  }
  if command == "--version" {
    stdout("0.1.0\n")
    return
  }
  if args.length() > 1 ||
    !(command == "plan" || command == "verify" || command == "csv") {
    stderr("Unknown usage; run with --help\n")
    return
  }
  let text = read_stdin()
  if command == "verify" {
    let errors = @batchplan.verify_json(text)
    if errors.is_empty() {
      stdout("{\"valid\":true}\n")
    } else {
      fail(errors)
    }
    return
  }
  match @batchplan.parse_request(text) {
    Err(errors) => fail(errors)
    Ok(request) =>
      match @batchplan.plan(request.items, request.budget) {
        Err(errors) => fail(errors)
        Ok(manifest) => {
          let errors = @batchplan.verify(
            request.items,
            request.budget,
            manifest,
          )
          if !errors.is_empty() {
            fail(errors)
            return
          }
          if command == "csv" {
            match
              @batchplan.assignments_csv(
                request.items,
                request.budget,
                manifest,
              ) {
              Err(errors) => fail(errors)
              Ok(csv) => stdout(csv)
            }
          } else {
            stdout(manifest.to_json_string() + "\n")
          }
        }
      }
  }
}
