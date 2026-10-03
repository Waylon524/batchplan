# Owner review before any release or application

This is a factual review checklist, not a competition proposal or text to submit as human-authored writing.

## Current state

- Local repository and genuine development history only
- Explicit AI-assistant commit identity; no user impersonation or manufactured backdating
- Provisional module namespace `dot-agent/batchplan`; change to an owner-controlled namespace before package publication
- No public repository, push, package registration/publication or competition submission performed
- Three synthetic, realistic workflow fixtures; no actual vendor API/database/storage integration or production-user validation
- Local checks are reported separately from GitHub-hosted CI, which cannot have run before publication

## Proposed license, awaiting owner choice

MIT is an OSI-approved permissive option. It allows commercial use, modification and redistribution, provided the copyright and permission notice are retained, and includes an as-is warranty disclaimer. Source: https://opensource.org/license/mit

No LICENSE file or module license declaration is installed yet, so this prototype must not be described as already MIT-licensed or ready for public distribution. The owner must decide license and appropriate attribution, review provenance and third-party obligations, then add the agreed license before release. MoonBit's standard library is an external dependency under Apache-2.0; no standard-library source or toolchain binary is copied into this source repository.

## Questions the applicant should answer in their own words

1. Which concrete batching problem have you encountered, and whose workflow needs it?
2. Why is deterministic order-preserving multi-budget planning useful beyond fixed-count chunking?
3. Why are caller-supplied costs and overhead necessary, and what limits do they create?
4. Can you explain contiguous groups, overflow guards and independent verification without reading generated prose?
5. Which fixture have you personally run and modified? What happened when you introduced an oversized item or stale total?
6. What real user/input will you validate next, and what work remains before a maintained package release?

If the competition requires a human-written proposal, the applicant should write it themselves from their own understanding. This repository deliberately contains no final one-page application.
