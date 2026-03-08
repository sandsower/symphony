import gleeunit/should
import rondo/workflow
import simplifile

pub fn parse_workflow_with_frontmatter_test() {
  let content =
    "---
max_turns: 5
timeout_ms: 60000
allowed_tools:
  - Read
  - Write
---
You are working on {{ issue.identifier }}: {{ issue.title }}"

  let result = workflow.parse(content)
  result |> should.be_ok()
  let wf = case result {
    Ok(w) -> w
    Error(_) -> panic
  }
  wf.prompt_template
  |> should.equal(
    "You are working on {{ issue.identifier }}: {{ issue.title }}",
  )
  wf.max_turns |> should.equal(5)
  wf.timeout_ms |> should.equal(60_000)
  wf.allowed_tools |> should.equal(["Read", "Write"])
}

pub fn parse_workflow_without_frontmatter_test() {
  let content = "Just a prompt with no config"
  let result = workflow.parse(content)
  result |> should.be_ok()
  let wf = case result {
    Ok(w) -> w
    Error(_) -> panic
  }
  wf.prompt_template |> should.equal("Just a prompt with no config")
  wf.max_turns |> should.equal(0)
}

pub fn parse_empty_content_test() {
  workflow.parse("") |> should.be_ok()
}

pub fn load_workflow_file_test() {
  let path = "/tmp/rondo-test-workflow.md"
  let content = "---\nmax_turns: 3\n---\nDo the work"
  let assert Ok(_) = simplifile.write(path, content)
  let result = workflow.load(path)
  result |> should.be_ok()
  let wf = case result {
    Ok(w) -> w
    Error(_) -> panic
  }
  wf.prompt_template |> should.equal("Do the work")
  wf.max_turns |> should.equal(3)
  let _ = simplifile.delete(path)
}
