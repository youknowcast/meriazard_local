defmodule MeriazardLocal.Application do
  alias MeriazardLocal.Server
  alias MeriazardLocal.DataStore
  use Application

  def start(_type, _args) do
    DataStore.setup()

    children = [
      # Starts a worker by calling: MyApp.Worker.start_link(arg)
      # {MyApp.Worker, arg}
      {Server, 32552}
    ]

    # See https://hexdocs.pm/elixir/Application.html
    # for more information on OTP Applications
    opts = [strategy: :one_for_one, name: MeriazardLocal.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
