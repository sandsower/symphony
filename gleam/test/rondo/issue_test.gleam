import gleeunit/should
import rondo/issue.{type Issue, Blocker, Issue}

pub fn safe_identifier_replaces_special_chars_test() {
  let i = test_issue("DAL-123")
  issue.safe_identifier(i) |> should.equal("DAL-123")
}

pub fn safe_identifier_replaces_slash_test() {
  let i = test_issue("FOO/BAR")
  issue.safe_identifier(i) |> should.equal("FOO_BAR")
}

pub fn is_blocked_false_when_empty_test() {
  let i = test_issue("DAL-1")
  issue.is_blocked(i) |> should.equal(False)
}

pub fn is_blocked_true_when_has_blockers_test() {
  let i = Issue(..test_issue("DAL-1"), blocked_by: [Blocker("x", "DAL-2", "Todo")])
  issue.is_blocked(i) |> should.equal(True)
}

fn test_issue(identifier: String) -> Issue {
  Issue(
    id: "uuid-1",
    identifier: identifier,
    title: "Test issue",
    description: "Description",
    priority: 1,
    state: "Todo",
    branch_name: "feature/test",
    url: "https://linear.app/test",
    assignee_id: "user-1",
    labels: [],
    blocked_by: [],
  )
}
