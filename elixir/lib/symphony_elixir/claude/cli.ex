defmodule SymphonyElixir.Claude.CLI do
  @moduledoc """
  Spawns Claude Code CLI subprocesses and streams events back to the caller.
  """

  require Logger
  alias SymphonyElixir.Claude.StreamParser
  alias SymphonyElixir.Config

  @port_line_bytes 10_485_760
  @max_log_bytes 1_000

  @type run_result :: %{
          session_id: String.t() | nil,
          exit_code: integer(),
          usage: map() | nil
        }

  @doc """
  Run a first-turn Claude Code session with the given prompt.
  """
  @spec run(String.t(), Path.t(), keyword()) :: {:ok, run_result()} | {:error, term()}
  def run(prompt, workspace, opts \\ []) do
    args = build_first_turn_args(prompt, workspace)
    execute(args, workspace, opts)
  end

  @doc """
  Resume an existing Claude Code session with continuation guidance.
  """
  @spec resume(String.t(), String.t(), Path.t(), keyword()) :: {:ok, run_result()} | {:error, term()}
  def resume(session_id, prompt, workspace, opts \\ []) do
    args = build_resume_args(session_id, prompt, workspace)
    execute(args, workspace, opts)
  end

  defp execute(args, workspace, opts) do
    on_event = Keyword.get(opts, :on_event, fn _event -> :ok end)
    turn_timeout_ms = Keyword.get(opts, :turn_timeout_ms, Config.claude_turn_timeout_ms())

    with :ok <- validate_workspace(workspace) do
      command = Config.claude_command()
      {cmd, cmd_args} = parse_command(command, args)

      port =
        Port.open(
          {:spawn_executable, cmd},
          [
            :binary,
            :exit_status,
            :stderr_to_stdout,
            {:line, @port_line_bytes},
            {:cd, Path.expand(workspace)},
            {:args, cmd_args}
          ]
        )

      deadline = System.monotonic_time(:millisecond) + turn_timeout_ms

      try do
        stream_loop(port, deadline, on_event, %{
          session_id: nil,
          usage: nil,
          buffer: ""
        })
      catch
        :exit, reason ->
          safe_port_close(port)
          {:error, {:subprocess_exit, reason}}
      end
    end
  end

  defp stream_loop(port, deadline, on_event, state) do
    remaining_ms = max(deadline - System.monotonic_time(:millisecond), 0)

    if remaining_ms <= 0 do
      safe_port_close(port)
      {:error, :turn_timeout}
    else
      receive do
        {^port, {:data, {:eol, line}}} ->
          state = handle_line(line, on_event, state)
          stream_loop(port, deadline, on_event, state)

        {^port, {:data, {:noeol, chunk}}} ->
          stream_loop(port, deadline, on_event, %{state | buffer: state.buffer <> chunk})

        {^port, {:exit_status, 0}} ->
          {:ok,
           %{
             session_id: state.session_id,
             exit_code: 0,
             usage: state.usage
           }}

        {^port, {:exit_status, code}} ->
          {:error, {:subprocess_exit, code}}
      after
        remaining_ms ->
          safe_port_close(port)
          {:error, :turn_timeout}
      end
    end
  end

  defp handle_line(line, on_event, state) do
    full_line = state.buffer <> line
    state = %{state | buffer: ""}

    case StreamParser.parse_line(full_line) do
      {:ok, event} ->
        session_id = StreamParser.extract_session_id(event) || state.session_id
        usage = StreamParser.extract_usage(event) || state.usage
        on_event.(event)
        %{state | session_id: session_id, usage: usage}

      {:error, reason} ->
        Logger.debug(
          "Unparseable stream line: #{inspect(reason)} line=#{String.slice(full_line, 0, @max_log_bytes)}"
        )

        state
    end
  end

  defp build_first_turn_args(prompt, workspace) do
    base = [
      "-p",
      prompt,
      "--output-format",
      Config.claude_output_format(),
      "--max-turns",
      to_string(Config.claude_max_turns()),
      "--permission-mode",
      Config.claude_permission_mode(),
      "--cwd",
      Path.expand(workspace)
    ]

    base
    |> maybe_add_flag(Config.claude_dangerously_skip_permissions?(), "--dangerously-skip-permissions")
    |> maybe_add_option(Config.claude_model(), "--model")
    |> maybe_add_allowed_tools(Config.claude_allowed_tools())
  end

  defp build_resume_args(session_id, prompt, workspace) do
    [
      "--resume",
      session_id,
      "-p",
      prompt,
      "--output-format",
      Config.claude_output_format(),
      "--max-turns",
      to_string(Config.claude_max_turns()),
      "--cwd",
      Path.expand(workspace)
    ]
  end

  defp maybe_add_flag(args, true, flag), do: args ++ [flag]
  defp maybe_add_flag(args, _, _flag), do: args

  defp maybe_add_option(args, nil, _opt), do: args
  defp maybe_add_option(args, value, opt), do: args ++ [opt, value]

  defp maybe_add_allowed_tools(args, nil), do: args
  defp maybe_add_allowed_tools(args, []), do: args

  defp maybe_add_allowed_tools(args, tools) when is_list(tools) do
    Enum.reduce(tools, args, fn tool, acc -> acc ++ ["--allowedTools", tool] end)
  end

  defp parse_command(command, extra_args) do
    parts = String.split(command, ~r/\s+/, trim: true)

    {cmd, cmd_args} =
      case parts do
        [cmd | rest] -> {cmd, rest ++ extra_args}
        [] -> {"claude", extra_args}
      end

    resolved_cmd = System.find_executable(cmd) || cmd
    {resolved_cmd, cmd_args}
  end

  defp validate_workspace(workspace) do
    expanded = Path.expand(workspace)
    root = Path.expand(Config.workspace_root())

    cond do
      !File.dir?(expanded) -> {:error, {:invalid_workspace_cwd, :not_a_directory}}
      !String.starts_with?(expanded, root) -> {:error, {:invalid_workspace_cwd, :outside_root}}
      true -> :ok
    end
  end

  defp safe_port_close(port) do
    Port.close(port)
  rescue
    ArgumentError -> :ok
  catch
    :error, :badarg -> :ok
  end
end
