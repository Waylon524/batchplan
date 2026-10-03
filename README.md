# BatchPlan

A pure MoonBit library and local CLI that partitions ordered records into deterministic batches under multiple caller-declared integer budgets, with explicit overhead, atomic groups, stable source positions and independent manifest verification.

Work in progress. Provisional namespace: `dot-agent/batchplan`. No user identity, public repository or package publication is implied. All code commits are made by an explicitly identified AI assistant using actual system timestamps.

## Intended uses

- Plan embedding-request batches from caller-supplied token and payload-byte counts
- Split database bulk payloads under row and byte limits
- Plan export shards under record-count and estimated-byte limits

This library does not tokenize, send requests, retry operations, schedule work, measure payloads or promise the minimum number of batches. Synthetic examples are not integrations or evidence of production use.

License selection and public release require owner review. No human-required competition application is generated here.
