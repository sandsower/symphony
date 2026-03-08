import gleam/string
import gleeunit/should
import rondo/config
import rondo/tracker/linear

pub fn build_poll_variables_includes_project_slug_test() {
  let c = config.Config(..config.default(), linear_project_slug: "my-proj")
  let vars = linear.build_poll_variables(c)
  vars |> string.contains("my-proj") |> should.be_true()
}

pub fn build_poll_variables_includes_assignee_when_set_test() {
  let c =
    config.Config(
      ..config.default(),
      linear_project_slug: "proj",
      linear_assignee: "user-123",
    )
  let vars = linear.build_poll_variables(c)
  vars |> string.contains("user-123") |> should.be_true()
}

pub fn build_poll_variables_omits_assignee_when_empty_test() {
  let c =
    config.Config(..config.default(), linear_project_slug: "proj")
  let vars = linear.build_poll_variables(c)
  vars |> string.contains("assigneeId") |> should.be_false()
}
