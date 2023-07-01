defmodule DataStoreTest do
  use ExUnit.Case

  alias MeriazardLocal.DataStore

  test "add media_list table" do
    DataStore.add_media(%{name: "my_file", path: "/to/my/file/path"})
    DataStore.add_media(%{name: "my_file2", path: "/to/my/file/path2"})
    DataStore.add_media(%{name: "my_file3", path: "/to/my/file/path3"})

    assert DataStore.get_media(1) == {:ok, {1, "my_file", "/to/my/file/path"}}
    assert DataStore.get_media(2) == {:ok, {2, "my_file2", "/to/my/file/path2"}}
    assert DataStore.get_media(3) == {:ok, {3, "my_file3", "/to/my/file/path3"}}

    assert DataStore.get_media(99) == {:error, "Media not found."}

    all_media = DataStore.get_all_media()
    assert all_media |> Enum.count() == 3

    assert DataStore.update_media(%{id: 1, name: "my_file_changed", path: "/to/my/file/path"})
    assert DataStore.get_media(1) == {:ok, {1, "my_file_changed", "/to/my/file/path"}}

    assert DataStore.update_media(%{name: "my_file_changed2", path: "/to/my/file/path"}) ==
             {:error, "id is not specified."}

    assert DataStore.delete_media(1) == :ok
    assert DataStore.get_media(1) == {:error, "Media not found."}
  end
end
