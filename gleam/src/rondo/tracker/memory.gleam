import gleam/list
import gleam/string
import rondo/issue.{type Issue}
import rondo/tracker.{type TrackerResult}

pub opaque type MemoryTracker {
  MemoryTracker(issues: List(Issue), active_states: List(String))
}

pub fn new(issues: List(Issue), active_states: List(String)) -> MemoryTracker {
  MemoryTracker(issues: issues, active_states: active_states)
}

pub fn fetch_candidate_issues(
  store: MemoryTracker,
) -> TrackerResult(List(Issue)) {
  let active =
    store.issues
    |> list.filter(fn(i) {
      list.any(store.active_states, fn(s) {
        string.lowercase(s) == string.lowercase(i.state)
      })
    })
  Ok(active)
}

pub fn fetch_issue_states_by_ids(
  store: MemoryTracker,
  ids: List(String),
) -> TrackerResult(List(Issue)) {
  let found =
    store.issues
    |> list.filter(fn(i) { list.contains(ids, i.id) })
  Ok(found)
}

pub fn create_comment(
  _store: MemoryTracker,
  _issue_id: String,
  _body: String,
) -> TrackerResult(Nil) {
  Ok(Nil)
}

pub fn update_issue_state(
  _store: MemoryTracker,
  _issue_id: String,
  _state: String,
) -> TrackerResult(Nil) {
  Ok(Nil)
}
