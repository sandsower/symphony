# Claude Code adaptation design

## Context

Symphony's Elixir reference implementation talks to Codex via a JSON-RPC app-server protocol. The spec has been rewritten for Claude Code, which uses a simpler subprocess-per-invocation model (`claude -p` + `--output-format stream-json`). About half the Elixir codebase transfers cleanly; the other half needs rewriting.

## Decisions

- **Language:** Elixir, adapting the existing reference implementation in-place
- **Scope:** Full spec -- core conformance + HTTP API + linear_graphql tool extension
- **Strategy:** Surgical rewrites of Codex-specific modules, field renames in orchestrator, leave working modules alone

## What changes

### Delete

- `codex/app_server.ex` -- JSON-RPC handshake protocol, no longer relevant
- `codex/dynamic_tool.ex` -- Codex-specific tool injection mechanism

### Rewrite

**`claude/cli.ex` (new, replaces app_server.ex)**

Spawns `claude -p` as a subprocess via Erlang ports. Reads newline-delimited JSON from stdout. No persistent connection, no handshake -- each turn is spawn-run-exit.

First turn:
```
claude -p "<prompt>" --output-format stream-json --max-turns 50 \
  --permission-mode bypassPermissions --dangerously-skip-permissions \
  --cwd <workspace>
```

Continuation:
```
claude --resume <session_id> -p "<continuation>" \
  --output-format stream-json --max-turns 50 --cwd <workspace>
```

Responsibilities:
- Build CLI args from config
- Spawn via `Port.open` for streaming stdout
- Parse JSON lines, emit events to caller via callback
- Extract `session_id` from output for `--resume`
- Extract token usage and rate limits
- Map exit code 0 to success, non-zero to failure
- Enforce `turn_timeout_ms` by killing the port process
- Log stderr as diagnostics, don't parse it as protocol

**`claude/stream_parser.ex` (new)**

Handles the `stream-json` output format:
- Buffer partial lines until newline
- JSON-decode complete lines
- Extract session_id, usage, rate_limit fields
- Categorize events (assistant, tool, result, system) into internal types (session_started, notification, tool_use, turn_completed, malformed)

**`agent_runner.ex`**

Replace `AppServer.start_session` / `AppServer.run_turn` / `AppServer.stop_session` with `Claude.CLI.run` / `Claude.CLI.resume`. The multi-turn loop structure stays the same -- just different function calls.

**`config.ex`**

Remove Codex fields:
- `approval_policy`, `thread_sandbox`, `turn_sandbox_policy`, `read_timeout_ms`

Add Claude Code fields under `claude` key (replacing `codex`):
- `command` (default: `claude`)
- `permission_mode` (default: `bypassPermissions`)
- `dangerously_skip_permissions` (default: `true`)
- `max_turns` (default: `50`)
- `output_format` (default: `stream-json`)
- `model` (default: `nil`)
- `allowed_tools` (default: `nil`)
- `turn_timeout_ms` (default: `3_600_000`)
- `stall_timeout_ms` (default: `300_000`)

The NimbleOptions schema and typed getters update accordingly.

**`orchestrator.ex`**

Field renames throughout:
- `codex_totals` -> `claude_totals`
- `codex_rate_limits` -> `claude_rate_limits`
- `codex_input_tokens` -> `claude_input_tokens` (and output/total variants)
- `codex_last_reported_*` -> `claude_last_reported_*`
- `codex_app_server_pid` -> `claude_pid`
- `last_codex_*` -> `last_claude_*`
- `{:codex_worker_update, ...}` -> `{:claude_worker_update, ...}`

Token extraction simplifies -- Claude Code's stream-json has flatter payloads than Codex's nested JSON-RPC structure. The deeply nested path resolution in `extract_token_usage/1` gets replaced with direct field access on stream-json events.

### Minor updates

- `cli.ex` -- Default command changes from `codex app-server` to `claude`
- `status_dashboard.ex` -- Display labels rename from Codex to Claude
- `log_file.ex` -- Path references update
- Tests -- Update fixtures and assertions for Claude Code payloads
- `WORKFLOW.md` -- Front matter key changes from `codex:` to `claude:`

### Unchanged

- `workflow.ex`, `workflow_store.ex` -- Loader and file watcher work as-is
- `workspace.ex` -- Creation, hooks, cleanup, safety invariants unchanged
- `linear/client.ex`, `linear/adapter.ex` -- GraphQL client and normalization unchanged
- `prompt_builder.ex` -- Liquid template rendering unchanged
- `tracker.ex` -- Tracker abstraction unchanged
- `http_server.ex` -- REST API structure unchanged

## Config trade-offs

Codex had fine-grained approval control (`approval_policy` with per-category reject maps) and built-in sandbox configuration (`thread_sandbox`, `turn_sandbox_policy` with writable roots, network access toggles). Claude Code's model is coarser: a permission tier plus an optional skip-all flag.

What's lost: per-category approval granularity and declarative sandbox config.

What compensates: `--allowedTools` for tool whitelisting, workspace `--cwd` isolation, external sandboxing (container/firejail) via the `command` field, and CLAUDE.md behavioral guardrails in the repo.

Default posture is `dangerously_skip_permissions: true` for unattended operation. Operators tighten via `allowed_tools` in WORKFLOW.md.

## Token extraction

Codex wrapped everything in JSON-RPC envelopes with deeply nested paths like `params.msg.payload.info.total_token_usage`. Claude Code's stream-json is flatter:

- Events have a `type` field (`assistant`, `tool`, `result`, `system`)
- The `result` event contains `session_id` and cumulative `usage`
- Usage fields: `input_tokens`, `output_tokens` (no nesting)
- Rate limits may appear in event metadata

The orchestrator's `integrate_claude_update/2` and `extract_token_delta/2` simplify accordingly.
