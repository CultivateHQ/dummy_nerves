defmodule Nerves.UART do
  @moduledoc """
  Fake out Nerves.UART, mostly for testing.

  """

  use GenServer

  defstruct port: nil, client: nil, reactions: [], written: []

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    {:ok, %__MODULE__{}}
  end

  def open(pid, port, opts) do
    case Keyword.get(opts, :active) do
      true ->
        GenServer.call(pid, {:open, port})
        :ok
      _ -> {:error, :active_only_supported}
    end
  end

  def write(pid, text) do
    GenServer.call(pid, {:write, text})
  end

  def written(pid) do
    GenServer.call(pid, :written)
  end

  def pretend_to_receive(pid, msg) do
    GenServer.call(pid, {:pretend_to_receive, msg})
  end

  def react_to_next_matching_write(pid, match, reaction_message) do
    GenServer.cast(pid, {:react_to_next_matching_write, match, reaction_message})
  end

  def handle_call({:open, port}, {from, _}, s) do
    {:reply, :ok, %{s | port: port, client: from}}
  end

  def handle_call({:write, text}, _, s = %{written: written,
                                           reactions: [{reaction_match, reaction_message}  | tail_reactions]}) do
    cond do
      text =~ reaction_match ->
        send_to_client(reaction_message, s)
        {:reply, :ok, %{s | written: [text | written], reactions: tail_reactions}}
      true ->
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
    {:noreply, %{s | reactions: [{match, reaction_message}, reactions]}}
  end

  defp send_to_client(msg, %{port: port, client: client}), do: send(client, {:nerves_uart, port, msg})
end
