defmodule MeriazardLocal.Service do
  @moduledoc """
  This is the Service module for MyApp.
  """

  alias MeriazardLocal.DataStore

  def process_request(request) do
    case request do
      "get_media_list" ->
        result = DataStore.get_all_media()

        case result do
          {:ok, media_list} -> media_list
          error -> %{error: error}
        end

      "get_media" ->
        # ここではデモ用に ID が 1 のメディアを取得しています。
        # 実際にはリクエストから ID を解析して適切なメディアを取得する必要があります。
        result = DataStore.get_media(1)

        case result do
          {:ok, media} -> media
          {:error, error} -> %{error: error}
        end

      _ ->
        %{error: "Unknown command"}
    end
  end
end
