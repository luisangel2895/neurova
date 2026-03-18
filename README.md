<div align="center">
  <img src="Neurova/Assets.xcassets/Brand/LogoPrimary.imageset/ChatGPT%20Image%20Mar%202,%202026,%2003_58_54%20AM%20copy-Photoroom.png" alt="Neurova" width="160" />
  <h1>Neurova</h1>
  <p><strong>Intelligent flashcards, on-device OCR, spaced repetition, and iCloud-native study workflows for iPhone and iPad.</strong></p>
</div>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-iOS%20%7C%20iPadOS-0A84FF">
  <img alt="UI" src="https://img.shields.io/badge/UI-SwiftUI-34C759">
  <img alt="Persistence" src="https://img.shields.io/badge/Data-SwiftData-5856D6">
  <img alt="Sync" src="https://img.shields.io/badge/Sync-CloudKit-5AC8FA">
  <img alt="Auth" src="https://img.shields.io/badge/Auth-Sign%20in%20with%20Apple-111111">
  <img alt="OCR" src="https://img.shields.io/badge/OCR-Apple%20Vision-FF9500">
</p>

## Overview

Neurova is a modern iOS study platform designed around a pragmatic product thesis:

- local-first performance
- private-by-default study data
- optional private iCloud sync
- high-quality review loops powered by spaced repetition
- fast content creation through structured library workflows and on-device OCR

The app combines subject and deck organization, flashcard creation, guided onboarding, study sessions, insights, streaks, XP progression, and scanner-driven card generation into a single SwiftUI codebase.

## Product Pillars

- **Fast study creation**: Create subjects, decks, and cards with a workflow optimized for speed.
- **Effective recall**: Review cards through a spaced repetition engine and session-based study flow.
- **Scanner-assisted input**: Extract study material from images using Apple Vision OCR on device.
- **Private sync**: Persist data locally with SwiftData and sync eligible models through CloudKit.
- **Progress visibility**: Surface streaks, XP, daily goals, deck health, and review analytics.

## Core Capabilities

- Sign in with Apple onboarding
- Subject, deck, and card management
- Review sessions with graded quality outcomes
- Streak and XP systems
- Insights and deck health analytics
- OCR-powered scan to study flow
- Language-aware UI
- Settings, privacy, and profile/debug surfaces
- Cloud-backed study library with local fallback behavior

## Tech Stack

- **Language**: Swift
- **UI**: SwiftUI
- **Persistence**: SwiftData
- **Sync**: CloudKit
- **Authentication**: AuthenticationServices / Sign in with Apple
- **OCR**: Vision
- **State storage**: `@AppStorage` + SwiftData models
- **Charts / visualization**: Swift Charts
- **Testing**: Swift Testing

## Architecture

Neurova follows a modular, feature-oriented structure with clear separation between domain logic, persistence, and presentation.

### Layers

- **DesignSystem**
  Shared tokens, colors, typography, layout primitives, and reusable UI components.

- **Domain**
  Product rules and business logic for analytics, spaced repetition, streaks, gamification, generation, and study orchestration.

- **Data**
  Concrete implementations for repositories and services such as SwiftData persistence, Vision OCR, analytics storage, gamification storage, and Cloud account profile handling.

- **Features / UI**
  End-user experiences such as onboarding, home, library, scanner, study, insights, and settings.

### Architectural Characteristics

- SwiftUI-first implementation
- local-first data behavior
- CloudKit-enabled model container with local fallback
- feature slices over abstract framework-heavy layering
- reusable design system across product surfaces

## Repository Structure

```text
Neurova/
├── Neurova/
│   ├── Data/
│   ├── DesignSystem/
│   ├── Domain/
│   ├── Features/
│   ├── UI/
│   ├── Assets.xcassets/
│   └── NeurovaApp.swift
├── App/
├── Core/
├── Data/
├── DesignSystem/
├── Domain/
├── Features/
├── Neurova.xcodeproj
└── README_DEV.md
```

## Data Model and Persistence Strategy

The app uses a combined storage model:

