defmodule MeriazardLocal.DataStore do
  alias :mnesia, as: Mnesia

  def setup do
    Mnesia.create_schema([node()])
    Mnesia.start()

    unless Mnesia.system_info(:tables) |> Enum.member?(:media_list) do
      Mnesia.create_table(:media_list,
        attributes: [:id, :name, :path],
        disc_copies: disc_copies()
      )
    end

    unless Mnesia.system_info(:tables) |> Enum.member?(:id_sequences) do
      Mnesia.create_table(:id_sequences,
        attributes: [:table_name, :next_id],
        disc_copies: disc_copies()
      )
    end

    unless Mnesia.system_info(:tables) |> Enum.member?(:media_captures) do
      Mnesia.create_table(:media_captures,
        attributes: [:id, :media_id, :comment, :path],
        disc_copies: disc_copies()
      )
    end

    :ok
  end

  def disc_copies() do
    case Mix.env() do
      :test -> []
      _ -> [node()]
    end
  end

  defp next_id(name) do
    # must use in transaction
    case Mnesia.read({:id_sequences, name}) do
      [] ->
        Mnesia.write({:id_sequences, name, 2})
        1

      [{:id_sequences, _name, next_id}] ->
        Mnesia.write({:id_sequences, name, next_id + 1})
        next_id
    end
  end

  def current_sequences() do
    {:atomic, result} =
      Mnesia.transaction(fn ->
        Mnesia.match_object({:id_sequences, :_, :_})
        |> Enum.map(fn {:id_sequences, table_name, next_id} ->
          %{table_name: table_name, next_id: next_id}
        end)
      end)

    result
  end

  def add_media(media) do
    create_or_update_media(media, true)
  end

  def update_media(media) do
    case media do
      %{id: _} ->
        create_or_update_media(media)

      _ ->
        {:error, %{error: "id is not specified."}}
    end
  end

  defp create_or_update_media(media, new_record \\ false) do
    {:atomic, result} =
      Mnesia.transaction(fn ->
        id =
          if new_record do
            next_id(:media_list)
          else
            media.id
          end

        Mnesia.write({:media_list, id, media.name, media.path})
      end)

    {:ok, result}
  end

  def delete_media(id) do
    {:atomic, :ok} =
      Mnesia.transaction(fn ->
        Mnesia.delete({:media_list, id})
      end)

    :ok
  end

  def get_media(id) do
    {:atomic, result} =
      Mnesia.transaction(fn ->
        case Mnesia.read({:media_list, id}) do
          [] -> {:error, "Media not found."}
          [{:media_list, id, name, path}] -> %{id: id, name: name, path: path}
        end
      end)

    case result do
      {:error, error} -> {:error, %{error: error}}
      _ -> {:ok, result}
    end
  end

  def get_all_media do
    {:atomic, result} =
      Mnesia.transaction(fn ->
        Mnesia.match_object({:media_list, :_, :_, :_})
        |> Enum.map(fn {:media_list, id, name, path} -> %{id: id, name: name, path: path} end)
      end)

    {:ok, result}
  end

  def add_media_capture(media_capture) do
    {:atomic, result} =
      Mnesia.transaction(fn ->
        Mnesia.write(
          {:media_captures, next_id(:media_captures), media_capture.media_id,
           media_capture.comment, media_capture.path}
        )
      end)

    {:ok, result}
  end

  def get_media_captures(media_id) do
    {:atomic, result} =
      Mnesia.transaction(fn ->
        Mnesia.match_object({:media_captures, :_, media_id, :_, :_})
        |> Enum.map(fn {:media_captures, id, media_id, comment, path} ->
          %{id: id, media_id: media_id, comment: comment, path: path}
        end)
      end)

    case result do
      {:error, error} -> {:error, %{error: error}}
      _ -> {:ok, result}
    end
  end
end
