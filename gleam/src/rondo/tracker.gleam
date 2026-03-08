import rondo/issue.{type Issue}

pub type TrackerError {
  NotFound(id: String)
  ApiError(detail: String)
}

pub type TrackerResult(a) =
  Result(a, TrackerError)

pub type TrackerCallbacks {
  TrackerCallbacks(
    fetch_candidate_issues: fn() -> TrackerResult(List(Issue)),
    fetch_issue_states_by_ids: fn(List(String)) -> TrackerResult(List(Issue)),
    create_comment: fn(String, String) -> TrackerResult(Nil),
    update_issue_state: fn(String, String) -> TrackerResult(Nil),
  )
}
