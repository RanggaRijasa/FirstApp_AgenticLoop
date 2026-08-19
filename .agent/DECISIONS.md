# Decisions

Use this file for architectural or product decisions that future agents must not rediscover.

Do not add trivial implementation choices.

## Template

### YYYY-MM-DD - Decision title

**Decision:**

Describe the durable decision.

**Reason:**

Explain why this decision exists.

**Alternatives considered:**

- Alternative A
- Alternative B

**Consequences:**

Describe important tradeoffs or future constraints.

---

## 2026-08-19 - Native SwiftUI application

**Decision:**

Build Cartsyne as a native Swift and SwiftUI iOS application.

**Reason:**

The product is focused on a fast, polished iPhone experience and benefits from native controls, accessibility, performance, SwiftData, widgets, App Intents, and other Apple platform integrations.

**Alternatives considered:**

- React Native
- Flutter
- Web/PWA

**Consequences:**

The initial product targets Apple platforms only. Android and web clients are outside MVP scope.

---

## 2026-08-19 - Minimum deployment target is iOS 18

**Decision:**

Target iOS 18 and later.

**Reason:**

This provides access to modern SwiftUI, Observation, SwiftData, and platform APIs while maintaining compatibility with a useful range of supported devices.

**Alternatives considered:**

- iOS 17
- latest iOS only

**Consequences:**

Code may rely on APIs available in iOS 18 but should avoid unnecessary use of newer APIs that would force the deployment target upward.

---

## 2026-08-19 - SwiftData local persistence

**Decision:**

Use SwiftData as the source of truth for grocery lists and grocery items.

**Reason:**

The data is structured, relational, local-first, and well suited to SwiftData.

**Alternatives considered:**

- UserDefaults
- JSON files
- Core Data
- SQLite
- remote backend

**Consequences:**

Persistent model evolution and migrations must be considered as the schema changes.

---

## 2026-08-19 - No backend for MVP

**Decision:**

Cartsyne MVP has no application backend.

**Reason:**

The core product does not require an account, collaboration, remote data, or online services.

Removing the backend reduces complexity and supports instant offline use.

**Alternatives considered:**

- custom REST API
- Firebase
- Supabase
- CloudKit from version 1

**Consequences:**

Cross-device synchronization and shared household lists are deferred.

---

## 2026-08-19 - No account required

**Decision:**

Users can use every MVP feature without creating an account.

**Reason:**

Account creation adds friction before the primary value of the app is experienced.

**Alternatives considered:**

- Sign in with Apple
- email/password accounts
- anonymous backend accounts

**Consequences:**

Account-dependent functionality such as shared lists is not part of MVP.

---

## 2026-08-19 - Local category suggestion

**Decision:**

Grocery category suggestions use local deterministic rules for MVP.

**Reason:**

Automatic categorization does not initially require an AI model or external service.

Local categorization is:

- instant
- predictable
- testable
- private
- available offline

**Alternatives considered:**

- remote LLM
- on-device ML model
- no automatic categorization

**Consequences:**

The initial category vocabulary will require maintenance and will not understand every grocery item.

Users can always override the result.

---

## 2026-08-19 - No third-party architecture framework

**Decision:**

Use SwiftUI, Observation, feature models, dependency injection, and simple service boundaries.

**Reason:**

Cartsyne's MVP does not require a larger architecture framework.

**Alternatives considered:**

- The Composable Architecture
- RxSwift
- custom Redux architecture

**Consequences:**

Architecture remains lightweight. This decision can be revisited if application complexity materially increases.

---

## 2026-08-19 - Zero third-party runtime dependencies initially

**Decision:**

The initial application should use only Apple frameworks unless a concrete requirement justifies otherwise.

**Reason:**

The MVP requirements can be implemented using native frameworks.

**Alternatives considered:**

Adding packages for persistence, networking, analytics, UI components, or state management.

**Consequences:**

Lower dependency risk and simpler maintenance, at the cost of implementing small app-specific utilities internally when required.
