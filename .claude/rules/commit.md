# Commit

Create well-formatted commits with conventional commit messages and emojis.

## Features:
- Runs pre-commit checks by default (lint, build, generate docs)
- Automatically stages files if none are staged
- Uses conventional commit format with descriptive emojis
- Suggests splitting commits for different concerns

## Usage:
- `/commit` - Standard commit with pre-commit checks
- `/commit --no-verify` - Skip pre-commit checks

## Commit Types:
- ✨ feat: New features
- 🐛 fix: Bug fixes
- 📝 docs: Documentation changes
- ♻️ refactor: Code restructuring without changing functionality
- 🎨 style: Code formatting, missing semicolons, etc.
- ⚡️ perf: Performance improvements
- ✅ test: Adding or correcting tests
- 🧑‍💻 chore: Tooling, configuration, maintenance
- 🚧 wip: Work in progress
- 🔥 remove: Removing code or files
- 🚑 hotfix: Critical fixes
- 🔒 security: Security improvements

## Process:
1. Check for staged changes (`git status`)
2. If no staged changes, review and stage appropriate files
3. Run pre-commit checks (unless --no-verify)
4. Analyze changes to determine commit type
5. Generate descriptive commit message
6. Include scope if applicable: `type(scope): description`
7. Add body for complex changes explaining why
8. Execute commit

## Message Content Guidelines:
- **Focus on WHAT changed, not HOW**: Describe user-facing changes and features
- **Describe outcomes in sub-points**: List benefits and what was achieved, not technical steps
- **Reflect actual git delta**: Only mention changes that appear in `git diff`
- **Don't reference uncommitted work**: Avoid mentioning attempts that were never committed
- **Include implementation details when useful**: Add technical details for searchability, but frame them as what's being introduced

### Examples:

**✅ Correct:**
```
✨ feat: add quit button to permission modal

- Allows users to exit the app when permissions are pending
- Prevents users from being stuck if window close button is disabled
- Uses exit(0) for immediate termination
```

**❌ Incorrect:**
```
✨ feat: add quit button to permission modal

- Replace NSApplication.terminate() with exit(0)  # Wrong: mentions uncommitted attempt
- Add button to modal  # Wrong: describes HOW not WHAT
- Fix issue where button didn't work  # Wrong: references uncommitted state
```

**✅ Correct (for actual replacement):**
```
🎨 style: increase font size for better readability

- Makes text more legible on desktop screens
- Changes base font from 14pt to 16pt
```

**❌ Incorrect:**
```
🎨 style: update font sizes

- Changed font size in multiple files  # Wrong: describes process not outcome
- Updated Constants.swift  # Wrong: lists files touched, not benefit
```

## Best Practices:
- Keep commits atomic and focused
- Write in imperative mood ("Add feature" not "Added feature")
- Explain why, not just what
- Reference issues/PRs when relevant
- Split unrelated changes into separate commits