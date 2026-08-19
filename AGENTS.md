# Repository Agent Instructions

## Product and architecture context
Before changing code, read:
- `.agent/PRODUCT.md`
- `.agent/ARCHITECTURE.md`
- `.agent/UI_GUIDELINES.md`
- `.agent/TASKS.json`
- `.agent/DECISIONS.md`

## Scope
This is a native iOS SwiftUI application. Xcode is the source of truth for project settings, signing, capabilities, targets, schemes, and simulator launch.

## Hard rules
- Do not edit signing, provisioning, Team, bundle identifier, entitlements, or capabilities unless the task explicitly requires it and the human approves.
- Do not manually edit `project.pbxproj` unless there is no safe alternative and the human explicitly approves.
- Do not add third-party frameworks without architecture approval.
- Do not put API keys, tokens, passwords, certificates, or production secrets in the repository.
- Do not weaken or delete tests merely to make verification pass.
- Do not push directly to `main`.
- Do not launch or control the iOS Simulator automatically. The human launches it from Xcode.
- Prefer native SwiftUI and Apple frameworks. Use UIKit only when there is a documented reason.

## Implementation defaults
- SwiftUI for UI.
- Swift Observation (`@Observable`) when compatible with the project's deployment target.
- Structured concurrency with `async/await`.
- `NavigationStack` for navigation when appropriate.
- `URLSession` for ordinary networking unless architecture says otherwise.
- Persistence technology is selected per product need; do not assume SwiftData is required.
- Prefer feature-oriented folders and small, testable services.

## Task workflow
1. Select exactly one task from `.agent/TASKS.json` whose status is `pending` and whose dependencies are complete.
2. Restate the acceptance criteria before editing.
3. Inspect the existing code and reuse project conventions.
4. Implement the smallest coherent change that satisfies the task.
5. Run `./scripts/verify-ios.sh`.
6. If verification fails, diagnose and fix. Maximum three implementation/verification attempts before reporting the blocker.
7. If verification passes, summarize changed files, tests, and any manual simulator checks still required.
8. Do not mark the task `done` until review and manual UI validation are complete when the task has visible UI behavior.

## Definition of done
A task is done only when:
- acceptance criteria are met;
- build passes;
- relevant automated tests pass;
- no new warnings/errors are knowingly introduced;
- user-facing UI has been manually checked in Simulator when applicable;
- reviewer feedback is resolved;
- the change is committed on a feature branch.
