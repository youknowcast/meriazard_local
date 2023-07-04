defmodule MeriazardLocal.Service do
  @moduledoc """
  This is the Service module for MyApp.
  """

  alias MeriazardLocal.DataStore

  def process_request(request) do
    [command | params] = String.split(request, ",")

    case command do
      "get_media_list" ->
        {:ok, result} = DataStore.get_all_media()
        result

      "get_media" ->
        [id | _] = params
        result = DataStore.get_media(id)

        case result do
          {:ok, media} -> media
          {:error, error} -> %{error: error}
        end

      _ ->
        %{error: "Unknown command"}
    end
  end
end
