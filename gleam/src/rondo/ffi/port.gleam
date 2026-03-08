pub type Port

@external(erlang, "rondo_port_ffi", "open_port")
pub fn open(command: String, args: List(String)) -> Result(Port, String)

@external(erlang, "rondo_port_ffi", "close_port")
pub fn close(port: Port) -> Nil
