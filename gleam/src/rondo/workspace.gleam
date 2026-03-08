import gleam/string
import rondo/issue.{type Issue}
import simplifile

pub type WorkspaceError {
  CreateFailed(detail: String)
  RemoveFailed(detail: String)
  HookFailed(detail: String)
  PathEscape(path: String)
}

pub fn create(root: String, issue: Issue) -> Result(String, WorkspaceError) {
  let safe_id = issue.safe_identifier(issue)
  let path = root <> "/" <> safe_id

  case string.starts_with(path, root) {
    False -> Error(PathEscape(path: path))
    True -> {
      case simplifile.create_directory_all(path) {
        Ok(_) -> Ok(path)
        Error(e) -> Error(CreateFailed(detail: string.inspect(e)))
      }
    }
  }
}

pub fn remove(path: String) -> Result(Nil, WorkspaceError) {
  case simplifile.delete(path) {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(RemoveFailed(detail: string.inspect(e)))
  }
}

pub fn interpolate_hook(
  command: String,
  workspace_path: String,
  issue_identifier: String,
) -> String {
  command
  |> string.replace("{{ workspace.path }}", workspace_path)
  |> string.replace("{{ issue.identifier }}", issue_identifier)
  |> string.replace("{{workspace.path}}", workspace_path)
  |> string.replace("{{issue.identifier}}", issue_identifier)
}
