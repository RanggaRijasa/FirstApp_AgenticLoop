Review the current feature branch as a senior Swift/iOS reviewer.

Read AGENTS.md and .agent architecture/product files first.
Review the diff against main and focus on:
- correctness and edge cases
- Swift concurrency and actor isolation
- SwiftUI state/data flow
- architecture boundary violations
- accessibility and UI states
- error handling
- test gaps
- unnecessary complexity
- accidental project/signing/capability changes

Return findings ordered by severity. If there are no blocking findings, say APPROVE and list any non-blocking follow-ups separately.
Do not edit code unless I explicitly ask you to fix the findings.
