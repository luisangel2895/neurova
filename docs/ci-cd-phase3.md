# CI/CD Phase 3 - GitHub PR CI

Phase 3 hardens GitHub Actions as the primary merge gate for `main`.

## Workflow responsibility

Workflow:

- `.github/workflows/ios-ci.yml`

Phase 3 responsibility:

- validate shared scheme availability
- build-for-testing once
- run unit tests from `NeurovaTests`
- run a stable UI smoke subset from `NeurovaUITests`
- upload `.xcresult` bundles for post-failure debugging
- publish a short GitHub workflow summary
- clean up the temporary simulator created for CI

This phase intentionally does not add:

- TestFlight distribution
- Xcode Cloud UI workflows
- nightly execution
- performance suites in CI

## PR validation scope

Current PR CI validates:

1. shared scheme is present in the repository
2. project builds for testing on simulator
3. unit test suite (`NeurovaTests`)
4. UI smoke subset:
   - `testLaunchShowsExpectedRootExperience`
   - `testOnboardingOrShellExposesPrimaryNavigationElement`

## Why the UI smoke scope stays small

The app has state and sync-sensitive flows.

For PR validation, the goal is:

- stable signal
- fast runtime
- low flakiness

That is why PR CI currently uses a very small smoke layer instead of broad UI coverage.

## Required GitHub manual settings

These settings must be applied manually in GitHub repository settings.

Recommended branch protection for `main`:

1. Require a pull request before merging
2. Require approvals
3. Require status checks to pass before merging
4. Select the required status check for this workflow job:
   - `PR Validation`
5. Require branches to be up to date before merging
6. Restrict direct pushes to `main`

If GitHub later shows the check with a different displayed name, use the exact job name shown in PR checks.

## Relationship to later phases

Phase 3 keeps GitHub as the main PR gate.

Later phases should split responsibility like this:

- GitHub:
  - PR validation
  - fast quality signal
- Xcode Cloud:
  - archive
  - internal beta distribution
  - optional nightly/performance

This avoids duplicating the full PR pipeline in both systems.

## Exact next step for Phase 4

Phase 4 should prepare Xcode Cloud readiness without replacing GitHub PR CI:

1. decide final test layering for PR / Beta / Nightly
2. decide whether to introduce an `.xctestplan`
3. confirm scheme/test configuration is ready for Apple-side workflow creation
4. document exact Xcode Cloud workflows to create later in the Apple UI
