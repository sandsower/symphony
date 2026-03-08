import gleeunit/should
import rondo/issue.{type Issue, Issue}
import rondo/prompt

pub fn build_prompt_replaces_issue_fields_test() {
  let template =
    "Work on {{ issue.identifier }}: {{ issue.title }}\n\n{{ issue.description }}"
  let issue = test_issue()
  prompt.build(template, issue, 1)
  |> should.equal("Work on DAL-42: Fix the bug\n\nSomething is broken")
}

pub fn build_prompt_replaces_attempt_test() {
  let template = "Attempt {{ attempt }} for {{ issue.identifier }}"
  let issue = test_issue()
  prompt.build(template, issue, 3)
  |> should.equal("Attempt 3 for DAL-42")
}

pub fn build_prompt_leaves_unknown_vars_test() {
  let template = "Hello {{ unknown }}"
  prompt.build(template, test_issue(), 1)
  |> should.equal("Hello {{ unknown }}")
}

pub fn build_prompt_handles_labels_test() {
  let template = "Labels: {{ issue.labels }}"
  let issue = Issue(..test_issue(), labels: ["bug", "urgent"])
  prompt.build(template, issue, 1)
  |> should.equal("Labels: bug, urgent")
}

fn test_issue() -> Issue {
  Issue(
    id: "uuid-1",
    identifier: "DAL-42",
    title: "Fix the bug",
    description: "Something is broken",
    priority: 1,
    state: "Todo",
    branch_name: "fix/bug",
    url: "https://linear.app/test/DAL-42",
    assignee_id: "user-1",
    labels: [],
    blocked_by: [],
  )
}
