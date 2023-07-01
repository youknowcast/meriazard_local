defmodule MeriazardLocal do
  @moduledoc """
  Documentation for `MeriazardLocal`.
  """

  alias MeriazardLocal.DataStore

  @doc """
  Hello world.

  ## Examples

      iex> MeriazardLocal.hello()
      :world

  """
  def hello do
    DataStore.setup()

    DataStore.add_media(%{id: 1, name: "hoo", path: "var"})
  end

  def commands do
    [
      all_media: DataStore.get_all_media,
    ]
  end
end
