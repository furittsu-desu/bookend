# Enhanced /git Workflow Implementation Plan

> **For Antigravity:** REQUIRED SUB-SKILL: Load executing-plans to implement this plan task-by-task.

**Goal:** Update the global `git.md` workflow to include intelligent phase detection, PR/Merge delivery, and automated cleanup.

**Architecture:** Update the markdown-based workflow definition to include logic gates for Phase 1 (Commit) and Phase 2 (Delivery), leveraging the GitHub MCP server for automation.

**Tech Stack:** Markdown, GitHub MCP, Git CLI.

---

### Task 1: Update Workflow Structure & Phase Detection
**Files:**
- Modify: `C:\Users\Darryl\.gemini\antigravity\global_workflows\git.md`

**Step 1: Update frontmatter and introduction**
Modify the description to include PR/Merge capabilities.

**Step 2: Define Intelligent Phase Detection**
Add a section at the top of the workflow instructions explaining how to determine the current phase (Modified vs. Clean state).

**Step 3: Commit changes**
```bash
git add C:\Users\Darryl\.gemini\antigravity\global_workflows\git.md
git commit -m "chore(workflow): update git workflow structure for delivery phase"
```

---

### Task 2: Implement Delivery Protocol
**Files:**
- Modify: `C:\Users\Darryl\.gemini\antigravity\global_workflows\git.md`

**Step 1: Add "Phase 2: Delivery Protocol" section**
Include detailed instructions for:
- Checking existing PRs via `mcp_github.list_pull_requests`.
- Creating PRs via `mcp_github.create_pull_request`.
- Evaluating merge strategy (Squash vs. Merge Commit) using `git log`.
- Executing the merge via `mcp_github.merge_pull_request`.

**Step 2: Commit changes**
```bash
git add C:\Users\Darryl\.gemini\antigravity\global_workflows\git.md
git commit -m "chore(workflow): add delivery protocol to git workflow"
```

---

### Task 3: Implement Cleanup Protocol
**Files:**
- Modify: `C:\Users\Darryl\.gemini\antigravity\global_workflows\git.md`

**Step 1: Add "Phase 3: Cleanup Protocol" section**
Include instructions for switching to main, pulling changes, and safe deletion of the local branch.

**Step 2: Commit changes**
```bash
git add C:\Users\Darryl\.gemini\antigravity\global_workflows\git.md
git commit -m "chore(workflow): add cleanup protocol to git workflow"
```

---

### Task 4: Final Verification
**Step 1: Review the full workflow file**
Ensure all instructions are clear, CLI fallbacks are present, and formatting is consistent.

**Step 2: Test the suggestion logic**
Manually verify that a "Review Approved" state correctly triggers a suggestion to run this workflow.
