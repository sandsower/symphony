import gleeunit/should
import rondo/issue.{type Issue, Issue}
import rondo/workspace

pub fn create_workspace_test() {
  let root = "/tmp/rondo-test-workspaces"
  let issue = test_issue("DAL-99")
  let result = workspace.create(root, issue)
  result |> should.be_ok()
  let path = case result {
    Ok(p) -> p
    Error(_) -> panic
  }
  path |> should.equal(root <> "/DAL-99")
  let _ = workspace.remove(path)
}

pub fn remove_workspace_test() {
  let root = "/tmp/rondo-test-workspaces"
  let issue = test_issue("DAL-100")
  let assert Ok(path) = workspace.create(root, issue)
  workspace.remove(path) |> should.be_ok()
}

pub fn interpolate_hook_command_test() {
  workspace.interpolate_hook(
    "echo {{ workspace.path }} {{ issue.identifier }}",
    "/tmp/ws",
    "DAL-1",
  )
  |> should.equal("echo /tmp/ws DAL-1")
}

fn test_issue(identifier: String) -> Issue {
  Issue(
    id: "uuid-1",
    identifier: identifier,
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
