import gleam/dict
import gleam/set
import gleeunit/should
import rondo/claude/cli.{CliOptions}
import rondo/claude/event
import rondo/config
import rondo/orchestrator.{type OrchestratorState, OrchestratorState}

pub fn snapshot_starts_empty_test() {
  let state = empty_state()
  state.running |> dict.size() |> should.equal(0)
  state.completed |> set.size() |> should.equal(0)
  state.totals |> should.equal(event.zero_usage())
}

fn empty_state() -> OrchestratorState {
  let c = config.Config(..config.default(), linear_api_token: "tok")
  let cli_opts =
    CliOptions(
      command: "echo",
      output_format: "stream-json",
      max_turns: 1,
      permission_mode: "default",
      dangerously_skip_permissions: False,
      model: "",
      allowed_tools: [],
      turn_timeout_ms: 5000,
    )
  OrchestratorState(
    config: c,
    cli_opts: cli_opts,
    running: dict.new(),
    completed: set.new(),
    claimed: set.new(),
    retry_attempts: dict.new(),
    totals: event.zero_usage(),
    fetch_candidates: fn() { Ok([]) },
    fetch_states: fn(_) { Ok([]) },
  )
}
