defmodule ServerTest do
  use ExUnit.Case

  alias MeriazardLocal.Server

  # server port for testing
  @port 32553

  setup do
    # The server will be automatically terminated when the test finishes
    {:ok, pid} = Server.start_link(@port)
    {:ok, pid: pid}
  end

  test "binds to a port and accepts connections" do
    {:ok, socket} = :gen_tcp.connect('localhost', @port, [:binary, packet: :line, active: false])

    :timer.sleep(1000)

    :ok = :gen_tcp.send(socket, "Hello, server!\n")

    {:ok, response} = :gen_tcp.recv(socket, 0, 1000)

    assert response == "You said Hello, server!\n"

    :ok = :gen_tcp.close(socket)
  end
end
