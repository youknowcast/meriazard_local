defmodule DataStoreTest do
  use ExUnit.Case

  alias MeriazardLocal.DataStore

  test "add media_list table" do
    DataStore.add_media(%{name: "my_file", path: "/to/my/file/path"})

    assert DataStore.get_media(1) == {:atomic, {:ok, {"my_file", "/to/my/file/path"}}}
  end
end
