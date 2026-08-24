# Issue plans

The autonomous architect writes one durable JSON plan per GitHub issue:

`.agent/issues/issue-<number>.json`

The controller updates task status after deterministic verification passes. These files are committed so an interrupted run can resume from the existing `agent/issue-<number>` branch.