- **SwiftData local store** for app persistence
- **CloudKit-backed configuration** for syncable entities
- **local-only store** for data that should remain device scoped

Current model container setup includes entities such as:

- `Subject`
- `Deck`
- `Card`
- `CloudAccountProfile`
- `XPEventEntity`
- `XPStatsEntity`
- `UserPreferences`
- `ScanEntity`

Key operational behavior:

- Cloud sync is enabled by default but guarded
- the app falls back to local mode if CloudKit initialization fails
- legacy local XP and preference data is migrated forward when possible

## Privacy and Security Model

Neurova is intentionally conservative in its privacy posture.

- Sign in with Apple is used for account identity
- Apple user ID, display name, and email may be stored when provided by Apple
- OCR runs on device through Apple Vision in the current build
- study data is stored locally and optionally synced with the user's private iCloud account
- the current app build does **not** include third-party ads, cross-app tracking, or external marketing analytics SDKs

Relevant product-facing privacy copy also exists in:

- `Neurova/Neurova/UI/Settings/PrivacyView.swift`

## Main User Flows

### 1. Onboarding

- Welcome and setup
- Daily goal selection
- Initial subject, deck, and card creation
- Sign in with Apple
- First guided study session

### 2. Library

- Organize content by subject
- Build decks and cards
- Prepare custom study material

### 3. Study

- Queue cards for active review
- Reveal front/back card states
- Grade recall quality
- Generate session summaries

### 4. Insights

- Review counts and quality breakdown
- Deck health
- Streak and XP context

### 5. Scanner

- Choose an image
- Run OCR on device
- Clean extracted text
- Convert material into study-ready content

## Key Screens and Responsibilities

- **Onboarding**: account bootstrap, initial content creation, first-session activation
- **Home**: progress dashboard, featured decks, recommendations, quick study entry
- **Library**: structured management of subjects, decks, and cards
- **Study**: core active recall workflow and session progression
- **Insights**: longitudinal review feedback and health metrics
- **Settings / Privacy**: user controls, privacy disclosures, debug profile surfaces

## Getting Started

### Requirements

- Xcode with current iOS SDK support
- Apple Developer account for Sign in with Apple, CloudKit, TestFlight, and App Store workflows
- iCloud-enabled simulator or device for sync-related validation

### Open the Project

```bash
open Neurova.xcodeproj
```

### Run Locally

1. Open the project in Xcode.
2. Select the `Neurova` scheme.
3. Choose an iPhone or iPad simulator.
4. Build and run.

## Build and Distribution Notes

Neurova is already prepared for:

- manual archive and upload to App Store Connect
- TestFlight internal distribution
- App Store submission metadata
- privacy disclosures and review notes

Operational notes:

- Xcode Cloud setup is currently being tracked separately
- App Store submission and TestFlight upload paths are already validated manually

## Recommended Development Workflow

1. Build vertical slices end-to-end.
2. Keep business rules inside `Domain`.
3. Implement persistence and external services inside `Data`.
4. Reuse `DesignSystem` primitives before adding one-off UI.
5. Validate compiler issues early from within Xcode.
6. Prefer incremental, shippable changes over speculative abstraction.

## Documentation Map

- `README_DEV.md`
  Product and development principles.

- `DesignSystem/README.md`
  Shared visual system notes.

- `App/README.md`, `Features/README.md`, `Data/README.md`, `Domain/README.md`
  Layer-specific notes and future expansion points.

## Roadmap Themes

- harden Xcode Cloud workflows
- continue expanding review analytics
- polish scanner-to-card generation flows
- deepen accessibility coverage
- grow regression and UI test coverage
- prepare operational documentation for post-launch iteration

## Brand and Product References

- Website: `https://neurova-web.vercel.app/`
- Support: `https://neurova-web.vercel.app/support`
- Privacy Policy: `https://neurova-web.vercel.app/privacy`

## Ownership

Neurova is designed and developed by Angel Orellana.

---

<p align="center">
  Built for focused study, private sync, and production-grade iOS delivery.
</p>
