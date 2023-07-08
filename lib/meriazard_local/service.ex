defmodule MeriazardLocal.Service do
  @moduledoc """
  This is the Service module for MyApp.
  """

  alias MeriazardLocal.DataStore

  def process_request(request) do
    [command | params] = String.split(request, ",", parts: 2)

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

      "add_media" ->
        [param | _] = params
        record = Jason.decode!(param, keys: :atoms)
        {:ok, media} = DataStore.add_media(record)
        [media]

      "delete_media" ->
        [id | _] = params
        DataStore.delete_media(String.to_integer(id))
        %{id: id}

      "add_media_capture" ->
        [param | _] = params
        record = Jason.decode!(param, keys: :atoms)
        {:ok, media_capture} = DataStore.add_media_capture(record)
        [media_capture]

      "get_media_captures" ->
        [media_id | _] = params
        {:ok, result} = DataStore.get_media_captures(String.to_integer(media_id))
        result

      "add_media_tag" ->
        [param | _] = params
        record = Jason.decode!(param, keys: :atoms)
        {:ok, media} = DataStore.add_media_tag(record)
        [media]

      _ ->
        %{error: "Unknown command"}
    end
  end
end
