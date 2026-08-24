#!/usr/bin/env bun

import { existsSync } from "node:fs";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

const ROOT = process.cwd();
const RUNTIME = path.join(ROOT, ".agent", "runtime");
const ISSUE_DIR = path.join(ROOT, ".agent", "issues");
await mkdir(RUNTIME, { recursive: true });
await mkdir(ISSUE_DIR, { recursive: true });

type Policy = {
  models: Record<string, string>;
  thinking: Record<string, string>;
  limits: {
    maxTasks: number;
    maxTaskAttempts: number;
    maxReviewCycles: number;
    maxVisualCycles: number;
    maxChangedFiles: number;
    maxDiffLines: number;
    ompTimeoutMinutes: number;
    verifyTimeoutMinutes: number;
  };
  autoMerge: boolean;
  forbiddenAutoEditPrefixes: string[];
  reviewRequiredPatterns: string[];
  protectedFiles: string[];
  secretMarkers: string[];
};

type Task = {
  id: string;
  title: string;
  status: "pending" | "completed" | "blocked";
  acceptance?: string[];
  notes?: string;
};

type IssuePlan = {
  issueNumber: number;
  summary: string;
  risk: "low" | "medium" | "high";
  uiImpact: boolean;
  tasks: Task[];
};

const policy: Policy = JSON.parse(await readFile(path.join(ROOT, "automation", "policy.json"), "utf8"));
const issueNumber = Number(process.env.ISSUE_NUMBER || "0");
const repo = process.env.GH_REPO || "";
const baseBranch = process.env.BASE_BRANCH || "main";
const repoPrivate = String(process.env.REPO_PRIVATE || "false") === "true";
const allowPublic = String(process.env.ALLOW_PUBLIC_AUTONOMY || "false").toLowerCase() === "true";

if (!issueNumber || !repo) failFast("ISSUE_NUMBER or GH_REPO missing");

function log(message: string) {
  console.log(`[agent] ${message}`);
}

function failFast(message: string): never {
  throw new Error(message);
}

function ompSafeEnv(): Record<string, string> {
  const keys = [
    "PATH", "HOME", "USER", "LOGNAME", "SHELL", "TMPDIR", "LANG", "LC_ALL", "TERM",
    "DEVELOPER_DIR", "SSH_AUTH_SOCK",
  ];
  const env: Record<string, string> = {};
  for (const key of keys) {
    const value = process.env[key];
    if (value) env[key] = value;
  }
  return env;
}

function gitAuthEnv(): Record<string, string> {
  const token = process.env.GH_TOKEN || "";
  if (!token) failFast("AGENT_GITHUB_TOKEN/GH_TOKEN is missing");
  const basic = Buffer.from(`x-access-token:${token}`).toString("base64");
  return {
    GIT_CONFIG_COUNT: "1",
    GIT_CONFIG_KEY_0: "http.extraHeader",
    GIT_CONFIG_VALUE_0: `Authorization: Basic ${basic}`,
  };
}

async function exec(cmd: string[], options: { timeoutMs?: number; allowFailure?: boolean; env?: Record<string, string>; cleanEnv?: boolean } = {}) {
  const env = (options.cleanEnv ? { ...(options.env || {}) } : { ...process.env, ...(options.env || {}) }) as Record<string, string>;
  const proc = Bun.spawn(cmd, { cwd: ROOT, stdout: "pipe", stderr: "pipe", env });
  let timedOut = false;
  const timeoutMs = options.timeoutMs ?? 10 * 60_000;
  const timer = setTimeout(() => {
    timedOut = true;
    proc.kill();
  }, timeoutMs);
  const [stdout, stderr, code] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ]);
  clearTimeout(timer);
  if ((code !== 0 || timedOut) && !options.allowFailure) {
    const suffix = timedOut ? ` timed out after ${timeoutMs}ms` : ` exited ${code}`;
    throw new Error(`${cmd.join(" ")}${suffix}\n${stdout}\n${stderr}`);
  }
  return { code, stdout, stderr, timedOut };
}

async function gh(args: string[], allowFailure = false) {
  return exec(["gh", ...args], { allowFailure, timeoutMs: 3 * 60_000 });
}

async function issueComment(body: string) {
  await gh(["issue", "comment", String(issueNumber), "--body", body], true);
}

