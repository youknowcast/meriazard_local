# MeriazardLocal

## MeriazardLocal.Server testing

its easy to test with using netcat.

```
% nc -v localhost 32552 -4
```

## front_app

0. need to create `captures` directory at Desktop for saving screenshot.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `meriazard_local` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:meriazard_local, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/meriazard_local>.

