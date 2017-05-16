defmodule Nerves.UART do
  @moduledoc """
  Fake out Nerves.UART, mostly for unit testing.

  """

  use GenServer

  @enforce_keys [:port, :client]
  defstruct port: nil, client: nil, reactions: [], written: []
  @opaque t :: %__MODULE__{port: String.t,
                           client: pid,
                           reactions: list({String.t | Regex.t, String.t}),
                           written: [String.t]}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    {:ok, nil}
  end

  @doc """
  Mimics real `Nerves.UART.open`. In opts active must be true, and all other opts are not
  supported.
  """
  @spec open(pid, String.t, [active: true] | %{active: true}) :: :ok | {:error, :active_only_supported}
  def open(pid, port, opts) do
    case Keyword.get(opts, :active) do
      true ->
        GenServer.call(pid, {:open, port})
        :ok
      _ -> {:error, :active_only_supported}
    end
  end

  @doc """
  Mimics the real `Nerves.UART.write`. What is written, will be stored and retrieved via `written/1`.
  """
  @spec write(pid, String.t) :: :ok | {:error, :ebadf}
  def write(pid, text) do
    GenServer.call(pid, {:write, text})
  end

  @doc """
  Everything written so far via `write/2`
  """
  @spec written(pid) :: list(String.t) | {:error, :ebadf}
  def written(pid) do
    GenServer.call(pid, :written)
  end

  @doc """
  Mimics receiving from the serial port. Will send a message to the client process (that which opened this GenServer)
  with in the form of `{:nerves_uart, port, msg}` where `port` is the serial port set in `open/3`.
  """
  @spec pretend_to_receive(pid, String.t) :: :ok | {:error, :ebadf}
  def pretend_to_receive(pid, msg) do
    GenServer.call(pid, {:pretend_to_receive, msg})
  end

  @doc """
  When next something is written, which matches `match` respond as if `reaction_message` has just been received. Mimics command/response
  over the wire. The client process is sent a message in the form of `{:nerves_uart, port, msg}`.

  Note that this is one-time only.
  """
  @spec react_to_next_matching_write(pid, String.t | Regex.t, String.t) :: :ok | {:error, :ebadf}
  def react_to_next_matching_write(pid, match, reaction_message) do
    GenServer.cast(pid, {:react_to_next_matching_write, match, reaction_message})
  end

  def handle_call({:open, port}, {from, _}, _) do
    {:reply, :ok, %__MODULE__{port: port, client: from}}
  end

  def handle_call(_, _, nil), do: {:reply, {:error, :ebadf}, nil}

  def handle_call({:write, text}, _, s = %{written: written,
                                           reactions: [{react_match, react_message}  | react_tail]}) do
    if text =~ react_match do
      send_to_client(react_message, s)
      {:reply, :ok, %{s | written: [text | written], reactions: react_tail}}
    else
      {:reply, :ok, %{s | written: [text | written]}}
    end
  end

  def handle_call({:write, text}, _, s = %{written: written}) do
    {:reply, :ok, %{s | written: [text | written]}}
  end

  def handle_call(:written, _, s = %{written: written}), do: {:reply, Enum.reverse(written), s}

  def handle_call({:pretend_to_receive, msg}, _from, s) do
    send_to_client(msg, s)
    {:reply, :ok, s}
  end

  def handle_cast({:react_to_next_matching_write, match, reaction_message}, s = %{reactions: reactions}) do
    {:noreply, %{s | reactions: reactions ++ [{match, reaction_message}]}}
  end

  defp send_to_client(msg, %{port: port, client: client}), do: send(client, {:nerves_uart, port, msg})
end
