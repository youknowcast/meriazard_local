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

  def add_media(media) do
    Mnesia.transaction(fn ->
      Mnesia.write({:media_list, next_id(:media_list), media.name, media.path})
    end)
  end

  def get_media(id) do
    Mnesia.transaction(fn ->
      case Mnesia.read({:media_list, id}) do
        [] -> {:error, "Media not found."}
        [{:media_list, _, name, path}] -> {:ok, {name, path}}
      end
    end)
  end

  def get_all_media do
    Mnesia.transaction(fn ->
      Mnesia.match_object({:media_list, :_, :_, :_})
      |> Enum.map(fn {:media_list, _, name, path} -> {name, path} end)
    end)
  end
end
