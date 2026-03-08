import gleam/int
import gleam/list
import gleam/string
import rondo/claude/event.{type ClaudeEvent, type TokenUsage}
import rondo/ffi/port
import rondo/run_result.{type RunResult, Completed, Failed, ProcessCrashed}

pub type CliOptions {
  CliOptions(
    command: String,
    output_format: String,
    max_turns: Int,
    permission_mode: String,
    dangerously_skip_permissions: Bool,
    model: String,
    allowed_tools: List(String),
    turn_timeout_ms: Int,
  )
}

pub type PortMessage {
  PortLine(String)
  PortExit(Int)
}

pub fn build_args(
  prompt: String,
  opts: CliOptions,
  resume_session_id: String,
) -> List(String) {
  let base = case string.is_empty(resume_session_id) {
    True -> ["-p", prompt]
    False -> ["-p", prompt, "--resume", resume_session_id]
  }
  let base =
    list.append(base, [
      "--verbose",
      "--output-format", opts.output_format,
      "--max-turns", int.to_string(opts.max_turns),
      "--permission-mode", opts.permission_mode,
    ])
  let base = case opts.dangerously_skip_permissions {
    True -> list.append(base, ["--dangerously-skip-permissions"])
    False -> base
  }
  let base = case string.is_empty(opts.model) {
    True -> base
    False -> list.append(base, ["--model", opts.model])
  }
  case list.is_empty(opts.allowed_tools) {
    True -> base
    False ->
      list.append(base, [
        "--allowedTools", string.join(opts.allowed_tools, ","),
      ])
  }
}

pub fn run(
  prompt: String,
  working_dir: String,
  opts: CliOptions,
  on_event: fn(ClaudeEvent) -> Nil,
) -> RunResult {
  run_session(prompt, working_dir, opts, "", on_event)
}

pub fn resume(
  guidance: String,
  session_id: String,
  working_dir: String,
  opts: CliOptions,
  on_event: fn(ClaudeEvent) -> Nil,
) -> RunResult {
  run_session(guidance, working_dir, opts, session_id, on_event)
}

fn run_session(
  prompt: String,
  _working_dir: String,
  opts: CliOptions,
  resume_session_id: String,
  on_event: fn(ClaudeEvent) -> Nil,
) -> RunResult {
  let args = build_args(prompt, opts, resume_session_id)
  case port.open(opts.command, args) {
    Error(_reason) -> Failed(reason: ProcessCrashed(exit_code: -1))
    Ok(p) -> {
      let result = collect_port_output(p, on_event, event.zero_usage(), "")
      let _ = port.close(p)
      result
    }
  }
}

fn collect_port_output(
  _port: port.Port,
  _on_event: fn(ClaudeEvent) -> Nil,
  _usage: TokenUsage,
  _session_id: String,
) -> RunResult {
  // Placeholder. Actual implementation needs to receive Erlang port messages
  // in a loop. Will be fleshed out when wiring up the Agent actor in Task 10.
  Completed(session_id: "", usage: event.zero_usage())
}
