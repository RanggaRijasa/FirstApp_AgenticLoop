Perform a final architecture and release-readiness review for the completed feature.

Verify that:
- implementation matches PRODUCT.md and acceptance criteria
- architecture remains coherent
- no unsafe project/signing/capability changes slipped in
- build/test evidence is present
- manual Simulator validation has been recorded when UI changed
- no secrets or debug-only artifacts are staged
- the change is suitable to commit and merge

Return either READY_TO_COMMIT or BLOCKED, followed by concise reasons.
