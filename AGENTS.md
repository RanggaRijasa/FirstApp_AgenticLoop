# Repository Agent Instructions - Multica Autonomous v5

## Read first
Before changing code, read:
- `.agent/PRODUCT.md`
- `.agent/ARCHITECTURE.md`
- `.agent/UI_GUIDELINES.md`
- `.agent/DECISIONS.md`
- `.agent/TEST_PLAN.md`

The current Multica issue is the source of truth for the work request, scope, and acceptance criteria. Do not use `.agent/TASKS.json` as the task queue in v5.

## Platform
This is a native iOS SwiftUI application. Xcode remains the source of truth for project settings, signing, capabilities, targets, and schemes.

## Hard rules
- Never push directly to `main`.
- Create or reuse a feature branch whose name contains the Multica issue ID, for example `cart-42-favorites-empty-state`.
- Do not edit signing, provisioning, Team, bundle identifier, entitlements, or capabilities unless the issue explicitly requires it and the Lead has classified the work as allowed.
- Do not manually edit `project.pbxproj` unless there is no safe alternative. Any change to `*.pbxproj`, `*.entitlements`, `*.xcconfig`, `Package.swift`, `Package.resolved`, or signing configuration requires `in_review` and must not be auto-merged.
- Do not add third-party frameworks without architecture approval.
- Never store API keys, tokens, passwords, certificates, or production secrets in the repository.
- Do not weaken or delete tests merely to make verification pass.
- Prefer native SwiftUI and Apple frameworks. Use UIKit only when a documented need exists.
- Keep changes within the current Multica issue scope.

## Automation allowed in v5
Agents may:
- run `xcodebuild`, XCTest, and XCUITest;
- boot or control an iOS Simulator with `xcrun simctl` for verification;
- capture screenshots into `.agent/screenshots/`;
- create feature branches, commit, push, and create GitHub pull requests;
- merge a pull request only after the Multica Reviewer has returned `APPROVE` and all local gates pass.

## Implementation defaults
- SwiftUI for UI.
- Swift Observation (`@Observable`) when compatible with the deployment target.
- Structured concurrency with `async/await` and cancellation where needed.
- `NavigationStack` for hierarchical navigation when appropriate.
- `URLSession` for ordinary networking unless architecture says otherwise.
- Persistence follows documented product needs and architecture decisions; Cartsyne currently uses SwiftData.
- Prefer feature-oriented folders and small, testable services.

## Verification
After code changes:
1. Run `./scripts/verify-ios.sh`.
2. If UI changed, run `./scripts/agent-simulator-smoke.sh` and inspect the latest screenshot.
3. Interactive acceptance criteria must be covered by XCUITest when practical. A launch screenshot is only a visual smoke check.
4. Maximum three implementation/verification attempts before reporting a blocker.

## Git and PR delivery
- Branch name must contain the Multica issue ID.
- Commit messages should be scoped and clear.
- Push the feature branch, never `main`.
- Create a PR whose title contains the issue ID.
- The PR body must contain a close intent exactly like `Closes CART-42` so Multica can move the issue to Done after merge.
- Do not merge until Reviewer says `APPROVE` in the Multica issue and final verification passes.
- For normal low/medium-risk source or test changes, merge with `gh pr merge --squash --delete-branch`.
- After merge, return the local checkout to a clean `main` and pull the latest changes.

## Definition of done
Normal development work is done when:
- acceptance criteria are met;
- build and automated tests pass;
- UI changes pass simulator smoke review and required XCUITests;
- Reviewer returns `APPROVE`;
- PR is merged;
- GitHub integration has moved the linked Multica issue to `Done`.

Sensitive project, signing, and dependency changes intentionally stop in `in_review` for human approval.
