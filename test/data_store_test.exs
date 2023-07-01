defmodule DataStoreTest do
  use ExUnit.Case

  alias MeriazardLocal.DataStore

  test "add media_list table" do
    DataStore.add_media(%{name: "my_file", path: "/to/my/file/path"})
    DataStore.add_media(%{name: "my_file2", path: "/to/my/file/path2"})
    DataStore.add_media(%{name: "my_file3", path: "/to/my/file/path3"})

    assert DataStore.get_media(1) == {:atomic, {:ok, {"my_file", "/to/my/file/path"}}}
    assert DataStore.get_media(2) == {:atomic, {:ok, {"my_file2", "/to/my/file/path2"}}}
    assert DataStore.get_media(3) == {:atomic, {:ok, {"my_file3", "/to/my/file/path3"}}}

    assert DataStore.get_media(99) == {:atomic, {:error, "Media not found."}}

    {:atomic, all_media} = DataStore.get_all_media()
    assert all_media |> Enum.count() == 3
  end
end
