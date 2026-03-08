import gleam/erlang/process
import gleeunit/should
import rondo/claude/cli.{CliOptions}
import rondo/claude/event
import rondo/config
import rondo/issue.{Issue}
import rondo/orchestrator
import rondo/tracker/memory

pub fn orchestrator_polls_and_reports_snapshot_test() {
  let issues = [
    Issue(
      id: "1",
      identifier: "DAL-1",
      title: "Test issue",
      description: "Fix it",
      priority: 1,
      state: "Todo",
      branch_name: "fix/test",
      url: "",
      assignee_id: "",
      labels: [],
      blocked_by: [],
    ),
  ]
  let store = memory.new(issues, ["Todo"])
  let c =
    config.Config(
      ..config.default(),
      linear_api_token: "tok",
      max_concurrent_agents: 2,
    )
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

  let fetch_candidates = fn() {
    case memory.fetch_candidate_issues(store) {
      Ok(found) -> Ok(found)
      Error(_) -> Error(Nil)
    }
  }
  let fetch_states = fn(ids) {
    case memory.fetch_issue_states_by_ids(store, ids) {
      Ok(found) -> Ok(found)
      Error(_) -> Error(Nil)
    }
  }

  let assert Ok(orch) =
    orchestrator.start(c, cli_opts, fetch_candidates, fetch_states)

  process.sleep(100)
  let snapshot_subject = process.new_subject()
  process.send(orch, orchestrator.GetSnapshot(snapshot_subject))
  let assert Ok(snapshot) = process.receive(snapshot_subject, 1000)

  snapshot.totals |> should.equal(event.zero_usage())
}
