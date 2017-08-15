defmodule ElixirALE.SPI do
  use GenServer

  defstruct devname: nil, spi_opts: [], transfer_answer: <<0::size(4), 0::size(12)>>, transfer_arguments: []

  def start_link(devname, spi_opts \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, {devname, spi_opts}, opts)
  end

  def set_transfer_answer(pid, answer) do
    GenServer.call(pid, {:set_transfer_answer, answer})

  end

  def transfer(pid, args) do
    GenServer.call(pid, {:transfer, args})
  end

  def transfer_arguments(pid) do
    GenServer.call(pid, :transfer_arguments)
  end

  def init({devname, spi_opts})  do
    {:ok, %__MODULE__{devname: devname, spi_opts: spi_opts}}
  end

  def handle_call({:set_transfer_answer, answer}, _, state) do
    {:reply, :ok, %{state | transfer_answer: answer}}
  end

  def handle_call({:transfer, args}, _, state = %{transfer_answer: answer}) do
    new_state = Map.update!(state, :transfer_arguments, fn (arguments_log) ->
      [args | arguments_log]
    end)
    {:reply, answer, new_state}
  end

  def handle_call(:transfer_arguments, _, state = %{transfer_arguments: transfer_arguments}) do
    {:reply, transfer_arguments, state}
  end

end