async function issueLabels(add: string[] = [], remove: string[] = []) {
  const args = ["issue", "edit", String(issueNumber)];
  for (const l of add) args.push("--add-label", l);
  for (const l of remove) args.push("--remove-label", l);
  await gh(args, true);
}

async function getIssue() {
  const r = await gh(["issue", "view", String(issueNumber), "--json", "number,title,body,author,labels,url"]);
  return JSON.parse(r.stdout);
}

async function omp(opts: { model: string; thinking: string; prompt: string; files?: string[]; tools?: string[]; noTools?: boolean }) {
  const args = [
    "omp", "-p", "--no-session", "--no-title", "--no-extensions", "--no-skills",
    "--model", opts.model,
    "--thinking", opts.thinking,
  ];
  if (opts.noTools) args.push("--no-tools");
  else if (opts.tools?.length) args.push("--tools", opts.tools.join(","));
  for (const file of opts.files || []) {
    if (existsSync(path.join(ROOT, file))) args.push(`@${file}`);
  }
  args.push(opts.prompt);
  const r = await exec(args, {
    timeoutMs: policy.limits.ompTimeoutMinutes * 60_000,
    allowFailure: true,
    cleanEnv: true,
    env: ompSafeEnv(),
  });
  const combined = `${r.stdout}\n${r.stderr}`.trim();
  if (r.code !== 0 || r.timedOut) throw new Error(`OMP failed (${opts.model})\n${combined}`);
  return combined;
}

async function readPrompt(name: string) {
  return readFile(path.join(ROOT, "automation", "prompts", name), "utf8");
}

async function writeIssueFile(issue: any) {
  const p = path.join(RUNTIME, `issue-${issueNumber}.md`);
  const text = `# GitHub Issue #${issueNumber}\n\n## Title\n${issue.title}\n\n## Author\n${issue.author?.login || "unknown"}\n\n## URL\n${issue.url}\n\n## Body\n${issue.body || "(empty)"}\n`;
  await writeFile(p, text);
  return path.relative(ROOT, p);
}

async function ensureTrust(issue: any) {
  if (!repoPrivate && !allowPublic) {
    await issueLabels(["agent-blocked"], ["agent-ready"]);
    await issueComment("Autonomous execution refused because this repository is public. Use a private repository or explicitly opt in after reviewing self-hosted-runner security risks.");
    failFast("Public repository rejected by policy");
  }

  const owner = repo.split("/")[0];
  const configured = (process.env.AGENT_ALLOWED_ACTORS || "").split(",").map(s => s.trim()).filter(Boolean);
  const allowed = configured.length ? configured : [owner];
  const actor = issue.author?.login || "";
  if (!allowed.includes(actor)) {
    await issueLabels(["agent-blocked"], ["agent-ready"]);
    await issueComment(`Autonomous execution refused. Issue author \`${actor}\` is not in AGENT_ALLOWED_ACTORS.`);
    failFast(`Untrusted issue author: ${actor}`);
  }
}

async function git(...args: string[]) {
  return exec(["git", ...args], { timeoutMs: 5 * 60_000, env: gitAuthEnv() });
}

async function setupBranch() {
  const branch = `agent/issue-${issueNumber}`;
  await git("fetch", "origin", baseBranch);
  const remote = await exec(["git", "ls-remote", "--exit-code", "--heads", "origin", branch], { allowFailure: true, env: gitAuthEnv() });
  if (remote.code === 0) {
    await git("fetch", "origin", branch);
    await git("checkout", "-B", branch, `origin/${branch}`);
  } else {
    await git("checkout", "-B", branch, `origin/${baseBranch}`);
  }
  await git("config", "user.name", "ios-agent-bot");
  await git("config", "user.email", "ios-agent-bot@users.noreply.github.com");
  return branch;
}

async function loadPlan(planPath: string): Promise<IssuePlan> {
  const raw = await readFile(planPath, "utf8");
  const plan = JSON.parse(raw) as IssuePlan;
  if (plan.issueNumber !== issueNumber) failFast(`Plan issueNumber mismatch: ${plan.issueNumber}`);
  if (!Array.isArray(plan.tasks) || plan.tasks.length === 0 || plan.tasks.length > policy.limits.maxTasks) {
    failFast(`Invalid task count: ${plan.tasks?.length}`);
  }
  return plan;
}

