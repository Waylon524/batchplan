# Contributing

Keep the library deterministic, portable and free of runtime IO. The Node CLI should remain a small adapter. Budget or grouping changes must be reflected in both the planner and the independently implemented verifier, with negative-manifest tests and overflow boundaries.

Before proposing a change:

```sh
bash scripts/check.sh
git diff --exit-code pkg.generated.mbti cmd/main/pkg.generated.mbti
```

Review and intentionally commit any API signature changes before running the final diff check. Add a reproducible test for each bug. Describe actual verification and anything not tested. Do not claim live integrations or optimal packing without evidence.

AI-assisted contributions are welcome when the contributor understands the change, reviews it and tests it. Preserve accurate authorship and commit history. Do not include credentials, personal datasets or private operational documents in examples or reports. Use synthetic fixtures.
