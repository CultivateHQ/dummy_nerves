defmodule ElixirALE.I2C do
  @moduledoc """
  A fake ElixirALE.I2C for testing purposes.
  """

  @type i2c_address :: 0..127

  defstruct call_log: [], binary_to_read: <<>>



  @spec start_link(binary, i2c_address, [term]) :: {:ok, pid}
  def start_link(devname, address, opts \\ []) do
    GenServer.start_link(__MODULE__, {devname, address}, opts)
  end

  def init({_devname, _address}) do
    {:ok, %__MODULE__{}}
  end

  @doc """
  Set the stream of bytes to be read
  """
  @spec set_binary_to_read(pid, binary) :: :ok
  def set_binary_to_read(pid, result) do
    GenServer.cast(pid, {:set_binary_to_read, result})
  end

  def call_log(pid) do
    pid
    |> GenServer.call(:call_log)
    |> Enum.reverse()
  end


  def write(pid, data) do
    GenServer.call(pid, {:write, data})
  end

  def read(pid, count) do
    GenServer.call(pid, {:read, count})
  end

  def write_read(pid, data, count) do
    GenServer.call(pid, {:write_read, data, count})
  end

  def write_read_device(pid, address, data, count) do
    GenServer.call(pid, {:write_read_device, address, data, count})
  end

  def handle_cast({:set_binary_to_read, binary_to_read}, s) do
    {:noreply, %{s | binary_to_read: binary_to_read}}
  end

  def handle_call(:call_log, _from, s = %{call_log: call_log}) do
    {:reply, call_log, s}
  end

  def handle_call(message, _from, s = %{call_log: call_log}) do
    new_log = [message | call_log]
    {result, new_s} = do_call(message, s)
    {:reply, result, %{new_s | call_log: new_log}}
  end

  defp do_call({:read, count}, s), do: do_read(count, s)
  defp do_call({:write_read, _, count}, s), do: do_read(count, s)
  defp do_call({:write_read_device, _, _, count}, s), do: do_read(count, s)

  defp do_call(_, s) do
    {:ok, s}
  end

  defp do_read(count, s) do
    {result, remaining} = read_bytes(count, s)
    {result, %{s | binary_to_read: remaining}}
  end

  defp read_bytes(count, %{binary_to_read: binary_to_read}) when byte_size(binary_to_read) < count do
    padding_size = (count - byte_size(binary_to_read)) * 8
    {binary_to_read <> <<0::size(padding_size)>>, <<>>}
  end

  defp read_bytes(count, %{binary_to_read: binary_to_read}) do
    result = binary_part(binary_to_read, 0, count)
    size = count * 8
    <<_::size(size), remaining::binary>> = binary_to_read
    {result, remaining}
  end
end
