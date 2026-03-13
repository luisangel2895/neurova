# Pending Work To Reach A Fully Professional Setup

This file tracks the remaining work to take Neurova from a solid repo and CI baseline to a fully professional delivery pipeline.

It is intentionally separate from the README and focused on operational/engineering readiness.

## Current completed phases

- Phase 1: repository readiness for CI/CD
- Phase 2: testing foundation
- Phase 3: GitHub PR CI hardening

## Remaining phases

### Phase 4: Xcode Cloud readiness

Goal:

- finalize the repo-side preparation for Apple-native CI/CD without configuring Apple UI yet

Pending work:

1. Decide final test layering for:
   - PR
   - Beta
   - Nightly
2. Decide whether introducing a repository `.xctestplan` now adds real value
3. Confirm the shared scheme and test scope are ready for Apple-side workflows
4. Document the exact Xcode Cloud workflows that will later be created manually

### Phase 5: Apple-side setup

Goal:

- create the real Apple distribution/testing workflows

Pending manual work in Apple UI:

1. Create Xcode Cloud workflow for PR verification if desired
2. Create Xcode Cloud workflow for `main` internal beta
3. Configure TestFlight internal testing groups
4. Validate signing, archive behavior, and Apple-side permissions

Note:

- these steps require manual work in Xcode Cloud / App Store Connect
- they should be performed with guidance, but cannot be completed purely from the repo

### Phase 6: Nightly and performance

Goal:

- improve confidence beyond PR validation

Pending work:

1. Add launch performance validation in CI strategy
2. Add nightly smoke workflow
3. Add a broader non-blocking regression suite
4. Consider expanding UI smoke coverage only if stability remains high

## Additional engineering upgrades to consider later

These are not blockers for CI/CD, but they are useful if the project grows.

### Testing expansion

1. Add more integration-style tests for view models and use cases
2. Add controlled app-state hooks for more reliable UI smoke tests
3. Add failure triage guidance for `.xcresult` artifacts

### Release discipline

1. Move from direct pushes to `main` toward PR-based merges when development expands
2. Enable branch protection once PR workflow becomes part of daily work
3. Define release tagging/versioning policy

### Observability and quality

1. Add a lightweight issue template for CI failures
2. Add a release checklist for internal beta builds
3. Add a documented rollback procedure for bad beta candidates

## What is intentionally out of scope here

- SwiftData persistence changes
- CloudKit/iCloud sync changes
- schema or model migrations
- redesign work
- architecture rewrites unrelated to CI/CD quality

## Recommended execution order

1. Finish Phase 4
2. Perform Apple-side setup from Phase 5
3. Validate internal beta distribution end-to-end
4. Add nightly/performance from Phase 6
5. Revisit branch protection and PR-only discipline when it matches the team workflow