async function savePlan(planPath: string, plan: IssuePlan) {
  await writeFile(planPath, JSON.stringify(plan, null, 2) + "\n");
}

async function commitAndPush(branch: string, message: string) {
  const status = (await git("status", "--porcelain")).stdout.trim();
  if (!status) return;
  await git("add", "-A");
  await exec(["git", "reset", "--", ".agent/local.env"], { allowFailure: true });
  await exec(["git", "reset", "--", ".agent/runtime"], { allowFailure: true });
  const staged = (await git("diff", "--cached", "--name-only")).stdout.trim();
  if (!staged) return;

  const stagedNames = staged.split("\n").map(s => s.trim()).filter(Boolean);
  const forbidden = stagedNames.filter(n =>
    policy.forbiddenAutoEditPrefixes.some(p => n.startsWith(p)) || policy.protectedFiles.includes(n)
  );
  if (forbidden.length) {
    throw new Error(`Refusing to checkpoint protected automation files: ${forbidden.join(", ")}`);
  }
  const stagedDiff = (await git("diff", "--cached")).stdout;
  const secretHits = policy.secretMarkers.filter(marker => stagedDiff.includes(marker));
  if (secretHits.length) {
    throw new Error(`Refusing to checkpoint possible secret markers: ${secretHits.join(", ")}`);
  }

  await git("commit", "-m", message);
  await git("push", "-u", "origin", branch);
}

async function runVerify(logName: string) {
  const r = await exec(["./scripts/verify-ios.sh"], {
    timeoutMs: policy.limits.verifyTimeoutMinutes * 60_000,
    allowFailure: true,
  });
  const logPath = path.join(RUNTIME, logName);
  await writeFile(logPath, `$ ./scripts/verify-ios.sh\n\n${r.stdout}\n${r.stderr}`);
  return { ok: r.code === 0 && !r.timedOut, relLog: path.relative(ROOT, logPath) };
}

async function currentDiffFile(name = "diff.patch") {
  const r = await exec(["git", "diff", `origin/${baseBranch}...HEAD`], { allowFailure: true });
  const w = await exec(["git", "diff"], { allowFailure: true });
  const p = path.join(RUNTIME, name);
  await writeFile(p, `${r.stdout}\n${w.stdout}`);
  return path.relative(ROOT, p);
}

function verdict(text: string) {
  if (/VERDICT=APPROVE\b/.test(text)) return "APPROVE";
  if (/VERDICT=BLOCK\b/.test(text)) return "BLOCK";
  return "UNKNOWN";
}

async function safetyScan() {
  await git("fetch", "origin", baseBranch);
  const namesRaw = (await exec(["git", "diff", "--name-only", `origin/${baseBranch}...HEAD`], { allowFailure: true })).stdout;
  const unstaged = (await exec(["git", "diff", "--name-only"], { allowFailure: true })).stdout;
  const names = Array.from(new Set([...namesRaw.split("\n"), ...unstaged.split("\n")].map(s => s.trim()).filter(Boolean)));

  const numstat = (await exec(["git", "diff", "--numstat", `origin/${baseBranch}...HEAD`], { allowFailure: true })).stdout;
  let lines = 0;
  for (const line of numstat.split("\n")) {
    const [a, d] = line.split("\t");
    if (/^\d+$/.test(a || "")) lines += Number(a);
    if (/^\d+$/.test(d || "")) lines += Number(d);
  }

  const forbidden = names.filter(n => policy.forbiddenAutoEditPrefixes.some(p => n.startsWith(p)) || policy.protectedFiles.includes(n));
  const reviewRequired = names.filter(n => policy.reviewRequiredPatterns.some(p => n.endsWith(p) || n.includes(p)));

  if (names.length > policy.limits.maxChangedFiles) forbidden.push(`TOO_MANY_FILES:${names.length}`);
  if (lines > policy.limits.maxDiffLines) forbidden.push(`DIFF_TOO_LARGE:${lines}`);

  const diff = (await exec(["git", "diff", `origin/${baseBranch}...HEAD`], { allowFailure: true })).stdout;
  const secretHits = policy.secretMarkers.filter(marker => diff.includes(marker));
  if (secretHits.length) forbidden.push(`SECRET_MARKER:${secretHits.join(",")}`);

  return { names, lines, forbidden, reviewRequired, autoMergeSafe: forbidden.length === 0 && reviewRequired.length === 0 };
}

