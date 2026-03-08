import gleeunit/should
import rondo/issue.{type Issue, Issue}
import rondo/tracker/memory

pub fn fetch_candidates_returns_active_issues_test() {
  let issues = [
    test_issue("1", "DAL-1", "Todo"),
    test_issue("2", "DAL-2", "Done"),
    test_issue("3", "DAL-3", "In Progress"),
  ]
  let store = memory.new(issues, ["Todo", "In Progress"])
  memory.fetch_candidate_issues(store)
  |> should.be_ok()
  |> fn(result) {
    case result {
      [a, b] -> {
        a.identifier |> should.equal("DAL-1")
        b.identifier |> should.equal("DAL-3")
      }
      _ -> panic
    }
  }
}

pub fn fetch_issue_states_by_ids_test() {
  let issues = [test_issue("1", "DAL-1", "Todo")]
  let store = memory.new(issues, ["Todo"])
  memory.fetch_issue_states_by_ids(store, ["1"])
  |> should.be_ok()
}

pub fn update_issue_state_test() {
  let issues = [test_issue("1", "DAL-1", "Todo")]
  let store = memory.new(issues, ["Todo"])
  memory.update_issue_state(store, "1", "In Progress")
  |> should.be_ok()
}

fn test_issue(id: String, identifier: String, state: String) -> Issue {
  Issue(
    id: id,
    identifier: identifier,
    title: "Test",
    description: "",
    priority: 1,
    state: state,
    branch_name: "",
    url: "",
    assignee_id: "",
    labels: [],
    blocked_by: [],
  )
}
