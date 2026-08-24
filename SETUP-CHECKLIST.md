# Fully Autonomous Setup Checklist

- [ ] Repository is private.
- [ ] v3 `./scripts/verify-ios.sh` passes locally.
- [ ] Dedicated non-admin macOS runner user exists.
- [ ] Xcode + required Simulator runtime installed for runner user.
- [ ] `omp`, `bun`, `gh`, `git`, `xcodebuild`, `xcrun` work under runner user.
- [ ] DeepSeek key exists in `~/.omp/agent/.env` under runner user.
- [ ] OMP OpenAI Codex OAuth is logged in under runner user.
- [ ] `omp models deepseek` shows DeepSeek V4 Flash.
- [ ] `omp models openai-codex` shows GPT-5.6 Luna/Sol.
- [ ] Fine-grained PAT created for this private repository with Contents/Issues/Pull requests read-write and saved as Actions secret `AGENT_GITHUB_TOKEN`.
- [ ] GitHub self-hosted runner registered with custom label `ios-agent`.
- [ ] Runner installed as service and status is Started.
- [ ] GitHub Actions variables created: IOS_CONTAINER, IOS_SCHEME, IOS_SIMULATOR, AGENT_ALLOWED_ACTORS.
- [ ] Agent labels created with `./scripts/setup-agent-labels.sh`.
- [ ] Repository auto-merge and squash merge enabled.
- [ ] `main` requires `iOS CI` after first successful CI run.
- [ ] Open an issue using the Autonomous Agent Task template.
