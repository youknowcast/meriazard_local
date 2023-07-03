defmodule DataStoreTest do
  use ExUnit.Case

  alias MeriazardLocal.DataStore

  test "add media_list table" do
    DataStore.add_media(%{name: "my_file", path: "/to/my/file/path"})
    DataStore.add_media(%{name: "my_file2", path: "/to/my/file/path2"})
    DataStore.add_media(%{name: "my_file3", path: "/to/my/file/path3"})

    assert DataStore.get_media(1) == {:ok, %{id: 1, name: "my_file", path: "/to/my/file/path"}}
    assert DataStore.get_media(2) == {:ok, %{id: 2, name: "my_file2", path: "/to/my/file/path2"}}
    assert DataStore.get_media(3) == {:ok, %{id: 3, name: "my_file3", path: "/to/my/file/path3"}}

    assert DataStore.get_media(99) == {:error, %{error: "Media not found."}}

    {:ok, all_media} = DataStore.get_all_media()
    assert all_media |> Enum.count() == 3

    assert DataStore.update_media(%{id: 1, name: "my_file_changed", path: "/to/my/file/path"})

    assert DataStore.get_media(1) ==
             {:ok, %{id: 1, name: "my_file_changed", path: "/to/my/file/path"}}

    assert DataStore.update_media(%{name: "my_file_changed2", path: "/to/my/file/path"}) ==
             {:error, %{error: "id is not specified."}}

    assert DataStore.delete_media(1) == :ok
    assert DataStore.get_media(1) == {:error, %{error: "Media not found."}}
  end
end
