import gleam/list
import gleam/string

pub type Issue {
  Issue(
    id: String,
    identifier: String,
    title: String,
    description: String,
    priority: Int,
    state: String,
    branch_name: String,
    url: String,
    assignee_id: String,
    labels: List(String),
    blocked_by: List(Blocker),
  )
}

pub type Blocker {
  Blocker(id: String, identifier: String, state: String)
}

pub fn label_names(issue: Issue) -> List(String) {
  issue.labels
}

pub fn is_blocked(issue: Issue) -> Bool {
  !list.is_empty(issue.blocked_by)
}

pub fn safe_identifier(issue: Issue) -> String {
  issue.identifier
  |> string.to_graphemes()
  |> list.map(fn(c) {
    case string.contains("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_", c) {
      True -> c
      False -> "_"
    }
  })
  |> string.concat()
}
