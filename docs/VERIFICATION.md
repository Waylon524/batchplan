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

A separate reviewer tested the pure core against an independently implemented Python oracle and malicious-manifest mutations. The final review report and exact reproduction scripts are delivered separately. Numbers in that report should be associated with its recorded code checkpoint, rather than extrapolated to later functional changes.

## Coverage observation

`moon test --target js --enable-coverage` passed all 26 tests. `moon coverage analyze -- -f summary` reported 317/354 instrumentation points. The CLI main accounted for 0/32 in this unit-test coverage run; it was exercised separately by black-box CLI tests. Core-only subtraction gives 317/322 points. This is not a claim of full branch coverage or formal verification.

## Not run or not completed

- GitHub-hosted CI: workflow prepared, never run because no remote repository exists
- Mooncakes publication: not attempted; owner namespace and license must be chosen first
- Live embeddings/database/storage integrations: not implemented or exercised
- Real user data, production load/performance, fuzzing of the upstream JSON parser, security certification: not evaluated
- Competition submission and final human-written proposal: not performed or generated
- Current license status: no active LICENSE grant; MIT is only a proposal for owner review

## Development-history evidence

The local history contains more than ten actual development commits under `dot AI assistant <dot-agent@localhost>`. Each commit is a substantive implementation, verification or documentation checkpoint. The recorded timestamps are the actual system times; display includes the environment's UTC-07:00 offset. No dates or identity were invented. The delivered Git bundle preserves that history.

Public repository and package publication requirements cannot be marked satisfied by a local bundle. Any eventual public release still needs owner authorization, a legitimate namespace, final license selection, and remote verification.
