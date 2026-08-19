# iOS Agent Factory Starter

Use this folder as a starter layer inside a native iOS SwiftUI repository.

## First-time use

1. Copy the contents into the root of your Xcode repository.
2. Copy `.agent/local.env.example` to `.agent/local.env`.
3. Edit the three values in `.agent/local.env` for your Xcode project/workspace, scheme, and simulator.
4. Fill in `.agent/PRODUCT.md` and `.agent/ARCHITECTURE.md`.
5. Run `./scripts/ios-doctor.sh`.
6. Run `./scripts/verify-ios.sh`.
7. Start `omp` from the repository root.

Do not store API keys in this repository. Keep DeepSeek credentials in `~/.omp/agent/.env`.
