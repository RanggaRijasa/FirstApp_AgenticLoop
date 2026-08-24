# iOS Agent Factory v4 - Fully Autonomous

This kit upgrades the v3 semi-autonomous workflow into:

GitHub Issue -> dedicated macOS self-hosted runner -> OMP -> Sol plan -> DeepSeek implementation -> deterministic Xcode verify -> automated Simulator smoke -> Luna vision/code review -> PR -> iOS CI -> auto-merge -> Issue closed.

## Assumptions

The target iOS repository already has the v3 setup working:

- `AGENTS.md`
- `.agent/PRODUCT.md`
- `.agent/ARCHITECTURE.md`
- `.agent/UI_GUIDELINES.md`
- `scripts/verify-ios.sh`
- valid Xcode project/scheme/simulator settings
- OMP configured with DeepSeek V4 Flash + GPT-5.6 Luna/Sol

Copy the contents of this kit into the root of that repository. Review existing files before overwriting anything.

## Trigger

Create an issue using the **Autonomous Agent Task** issue form. The form applies the `agent-ready` label. GitHub Actions listens for that label and dispatches the job to a dedicated macOS self-hosted runner.

## One-time GitHub bot credential

Create a **fine-grained personal access token** dedicated to this automation and store it as the repository Actions secret:

- `AGENT_GITHUB_TOKEN`

Give it access only to this private repository, with the minimum repository permissions needed by the controller:

- Contents: Read and write
- Issues: Read and write
- Pull requests: Read and write
- Metadata: Read

Why this extra token is required: a PR created with the workflow's default `GITHUB_TOKEN` can leave the resulting `pull_request` CI run waiting for manual approval. Creating the PR with this dedicated PAT allows the normal PR CI workflow to start automatically. Do not put the token in `.agent/`, OMP config, or the repository.

For a larger/long-lived installation, replace the PAT with a narrowly scoped GitHub App token.

## One-time repository variables

Create these under GitHub repository:

Settings -> Secrets and variables -> Actions -> Variables

- `IOS_CONTAINER` e.g. `MyApp.xcodeproj`
- `IOS_SCHEME` e.g. `MyApp`
- `IOS_SIMULATOR` e.g. `iPhone 17 Pro`
- `AGENT_ALLOWED_ACTORS` e.g. `your-github-username`
- optional `ALLOW_PUBLIC_AUTONOMY` = `false`

## One-time repository settings

- Private repository required by the default safety policy.
- Enable Issues.
- Enable GitHub Actions.
- Enable squash merge.
- Enable auto-merge.
- Protect `main` and require the `iOS CI` status check after it has run at least once.

## Runner requirements

Run the self-hosted runner under a dedicated, non-admin macOS account. Under that same user:

- Xcode and Simulator runtimes are installed.
- `omp`, `bun`, `gh`, `git`, `xcodebuild`, and `xcrun` are available.
- The dedicated `AGENT_GITHUB_TOKEN` secret exists in GitHub Actions; it is not stored on disk on the runner.
- `~/.omp/agent/.env` contains `DEEPSEEK_API_KEY`.
- OpenAI Codex OAuth login has already been completed in OMP.

Do not run this on a personal macOS account containing unrelated secrets or files.
