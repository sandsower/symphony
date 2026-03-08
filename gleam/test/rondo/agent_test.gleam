import gleam/erlang/process
import gleeunit/should
import rondo/agent
import rondo/claude/cli.{type CliOptions, CliOptions}
import rondo/issue.{type Issue, Issue}

pub fn agent_starts_and_reports_status_test() {
  let issue = test_issue()
  let notify = process.new_subject()
  let opts = test_cli_opts()

  let assert Ok(agent_subject) =
    agent.start(issue, "/tmp/test", "do work", opts, notify)

  let status_subject = process.new_subject()
  process.send(agent_subject, agent.GetStatus(status_subject))

  let status = process.receive(status_subject, 1000)
  status |> should.be_ok()
}

fn test_issue() -> Issue {
  Issue(
    id: "uuid-1",
    identifier: "DAL-1",
    title: "Test",
    description: "",
    priority: 1,
    state: "Todo",
    branch_name: "",
    url: "",
    assignee_id: "",
    labels: [],
    blocked_by: [],
  )
}

fn test_cli_opts() -> CliOptions {
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
}
