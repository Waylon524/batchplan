# Verification and readiness facts

Verification date: 2026-10-03 UTC. Code checkpoint: `e1eefb1773773109adb124a5c25f5688141fede2`. Later documentation-only commits do not change the tested program.

## Passed locally

- Official MoonBit toolchain archive SHA-256 matched its official checksum before execution
- moon 0.1.20260920; moonc v0.10.14+7d59c7ec9
- `moon fmt --check`
- `moon check`, `moon test`, and `moon build` for JavaScript, Wasm-GC and native
- 26 tests passed on each of those three backends, with zero failures
- 26 tests passed with JavaScript release compilation
- One test contains a deterministic 720-case input grid checked by the independent manifest verifier
- Public README API example compiled and passed as a black-box package test
- Nine CLI checks passed: valid planning, determinism, verification, altered totals, malformed JSON, fractional costs, unknown commands, CSV output and help
- Three six-record workflows each produced the hand-calculated three-batch result; an independent Python implementation recomputed all costs and coverage; Python's CSV reader verified the assignment exports
- Generated public interface checked into source control
- Working tree clean after code checks; source scan found no common private-key/token patterns

A successful pattern scan is not a proof that arbitrary files contain no secrets. This repository was newly created from synthetic examples and contains no downloaded private inputs or credentials.

## Independent review

The final code checkpoint above was independently reviewed and retested from a fresh source archive. The reviewer found no unresolved correctness defect. Additional JavaScript-target checks passed:

- 20,000 generated planning requests matched an independent Python integer-arithmetic oracle (3,932 feasible; 16,068 invalid or infeasible)
- 45,419 verifier mutation cases matched expected acceptance/rejection (3,932 valid; 41,487 intentionally invalid)
- 50 wire-protocol boundary cases
- Seven targeted group/order/count/coverage/overflow attacks
- 5,556 exhaustive assignment/batch-boundary cases for a fixed small grouped input

The exact reproduction scripts, archived code checkpoint and test logs accompany the delivery. These are deterministic test corpora, not 20,000 real workloads or a formal correctness proof.

## Coverage observation

`moon test --target js --enable-coverage` passed all 26 tests. `moon coverage analyze -- -f summary` reported 317/354 instrumentation points. The CLI main accounted for 0/32 in this unit-test coverage run; it was exercised separately by black-box CLI tests. Core-only subtraction gives 317/322 points. This is not a claim of full branch coverage or formal verification.

## Not run or not completed

- GitHub-hosted CI: see the repository Actions page for remote runs; the local results above are recorded independently
- Mooncakes publication: not attempted
- Live embeddings/database/storage integrations: not implemented or exercised
- Real user data, production load/performance, fuzzing of the upstream JSON parser, security certification: not evaluated

## Development-history evidence

The local history contains more than ten actual development commits under `dot AI assistant <dot-agent@localhost>`. Each commit is a substantive implementation, verification or documentation checkpoint. The recorded timestamps are the actual system times; display includes the environment's UTC-07:00 offset. No dates or identity were invented. The Git history preserves those checkpoints.

Publication preparation adds the owner namespace and approved MIT license without rewriting the earlier development history. Subsequent release work must be verified against its own commit; local test evidence does not imply a hosted CI pass.