async function block(reason: string, branch?: string) {
  log(`BLOCKED: ${reason}`);
  if (branch) {
    await commitAndPush(branch, `agent(#${issueNumber}): checkpoint blocked state`).catch(() => {});
  }
  await issueLabels(["agent-blocked"], ["agent-running", "agent-ready"]);
  await issueComment(`Autonomous run stopped.\n\n**Reason:** ${reason}\n\nAny completed checkpoints remain on branch \`agent/issue-${issueNumber}\`.`);
  process.exit(1);
}

try {
  const issue = await getIssue();
  await ensureTrust(issue);
  await issueLabels(["agent-running"], ["agent-ready", "agent-blocked", "agent-done"]);
  await issueComment("Autonomous iOS agent started. I will plan, implement, verify, run Simulator smoke checks, review, and open an auto-merge PR if policy permits.");

  const issueFile = await writeIssueFile(issue);
  const branch = await setupBranch();
  const planPath = path.join(ISSUE_DIR, `issue-${issueNumber}.json`);
  const planRel = path.relative(ROOT, planPath);

  if (!existsSync(planPath)) {
    log("Planning with Sol");
    const architectPrompt = await readPrompt("architect.md");
    await omp({
      model: policy.models.architect,
      thinking: policy.thinking.architect,
      tools: ["read", "grep", "find", "edit", "write", "lsp"],
      files: [issueFile, "AGENTS.md", ".agent/AUTONOMY.md", ".agent/PRODUCT.md", ".agent/ARCHITECTURE.md", ".agent/UI_GUIDELINES.md", ".agent/TEST_PLAN.md"],
      prompt: `${architectPrompt}\n\nWrite the plan to ${planRel}.`,
    });
    const plan = await loadPlan(planPath);
    await savePlan(planPath, plan);
    await commitAndPush(branch, `agent(#${issueNumber}): plan issue`);
  }

  let plan = await loadPlan(planPath);

  for (const task of plan.tasks) {
    if (task.status === "completed") continue;
    log(`Task ${task.id}: ${task.title}`);
    let passed = false;
    let lastLog = "";
    let triageFile = "";

    for (let attempt = 1; attempt <= policy.limits.maxTaskAttempts; attempt++) {
      const implementPrompt = await readPrompt("implement.md");
      const files = [issueFile, planRel, "AGENTS.md", ".agent/AUTONOMY.md", ".agent/PRODUCT.md", ".agent/ARCHITECTURE.md", ".agent/UI_GUIDELINES.md"];
      if (lastLog) files.push(lastLog);
      if (triageFile) files.push(triageFile);

      await omp({
        model: policy.models.implementer,
        thinking: policy.thinking.implementer,
        tools: ["read", "grep", "find", "edit", "write", "lsp"],
        files,
        prompt: `${implementPrompt}\n\nCurrent task: ${task.id} - ${task.title}\nAttempt: ${attempt}/${policy.limits.maxTaskAttempts}`,
      });

      const verify = await runVerify(`verify-${task.id}-attempt-${attempt}.log`);
      lastLog = verify.relLog;
      if (verify.ok) {
        passed = true;
        break;
      }

      if (attempt === policy.limits.maxTaskAttempts - 1) {
        const diffFile = await currentDiffFile(`triage-${task.id}.patch`);
        const triagePrompt = await readPrompt("triage.md");
        const triage = await omp({
          model: policy.models.reviewer,
          thinking: policy.thinking.reviewer,
          noTools: true,
          files: [issueFile, planRel, lastLog, diffFile, ".agent/ARCHITECTURE.md"],
          prompt: `${triagePrompt}\n\nTask: ${task.id} - ${task.title}`,
        });
        const p = path.join(RUNTIME, `triage-${task.id}.md`);
        await writeFile(p, triage);
        triageFile = path.relative(ROOT, p);
      }
    }

    if (!passed) await block(`Task ${task.id} failed deterministic verification after ${policy.limits.maxTaskAttempts} attempts.`, branch);

    task.status = "completed";
    await savePlan(planPath, plan);
    await commitAndPush(branch, `agent(#${issueNumber}): complete ${task.id}`);
  }

  // Final deterministic verification.
  const finalVerify = await runVerify("verify-final.log");
  if (!finalVerify.ok) await block("Final deterministic verification failed after all tasks were marked complete.", branch);

  // Automated Simulator smoke + vision review for UI-impact issues.
  plan = await loadPlan(planPath);
  if (plan.uiImpact) {
    for (let cycle = 1; cycle <= policy.limits.maxVisualCycles; cycle++) {
      const smoke = await exec(["./scripts/agent-simulator-smoke.sh"], { timeoutMs: 30 * 60_000, allowFailure: true });
      await writeFile(path.join(RUNTIME, `simulator-cycle-${cycle}.log`), `${smoke.stdout}\n${smoke.stderr}`);
      if (smoke.code !== 0) await block("Automated Simulator smoke test failed.", branch);

      const screenshotRel = ".agent/runtime/simulator-latest.png";
      const visualPrompt = await readPrompt("visual-review.md");
      const result = await omp({
        model: policy.models.vision,
        thinking: policy.thinking.vision,
        noTools: true,
        files: [screenshotRel, issueFile, ".agent/UI_GUIDELINES.md"],
        prompt: visualPrompt,
      });
      await writeFile(path.join(RUNTIME, `visual-review-${cycle}.md`), result);
      if (verdict(result) === "APPROVE") break;
      if (cycle === policy.limits.maxVisualCycles) await block("Luna visual review still blocks after the maximum visual repair cycles.", branch);

      const implementPrompt = await readPrompt("implement.md");
      await omp({
        model: policy.models.implementer,
        thinking: policy.thinking.implementer,
        tools: ["read", "grep", "find", "edit", "write", "lsp"],
        files: [issueFile, planRel, `.agent/runtime/visual-review-${cycle}.md`, screenshotRel],
        prompt: `${implementPrompt}\n\nFix only the blocking visual findings. Do not broaden scope.`,
      });
      const verify = await runVerify(`verify-visual-${cycle}.log`);
      if (!verify.ok) await block("Verification failed after visual repair.", branch);
      await commitAndPush(branch, `agent(#${issueNumber}): visual repair ${cycle}`);
    }
  }

  // Luna code review + repair cycles.
  for (let cycle = 1; cycle <= policy.limits.maxReviewCycles; cycle++) {
    const diffFile = await currentDiffFile(`review-${cycle}.patch`);
    const reviewPrompt = await readPrompt("review.md");
    const result = await omp({
      model: policy.models.reviewer,
      thinking: policy.thinking.reviewer,
      noTools: true,
      files: [diffFile, issueFile, planRel, "AGENTS.md", ".agent/AUTONOMY.md", ".agent/PRODUCT.md", ".agent/ARCHITECTURE.md"],
      prompt: reviewPrompt,
    });
    const reviewRel = `.agent/runtime/review-${cycle}.md`;
    await writeFile(path.join(ROOT, reviewRel), result);
    if (verdict(result) === "APPROVE") break;
    if (cycle === policy.limits.maxReviewCycles) await block("Luna code review remains blocking after the maximum repair cycles.", branch);

    const implementPrompt = await readPrompt("implement.md");
    await omp({
      model: policy.models.implementer,
      thinking: policy.thinking.implementer,
      tools: ["read", "grep", "find", "edit", "write", "lsp"],
      files: [issueFile, planRel, reviewRel],
      prompt: `${implementPrompt}\n\nFix only the blocking findings from Luna review cycle ${cycle}.`,
    });
    const verify = await runVerify(`verify-review-${cycle}.log`);
    if (!verify.ok) await block("Verification failed after code-review repair.", branch);
    await commitAndPush(branch, `agent(#${issueNumber}): review repair ${cycle}`);
  }

  // High-risk issues receive a final Sol read-only review.
  plan = await loadPlan(planPath);
  if (plan.risk === "high") {
    const diffFile = await currentDiffFile("sol-final.patch");
    const escalationPrompt = await readPrompt("escalation.md");
    const result = await omp({
      model: policy.models.escalation,
      thinking: policy.thinking.escalation,
      noTools: true,
      files: [diffFile, issueFile, planRel, "AGENTS.md", ".agent/AUTONOMY.md", ".agent/ARCHITECTURE.md"],
      prompt: escalationPrompt,
    });
    await writeFile(path.join(RUNTIME, "sol-final-review.md"), result);
    if (verdict(result) !== "APPROVE") await block("High-risk Sol final review did not approve autonomous completion.", branch);
  }

  // Safety scan after all model work.
  const scan = await safetyScan();
  log(`Safety scan: ${scan.names.length} files, ${scan.lines} changed lines`);
  if (scan.forbidden.length) await block(`Safety policy violation: ${scan.forbidden.join(", ")}`, branch);

  await commitAndPush(branch, `agent(#${issueNumber}): final verified state`);

  // Rebase onto latest main before PR if possible.
  await git("fetch", "origin", baseBranch);
  const behind = await exec(["git", "merge-base", "--is-ancestor", `origin/${baseBranch}`, "HEAD"], { allowFailure: true });
  if (behind.code !== 0) {
    const rb = await exec(["git", "rebase", `origin/${baseBranch}`], { allowFailure: true, timeoutMs: 10 * 60_000 });
    if (rb.code !== 0) {
      await exec(["git", "rebase", "--abort"], { allowFailure: true });
      await block("Branch could not rebase cleanly onto latest main.", branch);
    }
    const verify = await runVerify("verify-after-rebase.log");
    if (!verify.ok) await block("Verification failed after rebasing onto latest main.", branch);
    await git("push", "--force-with-lease", "origin", branch);
  }

  let prUrl = "";
  const existing = await gh(["pr", "list", "--head", branch, "--state", "open", "--json", "url", "--jq", ".[0].url"], true);
  prUrl = existing.stdout.trim();
  if (!prUrl) {
    const prBodyPath = path.join(RUNTIME, "pr-body.md");
    const autoNote = scan.autoMergeSafe ? "Eligible for autonomous merge." : `Human review required for: ${scan.reviewRequired.join(", ")}`;
    await writeFile(prBodyPath,
      `Fixes #${issueNumber}\n\n## Autonomous run\n- All planned tasks completed\n- Deterministic verify passed\n- Luna code review passed\n${plan.uiImpact ? "- Simulator smoke + Luna visual review passed\n" : ""}${plan.risk === "high" ? "- Sol high-risk review passed\n" : ""}- ${autoNote}\n`);
    const created = await gh(["pr", "create", "--base", baseBranch, "--head", branch, "--title", `Agent #${issueNumber}: ${issue.title}`, "--body-file", prBodyPath]);
    prUrl = created.stdout.trim().split("\n").pop() || "";
  }

  if (!scan.autoMergeSafe || !policy.autoMerge) {
    await issueLabels(["agent-review-required"], ["agent-running"]);
    await issueComment(`Implementation completed and PR opened: ${prUrl}\n\nPolicy requires human review before merge because these sensitive files changed: ${scan.reviewRequired.join(", ") || "policy auto-merge disabled"}.`);
    process.exit(0);
  }

  await issueComment(`Implementation and local review passed. PR opened: ${prUrl}\n\nAuto-merge is being enabled. The separate **iOS CI** workflow will re-run deterministic verification; when it passes, GitHub will merge the PR and close this issue automatically.`);

  const merge = await gh(["pr", "merge", prUrl, "--auto", "--squash", "--delete-branch"], true);
  if (merge.code !== 0) {
    await issueLabels(["agent-review-required"], ["agent-running"]);
    await issueComment(`Could not enable auto-merge automatically. PR remains open: ${prUrl}\n\nCLI output:\n\`\`\`\n${merge.stdout}\n${merge.stderr}\n\`\`\``);
  }

  log(`PR ready: ${prUrl}`);
} catch (error: any) {
  console.error(error?.stack || error);
  await issueLabels(["agent-blocked"], ["agent-running", "agent-ready"]).catch(() => {});
  await issueComment(`Autonomous run failed unexpectedly.\n\n\`\`\`\n${String(error?.message || error).slice(0, 5000)}\n\`\`\``).catch(() => {});
  process.exit(1);
}
