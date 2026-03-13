# CI/CD Phase 4 - Xcode Cloud Readiness

Phase 4 prepares the repository for Apple-native CI/CD without creating any workflow in the Apple UI yet.

## What changed in this phase

Repository additions:

- `Neurova.xctestplan`
- shared scheme updated to use the repository test plan:
  - `Neurova.xcodeproj/xcshareddata/xcschemes/Neurova.xcscheme`

## Why a test plan is now worth introducing

Phases 1 and 2 created enough real value for a repository test plan:

- shared scheme is already versioned
- the project now has real unit coverage
- the project now has a minimal UI smoke suite
- later Apple workflows need a predictable repo-side test entrypoint

Adding the test plan now gives:

- a stable Xcode Cloud entrypoint
- explicit test configurations by workflow intent
- a clean place to evolve PR / Beta / Nightly layering later

## Current test plan configurations

`Neurova.xctestplan` includes:

- `PR`
- `Beta`
- `Nightly`

At this phase, those configurations intentionally share the same base targets:

- `NeurovaTests`
- `NeurovaUITests`

This is enough for readiness.

Future phases can specialize configuration behavior further if needed.

## Intended workflow ownership

### GitHub

Use GitHub Actions for:

- PR validation
- fast build and test feedback
- merge safety

### Xcode Cloud

Use Xcode Cloud for:

- Apple-native PR verification if desired
- archive on `main`
- internal beta distribution
- scheduled nightly workflows

This keeps responsibilities separate and avoids duplicating the full pipeline in both systems.

## Exact Xcode Cloud workflows to create later

These are manual Apple-side workflows and are not created in this phase.

### Workflow 1: PR Verify

Purpose:

- optional Apple-side verification for pull requests to `main`

Recommended setup later:

- trigger: pull request updates to `main`
- action: build and test
- scheme: `Neurova`
- test plan: `Neurova.xctestplan`
- configuration to select: `PR`
- distribution: none

### Workflow 2: Main Internal Beta

Purpose:

- build validated app archives from `main`
- distribute to TestFlight internal testers

Recommended setup later:

- trigger: changes pushed/merged to `main`
- action: build, test, archive, distribute
- scheme: `Neurova`
- test plan: `Neurova.xctestplan`
- configuration to select: `Beta`
- distribution: TestFlight internal only

### Workflow 3: Nightly

Purpose:

- run broader validation outside the critical PR path

Recommended setup later:

- trigger: scheduled
- action: build and test
- scheme: `Neurova`
- test plan: `Neurova.xctestplan`
- configuration to select: `Nightly`
- distribution: none

## What still remains out of scope for this phase

- creating workflows in Xcode Cloud UI
- App Store Connect configuration
- TestFlight tester setup
- archive/distribution validation in Apple UI
- performance/nightly expansion beyond this readiness step

## Exact next step for Phase 5

Phase 5 should be performed with manual Apple-side work and guidance:

1. open Xcode Cloud / App Store Connect
2. create the workflows documented above
3. validate signing and archive behavior
4. connect TestFlight internal distribution
