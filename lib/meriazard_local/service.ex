defmodule MeriazardLocal.Service do
  @moduledoc """
  This is the Service module for MyApp.
  """

  def handle_command("get_media_list") do
    media_list = get_media_list()
    Enum.map(media_list, fn media -> %{id: media.id, name: media.name} end)
  end

  def handle_command("get_media") do
    media = get_media()
    %{id: media.id, name: media.name, path: media.path}
  end

  def handle_command(_command) do
    %{error: "Invalid command"}
  end

  defp get_media_list() do
    # ここでメディアのリストを取得します。以下は例です。
    [
      %{id: 1, name: "Media 1", path: "/path/to/media1"},
      %{id: 2, name: "Media 2", path: "/path/to/media2"}
    ]
  end

  defp get_media() do
    # ここで特定のメディアを取得します。以下は例です。
    %{id: 1, name: "Media 1", path: "/path/to/media1"}
  end
end
