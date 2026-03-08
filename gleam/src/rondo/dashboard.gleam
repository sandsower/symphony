import gleam/dict
import gleam/int
import gleam/list
import gleam/set
import gleam/string
import rondo/claude/event.{type TokenUsage}
import rondo/orchestrator.{type RunningEntry, type Snapshot}

pub fn render(snapshot: Snapshot) -> String {
  let header = "=== Rondo Dashboard ===\n"
  let running_count = dict.size(snapshot.running)
  let completed_count = set.size(snapshot.completed)

  let summary =
    "Running: "
    <> int.to_string(running_count)
    <> " | Completed: "
    <> int.to_string(completed_count)
    <> "\n"

  let totals_line = render_totals(snapshot.totals)

  let agents = case running_count {
    0 -> "No agents running\n"
    _ -> render_running_agents(snapshot.running)
  }

  header <> summary <> totals_line <> "\n" <> agents
}

fn render_totals(usage: TokenUsage) -> String {
  "Tokens — in: "
  <> int.to_string(usage.input_tokens)
  <> " out: "
  <> int.to_string(usage.output_tokens)
  <> " total: "
  <> int.to_string(usage.total_tokens)
  <> "\n"
}

fn render_running_agents(
  running: dict.Dict(String, RunningEntry),
) -> String {
  let entries =
    running
    |> dict.values()
    |> list.map(render_agent_entry)
    |> string.join("\n")

  let header_line =
    pad_right("ISSUE", 12)
    <> pad_right("STATE", 15)
    <> pad_right("TURN", 6)
    <> pad_right("TOKENS", 10)
    <> "\n"
  let separator = string.repeat("-", 43) <> "\n"

  header_line <> separator <> entries <> "\n"
}

fn render_agent_entry(entry: RunningEntry) -> String {
  pad_right(entry.identifier, 12)
  <> pad_right(entry.state, 15)
  <> pad_right(int.to_string(entry.turn), 6)
  <> pad_right(int.to_string(entry.usage.total_tokens), 10)
}

fn pad_right(s: String, width: Int) -> String {
  let len = string.length(s)
  case len >= width {
    True -> s
    False -> s <> string.repeat(" ", width - len)
  }
}
