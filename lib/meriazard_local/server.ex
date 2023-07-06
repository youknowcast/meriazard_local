defmodule MeriazardLocal.Server do
  use GenServer

  @max_retries 10

  def start_link(port) do
    GenServer.start_link(__MODULE__, port)
  end

  def init(port) do
    spawn_link(__MODULE__, :accept_loop, [port])

    {:ok, %{}}
  end

  def accept_loop(port, retries \\ 0) do
    case :gen_tcp.listen(port, [:binary, packet: :line, active: false]) do
      {:ok, socket} ->
        loop(socket)

      {:error, :eaddrinuse} ->
        if retries < @max_retries do
          wait_time = :math.pow(2, retries) |> round
          IO.puts("Address in use, retrying in #{wait_time} second(s)...")
          :timer.sleep(wait_time * 1000)
          accept_loop(port, retries + 1)
        else
          IO.puts("Failed to bind the address after #{@max_retries} retries")
        end
    end
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
