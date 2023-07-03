defmodule MeriazardLocal.Server do
  use GenServer

  def start_link(port) do
    GenServer.start_link(__MODULE__, port)
  end

  def init(port) do
    spawn_link(__MODULE__, :accept_loop, [port])

    {:ok, %{}}
  end

  def accept_loop(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false])
    loop(socket)
  end

  defp loop(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    spawn_link(__MODULE__, :client_loop, [client])
    loop(socket)
  end

  def client_loop(client) do
    case :gen_tcp.recv(client, 0) do
      {:ok, data} ->
        IO.puts("Received data: #{data}")
        response = MeriazardLocal.Service.process_request(String.trim(data))
        :gen_tcp.send(client, Jason.encode!(response))
        client_loop(client)

      {:error, _reason} ->
        IO.puts("Client disconnected")
        :ok
    end
  end
end
