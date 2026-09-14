# Pi goal-style extensions research

Date: 2026-09-14

## Question

Are there open-source Pi coding agent extensions that perform the role of a `/goal` command?

## Sources checked

- Pi official docs: `README.md`, `docs/extensions.md`, `docs/packages.md`, `docs/compaction.md`
- Pi official examples: `examples/extensions/README.md`, `examples/extensions/plan-mode/README.md`, `todo.ts`, `custom-compaction.ts`, `summarize.ts`, `bookmark.ts`
- npm registry search for `keywords:pi-package`
- npm package metadata and published package contents for likely goal-related packages

## Findings

Pi core does not ship a built-in `/goal` command. Its official command list includes `/compact`, `/session`, `/tree`, `/name`, `/new`, `/resume`, etc.; `Goal` appears as a section in the compaction/branch-summary format, not as a command.

There are multiple open-source extensions/packages that provide goal-like behavior:

| Package | License | Role | Notes |
|---|---:|---|---|
| `pi-goal-x` | MIT | Full `/goal` system | Adds `/goal`, `/sisyphus`, guided drafting, persistent task progress, multiple open goals, optional independent completion auditor. Published Pi manifest loads `extensions/goal.ts`. |
| `@narumitw/pi-goal` | MIT | Focused single-objective `/goal` | Adds session-scoped `/goal`, auto-continuation, `goal_complete`, `goal_blocked`, `goal_wait`, safety limits, token budgets, pause/resume/edit/clear/status. |
| `@schovest/pi-goal` | MIT | Fork/port of Narumitw goal mode | Similar single-objective `/goal` with completion/block/wait tools and token budgets. Lower version and appears to be a fork. |
| `pi-goal-list-loop-audit` | AGPL-3.0-only | Long-running mission-control goal/list/loop system | Adds `/goal` for broad outcomes, independent auditor process, task queue/list, loops, recovery, evidence-backed completion. Heavier and more opinionated. |
| `@agimon-ai/doompi-goal` | MIT | DoomPi goal minor mode | Adds persistent goals, token budgets, goal history, `/goal status/pause/resume/edit/clear`, `goal_complete`, `goal_blocked`. Alpha package and likely intended for DoomPi ecosystem. |
| `pi-code` | MIT | Claude Code-style suite including `/goal` | Broad Claude Code compatibility package; includes goals, todo, checkpoints, memory, web, subagents, hooks, etc. Its goal is “keep working until separate model check confirms condition holds.” |
| `pi-muselinn-harness` | MIT | Kimi Code-style orchestration suite including `/goal` | Broad harness with swarm, plan, permission, task, hooks, todo, and Goal lifecycle/budget/queue/completion-criteria gates. |

Adjacent but not direct `/goal` replacements:

- `@juicesharp/rpiv-todo`: persistent model todo list and overlay; tracks tasks but not an autonomous goal-completion loop.
- `@narumitw/pi-plan-mode`: read-only plan collaboration mode; useful before implementation but not goal persistence/autonomous completion.
- Pi official `examples/extensions/plan-mode`: plan extraction and step tracking, but explicitly read-only planning/execution workflow example rather than persistent goal mode.
- Pi official `examples/extensions/todo.ts`: model-managed todo list via a `todo` tool and `/todos` command; no autonomous goal auditor/continuation.

## Recommendation

For a direct `/goal` role, start by evaluating:

1. `pi-goal-x` if you want rich UX: guided goal drafting, task/subtask progress, multi-goal focus, ordered Sisyphus mode, and optional auditor.
2. `@narumitw/pi-goal` if you want a smaller, single-objective goal mode with explicit terminal tools and strong safety limits.
3. `pi-goal-list-loop-audit` only if you want long-running autonomous supervision with independent audits, queues, and loops, and accept AGPL-3.0-only.

Avoid installing multiple goal packages simultaneously because several register `/goal` and may conflict or degrade to renamed commands.

## Install commands to try

```bash
pi -e npm:pi-goal-x
pi -e npm:@narumitw/pi-goal
pi -e npm:pi-goal-list-loop-audit
```

Use `pi install npm:<package>` only after reviewing the source, because Pi extensions run with full local user permissions.
