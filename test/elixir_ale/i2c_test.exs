defmodule ElixirALE.I2CTest do
  use ExUnit.Case

  alias ElixirALE.I2C

  setup do
    {:ok, i2c} = I2C.start_link("test", 0x7, [:abc])
    {:ok, i2c: i2c}
  end

  test "logs calls", %{i2c: i2c} do
    I2C.write(i2c, <<0x72, 0x4>>)
    I2C.read(i2c, 2)
    I2C.write_read(i2c, <<0x9>>, 1)
    I2C.write_read_device(i2c, 0x7, <<0x9>>, 1)

    assert [
      {:write, <<0x72, 0x4>>},
      {:read, 2},
      {:write_read, <<0x9>>, 1},
      {:write_read_device, 0x7, <<9>>, 1},
    ] == I2C.call_log(i2c)
  end

  test "ignores test helper calls in log", %{i2c: i2c} do
    I2C.call_log(i2c)
    I2C.set_binary_to_read(i2c, <<0::size(11)>>)
    assert [] == I2C.call_log(i2c)
  end

  test "default read to zeroes", %{i2c: i2c} do
    assert <<0>> = I2C.read(i2c, 1)
    assert <<0, 0, 0>> = I2C.read(i2c, 3)
  end

  test "setting the read result", %{i2c: i2c} do
    I2C.set_binary_to_read(i2c, <<1, 2, 3>>)
    assert <<1, 2>> = I2C.read(i2c, 2)
    assert <<3>> == I2C.read(i2c, 1)
  end

  test "when not enough set to read it is padded with zeroes", %{i2c: i2c} do
    I2C.set_binary_to_read(i2c, <<1>>)
    assert <<1, 0>> == I2C.read(i2c, 2)
  end

  test "writes just succesed", %{i2c: i2c} do
    assert :ok == I2C.write(i2c, 0x1)
  end

  test "writes and reads", %{i2c: i2c} do
    I2C.set_binary_to_read(i2c, <<1, 2, 3, 4, 5>>)

    assert <<1, 2, 3>> == I2C.write_read(i2c, 0x5, 3)
    assert <<4, 5>> == I2C.write_read_device(i2c, 0x77, 0x5, 2)
  end
end
