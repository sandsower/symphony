import gleam/int
import gleam/string
import rondo/issue.{type Issue}

pub fn build(template: String, issue: Issue, attempt: Int) -> String {
  template
  |> replace_var("issue.identifier", issue.identifier)
  |> replace_var("issue.title", issue.title)
  |> replace_var("issue.description", issue.description)
  |> replace_var("issue.state", issue.state)
  |> replace_var("issue.branch_name", issue.branch_name)
  |> replace_var("issue.url", issue.url)
  |> replace_var("issue.id", issue.id)
  |> replace_var("issue.labels", string.join(issue.labels, ", "))
  |> replace_var("attempt", int.to_string(attempt))
}

fn replace_var(template: String, name: String, value: String) -> String {
  template
  |> string.replace("{{ " <> name <> " }}", value)
  |> string.replace("{{" <> name <> "}}", value)
}
