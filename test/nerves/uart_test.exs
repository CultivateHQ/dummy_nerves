defmodule Nerves.UARTTest do
  use ExUnit.Case

  alias Nerves.UART

  setup do
    {:ok, pid} = UART.start_link
    UART.open(pid, "tty.something", active: true)
    {:ok, pid: pid}
  end

  test "open when active", %{pid: pid} do
    assert :ok == UART.open(pid, "abc", active: true)
    assert "abc" == :sys.get_state(pid).port
  end

  test "doesn't support non active open", %{pid: pid} do
    assert {:error, :active_only_supported} == UART.open(pid, "abc", active: false)
  end

  test "receiving", %{pid: pid} do
    UART.pretend_to_receive(pid, "hello matey")
    assert_receive {:nerves_uart, "tty.something", "hello matey"}
  end

  test "write", %{pid: pid} do
    UART.write(pid, "watcha")
    UART.write(pid, "pal")

    assert ["watcha", "pal"] == UART.written(pid)
  end

  test "write with reaction", %{pid: pid} do
    UART.react_to_next_matching_write(pid, ~r/ll/, "surprise!")

    UART.write(pid, "hi there")
    refute_receive _

    UART.write(pid, "hello")
    assert_receive {:nerves_uart, "tty.something", "surprise!"}

    UART.write(pid, "hello")
    refute_receive _

    assert ["hi there", "hello", "hello"] == UART.written(pid)
  end
end
