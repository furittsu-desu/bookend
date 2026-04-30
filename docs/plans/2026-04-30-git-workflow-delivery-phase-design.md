# Design: Enhanced /git Workflow (Delivery Phase)

## Goal
Update the `@[/git]` workflow to handle the full lifecycle of a feature branch, including Pull Request creation, intelligent merge strategy evaluation, and post-merge cleanup.

## Orchestration Logic

### 1. Intelligent Phase Detection
The workflow will determine its action based on the state of the repository:
- **Modified files present**: Run the **Commit Protocol** (Smart Commit).
- **Clean state on feature branch**: Run the **Delivery Protocol** (PR & Merge).
- **Clean state on main**: Report "Nothing to do."

### 2. Delivery Protocol
1. **PR Creation**:
   - Check if a PR exists via GitHub MCP.
   - If not, create one using the branch name and the last commit message as a template.
2. **Merge Strategy Evaluation**:
   - **Squash and Merge**: Selected if the branch has repetitive commits (fixups, wip) or >3 commits.
   - **Merge Commit**: Selected if the branch has a clean, linear history of <=3 distinct conventional commits.
3. **Execution**:
   - Primary: `mcp_github.merge_pull_request`.
   - Fallback: Provide `gh pr merge` or `git merge` CLI commands.

### 3. Cleanup Protocol
After successful merge:
1. `git checkout main`
2. `git pull origin main`
3. `git branch -d <feature-branch>`
4. `git remote prune origin`

## Approval
Approved by USER on 2026-04-30.
