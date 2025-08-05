# Fast Commit Task

Generate 3 commit message suggestions based on the staged changes, then automatically use the first suggestion without user confirmation. 

Follow conventional commit format with appropriate emojis and create descriptive messages that explain the purpose of changes. Skip the manual message selection step to streamline the commit process.

## Steps:
1. Run `git status` to see staged changes
2. Generate 3 commit message suggestions following conventional commit format
3. Automatically select the first suggestion
4. Execute `git commit -m` with the selected message
5. Exclude Claude co-authorship footer from commits

## Message Guidelines:
- Focus on user-facing changes (WHAT) not implementation details (HOW)
- Describe benefits/outcomes, not technical steps
- Reflect actual git delta - only mention what's in `git diff`
- Include implementation details when useful, but as what's being added

### Quick Example:
✅ `feat: add export button to dashboard - Enables CSV data export`
❌ `feat: implement export functionality - Added button component to dashboard.tsx`

## Commit Types:
- ✨ feat: New features
- 🐛 fix: Bug fixes  
- 📝 docs: Documentation changes
- ♻️ refactor: Code restructuring
- 🧑‍💻 chore: Tooling and maintenance
- 🎨 style: Code formatting, missing semicolons, etc.
- ⚡️ perf: Performance improvements
- ✅ test: Adding or correcting tests