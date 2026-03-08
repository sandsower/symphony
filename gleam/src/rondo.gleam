import rondo/cli

pub fn main() {
  case cli.run() {
    Ok(_) -> Nil
    Error(_) -> Nil
  }
}
