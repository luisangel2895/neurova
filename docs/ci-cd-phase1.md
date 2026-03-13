# CI/CD Phase 1 Readiness

This repository is prepared in Phase 1 to support:

- GitHub PR validation today
- Xcode Cloud onboarding next
- TestFlight and distribution in later phases

## Current repository decisions

- GitHub remains the source of truth for code review and PR validation.
- GitHub Actions remains the first CI gate for build and test validation.
- Xcode Cloud is intentionally deferred to Apple-side setup in a later phase.
- Distribution and TestFlight are intentionally deferred.

## Shared scheme

The app now includes a shared scheme committed to the repository:

- `Neurova.xcodeproj/xcshareddata/xcschemes/Neurova.xcscheme`

This is required for reliable CI and is a prerequisite for Xcode Cloud.

## GitHub Actions role

Workflow:

- `.github/workflows/ios-ci.yml`

Phase 1 responsibility:

- validate the shared scheme exists
- build for testing on simulator
- run unit-test target validation
- upload `.xcresult` bundles for debugging

This workflow is intentionally conservative and does not yet handle:

- TestFlight distribution
- Xcode Cloud orchestration
- nightly pipelines
- performance test execution

## Testing matrix for later phases

### PR

Goal:

- fast signal for correctness and merge safety

Planned test scope:

- build
- unit tests
- small UI smoke suite

Expected runners:

- GitHub Actions
- optional Xcode Cloud PR Verify later if desired

### Beta

Goal:

- validate release candidate quality before internal testers receive builds

Planned test scope:

- build/archive
- unit tests
- integration-style app logic tests
- smoke UI tests

Expected runner:

- Xcode Cloud on `main`

### Nightly

Goal:

- slower but broader validation without blocking normal development

Planned test scope:

- full unit suite
- broader UI smoke/regression navigation
- launch/performance baselines

Expected runner:

- Xcode Cloud scheduled workflow or GitHub scheduled runner later

## Phase 2 exact next step

Build a real testing foundation:

1. replace placeholder unit tests with domain-level coverage
2. replace placeholder UI tests with a reliable launch + tab smoke suite
3. decide whether to add a repository-level `.xctestplan` once real suites exist

## Why no xctestplan yet

Phase 1 intentionally does not add an `.xctestplan` yet.

Reason:

- current test suites are still placeholders
- introducing a test plan before defining real test layers would create maintenance overhead without meaningful CI value
- the next useful moment to add it is Phase 2, once PR smoke/unit coverage is real
