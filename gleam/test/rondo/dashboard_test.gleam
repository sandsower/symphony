import gleam/dict
import gleam/erlang/process
import gleam/set
import gleam/string
import gleeunit/should
import rondo/claude/event.{TokenUsage}
import rondo/dashboard
import rondo/orchestrator.{RunningEntry, Snapshot}

pub fn render_empty_snapshot_test() {
  let snapshot =
    Snapshot(
      running: dict.new(),
      completed: set.new(),
      totals: event.zero_usage(),
    )
  let output = dashboard.render(snapshot)
  output |> string.contains("No agents running") |> should.be_true()
}

pub fn render_with_running_agents_test() {
  let dummy_subject = process.new_subject()
  let entry =
    RunningEntry(
      issue_id: "uuid-1",
      identifier: "DAL-42",
      state: "In Progress",
      session_id: "sess-1",
      turn: 2,
      usage: TokenUsage(
        input_tokens: 1000,
        output_tokens: 500,
        total_tokens: 1500,
      ),
      agent: dummy_subject,
    )
  let snapshot =
    Snapshot(
      running: dict.from_list([#("uuid-1", entry)]),
      completed: set.new(),
      totals: TokenUsage(
        input_tokens: 1000,
        output_tokens: 500,
        total_tokens: 1500,
      ),
    )
  let output = dashboard.render(snapshot)
  output |> string.contains("DAL-42") |> should.be_true()
  output |> string.contains("1500") |> should.be_true()
}
